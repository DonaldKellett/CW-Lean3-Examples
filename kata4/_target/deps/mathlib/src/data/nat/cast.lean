/-
Copyright (c) 2014 Mario Carneiro. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mario Carneiro

Natural homomorphism from the natural numbers into a monoid with one.
-/
import tactic.interactive algebra.order algebra.ordered_group algebra.ring
import tactic.norm_cast

namespace nat
variables {α : Type*}

section
variables [has_zero α] [has_one α] [has_add α]

/-- Canonical homomorphism from `ℕ` to a type `α` with `0`, `1` and `+`. -/
protected def cast : ℕ → α
| 0     := 0
| (n+1) := cast n + 1

@[priority 10] instance cast_coe : has_coe ℕ α := ⟨nat.cast⟩

@[simp, squash_cast] theorem cast_zero : ((0 : ℕ) : α) = 0 := rfl

theorem cast_add_one (n : ℕ) : ((n + 1 : ℕ) : α) = n + 1 := rfl
@[simp, move_cast] theorem cast_succ (n : ℕ) : ((succ n : ℕ) : α) = n + 1 := rfl
end

@[simp, squash_cast] theorem cast_one [add_monoid α] [has_one α] : ((1 : ℕ) : α) = 1 := zero_add _

@[simp, move_cast] theorem cast_add [add_monoid α] [has_one α] (m) : ∀ n, ((m + n : ℕ) : α) = m + n
| 0     := (add_zero _).symm
| (n+1) := show ((m + n : ℕ) : α) + 1 = m + (n + 1), by rw [cast_add n, add_assoc]

instance [add_monoid α] [has_one α] : is_add_monoid_hom (coe : ℕ → α) :=
{ map_zero := cast_zero, map_add := cast_add }

@[simp, squash_cast, move_cast] theorem cast_bit0 [add_monoid α] [has_one α] (n : ℕ) : ((bit0 n : ℕ) : α) = bit0 n := cast_add _ _

@[simp, squash_cast, move_cast] theorem cast_bit1 [add_monoid α] [has_one α] (n : ℕ) : ((bit1 n : ℕ) : α) = bit1 n :=
by rw [bit1, cast_add_one, cast_bit0]; refl

lemma cast_two {α : Type*} [semiring α] : ((2 : ℕ) : α) = 2 := by simp

@[simp, move_cast] theorem cast_pred [add_group α] [has_one α] : ∀ {n}, 0 < n → ((n - 1 : ℕ) : α) = n - 1
| (n+1) h := (add_sub_cancel (n:α) 1).symm

@[simp, move_cast] theorem cast_sub [add_group α] [has_one α] {m n} (h : m ≤ n) : ((n - m : ℕ) : α) = n - m :=
eq_sub_of_add_eq $ by rw [← cast_add, nat.sub_add_cancel h]

@[simp, move_cast] theorem cast_mul [semiring α] (m) : ∀ n, ((m * n : ℕ) : α) = m * n
| 0     := (mul_zero _).symm
| (n+1) := (cast_add _ _).trans $
show ((m * n : ℕ) : α) + m = m * (n + 1), by rw [cast_mul n, left_distrib, mul_one]

instance [semiring α] : is_semiring_hom (coe : ℕ → α) :=
by refine_struct {..}; simp

theorem mul_cast_comm [semiring α] (a : α) (n : ℕ) : a * n = n * a :=
by induction n; simp [left_distrib, right_distrib, *]

@[simp] theorem cast_nonneg [linear_ordered_semiring α] : ∀ n : ℕ, 0 ≤ (n : α)
| 0     := le_refl _
| (n+1) := add_nonneg (cast_nonneg n) zero_le_one

@[simp, elim_cast] theorem cast_le [linear_ordered_semiring α] : ∀ {m n : ℕ}, (m : α) ≤ n ↔ m ≤ n
| 0     n     := by simp [zero_le]
| (m+1) 0     := by simpa [not_succ_le_zero] using
  lt_add_of_lt_of_nonneg zero_lt_one (@cast_nonneg α _ m)
| (m+1) (n+1) := (add_le_add_iff_right 1).trans $
  (@cast_le m n).trans $ (add_le_add_iff_right 1).symm

@[simp, elim_cast] theorem cast_lt [linear_ordered_semiring α] {m n : ℕ} : (m : α) < n ↔ m < n :=
by simpa [-cast_le] using not_congr (@cast_le α _ n m)

@[simp] theorem cast_pos [linear_ordered_semiring α] {n : ℕ} : (0 : α) < n ↔ 0 < n :=
by rw [← cast_zero, cast_lt]

lemma cast_add_one_pos [linear_ordered_semiring α] (n : ℕ) : 0 < (n : α) + 1 :=
  add_pos_of_nonneg_of_pos n.cast_nonneg zero_lt_one

theorem eq_cast [add_monoid α] [has_one α] (f : ℕ → α)
  (H0 : f 0 = 0) (H1 : f 1 = 1)
  (Hadd : ∀ x y, f (x + y) = f x + f y) : ∀ n : ℕ, f n = n
| 0     := H0
| (n+1) := by rw [Hadd, H1, eq_cast]; refl

theorem eq_cast' [add_group α] [has_one α] (f : ℕ → α)
  (H1 : f 1 = 1) (Hadd : ∀ x y, f (x + y) = f x + f y) : ∀ n : ℕ, f n = n :=
eq_cast _ (by rw [← add_left_inj (f 0), add_zero, ← Hadd]) H1 Hadd

@[simp, squash_cast] theorem cast_id (n : ℕ) : ↑n = n :=
(eq_cast id rfl rfl (λ _ _, rfl) n).symm

@[simp, move_cast] theorem cast_min [decidable_linear_ordered_semiring α] {a b : ℕ} : (↑(min a b) : α) = min a b :=
by by_cases a ≤ b; simp [h, min]

@[simp, move_cast] theorem cast_max [decidable_linear_ordered_semiring α] {a b : ℕ} : (↑(max a b) : α) = max a b :=
by by_cases a ≤ b; simp [h, max]

@[simp, elim_cast] theorem abs_cast [decidable_linear_ordered_comm_ring α] (a : ℕ) : abs (a : α) = a :=
abs_of_nonneg (cast_nonneg a)

end nat

section semiring_hom
variables {α : Type*} {β : Type*} [semiring α] [semiring β]

lemma is_semiring_hom.map_nat_cast (f : α → β) [is_semiring_hom f] :
  ∀ (n : ℕ), f n = n
| 0     := by simp [is_semiring_hom.map_zero f]
| (n+1) := by simp [is_semiring_hom.map_add f, is_semiring_hom.map_one f,
  is_semiring_hom.map_nat_cast n]

@[simp] lemma ring_hom.map_nat_cast (f : α →+* β) (n : ℕ) : f (n : α) = n :=
is_semiring_hom.map_nat_cast _ _

end semiring_hom
