/-
Copyright (c) 2018 Mario Carneiro. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mario Carneiro, Abhimanyu Pallavi Sudhir, Jean Lo, Calle Sönne.

Irrationality of real numbers.
-/
import data.real.basic data.padics.padic_norm

open rat real multiplicity

def irrational (x : ℝ) := ¬ ∃ q : ℚ, x = q

theorem irr_nrt_of_notint_nrt {x : ℝ} (n : ℕ) (m : ℤ)
  (hxr : x ^ n = m) (hv : ¬ ∃ y : ℤ, x = y) (hnpos : 0 < n) :
  irrational x
| ⟨q, e⟩ := begin
  rw [e, ← cast_pow] at hxr, cases q with N D P C,
  have c1 : ((D : ℤ) : ℝ) ≠ 0,
  { rw [int.cast_ne_zero, int.coe_nat_ne_zero], exact ne_of_gt P },
  have c2 : ((D : ℤ) : ℝ) ^ n ≠ 0 := pow_ne_zero _ c1,
  rw [num_denom', cast_pow, cast_mk, div_pow _ c1, div_eq_iff_mul_eq c2,
      ← int.cast_pow, ← int.cast_pow, ← int.cast_mul, int.cast_inj] at hxr,
  have hdivn : ↑D ^ n ∣ N ^ n := dvd.intro_left m hxr,
  rw [← int.dvd_nat_abs, ← int.coe_nat_pow, int.coe_nat_dvd, int.nat_abs_pow, nat.pow_dvd_pow_iff hnpos] at hdivn,
  have hdivn' : nat.gcd N.nat_abs D = D := nat.gcd_eq_right hdivn,
  refine hv ⟨N, _⟩,
  rwa [num_denom', ← hdivn', C.gcd_eq_one, int.coe_nat_one, mk_eq_div,
      int.cast_one, div_one, cast_coe_int] at e
end

theorem irr_nrt_of_n_not_dvd_multiplicity {x : ℝ} (n : ℕ) {m : ℤ} (hm : m ≠ 0) (p : ℕ)
  [hp : nat.prime p] (hxr : x ^ n = m)
  (hv : (multiplicity (p : ℤ) m).get (finite_int_iff.2 ⟨hp.ne_one, hm⟩) % n ≠ 0) :
  irrational x :=
begin
  rcases nat.eq_zero_or_pos n with rfl | hnpos,
  { rw [eq_comm, pow_zero, ← int.cast_one, int.cast_inj] at hxr,
    simpa [hxr, multiplicity.one_right (mt is_unit_iff_dvd_one.1
      (mt int.coe_nat_dvd.1 hp.not_dvd_one)), nat.zero_mod] using hv },
  refine irr_nrt_of_notint_nrt _ _ hxr _ hnpos,
  rintro ⟨y, rfl⟩,
  rw [← int.cast_pow, int.cast_inj] at hxr, subst m,
  have : y ≠ 0, { rintro rfl, rw zero_pow hnpos at hm, exact hm rfl },
  erw [multiplicity.pow' (nat.prime_iff_prime_int.1 hp)
    (finite_int_iff.2 ⟨hp.ne_one, this⟩), nat.mul_mod_right] at hv,
  exact hv rfl
end

theorem irr_sqrt_of_multiplicity_odd (m : ℤ) (hm : 0 < m)
  (p : ℕ) [hp : nat.prime p]
  (Hpv : (multiplicity (p : ℤ) m).get (finite_int_iff.2 ⟨hp.ne_one, ne.symm (ne_of_lt hm)⟩) % 2 = 1) :
  irrational (sqrt m) :=
irr_nrt_of_n_not_dvd_multiplicity 2 (ne.symm (ne_of_lt hm)) p
  (sqr_sqrt (int.cast_nonneg.2 $ le_of_lt hm))
  (by rw Hpv; exact one_ne_zero)

theorem irr_sqrt_of_prime (p : ℕ) (hp : nat.prime p) : irrational (sqrt p) :=
irr_sqrt_of_multiplicity_odd p (int.coe_nat_pos.2 hp.pos) p $
by simp [multiplicity_self (mt is_unit_iff_dvd_one.1 (mt int.coe_nat_dvd.1 hp.not_dvd_one) : _)];
  refl

theorem irr_sqrt_two : irrational (sqrt 2) :=
by simpa using irr_sqrt_of_prime 2 nat.prime_two

theorem irr_sqrt_rat_iff (q : ℚ) : irrational (sqrt q) ↔
  rat.sqrt q * rat.sqrt q ≠ q ∧ 0 ≤ q :=
if H1 : rat.sqrt q * rat.sqrt q = q
then iff_of_false (not_not_intro ⟨rat.sqrt q,
  by rw [← H1, cast_mul, sqrt_mul_self (cast_nonneg.2 $ rat.sqrt_nonneg q),
         sqrt_eq, abs_of_nonneg (rat.sqrt_nonneg q)]⟩) (λ h, h.1 H1)
else if H2 : 0 ≤ q
then iff_of_true (λ ⟨r, hr⟩, H1 $ (exists_mul_self _).1 ⟨r,
  by rwa [sqrt_eq_iff_mul_self_eq (cast_nonneg.2 H2), ← cast_mul, cast_inj] at hr;
  rw [← hr]; exact real.sqrt_nonneg _⟩) ⟨H1, H2⟩
else iff_of_false (not_not_intro ⟨0,
  by rw cast_zero; exact sqrt_eq_zero_of_nonpos (rat.cast_nonpos.2 $ le_of_not_le H2)⟩)
  (λ h, H2 h.2)

instance (q : ℚ) : decidable (irrational (sqrt q)) :=
decidable_of_iff' _ (irr_sqrt_rat_iff q)

variables {q : ℚ} {x : ℝ}

theorem irr_rat_add_of_irr : irrational x → irrational (q + x) :=
mt $ λ ⟨a, h⟩, ⟨-q + a, by rw [rat.cast_add, ← h, rat.cast_neg, neg_add_cancel_left]⟩

@[simp] theorem irr_rat_add_iff_irr : irrational (q + x) ↔ irrational x :=
⟨by simpa only [cast_neg, neg_add_cancel_left] using @irr_rat_add_of_irr (-q) (q+x),
irr_rat_add_of_irr⟩

@[simp] theorem irr_add_rat_iff_irr : irrational (x + q) ↔ irrational x :=
by rw [add_comm, irr_rat_add_iff_irr]

theorem irr_mul_rat_iff_irr (Hqn0 : q ≠ 0) : irrational (x * ↑q) ↔ irrational x :=
⟨mt $ λ ⟨r, hr⟩, ⟨r * q, hr.symm ▸ (rat.cast_mul _ _).symm⟩,
mt $ λ ⟨r, hr⟩, ⟨r / q, by rw [cast_div, ← hr, mul_div_cancel]; rwa cast_ne_zero⟩⟩

theorem irr_of_irr_mul_self : irrational (x * x) → irrational x :=
mt $ λ ⟨p, e⟩, ⟨p * p, by rw [e, cast_mul]⟩

@[simp] theorem irr_neg : irrational (-x) ↔ irrational x :=
⟨λ hn ⟨q, hx⟩, hn ⟨-q, by rw [hx, cast_neg]⟩,
 λ hx ⟨q, hn⟩, hx ⟨-q, by rw [←neg_neg x, hn, cast_neg]⟩⟩
