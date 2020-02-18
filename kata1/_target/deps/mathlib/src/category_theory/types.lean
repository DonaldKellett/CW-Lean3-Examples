/-
Copyright (c) 2017 Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Stephen Morgan, Scott Morrison, Johannes Hölzl
-/
import category_theory.functor_category
import category_theory.fully_faithful
import data.equiv.basic

namespace category_theory

universes v v' w u u' -- declare the `v`'s first; see `category_theory.category` for an explanation

instance types : large_category (Type u) :=
{ hom     := λ a b, (a → b),
  id      := λ a, id,
  comp    := λ _ _ _ f g, g ∘ f }

@[simp] lemma types_hom {α β : Type u} : (α ⟶ β) = (α → β) := rfl
@[simp] lemma types_id (X : Type u) : 𝟙 X = id := rfl
@[simp] lemma types_comp {X Y Z : Type u} (f : X ⟶ Y) (g : Y ⟶ Z) : f ≫ g = g ∘ f := rfl

namespace functor
variables {J : Type u} [𝒥 : category.{v} J]
include 𝒥

def sections (F : J ⥤ Type w) : set (Π j, F.obj j) :=
{ u | ∀ {j j'} (f : j ⟶ j'), F.map f (u j) = u j'}
end functor

namespace functor_to_types
variables {C : Type u} [𝒞 : category.{v} C] (F G H : C ⥤ Type w) {X Y Z : C}
include 𝒞
variables (σ : F ⟶ G) (τ : G ⟶ H)

@[simp] lemma map_comp (f : X ⟶ Y) (g : Y ⟶ Z) (a : F.obj X) : (F.map (f ≫ g)) a = (F.map g) ((F.map f) a) :=
by simp

@[simp] lemma map_id (a : F.obj X) : (F.map (𝟙 X)) a = a :=
by simp

lemma naturality (f : X ⟶ Y) (x : F.obj X) : σ.app Y ((F.map f) x) = (G.map f) (σ.app X x) :=
congr_fun (σ.naturality f) x

@[simp] lemma comp (x : F.obj X) : (σ ≫ τ).app X x = τ.app X (σ.app X x) := rfl

variables {D : Type u'} [𝒟 : category.{u'} D] (I J : D ⥤ C) (ρ : I ⟶ J) {W : D}

@[simp] lemma hcomp (x : (I ⋙ F).obj W) : (ρ ◫ σ).app W x = (G.map (ρ.app W)) (σ.app (I.obj W) x) := rfl

end functor_to_types

def ulift_trivial (V : Type u) : ulift.{u} V ≅ V := by tidy

def ulift_functor : Type u ⥤ Type (max u v) :=
{ obj := λ X, ulift.{v} X,
  map := λ X Y f, λ x : ulift.{v} X, ulift.up (f x.down) }

@[simp] lemma ulift_functor_map {X Y : Type u} (f : X ⟶ Y) (x : ulift.{v} X) :
  ulift_functor.map f x = ulift.up (f x.down) := rfl

instance ulift_functor_full : full ulift_functor :=
{ preimage := λ X Y f x, (f (ulift.up x)).down }
instance ulift_functor_faithful : faithful ulift_functor :=
{ injectivity' := λ X Y f g p, funext $ λ x,
    congr_arg ulift.down ((congr_fun p (ulift.up x)) : ((ulift.up (f x)) = (ulift.up (g x)))) }

def hom_of_element {X : Type u} (x : X) : punit ⟶ X := λ _, x

lemma hom_of_element_eq_iff {X : Type u} (x y : X) :
  hom_of_element x = hom_of_element y ↔ x = y :=
⟨λ H, congr_fun H punit.star, by cc⟩

lemma mono_iff_injective {X Y : Type u} (f : X ⟶ Y) : mono f ↔ function.injective f :=
begin
  split,
  { intros H x x' h,
    resetI,
    rw ←hom_of_element_eq_iff at ⊢ h,
    exact (cancel_mono f).mp h },
  { refine λ H, ⟨λ Z g h H₂, _⟩,
    ext z,
    replace H₂ := congr_fun H₂ z,
    exact H H₂ }
end

lemma epi_iff_surjective {X Y : Type u} (f : X ⟶ Y) : epi f ↔ function.surjective f :=
begin
  split,
  { intros H,
    let g : Y ⟶ ulift Prop := λ y, ⟨true⟩,
    let h : Y ⟶ ulift Prop := λ y, ⟨∃ x, f x = y⟩,
    suffices : f ≫ g = f ≫ h,
    { resetI,
      rw cancel_epi at this,
      intro y,
      replace this := congr_fun this y,
      replace this : true = ∃ x, f x = y := congr_arg ulift.down this,
      rw ←this,
      trivial },
    ext x,
    change true ↔ ∃ x', f x' = f x,
    rw true_iff,
    exact ⟨x, rfl⟩ },
  { intro H,
    constructor,
    intros Z g h H₂,
    apply funext,
    rw ←forall_iff_forall_surj H,
    intro x,
    exact (congr_fun H₂ x : _) }
end

section

/-- `of_type_functor m` converts from Lean's `Type`-based `category` to `category_theory`. This
allows us to use these functors in category theory. -/
def of_type_functor (m : Type u → Type v) [_root_.functor m] [is_lawful_functor m] :
  Type u ⥤ Type v :=
{ obj       := m,
  map       := λα β, _root_.functor.map,
  map_id'   := assume α, _root_.functor.map_id,
  map_comp' := assume α β γ f g, funext $ assume a, is_lawful_functor.comp_map f g _ }

variables (m : Type u → Type v) [_root_.functor m] [is_lawful_functor m]

@[simp]
lemma of_type_functor_obj : (of_type_functor m).obj = m := rfl

@[simp]
lemma of_type_functor_map {α β} (f : α → β) :
  (of_type_functor m).map f = (_root_.functor.map f : m α → m β) := rfl

end

end category_theory

-- Isomorphisms in Type and equivalences.

namespace equiv

universe u

variables {X Y : Type u}

def to_iso (e : X ≃ Y) : X ≅ Y :=
{ hom := e.to_fun,
  inv := e.inv_fun,
  hom_inv_id' := funext e.left_inv,
  inv_hom_id' := funext e.right_inv }

@[simp] lemma to_iso_hom {e : X ≃ Y} : e.to_iso.hom = e := rfl
@[simp] lemma to_iso_inv {e : X ≃ Y} : e.to_iso.inv = e.symm := rfl

end equiv

namespace category_theory.iso

universe u

variables {X Y : Type u}

def to_equiv (i : X ≅ Y) : X ≃ Y :=
{ to_fun := i.hom,
  inv_fun := i.inv,
  left_inv := λ x, congr_fun i.hom_inv_id x,
  right_inv := λ y, congr_fun i.inv_hom_id y }

@[simp] lemma to_equiv_fun (i : X ≅ Y) : (i.to_equiv : X → Y) = i.hom := rfl
@[simp] lemma to_equiv_symm_fun (i : X ≅ Y) : (i.to_equiv.symm : Y → X) = i.inv := rfl

end category_theory.iso


universe u

-- We prove `equiv_iso_iso` and then use that to sneakily construct `equiv_equiv_iso`.
-- (In this order the proofs are handled by `obviously`.)

/-- equivalences (between types in the same universe) are the same as (isomorphic to) isomorphisms of types -/
@[simps] def equiv_iso_iso {X Y : Type u} : (X ≃ Y) ≅ (X ≅ Y) :=
{ hom := λ e, e.to_iso,
  inv := λ i, i.to_equiv, }

/-- equivalences (between types in the same universe) are the same as (equivalent to) isomorphisms of types -/
-- We leave `X` and `Y` as explicit arguments here, because the coercions from `equiv` to a function won't fire without them.
def equiv_equiv_iso (X Y : Type u) : (X ≃ Y) ≃ (X ≅ Y) :=
(equiv_iso_iso).to_equiv

@[simp] lemma equiv_equiv_iso_hom {X Y : Type u} (e : X ≃ Y) : (equiv_equiv_iso X Y) e = e.to_iso := rfl
@[simp] lemma equiv_equiv_iso_inv {X Y : Type u} (e : X ≅ Y) : (equiv_equiv_iso X Y).symm e = e.to_equiv := rfl
