-- No axioms required
def GOAL1 := ∀ n m : ℕ, n + m = n + m
notation `GOAL1` := GOAL1

-- Using `simp` introduces `propext`
def GOAL2 := ∀ n m : ℕ, n + m = m + n
notation `GOAL2` := GOAL2

-- Requires all 3 core axioms
def GOAL3 := ∀ p : Prop, p ∨ ¬p
notation `GOAL3` := GOAL3

-- Unprovable
def GOAL4 := 1 + 1 = 3
notation `GOAL4` := GOAL4