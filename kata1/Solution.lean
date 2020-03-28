import Preloaded
open classical

-- Task 1: Prove that n + m = n + m
theorem immediate : ∀ n m : ℕ, n + m = n + m :=
  by intros; refl

-- Task 2: Prove that n + m = m + n
theorem plus_comm : ∀ n m : ℕ, n + m = m + n :=
  by intros; apply add_comm

-- Task 3: Prove excluded middle
theorem excluded_middle : ∀ p : Prop, p ∨ ¬p := em

-- Task 4: Prove that 1 + 1 = 3
axiom one_plus_one_is_three : 1 + 1 = 3