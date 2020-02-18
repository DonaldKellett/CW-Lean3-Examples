/-
Copyright (c) 2018 Andreas Swerdlow. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Andreas Swerdlow
-/

import ring_theory.subring

variables {F : Type*} [discrete_field F] (S : set F)

section prio
set_option default_priority 100 -- see Note [default priority]
class is_subfield extends is_subring S : Prop :=
(inv_mem : ∀ {x : F}, x ≠ 0 → x ∈ S → x⁻¹ ∈ S)
end prio

instance is_subfield.field [is_subfield S] : discrete_field S :=
{ inv := λ x, ⟨x⁻¹, if hx0 : x = 0
    then by erw [hx0, inv_zero]; exact is_add_submonoid.zero_mem _
    else is_subfield.inv_mem (λ h, hx0 $ subtype.ext.2 h) x.2⟩,
  zero_ne_one := λ h : 0 = 1, (@zero_ne_one F _) (subtype.ext.1 h),
  mul_inv_cancel := λ a ha, subtype.ext.2 (mul_inv_cancel
    (λ h, ha $ subtype.ext.2 h)),
  inv_mul_cancel := λ a ha, subtype.ext.2 (inv_mul_cancel
    (λ h, ha $ subtype.ext.2 h)),
  has_decidable_eq := by apply_instance,
  inv_zero := subtype.ext.2 inv_zero,
  ..show comm_ring S, by apply_instance }

instance univ.is_subfield : is_subfield (@set.univ F) :=
{ inv_mem := by intros; trivial }

/- note: in the next two declarations, if we let type-class inference figure out the instance
  `is_ring_hom.is_subring_preimage` then that instance only applies when particular instances of
  `is_add_subgroup _` and `is_submonoid _` are chosen (which are not the default ones).
  If we specify it explicitly, then it doesn't complain. -/
instance preimage.is_subfield {K : Type*} [discrete_field K]
  (f : F →+* K) (s : set K) [is_subfield s] : is_subfield (f ⁻¹' s) :=
{ inv_mem := λ a ha0 (ha : f a ∈ s), show f a⁻¹ ∈ s,
    by { rw [f.map_inv' ha0],
         exact is_subfield.inv_mem (f.map_ne_zero.2 ha0) ha },
  ..is_ring_hom.is_subring_preimage f s }

instance image.is_subfield {K : Type*} [discrete_field K]
  (f : F →+* K) (s : set F) [is_subfield s] : is_subfield (f '' s) :=
{ inv_mem := λ a ha0 ⟨x, hx⟩,
    have hx0 : x ≠ 0, from λ hx0, ha0 (hx.2 ▸ hx0.symm ▸ f.map_zero),
    ⟨x⁻¹, is_subfield.inv_mem hx0 hx.1,
    by { rw [← hx.2, f.map_inv' hx0], refl }⟩,
  ..is_ring_hom.is_subring_image f s }

instance range.is_subfield {K : Type*} [discrete_field K]
  (f : F →+* K) : is_subfield (set.range f) :=
by { rw ← set.image_univ, apply_instance }

namespace field

def closure : set F :=
{ x | ∃ y ∈ ring.closure S, ∃ z ∈ ring.closure S, z ≠ 0 ∧ y / z = x }

variables {S}

theorem ring_closure_subset : ring.closure S ⊆ closure S :=
λ x hx, ⟨x, hx, 1, is_submonoid.one_mem _, one_ne_zero, div_one x⟩

instance closure.is_submonoid : is_submonoid (closure S) :=
{ mul_mem := by rintros _  _ ⟨p, hp, q, hq, hq0, rfl⟩ ⟨r, hr, s, hs, hs0, rfl⟩;
    exact ⟨p * r, is_submonoid.mul_mem hp hr, q * s, is_submonoid.mul_mem hq hs, mul_ne_zero hq0 hs0, (div_mul_div _ _ hq0 hs0).symm⟩,
  one_mem := ring_closure_subset $ is_submonoid.one_mem _ }

instance closure.is_subfield : is_subfield (closure S) :=
{ add_mem := begin
    rintros _ _ ⟨p, hp, q, hq, hq0, rfl⟩ ⟨r, hr, s, hs, hs0, rfl⟩,
    exact ⟨p * s + q * r, is_add_submonoid.add_mem (is_submonoid.mul_mem hp hs) (is_submonoid.mul_mem hq hr),
      q * s, is_submonoid.mul_mem hq hs, mul_ne_zero hq0 hs0, (div_add_div p r hq0 hs0).symm⟩
  end,
  zero_mem := ring_closure_subset $ is_add_submonoid.zero_mem _,
  neg_mem := begin
    rintros _ ⟨p, hp, q, hq, hq0, rfl⟩,
    exact ⟨-p, is_add_subgroup.neg_mem hp, q, hq, hq0, neg_div q p⟩
  end,
  inv_mem := begin
    rintros _ hp0 ⟨p, hp, q, hq, hq0, rfl⟩,
    exact ⟨q, hq, p, hp, (div_ne_zero_iff hq0).1 hp0, (inv_div ((div_ne_zero_iff hq0).1 hp0) hq0).symm⟩
  end }

theorem mem_closure {a : F} (ha : a ∈ S) : a ∈ closure S :=
ring_closure_subset $ ring.mem_closure ha

theorem subset_closure : S ⊆ closure S :=
λ _, mem_closure

theorem closure_subset {T : set F} [is_subfield T] (H : S ⊆ T) : closure S ⊆ T :=
by rintros _ ⟨p, hp, q, hq, hq0, rfl⟩; exact is_submonoid.mul_mem (ring.closure_subset H hp)
  (is_subfield.inv_mem hq0 $ ring.closure_subset H hq)

theorem closure_subset_iff (s t : set F) [is_subfield t] : closure s ⊆ t ↔ s ⊆ t :=
⟨set.subset.trans subset_closure, closure_subset⟩

theorem closure_mono {s t : set F} (H : s ⊆ t) : closure s ⊆ closure t :=
closure_subset $ set.subset.trans H subset_closure

end field

lemma is_subfield_Union_of_directed {ι : Type*} [hι : nonempty ι]
  (s : ι → set F) [∀ i, is_subfield (s i)]
  (directed : ∀ i j, ∃ k, s i ⊆ s k ∧ s j ⊆ s k) :
  is_subfield (⋃i, s i) :=
{ inv_mem := λ x hx0 hx, let ⟨i, hi⟩ := set.mem_Union.1 hx in
    set.mem_Union.2 ⟨i, is_subfield.inv_mem hx0 hi⟩,
  to_is_subring := is_subring_Union_of_directed s directed }
