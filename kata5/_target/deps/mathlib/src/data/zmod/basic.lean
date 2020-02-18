/-
Copyright (c) 2018 Chris Hughes. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Chris Hughes
-/

import data.int.modeq data.int.gcd data.fintype data.pnat.basic tactic.ring

/-!
# Integers mod `n`

Definition of the integers mod n, and the field structure on the integers mod p.

There are two types defined, `zmod n`, which is for integers modulo a positive nat `n : ℕ+`.
`zmodp` is the type of integers modulo a prime number, for which a field structure is defined.

## Definitions

* `val` is inherited from `fin` and returns the least natural number in the equivalence class

* `val_min_abs` returns the integer closest to zero in the equivalence class.

* A coercion `cast` is defined from `zmod n` into any semiring. This is a semiring hom if the ring has
characteristic dividing `n`

## Implentation notes

`zmod` and `zmodp` are implemented as different types so that the field instance for `zmodp` can be
synthesized. This leads to a lot of code duplication and most of the functions and theorems for
`zmod` are restated for `zmodp`
-/

open nat nat.modeq int

def zmod (n : ℕ+) := fin n

namespace zmod

instance (n : ℕ+) : has_neg (zmod n) :=
⟨λ a, ⟨nat_mod (-(a.1 : ℤ)) n,
  have h : (n : ℤ) ≠ 0 := int.coe_nat_ne_zero_iff_pos.2 n.pos,
  have h₁ : ((n : ℕ) : ℤ) = abs n := (abs_of_nonneg (int.coe_nat_nonneg n)).symm,
  by rw [← int.coe_nat_lt, nat_mod, to_nat_of_nonneg (int.mod_nonneg _ h), h₁];
    exact int.mod_lt _ h⟩⟩

instance (n : ℕ+) : add_comm_semigroup (zmod n) :=
{ add_assoc := λ ⟨a, ha⟩ ⟨b, hb⟩ ⟨c, hc⟩, fin.eq_of_veq
    (show ((a + b) % n + c) ≡ (a + (b + c) % n) [MOD n],
    from calc ((a + b) % n + c) ≡ a + b + c [MOD n] : modeq_add (nat.mod_mod _ _) rfl
      ... ≡ a + (b + c) [MOD n] : by rw add_assoc
      ... ≡ (a + (b + c) % n) [MOD n] : modeq_add rfl (nat.mod_mod _ _).symm),
  add_comm := λ ⟨a, _⟩ ⟨b, _⟩, fin.eq_of_veq (show (a + b) % n = (b + a) % n, by rw add_comm),
  ..fin.has_add }

instance (n : ℕ+) : comm_semigroup (zmod n) :=
{ mul_assoc := λ ⟨a, ha⟩ ⟨b, hb⟩ ⟨c, hc⟩, fin.eq_of_veq
    (calc ((a * b) % n * c) ≡ a * b * c [MOD n] : modeq_mul (nat.mod_mod _ _) rfl
      ... ≡ a * (b * c) [MOD n] : by rw mul_assoc
      ... ≡ a * (b * c % n) [MOD n] : modeq_mul rfl (nat.mod_mod _ _).symm),
  mul_comm := λ ⟨a, _⟩ ⟨b, _⟩, fin.eq_of_veq (show (a * b) % n = (b * a) % n, by rw mul_comm),
  ..fin.has_mul }

instance (n : ℕ+) : has_one (zmod n) := ⟨⟨(1 % n), nat.mod_lt _ n.pos⟩⟩

instance (n : ℕ+) : has_zero (zmod n) := ⟨⟨0, n.pos⟩⟩

instance (n : ℕ+) : inhabited (zmod n) := ⟨0⟩

instance zmod_one.subsingleton : subsingleton (zmod 1) :=
⟨λ a b, fin.eq_of_veq (by rw [eq_zero_of_le_zero (le_of_lt_succ a.2),
  eq_zero_of_le_zero (le_of_lt_succ b.2)])⟩

lemma add_val {n : ℕ+} : ∀ a b : zmod n, (a + b).val = (a.val + b.val) % n
| ⟨_, _⟩ ⟨_, _⟩ := rfl

lemma mul_val {n : ℕ+} :  ∀ a b : zmod n, (a * b).val = (a.val * b.val) % n
| ⟨_, _⟩ ⟨_, _⟩ := rfl

lemma one_val {n : ℕ+} : (1 : zmod n).val = 1 % n := rfl

@[simp] lemma zero_val (n : ℕ+) : (0 : zmod n).val = 0 := rfl

private lemma one_mul_aux (n : ℕ+) (a : zmod n) : (1 : zmod n) * a = a :=
begin
  cases n with n hn,
  cases n with n,
  { exact (lt_irrefl _ hn).elim },
  { cases n with n,
    { exact @subsingleton.elim (zmod 1) _ _ _ },
    { have h₁ : a.1 % n.succ.succ = a.1 := nat.mod_eq_of_lt a.2,
      have h₂ : 1 % n.succ.succ = 1 := nat.mod_eq_of_lt dec_trivial,
      refine fin.eq_of_veq _,
      simp [mul_val, one_val, h₁, h₂] } }
end

private lemma left_distrib_aux (n : ℕ+) : ∀ a b c : zmod n, a * (b + c) = a * b + a * c :=
λ ⟨a, ha⟩ ⟨b, hb⟩ ⟨c, hc⟩, fin.eq_of_veq
(calc a * ((b + c) % n) ≡ a * (b + c) [MOD n] : modeq_mul rfl (nat.mod_mod _ _)
  ... ≡ a * b + a * c [MOD n] : by rw mul_add
  ... ≡ (a * b) % n + (a * c) % n [MOD n] : modeq_add (nat.mod_mod _ _).symm (nat.mod_mod _ _).symm)

instance (n : ℕ+) : comm_ring (zmod n) :=
{ zero_add := λ ⟨a, ha⟩, fin.eq_of_veq (show (0 + a) % n = a, by rw zero_add; exact nat.mod_eq_of_lt ha),
  add_zero := λ ⟨a, ha⟩, fin.eq_of_veq (nat.mod_eq_of_lt ha),
  add_left_neg :=
    λ ⟨a, ha⟩, fin.eq_of_veq (show (((-a : ℤ) % n).to_nat + a) % n = 0,
      from int.coe_nat_inj
      begin
        have hn : (n : ℤ) ≠ 0 := (ne_of_lt (int.coe_nat_lt.2 n.pos)).symm,
        rw [int.coe_nat_mod, int.coe_nat_add, to_nat_of_nonneg (int.mod_nonneg _ hn), add_comm],
        simp,
      end),
  one_mul := one_mul_aux n,
  mul_one := λ a, by rw mul_comm; exact one_mul_aux n a,
  left_distrib := left_distrib_aux n,
  right_distrib := λ a b c, by rw [mul_comm, left_distrib_aux, mul_comm _ b, mul_comm]; refl,
  ..zmod.has_zero n,
  ..zmod.has_one n,
  ..zmod.has_neg n,
  ..zmod.add_comm_semigroup n,
  ..zmod.comm_semigroup n }

lemma val_cast_nat {n : ℕ+} (a : ℕ) : (a : zmod n).val = a % n :=
begin
  induction a with a ih,
  { rw [nat.zero_mod]; refl },
  { rw [succ_eq_add_one, nat.cast_add, add_val, ih],
    show (a % n + ((0 + (1 % n)) % n)) % n = (a + 1) % n,
    rw [zero_add, nat.mod_mod],
    exact nat.modeq.modeq_add (nat.mod_mod a n) (nat.mod_mod 1 n) }
end

lemma neg_val' {m : pnat} (n : zmod m) : (-n).val = (m - n.val) % m :=
have ((-n).val + n.val) % m = (m - n.val + n.val) % m,
  by { rw [←add_val, add_left_neg, nat.sub_add_cancel (le_of_lt n.is_lt), nat.mod_self], refl },
(nat.mod_eq_of_lt (fin.is_lt _)).symm.trans (nat.modeq.modeq_add_cancel_right rfl this)

lemma neg_val {m : pnat} (n : zmod m) : (-n).val = if n = 0 then 0 else m - n.val :=
begin
  rw neg_val',
  by_cases h : n = 0; simp [h],
  cases n with n nlt; cases n; dsimp, { contradiction },
  rw nat.mod_eq_of_lt,
  apply nat.sub_lt m.2 (nat.succ_pos _),
end

lemma mk_eq_cast {n : ℕ+} {a : ℕ} (h : a < n) : (⟨a, h⟩ : zmod n) = (a : zmod n) :=
fin.eq_of_veq (by rw [val_cast_nat, nat.mod_eq_of_lt h])

@[simp] lemma cast_self_eq_zero {n : ℕ+} : ((n : ℕ) : zmod n) = 0 :=
fin.eq_of_veq (show (n : zmod n).val = 0, by simp [val_cast_nat])

lemma val_cast_of_lt {n : ℕ+} {a : ℕ} (h : a < n) : (a : zmod n).val = a :=
by rw [val_cast_nat, nat.mod_eq_of_lt h]

@[simp] lemma cast_mod_nat (n : ℕ+) (a : ℕ) : ((a % n : ℕ) : zmod n) = a :=
by conv {to_rhs, rw ← nat.mod_add_div a n}; simp

@[simp] lemma cast_mod_nat' {n : ℕ} (hn : 0 < n) (a : ℕ) : ((a % n : ℕ) : zmod ⟨n, hn⟩) = a :=
cast_mod_nat _ _

@[simp] lemma cast_val {n : ℕ+} (a : zmod n) : (a.val : zmod n) = a :=
by cases a; simp [mk_eq_cast]

@[simp] lemma cast_mod_int (n : ℕ+) (a : ℤ) : ((a % (n : ℕ) : ℤ) : zmod n) = a :=
by conv {to_rhs, rw ← int.mod_add_div a n}; simp

@[simp] lemma cast_mod_int' {n : ℕ} (hn : 0 < n) (a : ℤ) :
  ((a % (n : ℕ) : ℤ) : zmod ⟨n, hn⟩) = a := cast_mod_int _ _

lemma val_cast_int {n : ℕ+} (a : ℤ) : (a : zmod n).val = (a % (n : ℕ)).nat_abs :=
have h : nat_abs (a % (n : ℕ)) < n := int.coe_nat_lt.1 begin
  rw [nat_abs_of_nonneg (mod_nonneg _ (int.coe_nat_ne_zero_iff_pos.2 n.pos))],
  conv {to_rhs, rw ← abs_of_nonneg (int.coe_nat_nonneg n)},
  exact int.mod_lt _ (int.coe_nat_ne_zero_iff_pos.2 n.pos)
end,
int.coe_nat_inj $
  by conv {to_lhs, rw [← cast_mod_int n a,
    ← nat_abs_of_nonneg (mod_nonneg _ (int.coe_nat_ne_zero_iff_pos.2 n.pos)),
    int.cast_coe_nat, val_cast_of_lt h] }

lemma coe_val_cast_int {n : ℕ+} (a : ℤ) : ((a : zmod n).val : ℤ) = a % (n : ℕ) :=
by rw [val_cast_int, int.nat_abs_of_nonneg (mod_nonneg _ (int.coe_nat_ne_zero_iff_pos.2 n.pos))]

lemma eq_iff_modeq_nat {n : ℕ+} {a b : ℕ} : (a : zmod n) = b ↔ a ≡ b [MOD n] :=
⟨λ h, by have := fin.veq_of_eq h;
  rwa [val_cast_nat, val_cast_nat] at this,
λ h, fin.eq_of_veq $ by rwa [val_cast_nat, val_cast_nat]⟩

lemma eq_iff_modeq_nat' {n : ℕ} (hn : 0 < n) {a b : ℕ} : (a : zmod ⟨n, hn⟩) = b ↔ a ≡ b [MOD n] :=
eq_iff_modeq_nat

lemma eq_iff_modeq_int {n : ℕ+} {a b : ℤ} : (a : zmod n) = b ↔ a ≡ b [ZMOD (n : ℕ)] :=
⟨λ h, by have := fin.veq_of_eq h;
  rwa [val_cast_int, val_cast_int, ← int.coe_nat_eq_coe_nat_iff,
    nat_abs_of_nonneg (int.mod_nonneg _ (int.coe_nat_ne_zero_iff_pos.2 n.pos)),
    nat_abs_of_nonneg (int.mod_nonneg _ (int.coe_nat_ne_zero_iff_pos.2 n.pos))] at this,
λ h : a % (n : ℕ) = b % (n : ℕ),
  by rw [← cast_mod_int n a, ← cast_mod_int n b, h]⟩

lemma eq_iff_modeq_int' {n : ℕ} (hn : 0 < n) {a b : ℤ} :
  (a : zmod ⟨n, hn⟩) = b ↔ a ≡ b [ZMOD (n : ℕ)] := eq_iff_modeq_int

lemma eq_zero_iff_dvd_nat {n : ℕ+} {a : ℕ} : (a : zmod n) = 0 ↔ (n : ℕ) ∣ a :=
by rw [← @nat.cast_zero (zmod n), eq_iff_modeq_nat, nat.modeq.modeq_zero_iff]

lemma eq_zero_iff_dvd_int {n : ℕ+} {a : ℤ} : (a : zmod n) = 0 ↔ ((n : ℕ) : ℤ) ∣ a :=
by rw [← @int.cast_zero (zmod n), eq_iff_modeq_int, int.modeq.modeq_zero_iff]

instance (n : ℕ+) : fintype (zmod n) := fin.fintype _

instance decidable_eq (n : ℕ+) : decidable_eq (zmod n) := fin.decidable_eq _

instance (n : ℕ+) : has_repr (zmod n) := fin.has_repr _

lemma card_zmod (n : ℕ+) : fintype.card (zmod n) = n := fintype.card_fin n

lemma le_div_two_iff_lt_neg {n : ℕ+} (hn : (n : ℕ) % 2 = 1)
  {x : zmod n} (hx0 : x ≠ 0) : x.1 ≤ (n / 2 : ℕ) ↔ (n / 2 : ℕ) < (-x).1 :=
have hn2 : (n : ℕ) / 2 < n := nat.div_lt_of_lt_mul ((lt_mul_iff_one_lt_left n.pos).2 dec_trivial),
have hn2' : (n : ℕ) - n / 2 = n / 2 + 1,
  by conv {to_lhs, congr, rw [← succ_sub_one n, succ_sub n.pos]};
  rw [← two_mul_odd_div_two hn, two_mul, ← succ_add, nat.add_sub_cancel],
have hxn : (n : ℕ) - x.val < n,
  begin
    rw [nat.sub_lt_iff (le_of_lt x.2) (le_refl _), nat.sub_self],
    rw ← zmod.cast_val x at hx0,
    exact nat.pos_of_ne_zero (λ h, by simpa [h] using hx0)
  end,
by conv {to_rhs, rw [← nat.succ_le_iff, succ_eq_add_one, ← hn2', ← zero_add (- x), ← zmod.cast_self_eq_zero,
  ← sub_eq_add_neg, ← zmod.cast_val x, ← nat.cast_sub (le_of_lt x.2),
  zmod.val_cast_nat, mod_eq_of_lt hxn, nat.sub_le_sub_left_iff (le_of_lt x.2)] }

lemma ne_neg_self {n : ℕ+} (hn1 : (n : ℕ) % 2 = 1) {a : zmod n} (ha : a ≠ 0) : a ≠ -a :=
λ h, have a.val ≤ n / 2 ↔ (n : ℕ) / 2 < (-a).val := le_div_two_iff_lt_neg hn1 ha,
by rwa [← h, ← not_lt, not_iff_self] at this

@[simp] lemma cast_mul_right_val_cast {n m : ℕ+} (a : ℕ) :
  ((a : zmod (m * n)).val : zmod m) = (a : zmod m) :=
zmod.eq_iff_modeq_nat.2 (by rw zmod.val_cast_nat;
  exact nat.modeq.modeq_of_modeq_mul_right _ (nat.mod_mod _ _))

@[simp] lemma cast_mul_left_val_cast {n m : ℕ+} (a : ℕ) :
  ((a : zmod (n * m)).val : zmod m) = (a : zmod m) :=
zmod.eq_iff_modeq_nat.2 (by rw zmod.val_cast_nat;
  exact nat.modeq.modeq_of_modeq_mul_left _ (nat.mod_mod _ _))

lemma cast_val_cast_of_dvd {n m : ℕ+} (h : (m : ℕ) ∣ n) (a : ℕ) :
  ((a : zmod n).val : zmod m) = (a : zmod m) :=
let ⟨k , hk⟩ := h in
zmod.eq_iff_modeq_nat.2 (nat.modeq.modeq_of_modeq_mul_right k
    (by rw [← hk, zmod.val_cast_nat]; exact nat.mod_mod _ _))

def units_equiv_coprime {n : ℕ+} : units (zmod n) ≃ {x : zmod n // nat.coprime x.1 n} :=
{ to_fun := λ x, ⟨x, nat.modeq.coprime_of_mul_modeq_one (x⁻¹).1.1 begin
    have := units.ext_iff.1 (mul_right_inv x),
    rwa [← zmod.cast_val ((1 : units (zmod n)) : zmod n), units.coe_one, zmod.one_val,
      ← zmod.cast_val ((x * x⁻¹ : units (zmod n)) : zmod n),
      units.coe_mul, zmod.mul_val, zmod.cast_mod_nat, zmod.cast_mod_nat,
      zmod.eq_iff_modeq_nat] at this
    end⟩,
  inv_fun := λ x,
    have x.val * ↑(gcd_a ((x.val).val) ↑n) = 1,
      by rw [← zmod.cast_val x.1, ← int.cast_coe_nat, ← int.cast_one, ← int.cast_mul,
          zmod.eq_iff_modeq_int, ← int.coe_nat_one, ← (show nat.gcd _ _ = _, from x.2)];
        simpa using int.modeq.gcd_a_modeq x.1.1 n,
    ⟨x.1, gcd_a x.1.1 n, this, by simpa [mul_comm] using this⟩,
  left_inv := λ ⟨_, _, _, _⟩, units.ext rfl,
  right_inv := λ ⟨_, _⟩, rfl }

/-- `val_min_abs x` returns the integer in the same equivalence class as `x` that is closest to `0`,
  The result will be in the interval `(-n/2, n/2]` -/
def val_min_abs {n : ℕ+} (x : zmod n) : ℤ :=
if x.val ≤ n / 2 then x.val else x.val - n

@[simp] lemma coe_val_min_abs {n : ℕ+} (x : zmod n) :
  (x.val_min_abs : zmod n) = x :=
by simp [zmod.val_min_abs]; split_ifs; simp

lemma nat_abs_val_min_abs_le {n : ℕ+} (x : zmod n) : x.val_min_abs.nat_abs ≤ n / 2 :=
have (x.val - n : ℤ) ≤ 0, from sub_nonpos.2 $ int.coe_nat_le.2 $ le_of_lt x.2,
begin
  rw zmod.val_min_abs,
  split_ifs with h,
  { exact h },
  { rw [← int.coe_nat_le, int.of_nat_nat_abs_of_nonpos this, neg_sub],
    conv_lhs { congr, rw [coe_coe, ← nat.mod_add_div n 2, int.coe_nat_add, int.coe_nat_mul,
      int.coe_nat_bit0, int.coe_nat_one] },
    rw ← sub_nonneg,
    suffices : (0 : ℤ) ≤ x.val - ((n % 2 : ℕ) + (n / 2 : ℕ)),
    { exact le_trans this (le_of_eq $ by ring) },
    exact sub_nonneg.2 (by rw [← int.coe_nat_add, int.coe_nat_le];
      exact calc (n : ℕ) % 2 + n / 2 ≤ 1 + n / 2 :
        add_le_add (nat.le_of_lt_succ (nat.mod_lt _ dec_trivial)) (le_refl _)
        ... ≤ x.val : by rw add_comm; exact nat.succ_le_of_lt (lt_of_not_ge h)) }
end

@[simp] lemma val_min_abs_zero {n : ℕ+} : (0 : zmod n).val_min_abs = 0 :=
by simp [zmod.val_min_abs]

@[simp] lemma val_min_abs_eq_zero {n : ℕ+} (x : zmod n) :
  x.val_min_abs = 0 ↔ x = 0 :=
⟨λ h, begin
  dsimp [zmod.val_min_abs] at h,
  split_ifs at h,
  { exact fin.eq_of_veq (by simp * at *) },
  { exact absurd h (mt sub_eq_zero.1 (ne_of_lt $ int.coe_nat_lt.2 x.2)) }
end, λ hx0, hx0.symm ▸ zmod.val_min_abs_zero⟩

lemma cast_nat_abs_val_min_abs {n : ℕ+} (a : zmod n) :
  (a.val_min_abs.nat_abs : zmod n) = if a.val ≤ (n : ℕ) / 2 then a else -a :=
have (a.val : ℤ) + -n ≤ 0, by erw [sub_nonpos, int.coe_nat_le]; exact le_of_lt a.2,
begin
  dsimp [zmod.val_min_abs],
  split_ifs,
  { simp },
  { erw [← int.cast_coe_nat, int.of_nat_nat_abs_of_nonpos this],
    simp }
end

@[simp] lemma nat_abs_val_min_abs_neg {n : ℕ+} (a : zmod n) :
  (-a).val_min_abs.nat_abs = a.val_min_abs.nat_abs :=
if haa : -a = a then by rw [haa]
else
have hpa : (n : ℕ) - a.val ≤ n / 2 ↔ (n : ℕ) / 2 < a.val,
  from suffices (((n : ℕ) % 2) + 2 * (n / 2)) - a.val ≤ (n : ℕ) / 2 ↔ (n : ℕ) / 2 < a.val,
    by rwa [nat.mod_add_div] at this,
  begin
    rw [nat.sub_le_iff, two_mul, ← add_assoc, nat.add_sub_cancel],
    cases (n : ℕ).mod_two_eq_zero_or_one with hn0 hn1,
    { split,
      { exact λ h, lt_of_le_of_ne (le_trans (nat.le_add_left _ _) h)
          begin
            assume hna,
            rw [← zmod.cast_val a, ← hna, neg_eq_iff_add_eq_zero, ← nat.cast_add,
              zmod.eq_zero_iff_dvd_nat, ← two_mul, ← zero_add (2 * _), ← hn0,
              nat.mod_add_div] at haa,
            exact haa (dvd_refl _)
          end },
      { rw [hn0, zero_add], exact le_of_lt } },
    { rw [hn1, add_comm, nat.succ_le_iff] }
  end,
have ha0 : ¬ a = 0, from λ ha0, by simp * at *,
begin
  dsimp [zmod.val_min_abs],
  rw [← not_le] at hpa,
  simp only [if_neg ha0, zmod.neg_val, hpa, int.coe_nat_sub (le_of_lt a.2)],
  split_ifs,
  { simp },
  { rw [← int.nat_abs_neg], simp }
end

lemma val_eq_ite_val_min_abs {n : ℕ+} (a : zmod n) :
  (a.val : ℤ) = a.val_min_abs + if a.val ≤ n / 2 then 0 else n :=
by simp [zmod.val_min_abs]; split_ifs; simp

lemma neg_eq_self_mod_two : ∀ (a : zmod 2), -a = a := dec_trivial

@[simp] lemma nat_abs_mod_two (a : ℤ) : (a.nat_abs : zmod 2) = a :=
by cases a; simp [zmod.neg_eq_self_mod_two]

section
variables {α : Type*} [has_zero α] [has_one α] [has_add α] {n : ℕ+}

def cast : zmod n → α := nat.cast ∘ fin.val

end

end zmod

def zmodp (p : ℕ) (hp : prime p) : Type := zmod ⟨p, hp.pos⟩

namespace zmodp

variables {p : ℕ} (hp : prime p)

instance : comm_ring (zmodp p hp) := zmod.comm_ring ⟨p, hp.pos⟩

instance : inhabited (zmodp p hp) := ⟨0⟩

instance {p : ℕ} (hp : prime p) : has_inv (zmodp p hp) :=
⟨λ a, gcd_a a.1 p⟩

lemma add_val : ∀ a b : zmodp p hp, (a + b).val = (a.val + b.val) % p
| ⟨_, _⟩ ⟨_, _⟩ := rfl

lemma mul_val : ∀ a b : zmodp p hp, (a * b).val = (a.val * b.val) % p
| ⟨_, _⟩ ⟨_, _⟩ := rfl

@[simp] lemma one_val : (1 : zmodp p hp).val = 1 :=
nat.mod_eq_of_lt hp.one_lt

@[simp] lemma zero_val : (0 : zmodp p hp).val = 0 := rfl

lemma val_cast_nat (a : ℕ) : (a : zmodp p hp).val = a % p :=
@zmod.val_cast_nat ⟨p, hp.pos⟩ _

lemma mk_eq_cast {a : ℕ} (h : a < p) : (⟨a, h⟩ : zmodp p hp) = (a : zmodp p hp) :=
@zmod.mk_eq_cast ⟨p, hp.pos⟩ _ _

@[simp] lemma cast_self_eq_zero: (p : zmodp p hp) = 0 :=
fin.eq_of_veq $ by simp [val_cast_nat]

lemma val_cast_of_lt {a : ℕ} (h : a < p) : (a : zmodp p hp).val = a :=
@zmod.val_cast_of_lt ⟨p, hp.pos⟩ _ h

@[simp] lemma cast_mod_nat (a : ℕ) : ((a % p : ℕ) : zmodp p hp) = a :=
@zmod.cast_mod_nat ⟨p, hp.pos⟩ _

@[simp] lemma cast_val (a : zmodp p hp) : (a.val : zmodp p hp) = a :=
@zmod.cast_val ⟨p, hp.pos⟩ _

@[simp] lemma cast_mod_int (a : ℤ) : ((a % p : ℤ) : zmodp p hp) = a :=
@zmod.cast_mod_int ⟨p, hp.pos⟩ _

lemma val_cast_int (a : ℤ) : (a : zmodp p hp).val = (a % p).nat_abs :=
@zmod.val_cast_int ⟨p, hp.pos⟩ _

lemma coe_val_cast_int  (a : ℤ) : ((a : zmodp p hp).val : ℤ) = a % (p : ℕ) :=
@zmod.coe_val_cast_int ⟨p, hp.pos⟩ _

lemma eq_iff_modeq_nat {a b : ℕ} : (a : zmodp p hp) = b ↔ a ≡ b [MOD p] :=
@zmod.eq_iff_modeq_nat ⟨p, hp.pos⟩ _ _

lemma eq_iff_modeq_int {a b : ℤ} : (a : zmodp p hp) = b ↔ a ≡ b [ZMOD p] :=
@zmod.eq_iff_modeq_int ⟨p, hp.pos⟩ _ _

lemma eq_zero_iff_dvd_nat (a : ℕ) : (a : zmodp p hp) = 0 ↔ p ∣ a :=
@zmod.eq_zero_iff_dvd_nat ⟨p, hp.pos⟩ _

lemma eq_zero_iff_dvd_int (a : ℤ) : (a : zmodp p hp) = 0 ↔ (p : ℤ) ∣ a :=
@zmod.eq_zero_iff_dvd_int ⟨p, hp.pos⟩ _

instance : fintype (zmodp p hp) := @zmod.fintype ⟨p, hp.pos⟩

instance decidable_eq : decidable_eq (zmodp p hp) := fin.decidable_eq _

instance : has_repr (zmodp p hp) := fin.has_repr _

@[simp] lemma card_zmodp : fintype.card (zmodp p hp) = p :=
@zmod.card_zmod ⟨p, hp.pos⟩

lemma le_div_two_iff_lt_neg {p : ℕ} (hp : prime p) (hp1 : p % 2 = 1)
  {x : zmodp p hp} (hx0 : x ≠ 0) : x.1 ≤ (p / 2 : ℕ) ↔ (p / 2 : ℕ) < (-x).1 :=
@zmod.le_div_two_iff_lt_neg ⟨p, hp.pos⟩ hp1 _ hx0

lemma ne_neg_self (hp1 : p % 2 = 1) {a : zmodp p hp} (ha : a ≠ 0) : a ≠ -a :=
@zmod.ne_neg_self ⟨p, hp.pos⟩ hp1 _ ha

variable {hp}

/-- `val_min_abs x` returns the integer in the same equivalence class as `x` that is closest to `0`,
  The result will be in the interval `(-n/2, n/2]` -/
def val_min_abs (x : zmodp p hp) : ℤ := zmod.val_min_abs x

@[simp] lemma coe_val_min_abs (x : zmodp p hp) :
  (x.val_min_abs : zmodp p hp) = x :=
zmod.coe_val_min_abs x

lemma nat_abs_val_min_abs_le (x : zmodp p hp) : x.val_min_abs.nat_abs ≤ p / 2 :=
zmod.nat_abs_val_min_abs_le x

@[simp] lemma val_min_abs_zero : (0 : zmodp p hp).val_min_abs = 0 :=
zmod.val_min_abs_zero

@[simp] lemma val_min_abs_eq_zero (x : zmodp p hp) : x.val_min_abs = 0 ↔ x = 0 :=
zmod.val_min_abs_eq_zero x

lemma cast_nat_abs_val_min_abs (a : zmodp p hp) :
  (a.val_min_abs.nat_abs : zmodp p hp) = if a.val ≤ p / 2 then a else -a :=
zmod.cast_nat_abs_val_min_abs a

@[simp] lemma nat_abs_val_min_abs_neg (a : zmodp p hp) :
  (-a).val_min_abs.nat_abs = a.val_min_abs.nat_abs :=
zmod.nat_abs_val_min_abs_neg _

lemma val_eq_ite_val_min_abs (a : zmodp p hp) :
  (a.val : ℤ) = a.val_min_abs + if a.val ≤ p / 2 then 0 else p :=
zmod.val_eq_ite_val_min_abs _

variable (hp)

lemma prime_ne_zero {q : ℕ} (hq : prime q) (hpq : p ≠ q) : (q : zmodp p hp) ≠ 0 :=
by rwa [← nat.cast_zero, ne.def, zmodp.eq_iff_modeq_nat, nat.modeq.modeq_zero_iff,
  ← hp.coprime_iff_not_dvd, coprime_primes hp hq]

lemma mul_inv_eq_gcd (a : ℕ) : (a : zmodp p hp) * a⁻¹ = nat.gcd a p :=
by rw [← int.cast_coe_nat (nat.gcd _ _), nat.gcd_comm, nat.gcd_rec, ← (eq_iff_modeq_int _).2 (int.modeq.gcd_a_modeq _ _)];
  simp [has_inv.inv, val_cast_nat]

private lemma mul_inv_cancel_aux : ∀ a : zmodp p hp, a ≠ 0 → a * a⁻¹ = 1 :=
λ ⟨a, hap⟩ ha0, begin
  rw [mk_eq_cast, ne.def, ← @nat.cast_zero (zmodp p hp), eq_iff_modeq_nat, modeq_zero_iff] at ha0,
  have : nat.gcd p a = 1 := (prime.coprime_iff_not_dvd hp).2 ha0,
  rw [mk_eq_cast _ hap, mul_inv_eq_gcd, nat.gcd_comm],
  simpa [nat.gcd_comm, this]
end

instance : discrete_field (zmodp p hp) :=
{ zero_ne_one := fin.ne_of_vne $ show 0 ≠ 1 % p,
    by rw nat.mod_eq_of_lt hp.one_lt;
      exact zero_ne_one,
  mul_inv_cancel := mul_inv_cancel_aux hp,
  inv_mul_cancel := λ a, by rw mul_comm; exact mul_inv_cancel_aux hp _,
  has_decidable_eq := by apply_instance,
  inv_zero := show (gcd_a 0 p : zmodp p hp) = 0,
    by unfold gcd_a xgcd xgcd_aux; refl,
  ..zmodp.comm_ring hp,
  ..zmodp.has_inv hp }

end zmodp
