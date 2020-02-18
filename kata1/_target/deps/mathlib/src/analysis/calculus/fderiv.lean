/-
Copyright (c) 2019 Jeremy Avigad. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jeremy Avigad, Sébastien Gouëzel, Yury Kudryashov
-/

import analysis.asymptotics analysis.calculus.tangent_cone

/-!
# The Fréchet derivative

Let `E` and `F` be normed spaces, `f : E → F`, and `f' : E →L[𝕜] F` a
continuous 𝕜-linear map, where `𝕜` is a non-discrete normed field. Then

  `has_fderiv_within_at f f' s x`

says that `f` has derivative `f'` at `x`, where the domain of interest
is restricted to `s`. We also have

  `has_fderiv_at f f' x := has_fderiv_within_at f f' x univ`

## Main results

In addition to the definition and basic properties of the derivative, this file contains the
usual formulas (and existence assertions) for the derivative of
* constants
* the identity
* bounded linear maps
* bounded bilinear maps
* sum of two functions
* multiplication of a function by a scalar constant
* negative of a function
* subtraction of two functions
* multiplication of a function by a scalar function
* multiplication of two scalar functions
* composition of functions (the chain rule)

For most binary operations we also define `const_op` and `op_const` theorems for the cases when
the first or second argument is a constant. This makes writing chains of `has_deriv_at`'s easier,
and they more frequently lead to the desired result.

One can also interpret the derivative of a function `f : 𝕜 → E` as an element of `E` (by identifying
a linear function from `𝕜` to `E` with its value at `1`). Results on the Fréchet derivative are
translated to this more elementary point of view on the derivative in the file `deriv.lean`. The
derivative of polynomials is handled there, as it is naturally one-dimensional.

## Implementation details

The derivative is defined in terms of the `is_o` relation, but also
characterized in terms of the `tendsto` relation.

We also introduce predicates `differentiable_within_at 𝕜 f s x` (where `𝕜` is the base field,
`f` the function to be differentiated, `x` the point at which the derivative is asserted to exist,
and `s` the set along which the derivative is defined), as well as `differentiable_at 𝕜 f x`,
`differentiable_on 𝕜 f s` and `differentiable 𝕜 f` to express the existence of a derivative.

To be able to compute with derivatives, we write `fderiv_within 𝕜 f s x` and `fderiv 𝕜 f x`
for some choice of a derivative if it exists, and the zero function otherwise. This choice only
behaves well along sets for which the derivative is unique, i.e., those for which the tangent
directions span a dense subset of the whole space. The predicates `unique_diff_within_at s x` and
`unique_diff_on s`, defined in `tangent_cone.lean` express this property. We prove that indeed
they imply the uniqueness of the derivative. This is satisfied for open subsets, and in particular
for `univ`. This uniqueness only holds when the field is non-discrete, which we request at the very
beginning: otherwise, a derivative can be defined, but it has no interesting properties whatsoever.

## Tags

derivative, differentiable, Fréchet, calculus

-/

open filter asymptotics continuous_linear_map set
open_locale topological_space classical

noncomputable theory

set_option class.instance_max_depth 90

section

variables {𝕜 : Type*} [nondiscrete_normed_field 𝕜]
variables {E : Type*} [normed_group E] [normed_space 𝕜 E]
variables {F : Type*} [normed_group F] [normed_space 𝕜 F]
variables {G : Type*} [normed_group G] [normed_space 𝕜 G]

/-- A function `f` has the continuous linear map `f'` as derivative along the filter `L` if
`f x' = f x + f' (x' - x) + o (x' - x)` when `x'` converges along the filter `L`. This definition
is designed to be specialized for `L = 𝓝 x` (in `has_fderiv_at`), giving rise to the usual notion
of Fréchet derivative, and for `L = nhds_within x s` (in `has_fderiv_within_at`), giving rise to
the notion of Fréchet derivative along the set `s`. -/
def has_fderiv_at_filter (f : E → F) (f' : E →L[𝕜] F) (x : E) (L : filter E) :=
is_o (λ x', f x' - f x - f' (x' - x)) (λ x', x' - x) L

/-- A function `f` has the continuous linear map `f'` as derivative at `x` within a set `s` if
`f x' = f x + f' (x' - x) + o (x' - x)` when `x'` tends to `x` inside `s`. -/
def has_fderiv_within_at (f : E → F) (f' : E →L[𝕜] F) (s : set E) (x : E) :=
has_fderiv_at_filter f f' x (nhds_within x s)

/-- A function `f` has the continuous linear map `f'` as derivative at `x` if
`f x' = f x + f' (x' - x) + o (x' - x)` when `x'` tends to `x`. -/
def has_fderiv_at (f : E → F) (f' : E →L[𝕜] F) (x : E) :=
has_fderiv_at_filter f f' x (𝓝 x)

variables (𝕜)

/-- A function `f` is differentiable at a point `x` within a set `s` if it admits a derivative
there (possibly non-unique). -/
def differentiable_within_at (f : E → F) (s : set E) (x : E) :=
∃f' : E →L[𝕜] F, has_fderiv_within_at f f' s x

/-- A function `f` is differentiable at a point `x` if it admits a derivative there (possibly
non-unique). -/
def differentiable_at (f : E → F) (x : E) :=
∃f' : E →L[𝕜] F, has_fderiv_at f f' x

/-- If `f` has a derivative at `x` within `s`, then `fderiv_within 𝕜 f s x` is such a derivative.
Otherwise, it is set to `0`. -/
def fderiv_within (f : E → F) (s : set E) (x : E) : E →L[𝕜] F :=
if h : ∃f', has_fderiv_within_at f f' s x then classical.some h else 0

/-- If `f` has a derivative at `x`, then `fderiv 𝕜 f x` is such a derivative. Otherwise, it is
set to `0`. -/
def fderiv (f : E → F) (x : E) : E →L[𝕜] F :=
if h : ∃f', has_fderiv_at f f' x then classical.some h else 0

/-- `differentiable_on 𝕜 f s` means that `f` is differentiable within `s` at any point of `s`. -/
def differentiable_on (f : E → F) (s : set E) :=
∀x ∈ s, differentiable_within_at 𝕜 f s x

/-- `differentiable 𝕜 f` means that `f` is differentiable at any point. -/
def differentiable (f : E → F) :=
∀x, differentiable_at 𝕜 f x

variables {𝕜}
variables {f f₀ f₁ g : E → F}
variables {f' f₀' f₁' g' : E →L[𝕜] F}
variables (e : E →L[𝕜] F)
variables {x : E}
variables {s t : set E}
variables {L L₁ L₂ : filter E}

lemma fderiv_within_zero_of_not_differentiable_within_at
  (h : ¬ differentiable_within_at 𝕜 f s x) : fderiv_within 𝕜 f s x = 0 :=
have ¬ ∃ f', has_fderiv_within_at f f' s x, from h,
by simp [fderiv_within, this]

lemma fderiv_zero_of_not_differentiable_at (h : ¬ differentiable_at 𝕜 f x) : fderiv 𝕜 f x = 0 :=
have ¬ ∃ f', has_fderiv_at f f' x, from h,
by simp [fderiv, this]

section derivative_uniqueness
/- In this section, we discuss the uniqueness of the derivative.
We prove that the definitions `unique_diff_within_at` and `unique_diff_on` indeed imply the
uniqueness of the derivative. -/

/-- If a function f has a derivative f' at x, a rescaled version of f around x converges to f', i.e.,
`n (f (x + (1/n) v) - f x)` converges to `f' v`. More generally, if `c n` tends to infinity and
`c n * d n` tends to `v`, then `c n * (f (x + d n) - f x)` tends to `f' v`. This lemma expresses
this fact, for functions having a derivative within a set. Its specific formulation is useful for
tangent cone related discussions. -/
theorem has_fderiv_within_at.lim (h : has_fderiv_within_at f f' s x) {α : Type*} (l : filter α)
  {c : α → 𝕜} {d : α → E} {v : E} (dtop : ∀ᶠ n in l, x + d n ∈ s)
  (clim : tendsto (λ n, ∥c n∥) l at_top)
  (cdlim : tendsto (λ n, c n • d n) l (𝓝 v)) :
  tendsto (λn, c n • (f (x + d n) - f x)) l (𝓝 (f' v)) :=
begin
  have tendsto_arg : tendsto (λ n, x + d n) l (nhds_within x s),
  { conv in (nhds_within x s) { rw ← add_zero x },
    rw [nhds_within, tendsto_inf],
    split,
    { apply tendsto_const_nhds.add (tangent_cone_at.lim_zero l clim cdlim) },
    { rwa tendsto_principal } },
  have : is_o (λ y, f y - f x - f' (y - x)) (λ y, y - x) (nhds_within x s) := h,
  have : is_o (λ n, f (x + d n) - f x - f' ((x + d n) - x)) (λ n, (x + d n)  - x) l :=
    this.comp_tendsto tendsto_arg,
  have : is_o (λ n, f (x + d n) - f x - f' (d n)) d l := by simpa only [add_sub_cancel'],
  have : is_o (λn, c n • (f (x + d n) - f x - f' (d n))) (λn, c n • d n) l :=
    (is_O_refl c l).smul_is_o this,
  have : is_o (λn, c n • (f (x + d n) - f x - f' (d n))) (λn, (1:ℝ)) l :=
    this.trans_is_O (is_O_one_of_tendsto ℝ cdlim),
  have L1 : tendsto (λn, c n • (f (x + d n) - f x - f' (d n))) l (𝓝 0) :=
    (is_o_one_iff ℝ).1 this,
  have L2 : tendsto (λn, f' (c n • d n)) l (𝓝 (f' v)) :=
    tendsto.comp f'.cont.continuous_at cdlim,
  have L3 : tendsto (λn, (c n • (f (x + d n) - f x - f' (d n)) +  f' (c n • d n)))
            l (𝓝 (0 + f' v)) :=
    L1.add L2,
  have : (λn, (c n • (f (x + d n) - f x - f' (d n)) +  f' (c n • d n)))
          = (λn, c n • (f (x + d n) - f x)),
    by { ext n, simp [smul_add] },
  rwa [this, zero_add] at L3
end

/-- `unique_diff_within_at` achieves its goal: it implies the uniqueness of the derivative. -/
theorem unique_diff_within_at.eq (H : unique_diff_within_at 𝕜 s x)
  (h : has_fderiv_within_at f f' s x) (h₁ : has_fderiv_within_at f f₁' s x) : f' = f₁' :=
begin
  have A : ∀y ∈ tangent_cone_at 𝕜 s x, f' y = f₁' y,
  { rintros y ⟨c, d, dtop, clim, cdlim⟩,
    exact tendsto_nhds_unique (by simp) (h.lim at_top dtop clim cdlim) (h₁.lim at_top dtop clim cdlim) },
  have B : ∀y ∈ submodule.span 𝕜 (tangent_cone_at 𝕜 s x), f' y = f₁' y,
  { assume y hy,
    apply submodule.span_induction hy,
    { exact λy hy, A y hy },
    { simp only [continuous_linear_map.map_zero] },
    { simp {contextual := tt} },
    { simp {contextual := tt} } },
  have C : ∀y ∈ closure ((submodule.span 𝕜 (tangent_cone_at 𝕜 s x)) : set E), f' y = f₁' y,
  { assume y hy,
    let K := {y | f' y = f₁' y},
    have : (submodule.span 𝕜 (tangent_cone_at 𝕜 s x) : set E) ⊆ K := B,
    have : closure (submodule.span 𝕜 (tangent_cone_at 𝕜 s x) : set E) ⊆ closure K :=
      closure_mono this,
    have : y ∈ closure K := this hy,
    rwa closure_eq_of_is_closed (is_closed_eq f'.continuous f₁'.continuous) at this },
  rw H.1 at C,
  ext y,
  exact C y (mem_univ _)
end

theorem unique_diff_on.eq (H : unique_diff_on 𝕜 s) (hx : x ∈ s)
  (h : has_fderiv_within_at f f' s x) (h₁ : has_fderiv_within_at f f₁' s x) : f' = f₁' :=
unique_diff_within_at.eq (H x hx) h h₁

end derivative_uniqueness

section fderiv_properties
/-! ### Basic properties of the derivative -/

theorem has_fderiv_at_filter_iff_tendsto :
  has_fderiv_at_filter f f' x L ↔
  tendsto (λ x', ∥x' - x∥⁻¹ * ∥f x' - f x - f' (x' - x)∥) L (𝓝 0) :=
have h : ∀ x', ∥x' - x∥ = 0 → ∥f x' - f x - f' (x' - x)∥ = 0, from λ x' hx',
  by { rw [sub_eq_zero.1 ((norm_eq_zero (x' - x)).1 hx')], simp },
begin
  unfold has_fderiv_at_filter,
  rw [←is_o_norm_left, ←is_o_norm_right, is_o_iff_tendsto h],
  exact tendsto_congr (λ _, div_eq_inv_mul),
end

theorem has_fderiv_within_at_iff_tendsto : has_fderiv_within_at f f' s x ↔
  tendsto (λ x', ∥x' - x∥⁻¹ * ∥f x' - f x - f' (x' - x)∥) (nhds_within x s) (𝓝 0) :=
has_fderiv_at_filter_iff_tendsto

theorem has_fderiv_at_iff_tendsto : has_fderiv_at f f' x ↔
  tendsto (λ x', ∥x' - x∥⁻¹ * ∥f x' - f x - f' (x' - x)∥) (𝓝 x) (𝓝 0) :=
has_fderiv_at_filter_iff_tendsto

theorem has_fderiv_at_iff_is_o_nhds_zero : has_fderiv_at f f' x ↔
  is_o (λh, f (x + h) - f x - f' h) (λh, h) (𝓝 0) :=
begin
  split,
  { assume H,
    have : tendsto (λ (z : E), z + x) (𝓝 0) (𝓝 (0 + x)),
      from tendsto_id.add tendsto_const_nhds,
    rw [zero_add] at this,
    refine (H.comp_tendsto this).congr _ _;
      intro z; simp only [function.comp, add_sub_cancel', add_comm z] },
  { assume H,
    have : tendsto (λ (z : E), z - x) (𝓝 x) (𝓝 (x - x)),
      from tendsto_id.sub tendsto_const_nhds,
    rw [sub_self] at this,
    refine (H.comp_tendsto this).congr _ _;
      intro z; simp only [function.comp, add_sub_cancel'_right] }
end

theorem has_fderiv_at_filter.mono (h : has_fderiv_at_filter f f' x L₂) (hst : L₁ ≤ L₂) :
  has_fderiv_at_filter f f' x L₁ :=
h.mono hst

theorem has_fderiv_within_at.mono (h : has_fderiv_within_at f f' t x) (hst : s ⊆ t) :
  has_fderiv_within_at f f' s x :=
h.mono (nhds_within_mono _ hst)

theorem has_fderiv_at.has_fderiv_at_filter (h : has_fderiv_at f f' x) (hL : L ≤ 𝓝 x) :
  has_fderiv_at_filter f f' x L :=
h.mono hL

theorem has_fderiv_at.has_fderiv_within_at
  (h : has_fderiv_at f f' x) : has_fderiv_within_at f f' s x :=
h.has_fderiv_at_filter lattice.inf_le_left

lemma has_fderiv_within_at.differentiable_within_at (h : has_fderiv_within_at f f' s x) :
  differentiable_within_at 𝕜 f s x :=
⟨f', h⟩

lemma has_fderiv_at.differentiable_at (h : has_fderiv_at f f' x) : differentiable_at 𝕜 f x :=
⟨f', h⟩

@[simp] lemma has_fderiv_within_at_univ :
  has_fderiv_within_at f f' univ x ↔ has_fderiv_at f f' x :=
by { simp only [has_fderiv_within_at, nhds_within_univ], refl }

/-- Directional derivative agrees with `has_fderiv`. -/
lemma has_fderiv_at.lim (hf : has_fderiv_at f f' x) (v : E) {α : Type*} {c : α → 𝕜}
  {l : filter α} (hc : tendsto (λ n, ∥c n∥) l at_top) :
  tendsto (λ n, (c n) • (f (x + (c n)⁻¹ • v) - f x)) l (𝓝 (f' v)) :=
begin
  refine (has_fderiv_within_at_univ.2 hf).lim _ (univ_mem_sets' (λ _, trivial)) hc _,
  assume U hU,
  apply mem_sets_of_superset (ne_mem_of_tendsto_norm_at_top hc (0:𝕜)) _,
  assume y hy,
  rw [mem_preimage],
  convert mem_of_nhds hU,
  rw [← mul_smul, mul_inv_cancel hy, one_smul]
end

theorem has_fderiv_at_unique
  (h₀ : has_fderiv_at f f₀' x) (h₁ : has_fderiv_at f f₁' x) : f₀' = f₁' :=
begin
  rw ← has_fderiv_within_at_univ at h₀ h₁,
  exact unique_diff_within_at_univ.eq h₀ h₁
end

lemma has_fderiv_within_at_inter' (h : t ∈ nhds_within x s) :
  has_fderiv_within_at f f' (s ∩ t) x ↔ has_fderiv_within_at f f' s x :=
by simp [has_fderiv_within_at, nhds_within_restrict'' s h]

lemma has_fderiv_within_at_inter (h : t ∈ 𝓝 x) :
  has_fderiv_within_at f f' (s ∩ t) x ↔ has_fderiv_within_at f f' s x :=
by simp [has_fderiv_within_at, nhds_within_restrict' s h]

lemma has_fderiv_within_at.union (hs : has_fderiv_within_at f f' s x) (ht : has_fderiv_within_at f f' t x) :
  has_fderiv_within_at f f' (s ∪ t) x :=
begin
  simp only [has_fderiv_within_at, nhds_within_union],
  exact hs.join ht,
end

lemma has_fderiv_within_at.nhds_within (h : has_fderiv_within_at f f' s x)
  (ht : s ∈ nhds_within x t) : has_fderiv_within_at f f' t x :=
(has_fderiv_within_at_inter' ht).1 (h.mono (inter_subset_right _ _))

lemma has_fderiv_within_at.has_fderiv_at (h : has_fderiv_within_at f f' s x) (hs : s ∈ 𝓝 x) :
  has_fderiv_at f f' x :=
by rwa [← univ_inter s, has_fderiv_within_at_inter hs, has_fderiv_within_at_univ] at h

lemma differentiable_within_at.has_fderiv_within_at (h : differentiable_within_at 𝕜 f s x) :
  has_fderiv_within_at f (fderiv_within 𝕜 f s x) s x :=
begin
  dunfold fderiv_within,
  dunfold differentiable_within_at at h,
  rw dif_pos h,
  exact classical.some_spec h
end

lemma differentiable_at.has_fderiv_at (h : differentiable_at 𝕜 f x) :
  has_fderiv_at f (fderiv 𝕜 f x) x :=
begin
  dunfold fderiv,
  dunfold differentiable_at at h,
  rw dif_pos h,
  exact classical.some_spec h
end

lemma has_fderiv_at.fderiv (h : has_fderiv_at f f' x) : fderiv 𝕜 f x = f' :=
by { ext, rw has_fderiv_at_unique h h.differentiable_at.has_fderiv_at }

lemma has_fderiv_within_at.fderiv_within
  (h : has_fderiv_within_at f f' s x) (hxs : unique_diff_within_at 𝕜 s x) :
  fderiv_within 𝕜 f s x = f' :=
by { ext, rw hxs.eq h h.differentiable_within_at.has_fderiv_within_at }

/-- If `x` is not in the closure of `s`, then `f` has any derivative at `x` within `s`,
as this statement is empty. -/
lemma has_fderiv_within_at_of_not_mem_closure (h : x ∉ closure s) :
  has_fderiv_within_at f f' s x :=
begin
  simp [mem_closure_iff_nhds_within_ne_bot] at h,
  simp [has_fderiv_within_at, has_fderiv_at_filter, h, is_o, is_O_with],
end

lemma differentiable_within_at.mono (h : differentiable_within_at 𝕜 f t x) (st : s ⊆ t) :
  differentiable_within_at 𝕜 f s x :=
begin
  rcases h with ⟨f', hf'⟩,
  exact ⟨f', hf'.mono st⟩
end

lemma differentiable_within_at_univ :
  differentiable_within_at 𝕜 f univ x ↔ differentiable_at 𝕜 f x :=
by simp only [differentiable_within_at, has_fderiv_within_at_univ, differentiable_at]

lemma differentiable_within_at_inter (ht : t ∈ 𝓝 x) :
  differentiable_within_at 𝕜 f (s ∩ t) x ↔ differentiable_within_at 𝕜 f s x :=
by simp only [differentiable_within_at, has_fderiv_within_at, has_fderiv_at_filter,
    nhds_within_restrict' s ht]

lemma differentiable_within_at_inter' (ht : t ∈ nhds_within x s) :
  differentiable_within_at 𝕜 f (s ∩ t) x ↔ differentiable_within_at 𝕜 f s x :=
by simp only [differentiable_within_at, has_fderiv_within_at, has_fderiv_at_filter,
    nhds_within_restrict'' s ht]

lemma differentiable_at.differentiable_within_at
  (h : differentiable_at 𝕜 f x) : differentiable_within_at 𝕜 f s x :=
(differentiable_within_at_univ.2 h).mono (subset_univ _)

lemma differentiable.differentiable_at (h : differentiable 𝕜 f) :
  differentiable_at 𝕜 f x :=
h x

lemma differentiable_within_at.differentiable_at
  (h : differentiable_within_at 𝕜 f s x) (hs : s ∈ 𝓝 x) : differentiable_at 𝕜 f x :=
h.imp (λ f' hf', hf'.has_fderiv_at hs)

lemma differentiable_at.fderiv_within
  (h : differentiable_at 𝕜 f x) (hxs : unique_diff_within_at 𝕜 s x) :
  fderiv_within 𝕜 f s x = fderiv 𝕜 f x :=
begin
  apply has_fderiv_within_at.fderiv_within _ hxs,
  exact h.has_fderiv_at.has_fderiv_within_at
end

lemma differentiable_on.mono (h : differentiable_on 𝕜 f t) (st : s ⊆ t) :
  differentiable_on 𝕜 f s :=
λx hx, (h x (st hx)).mono st

lemma differentiable_on_univ :
  differentiable_on 𝕜 f univ ↔ differentiable 𝕜 f :=
by { simp [differentiable_on, differentiable_within_at_univ], refl }

lemma differentiable.differentiable_on (h : differentiable 𝕜 f) : differentiable_on 𝕜 f s :=
(differentiable_on_univ.2 h).mono (subset_univ _)

lemma differentiable_on_of_locally_differentiable_on
  (h : ∀x∈s, ∃u, is_open u ∧ x ∈ u ∧ differentiable_on 𝕜 f (s ∩ u)) : differentiable_on 𝕜 f s :=
begin
  assume x xs,
  rcases h x xs with ⟨t, t_open, xt, ht⟩,
  exact (differentiable_within_at_inter (mem_nhds_sets t_open xt)).1 (ht x ⟨xs, xt⟩)
end

lemma fderiv_within_subset (st : s ⊆ t) (ht : unique_diff_within_at 𝕜 s x)
  (h : differentiable_within_at 𝕜 f t x) :
  fderiv_within 𝕜 f s x = fderiv_within 𝕜 f t x :=
((differentiable_within_at.has_fderiv_within_at h).mono st).fderiv_within ht

@[simp] lemma fderiv_within_univ : fderiv_within 𝕜 f univ = fderiv 𝕜 f :=
begin
  ext x : 1,
  by_cases h : differentiable_at 𝕜 f x,
  { apply has_fderiv_within_at.fderiv_within _ unique_diff_within_at_univ,
    rw has_fderiv_within_at_univ,
    apply h.has_fderiv_at },
  { have : ¬ differentiable_within_at 𝕜 f univ x,
      by contrapose! h; rwa ← differentiable_within_at_univ,
    rw [fderiv_zero_of_not_differentiable_at h,
        fderiv_within_zero_of_not_differentiable_within_at this] }
end

lemma fderiv_within_inter (ht : t ∈ 𝓝 x) (hs : unique_diff_within_at 𝕜 s x) :
  fderiv_within 𝕜 f (s ∩ t) x = fderiv_within 𝕜 f s x :=
begin
  by_cases h : differentiable_within_at 𝕜 f (s ∩ t) x,
  { apply fderiv_within_subset (inter_subset_left _ _) _ ((differentiable_within_at_inter ht).1 h),
    apply hs.inter ht },
  { have : ¬ differentiable_within_at 𝕜 f s x,
      by contrapose! h; rw differentiable_within_at_inter; assumption,
    rw [fderiv_within_zero_of_not_differentiable_within_at h,
        fderiv_within_zero_of_not_differentiable_within_at this] }
end

end fderiv_properties

section congr
/-! ### congr properties of the derivative -/

theorem has_fderiv_at_filter_congr_of_mem_sets
  (hx : f₀ x = f₁ x) (h₀ : ∀ᶠ x in L, f₀ x = f₁ x) (h₁ : ∀ x, f₀' x = f₁' x) :
  has_fderiv_at_filter f₀ f₀' x L ↔ has_fderiv_at_filter f₁ f₁' x L :=
by { rw (ext h₁), exact is_o_congr
  (by filter_upwards [h₀] λ x (h : _ = _), by simp [h, hx])
  (univ_mem_sets' $ λ _, rfl) }

lemma has_fderiv_at_filter.congr_of_mem_sets (h : has_fderiv_at_filter f f' x L)
  (hL : ∀ᶠ x in L, f₁ x = f x) (hx : f₁ x = f x) : has_fderiv_at_filter f₁ f' x L :=
begin
  apply (has_fderiv_at_filter_congr_of_mem_sets hx hL _).2 h,
  exact λx, rfl
end

lemma has_fderiv_within_at.congr_mono (h : has_fderiv_within_at f f' s x) (ht : ∀x ∈ t, f₁ x = f x)
  (hx : f₁ x = f x) (h₁ : t ⊆ s) : has_fderiv_within_at f₁ f' t x :=
has_fderiv_at_filter.congr_of_mem_sets (h.mono h₁) (filter.mem_inf_sets_of_right ht) hx

lemma has_fderiv_within_at.congr (h : has_fderiv_within_at f f' s x) (hs : ∀x ∈ s, f₁ x = f x)
  (hx : f₁ x = f x) : has_fderiv_within_at f₁ f' s x :=
h.congr_mono hs hx (subset.refl _)

lemma has_fderiv_within_at.congr_of_mem_nhds_within (h : has_fderiv_within_at f f' s x)
  (h₁ : ∀ᶠ y in nhds_within x s, f₁ y = f y) (hx : f₁ x = f x) : has_fderiv_within_at f₁ f' s x :=
has_fderiv_at_filter.congr_of_mem_sets h h₁ hx

lemma has_fderiv_at.congr_of_mem_nhds (h : has_fderiv_at f f' x)
  (h₁ : ∀ᶠ y in 𝓝 x, f₁ y = f y) : has_fderiv_at f₁ f' x :=
has_fderiv_at_filter.congr_of_mem_sets h h₁ (mem_of_nhds h₁ : _)

lemma differentiable_within_at.congr_mono (h : differentiable_within_at 𝕜 f s x)
  (ht : ∀x ∈ t, f₁ x = f x) (hx : f₁ x = f x) (h₁ : t ⊆ s) : differentiable_within_at 𝕜 f₁ t x :=
(has_fderiv_within_at.congr_mono h.has_fderiv_within_at ht hx h₁).differentiable_within_at

lemma differentiable_within_at.congr (h : differentiable_within_at 𝕜 f s x)
  (ht : ∀x ∈ s, f₁ x = f x) (hx : f₁ x = f x) : differentiable_within_at 𝕜 f₁ s x :=
differentiable_within_at.congr_mono h ht hx (subset.refl _)

lemma differentiable_within_at.congr_of_mem_nhds_within
  (h : differentiable_within_at 𝕜 f s x) (h₁ : ∀ᶠ y in nhds_within x s, f₁ y = f y)
  (hx : f₁ x = f x) : differentiable_within_at 𝕜 f₁ s x :=
(h.has_fderiv_within_at.congr_of_mem_nhds_within h₁ hx).differentiable_within_at

lemma differentiable_on.congr_mono (h : differentiable_on 𝕜 f s) (h' : ∀x ∈ t, f₁ x = f x)
  (h₁ : t ⊆ s) : differentiable_on 𝕜 f₁ t :=
λ x hx, (h x (h₁ hx)).congr_mono h' (h' x hx) h₁

lemma differentiable_on.congr (h : differentiable_on 𝕜 f s) (h' : ∀x ∈ s, f₁ x = f x) :
  differentiable_on 𝕜 f₁ s :=
λ x hx, (h x hx).congr h' (h' x hx)

lemma differentiable_on_congr (h' : ∀x ∈ s, f₁ x = f x) :
  differentiable_on 𝕜 f₁ s ↔ differentiable_on 𝕜 f s :=
⟨λ h, differentiable_on.congr h (λy hy, (h' y hy).symm),
λ h, differentiable_on.congr h h'⟩

lemma differentiable_at.congr_of_mem_nhds (h : differentiable_at 𝕜 f x)
  (hL : ∀ᶠ y in 𝓝 x, f₁ y = f y) : differentiable_at 𝕜 f₁ x :=
has_fderiv_at.differentiable_at (has_fderiv_at_filter.congr_of_mem_sets h.has_fderiv_at hL (mem_of_nhds hL : _))

lemma differentiable_within_at.fderiv_within_congr_mono (h : differentiable_within_at 𝕜 f s x)
  (hs : ∀x ∈ t, f₁ x = f x) (hx : f₁ x = f x) (hxt : unique_diff_within_at 𝕜 t x) (h₁ : t ⊆ s) :
  fderiv_within 𝕜 f₁ t x = fderiv_within 𝕜 f s x :=
(has_fderiv_within_at.congr_mono h.has_fderiv_within_at hs hx h₁).fderiv_within hxt

lemma fderiv_within_congr_of_mem_nhds_within (hs : unique_diff_within_at 𝕜 s x)
  (hL : ∀ᶠ y in nhds_within x s, f₁ y = f y) (hx : f₁ x = f x) :
  fderiv_within 𝕜 f₁ s x = fderiv_within 𝕜 f s x :=
begin
  by_cases h : differentiable_within_at 𝕜 f s x ∨ differentiable_within_at 𝕜 f₁ s x,
  { cases h,
    { apply has_fderiv_within_at.fderiv_within _ hs,
      exact has_fderiv_at_filter.congr_of_mem_sets h.has_fderiv_within_at hL hx },
    { symmetry,
      apply has_fderiv_within_at.fderiv_within _ hs,
      apply has_fderiv_at_filter.congr_of_mem_sets h.has_fderiv_within_at _ hx.symm,
      convert hL,
      ext y,
      exact eq_comm } },
  { push_neg at h,
    have A : fderiv_within 𝕜 f s x = 0,
      by { unfold differentiable_within_at at h, simp [fderiv_within, h] },
    have A₁ : fderiv_within 𝕜 f₁ s x = 0,
      by { unfold differentiable_within_at at h, simp [fderiv_within, h] },
    rw [A, A₁] }
end

lemma fderiv_within_congr (hs : unique_diff_within_at 𝕜 s x)
  (hL : ∀y∈s, f₁ y = f y) (hx : f₁ x = f x) :
  fderiv_within 𝕜 f₁ s x = fderiv_within 𝕜 f s x :=
begin
  apply fderiv_within_congr_of_mem_nhds_within hs _ hx,
  apply mem_sets_of_superset self_mem_nhds_within,
  exact hL
end

lemma fderiv_congr_of_mem_nhds (hL : ∀ᶠ y in 𝓝 x, f₁ y = f y) :
  fderiv 𝕜 f₁ x = fderiv 𝕜 f x :=
begin
  have A : f₁ x = f x := (mem_of_nhds hL : _),
  rw [← fderiv_within_univ, ← fderiv_within_univ],
  rw ← nhds_within_univ at hL,
  exact fderiv_within_congr_of_mem_nhds_within unique_diff_within_at_univ hL A
end

end congr

section id
/-! ### Derivative of the identity -/

theorem has_fderiv_at_filter_id (x : E) (L : filter E) :
  has_fderiv_at_filter id (id : E →L[𝕜] E) x L :=
(is_o_zero _ _).congr_left $ by simp

theorem has_fderiv_within_at_id (x : E) (s : set E) :
  has_fderiv_within_at id (id : E →L[𝕜] E) s x :=
has_fderiv_at_filter_id _ _

theorem has_fderiv_at_id (x : E) : has_fderiv_at id (id : E →L[𝕜] E) x :=
has_fderiv_at_filter_id _ _

lemma differentiable_at_id : differentiable_at 𝕜 id x :=
(has_fderiv_at_id x).differentiable_at

lemma differentiable_within_at_id : differentiable_within_at 𝕜 id s x :=
differentiable_at_id.differentiable_within_at

lemma differentiable_id : differentiable 𝕜 (id : E → E) :=
λx, differentiable_at_id

lemma differentiable_on_id : differentiable_on 𝕜 id s :=
differentiable_id.differentiable_on

lemma fderiv_id : fderiv 𝕜 id x = id :=
has_fderiv_at.fderiv (has_fderiv_at_id x)

lemma fderiv_within_id (hxs : unique_diff_within_at 𝕜 s x) :
  fderiv_within 𝕜 id s x = id :=
begin
  rw differentiable_at.fderiv_within (differentiable_at_id) hxs,
  exact fderiv_id
end

end id

section const
/-! ### derivative of a constant function -/

theorem has_fderiv_at_filter_const (c : F) (x : E) (L : filter E) :
  has_fderiv_at_filter (λ x, c) (0 : E →L[𝕜] F) x L :=
(is_o_zero _ _).congr_left $ λ _, by simp only [zero_apply, sub_self]

theorem has_fderiv_within_at_const (c : F) (x : E) (s : set E) :
  has_fderiv_within_at (λ x, c) (0 : E →L[𝕜] F) s x :=
has_fderiv_at_filter_const _ _ _

theorem has_fderiv_at_const (c : F) (x : E) :
  has_fderiv_at (λ x, c) (0 : E →L[𝕜] F) x :=
has_fderiv_at_filter_const _ _ _

lemma differentiable_at_const (c : F) : differentiable_at 𝕜 (λx, c) x :=
⟨0, has_fderiv_at_const c x⟩

lemma differentiable_within_at_const (c : F) : differentiable_within_at 𝕜 (λx, c) s x :=
differentiable_at.differentiable_within_at (differentiable_at_const _)

lemma fderiv_const_apply (c : F) : fderiv 𝕜 (λy, c) x = 0 :=
has_fderiv_at.fderiv (has_fderiv_at_const c x)

lemma fderiv_const (c : F) : fderiv 𝕜 (λ (y : E), c) = 0 :=
by { ext m, rw fderiv_const_apply, refl }

lemma fderiv_within_const_apply (c : F) (hxs : unique_diff_within_at 𝕜 s x) :
  fderiv_within 𝕜 (λy, c) s x = 0 :=
begin
  rw differentiable_at.fderiv_within (differentiable_at_const _) hxs,
  exact fderiv_const_apply _
end

lemma differentiable_const (c : F) : differentiable 𝕜 (λx : E, c) :=
λx, differentiable_at_const _

lemma differentiable_on_const (c : F) : differentiable_on 𝕜 (λx, c) s :=
(differentiable_const _).differentiable_on

end const

section continuous_linear_map
/-! ### Continuous linear maps

There are currently two variants of these in mathlib, the bundled version
(named `continuous_linear_map`, and denoted `E →L[𝕜] F`), and the unbundled version (with a
predicate `is_bounded_linear_map`). We give statements for both versions. -/

lemma is_bounded_linear_map.has_fderiv_at_filter (h : is_bounded_linear_map 𝕜 f) :
  has_fderiv_at_filter f h.to_continuous_linear_map x L :=
begin
  have : (λ (x' : E), f x' - f x - h.to_continuous_linear_map (x' - x)) = λx', 0,
  { ext,
    have : ∀a, h.to_continuous_linear_map a = f a := λa, rfl,
    simp,
    simp [this] },
  rw [has_fderiv_at_filter, this],
  exact asymptotics.is_o_zero _ _
end

lemma is_bounded_linear_map.has_fderiv_within_at (h : is_bounded_linear_map 𝕜 f) :
  has_fderiv_within_at f h.to_continuous_linear_map s x :=
h.has_fderiv_at_filter

lemma is_bounded_linear_map.has_fderiv_at (h : is_bounded_linear_map 𝕜 f) :
  has_fderiv_at f h.to_continuous_linear_map x  :=
h.has_fderiv_at_filter

lemma is_bounded_linear_map.differentiable_at (h : is_bounded_linear_map 𝕜 f) :
  differentiable_at 𝕜 f x :=
h.has_fderiv_at.differentiable_at

lemma is_bounded_linear_map.differentiable_within_at (h : is_bounded_linear_map 𝕜 f) :
  differentiable_within_at 𝕜 f s x :=
h.differentiable_at.differentiable_within_at

lemma is_bounded_linear_map.fderiv (h : is_bounded_linear_map 𝕜 f) :
  fderiv 𝕜 f x = h.to_continuous_linear_map :=
has_fderiv_at.fderiv (h.has_fderiv_at)

lemma is_bounded_linear_map.fderiv_within (h : is_bounded_linear_map 𝕜 f)
  (hxs : unique_diff_within_at 𝕜 s x) : fderiv_within 𝕜 f s x = h.to_continuous_linear_map :=
begin
  rw differentiable_at.fderiv_within h.differentiable_at hxs,
  exact h.fderiv
end

lemma is_bounded_linear_map.differentiable (h : is_bounded_linear_map 𝕜 f) :
  differentiable 𝕜 f :=
λx, h.differentiable_at

lemma is_bounded_linear_map.differentiable_on (h : is_bounded_linear_map 𝕜 f) :
  differentiable_on 𝕜 f s :=
h.differentiable.differentiable_on

lemma continuous_linear_map.has_fderiv_at_filter :
  has_fderiv_at_filter e e x L :=
begin
  have : (λ (x' : E), e x' - e x - e (x' - x)) = λx', 0, by { ext, simp },
  rw [has_fderiv_at_filter, this],
  exact asymptotics.is_o_zero _ _
end

protected lemma continuous_linear_map.has_fderiv_within_at : has_fderiv_within_at e e s x :=
e.has_fderiv_at_filter

protected lemma continuous_linear_map.has_fderiv_at : has_fderiv_at e e x :=
e.has_fderiv_at_filter

protected lemma continuous_linear_map.differentiable_at : differentiable_at 𝕜 e x :=
e.has_fderiv_at.differentiable_at

protected lemma continuous_linear_map.differentiable_within_at : differentiable_within_at 𝕜 e s x :=
e.differentiable_at.differentiable_within_at

protected lemma continuous_linear_map.fderiv : fderiv 𝕜 e x = e :=
e.has_fderiv_at.fderiv

protected lemma continuous_linear_map.fderiv_within (hxs : unique_diff_within_at 𝕜 s x) :
  fderiv_within 𝕜 e s x = e :=
begin
  rw differentiable_at.fderiv_within e.differentiable_at hxs,
  exact e.fderiv
end

protected lemma continuous_linear_map.differentiable : differentiable 𝕜 e :=
λx, e.differentiable_at

protected lemma continuous_linear_map.differentiable_on : differentiable_on 𝕜 e s :=
e.differentiable.differentiable_on

end continuous_linear_map

section const_smul
/-! ### Derivative of a function multiplied by a constant -/
theorem has_fderiv_at_filter.const_smul (h : has_fderiv_at_filter f f' x L) (c : 𝕜) :
  has_fderiv_at_filter (λ x, c • f x) (c • f') x L :=
(is_o_const_smul_left h c).congr_left $ λ x, by simp [smul_neg, smul_add]

theorem has_fderiv_within_at.const_smul (h : has_fderiv_within_at f f' s x) (c : 𝕜) :
  has_fderiv_within_at (λ x, c • f x) (c • f') s x :=
h.const_smul c

theorem has_fderiv_at.const_smul (h : has_fderiv_at f f' x) (c : 𝕜) :
  has_fderiv_at (λ x, c • f x) (c • f') x :=
h.const_smul c

lemma differentiable_within_at.const_smul (h : differentiable_within_at 𝕜 f s x) (c : 𝕜) :
  differentiable_within_at 𝕜 (λy, c • f y) s x :=
(h.has_fderiv_within_at.const_smul c).differentiable_within_at

lemma differentiable_at.const_smul (h : differentiable_at 𝕜 f x) (c : 𝕜) :
  differentiable_at 𝕜 (λy, c • f y) x :=
(h.has_fderiv_at.const_smul c).differentiable_at

lemma differentiable_on.const_smul (h : differentiable_on 𝕜 f s) (c : 𝕜) :
  differentiable_on 𝕜 (λy, c • f y) s :=
λx hx, (h x hx).const_smul c

lemma differentiable.const_smul (h : differentiable 𝕜 f) (c : 𝕜) :
  differentiable 𝕜 (λy, c • f y) :=
λx, (h x).const_smul c

lemma fderiv_within_const_smul (hxs : unique_diff_within_at 𝕜 s x)
  (h : differentiable_within_at 𝕜 f s x) (c : 𝕜) :
  fderiv_within 𝕜 (λy, c • f y) s x = c • fderiv_within 𝕜 f s x :=
(h.has_fderiv_within_at.const_smul c).fderiv_within hxs

lemma fderiv_const_smul (h : differentiable_at 𝕜 f x) (c : 𝕜) :
  fderiv 𝕜 (λy, c • f y) x = c • fderiv 𝕜 f x :=
(h.has_fderiv_at.const_smul c).fderiv

end const_smul

section add
/-! ### Derivative of the sum of two functions -/

theorem has_fderiv_at_filter.add
  (hf : has_fderiv_at_filter f f' x L) (hg : has_fderiv_at_filter g g' x L) :
  has_fderiv_at_filter (λ y, f y + g y) (f' + g') x L :=
(hf.add hg).congr_left $ λ _, by simp

theorem has_fderiv_within_at.add
  (hf : has_fderiv_within_at f f' s x) (hg : has_fderiv_within_at g g' s x) :
  has_fderiv_within_at (λ y, f y + g y) (f' + g') s x :=
hf.add hg

theorem has_fderiv_at.add
  (hf : has_fderiv_at f f' x) (hg : has_fderiv_at g g' x) :
  has_fderiv_at (λ x, f x + g x) (f' + g') x :=
hf.add hg

lemma differentiable_within_at.add
  (hf : differentiable_within_at 𝕜 f s x) (hg : differentiable_within_at 𝕜 g s x) :
  differentiable_within_at 𝕜 (λ y, f y + g y) s x :=
(hf.has_fderiv_within_at.add hg.has_fderiv_within_at).differentiable_within_at

lemma differentiable_at.add
  (hf : differentiable_at 𝕜 f x) (hg : differentiable_at 𝕜 g x) :
  differentiable_at 𝕜 (λ y, f y + g y) x :=
(hf.has_fderiv_at.add hg.has_fderiv_at).differentiable_at

lemma differentiable_on.add
  (hf : differentiable_on 𝕜 f s) (hg : differentiable_on 𝕜 g s) :
  differentiable_on 𝕜 (λy, f y + g y) s :=
λx hx, (hf x hx).add (hg x hx)

lemma differentiable.add
  (hf : differentiable 𝕜 f) (hg : differentiable 𝕜 g) :
  differentiable 𝕜 (λy, f y + g y) :=
λx, (hf x).add (hg x)

lemma fderiv_within_add (hxs : unique_diff_within_at 𝕜 s x)
  (hf : differentiable_within_at 𝕜 f s x) (hg : differentiable_within_at 𝕜 g s x) :
  fderiv_within 𝕜 (λy, f y + g y) s x = fderiv_within 𝕜 f s x + fderiv_within 𝕜 g s x :=
(hf.has_fderiv_within_at.add hg.has_fderiv_within_at).fderiv_within hxs

lemma fderiv_add
  (hf : differentiable_at 𝕜 f x) (hg : differentiable_at 𝕜 g x) :
  fderiv 𝕜 (λy, f y + g y) x = fderiv 𝕜 f x + fderiv 𝕜 g x :=
(hf.has_fderiv_at.add hg.has_fderiv_at).fderiv

theorem has_fderiv_at_filter.add_const
  (hf : has_fderiv_at_filter f f' x L) (c : F) :
  has_fderiv_at_filter (λ y, f y + c) f' x L :=
add_zero f' ▸ hf.add (has_fderiv_at_filter_const _ _ _)

theorem has_fderiv_within_at.add_const
  (hf : has_fderiv_within_at f f' s x) (c : F) :
  has_fderiv_within_at (λ y, f y + c) f' s x :=
hf.add_const c

theorem has_fderiv_at.add_const
  (hf : has_fderiv_at f f' x) (c : F):
  has_fderiv_at (λ x, f x + c) f' x :=
hf.add_const c

lemma differentiable_within_at.add_const
  (hf : differentiable_within_at 𝕜 f s x) (c : F) :
  differentiable_within_at 𝕜 (λ y, f y + c) s x :=
(hf.has_fderiv_within_at.add_const c).differentiable_within_at

lemma differentiable_at.add_const
  (hf : differentiable_at 𝕜 f x) (c : F) :
  differentiable_at 𝕜 (λ y, f y + c) x :=
(hf.has_fderiv_at.add_const c).differentiable_at

lemma differentiable_on.add_const
  (hf : differentiable_on 𝕜 f s) (c : F) :
  differentiable_on 𝕜 (λy, f y + c) s :=
λx hx, (hf x hx).add_const c

lemma differentiable.add_const
  (hf : differentiable 𝕜 f) (c : F) :
  differentiable 𝕜 (λy, f y + c) :=
λx, (hf x).add_const c

lemma fderiv_within_add_const (hxs : unique_diff_within_at 𝕜 s x)
  (hf : differentiable_within_at 𝕜 f s x) (c : F) :
  fderiv_within 𝕜 (λy, f y + c) s x = fderiv_within 𝕜 f s x :=
(hf.has_fderiv_within_at.add_const c).fderiv_within hxs

lemma fderiv_add_const
  (hf : differentiable_at 𝕜 f x) (c : F) :
  fderiv 𝕜 (λy, f y + c) x = fderiv 𝕜 f x :=
(hf.has_fderiv_at.add_const c).fderiv

theorem has_fderiv_at_filter.const_add
  (hf : has_fderiv_at_filter f f' x L) (c : F) :
  has_fderiv_at_filter (λ y, c + f y) f' x L :=
zero_add f' ▸ (has_fderiv_at_filter_const _ _ _).add hf

theorem has_fderiv_within_at.const_add
  (hf : has_fderiv_within_at f f' s x) (c : F) :
  has_fderiv_within_at (λ y, c + f y) f' s x :=
hf.const_add c

theorem has_fderiv_at.const_add
  (hf : has_fderiv_at f f' x) (c : F):
  has_fderiv_at (λ x, c + f x) f' x :=
hf.const_add c

lemma differentiable_within_at.const_add
  (hf : differentiable_within_at 𝕜 f s x) (c : F) :
  differentiable_within_at 𝕜 (λ y, c + f y) s x :=
(hf.has_fderiv_within_at.const_add c).differentiable_within_at

lemma differentiable_at.const_add
  (hf : differentiable_at 𝕜 f x) (c : F) :
  differentiable_at 𝕜 (λ y, c + f y) x :=
(hf.has_fderiv_at.const_add c).differentiable_at

lemma differentiable_on.const_add
  (hf : differentiable_on 𝕜 f s) (c : F) :
  differentiable_on 𝕜 (λy, c + f y) s :=
λx hx, (hf x hx).const_add c

lemma differentiable.const_add
  (hf : differentiable 𝕜 f) (c : F) :
  differentiable 𝕜 (λy, c + f y) :=
λx, (hf x).const_add c

lemma fderiv_within_const_add (hxs : unique_diff_within_at 𝕜 s x)
  (hf : differentiable_within_at 𝕜 f s x) (c : F) :
  fderiv_within 𝕜 (λy, c + f y) s x = fderiv_within 𝕜 f s x :=
(hf.has_fderiv_within_at.const_add c).fderiv_within hxs

lemma fderiv_const_add
  (hf : differentiable_at 𝕜 f x) (c : F) :
  fderiv 𝕜 (λy, c + f y) x = fderiv 𝕜 f x :=
(hf.has_fderiv_at.const_add c).fderiv

end add

section neg
/-! ### Derivative of the negative of a function -/

theorem has_fderiv_at_filter.neg (h : has_fderiv_at_filter f f' x L) :
  has_fderiv_at_filter (λ x, -f x) (-f') x L :=
(h.const_smul (-1:𝕜)).congr (by simp) (by simp)

theorem has_fderiv_within_at.neg (h : has_fderiv_within_at f f' s x) :
  has_fderiv_within_at (λ x, -f x) (-f') s x :=
h.neg

theorem has_fderiv_at.neg (h : has_fderiv_at f f' x) :
  has_fderiv_at (λ x, -f x) (-f') x :=
h.neg

lemma differentiable_within_at.neg (h : differentiable_within_at 𝕜 f s x) :
  differentiable_within_at 𝕜 (λy, -f y) s x :=
h.has_fderiv_within_at.neg.differentiable_within_at

lemma differentiable_at.neg (h : differentiable_at 𝕜 f x) :
  differentiable_at 𝕜 (λy, -f y) x :=
h.has_fderiv_at.neg.differentiable_at

lemma differentiable_on.neg (h : differentiable_on 𝕜 f s) :
  differentiable_on 𝕜 (λy, -f y) s :=
λx hx, (h x hx).neg

lemma differentiable.neg (h : differentiable 𝕜 f) :
  differentiable 𝕜 (λy, -f y) :=
λx, (h x).neg

lemma fderiv_within_neg (hxs : unique_diff_within_at 𝕜 s x)
  (h : differentiable_within_at 𝕜 f s x) :
  fderiv_within 𝕜 (λy, -f y) s x = - fderiv_within 𝕜 f s x :=
h.has_fderiv_within_at.neg.fderiv_within hxs

lemma fderiv_neg (h : differentiable_at 𝕜 f x) :
  fderiv 𝕜 (λy, -f y) x = - fderiv 𝕜 f x :=
h.has_fderiv_at.neg.fderiv

end neg

section sub
/-! ### Derivative of the difference of two functions -/

theorem has_fderiv_at_filter.sub
  (hf : has_fderiv_at_filter f f' x L) (hg : has_fderiv_at_filter g g' x L) :
  has_fderiv_at_filter (λ x, f x - g x) (f' - g') x L :=
hf.add hg.neg

theorem has_fderiv_within_at.sub
  (hf : has_fderiv_within_at f f' s x) (hg : has_fderiv_within_at g g' s x) :
  has_fderiv_within_at (λ x, f x - g x) (f' - g') s x :=
hf.sub hg

theorem has_fderiv_at.sub
  (hf : has_fderiv_at f f' x) (hg : has_fderiv_at g g' x) :
  has_fderiv_at (λ x, f x - g x) (f' - g') x :=
hf.sub hg

lemma differentiable_within_at.sub
  (hf : differentiable_within_at 𝕜 f s x) (hg : differentiable_within_at 𝕜 g s x) :
  differentiable_within_at 𝕜 (λ y, f y - g y) s x :=
(hf.has_fderiv_within_at.sub hg.has_fderiv_within_at).differentiable_within_at

lemma differentiable_at.sub
  (hf : differentiable_at 𝕜 f x) (hg : differentiable_at 𝕜 g x) :
  differentiable_at 𝕜 (λ y, f y - g y) x :=
(hf.has_fderiv_at.sub hg.has_fderiv_at).differentiable_at

lemma differentiable_on.sub
  (hf : differentiable_on 𝕜 f s) (hg : differentiable_on 𝕜 g s) :
  differentiable_on 𝕜 (λy, f y - g y) s :=
λx hx, (hf x hx).sub (hg x hx)

lemma differentiable.sub
  (hf : differentiable 𝕜 f) (hg : differentiable 𝕜 g) :
  differentiable 𝕜 (λy, f y - g y) :=
λx, (hf x).sub (hg x)

lemma fderiv_within_sub (hxs : unique_diff_within_at 𝕜 s x)
  (hf : differentiable_within_at 𝕜 f s x) (hg : differentiable_within_at 𝕜 g s x) :
  fderiv_within 𝕜 (λy, f y - g y) s x = fderiv_within 𝕜 f s x - fderiv_within 𝕜 g s x :=
(hf.has_fderiv_within_at.sub hg.has_fderiv_within_at).fderiv_within hxs

lemma fderiv_sub
  (hf : differentiable_at 𝕜 f x) (hg : differentiable_at 𝕜 g x) :
  fderiv 𝕜 (λy, f y - g y) x = fderiv 𝕜 f x - fderiv 𝕜 g x :=
(hf.has_fderiv_at.sub hg.has_fderiv_at).fderiv

theorem has_fderiv_at_filter.is_O_sub (h : has_fderiv_at_filter f f' x L) :
is_O (λ x', f x' - f x) (λ x', x' - x) L :=
h.is_O.congr_of_sub.2 (f'.is_O_sub _ _)

theorem has_fderiv_at_filter.sub_const
  (hf : has_fderiv_at_filter f f' x L) (c : F) :
  has_fderiv_at_filter (λ x, f x - c) f' x L :=
hf.add_const (-c)

theorem has_fderiv_within_at.sub_const
  (hf : has_fderiv_within_at f f' s x) (c : F) :
  has_fderiv_within_at (λ x, f x - c) f' s x :=
hf.sub_const c

theorem has_fderiv_at.sub_const
  (hf : has_fderiv_at f f' x) (c : F) :
  has_fderiv_at (λ x, f x - c) f' x :=
hf.sub_const c

lemma differentiable_within_at.sub_const
  (hf : differentiable_within_at 𝕜 f s x) (c : F) :
  differentiable_within_at 𝕜 (λ y, f y - c) s x :=
(hf.has_fderiv_within_at.sub_const c).differentiable_within_at

lemma differentiable_at.sub_const
  (hf : differentiable_at 𝕜 f x) (c : F) :
  differentiable_at 𝕜 (λ y, f y - c) x :=
(hf.has_fderiv_at.sub_const c).differentiable_at

lemma differentiable_on.sub_const
  (hf : differentiable_on 𝕜 f s) (c : F) :
  differentiable_on 𝕜 (λy, f y - c) s :=
λx hx, (hf x hx).sub_const c

lemma differentiable.sub_const
  (hf : differentiable 𝕜 f) (c : F) :
  differentiable 𝕜 (λy, f y - c) :=
λx, (hf x).sub_const c

lemma fderiv_within_sub_const (hxs : unique_diff_within_at 𝕜 s x)
  (hf : differentiable_within_at 𝕜 f s x) (c : F) :
  fderiv_within 𝕜 (λy, f y - c) s x = fderiv_within 𝕜 f s x :=
(hf.has_fderiv_within_at.sub_const c).fderiv_within hxs

lemma fderiv_sub_const
  (hf : differentiable_at 𝕜 f x) (c : F) :
  fderiv 𝕜 (λy, f y - c) x = fderiv 𝕜 f x :=
(hf.has_fderiv_at.sub_const c).fderiv

theorem has_fderiv_at_filter.const_sub
  (hf : has_fderiv_at_filter f f' x L) (c : F) :
  has_fderiv_at_filter (λ x, c - f x) (-f') x L :=
hf.neg.const_add c

theorem has_fderiv_within_at.const_sub
  (hf : has_fderiv_within_at f f' s x) (c : F) :
  has_fderiv_within_at (λ x, c - f x) (-f') s x :=
hf.const_sub c

theorem has_fderiv_at.const_sub
  (hf : has_fderiv_at f f' x) (c : F) :
  has_fderiv_at (λ x, c - f x) (-f') x :=
hf.const_sub c

lemma differentiable_within_at.const_sub
  (hf : differentiable_within_at 𝕜 f s x) (c : F) :
  differentiable_within_at 𝕜 (λ y, c - f y) s x :=
(hf.has_fderiv_within_at.const_sub c).differentiable_within_at

lemma differentiable_at.const_sub
  (hf : differentiable_at 𝕜 f x) (c : F) :
  differentiable_at 𝕜 (λ y, c - f y) x :=
(hf.has_fderiv_at.const_sub c).differentiable_at

lemma differentiable_on.const_sub
  (hf : differentiable_on 𝕜 f s) (c : F) :
  differentiable_on 𝕜 (λy, c - f y) s :=
λx hx, (hf x hx).const_sub c

lemma differentiable.const_sub
  (hf : differentiable 𝕜 f) (c : F) :
  differentiable 𝕜 (λy, c - f y) :=
λx, (hf x).const_sub c

lemma fderiv_within_const_sub (hxs : unique_diff_within_at 𝕜 s x)
  (hf : differentiable_within_at 𝕜 f s x) (c : F) :
  fderiv_within 𝕜 (λy, c - f y) s x = -fderiv_within 𝕜 f s x :=
(hf.has_fderiv_within_at.const_sub c).fderiv_within hxs

lemma fderiv_const_sub
  (hf : differentiable_at 𝕜 f x) (c : F) :
  fderiv 𝕜 (λy, c - f y) x = -fderiv 𝕜 f x :=
(hf.has_fderiv_at.const_sub c).fderiv

end sub

section continuous
/-! ### Deducing continuity from differentiability -/

theorem has_fderiv_at_filter.tendsto_nhds
  (hL : L ≤ 𝓝 x) (h : has_fderiv_at_filter f f' x L) :
  tendsto f L (𝓝 (f x)) :=
begin
  have : tendsto (λ x', f x' - f x) L (𝓝 0),
  { refine h.is_O_sub.trans_tendsto (tendsto_le_left hL _),
    rw ← sub_self x, exact tendsto_id.sub tendsto_const_nhds },
  have := tendsto.add this tendsto_const_nhds,
  rw zero_add (f x) at this,
  exact this.congr (by simp)
end

theorem has_fderiv_within_at.continuous_within_at
  (h : has_fderiv_within_at f f' s x) : continuous_within_at f s x :=
has_fderiv_at_filter.tendsto_nhds lattice.inf_le_left h

theorem has_fderiv_at.continuous_at (h : has_fderiv_at f f' x) :
  continuous_at f x :=
has_fderiv_at_filter.tendsto_nhds (le_refl _) h

lemma differentiable_within_at.continuous_within_at (h : differentiable_within_at 𝕜 f s x) :
  continuous_within_at f s x :=
let ⟨f', hf'⟩ := h in hf'.continuous_within_at

lemma differentiable_at.continuous_at (h : differentiable_at 𝕜 f x) : continuous_at f x :=
let ⟨f', hf'⟩ := h in hf'.continuous_at

lemma differentiable_on.continuous_on (h : differentiable_on 𝕜 f s) : continuous_on f s :=
λx hx, (h x hx).continuous_within_at

lemma differentiable.continuous (h : differentiable 𝕜 f) : continuous f :=
continuous_iff_continuous_at.2 $ λx, (h x).continuous_at

end continuous

section bilinear_map
/-! ### Derivative of a bounded bilinear map -/

variables {b : E × F → G} {u : set (E × F) }

open normed_field

lemma is_bounded_bilinear_map.has_fderiv_at (h : is_bounded_bilinear_map 𝕜 b) (p : E × F) :
  has_fderiv_at b (h.deriv p) p :=
begin
  have : (λ (x : E × F), b x - b p - (h.deriv p) (x - p)) = (λx, b (x.1 - p.1, x.2 - p.2)),
  { ext x,
    delta is_bounded_bilinear_map.deriv,
    change b x - b p - (b (p.1, x.2-p.2) + b (x.1-p.1, p.2))
           = b (x.1 - p.1, x.2 - p.2),
    have : b x = b (x.1, x.2), by { cases x, refl },
    rw this,
    have : b p = b (p.1, p.2), by { cases p, refl },
    rw this,
    simp only [h.map_sub_left, h.map_sub_right],
    abel },
  rw [has_fderiv_at, has_fderiv_at_filter, this],
  rcases h.bound with ⟨C, Cpos, hC⟩,
  have A : asymptotics.is_O (λx : E × F, b (x.1 - p.1, x.2 - p.2))
    (λx, ∥x - p∥ * ∥x - p∥) (𝓝 p) :=
  ⟨C, filter.univ_mem_sets' (λx, begin
    simp only [mem_set_of_eq, norm_mul, norm_norm],
    calc ∥b (x.1 - p.1, x.2 - p.2)∥ ≤ C * ∥x.1 - p.1∥ * ∥x.2 - p.2∥ : hC _ _
    ... ≤ C * ∥x-p∥ * ∥x-p∥ : by apply_rules [mul_le_mul, le_max_left, le_max_right, norm_nonneg,
      le_of_lt Cpos, le_refl, mul_nonneg, norm_nonneg, norm_nonneg]
    ... = C * (∥x-p∥ * ∥x-p∥) : mul_assoc _ _ _ end)⟩,
  have B : asymptotics.is_o (λ (x : E × F), ∥x - p∥ * ∥x - p∥)
    (λx, 1 * ∥x - p∥) (𝓝 p),
  { refine asymptotics.is_o.mul_is_O (asymptotics.is_o.norm_left _) (asymptotics.is_O_refl _ _),
    apply (asymptotics.is_o_one_iff ℝ).2,
    rw [← sub_self p],
    exact tendsto_id.sub tendsto_const_nhds },
  simp only [one_mul, asymptotics.is_o_norm_right] at B,
  exact A.trans_is_o B
end

lemma is_bounded_bilinear_map.has_fderiv_within_at (h : is_bounded_bilinear_map 𝕜 b) (p : E × F) :
  has_fderiv_within_at b (h.deriv p) u p :=
(h.has_fderiv_at p).has_fderiv_within_at

lemma is_bounded_bilinear_map.differentiable_at (h : is_bounded_bilinear_map 𝕜 b) (p : E × F) :
  differentiable_at 𝕜 b p :=
(h.has_fderiv_at p).differentiable_at

lemma is_bounded_bilinear_map.differentiable_within_at (h : is_bounded_bilinear_map 𝕜 b) (p : E × F) :
  differentiable_within_at 𝕜 b u p :=
(h.differentiable_at p).differentiable_within_at

lemma is_bounded_bilinear_map.fderiv (h : is_bounded_bilinear_map 𝕜 b) (p : E × F) :
  fderiv 𝕜 b p = h.deriv p :=
has_fderiv_at.fderiv (h.has_fderiv_at p)

lemma is_bounded_bilinear_map.fderiv_within (h : is_bounded_bilinear_map 𝕜 b) (p : E × F)
  (hxs : unique_diff_within_at 𝕜 u p) : fderiv_within 𝕜 b u p = h.deriv p :=
begin
  rw differentiable_at.fderiv_within (h.differentiable_at p) hxs,
  exact h.fderiv p
end

lemma is_bounded_bilinear_map.differentiable (h : is_bounded_bilinear_map 𝕜 b) :
  differentiable 𝕜 b :=
λx, h.differentiable_at x

lemma is_bounded_bilinear_map.differentiable_on (h : is_bounded_bilinear_map 𝕜 b) :
  differentiable_on 𝕜 b u :=
h.differentiable.differentiable_on

lemma is_bounded_bilinear_map.continuous (h : is_bounded_bilinear_map 𝕜 b) :
  continuous b :=
h.differentiable.continuous

lemma is_bounded_bilinear_map.continuous_left (h : is_bounded_bilinear_map 𝕜 b) {f : F} :
  continuous (λe, b (e, f)) :=
h.continuous.comp (continuous_id.prod_mk continuous_const)

lemma is_bounded_bilinear_map.continuous_right (h : is_bounded_bilinear_map 𝕜 b) {e : E} :
  continuous (λf, b (e, f)) :=
h.continuous.comp (continuous_const.prod_mk continuous_id)

end bilinear_map

section cartesian_product
/-! ### Derivative of the cartesian product of two functions -/

variables {f₂ : E → G} {f₂' : E →L[𝕜] G}

lemma has_fderiv_at_filter.prod
  (hf₁ : has_fderiv_at_filter f₁ f₁' x L) (hf₂ : has_fderiv_at_filter f₂ f₂' x L) :
  has_fderiv_at_filter (λx, (f₁ x, f₂ x)) (continuous_linear_map.prod f₁' f₂') x L :=
begin
  have : (λ (x' : E), (f₁ x', f₂ x') - (f₁ x, f₂ x) - (continuous_linear_map.prod f₁' f₂') (x' -x)) =
           (λ (x' : E), (f₁ x' - f₁ x - f₁' (x' - x), f₂ x' - f₂ x - f₂' (x' - x))) := rfl,
  rw [has_fderiv_at_filter, this],
  rw [asymptotics.is_o_prod_left],
  exact ⟨hf₁, hf₂⟩
end

lemma has_fderiv_within_at.prod
  (hf₁ : has_fderiv_within_at f₁ f₁' s x) (hf₂ : has_fderiv_within_at f₂ f₂' s x) :
  has_fderiv_within_at (λx, (f₁ x, f₂ x)) (continuous_linear_map.prod f₁' f₂') s x :=
hf₁.prod hf₂

lemma has_fderiv_at.prod (hf₁ : has_fderiv_at f₁ f₁' x) (hf₂ : has_fderiv_at f₂ f₂' x) :
  has_fderiv_at (λx, (f₁ x, f₂ x)) (continuous_linear_map.prod f₁' f₂') x :=
hf₁.prod hf₂

lemma differentiable_within_at.prod
  (hf₁ : differentiable_within_at 𝕜 f₁ s x) (hf₂ : differentiable_within_at 𝕜 f₂ s x) :
  differentiable_within_at 𝕜 (λx:E, (f₁ x, f₂ x)) s x :=
(hf₁.has_fderiv_within_at.prod hf₂.has_fderiv_within_at).differentiable_within_at

lemma differentiable_at.prod (hf₁ : differentiable_at 𝕜 f₁ x) (hf₂ : differentiable_at 𝕜 f₂ x) :
  differentiable_at 𝕜 (λx:E, (f₁ x, f₂ x)) x :=
(hf₁.has_fderiv_at.prod hf₂.has_fderiv_at).differentiable_at

lemma differentiable_on.prod (hf₁ : differentiable_on 𝕜 f₁ s) (hf₂ : differentiable_on 𝕜 f₂ s) :
  differentiable_on 𝕜 (λx:E, (f₁ x, f₂ x)) s :=
λx hx, differentiable_within_at.prod (hf₁ x hx) (hf₂ x hx)

lemma differentiable.prod (hf₁ : differentiable 𝕜 f₁) (hf₂ : differentiable 𝕜 f₂) :
  differentiable 𝕜 (λx:E, (f₁ x, f₂ x)) :=
λ x, differentiable_at.prod (hf₁ x) (hf₂ x)

lemma differentiable_at.fderiv_prod
  (hf₁ : differentiable_at 𝕜 f₁ x) (hf₂ : differentiable_at 𝕜 f₂ x) :
  fderiv 𝕜 (λx:E, (f₁ x, f₂ x)) x =
    continuous_linear_map.prod (fderiv 𝕜 f₁ x) (fderiv 𝕜 f₂ x) :=
has_fderiv_at.fderiv (has_fderiv_at.prod hf₁.has_fderiv_at hf₂.has_fderiv_at)

lemma differentiable_at.fderiv_within_prod
  (hf₁ : differentiable_within_at 𝕜 f₁ s x) (hf₂ : differentiable_within_at 𝕜 f₂ s x)
  (hxs : unique_diff_within_at 𝕜 s x) :
  fderiv_within 𝕜 (λx:E, (f₁ x, f₂ x)) s x =
    continuous_linear_map.prod (fderiv_within 𝕜 f₁ s x) (fderiv_within 𝕜 f₂ s x) :=
begin
  apply has_fderiv_within_at.fderiv_within _ hxs,
  exact has_fderiv_within_at.prod hf₁.has_fderiv_within_at hf₂.has_fderiv_within_at
end

end cartesian_product

section composition
/-! ###
Derivative of the composition of two functions

For composition lemmas, we put x explicit to help the elaborator, as otherwise Lean tends to
get confused since there are too many possibilities for composition -/

variable (x)

theorem has_fderiv_at_filter.comp {g : F → G} {g' : F →L[𝕜] G}
  (hg : has_fderiv_at_filter g g' (f x) (L.map f))
  (hf : has_fderiv_at_filter f f' x L) :
  has_fderiv_at_filter (g ∘ f) (g'.comp f') x L :=
let eq₁ := (g'.is_O_comp _ _).trans_is_o hf in
let eq₂ := (hg.comp_tendsto tendsto_map).trans_is_O hf.is_O_sub in
by { refine eq₂.triangle (eq₁.congr_left (λ x', _)), simp }

/- A readable version of the previous theorem,
   a general form of the chain rule. -/

example {g : F → G} {g' : F →L[𝕜] G}
  (hg : has_fderiv_at_filter g g' (f x) (L.map f))
  (hf : has_fderiv_at_filter f f' x L) :
  has_fderiv_at_filter (g ∘ f) (g'.comp f') x L :=
begin
  unfold has_fderiv_at_filter at hg,
  have : is_o (λ x', g (f x') - g (f x) - g' (f x' - f x)) (λ x', f x' - f x) L,
    from hg.comp_tendsto (le_refl _),
  have eq₁ : is_o (λ x', g (f x') - g (f x) - g' (f x' - f x)) (λ x', x' - x) L,
    from this.trans_is_O hf.is_O_sub,
  have eq₂ : is_o (λ x', f x' - f x - f' (x' - x)) (λ x', x' - x) L,
    from hf,
  have : is_O
    (λ x', g' (f x' - f x - f' (x' - x))) (λ x', f x' - f x - f' (x' - x)) L,
    from g'.is_O_comp _ _,
  have : is_o (λ x', g' (f x' - f x - f' (x' - x))) (λ x', x' - x) L,
    from this.trans_is_o eq₂,
  have eq₃ : is_o (λ x', g' (f x' - f x) - (g' (f' (x' - x)))) (λ x', x' - x) L,
    by { refine this.congr_left _, simp},
  exact eq₁.triangle eq₃
end

theorem has_fderiv_within_at.comp {g : F → G} {g' : F →L[𝕜] G} {t : set F}
  (hg : has_fderiv_within_at g g' t (f x)) (hf : has_fderiv_within_at f f' s x) (hst : s ⊆ f ⁻¹' t) :
  has_fderiv_within_at (g ∘ f) (g'.comp f') s x :=
begin
  apply has_fderiv_at_filter.comp _ (has_fderiv_at_filter.mono hg _) hf,
  calc map f (nhds_within x s)
      ≤ nhds_within (f x) (f '' s) : hf.continuous_within_at.tendsto_nhds_within_image
  ... ≤ nhds_within (f x) t        : nhds_within_mono _ (image_subset_iff.mpr hst)
end

/-- The chain rule. -/
theorem has_fderiv_at.comp {g : F → G} {g' : F →L[𝕜] G}
  (hg : has_fderiv_at g g' (f x)) (hf : has_fderiv_at f f' x) :
  has_fderiv_at (g ∘ f) (g'.comp f') x :=
(hg.mono hf.continuous_at).comp x hf

theorem has_fderiv_at.comp_has_fderiv_within_at {g : F → G} {g' : F →L[𝕜] G}
  (hg : has_fderiv_at g g' (f x)) (hf : has_fderiv_within_at f f' s x) :
  has_fderiv_within_at (g ∘ f) (g'.comp f') s x :=
begin
  rw ← has_fderiv_within_at_univ at hg,
  exact has_fderiv_within_at.comp x hg hf subset_preimage_univ
end

lemma differentiable_within_at.comp {g : F → G} {t : set F}
  (hg : differentiable_within_at 𝕜 g t (f x)) (hf : differentiable_within_at 𝕜 f s x)
  (h : s ⊆ f ⁻¹' t) : differentiable_within_at 𝕜 (g ∘ f) s x :=
begin
  rcases hf with ⟨f', hf'⟩,
  rcases hg with ⟨g', hg'⟩,
  exact ⟨continuous_linear_map.comp g' f', hg'.comp x hf' h⟩
end

lemma differentiable_at.comp {g : F → G}
  (hg : differentiable_at 𝕜 g (f x)) (hf : differentiable_at 𝕜 f x) :
  differentiable_at 𝕜 (g ∘ f) x :=
(hg.has_fderiv_at.comp x hf.has_fderiv_at).differentiable_at

lemma differentiable_at.comp_differentiable_within_at {g : F → G}
  (hg : differentiable_at 𝕜 g (f x)) (hf : differentiable_within_at 𝕜 f s x) :
  differentiable_within_at 𝕜 (g ∘ f) s x :=
(differentiable_within_at_univ.2 hg).comp x hf (by simp)

lemma fderiv_within.comp {g : F → G} {t : set F}
  (hg : differentiable_within_at 𝕜 g t (f x)) (hf : differentiable_within_at 𝕜 f s x)
  (h : s ⊆ f ⁻¹' t) (hxs : unique_diff_within_at 𝕜 s x) :
  fderiv_within 𝕜 (g ∘ f) s x = (fderiv_within 𝕜 g t (f x)).comp (fderiv_within 𝕜 f s x) :=
begin
  apply has_fderiv_within_at.fderiv_within _ hxs,
  exact has_fderiv_within_at.comp x (hg.has_fderiv_within_at) (hf.has_fderiv_within_at) h
end

lemma fderiv.comp {g : F → G}
  (hg : differentiable_at 𝕜 g (f x)) (hf : differentiable_at 𝕜 f x) :
  fderiv 𝕜 (g ∘ f) x = (fderiv 𝕜 g (f x)).comp (fderiv 𝕜 f x) :=
begin
  apply has_fderiv_at.fderiv,
  exact has_fderiv_at.comp x hg.has_fderiv_at hf.has_fderiv_at
end

lemma fderiv.comp_fderiv_within {g : F → G}
  (hg : differentiable_at 𝕜 g (f x)) (hf : differentiable_within_at 𝕜 f s x)
  (hxs : unique_diff_within_at 𝕜 s x) :
  fderiv_within 𝕜 (g ∘ f) s x = (fderiv 𝕜 g (f x)).comp (fderiv_within 𝕜 f s x) :=
begin
  apply has_fderiv_within_at.fderiv_within _ hxs,
  exact has_fderiv_at.comp_has_fderiv_within_at x (hg.has_fderiv_at) (hf.has_fderiv_within_at)
end

lemma differentiable_on.comp {g : F → G} {t : set F}
  (hg : differentiable_on 𝕜 g t) (hf : differentiable_on 𝕜 f s) (st : s ⊆ f ⁻¹' t) :
  differentiable_on 𝕜 (g ∘ f) s :=
λx hx, differentiable_within_at.comp x (hg (f x) (st hx)) (hf x hx) st

lemma differentiable.comp {g : F → G} (hg : differentiable 𝕜 g) (hf : differentiable 𝕜 f) :
  differentiable 𝕜 (g ∘ f) :=
λx, differentiable_at.comp x (hg (f x)) (hf x)

lemma differentiable.comp_differentiable_on {g : F → G} (hg : differentiable 𝕜 g)
  (hf : differentiable_on 𝕜 f s) :
  differentiable_on 𝕜 (g ∘ f) s :=
(differentiable_on_univ.2 hg).comp hf (by simp)

end composition

section smul
/-! ### Derivative of the product of a scalar-valued function and a vector-valued function -/

variables {c : E → 𝕜} {c' : E →L[𝕜] 𝕜}

theorem has_fderiv_within_at.smul
  (hc : has_fderiv_within_at c c' s x) (hf : has_fderiv_within_at f f' s x) :
  has_fderiv_within_at (λ y, c y • f y) (c x • f' + c'.smul_right (f x)) s x :=
begin
  have : is_bounded_bilinear_map 𝕜 (λ (p : 𝕜 × F), p.1 • p.2) := is_bounded_bilinear_map_smul,
  exact has_fderiv_at.comp_has_fderiv_within_at x (this.has_fderiv_at (c x, f x)) (hc.prod hf)
end

theorem has_fderiv_at.smul (hc : has_fderiv_at c c' x) (hf : has_fderiv_at f f' x) :
  has_fderiv_at (λ y, c y • f y) (c x • f' + c'.smul_right (f x)) x :=
begin
  have : is_bounded_bilinear_map 𝕜 (λ (p : 𝕜 × F), p.1 • p.2) := is_bounded_bilinear_map_smul,
  exact has_fderiv_at.comp x (this.has_fderiv_at (c x, f x)) (hc.prod hf)
end

lemma differentiable_within_at.smul
  (hc : differentiable_within_at 𝕜 c s x) (hf : differentiable_within_at 𝕜 f s x) :
  differentiable_within_at 𝕜 (λ y, c y • f y) s x :=
(hc.has_fderiv_within_at.smul hf.has_fderiv_within_at).differentiable_within_at

lemma differentiable_at.smul (hc : differentiable_at 𝕜 c x) (hf : differentiable_at 𝕜 f x) :
  differentiable_at 𝕜 (λ y, c y • f y) x :=
(hc.has_fderiv_at.smul hf.has_fderiv_at).differentiable_at

lemma differentiable_on.smul (hc : differentiable_on 𝕜 c s) (hf : differentiable_on 𝕜 f s) :
  differentiable_on 𝕜 (λ y, c y • f y) s :=
λx hx, (hc x hx).smul (hf x hx)

lemma differentiable.smul (hc : differentiable 𝕜 c) (hf : differentiable 𝕜 f) :
  differentiable 𝕜 (λ y, c y • f y) :=
λx, (hc x).smul (hf x)

lemma fderiv_within_smul (hxs : unique_diff_within_at 𝕜 s x)
  (hc : differentiable_within_at 𝕜 c s x) (hf : differentiable_within_at 𝕜 f s x) :
  fderiv_within 𝕜 (λ y, c y • f y) s x =
    c x • fderiv_within 𝕜 f s x + (fderiv_within 𝕜 c s x).smul_right (f x) :=
(hc.has_fderiv_within_at.smul hf.has_fderiv_within_at).fderiv_within hxs

lemma fderiv_smul (hc : differentiable_at 𝕜 c x) (hf : differentiable_at 𝕜 f x) :
  fderiv 𝕜 (λ y, c y • f y) x =
    c x • fderiv 𝕜 f x + (fderiv 𝕜 c x).smul_right (f x) :=
(hc.has_fderiv_at.smul hf.has_fderiv_at).fderiv

theorem has_fderiv_within_at.smul_const (hc : has_fderiv_within_at c c' s x) (f : F) :
  has_fderiv_within_at (λ y, c y • f) (c'.smul_right f) s x :=
begin
  convert hc.smul (has_fderiv_within_at_const f x s),
  -- Help Lean find an instance
  letI : distrib_mul_action 𝕜 (E →L[𝕜] F) :=
    continuous_linear_map.module.to_distrib_mul_action,
  rw [smul_zero, zero_add]
end

theorem has_fderiv_at.smul_const (hc : has_fderiv_at c c' x) (f : F) :
  has_fderiv_at (λ y, c y • f) (c'.smul_right f) x :=
begin
  rw [← has_fderiv_within_at_univ] at *,
  exact hc.smul_const f
end

lemma differentiable_within_at.smul_const
  (hc : differentiable_within_at 𝕜 c s x) (f : F) :
  differentiable_within_at 𝕜 (λ y, c y • f) s x :=
(hc.has_fderiv_within_at.smul_const f).differentiable_within_at

lemma differentiable_at.smul_const (hc : differentiable_at 𝕜 c x) (f : F) :
  differentiable_at 𝕜 (λ y, c y • f) x :=
(hc.has_fderiv_at.smul_const f).differentiable_at

lemma differentiable_on.smul_const (hc : differentiable_on 𝕜 c s) (f : F) :
  differentiable_on 𝕜 (λ y, c y • f) s :=
λx hx, (hc x hx).smul_const f

lemma differentiable.smul_const (hc : differentiable 𝕜 c) (f : F) :
  differentiable 𝕜 (λ y, c y • f) :=
λx, (hc x).smul_const f

lemma fderiv_within_smul_const (hxs : unique_diff_within_at 𝕜 s x)
  (hc : differentiable_within_at 𝕜 c s x) (f : F) :
  fderiv_within 𝕜 (λ y, c y • f) s x =
    (fderiv_within 𝕜 c s x).smul_right f :=
(hc.has_fderiv_within_at.smul_const f).fderiv_within hxs

lemma fderiv_smul_const (hc : differentiable_at 𝕜 c x) (f : F) :
  fderiv 𝕜 (λ y, c y • f) x = (fderiv 𝕜 c x).smul_right f :=
(hc.has_fderiv_at.smul_const f).fderiv

end smul

section mul
/-! ### Derivative of the product of two scalar-valued functions -/

set_option class.instance_max_depth 120
variables {c d : E → 𝕜} {c' d' : E →L[𝕜] 𝕜}

theorem has_fderiv_within_at.mul
  (hc : has_fderiv_within_at c c' s x) (hd : has_fderiv_within_at d d' s x) :
  has_fderiv_within_at (λ y, c y * d y) (c x • d' + d x • c') s x :=
begin
  have : is_bounded_bilinear_map 𝕜 (λ (p : 𝕜 × 𝕜), p.1 * p.2) := is_bounded_bilinear_map_mul,
  convert has_fderiv_at.comp_has_fderiv_within_at x (this.has_fderiv_at (c x, d x)) (hc.prod hd),
  ext z,
  change c x * d' z + d x * c' z = c x * d' z + c' z * d x,
  ring
end

theorem has_fderiv_at.mul (hc : has_fderiv_at c c' x) (hd : has_fderiv_at d d' x) :
  has_fderiv_at (λ y, c y * d y) (c x • d' + d x • c') x :=
begin
  have : is_bounded_bilinear_map 𝕜 (λ (p : 𝕜 × 𝕜), p.1 * p.2) := is_bounded_bilinear_map_mul,
  convert has_fderiv_at.comp x (this.has_fderiv_at (c x, d x)) (hc.prod hd),
  ext z,
  change c x * d' z + d x * c' z = c x * d' z + c' z * d x,
  ring
end

lemma differentiable_within_at.mul
  (hc : differentiable_within_at 𝕜 c s x) (hd : differentiable_within_at 𝕜 d s x) :
  differentiable_within_at 𝕜 (λ y, c y * d y) s x :=
(hc.has_fderiv_within_at.mul hd.has_fderiv_within_at).differentiable_within_at

lemma differentiable_at.mul (hc : differentiable_at 𝕜 c x) (hd : differentiable_at 𝕜 d x) :
  differentiable_at 𝕜 (λ y, c y * d y) x :=
(hc.has_fderiv_at.mul hd.has_fderiv_at).differentiable_at

lemma differentiable_on.mul (hc : differentiable_on 𝕜 c s) (hd : differentiable_on 𝕜 d s) :
  differentiable_on 𝕜 (λ y, c y * d y) s :=
λx hx, (hc x hx).mul (hd x hx)

lemma differentiable.mul (hc : differentiable 𝕜 c) (hd : differentiable 𝕜 d) :
  differentiable 𝕜 (λ y, c y * d y) :=
λx, (hc x).mul (hd x)

lemma fderiv_within_mul (hxs : unique_diff_within_at 𝕜 s x)
  (hc : differentiable_within_at 𝕜 c s x) (hd : differentiable_within_at 𝕜 d s x) :
  fderiv_within 𝕜 (λ y, c y * d y) s x =
    c x • fderiv_within 𝕜 d s x + d x • fderiv_within 𝕜 c s x :=
(hc.has_fderiv_within_at.mul hd.has_fderiv_within_at).fderiv_within hxs

lemma fderiv_mul (hc : differentiable_at 𝕜 c x) (hd : differentiable_at 𝕜 d x) :
  fderiv 𝕜 (λ y, c y * d y) x =
    c x • fderiv 𝕜 d x + d x • fderiv 𝕜 c x :=
(hc.has_fderiv_at.mul hd.has_fderiv_at).fderiv

theorem has_fderiv_within_at.mul_const
  (hc : has_fderiv_within_at c c' s x) (d : 𝕜) :
  has_fderiv_within_at (λ y, c y * d) (d • c') s x :=
begin
  have := hc.mul (has_fderiv_within_at_const d x s),
  letI : distrib_mul_action 𝕜 (E →L[𝕜] 𝕜) := continuous_linear_map.module.to_distrib_mul_action,
  rwa [smul_zero, zero_add] at this
end

theorem has_fderiv_at.mul_const (hc : has_fderiv_at c c' x) (d : 𝕜) :
  has_fderiv_at (λ y, c y * d) (d • c') x :=
begin
  rw [← has_fderiv_within_at_univ] at *,
  exact hc.mul_const d
end

lemma differentiable_within_at.mul_const
  (hc : differentiable_within_at 𝕜 c s x) (d : 𝕜) :
  differentiable_within_at 𝕜 (λ y, c y * d) s x :=
(hc.has_fderiv_within_at.mul_const d).differentiable_within_at

lemma differentiable_at.mul_const (hc : differentiable_at 𝕜 c x) (d : 𝕜) :
  differentiable_at 𝕜 (λ y, c y * d) x :=
(hc.has_fderiv_at.mul_const d).differentiable_at

lemma differentiable_on.mul_const (hc : differentiable_on 𝕜 c s) (d : 𝕜) :
  differentiable_on 𝕜 (λ y, c y * d) s :=
λx hx, (hc x hx).mul_const d

lemma differentiable.mul_const (hc : differentiable 𝕜 c) (d : 𝕜) :
  differentiable 𝕜 (λ y, c y * d) :=
λx, (hc x).mul_const d

lemma fderiv_within_mul_const (hxs : unique_diff_within_at 𝕜 s x)
  (hc : differentiable_within_at 𝕜 c s x) (d : 𝕜) :
  fderiv_within 𝕜 (λ y, c y * d) s x = d • fderiv_within 𝕜 c s x :=
(hc.has_fderiv_within_at.mul_const d).fderiv_within hxs

lemma fderiv_mul_const (hc : differentiable_at 𝕜 c x) (d : 𝕜) :
  fderiv 𝕜 (λ y, c y * d) x = d • fderiv 𝕜 c x :=
(hc.has_fderiv_at.mul_const d).fderiv

theorem has_fderiv_within_at.const_mul
  (hc : has_fderiv_within_at c c' s x) (d : 𝕜) :
  has_fderiv_within_at (λ y, d * c y) (d • c') s x :=
begin
  simp only [mul_comm d],
  exact hc.mul_const d,
end

theorem has_fderiv_at.const_mul (hc : has_fderiv_at c c' x) (d : 𝕜) :
  has_fderiv_at (λ y, d * c y) (d • c') x :=
begin
  simp only [mul_comm d],
  exact hc.mul_const d,
end

lemma differentiable_within_at.const_mul
  (hc : differentiable_within_at 𝕜 c s x) (d : 𝕜) :
  differentiable_within_at 𝕜 (λ y, d * c y) s x :=
(hc.has_fderiv_within_at.const_mul d).differentiable_within_at

lemma differentiable_at.const_mul (hc : differentiable_at 𝕜 c x) (d : 𝕜) :
  differentiable_at 𝕜 (λ y, d * c y) x :=
(hc.has_fderiv_at.const_mul d).differentiable_at

lemma differentiable_on.const_mul (hc : differentiable_on 𝕜 c s) (d : 𝕜) :
  differentiable_on 𝕜 (λ y, d * c y) s :=
λx hx, (hc x hx).const_mul d

lemma differentiable.const_mul (hc : differentiable 𝕜 c) (d : 𝕜) :
  differentiable 𝕜 (λ y, d * c y) :=
λx, (hc x).const_mul d

lemma fderiv_within_const_mul (hxs : unique_diff_within_at 𝕜 s x)
  (hc : differentiable_within_at 𝕜 c s x) (d : 𝕜) :
  fderiv_within 𝕜 (λ y, d * c y) s x = d • fderiv_within 𝕜 c s x :=
(hc.has_fderiv_within_at.const_mul d).fderiv_within hxs

lemma fderiv_const_mul (hc : differentiable_at 𝕜 c x) (d : 𝕜) :
  fderiv 𝕜 (λ y, d * c y) x = d • fderiv 𝕜 c x :=
(hc.has_fderiv_at.const_mul d).fderiv

end mul

section continuous_linear_equiv
/-! ### Differentiability of linear equivs, and invariance of differentiability -/

variable (iso : E ≃L[𝕜] F)

protected lemma continuous_linear_equiv.has_fderiv_within_at :
  has_fderiv_within_at iso (iso : E →L[𝕜] F) s x :=
iso.to_continuous_linear_map.has_fderiv_within_at

protected lemma continuous_linear_equiv.has_fderiv_at : has_fderiv_at iso (iso : E →L[𝕜] F) x :=
iso.to_continuous_linear_map.has_fderiv_at_filter

protected lemma continuous_linear_equiv.differentiable_at : differentiable_at 𝕜 iso x :=
iso.has_fderiv_at.differentiable_at

protected lemma continuous_linear_equiv.differentiable_within_at :
  differentiable_within_at 𝕜 iso s x :=
iso.differentiable_at.differentiable_within_at

protected lemma continuous_linear_equiv.fderiv : fderiv 𝕜 iso x = iso :=
iso.has_fderiv_at.fderiv

protected lemma continuous_linear_equiv.fderiv_within (hxs : unique_diff_within_at 𝕜 s x) :
  fderiv_within 𝕜 iso s x = iso :=
iso.to_continuous_linear_map.fderiv_within hxs

protected lemma continuous_linear_equiv.differentiable : differentiable 𝕜 iso :=
λx, iso.differentiable_at

protected lemma continuous_linear_equiv.differentiable_on : differentiable_on 𝕜 iso s :=
iso.differentiable.differentiable_on

lemma continuous_linear_equiv.comp_differentiable_within_at_iff {f : G → E} {s : set G} {x : G} :
  differentiable_within_at 𝕜 (iso ∘ f) s x ↔ differentiable_within_at 𝕜 f s x :=
begin
  refine ⟨λ H, _, λ H, iso.differentiable.differentiable_at.comp_differentiable_within_at x H⟩,
  have : differentiable_within_at 𝕜 (iso.symm ∘ (iso ∘ f)) s x :=
    iso.symm.differentiable.differentiable_at.comp_differentiable_within_at x H,
  rwa [← function.comp.assoc iso.symm iso f, iso.symm_comp_self] at this,
end

lemma continuous_linear_equiv.comp_differentiable_at_iff {f : G → E} {x : G} :
  differentiable_at 𝕜 (iso ∘ f) x ↔ differentiable_at 𝕜 f x :=
by rw [← differentiable_within_at_univ, ← differentiable_within_at_univ,
       iso.comp_differentiable_within_at_iff]

lemma continuous_linear_equiv.comp_differentiable_on_iff {f : G → E} {s : set G} :
  differentiable_on 𝕜 (iso ∘ f) s ↔ differentiable_on 𝕜 f s :=
begin
  rw [differentiable_on, differentiable_on],
  simp only [iso.comp_differentiable_within_at_iff],
end

lemma continuous_linear_equiv.comp_differentiable_iff {f : G → E} :
  differentiable 𝕜 (iso ∘ f) ↔ differentiable 𝕜 f :=
begin
  rw [← differentiable_on_univ, ← differentiable_on_univ],
  exact iso.comp_differentiable_on_iff
end

lemma continuous_linear_equiv.comp_has_fderiv_within_at_iff
  {f : G → E} {s : set G} {x : G} {f' : G →L[𝕜] E} :
  has_fderiv_within_at (iso ∘ f) ((iso : E →L[𝕜] F).comp f') s x ↔ has_fderiv_within_at f f' s x :=
begin
  refine ⟨λ H, _, λ H, iso.has_fderiv_at.comp_has_fderiv_within_at x H⟩,
  have A : f = iso.symm ∘ (iso ∘ f), by { rw [← function.comp.assoc, iso.symm_comp_self], refl },
  have B : f' = (iso.symm : F →L[𝕜] E).comp ((iso : E →L[𝕜] F).comp f'),
    by rw [← continuous_linear_map.comp_assoc, iso.coe_symm_comp_coe, continuous_linear_map.id_comp],
  rw [A, B],
  exact iso.symm.has_fderiv_at.comp_has_fderiv_within_at x H
end

lemma continuous_linear_equiv.comp_has_fderiv_at_iff {f : G → E} {x : G} {f' : G →L[𝕜] E} :
  has_fderiv_at (iso ∘ f) ((iso : E →L[𝕜] F).comp f') x ↔ has_fderiv_at f f' x :=
by rw [← has_fderiv_within_at_univ, ← has_fderiv_within_at_univ, iso.comp_has_fderiv_within_at_iff]

lemma continuous_linear_equiv.comp_has_fderiv_within_at_iff'
  {f : G → E} {s : set G} {x : G} {f' : G →L[𝕜] F} :
  has_fderiv_within_at (iso ∘ f) f' s x ↔
  has_fderiv_within_at f ((iso.symm : F →L[𝕜] E).comp f') s x :=
begin
  set g := (iso.symm : F →L[𝕜] E).comp f' with h,
  have : f' = (iso : E →L[𝕜] F).comp g,
    by rw [h, ← continuous_linear_map.comp_assoc, iso.coe_comp_coe_symm,
           continuous_linear_map.id_comp],
  rw this,
  exact iso.comp_has_fderiv_within_at_iff
end

lemma continuous_linear_equiv.comp_has_fderiv_at_iff' {f : G → E} {x : G} {f' : G →L[𝕜] F} :
  has_fderiv_at (iso ∘ f) f' x ↔ has_fderiv_at f ((iso.symm : F →L[𝕜] E).comp f') x :=
by rw [← has_fderiv_within_at_univ, ← has_fderiv_within_at_univ, iso.comp_has_fderiv_within_at_iff']

lemma continuous_linear_equiv.comp_fderiv_within {f : G → E} {s : set G} {x : G}
  (hxs : unique_diff_within_at 𝕜 s x) :
  fderiv_within 𝕜 (iso ∘ f) s x = (iso : E →L[𝕜] F).comp (fderiv_within 𝕜 f s x) :=
begin
  by_cases h : differentiable_within_at 𝕜 f s x,
  { rw [fderiv.comp_fderiv_within x iso.differentiable_at h hxs, iso.fderiv] },
  { have : ¬differentiable_within_at 𝕜 (iso ∘ f) s x,
      by simp [-coe_fn_coe_base, iso.comp_differentiable_within_at_iff, h],
    rw [fderiv_within_zero_of_not_differentiable_within_at h,
        fderiv_within_zero_of_not_differentiable_within_at this],
    ext y,
    simp [-coe_fn_coe_base] }
end

lemma continuous_linear_equiv.comp_fderiv {f : G → E} {x : G} :
  fderiv 𝕜 (iso ∘ f) x = (iso : E →L[𝕜] F).comp (fderiv 𝕜 f x) :=
begin
  rw [← fderiv_within_univ, ← fderiv_within_univ],
  exact iso.comp_fderiv_within unique_diff_within_at_univ,
end

end continuous_linear_equiv

end

section
/-
  In the special case of a normed space over the reals,
  we can use  scalar multiplication in the `tendsto` characterization
  of the Fréchet derivative.
-/


variables {E : Type*} [normed_group E] [normed_space ℝ E]
variables {F : Type*} [normed_group F] [normed_space ℝ F]
variables {f : E → F} {f' : E →L[ℝ] F} {x : E}

theorem has_fderiv_at_filter_real_equiv {L : filter E} :
  tendsto (λ x' : E, ∥x' - x∥⁻¹ * ∥f x' - f x - f' (x' - x)∥) L (𝓝 0) ↔
  tendsto (λ x' : E, ∥x' - x∥⁻¹ • (f x' - f x - f' (x' - x))) L (𝓝 0) :=
begin
  symmetry,
  rw [tendsto_iff_norm_tendsto_zero], refine tendsto_congr (λ x', _),
  have : ∥x' + -x∥⁻¹ ≥ 0, from inv_nonneg.mpr (norm_nonneg _),
  simp [norm_smul, real.norm_eq_abs, abs_of_nonneg this]
end

lemma has_fderiv_at.lim_real (hf : has_fderiv_at f f' x) (v : E) :
  tendsto (λ (c:ℝ), c • (f (x + c⁻¹ • v) - f x)) at_top (𝓝 (f' v)) :=
begin
  apply hf.lim v,
  rw tendsto_at_top_at_top,
  exact λ b, ⟨b, λ a ha, le_trans ha (le_abs_self _)⟩
end

end

section tangent_cone

variables {𝕜 : Type*} [nondiscrete_normed_field 𝕜]
{E : Type*} [normed_group E] [normed_space 𝕜 E]
{F : Type*} [normed_group F] [normed_space 𝕜 F]
{f : E → F} {s : set E} {f' : E →L[𝕜] F}

/-- The image of a tangent cone under the differential of a map is included in the tangent cone to
the image. -/
lemma has_fderiv_within_at.image_tangent_cone_subset {x : E} (h : has_fderiv_within_at f f' s x) :
  f' '' (tangent_cone_at 𝕜 s x) ⊆ tangent_cone_at 𝕜 (f '' s) (f x) :=
begin
  rw image_subset_iff,
  rintros v ⟨c, d, dtop, clim, cdlim⟩,
  refine ⟨c, (λn, f (x + d n) - f x), mem_sets_of_superset dtop _, clim, h.lim at_top dtop clim cdlim⟩,
  simp [-mem_image, mem_image_of_mem] {contextual := tt}
end

/-- If a set has the unique differentiability property at a point x, then the image of this set
under a map with onto derivative has also the unique differentiability property at the image point.
-/
lemma has_fderiv_within_at.unique_diff_within_at {x : E} (h : has_fderiv_within_at f f' s x)
  (hs : unique_diff_within_at 𝕜 s x) (h' : closure (range f') = univ) :
  unique_diff_within_at 𝕜 (f '' s) (f x) :=
begin
  have A : ∀v ∈ tangent_cone_at 𝕜 s x, f' v ∈ tangent_cone_at 𝕜 (f '' s) (f x),
  { assume v hv,
    have := h.image_tangent_cone_subset,
    rw image_subset_iff at this,
    exact this hv },
  have B : ∀v ∈ (submodule.span 𝕜 (tangent_cone_at 𝕜 s x) : set E),
    f' v ∈ (submodule.span 𝕜 (tangent_cone_at 𝕜 (f '' s) (f x)) : set F),
  { assume v hv,
    apply submodule.span_induction hv,
    { exact λ w hw, submodule.subset_span (A w hw) },
    { simp },
    { assume w₁ w₂ hw₁ hw₂,
      rw continuous_linear_map.map_add,
      exact submodule.add_mem (submodule.span 𝕜 (tangent_cone_at 𝕜 (f '' s) (f x))) hw₁ hw₂ },
    { assume a w hw,
      rw continuous_linear_map.map_smul,
      exact submodule.smul_mem (submodule.span 𝕜 (tangent_cone_at 𝕜 (f '' s) (f x))) _ hw } },
  rw [unique_diff_within_at, ← univ_subset_iff],
  split,
  show f x ∈ closure (f '' s), from h.continuous_within_at.mem_closure_image hs.2,
  show univ ⊆ closure ↑(submodule.span 𝕜 (tangent_cone_at 𝕜 (f '' s) (f x))), from calc
    univ ⊆ closure (range f') : univ_subset_iff.2 h'
    ... = closure (f' '' univ) : by rw image_univ
    ... = closure (f' '' (closure (submodule.span 𝕜 (tangent_cone_at 𝕜 s x) : set E))) : by rw hs.1
    ... ⊆ closure (closure (f' '' (submodule.span 𝕜 (tangent_cone_at 𝕜 s x) : set E))) :
      closure_mono (image_closure_subset_closure_image f'.cont)
    ... = closure (f' '' (submodule.span 𝕜 (tangent_cone_at 𝕜 s x) : set E)) : closure_closure
    ... ⊆ closure (submodule.span 𝕜 (tangent_cone_at 𝕜 (f '' s) (f x)) : set F) :
      closure_mono (image_subset_iff.mpr B)
end

lemma has_fderiv_within_at.unique_diff_within_at_of_continuous_linear_equiv
  {x : E} (e' : E ≃L[𝕜] F) (h : has_fderiv_within_at f (e' : E →L[𝕜] F) s x)
  (hs : unique_diff_within_at 𝕜 s x) :
  unique_diff_within_at 𝕜 (f '' s) (f x) :=
begin
  apply h.unique_diff_within_at hs,
  have : range (e' : E →L[𝕜] F) = univ := e'.to_linear_equiv.to_equiv.range_eq_univ,
  rw [this, closure_univ]
end

lemma continuous_linear_equiv.unique_diff_on_preimage_iff (e : F ≃L[𝕜] E) :
  unique_diff_on 𝕜 (e ⁻¹' s) ↔ unique_diff_on 𝕜 s :=
begin
  split,
  { assume hs x hx,
    have A : s = e '' (e.symm '' s) :=
      (equiv.symm_image_image (e.symm.to_linear_equiv.to_equiv) s).symm,
    have B : e.symm '' s = e⁻¹' s :=
      equiv.image_eq_preimage e.symm.to_linear_equiv.to_equiv s,
    rw [A, B, (e.apply_symm_apply x).symm],
    refine has_fderiv_within_at.unique_diff_within_at_of_continuous_linear_equiv e
      e.has_fderiv_within_at (hs _ _),
    rwa [mem_preimage, e.apply_symm_apply x] },
  { assume hs x hx,
    have : e ⁻¹' s = e.symm '' s :=
      (equiv.image_eq_preimage e.symm.to_linear_equiv.to_equiv s).symm,
    rw [this, (e.symm_apply_apply x).symm],
    exact has_fderiv_within_at.unique_diff_within_at_of_continuous_linear_equiv e.symm
      e.symm.has_fderiv_within_at (hs _ hx) },
end

end tangent_cone

section restrict_scalars
/-! ### Restricting from `ℂ` to `ℝ`, or generally from `𝕜'` to `𝕜`

If a function is differentiable over `ℂ`, then it is differentiable over `ℝ`. In this paragraph,
we give variants of this statement, in the general situation where `ℂ` and `ℝ` are replaced
respectively by `𝕜'` and `𝕜` where `𝕜'` is a normed algebra over `𝕜`. -/

variables (𝕜 : Type*) [nondiscrete_normed_field 𝕜]
{𝕜' : Type*} [nondiscrete_normed_field 𝕜'] [normed_algebra 𝕜 𝕜']
{E : Type*} [normed_group E] [normed_space 𝕜' E]
{F : Type*} [normed_group F] [normed_space 𝕜' F]
{f : E → F} {f' : E →L[𝕜'] F} {s : set E} {x : E}

local attribute [instance] normed_space.restrict_scalars

lemma has_fderiv_at.restrict_scalars (h : has_fderiv_at f f' x) :
  has_fderiv_at f (f'.restrict_scalars 𝕜) x := h

lemma has_fderiv_within_at.restrict_scalars (h : has_fderiv_within_at f f' s x) :
  has_fderiv_within_at f (f'.restrict_scalars 𝕜) s x := h

lemma differentiable_at.restrict_scalars (h : differentiable_at 𝕜' f x) :
  differentiable_at 𝕜 f x :=
(h.has_fderiv_at.restrict_scalars 𝕜).differentiable_at

lemma differentiable_within_at.restrict_scalars (h : differentiable_within_at 𝕜' f s x) :
  differentiable_within_at 𝕜 f s x :=
(h.has_fderiv_within_at.restrict_scalars 𝕜).differentiable_within_at

lemma differentiable_on.restrict_scalars (h : differentiable_on 𝕜' f s) :
  differentiable_on 𝕜 f s :=
λx hx, (h x hx).restrict_scalars 𝕜

lemma differentiable.restrict_scalars (h : differentiable 𝕜' f) :
  differentiable 𝕜 f :=
λx, (h x).restrict_scalars 𝕜

end restrict_scalars
