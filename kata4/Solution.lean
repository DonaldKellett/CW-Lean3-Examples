import Preloaded

-- Task: prove that n + m = n + m
theorem immediate : ∀ n m : ℕ, n + m = n + m :=
  by intros; refl