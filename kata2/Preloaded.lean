-- Task 1: no axioms required
def TASK_1 := ∀ n m : ℕ, n + m = n + m
notation `TASK_1` := TASK_1

-- Task 2: using `simp` introduces `propext`
def TASK_2 := ∀ n m : ℕ, n + m = m + n
notation `TASK_2` := TASK_2

-- Task 3: requires all 3 core axioms
def TASK_3 := ∀ p : Prop, p ∨ ¬p
notation `TASK_3` := TASK_3

-- Task 4: unprovable
def TASK_4 := 1 + 1 = 3
notation `TASK_4` := TASK_4