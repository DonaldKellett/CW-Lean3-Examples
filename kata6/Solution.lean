import Preloaded set_theory.cardinal

noncomputable theorem mathlib_example : ℕ ≃ ℤ :=
  by apply classical.choice; rw [← cardinal.eq,
  cardinal.mk_nat, cardinal.mk_int]