/-
Copyright (c) 2018 Patrick Massot. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Patrick Massot, Johannes Hölzl

Theory of topological rings with uniform structure.
-/

import topology.algebra.group_completion topology.algebra.ring

open classical set lattice filter topological_space add_comm_group
open_locale classical
noncomputable theory

namespace uniform_space.completion
open dense_inducing uniform_space function
variables (α : Type*) [ring α] [uniform_space α]

instance : has_one (completion α) := ⟨(1:α)⟩

instance : has_mul (completion α) :=
  ⟨curry $ (dense_inducing_coe.prod dense_inducing_coe).extend (coe ∘ uncurry' (*))⟩

@[elim_cast]
lemma coe_one : ((1 : α) : completion α) = 1 := rfl

variables {α} [topological_ring α]

@[move_cast]
lemma coe_mul (a b : α) : ((a * b : α) : completion α) = a * b :=
((dense_inducing_coe.prod dense_inducing_coe).extend_eq_of_cont
  ((continuous_coe α).comp continuous_mul) (a, b)).symm

variables [uniform_add_group α]

lemma continuous_mul : continuous (λ p : completion α × completion α, p.1 * p.2) :=
begin
  haveI : is_Z_bilin ((coe ∘ uncurry' (*)) : α × α → completion α) :=
  { add_left := begin
      introv,
      change coe ((a + a')*b) = coe (a*b) + coe (a'*b),
      rw_mod_cast add_mul
    end,
    add_right := begin
      introv,
      change coe (a*(b + b')) = coe (a*b) + coe (a*b'),
      rw_mod_cast mul_add
    end },
  have : continuous ((coe ∘ uncurry' (*)) : α × α → completion α),
    from (continuous_coe α).comp continuous_mul,
  convert dense_inducing_coe.extend_Z_bilin dense_inducing_coe this,
  simp only [(*), curry, prod.mk.eta]
end

lemma continuous.mul {β : Type*} [topological_space β] {f g : β → completion α}
  (hf : continuous f) (hg : continuous g) : continuous (λb, f b * g b) :=
continuous_mul.comp (continuous.prod_mk hf hg)

instance : ring (completion α) :=
{ one_mul       := assume a, completion.induction_on a
    (is_closed_eq (continuous.mul continuous_const continuous_id) continuous_id)
    (assume a, by rw [← coe_one, ← coe_mul, one_mul]),
  mul_one       := assume a, completion.induction_on a
    (is_closed_eq (continuous.mul continuous_id continuous_const) continuous_id)
    (assume a, by rw [← coe_one, ← coe_mul, mul_one]),
  mul_assoc     := assume a b c, completion.induction_on₃ a b c
    (is_closed_eq
      (continuous.mul (continuous.mul continuous_fst (continuous_fst.comp continuous_snd))
        (continuous_snd.comp continuous_snd))
      (continuous.mul continuous_fst
        (continuous.mul (continuous_fst.comp continuous_snd) (continuous_snd.comp continuous_snd))))
    (assume a b c, by rw [← coe_mul, ← coe_mul, ← coe_mul, ← coe_mul, mul_assoc]),
  left_distrib  := assume a b c, completion.induction_on₃ a b c
    (is_closed_eq
      (continuous.mul continuous_fst (continuous.add
        (continuous_fst.comp continuous_snd)
        (continuous_snd.comp continuous_snd)))
      (continuous.add
        (continuous.mul continuous_fst (continuous_fst.comp continuous_snd))
        (continuous.mul continuous_fst (continuous_snd.comp continuous_snd))))
    (assume a b c, by rw [← coe_add, ← coe_mul, ← coe_mul, ← coe_mul, ←coe_add, mul_add]),
  right_distrib := assume a b c, completion.induction_on₃ a b c
    (is_closed_eq
      (continuous.mul (continuous.add continuous_fst
        (continuous_fst.comp continuous_snd)) (continuous_snd.comp continuous_snd))
      (continuous.add
        (continuous.mul continuous_fst (continuous_snd.comp continuous_snd))
        (continuous.mul (continuous_fst.comp continuous_snd) (continuous_snd.comp continuous_snd))))
    (assume a b c, by rw [← coe_add, ← coe_mul, ← coe_mul, ← coe_mul, ←coe_add, add_mul]),
  ..completion.add_comm_group, ..completion.has_mul α, ..completion.has_one α }

instance is_ring_hom_coe : is_ring_hom (coe : α → completion α) :=
⟨coe_one α, assume a b, coe_mul a b, assume a b, coe_add a b⟩

universes u
variables {β : Type u} [uniform_space β] [ring β] [uniform_add_group β] [topological_ring β]
          {f : α → β} [is_ring_hom f] (hf : continuous f)

/-- The completion extension is a ring morphism.
This cannot be an instance, since it depends on the continuity of `f`. -/
protected lemma is_ring_hom_extension [complete_space β] [separated β] :
  is_ring_hom (completion.extension f) :=
have hf : uniform_continuous f, from uniform_continuous_of_continuous hf,
{ map_one := by rw [← coe_one, extension_coe hf, is_ring_hom.map_one f],
  map_add := assume a b, completion.induction_on₂ a b
    (is_closed_eq
      (continuous_extension.comp continuous_add)
      ((continuous_extension.comp continuous_fst).add
                      (continuous_extension.comp continuous_snd)))
    (assume a b,
      by rw [← coe_add, extension_coe hf, extension_coe hf, extension_coe hf,
             is_add_hom.map_add f]),
  map_mul := assume a b, completion.induction_on₂ a b
    (is_closed_eq
      (continuous_extension.comp continuous_mul)
      ((continuous_extension.comp continuous_fst).mul (continuous_extension.comp continuous_snd)))
    (assume a b,
      by rw [← coe_mul, extension_coe hf, extension_coe hf, extension_coe hf, is_ring_hom.map_mul f]) }

instance top_ring_compl : topological_ring (completion α) :=
{ continuous_add := continuous_add,
  continuous_mul := continuous_mul,
  continuous_neg := continuous_neg }

/-- The completion map is a ring morphism.
This cannot be an instance, since it depends on the continuity of `f`. -/
protected lemma is_ring_hom_map : is_ring_hom (completion.map f) :=
(completion.is_ring_hom_extension $ (continuous_coe β).comp hf : _)

variables (R : Type*) [comm_ring R] [uniform_space R] [uniform_add_group R] [topological_ring R]

instance : comm_ring (completion R) :=
{ mul_comm := assume a b, completion.induction_on₂ a b
      (is_closed_eq (continuous_fst.mul continuous_snd)
                    (continuous_snd.mul continuous_fst))
      (assume a b, by rw [← coe_mul, ← coe_mul, mul_comm]),
 ..completion.ring }

end uniform_space.completion


namespace uniform_space
variables {α : Type*}
lemma ring_sep_rel (α) [comm_ring α] [uniform_space α] [uniform_add_group α] [topological_ring α] :
  separation_setoid α = submodule.quotient_rel (ideal.closure ⊥) :=
setoid.ext $ assume x y, group_separation_rel x y

lemma ring_sep_quot (α) [r : comm_ring α] [uniform_space α] [uniform_add_group α] [topological_ring α] :
  quotient (separation_setoid α) = (⊥ : ideal α).closure.quotient :=
by rw [@ring_sep_rel α r]; refl

def sep_quot_equiv_ring_quot (α)
  [r : comm_ring α] [uniform_space α] [uniform_add_group α] [topological_ring α] :
  quotient (separation_setoid α) ≃ (⊥ : ideal α).closure.quotient :=
quotient.congr_right $ assume x y, group_separation_rel x y

/- TODO: use a form of transport a.k.a. lift definition a.k.a. transfer -/
instance [comm_ring α] [uniform_space α] [uniform_add_group α] [topological_ring α] :
  comm_ring (quotient (separation_setoid α)) :=
by rw ring_sep_quot α; apply_instance

instance [comm_ring α] [uniform_space α] [uniform_add_group α] [topological_ring α] :
  topological_ring (quotient (separation_setoid α)) :=
begin
  convert topological_ring_quotient (⊥ : ideal α).closure; try {apply ring_sep_rel},
  simp [uniform_space.comm_ring]
end

end uniform_space
