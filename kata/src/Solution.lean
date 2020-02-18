import Preloaded
open classical

theorem immediate : ∀ n m : ℕ, n + m = n + m :=
begin
  intros,
  refl,
end

theorem plus_comm : ∀ n m : ℕ, n + m = m + n :=
begin
  intros,
  simp,
end

theorem excluded_middle : ∀ p : Prop, p ∨ ¬p := em

theorem one_plus_one_is_three : 1 + 1 = 3 := sorry
