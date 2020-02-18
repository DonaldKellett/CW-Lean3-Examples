/-
Copyright (c) 2018 Ellen Arlt. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ellen Arlt, Blair Shi, Sean Leather, Mario Carneiro, Johan Commelin

Matrices
-/
import algebra.module algebra.pi_instances
import data.fintype

universes u v w

def matrix (m n : Type u) [fintype m] [fintype n] (α : Type v) : Type (max u v) :=
m → n → α

namespace matrix
variables {l m n o : Type u} [fintype l] [fintype m] [fintype n] [fintype o]
variables {α : Type v}

section ext
variables {M N : matrix m n α}

theorem ext_iff : (∀ i j, M i j = N i j) ↔ M = N :=
⟨λ h, funext $ λ i, funext $ h i, λ h, by simp [h]⟩

@[ext] theorem ext : (∀ i j, M i j = N i j) → M = N :=
ext_iff.mp

end ext

def transpose (M : matrix m n α) : matrix n m α
| x y := M y x

localized "postfix `ᵀ`:1500 := matrix.transpose" in matrix

def col (w : m → α) : matrix m punit α
| x y := w x

def row (v : n → α) : matrix punit n α
| x y := v y

instance [inhabited α] : inhabited (matrix m n α) := pi.inhabited _
instance [has_add α] : has_add (matrix m n α) := pi.has_add
instance [add_semigroup α] : add_semigroup (matrix m n α) := pi.add_semigroup
instance [add_comm_semigroup α] : add_comm_semigroup (matrix m n α) := pi.add_comm_semigroup
instance [has_zero α] : has_zero (matrix m n α) := pi.has_zero
instance [add_monoid α] : add_monoid (matrix m n α) := pi.add_monoid
instance [add_comm_monoid α] : add_comm_monoid (matrix m n α) := pi.add_comm_monoid
instance [has_neg α] : has_neg (matrix m n α) := pi.has_neg
instance [add_group α] : add_group (matrix m n α) := pi.add_group
instance [add_comm_group α] : add_comm_group (matrix m n α) := pi.add_comm_group

@[simp] theorem zero_val [has_zero α] (i j) : (0 : matrix m n α) i j = 0 := rfl
@[simp] theorem neg_val [has_neg α] (M : matrix m n α) (i j) : (- M) i j = - M i j := rfl
@[simp] theorem add_val [has_add α] (M N : matrix m n α) (i j) : (M + N) i j = M i j + N i j := rfl

section diagonal
variables [decidable_eq n]

def diagonal [has_zero α] (d : n → α) : matrix n n α := λ i j, if i = j then d i else 0

@[simp] theorem diagonal_val_eq [has_zero α] {d : n → α} (i : n) : (diagonal d) i i = d i :=
by simp [diagonal]

@[simp] theorem diagonal_val_ne [has_zero α] {d : n → α} {i j : n} (h : i ≠ j) :
  (diagonal d) i j = 0 := by simp [diagonal, h]

theorem diagonal_val_ne' [has_zero α] {d : n → α} {i j : n} (h : j ≠ i) :
  (diagonal d) i j = 0 := diagonal_val_ne h.symm

@[simp] theorem diagonal_zero [has_zero α] : (diagonal (λ _, 0) : matrix n n α) = 0 :=
by simp [diagonal]; refl

section one
variables [has_zero α] [has_one α]

instance : has_one (matrix n n α) := ⟨diagonal (λ _, 1)⟩

@[simp] theorem diagonal_one : (diagonal (λ _, 1) : matrix n n α) = 1 := rfl

theorem one_val {i j} : (1 : matrix n n α) i j = if i = j then 1 else 0 := rfl

@[simp] theorem one_val_eq (i) : (1 : matrix n n α) i i = 1 := diagonal_val_eq i

@[simp] theorem one_val_ne {i j} : i ≠ j → (1 : matrix n n α) i j = 0 :=
diagonal_val_ne

theorem one_val_ne' {i j} : j ≠ i → (1 : matrix n n α) i j = 0 :=
diagonal_val_ne'

end one
end diagonal

@[simp] theorem diagonal_add [decidable_eq n] [add_monoid α] (d₁ d₂ : n → α) :
  diagonal d₁ + diagonal d₂ = diagonal (λ i, d₁ i + d₂ i) :=
by ext i j; by_cases i = j; simp [h]

protected def mul [has_mul α] [add_comm_monoid α] (M : matrix l m α) (N : matrix m n α) :
  matrix l n α :=
λ i k, finset.univ.sum (λ j, M i j * N j k)

localized "infixl ` ⬝ `:75 := matrix.mul" in matrix

theorem mul_val [has_mul α] [add_comm_monoid α] {M : matrix l m α} {N : matrix m n α} {i k} :
  (M ⬝ N) i k = finset.univ.sum (λ j, M i j * N j k) := rfl

local attribute [simp] mul_val

instance [has_mul α] [add_comm_monoid α] : has_mul (matrix n n α) := ⟨matrix.mul⟩

@[simp] theorem mul_eq_mul [has_mul α] [add_comm_monoid α] (M N : matrix n n α) :
  M * N = M ⬝ N := rfl

theorem mul_val' [has_mul α] [add_comm_monoid α] {M N : matrix n n α} {i k} :
  (M * N) i k = finset.univ.sum (λ j, M i j * N j k) := rfl

section semigroup
variables [semiring α]

protected theorem mul_assoc (L : matrix l m α) (M : matrix m n α) (N : matrix n o α) :
  (L ⬝ M) ⬝ N = L ⬝ (M ⬝ N) :=
by classical; funext i k;
   simp [finset.mul_sum, finset.sum_mul, mul_assoc];
   rw finset.sum_comm

instance : semigroup (matrix n n α) :=
{ mul_assoc := matrix.mul_assoc, ..matrix.has_mul }

end semigroup

@[simp] theorem diagonal_neg [decidable_eq n] [add_group α] (d : n → α) :
  -diagonal d = diagonal (λ i, -d i) :=
by ext i j; by_cases i = j; simp [h]

section semiring
variables [semiring α]

@[simp] protected theorem mul_zero (M : matrix m n α) : M ⬝ (0 : matrix n o α) = 0 :=
by ext i j; simp

@[simp] protected theorem zero_mul (M : matrix m n α) : (0 : matrix l m α) ⬝ M = 0 :=
by ext i j; simp

protected theorem mul_add (L : matrix m n α) (M N : matrix n o α) : L ⬝ (M + N) = L ⬝ M + L ⬝ N :=
by ext i j; simp [finset.sum_add_distrib, mul_add]

protected theorem add_mul (L M : matrix l m α) (N : matrix m n α) : (L + M) ⬝ N = L ⬝ N + M ⬝ N :=
by ext i j; simp [finset.sum_add_distrib, add_mul]

@[simp] theorem diagonal_mul [decidable_eq m]
  (d : m → α) (M : matrix m n α) (i j) : (diagonal d).mul M i j = d i * M i j :=
by simp; rw finset.sum_eq_single i; simp [diagonal_val_ne'] {contextual := tt}

@[simp] theorem mul_diagonal [decidable_eq n]
  (d : n → α) (M : matrix m n α) (i j) : (M ⬝ diagonal d) i j = M i j * d j :=
by simp; rw finset.sum_eq_single j; simp {contextual := tt}

@[simp] protected theorem one_mul [decidable_eq m] (M : matrix m n α) : (1 : matrix m m α) ⬝ M = M :=
by ext i j; rw [← diagonal_one, diagonal_mul, one_mul]

@[simp] protected theorem mul_one [decidable_eq n] (M : matrix m n α) : M ⬝ (1 : matrix n n α) = M :=
by ext i j; rw [← diagonal_one, mul_diagonal, mul_one]

instance [decidable_eq n] : monoid (matrix n n α) :=
{ one_mul := matrix.one_mul,
  mul_one := matrix.mul_one,
  ..matrix.has_one, ..matrix.semigroup }

instance [decidable_eq n] : semiring (matrix n n α) :=
{ mul_zero := matrix.mul_zero,
  zero_mul := matrix.zero_mul,
  left_distrib := matrix.mul_add,
  right_distrib := matrix.add_mul,
  ..matrix.add_comm_monoid,
  ..matrix.monoid }

@[simp] theorem diagonal_mul_diagonal [decidable_eq n] (d₁ d₂ : n → α) :
  (diagonal d₁) ⬝ (diagonal d₂) = diagonal (λ i, d₁ i * d₂ i) :=
by ext i j; by_cases i = j; simp [h]

theorem diagonal_mul_diagonal' [decidable_eq n] (d₁ d₂ : n → α) :
  diagonal d₁ * diagonal d₂ = diagonal (λ i, d₁ i * d₂ i) :=
diagonal_mul_diagonal _ _

lemma is_add_monoid_hom_mul_left (M : matrix l m α) :
  is_add_monoid_hom (λ x : matrix m n α, M ⬝ x) :=
{ to_is_add_hom := ⟨matrix.mul_add _⟩, map_zero := matrix.mul_zero _ }

lemma is_add_monoid_hom_mul_right (M : matrix m n α) :
  is_add_monoid_hom (λ x : matrix l m α, x ⬝ M) :=
{ to_is_add_hom := ⟨λ _ _, matrix.add_mul _ _ _⟩, map_zero := matrix.zero_mul _ }

protected lemma sum_mul {β : Type*} (s : finset β) (f : β → matrix l m α)
  (M : matrix m n α) : s.sum f ⬝ M = s.sum (λ a, f a ⬝ M) :=
(@finset.sum_hom _ _ _ _ _ s f (λ x, x ⬝ M)
/- This line does not type-check without `id` and `: _`. Lean did not recognize that two different
  `add_monoid` instances were def-eq -/
  (id (@is_add_monoid_hom_mul_right l _ _ _ _ _ _ _ M) : _)).symm

protected lemma mul_sum {β : Type*} (s : finset β) (f : β → matrix m n α)
  (M : matrix l m α) :  M ⬝ s.sum f = s.sum (λ a, M ⬝ f a) :=
(@finset.sum_hom _ _ _ _ _ s f (λ x, M ⬝ x)
/- This line does not type-check without `id` and `: _`. Lean did not recognize that two different
  `add_monoid` instances were def-eq -/
  (id (@is_add_monoid_hom_mul_left _ _ n _ _ _ _ _ M) : _)).symm

end semiring

section ring
variables [ring α]

@[simp] theorem neg_mul (M : matrix m n α) (N : matrix n o α) :
  (-M) ⬝ N = -(M ⬝ N) := by ext; simp [matrix.mul]

@[simp] theorem mul_neg (M : matrix m n α) (N : matrix n o α) :
  M ⬝ (-N) = -(M ⬝ N) := by ext; simp [matrix.mul]

end ring

instance [decidable_eq n] [ring α] : ring (matrix n n α) :=
{ ..matrix.add_comm_group, ..matrix.semiring }

instance [semiring α] : has_scalar α (matrix m n α) := pi.has_scalar
instance {β : Type w} [ring α] [add_comm_group β] [module α β] :
  module α (matrix m n β) := pi.module _

@[simp] lemma smul_val [semiring α] (a : α) (A : matrix m n α) (i : m) (j : n) : (a • A) i j = a * A i j := rfl

section comm_ring
variables [comm_ring α]

lemma smul_eq_diagonal_mul [decidable_eq m] (M : matrix m n α) (a : α) :
  a • M = diagonal (λ _, a) ⬝ M :=
by { ext, simp }

lemma smul_eq_mul_diagonal [decidable_eq n] (M : matrix m n α) (a : α) :
  a • M = M ⬝ diagonal (λ _, a) :=
by { ext, simp [mul_comm] }

@[simp] lemma mul_smul (M : matrix m n α) (a : α) (N : matrix n l α) : M ⬝ (a • N) = a • M ⬝ N :=
begin
  ext i j,
  unfold matrix.mul has_scalar.smul,
  rw finset.mul_sum,
  congr,
  ext,
  ac_refl
end

@[simp] lemma smul_mul (M : matrix m n α) (a : α) (N : matrix n l α) : (a • M) ⬝ N = a • M ⬝ N :=
begin
  ext i j,
  unfold matrix.mul has_scalar.smul,
  rw finset.mul_sum,
  congr,
  ext,
  ac_refl
end

end comm_ring

section semiring
variables [semiring α]

def vec_mul_vec (w : m → α) (v : n → α) : matrix m n α
| x y := w x * v y

def mul_vec (M : matrix m n α) (v : n → α) : m → α
| x := finset.univ.sum (λy:n, M x y * v y)

def vec_mul (v : m → α) (M : matrix m n α) : n → α
| y := finset.univ.sum (λx:m, v x * M x y)

instance mul_vec.is_add_monoid_hom_left (v : n → α) :
  is_add_monoid_hom (λM:matrix m n α, mul_vec M v) :=
{ map_zero := by ext; simp [mul_vec]; refl,
  map_add :=
  begin
    intros x y,
    ext m,
    rw pi.add_apply (mul_vec x v) (mul_vec y v) m,
    simp [mul_vec, finset.sum_add_distrib, right_distrib]
  end }

lemma mul_vec_diagonal [decidable_eq m] (v w : m → α) (x : m) :
  mul_vec (diagonal v) w x = v x * w x :=
begin
  transitivity,
  refine finset.sum_eq_single x _ _,
  { assume b _ ne, simp [diagonal, ne.symm] },
  { simp },
  { rw [diagonal_val_eq] }
end

@[simp] lemma mul_vec_one [decidable_eq m] (v : m → α) : mul_vec 1 v = v :=
by { ext, rw [←diagonal_one, mul_vec_diagonal, one_mul] }

lemma vec_mul_vec_eq (w : m → α) (v : n → α) :
  vec_mul_vec w v = (col w) ⬝ (row v) :=
by simp [matrix.mul]; refl

end semiring

section transpose

open_locale matrix

/--
  Tell `simp` what the entries are in a transposed matrix.

  Compare with `mul_val`, `diagonal_val_eq`, etc.
-/
@[simp] lemma transpose_val (M : matrix m n α) (i j) : M.transpose j i = M i j := rfl

@[simp] lemma transpose_transpose (M : matrix m n α) :
  Mᵀᵀ = M :=
by ext; refl

@[simp] lemma transpose_zero [has_zero α] : (0 : matrix m n α)ᵀ = 0 :=
by ext i j; refl

@[simp] lemma transpose_one [decidable_eq n] [has_zero α] [has_one α] : (1 : matrix n n α)ᵀ = 1 :=
begin
  ext i j,
  unfold has_one.one transpose,
  by_cases i = j,
  { simp only [h, diagonal_val_eq] },
  { simp only [diagonal_val_ne h, diagonal_val_ne (λ p, h (symm p))] }
end

@[simp] lemma transpose_add [has_add α] (M : matrix m n α) (N : matrix m n α) :
  (M + N)ᵀ = Mᵀ + Nᵀ  :=
by { ext i j, simp }

@[simp] lemma transpose_mul [comm_ring α] (M : matrix m n α) (N : matrix n l α) :
  (M ⬝ N)ᵀ = Nᵀ ⬝ Mᵀ  :=
begin
  ext i j,
  unfold matrix.mul transpose,
  congr,
  ext,
  ac_refl
end

@[simp] lemma transpose_smul [comm_ring α] (c : α)(M : matrix m n α) :
  (c • M)ᵀ = c • Mᵀ := 
by { ext i j, refl }

@[simp] lemma transpose_neg [comm_ring α] (M : matrix m n α) :
  (- M)ᵀ = - Mᵀ  :=
by ext i j; refl

end transpose

def minor (A : matrix m n α) (row : l → m) (col : o → n) : matrix l o α :=
λ i j, A (row i) (col j)

@[reducible]
def sub_left {m l r : nat} (A : matrix (fin m) (fin (l + r)) α) : matrix (fin m) (fin l) α :=
minor A id (fin.cast_add r)

@[reducible]
def sub_right {m l r : nat} (A : matrix (fin m) (fin (l + r)) α) : matrix (fin m) (fin r) α :=
minor A id (fin.nat_add l)

@[reducible]
def sub_up {d u n : nat} (A : matrix (fin (u + d)) (fin n) α) : matrix (fin u) (fin n) α :=
minor A (fin.cast_add d) id

@[reducible]
def sub_down {d u n : nat} (A : matrix (fin (u + d)) (fin n) α) : matrix (fin d) (fin n) α :=
minor A (fin.nat_add u) id

@[reducible]
def sub_up_right {d u l r : nat} (A: matrix (fin (u + d)) (fin (l + r)) α) :
  matrix (fin u) (fin r) α :=
sub_up (sub_right A)

@[reducible]
def sub_down_right {d u l r : nat} (A : matrix (fin (u + d)) (fin (l + r)) α) :
  matrix (fin d) (fin r) α :=
sub_down (sub_right A)

@[reducible]
def sub_up_left {d u l r : nat} (A : matrix (fin (u + d)) (fin (l + r)) α) :
  matrix (fin u) (fin (l)) α :=
sub_up (sub_left A)

@[reducible]
def sub_down_left {d u l r : nat} (A: matrix (fin (u + d)) (fin (l + r)) α) :
  matrix (fin d) (fin (l)) α :=
sub_down (sub_left A)

end matrix
