/-
Copyright (c) 2017 Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Tim Baumann, Stephen Morgan, Scott Morrison, Floris van Doorn
-/
import category_theory.fully_faithful
import category_theory.whiskering
import category_theory.natural_isomorphism
import tactic.slice
import tactic.converter.interactive

namespace category_theory
open category_theory.functor nat_iso category
universes v₁ v₂ v₃ u₁ u₂ u₃ -- declare the `v`'s first; see `category_theory.category` for an explanation

/-- We define an equivalence as a (half)-adjoint equivalence, a pair of functors with
  a unit and counit which are natural isomorphisms and the triangle law `Fη ≫ εF = 1`, or in other
  words the composite `F ⟶ FGF ⟶ F` is the identity.

  The triangle equation is written as a family of equalities between morphisms, it is more
  complicated if we write it as an equality of natural transformations, because then we would have
  to insert natural transformations like `F ⟶ F1`.
-/
structure equivalence (C : Type u₁) [category.{v₁} C] (D : Type u₂) [category.{v₂} D] :=
mk' ::
(functor : C ⥤ D)
(inverse : D ⥤ C)
(unit_iso   : 𝟭 C ≅ functor ⋙ inverse)
(counit_iso : inverse ⋙ functor ≅ 𝟭 D)
(functor_unit_iso_comp' : ∀(X : C), functor.map ((unit_iso.hom : 𝟭 C ⟶ functor ⋙ inverse).app X) ≫
  counit_iso.hom.app (functor.obj X) = 𝟙 (functor.obj X) . obviously)

restate_axiom equivalence.functor_unit_iso_comp'

infixr ` ≌ `:10  := equivalence

variables {C : Type u₁} [𝒞 : category.{v₁} C] {D : Type u₂} [𝒟 : category.{v₂} D]
include 𝒞 𝒟

namespace equivalence

@[simp] def unit (e : C ≌ D) : 𝟭 C ⟶ e.functor ⋙ e.inverse := e.unit_iso.hom
@[simp] def counit (e : C ≌ D) : e.inverse ⋙ e.functor ⟶ 𝟭 D := e.counit_iso.hom
@[simp] def unit_inv (e : C ≌ D) : e.functor ⋙ e.inverse ⟶ 𝟭 C := e.unit_iso.inv
@[simp] def counit_inv (e : C ≌ D) : 𝟭 D ⟶ e.inverse ⋙ e.functor := e.counit_iso.inv

lemma unit_def (e : C ≌ D) : e.unit_iso.hom = e.unit := rfl
lemma counit_def (e : C ≌ D) : e.counit_iso.hom = e.counit := rfl
lemma unit_inv_def (e : C ≌ D) : e.unit_iso.inv = e.unit_inv := rfl
lemma counit_inv_def (e : C ≌ D) : e.counit_iso.inv = e.counit_inv := rfl

@[simp] lemma functor_unit_comp (e : C ≌ D) (X : C) : e.functor.map (e.unit.app X) ≫
  e.counit.app (e.functor.obj X) = 𝟙 (e.functor.obj X) :=
e.functor_unit_iso_comp X

@[simp] lemma counit_inv_functor_comp (e : C ≌ D) (X : C) :
  e.counit_inv.app (e.functor.obj X) ≫ e.functor.map (e.unit_inv.app X) = 𝟙 (e.functor.obj X) :=
begin
  erw [iso.inv_eq_inv
    (e.functor.map_iso (e.unit_iso.app X) ≪≫ e.counit_iso.app (e.functor.obj X)) (iso.refl _)],
  exact e.functor_unit_comp X
end

lemma functor_unit (e : C ≌ D) (X : C) :
  e.functor.map (e.unit.app X) = e.counit_inv.app (e.functor.obj X) :=
by { erw [←iso.comp_hom_eq_id (e.counit_iso.app _), functor_unit_comp], refl }

lemma counit_functor (e : C ≌ D) (X : C) :
  e.counit.app (e.functor.obj X) = e.functor.map (e.unit_inv.app X) :=
by { erw [←iso.hom_comp_eq_id (e.functor.map_iso (e.unit_iso.app X)), functor_unit_comp], refl }

/-- The other triangle equality. The proof follows the following proof in Globular:
  http://globular.science/1905.001 -/
@[simp] lemma unit_inverse_comp (e : C ≌ D) (Y : D) :
  e.unit.app (e.inverse.obj Y) ≫ e.inverse.map (e.counit.app Y) = 𝟙 (e.inverse.obj Y) :=
begin
  rw [←id_comp _ (e.inverse.map _), ←map_id e.inverse, ←counit_inv_functor_comp, map_comp,
      ←iso.hom_inv_id_assoc (e.unit_iso.app _) (e.inverse.map (e.functor.map _)),
      app_hom, app_inv, unit_def, unit_inv_def],
  slice_lhs 2 3 { erw [e.unit.naturality] },
  slice_lhs 1 2 { erw [e.unit.naturality] },
  slice_lhs 4 4
  { rw [←iso.hom_inv_id_assoc (e.inverse.map_iso (e.counit_iso.app _)) (e.unit_inv.app _)] },
  slice_lhs 3 4 { erw [←map_comp e.inverse, e.counit.naturality],
    erw [(e.counit_iso.app _).hom_inv_id, map_id] }, erw [id_comp],
  slice_lhs 2 3 { erw [←map_comp e.inverse, e.counit_iso.inv.naturality, map_comp] },
  slice_lhs 3 4 { erw [e.unit_inv.naturality] },
  slice_lhs 4 5 { erw [←map_comp (e.functor ⋙ e.inverse), (e.unit_iso.app _).hom_inv_id, map_id] },
  erw [id_comp],
  slice_lhs 3 4 { erw [←e.unit_inv.naturality] },
  slice_lhs 2 3 { erw [←map_comp e.inverse, ←e.counit_iso.inv.naturality,
    (e.counit_iso.app _).hom_inv_id, map_id] }, erw [id_comp, (e.unit_iso.app _).hom_inv_id], refl
end

@[simp] lemma inverse_counit_inv_comp (e : C ≌ D) (Y : D) :
  e.inverse.map (e.counit_inv.app Y) ≫ e.unit_inv.app (e.inverse.obj Y) = 𝟙 (e.inverse.obj Y) :=
begin
  erw [iso.inv_eq_inv
    (e.unit_iso.app (e.inverse.obj Y) ≪≫ e.inverse.map_iso (e.counit_iso.app Y)) (iso.refl _)],
  exact e.unit_inverse_comp Y
end

lemma unit_inverse (e : C ≌ D) (Y : D) :
  e.unit.app (e.inverse.obj Y) = e.inverse.map (e.counit_inv.app Y) :=
by { erw [←iso.comp_hom_eq_id (e.inverse.map_iso (e.counit_iso.app Y)), unit_inverse_comp], refl }

lemma inverse_counit (e : C ≌ D) (Y : D) :
  e.inverse.map (e.counit.app Y) = e.unit_inv.app (e.inverse.obj Y) :=
by { erw [←iso.hom_comp_eq_id (e.unit_iso.app _), unit_inverse_comp], refl }

@[simp] lemma fun_inv_map (e : C ≌ D) (X Y : D) (f : X ⟶ Y) :
  e.functor.map (e.inverse.map f) = e.counit.app X ≫ f ≫ e.counit_inv.app Y :=
(nat_iso.naturality_2 (e.counit_iso) f).symm

@[simp] lemma inv_fun_map (e : C ≌ D) (X Y : C) (f : X ⟶ Y) :
  e.inverse.map (e.functor.map f) = e.unit_inv.app X ≫ f ≫ e.unit.app Y :=
(nat_iso.naturality_1 (e.unit_iso) f).symm

section
-- In this section we convert an arbitrary equivalence to a half-adjoint equivalence.
variables {F : C ⥤ D} {G : D ⥤ C} (η : 𝟭 C ≅ F ⋙ G) (ε : G ⋙ F ≅ 𝟭 D)

def adjointify_η : 𝟭 C ≅ F ⋙ G :=
calc
  𝟭 C ≅ F ⋙ G               : η
  ... ≅ F ⋙ (𝟭 D ⋙ G)      : iso_whisker_left F (left_unitor G).symm
  ... ≅ F ⋙ ((G ⋙ F) ⋙ G) : iso_whisker_left F (iso_whisker_right ε.symm G)
  ... ≅ F ⋙ (G ⋙ (F ⋙ G)) : iso_whisker_left F (associator G F G)
  ... ≅ (F ⋙ G) ⋙ (F ⋙ G) : (associator F G (F ⋙ G)).symm
  ... ≅ 𝟭 C ⋙ (F ⋙ G)      : iso_whisker_right η.symm (F ⋙ G)
  ... ≅ F ⋙ G               : left_unitor (F ⋙ G)

lemma adjointify_η_ε (X : C) :
  F.map ((adjointify_η η ε).hom.app X) ≫ ε.hom.app (F.obj X) = 𝟙 (F.obj X) :=
begin
  dsimp [adjointify_η], simp,
  have := ε.hom.naturality (F.map (η.inv.app X)), dsimp at this, rw [this], clear this,
  rw [←assoc _ _ _ (F.map _)],
  have := ε.hom.naturality (ε.inv.app $ F.obj X), dsimp at this, rw [this], clear this,
  have := (ε.app $ F.obj X).hom_inv_id, dsimp at this, rw [this], clear this,
  rw [id_comp], have := (F.map_iso $ η.app X).hom_inv_id, dsimp at this, rw [this]
end

end

protected definition mk (F : C ⥤ D) (G : D ⥤ C)
  (η : 𝟭 C ≅ F ⋙ G) (ε : G ⋙ F ≅ 𝟭 D) : C ≌ D :=
⟨F, G, adjointify_η η ε, ε, adjointify_η_ε η ε⟩

omit 𝒟
@[refl] def refl : C ≌ C := equivalence.mk (𝟭 C) (𝟭 C) (iso.refl _) (iso.refl _)
include 𝒟

@[symm] def symm (e : C ≌ D) : D ≌ C :=
⟨e.inverse, e.functor, e.counit_iso.symm, e.unit_iso.symm, e.inverse_counit_inv_comp⟩

variables {E : Type u₃} [ℰ : category.{v₃} E]
include ℰ

@[trans] def trans (e : C ≌ D) (f : D ≌ E) : C ≌ E :=
begin
  apply equivalence.mk (e.functor ⋙ f.functor) (f.inverse ⋙ e.inverse),
  { refine iso.trans e.unit_iso _,
    exact iso_whisker_left e.functor (iso_whisker_right f.unit_iso e.inverse) },
  { refine iso.trans _ f.counit_iso,
    exact iso_whisker_left f.inverse (iso_whisker_right e.counit_iso f.functor) }
end

def fun_inv_id_assoc (e : C ≌ D) (F : C ⥤ E) : e.functor ⋙ e.inverse ⋙ F ≅ F :=
(functor.associator _ _ _).symm ≪≫ iso_whisker_right e.unit_iso.symm F ≪≫ F.left_unitor

@[simp] lemma fun_inv_id_assoc_hom_app (e : C ≌ D) (F : C ⥤ E) (X : C) :
  (fun_inv_id_assoc e F).hom.app X = F.map (e.unit_inv.app X) :=
by { dsimp [fun_inv_id_assoc], tidy }

@[simp] lemma fun_inv_id_assoc_inv_app (e : C ≌ D) (F : C ⥤ E) (X : C) :
  (fun_inv_id_assoc e F).inv.app X = F.map (e.unit.app X) :=
by { dsimp [fun_inv_id_assoc], tidy }

def inv_fun_id_assoc (e : C ≌ D) (F : D ⥤ E) : e.inverse ⋙ e.functor ⋙ F ≅ F :=
(functor.associator _ _ _).symm ≪≫ iso_whisker_right e.counit_iso F ≪≫ F.left_unitor

@[simp] lemma inv_fun_id_assoc_hom_app (e : C ≌ D) (F : D ⥤ E) (X : D) :
  (inv_fun_id_assoc e F).hom.app X = F.map (e.counit.app X) :=
by { dsimp [inv_fun_id_assoc], tidy }

@[simp] lemma inv_fun_id_assoc_inv_app (e : C ≌ D) (F : D ⥤ E) (X : D) :
  (inv_fun_id_assoc e F).inv.app X = F.map (e.counit_inv.app X) :=
by { dsimp [inv_fun_id_assoc], tidy }

end equivalence


/-- A functor that is part of a (half) adjoint equivalence -/
class is_equivalence (F : C ⥤ D) :=
mk' ::
(inverse    : D ⥤ C)
(unit_iso   : 𝟭 C ≅ F ⋙ inverse)
(counit_iso : inverse ⋙ F ≅ 𝟭 D)
(functor_unit_iso_comp' : ∀ (X : C), F.map ((unit_iso.hom : 𝟭 C ⟶ F ⋙ inverse).app X) ≫
  counit_iso.hom.app (F.obj X) = 𝟙 (F.obj X) . obviously)

restate_axiom is_equivalence.functor_unit_iso_comp'

namespace is_equivalence

instance of_equivalence (F : C ≌ D) : is_equivalence F.functor :=
{ ..F }

instance of_equivalence_inverse (F : C ≌ D) : is_equivalence F.inverse :=
is_equivalence.of_equivalence F.symm

open equivalence
protected definition mk {F : C ⥤ D} (G : D ⥤ C)
  (η : 𝟭 C ≅ F ⋙ G) (ε : G ⋙ F ≅ 𝟭 D) : is_equivalence F :=
⟨G, adjointify_η η ε, ε, adjointify_η_ε η ε⟩

end is_equivalence


namespace functor

def as_equivalence (F : C ⥤ D) [is_equivalence F] : C ≌ D :=
⟨F, is_equivalence.inverse F, is_equivalence.unit_iso F, is_equivalence.counit_iso F,
  is_equivalence.functor_unit_iso_comp F⟩

omit 𝒟
instance is_equivalence_refl : is_equivalence (𝟭 C) :=
is_equivalence.of_equivalence equivalence.refl
include 𝒟

def inv (F : C ⥤ D) [is_equivalence F] : D ⥤ C :=
is_equivalence.inverse F

instance is_equivalence_inv (F : C ⥤ D) [is_equivalence F] : is_equivalence F.inv :=
is_equivalence.of_equivalence F.as_equivalence.symm

def fun_inv_id (F : C ⥤ D) [is_equivalence F] : F ⋙ F.inv ≅ 𝟭 C :=
(is_equivalence.unit_iso F).symm

def inv_fun_id (F : C ⥤ D) [is_equivalence F] : F.inv ⋙ F ≅ 𝟭 D :=
is_equivalence.counit_iso F

variables {E : Type u₃} [ℰ : category.{v₃} E]
include ℰ

instance is_equivalence_trans (F : C ⥤ D) (G : D ⥤ E) [is_equivalence F] [is_equivalence G] :
  is_equivalence (F ⋙ G) :=
is_equivalence.of_equivalence (equivalence.trans (as_equivalence F) (as_equivalence G))

end functor

namespace is_equivalence

@[simp] lemma fun_inv_map (F : C ⥤ D) [is_equivalence F] (X Y : D) (f : X ⟶ Y) :
  F.map (F.inv.map f) = (F.inv_fun_id.hom.app X) ≫ f ≫ (F.inv_fun_id.inv.app Y) :=
begin
  erw [nat_iso.naturality_2],
  refl
end
@[simp] lemma inv_fun_map (F : C ⥤ D) [is_equivalence F] (X Y : C) (f : X ⟶ Y) :
  F.inv.map (F.map f) = (F.fun_inv_id.hom.app X) ≫ f ≫ (F.fun_inv_id.inv.app Y) :=
begin
  erw [nat_iso.naturality_2],
  refl
end

-- We should probably restate many of the lemmas about `equivalence` for `is_equivalence`,
-- but these are the only ones I need for now.
@[simp] lemma functor_unit_comp (E : C ⥤ D) [is_equivalence E] (Y) :
  E.map (((is_equivalence.unit_iso E).hom).app Y) ≫ ((is_equivalence.counit_iso E).hom).app (E.obj Y) = 𝟙 _ :=
equivalence.functor_unit_comp (E.as_equivalence) Y

@[simp] lemma counit_inv_functor_comp (E : C ⥤ D) [is_equivalence E] (Y) :
  ((is_equivalence.counit_iso E).inv).app (E.obj Y) ≫ E.map (((is_equivalence.unit_iso E).inv).app Y) = 𝟙 _ :=
eq_of_inv_eq_inv (functor_unit_comp _ _)

end is_equivalence

class ess_surj (F : C ⥤ D) :=
(obj_preimage (d : D) : C)
(iso' (d : D) : F.obj (obj_preimage d) ≅ d . obviously)

restate_axiom ess_surj.iso'

namespace functor
def obj_preimage (F : C ⥤ D) [ess_surj F] (d : D) : C := ess_surj.obj_preimage.{v₁ v₂} F d
def fun_obj_preimage_iso (F : C ⥤ D) [ess_surj F] (d : D) : F.obj (F.obj_preimage d) ≅ d :=
ess_surj.iso F d
end functor

namespace equivalence

def ess_surj_of_equivalence (F : C ⥤ D) [is_equivalence F] : ess_surj F :=
⟨ λ Y : D, F.inv.obj Y, λ Y : D, (F.inv_fun_id.app Y) ⟩

@[priority 100] -- see Note [lower instance priority]
instance faithful_of_equivalence (F : C ⥤ D) [is_equivalence F] : faithful F :=
{ injectivity' := λ X Y f g w,
  begin
    have p := congr_arg (@category_theory.functor.map _ _ _ _ F.inv _ _) w,
    simpa only [cancel_epi, cancel_mono, is_equivalence.inv_fun_map] using p
  end }.

@[priority 100] -- see Note [lower instance priority]
instance full_of_equivalence (F : C ⥤ D) [is_equivalence F] : full F :=
{ preimage := λ X Y f, (F.fun_inv_id.app X).inv ≫ (F.inv.map f) ≫ (F.fun_inv_id.app Y).hom,
  witness' := λ X Y f,
  begin
    apply F.inv.injectivity,
    /- obviously can finish from here... -/
    dsimp, simp, dsimp,
    slice_lhs 4 6 {
      rw [←functor.map_comp, ←functor.map_comp],
      rw [←is_equivalence.fun_inv_map],
    },
    slice_lhs 1 2 { simp },
    dsimp, simp,
    slice_lhs 2 4 {
      rw [←functor.map_comp, ←functor.map_comp],
      erw [nat_iso.naturality_2],
    },
    erw [nat_iso.naturality_1], refl
  end }.

@[simp] private def equivalence_inverse (F : C ⥤ D) [full F] [faithful F] [ess_surj F] : D ⥤ C :=
{ obj  := λ X, F.obj_preimage X,
  map := λ X Y f, F.preimage ((F.fun_obj_preimage_iso X).hom ≫ f ≫ (F.fun_obj_preimage_iso Y).inv),
  map_id' := λ X, begin apply F.injectivity, tidy end,
  map_comp' := λ X Y Z f g, by apply F.injectivity; simp }.

def equivalence_of_fully_faithfully_ess_surj
  (F : C ⥤ D) [full F] [faithful F] [ess_surj F] : is_equivalence F :=
is_equivalence.mk (equivalence_inverse F)
  (nat_iso.of_components
    (λ X, (preimage_iso $ F.fun_obj_preimage_iso $ F.obj X).symm)
    (λ X Y f, by { apply F.injectivity, obviously }))
  (nat_iso.of_components
    (λ Y, F.fun_obj_preimage_iso Y)
    (by obviously))

end equivalence

end category_theory
