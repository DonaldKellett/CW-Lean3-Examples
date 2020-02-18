/-
Copyright (c) 2020 Sébastien Gouëzel. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Sébastien Gouëzel
-/

import geometry.manifold.basic_smooth_bundle

/-!
# The derivative of functions between smooth manifolds

Let `M` and `M'` be two smooth manifolds with corners over a field `𝕜` (with respective models with
corners `I` on `(E, H)` and `I'` on `(E', H')`), and let `f : M → M'`. We define the
derivative of the function at a point, within a set or along the whole space, mimicking the API
for (Fréchet) derivatives. It is denoted by `mfderiv I I' f x`, where "m" stands for "manifold" and
"f" for "Fréchet" (as in the usual derivative `fderiv 𝕜 f x`).

## Main definitions

* `unique_mdiff_on I s` : predicate saying that, at each point of the set `s`, a function can have
  at most one derivative. This technical condition is important when we define
  `mfderiv_within` below, as otherwise there is an arbitrary choice in the derivative,
  and many properties will fail (for instance the chain rule). This is analogous to
  `unique_diff_on 𝕜 s` in a vector space.

Let `f` be a map between smooth manifolds. The following definitions follow the `fderiv` API.

* `mfderiv I I' f x` : the derivative of `f` at `x`, as a continuous linear map from the tangent
  space at `x` to the tangent space at `f x`. If the map is not differentiable, this is `0`.
* `mfderiv_within I I' f s x` : the derivative of `f` at `x` within `s`, as a continuous linear map
  from the tangent space at `x` to the tangent space at `f x`. If the map is not differentiable
  within `s`, this is `0`.
* `mdifferentiable_at I I' f x` : Prop expressing whether `f` is differentiable at `x`.
* `mdifferentiable_within_at 𝕜 f s x` : Prop expressing whether `f` is differentiable within `s`
  at `x`.
* `has_mfderiv_at I I' f s x f'` : Prop expressing whether `f` has `f'` as a derivative at `x`.
* `has_mfderiv_within_at I I' f s x f'` : Prop expressing whether `f` has `f'` as a derivative
  within `s` at `x`.
* `mdifferentiable_on I I' f s` : Prop expressing that `f` is differentiable on the set `s`.
* `mdifferentiable I I' f` : Prop expressing that `f` is differentiable everywhere.
* `bundle_mfderiv I I' f` : the derivative of `f`, as a map from the tangent bundle of `M` to the
  tangent bundle of `M'`.

We also establish results on the differential of the identity, constant functions, charts, extended
charts. For functions between vector spaces, we show that the usual notions and the manifold notions
coincide.

## Implementation notes

The tangent bundle is constructed using the machinery of topological fiber bundles, for which one
can define bundled morphisms and construct canonically maps from the total space of one bundle to
the total space of another one. One could use this mechanism to construct directly the derivative
of a smooth map. However, we want to define the derivative of any map (and let it be zero if the map
is not differentiable) to avoid proof arguments everywhere. This means we have to go back to the
details of the definition of the total space of a fiber bundle constructed from core, to cook up a
suitable definition of the derivative. It is the following: at each point, we have a preferred chart
(used to identify the fiber above the point with the model vector space in fiber bundles). Then one
should read the function using these preferred charts at `x` and `f x`, and take the derivative
of `f` in these charts.

Due to the fact that we are working in a model with corners, with an additional embedding `I` of the
model space `H` in the model vector space `E`, the charts taking values in `E` are not the original
charts of the manifold, but those ones composed with `I`, called extended charts. We
define `written_in_ext_chart I I' x f` for the function `f` written in the preferred extended charts.
Then the manifold derivative of `f`, at `x`, is just the usual derivative of
`written_in_ext_chart I I' x f`, at the point `(ext_chart_at I x).to_fun x`.

There is a subtelty with respect to continuity: if the function is not continuous, then the image
of a small open set around `x` will not be contained in the source of the preferred chart around
`f x`, which means that when reading `f` in the chart one is losing some information. To avoid this,
we include continuity in the definition of differentiablity (which is reasonable since with any
definition, differentiability implies continuity).

*Warning*: the derivative (even within a subset) is a linear map on the whole tangent space. Suppose
that one is given a smooth submanifold `N`, and a function which is smooth on `N` (i.e., its
restriction to the subtype  `N` is smooth). Then, in the whole manifold `M`, the property
`mdifferentiable_on I I' f N` holds. However, `mfderiv_within I I' f N` is not uniquely defined
(what values would one choose for vectors that are transverse to `N`?), which can create issues down
the road. The problem here is that knowing the value of `f` along `N` does not determine the
differential of `f` in all directions. This is in contrast to the case where `N` would be an open
subset, or a submanifold with boundary of maximal dimension, where this issue does not appear.
The predicate `unique_mdiff_on I N` indicates that the derivative along `N` is unique if it exists,
and is an assumption in most statements requiring a form of uniqueness.

On a vector space, the manifold derivative and the usual derivative are equal. This means in
particular that they live on the same space, i.e., the tangent space is defeq to the original vector
space. To get this property is a motivation for our definition of the tangent space as a single
copy of the vector space, instead of more usual definitions such as the space of derivations, or
the space of equivalence classes of smooth curves in the manifold.

## Notations

For the composition of local homeomorphisms and local equivs, we use respectively ` ≫ₕ` and ` ≫`.

## Tags
Derivative, manifold
-/

noncomputable theory
open_locale classical topological_space

open set

local infixr  ` ≫ₕ `:100 := local_homeomorph.trans
local infixr  ` ≫ `:100 := local_equiv.trans

universe u

section derivatives_definitions
/-!
### Derivative of maps between manifolds

The derivative of a smooth map `f` between smooth manifold `M` and `M'` at `x` is a bounded linear
map from the tangent space to `M` at `x`, to the tangent space to `M'` at `f x`. Since we defined
the tangent space using one specific chart, the formula for the derivative is written in terms of
this specific chart.

We use the names `mdifferentiable` and `mfderiv`, where the prefix letter `m` means "manifold".
-/

variables {𝕜 : Type*} [nondiscrete_normed_field 𝕜]
{E : Type*} [normed_group E] [normed_space 𝕜 E]
{H : Type*} [topological_space H] (I : model_with_corners 𝕜 E H)
{M : Type*} [topological_space M] [manifold H M]
{E' : Type*} [normed_group E'] [normed_space 𝕜 E']
{H' : Type*} [topological_space H'] (I' : model_with_corners 𝕜 E' H')
{M' : Type*} [topological_space M'] [manifold H' M']

/-- Predicate ensuring that, at a point and within a set, a function can have at most one
derivative. This is expressed using the preferred chart at the considered point. -/
def unique_mdiff_within_at (s : set M) (x : M) :=
unique_diff_within_at 𝕜 ((ext_chart_at I x).inv_fun ⁻¹' s ∩ range I.to_fun)
  ((ext_chart_at I x).to_fun x)

/-- Predicate ensuring that, at all points of a set, a function can have at most one derivative. -/
def unique_mdiff_on (s : set M) :=
∀x∈s, unique_mdiff_within_at I s x

/-- Conjugating a function to write it in the preferred charts around `x`. The manifold derivative
of `f` will just be the derivative of this conjugated function. -/
def written_in_ext_chart_at (x : M) (f : M → M') : E → E' :=
(ext_chart_at I' (f x)).to_fun ∘ f ∘ (ext_chart_at I x).inv_fun

/-- `mdifferentiable_within_at I I' f s x` indicates that the function `f` between manifolds
has a derivative at the point `x` within the set `s`.
This is a generalization of `differentiable_within_at` to manifolds.

We require continuity in the definition, as otherwise points close to `x` in `s` could be sent by
`f` outside of the chart domain around `f x`. Then the chart could do anything to the image points,
and in particular by coincidence `written_in_ext_chart_at I I' x f` could be differentiable, while
this would not mean anything relevant. -/
def mdifferentiable_within_at (f : M → M') (s : set M) (x : M) :=
continuous_within_at f s x ∧
differentiable_within_at 𝕜 (written_in_ext_chart_at I I' x f)
  ((ext_chart_at I x).inv_fun ⁻¹' s ∩ range I.to_fun) ((ext_chart_at I x).to_fun x)

/-- `mdifferentiable_at I I' f x` indicates that the function `f` between manifolds
has a derivative at the point `x`.
This is a generalization of `differentiable_at` to manifolds.

We require continuity in the definition, as otherwise points close to `x` could be sent by
`f` outside of the chart domain around `f x`. Then the chart could do anything to the image points,
and in particular by coincidence `written_in_ext_chart_at I I' x f` could be differentiable, while
this would not mean anything relevant. -/
def mdifferentiable_at (f : M → M') (x : M) :=
continuous_at f x ∧
differentiable_within_at 𝕜 (written_in_ext_chart_at I I' x f) (range I.to_fun)
  ((ext_chart_at I x).to_fun x)

/-- `mdifferentiable_on I I' f s` indicates that the function `f` between manifolds
has a derivative within `s` at all points of `s`.
This is a generalization of `differentiable_on` to manifolds. -/
def mdifferentiable_on (f : M → M') (s : set M) :=
∀x ∈ s, mdifferentiable_within_at I I' f s x

/-- `mdifferentiable I I' f` indicates that the function `f` between manifolds
has a derivative everywhere.
This is a generalization of `differentiable` to manifolds. -/
def mdifferentiable (f : M → M') :=
∀x, mdifferentiable_at I I' f x

/-- Prop registering if a local homeomorphism is a local diffeomorphism on its source -/
def local_homeomorph.mdifferentiable (f : local_homeomorph M M') :=
(mdifferentiable_on I I' f.to_fun f.source) ∧ (mdifferentiable_on I' I f.inv_fun f.target)

variables [smooth_manifold_with_corners I M] [smooth_manifold_with_corners I' M']

/-- `has_mfderiv_within_at I I' f s x f'` indicates that the function `f` between manifolds
has, at the point `x` and within the set `s`, the derivative `f'`. Here, `f'` is a continuous linear
map from the tangent space at `x` to the tangent space at `f x`.

This is a generalization of `has_fderiv_within_at` to manifolds (as indicated by the prefix `m`).
The order of arguments is changed as the type of the derivative `f'` depends on the choice of `x`.

We require continuity in the definition, as otherwise points close to `x` in `s` could be sent by
`f` outside of the chart domain around `f x`. Then the chart could do anything to the image points,
and in particular by coincidence `written_in_ext_chart_at I I' x f` could be differentiable, while
this would not mean anything relevant. -/
def has_mfderiv_within_at (f : M → M') (s : set M) (x : M)
  (f' : tangent_space I x →L[𝕜] tangent_space I' (f x)) :=
continuous_within_at f s x ∧
has_fderiv_within_at (written_in_ext_chart_at I I' x f : E → E') f'
  ((ext_chart_at I x).inv_fun ⁻¹' s ∩ range I.to_fun) ((ext_chart_at I x).to_fun x)

/-- `has_mfderiv_at I I' f x f'` indicates that the function `f` between manifolds
has, at the point `x`, the derivative `f'`. Here, `f'` is a continuous linear
map from the tangent space at `x` to the tangent space at `f x`.

We require continuity in the definition, as otherwise points close to `x` `s` could be sent by
`f` outside of the chart domain around `f x`. Then the chart could do anything to the image points,
and in particular by coincidence `written_in_ext_chart_at I I' x f` could be differentiable, while
this would not mean anything relevant. -/
def has_mfderiv_at (f : M → M') (x : M)
  (f' : tangent_space I x →L[𝕜] tangent_space I' (f x)) :=
continuous_at f x ∧
has_fderiv_within_at (written_in_ext_chart_at I I' x f : E → E') f' (range I.to_fun)
  ((ext_chart_at I x).to_fun x)

/-- Let `f` be a function between two smooth manifolds. Then `mfderiv_within I I' f s x` is the
derivative of `f` at `x` within `s`, as a continuous linear map from the tangent space at `x` to the
tangent space at `f x`. -/
def mfderiv_within (f : M → M') (s : set M) (x : M) : tangent_space I x →L[𝕜] tangent_space I' (f x) :=
if h : mdifferentiable_within_at I I' f s x then
(fderiv_within 𝕜 (written_in_ext_chart_at I I' x f) ((ext_chart_at I x).inv_fun ⁻¹' s ∩ range I.to_fun)
  ((ext_chart_at I x).to_fun x) : _)
else continuous_linear_map.zero

/-- Let `f` be a function between two smooth manifolds. Then `mfderiv I I' f x` is the derivative of
`f` at `x`, as a continuous linear map from the tangent space at `x` to the tangent space at `f x`. -/
def mfderiv (f : M → M') (x : M) : tangent_space I x →L[𝕜] tangent_space I' (f x) :=
if h : mdifferentiable_at I I' f x then
(fderiv_within 𝕜 (written_in_ext_chart_at I I' x f : E → E') (range I.to_fun)
  ((ext_chart_at I x).to_fun x) : _)
else continuous_linear_map.zero

set_option class.instance_max_depth 60

/-- The derivative within a set, as a map between the tangent bundles -/
def bundle_mfderiv_within (f : M → M') (s : set M) : tangent_bundle I M → tangent_bundle I' M' :=
λp, ⟨f p.1, (mfderiv_within I I' f s p.1 : tangent_space I p.1 → tangent_space I' (f p.1)) p.2⟩

/-- The derivative, as a map between the tangent bundles -/
def bundle_mfderiv (f : M → M') : tangent_bundle I M → tangent_bundle I' M' :=
λp, ⟨f p.1, (mfderiv I I' f p.1 : tangent_space I p.1 → tangent_space I' (f p.1)) p.2⟩

end derivatives_definitions

section derivatives_properties
/-! ### Unique differentiability sets in manifolds -/

variables {𝕜 : Type*} [nondiscrete_normed_field 𝕜]
{E : Type*} [normed_group E] [normed_space 𝕜 E]
{H : Type*} [topological_space H] (I : model_with_corners 𝕜 E H)
{M : Type*} [topological_space M] [manifold H M] --
{E' : Type*} [normed_group E'] [normed_space 𝕜 E']
{H' : Type*} [topological_space H'] {I' : model_with_corners 𝕜 E' H'}
{M' : Type*} [topological_space M'] [manifold H' M']
{E'' : Type*} [normed_group E''] [normed_space 𝕜 E'']
{H'' : Type*} [topological_space H''] {I'' : model_with_corners 𝕜 E'' H''}
{M'' : Type*} [topological_space M''] [manifold H'' M'']
{f f₀ f₁ : M → M'}
{x : M}
{s t : set M}
{g : M' → M''}
{u : set M'}

lemma unique_mdiff_within_at_univ : unique_mdiff_within_at I univ x :=
begin
  unfold unique_mdiff_within_at,
  simp only [preimage_univ, univ_inter],
  exact I.unique_diff _ (mem_range_self _)
end
variable {I}

lemma unique_mdiff_within_at_iff {s : set M} {x : M} :
  unique_mdiff_within_at I s x ↔
  unique_diff_within_at 𝕜 ((ext_chart_at I x).inv_fun ⁻¹' s ∩ (ext_chart_at I x).target)
  ((ext_chart_at I x).to_fun x) :=
begin
  apply unique_diff_within_at_congr,
  rw [nhds_within_inter, nhds_within_inter, nhds_within_ext_chart_target_eq]
end

lemma unique_mdiff_within_at.mono (h : unique_mdiff_within_at I s x) (st : s ⊆ t) :
  unique_mdiff_within_at I t x :=
unique_diff_within_at.mono h $ inter_subset_inter (preimage_mono st) (subset.refl _)

lemma unique_mdiff_within_at.inter' (hs : unique_mdiff_within_at I s x) (ht : t ∈ nhds_within x s) :
  unique_mdiff_within_at I (s ∩ t) x :=
begin
  rw [unique_mdiff_within_at, ext_chart_preimage_inter_eq],
  exact unique_diff_within_at.inter' hs (ext_chart_preimage_mem_nhds_within I x ht)
end

lemma unique_mdiff_within_at.inter (hs : unique_mdiff_within_at I s x) (ht : t ∈ 𝓝 x) :
  unique_mdiff_within_at I (s ∩ t) x :=
begin
  rw [unique_mdiff_within_at, ext_chart_preimage_inter_eq],
  exact unique_diff_within_at.inter hs (ext_chart_preimage_mem_nhds I x ht)
end

lemma is_open.unique_mdiff_within_at (xs : x ∈ s) (hs : is_open s) : unique_mdiff_within_at I s x :=
begin
  have := unique_mdiff_within_at.inter (unique_mdiff_within_at_univ I) (mem_nhds_sets hs xs),
  rwa univ_inter at this
end

lemma unique_mdiff_on.inter (hs : unique_mdiff_on I s) (ht : is_open t) : unique_mdiff_on I (s ∩ t) :=
λx hx, unique_mdiff_within_at.inter (hs _ hx.1) (mem_nhds_sets ht hx.2)

lemma is_open.unique_mdiff_on (hs : is_open s) : unique_mdiff_on I s :=
λx hx, is_open.unique_mdiff_within_at hx hs

/- We name the typeclass variables related to `smooth_manifold_with_corners` structure as they are
necessary in lemmas mentioning the derivative, but not in lemmas about differentiability, so we
want to include them or omit them when necessary. -/
variables [Is : smooth_manifold_with_corners I M] [I's : smooth_manifold_with_corners I' M']
[I''s : smooth_manifold_with_corners I'' M'']
{f' f₀' f₁' : tangent_space I x →L[𝕜] tangent_space I' (f x)}
{g' : tangent_space I' (f x) →L[𝕜] tangent_space I'' (g (f x))}

/-- `unique_mdiff_within_at` achieves its goal: it implies the uniqueness of the derivative. -/
theorem unique_mdiff_within_at.eq (U : unique_mdiff_within_at I s x)
  (h : has_mfderiv_within_at I I' f s x f') (h₁ : has_mfderiv_within_at I I' f s x f₁') : f' = f₁' :=
U.eq h.2 h₁.2

theorem unique_mdiff_on.eq (U : unique_mdiff_on I s) (hx : x ∈ s)
  (h : has_mfderiv_within_at I I' f s x f') (h₁ : has_mfderiv_within_at I I' f s x f₁') : f' = f₁' :=
unique_mdiff_within_at.eq (U _ hx) h h₁


/-!
### General lemmas on derivatives of functions between manifolds

We mimick the API for functions between vector spaces
-/

lemma mdifferentiable_within_at_iff {f : M → M'} {s : set M} {x : M} :
  mdifferentiable_within_at I I' f s x ↔
  continuous_within_at f s x ∧
  differentiable_within_at 𝕜 (written_in_ext_chart_at I I' x f)
    ((ext_chart_at I x).target ∩ (ext_chart_at I x).inv_fun ⁻¹' s) ((ext_chart_at I x).to_fun x) :=
begin
  refine and_congr iff.rfl (exists_congr $ λ f', _),
  rw [inter_comm],
  simp only [has_fderiv_within_at, nhds_within_inter, nhds_within_ext_chart_target_eq]
end

include Is I's
set_option class.instance_max_depth 60

lemma mfderiv_within_zero_of_not_mdifferentiable_within_at
  (h : ¬ mdifferentiable_within_at I I' f s x) : mfderiv_within I I' f s x = 0 :=
by { simp [mfderiv_within, h], refl }

lemma mfderiv_zero_of_not_mdifferentiable_at
  (h : ¬ mdifferentiable_at I I' f x) : mfderiv I I' f x = 0 :=
by { simp [mfderiv, h], refl }

theorem has_mfderiv_within_at.mono (h : has_mfderiv_within_at I I' f t x f') (hst : s ⊆ t) :
  has_mfderiv_within_at I I' f s x f' :=
⟨ continuous_within_at.mono h.1 hst,
  has_fderiv_within_at.mono h.2 (inter_subset_inter (preimage_mono hst) (subset.refl _)) ⟩

theorem has_mfderiv_at.has_mfderiv_within_at
  (h : has_mfderiv_at I I' f x f') : has_mfderiv_within_at I I' f s x f' :=
⟨ continuous_at.continuous_within_at h.1, has_fderiv_within_at.mono h.2 (inter_subset_right _ _) ⟩

lemma has_mfderiv_within_at.mdifferentiable_within_at (h : has_mfderiv_within_at I I' f s x f') :
  mdifferentiable_within_at I I' f s x :=
⟨h.1, ⟨f', h.2⟩⟩

lemma has_mfderiv_at.mdifferentiable_at (h : has_mfderiv_at I I' f x f') :
  mdifferentiable_at I I' f x :=
⟨h.1, ⟨f', h.2⟩⟩

@[simp] lemma has_mfderiv_within_at_univ :
  has_mfderiv_within_at I I' f univ x f' ↔ has_mfderiv_at I I' f x f' :=
by simp [has_mfderiv_within_at, has_mfderiv_at, continuous_within_at_univ]

theorem has_mfderiv_at_unique
  (h₀ : has_mfderiv_at I I' f x f₀') (h₁ : has_mfderiv_at I I' f x f₁') : f₀' = f₁' :=
begin
  rw ← has_mfderiv_within_at_univ at h₀ h₁,
  exact (unique_mdiff_within_at_univ I).eq h₀ h₁
end

lemma has_mfderiv_within_at_inter' (h : t ∈ nhds_within x s) :
  has_mfderiv_within_at I I' f (s ∩ t) x f' ↔ has_mfderiv_within_at I I' f s x f' :=
begin
  rw [has_mfderiv_within_at, has_mfderiv_within_at, ext_chart_preimage_inter_eq,
      has_fderiv_within_at_inter', continuous_within_at_inter' h],
  exact ext_chart_preimage_mem_nhds_within I x h,
end

lemma has_mfderiv_within_at_inter (h : t ∈ 𝓝 x) :
  has_mfderiv_within_at I I' f (s ∩ t) x f' ↔ has_mfderiv_within_at I I' f s x f' :=
begin
  rw [has_mfderiv_within_at, has_mfderiv_within_at, ext_chart_preimage_inter_eq,
      has_fderiv_within_at_inter, continuous_within_at_inter h],
  exact ext_chart_preimage_mem_nhds I x h,
end

lemma has_mfderiv_within_at.union
  (hs : has_mfderiv_within_at I I' f s x f') (ht : has_mfderiv_within_at I I' f t x f') :
  has_mfderiv_within_at I I' f (s ∪ t) x f' :=
begin
  split,
  { exact continuous_within_at.union hs.1 ht.1 },
  { convert has_fderiv_within_at.union hs.2 ht.2,
    simp [union_inter_distrib_right] }
end

lemma has_mfderiv_within_at.nhds_within (h : has_mfderiv_within_at I I' f s x f')
  (ht : s ∈ nhds_within x t) : has_mfderiv_within_at I I' f t x f' :=
(has_mfderiv_within_at_inter' ht).1 (h.mono (inter_subset_right _ _))

lemma has_mfderiv_within_at.has_mfderiv_at (h : has_mfderiv_within_at I I' f s x f') (hs : s ∈ 𝓝 x) :
  has_mfderiv_at I I' f x f' :=
by rwa [← univ_inter s, has_mfderiv_within_at_inter hs, has_mfderiv_within_at_univ] at h

lemma mdifferentiable_within_at.has_mfderiv_within_at (h : mdifferentiable_within_at I I' f s x) :
  has_mfderiv_within_at I I' f s x (mfderiv_within I I' f s x) :=
begin
  refine ⟨h.1, _⟩,
  simp [mfderiv_within, h],
  exact differentiable_within_at.has_fderiv_within_at h.2
end

lemma mdifferentiable_within_at.mfderiv_within (h : mdifferentiable_within_at I I' f s x) :
  (mfderiv_within I I' f s x) =
  fderiv_within 𝕜 (written_in_ext_chart_at I I' x f : _) ((ext_chart_at I x).inv_fun ⁻¹' s ∩ range I.to_fun)
  ((ext_chart_at I x).to_fun x) :=
by simp [mfderiv_within, h]

lemma mdifferentiable_at.has_mfderiv_at (h : mdifferentiable_at I I' f x) :
  has_mfderiv_at I I' f x (mfderiv I I' f x) :=
begin
  refine ⟨h.1, _⟩,
  simp [mfderiv, h],
  exact differentiable_within_at.has_fderiv_within_at h.2
end

lemma mdifferentiable_at.mfderiv (h : mdifferentiable_at I I' f x) :
  (mfderiv I I' f x) =
  fderiv_within 𝕜 (written_in_ext_chart_at I I' x f : _) (range I.to_fun) ((ext_chart_at I x).to_fun x) :=
by simp [mfderiv, h]

lemma has_mfderiv_at.mfderiv (h : has_mfderiv_at I I' f x f') :
  mfderiv I I' f x = f' :=
by { ext, rw has_mfderiv_at_unique h h.mdifferentiable_at.has_mfderiv_at }

lemma has_mfderiv_within_at.mfderiv_within
  (h : has_mfderiv_within_at I I' f s x f') (hxs : unique_mdiff_within_at I s x) :
  mfderiv_within I I' f s x = f' :=
by { ext, rw hxs.eq h h.mdifferentiable_within_at.has_mfderiv_within_at }

lemma mdifferentiable.mfderiv_within
  (h : mdifferentiable_at I I' f x) (hxs : unique_mdiff_within_at I s x) :
  mfderiv_within I I' f s x = mfderiv I I' f x :=
begin
  apply has_mfderiv_within_at.mfderiv_within _ hxs,
  exact h.has_mfderiv_at.has_mfderiv_within_at
end

lemma mfderiv_within_subset (st : s ⊆ t) (hs : unique_mdiff_within_at I s x)
  (h : mdifferentiable_within_at I I' f t x) :
  mfderiv_within I I' f s x = mfderiv_within I I' f t x :=
((mdifferentiable_within_at.has_mfderiv_within_at h).mono st).mfderiv_within hs

omit Is I's

lemma mdifferentiable_within_at.mono (hst : s ⊆ t)
  (h : mdifferentiable_within_at I I' f t x) : mdifferentiable_within_at I I' f s x :=
⟨ continuous_within_at.mono h.1 hst,
  differentiable_within_at.mono h.2 (inter_subset_inter (preimage_mono hst) (subset.refl _)) ⟩

lemma mdifferentiable_within_at_univ :
  mdifferentiable_within_at I I' f univ x ↔ mdifferentiable_at I I' f x :=
by simp [mdifferentiable_within_at, mdifferentiable_at, continuous_within_at_univ]

lemma mdifferentiable_within_at_inter (ht : t ∈ 𝓝 x) :
  mdifferentiable_within_at I I' f (s ∩ t) x ↔ mdifferentiable_within_at I I' f s x :=
begin
  rw [mdifferentiable_within_at, mdifferentiable_within_at, ext_chart_preimage_inter_eq,
      differentiable_within_at_inter, continuous_within_at_inter ht],
  exact ext_chart_preimage_mem_nhds I x ht
end

lemma mdifferentiable_within_at_inter' (ht : t ∈ nhds_within x s) :
  mdifferentiable_within_at I I' f (s ∩ t) x ↔ mdifferentiable_within_at I I' f s x :=
begin
  rw [mdifferentiable_within_at, mdifferentiable_within_at, ext_chart_preimage_inter_eq,
      differentiable_within_at_inter', continuous_within_at_inter' ht],
  exact ext_chart_preimage_mem_nhds_within I x ht
end

lemma mdifferentiable_at.mdifferentiable_within_at
  (h : mdifferentiable_at I I' f x) : mdifferentiable_within_at I I' f s x :=
mdifferentiable_within_at.mono (subset_univ _) (mdifferentiable_within_at_univ.2 h)

lemma mdifferentiable_within_at.mdifferentiable_at
  (h : mdifferentiable_within_at I I' f s x) (hs : s ∈ 𝓝 x) : mdifferentiable_at I I' f x :=
begin
  have : s = univ ∩ s, by rw univ_inter,
  rwa [this, mdifferentiable_within_at_inter hs, mdifferentiable_within_at_univ] at h,
end

lemma mdifferentiable_on.mono
  (h : mdifferentiable_on I I' f t) (st : s ⊆ t) : mdifferentiable_on I I' f s :=
λx hx, (h x (st hx)).mono st

lemma mdifferentiable_on_univ :
  mdifferentiable_on I I' f univ ↔ mdifferentiable I I' f :=
by { simp [mdifferentiable_on, mdifferentiable_within_at_univ], refl }

lemma mdifferentiable.mdifferentiable_on
  (h : mdifferentiable I I' f) : mdifferentiable_on I I' f s :=
(mdifferentiable_on_univ.2 h).mono (subset_univ _)

lemma mdifferentiable_on_of_locally_mdifferentiable_on
  (h : ∀x∈s, ∃u, is_open u ∧ x ∈ u ∧ mdifferentiable_on I I' f (s ∩ u)) : mdifferentiable_on I I' f s :=
begin
  assume x xs,
  rcases h x xs with ⟨t, t_open, xt, ht⟩,
  exact (mdifferentiable_within_at_inter (mem_nhds_sets t_open xt)).1 (ht x ⟨xs, xt⟩)
end

include Is I's
@[simp] lemma mfderiv_within_univ : mfderiv_within I I' f univ = mfderiv I I' f :=
begin
  ext x : 1,
  simp [mfderiv_within, mfderiv],
  erw mdifferentiable_within_at_univ
end

lemma mfderiv_within_inter (ht : t ∈ 𝓝 x) (hs : unique_mdiff_within_at I s x) :
  mfderiv_within I I' f (s ∩ t) x = mfderiv_within I I' f s x :=
by erw [mfderiv_within, mfderiv_within, ext_chart_preimage_inter_eq,
  mdifferentiable_within_at_inter ht, fderiv_within_inter (ext_chart_preimage_mem_nhds I x ht) hs]

omit Is I's

/-! ### Deriving continuity from differentiability on manifolds -/

theorem has_mfderiv_within_at.continuous_within_at
  (h : mdifferentiable_within_at I I' f s x) : continuous_within_at f s x :=
h.1

theorem has_mfderiv_at.continuous_at (h : has_mfderiv_at I I' f x f') :
  continuous_at f x :=
h.1

lemma mdifferentiable_within_at.continuous_within_at (h : mdifferentiable_within_at I I' f s x) :
  continuous_within_at f s x :=
h.1

lemma mdifferentiable_at.continuous_at (h : mdifferentiable_at I I' f x) : continuous_at f x :=
h.1

lemma mdifferentiable_on.continuous_on (h : mdifferentiable_on I I' f s) : continuous_on f s :=
λx hx, (h x hx).continuous_within_at

lemma mdifferentiable.continuous (h : mdifferentiable I I' f) : continuous f :=
continuous_iff_continuous_at.2 $ λx, (h x).continuous_at

include Is I's
lemma bundle_mfderiv_within_subset {p : tangent_bundle I M}
  (st : s ⊆ t) (hs : unique_mdiff_within_at I s p.1) (h : mdifferentiable_within_at I I' f t p.1) :
  bundle_mfderiv_within I I' f s p = bundle_mfderiv_within I I' f t p :=
by { simp [bundle_mfderiv_within], rw mfderiv_within_subset st hs h }

lemma bundle_mfderiv_within_univ :
  bundle_mfderiv_within I I' f univ = bundle_mfderiv I I' f :=
by { ext p : 1, simp [bundle_mfderiv_within, bundle_mfderiv], rw mfderiv_within_univ }

lemma bundle_mfderiv_within_eq_bundle_mfderiv {p : tangent_bundle I M}
  (hs : unique_mdiff_within_at I s p.1) (h : mdifferentiable_at I I' f p.1) :
  bundle_mfderiv_within I I' f s p = bundle_mfderiv I I' f p :=
begin
  rw ← mdifferentiable_within_at_univ at h,
  rw ← bundle_mfderiv_within_univ,
  exact bundle_mfderiv_within_subset (subset_univ _) hs h,
end

@[simp] lemma bundle_mfderiv_within_tangent_bundle_proj {p : tangent_bundle I M} :
  tangent_bundle.proj I' M' (bundle_mfderiv_within I I' f s p) = f (tangent_bundle.proj I M p) := rfl

@[simp] lemma bundle_mfderiv_within_proj {p : tangent_bundle I M} :
  (bundle_mfderiv_within I I' f s p).1 = f p.1 := rfl

@[simp] lemma bundle_mfderiv_tangent_bundle_proj {p : tangent_bundle I M} :
  tangent_bundle.proj I' M' (bundle_mfderiv I I' f p) = f (tangent_bundle.proj I M p) := rfl

@[simp] lemma bundle_mfderiv_proj {p : tangent_bundle I M} :
  (bundle_mfderiv I I' f p).1 = f p.1 := rfl

omit Is I's

/-! ### Congruence lemmas for derivatives on manifolds -/

lemma has_mfderiv_within_at.congr_of_mem_nhds_within (h : has_mfderiv_within_at I I' f s x f')
  (h₁ : ∀ᶠ y in nhds_within x s, f₁ y = f y) (hx : f₁ x = f x) : has_mfderiv_within_at I I' f₁ s x f' :=
begin
  refine ⟨continuous_within_at.congr_of_mem_nhds_within h.1 h₁ hx, _⟩,
  apply has_fderiv_within_at.congr_of_mem_nhds_within h.2,
  { have : (ext_chart_at I x).inv_fun ⁻¹' {y | f₁ y = f y} ∈
      nhds_within ((ext_chart_at I x).to_fun x) ((ext_chart_at I x).inv_fun ⁻¹' s ∩ range I.to_fun) :=
      ext_chart_preimage_mem_nhds_within I x h₁,
    apply filter.mem_sets_of_superset this (λy, _),
    simp [written_in_ext_chart_at, hx] {contextual := tt} },
  { simp [written_in_ext_chart_at, hx] },
end

lemma has_mfderiv_within_at.congr_mono (h : has_mfderiv_within_at I I' f s x f')
  (ht : ∀x ∈ t, f₁ x = f x) (hx : f₁ x = f x) (h₁ : t ⊆ s) :
  has_mfderiv_within_at I I' f₁ t x f' :=
(h.mono h₁).congr_of_mem_nhds_within (filter.mem_inf_sets_of_right ht) hx

lemma has_mfderiv_at.congr_of_mem_nhds (h : has_mfderiv_at I I' f x f')
  (h₁ : ∀ᶠ y in 𝓝 x, f₁ y = f y) : has_mfderiv_at I I' f₁ x f' :=
begin
  erw ← has_mfderiv_within_at_univ at ⊢ h,
  apply h.congr_of_mem_nhds_within _ (mem_of_nhds h₁ : _),
  rwa nhds_within_univ
end

include Is I's

lemma mdifferentiable_within_at.congr_of_mem_nhds_within
  (h : mdifferentiable_within_at I I' f s x) (h₁ : ∀ᶠ y in nhds_within x s, f₁ y = f y)
  (hx : f₁ x = f x) : mdifferentiable_within_at I I' f₁ s x :=
(h.has_mfderiv_within_at.congr_of_mem_nhds_within h₁ hx).mdifferentiable_within_at

variables (I I')
lemma mdifferentiable_within_at_congr_of_mem_nhds_within
  (h₁ : ∀ᶠ y in nhds_within x s, f₁ y = f y) (hx : f₁ x = f x) :
  mdifferentiable_within_at I I' f s x ↔ mdifferentiable_within_at I I' f₁ s x :=
begin
  split,
  { assume h,
    apply h.congr_of_mem_nhds_within h₁ hx },
  { assume h,
    apply h.congr_of_mem_nhds_within _ hx.symm,
    apply h₁.mono,
    intro y,
    apply eq.symm }
end
variables {I I'}

lemma mdifferentiable_within_at.congr_mono (h : mdifferentiable_within_at I I' f s x)
  (ht : ∀x ∈ t, f₁ x = f x) (hx : f₁ x = f x) (h₁ : t ⊆ s) : mdifferentiable_within_at I I' f₁ t x :=
(has_mfderiv_within_at.congr_mono h.has_mfderiv_within_at ht hx h₁).mdifferentiable_within_at

lemma mdifferentiable_within_at.congr (h : mdifferentiable_within_at I I' f s x)
  (ht : ∀x ∈ s, f₁ x = f x) (hx : f₁ x = f x) : mdifferentiable_within_at I I' f₁ s x :=
(has_mfderiv_within_at.congr_mono h.has_mfderiv_within_at ht hx (subset.refl _)).mdifferentiable_within_at

lemma mdifferentiable_on.congr_mono (h : mdifferentiable_on I I' f s) (h' : ∀x ∈ t, f₁ x = f x)
  (h₁ : t ⊆ s) : mdifferentiable_on I I' f₁ t :=
λ x hx, (h x (h₁ hx)).congr_mono h' (h' x hx) h₁

lemma mdifferentiable_at.congr_of_mem_nhds (h : mdifferentiable_at I I' f x)
  (hL : ∀ᶠ y in 𝓝 x, f₁ y = f y) : mdifferentiable_at I I' f₁ x :=
((h.has_mfderiv_at).congr_of_mem_nhds hL).mdifferentiable_at

lemma mdifferentiable_within_at.mfderiv_within_congr_mono (h : mdifferentiable_within_at I I' f s x)
  (hs : ∀x ∈ t, f₁ x = f x) (hx : f₁ x = f x) (hxt : unique_mdiff_within_at I t x) (h₁ : t ⊆ s) :
  mfderiv_within I I' f₁ t x = (mfderiv_within I I' f s x : _) :=
(has_mfderiv_within_at.congr_mono h.has_mfderiv_within_at hs hx h₁).mfderiv_within hxt

lemma mfderiv_within_congr_of_mem_nhds_within (hs : unique_mdiff_within_at I s x)
  (hL : ∀ᶠ y in nhds_within x s, f₁ y = f y) (hx : f₁ x = f x) :
  mfderiv_within I I' f₁ s x = (mfderiv_within I I' f s x : _) :=
begin
  by_cases h : mdifferentiable_within_at I I' f s x,
  { exact ((h.has_mfderiv_within_at).congr_of_mem_nhds_within hL hx).mfderiv_within hs },
  { unfold mfderiv_within,
    rw [dif_neg, dif_neg],
    assumption,
    rwa ← mdifferentiable_within_at_congr_of_mem_nhds_within I I' hL hx }
end

lemma mfderiv_congr_of_mem_nhds (hL : ∀ᶠ y in 𝓝 x, f₁ y = f y) :
  mfderiv I I' f₁ x = (mfderiv I I' f x : _) :=
begin
  have A : f₁ x = f x := (mem_of_nhds hL : _),
  rw [← mfderiv_within_univ, ← mfderiv_within_univ],
  rw ← nhds_within_univ at hL,
  exact mfderiv_within_congr_of_mem_nhds_within (unique_mdiff_within_at_univ I) hL A
end

/-! ### Composition lemmas -/

omit Is I's

lemma written_in_ext_chart_comp (h : continuous_within_at f s x) :
  {y | written_in_ext_chart_at I I'' x (g ∘ f) y
       = ((written_in_ext_chart_at I' I'' (f x) g) ∘ (written_in_ext_chart_at I I' x f)) y}
  ∈ nhds_within ((ext_chart_at I x).to_fun x) ((ext_chart_at I x).inv_fun ⁻¹' s ∩ range I.to_fun) :=
begin
  apply @filter.mem_sets_of_superset _ _
    ((f ∘ (ext_chart_at I x).inv_fun)⁻¹' (ext_chart_at I' (f x)).source) _
    (ext_chart_preimage_mem_nhds_within I x (h.preimage_mem_nhds_within (ext_chart_at_source_mem_nhds _ _))),
  assume y hy,
  simp only [ext_chart_at, written_in_ext_chart_at, model_with_corners_left_inv,
             mem_set_of_eq, function.comp_app, local_equiv.trans_to_fun, local_equiv.trans_inv_fun],
  rw (chart_at H' (f x)).left_inv,
  simpa [ext_chart_at_source] using hy
end

variable (x)
include Is I's I''s

theorem has_mfderiv_within_at.comp
  (hg : has_mfderiv_within_at I' I'' g u (f x) g') (hf : has_mfderiv_within_at I I' f s x f')
  (hst : s ⊆ f ⁻¹' u) :
  has_mfderiv_within_at I I'' (g ∘ f) s x (g'.comp f') :=
begin
  refine ⟨continuous_within_at.comp hg.1 hf.1 hst, _⟩,
  have A : has_fderiv_within_at ((written_in_ext_chart_at I' I'' (f x) g) ∘
       (written_in_ext_chart_at I I' x f))
    (continuous_linear_map.comp g' f' : E →L[𝕜] E'')
    ((ext_chart_at I x).inv_fun ⁻¹' s ∩ range (I.to_fun))
    ((ext_chart_at I x).to_fun x),
  { have : (ext_chart_at I x).inv_fun ⁻¹' (f ⁻¹' (ext_chart_at I' (f x)).source)
    ∈ nhds_within ((ext_chart_at I x).to_fun x) ((ext_chart_at I x).inv_fun ⁻¹' s ∩ range I.to_fun) :=
      (ext_chart_preimage_mem_nhds_within I x
        (hf.1.preimage_mem_nhds_within (ext_chart_at_source_mem_nhds _ _))),
    unfold has_mfderiv_within_at at *,
    rw [← has_fderiv_within_at_inter' this, ← ext_chart_preimage_inter_eq] at hf ⊢,
    have : written_in_ext_chart_at I I' x f ((ext_chart_at I x).to_fun x)
        = (ext_chart_at I' (f x)).to_fun (f x),
      by simp [written_in_ext_chart_at, local_equiv.left_inv, mem_chart_source],
    rw ← this at hg,
    apply has_fderiv_within_at.comp ((ext_chart_at I x).to_fun x) hg.2 hf.2 _,
    assume y hy,
    simp [ext_chart_at, local_equiv.trans_source, -mem_range] at hy,
    have : f ((chart_at H x).inv_fun (I.inv_fun y)) ∈ u := hst hy.1.1,
    simp [written_in_ext_chart_at, ext_chart_at, -mem_range, hy, this, mem_range_self] },
  apply A.congr_of_mem_nhds_within (written_in_ext_chart_comp hf.1),
  simp [written_in_ext_chart_at, ext_chart_at, local_equiv.left_inv, mem_chart_source]
end

/-- The chain rule. -/
theorem has_mfderiv_at.comp
  (hg : has_mfderiv_at I' I'' g (f x) g') (hf : has_mfderiv_at I I' f x f') :
  has_mfderiv_at I I'' (g ∘ f) x (g'.comp f') :=
begin
  rw ← has_mfderiv_within_at_univ at *,
  exact has_mfderiv_within_at.comp x (hg.mono (subset_univ _)) hf subset_preimage_univ
end

theorem has_mfderiv_at.comp_has_mfderiv_within_at
  (hg : has_mfderiv_at I' I'' g (f x) g') (hf : has_mfderiv_within_at I I' f s x f') :
  has_mfderiv_within_at I I'' (g ∘ f) s x (g'.comp f') :=
begin
  rw ← has_mfderiv_within_at_univ at *,
  exact has_mfderiv_within_at.comp x (hg.mono (subset_univ _)) hf subset_preimage_univ
end

lemma mdifferentiable_within_at.comp
  (hg : mdifferentiable_within_at I' I'' g u (f x)) (hf : mdifferentiable_within_at I I' f s x)
  (h : s ⊆ f ⁻¹' u) : mdifferentiable_within_at I I'' (g ∘ f) s x :=
begin
  rcases hf.2 with ⟨f', hf'⟩,
  have F : has_mfderiv_within_at I I' f s x f' := ⟨hf.1, hf'⟩,
  rcases hg.2 with ⟨g', hg'⟩,
  have G : has_mfderiv_within_at I' I'' g u (f x) g' := ⟨hg.1, hg'⟩,
  exact (has_mfderiv_within_at.comp x G F h).mdifferentiable_within_at
end

lemma mdifferentiable_at.comp
  (hg : mdifferentiable_at I' I'' g (f x)) (hf : mdifferentiable_at I I' f x) :
  mdifferentiable_at I I'' (g ∘ f) x :=
(hg.has_mfderiv_at.comp x hf.has_mfderiv_at).mdifferentiable_at

lemma mfderiv_within_comp
  (hg : mdifferentiable_within_at I' I'' g u (f x)) (hf : mdifferentiable_within_at I I' f s x)
  (h : s ⊆ f ⁻¹' u) (hxs : unique_mdiff_within_at I s x) :
  mfderiv_within I I'' (g ∘ f) s x = (mfderiv_within I' I'' g u (f x)).comp (mfderiv_within I I' f s x) :=
begin
  apply has_mfderiv_within_at.mfderiv_within _ hxs,
  exact has_mfderiv_within_at.comp x hg.has_mfderiv_within_at hf.has_mfderiv_within_at h
end

lemma mfderiv_comp
  (hg : mdifferentiable_at I' I'' g (f x)) (hf : mdifferentiable_at I I' f x) :
  mfderiv I I'' (g ∘ f) x = (mfderiv I' I'' g (f x)).comp (mfderiv I I' f x) :=
begin
  apply has_mfderiv_at.mfderiv,
  exact has_mfderiv_at.comp x hg.has_mfderiv_at hf.has_mfderiv_at
end

lemma mdifferentiable_on.comp
  (hg : mdifferentiable_on I' I'' g u) (hf : mdifferentiable_on I I' f s) (st : s ⊆ f ⁻¹' u) :
  mdifferentiable_on I I'' (g ∘ f) s :=
λx hx, mdifferentiable_within_at.comp x (hg (f x) (st hx)) (hf x hx) st

lemma mdifferentiable.comp
  (hg : mdifferentiable I' I'' g) (hf : mdifferentiable I I' f) : mdifferentiable I I'' (g ∘ f) :=
λx, mdifferentiable_at.comp x (hg (f x)) (hf x)

lemma bundle_mfderiv_within_comp_at (p : tangent_bundle I M)
  (hg : mdifferentiable_within_at I' I'' g u (f p.1)) (hf : mdifferentiable_within_at I I' f s p.1)
  (h : s ⊆ f ⁻¹' u)  (hps : unique_mdiff_within_at I s p.1) :
  bundle_mfderiv_within I I'' (g ∘ f) s p =
  bundle_mfderiv_within I' I'' g u (bundle_mfderiv_within I I' f s p) :=
begin
  simp [bundle_mfderiv_within],
  rw mfderiv_within_comp p.1 hg hf h hps,
  refl
end

lemma bundle_mfderiv_comp_at (p : tangent_bundle I M)
  (hg : mdifferentiable_at I' I'' g (f p.1)) (hf : mdifferentiable_at I I' f p.1) :
  bundle_mfderiv I I'' (g ∘ f) p = bundle_mfderiv I' I'' g (bundle_mfderiv I I' f p) :=
begin
  rcases p with ⟨x, v⟩,
  simp [bundle_mfderiv],
  rw mfderiv_comp x hg hf,
  refl
end

lemma bundle_mfderiv_comp (hg : mdifferentiable I' I'' g) (hf : mdifferentiable I I' f) :
  bundle_mfderiv I I'' (g ∘ f) = (bundle_mfderiv I' I'' g) ∘ (bundle_mfderiv I I' f) :=
by { ext p : 1, exact bundle_mfderiv_comp_at _ (hg _) (hf _) }

end derivatives_properties

section specific_functions

/-! ### Differentiability of specific functions -/

variables {𝕜 : Type*} [nondiscrete_normed_field 𝕜]
{E : Type*} [normed_group E] [normed_space 𝕜 E]
{H : Type*} [topological_space H] (I : model_with_corners 𝕜 E H)
{M : Type*} [topological_space M] [manifold H M] [smooth_manifold_with_corners I M]
{s : set M} {x : M}

section id
/-! #### Identity -/

lemma has_mfderiv_at_id (x : M) :
  has_mfderiv_at I I (@_root_.id M) x
  (continuous_linear_map.id : tangent_space I x →L[𝕜] tangent_space I x) :=
begin
  refine ⟨continuous_id.continuous_at, _⟩,
  have : ∀ᶠ y in nhds_within ((ext_chart_at I x).to_fun x) (range (I.to_fun)),
    ((ext_chart_at I x).to_fun ∘ (ext_chart_at I x).inv_fun) y = id y,
  { apply filter.mem_sets_of_superset (ext_chart_at_target_mem_nhds_within I x),
    assume y hy,
    simp [(ext_chart_at I x).right_inv hy] },
  apply has_fderiv_within_at.congr_of_mem_nhds_within (has_fderiv_within_at_id _ _) this,
  simp [(ext_chart_at I x).left_inv, mem_ext_chart_source I x]
end

theorem has_mfderiv_within_at_id (s : set M) (x : M) :
  has_mfderiv_within_at I I (@_root_.id M) s x
  (continuous_linear_map.id : tangent_space I x →L[𝕜] tangent_space I x) :=
(has_mfderiv_at_id I x).has_mfderiv_within_at

lemma mdifferentiable_at_id : mdifferentiable_at I I (@_root_.id M) x :=
(has_mfderiv_at_id I x).mdifferentiable_at

lemma mdifferentiable_within_at_id : mdifferentiable_within_at I I (@_root_.id M) s x :=
(mdifferentiable_at_id I).mdifferentiable_within_at

lemma mdifferentiable_id : mdifferentiable I I (@_root_.id M) :=
λx, mdifferentiable_at_id I

lemma mdifferentiable_on_id : mdifferentiable_on I I (@_root_.id M) s :=
(mdifferentiable_id I).mdifferentiable_on

@[simp] lemma mfderiv_id : mfderiv I I (@_root_.id M) x =
  (continuous_linear_map.id : tangent_space I x →L[𝕜] tangent_space I x) :=
has_mfderiv_at.mfderiv (has_mfderiv_at_id I x)

lemma mfderiv_within_id (hxs : unique_mdiff_within_at I s x) :
  mfderiv_within I I (@_root_.id M) s x =
  (continuous_linear_map.id : tangent_space I x →L[𝕜] tangent_space I x) :=
begin
  rw mdifferentiable.mfderiv_within (mdifferentiable_at_id I) hxs,
  exact mfderiv_id I
end

end id

section const
/-! #### Constants -/

variables {E' : Type*} [normed_group E'] [normed_space 𝕜 E']
{H' : Type*} [topological_space H'] (I' : model_with_corners 𝕜 E' H')
{M' : Type*} [topological_space M'] [manifold H' M'] [smooth_manifold_with_corners I' M']
{c : M'}

lemma has_mfderiv_at_const (c : M') (x : M) :
  has_mfderiv_at I I' (λy : M, c) x
  (continuous_linear_map.zero : tangent_space I x →L[𝕜] tangent_space I' c) :=
begin
  refine ⟨continuous_const.continuous_at, _⟩,
  have : (ext_chart_at I' c).to_fun ∘ (λ (y : M), c) ∘ (ext_chart_at I x).inv_fun =
    (λy, (ext_chart_at I' c).to_fun c) := rfl,
  rw [written_in_ext_chart_at, this],
  apply has_fderiv_within_at_const
end

theorem has_mfderiv_within_at_const (c : M') (s : set M) (x : M) :
  has_mfderiv_within_at I I' (λy : M, c) s x
  (continuous_linear_map.zero : tangent_space I x →L[𝕜] tangent_space I' c) :=
(has_mfderiv_at_const I I' c x).has_mfderiv_within_at

lemma mdifferentiable_at_const : mdifferentiable_at I I' (λy : M, c) x :=
(has_mfderiv_at_const I I' c x).mdifferentiable_at

lemma mdifferentiable_within_at_const : mdifferentiable_within_at I I' (λy : M, c) s x :=
(mdifferentiable_at_const I I').mdifferentiable_within_at

lemma mdifferentiable_const : mdifferentiable I I' (λy : M, c) :=
λx, mdifferentiable_at_const I I'

lemma mdifferentiable_on_const : mdifferentiable_on I I' (λy : M, c) s :=
(mdifferentiable_const I I').mdifferentiable_on

@[simp] lemma mfderiv_const : mfderiv I I' (λy : M, c) x =
  (continuous_linear_map.zero : tangent_space I x →L[𝕜] tangent_space I' c) :=
has_mfderiv_at.mfderiv (has_mfderiv_at_const I I' c x)

lemma mfderiv_within_const (hxs : unique_mdiff_within_at I s x) :
  mfderiv_within I I' (λy : M, c) s x =
  (continuous_linear_map.zero : tangent_space I x →L[𝕜] tangent_space I' c) :=
begin
  rw mdifferentiable.mfderiv_within (mdifferentiable_at_const I I') hxs,
  { exact mfderiv_const I I' },
  { apply_instance }
end

end const

section model_with_corners
/-! #### Model with corners -/

lemma model_with_corners_mdifferentiable_on_to_fun :
  mdifferentiable I (model_with_corners_self 𝕜 E) I.to_fun :=
begin
  simp only [mdifferentiable, mdifferentiable_at, written_in_ext_chart_at, ext_chart_at,
             local_equiv.refl_trans, local_equiv.refl_to_fun, model_with_corners_self_local_equiv,
             chart_at_model_space_eq, local_homeomorph.refl_local_equiv, function.comp.left_id],
  assume x,
  refine ⟨I.continuous_to_fun.continuous_at, _⟩,
  have : differentiable_within_at 𝕜 id (range I.to_fun) (I.to_fun x) :=
    differentiable_at_id.differentiable_within_at,
  apply this.congr,
  { simp [model_with_corners_right_inv] {contextual := tt} },
  { simp [model_with_corners_left_inv] }
end

lemma model_with_corners_mdifferentiable_on_inv_fun :
  mdifferentiable_on (model_with_corners_self 𝕜 E) I I.inv_fun (range I.to_fun) :=
begin
  simp only [mdifferentiable_on, -mem_range, mdifferentiable_within_at, written_in_ext_chart_at,
             ext_chart_at, local_equiv.refl_trans, local_equiv.refl_to_fun, preimage_id, id.def,
             inter_univ, model_with_corners_self_local_equiv, local_equiv.refl_inv_fun, range_id,
             function.comp.right_id, chart_at_model_space_eq, local_homeomorph.refl_local_equiv],
  assume x hx,
  refine ⟨I.continuous_inv_fun.continuous_at.continuous_within_at, _⟩,
  have : differentiable_within_at 𝕜 id (range I.to_fun) x :=
    differentiable_at_id.differentiable_within_at,
  apply this.congr,
  { simp [model_with_corners_right_inv] {contextual := tt} },
  { simp [model_with_corners_right_inv, hx] }
end

end model_with_corners

section charts

variable {e : local_homeomorph M H}

lemma mdifferentiable_at_atlas_to_fun (h : e ∈ atlas H M) {x : M} (hx : x ∈ e.source) :
  mdifferentiable_at I I e.to_fun x :=
begin
  refine ⟨(e.continuous_to_fun x hx).continuous_at (mem_nhds_sets e.open_source hx), _⟩,
  have zero_one : ((0 : ℕ) : with_top ℕ) < ⊤, by simp,
  have mem : I.to_fun ((chart_at H x).to_fun x) ∈
    I.inv_fun ⁻¹' ((chart_at H x).symm ≫ₕ e).source ∩ range I.to_fun,
  { simp only [mem_preimage, mem_inter_eq, model_with_corners_left_inv, mem_range_self,
      local_homeomorph.trans_source, local_homeomorph.symm_source, local_homeomorph.symm_to_fun,
      and_true],
    split,
    { exact local_equiv.map_source _ (mem_chart_source _ _) },
    { rw local_equiv.left_inv _ (mem_chart_source _ _), exact hx } },
  have : (chart_at H x).symm.trans e ∈ times_cont_diff_groupoid ⊤ I :=
    has_groupoid.compatible _ (chart_mem_atlas H x) h,
  have A : times_cont_diff_on 𝕜 ⊤
    (I.to_fun ∘ ((chart_at H x).symm.trans e).to_fun ∘ I.inv_fun)
    (I.inv_fun ⁻¹' ((chart_at H x).symm.trans e).source ∩ range I.to_fun) :=
    this.1,
  have B := A.2 _ zero_one (I.to_fun ((chart_at H x).to_fun x)) mem,
  simp only [local_homeomorph.trans_to_fun, iterated_fderiv_within_zero, local_homeomorph.symm_to_fun] at B,
  rw [inter_comm, differentiable_within_at_inter
    (mem_nhds_sets (I.continuous_inv_fun _ (local_homeomorph.open_source _)) mem.1)] at B,
  simpa [written_in_ext_chart_at, ext_chart_at]
end

lemma mdifferentiable_on_atlas_to_fun (h : e ∈ atlas H M) :
  mdifferentiable_on I I e.to_fun e.source :=
λx hx, (mdifferentiable_at_atlas_to_fun I h hx).mdifferentiable_within_at

lemma mdifferentiable_at_atlas_inv_fun (h : e ∈ atlas H M) {x : H} (hx : x ∈ e.target) :
  mdifferentiable_at I I e.inv_fun x :=
begin
  refine ⟨(e.continuous_inv_fun x hx).continuous_at (mem_nhds_sets e.open_target hx), _⟩,
  have zero_one : ((0 : ℕ) : with_top ℕ) < ⊤, by simp,
  have mem : I.to_fun x ∈ I.inv_fun ⁻¹' (e.symm ≫ₕ chart_at H (e.inv_fun x)).source ∩ range (I.to_fun),
    by simp only [local_homeomorph.trans_source, local_homeomorph.symm_source, mem_preimage,
      mem_inter_eq, model_with_corners_left_inv, preimage_inter, and_true, hx, true_and,
      local_homeomorph.symm_to_fun, mem_range_self, mem_chart_source],
  have : e.symm.trans (chart_at H (e.inv_fun x)) ∈ times_cont_diff_groupoid ⊤ I :=
    has_groupoid.compatible _ h (chart_mem_atlas H _),
  have A : times_cont_diff_on 𝕜 ⊤
    (I.to_fun ∘ (e.symm.trans (chart_at H (e.inv_fun x))).to_fun ∘ I.inv_fun)
    (I.inv_fun ⁻¹' (e.symm.trans (chart_at H (e.inv_fun x))).source ∩ range I.to_fun) :=
    this.1,
  have B := A.2 _ zero_one (I.to_fun x) mem,
  simp only [local_homeomorph.trans_to_fun, iterated_fderiv_within_zero, local_homeomorph.symm_to_fun] at B,
  rw [inter_comm, differentiable_within_at_inter
    (mem_nhds_sets (I.continuous_inv_fun _ (local_homeomorph.open_source _)) mem.1)] at B,
  simpa [written_in_ext_chart_at, ext_chart_at],
end

lemma mdifferentiable_on_atlas_inv_fun (h : e ∈ atlas H M) :
  mdifferentiable_on I I e.inv_fun e.target :=
λx hx, (mdifferentiable_at_atlas_inv_fun I h hx).mdifferentiable_within_at

lemma mdifferentiable_of_mem_atlas (h : e ∈ atlas H M) : e.mdifferentiable I I :=
⟨mdifferentiable_on_atlas_to_fun I h, mdifferentiable_on_atlas_inv_fun I h⟩

lemma mdifferentiable_chart (x : M) : (chart_at H x).mdifferentiable I I :=
mdifferentiable_of_mem_atlas _ (chart_mem_atlas _ _)

/-- The derivative of the chart at a base point is the chart of the tangent bundle. -/
lemma bundle_mfderiv_chart_to_fun {p q : tangent_bundle I M} (h : q.1 ∈ (chart_at H p.1).source) :
  bundle_mfderiv I I (chart_at H p.1).to_fun q = (chart_at (H × E) p).to_fun q :=
begin
  dsimp [bundle_mfderiv],
  rw mdifferentiable_at.mfderiv,
  { refl },
  { exact mdifferentiable_at_atlas_to_fun _ (chart_mem_atlas _ _) h }
end

/-- The derivative of the inverse of the chart at a base point is the inverse of the chart of the
tangent bundle. -/
lemma bundle_mfderiv_chart_inv_fun {p : tangent_bundle I M} {q : H × E}
  (h : q.1 ∈ (chart_at H p.1).target) :
  bundle_mfderiv I I (chart_at H p.1).inv_fun q = (chart_at (H × E) p).inv_fun q :=
begin
  dsimp only [bundle_mfderiv],
  rw mdifferentiable_at.mfderiv (mdifferentiable_at_atlas_inv_fun _ (chart_mem_atlas _ _) h),
  -- a trivial instance is needed after the rewrite, handle it right now.
  rotate, { apply_instance },
  dsimp [written_in_ext_chart_at, ext_chart_at, chart_at, manifold.chart_at,
    basic_smooth_bundle_core.chart, basic_smooth_bundle_core.to_topological_fiber_bundle_core,
    topological_fiber_bundle_core.local_triv, topological_fiber_bundle_core.local_triv',
    tangent_bundle_core],
  rw local_equiv.right_inv,
  exact h
end

end charts

end specific_functions

section mfderiv_fderiv

/-! ### Relations between vector space derivative and manifold derivative

The manifold derivative `mfderiv`, when considered on the model vector space with its trivial
manifold structure, coincides with the usual Frechet derivative `fderiv`. In this section, we prove
this and related statements.
-/

variables {𝕜 : Type*} [nondiscrete_normed_field 𝕜]
{E : Type*} [normed_group E] [normed_space 𝕜 E]
{E' : Type*} [normed_group E'] [normed_space 𝕜 E']
{f : E → E'} {s : set E} {x : E}

lemma unique_mdiff_within_at_iff_unique_diff_within_at :
  unique_mdiff_within_at (model_with_corners_self 𝕜 E) s x ↔ unique_diff_within_at 𝕜 s x :=
by simp [unique_mdiff_within_at]

lemma unique_mdiff_on_iff_unique_diff_on :
  unique_mdiff_on (model_with_corners_self 𝕜 E) s ↔ unique_diff_on 𝕜 s :=
by simp [unique_mdiff_on, unique_diff_on, unique_mdiff_within_at_iff_unique_diff_within_at]

@[simp] lemma written_in_ext_chart_model_space :
  written_in_ext_chart_at (model_with_corners_self 𝕜 E) (model_with_corners_self 𝕜 E') x f = f :=
by { ext y, simp [written_in_ext_chart_at] }

/-- For maps between vector spaces, mdifferentiable_within_at and fdifferentiable_within_at coincide -/
theorem mdifferentiable_within_at_iff_differentiable_within_at :
  mdifferentiable_within_at (model_with_corners_self 𝕜 E) (model_with_corners_self 𝕜 E') f s x
  ↔ differentiable_within_at 𝕜 f s x :=
begin
  simp [mdifferentiable_within_at],
  exact ⟨λH, H.2, λH, ⟨H.continuous_within_at, H⟩⟩
end

/-- For maps between vector spaces, mdifferentiable_at and differentiable_at coincide -/
theorem mdifferentiable_at_iff_differentiable_at :
  mdifferentiable_at (model_with_corners_self 𝕜 E) (model_with_corners_self 𝕜 E') f x
  ↔ differentiable_at 𝕜 f x :=
begin
  simp [mdifferentiable_at, differentiable_within_at_univ],
  exact ⟨λH, H.2, λH, ⟨H.continuous_at, H⟩⟩
end

/-- For maps between vector spaces, mdifferentiable_on and differentiable_on coincide -/
theorem mdifferentiable_on_iff_differentiable_on :
  mdifferentiable_on (model_with_corners_self 𝕜 E) (model_with_corners_self 𝕜 E') f s
  ↔ differentiable_on 𝕜 f s :=
by simp [mdifferentiable_on, differentiable_on, mdifferentiable_within_at_iff_differentiable_within_at]

/-- For maps between vector spaces, mdifferentiable and differentiable coincide -/
theorem mdifferentiable_iff_differentiable :
  mdifferentiable (model_with_corners_self 𝕜 E) (model_with_corners_self 𝕜 E') f
  ↔ differentiable 𝕜 f :=
by simp [mdifferentiable, differentiable, mdifferentiable_at_iff_differentiable_at]

/-- For maps between vector spaces, mfderiv_within and fderiv_within coincide -/
theorem mfderiv_within_eq_fderiv_within :
  mfderiv_within (model_with_corners_self 𝕜 E) (model_with_corners_self 𝕜 E') f s x
  = fderiv_within 𝕜 f s x :=
begin
  by_cases h : mdifferentiable_within_at (model_with_corners_self 𝕜 E) (model_with_corners_self 𝕜 E') f s x,
  { simp [mfderiv_within, h] },
  { simp [mfderiv_within, h],
    rw [mdifferentiable_within_at_iff_differentiable_within_at,
        differentiable_within_at] at h,
    change ¬(∃(f' : tangent_space (model_with_corners_self 𝕜 E) x →L[𝕜]
                    tangent_space (model_with_corners_self 𝕜 E') (f x)),
            has_fderiv_within_at f f' s x) at h,
    simp [fderiv_within, h],
    refl }
end

/-- For maps between vector spaces, mfderiv and fderiv coincide -/
theorem mfderiv_eq_fderiv :
  mfderiv (model_with_corners_self 𝕜 E) (model_with_corners_self 𝕜 E') f x = fderiv 𝕜 f x :=
begin
  rw [← mfderiv_within_univ, ← fderiv_within_univ],
  exact mfderiv_within_eq_fderiv_within
end

end mfderiv_fderiv

/-! ### Differentiable local homeomorphisms -/
namespace local_homeomorph.mdifferentiable

variables {𝕜 : Type*} [nondiscrete_normed_field 𝕜]
{E : Type*} [normed_group E] [normed_space 𝕜 E]
{H : Type*} [topological_space H] {I : model_with_corners 𝕜 E H}
{M : Type*} [topological_space M] [manifold H M]
{E' : Type*} [normed_group E'] [normed_space 𝕜 E']
{H' : Type*} [topological_space H'] {I' : model_with_corners 𝕜 E' H'}
{M' : Type*} [topological_space M'] [manifold H' M']
{E'' : Type*} [normed_group E''] [normed_space 𝕜 E'']
{H'' : Type*} [topological_space H''] {I'' : model_with_corners 𝕜 E'' H''}
{M'' : Type*} [topological_space M''] [manifold H'' M'']
{e : local_homeomorph M M'} (he : e.mdifferentiable I I')
{e' : local_homeomorph M' M''}
include he

lemma symm : e.symm.mdifferentiable I' I :=
⟨he.2, he.1⟩

lemma mdifferentiable_at_to_fun {x : M} (hx : x ∈ e.source) :
  mdifferentiable_at I I' e.to_fun x :=
(he.1 x hx).mdifferentiable_at (mem_nhds_sets e.open_source hx)

lemma mdifferentiable_at_inv_fun {x : M'} (hx : x ∈ e.target) :
  mdifferentiable_at I' I e.inv_fun x :=
(he.2 x hx).mdifferentiable_at (mem_nhds_sets e.open_target hx)

variables [smooth_manifold_with_corners I M] [smooth_manifold_with_corners I' M']
[smooth_manifold_with_corners I'' M'']

lemma inv_fun_to_fun_deriv {x : M} (hx : x ∈ e.source) :
  (mfderiv I' I e.inv_fun (e.to_fun x)).comp (mfderiv I I' e.to_fun x) = continuous_linear_map.id :=
begin
  have : (mfderiv I I (e.inv_fun ∘ e.to_fun) x) =
         (mfderiv I' I e.inv_fun (e.to_fun x)).comp (mfderiv I I' e.to_fun x) :=
    mfderiv_comp x (he.mdifferentiable_at_inv_fun (e.map_source hx)) (he.mdifferentiable_at_to_fun hx),
  rw ← this,
  have : mfderiv I I (_root_.id : M → M) x = continuous_linear_map.id := mfderiv_id I,
  rw ← this,
  apply mfderiv_congr_of_mem_nhds,
  have : e.source ∈ 𝓝 x := mem_nhds_sets e.open_source hx,
  apply filter.mem_sets_of_superset this,
  assume p hp,
  simp [e.left_inv, hp]
end

lemma to_fun_inv_fun_deriv {x : M'} (hx : x ∈ e.target) :
  (mfderiv I I' e.to_fun (e.inv_fun x)).comp (mfderiv I' I e.inv_fun x) = continuous_linear_map.id :=
he.symm.inv_fun_to_fun_deriv hx

set_option class.instance_max_depth 60

/-- The derivative of a differentiable local homeomorphism, as a continuous linear equivalence
between the tangent spaces at `x` and `e.to_fun x`. -/
protected def mfderiv {x : M} (hx : x ∈ e.source) :
  tangent_space I x ≃L[𝕜] tangent_space I' (e.to_fun x) :=
{ inv_fun := (mfderiv I' I e.inv_fun (e.to_fun x)).to_fun,
  continuous_to_fun := (mfderiv I I' e.to_fun x).cont,
  continuous_inv_fun := (mfderiv I' I e.inv_fun (e.to_fun x)).cont,
  left_inv := λy, begin
    have : (continuous_linear_map.id : tangent_space I x →L[𝕜] tangent_space I x) y = y := rfl,
    conv_rhs { rw [← this, ← he.inv_fun_to_fun_deriv hx] },
    refl
  end,
  right_inv := λy, begin
    have : (continuous_linear_map.id : tangent_space I' (e.to_fun x) →L[𝕜] tangent_space I' (e.to_fun x)) y = y := rfl,
    conv_rhs { rw [← this, ← he.to_fun_inv_fun_deriv (e.map_source hx)] },
    rw e.to_local_equiv.left_inv hx,
    refl
  end,
  .. mfderiv I I' e.to_fun x }

set_option class.instance_max_depth 100

lemma range_mfderiv_eq_univ {x : M} (hx : x ∈ e.source) :
  range (mfderiv I I' e.to_fun x) = univ :=
(he.mfderiv hx).to_linear_equiv.to_equiv.range_eq_univ

lemma trans (he': e'.mdifferentiable I' I'') : (e.trans e').mdifferentiable I I'' :=
begin
  split,
  { assume x hx,
    simp [local_equiv.trans_source] at hx,
    exact ((he'.mdifferentiable_at_to_fun hx.2).comp _
           (he.mdifferentiable_at_to_fun hx.1)).mdifferentiable_within_at },
  { assume x hx,
    simp [local_equiv.trans_target] at hx,
    exact ((he.mdifferentiable_at_inv_fun hx.2).comp _
           (he'.mdifferentiable_at_inv_fun hx.1)).mdifferentiable_within_at }
end

end local_homeomorph.mdifferentiable

/-! ### Unique derivative sets in manifolds -/
section unique_mdiff

variables {𝕜 : Type*} [nondiscrete_normed_field 𝕜]
{E : Type u} [normed_group E] [normed_space 𝕜 E]
{H : Type*} [topological_space H] {I : model_with_corners 𝕜 E H}
{M : Type*} [topological_space M] [manifold H M] [smooth_manifold_with_corners I M]
{E' : Type u} [normed_group E'] [normed_space 𝕜 E']
{H' : Type*} [topological_space H'] {I' : model_with_corners 𝕜 E' H'}
{M' : Type*} [topological_space M'] [manifold H' M']
{s : set M}

/-- If a set has the unique differential property, then its image under a local
diffeomorphism also has the unique differential property. -/
lemma unique_mdiff_on.unique_mdiff_on_preimage [smooth_manifold_with_corners I' M']
  (hs : unique_mdiff_on I s) {e : local_homeomorph M M'} (he : e.mdifferentiable I I') :
  unique_mdiff_on I' (e.target ∩ e.inv_fun ⁻¹' s) :=
begin
  /- Start from a point `x` in the image, and let `z` be its preimage. Then the unique
  derivative property at `x` is expressed through `ext_chart_at I' x`, and the unique
  derivative property at `z` is expressed through `ext_chart_at I z`. We will argue that
  the composition of these two charts with `e` is a local diffeomorphism in vector spaces,
  and therefore preserves the unique differential property thanks to lemma
  `has_fderiv_within_at.unique_diff_within_at`, saying that a differentiable function with onto
  derivative preserves the unique derivative property.-/
  assume x hx,
  let z := e.inv_fun x,
  have z_source : z ∈ e.source, by simp [hx.1, local_equiv.map_target],
  have zx : e.to_fun z = x, by simp [z, hx.1],
  let F := ext_chart_at I z,
  -- the unique derivative property at `z` is expressed through its preferred chart, that we call `F`.
  have B : unique_diff_within_at 𝕜
    (F.inv_fun ⁻¹' (s ∩ (e.source ∩ e.to_fun ⁻¹' ((ext_chart_at I' x).source))) ∩ F.target) (F.to_fun z),
  { have : unique_mdiff_within_at I s z := hs _ hx.2,
    have S : e.source ∩ e.to_fun ⁻¹' ((ext_chart_at I' x).source) ∈ 𝓝 z,
    { apply mem_nhds_sets,
      apply e.continuous_to_fun.preimage_open_of_open e.open_source (ext_chart_at_open_source I' x),
      simp [z_source, zx] },
    have := this.inter S,
    rw [unique_mdiff_within_at_iff] at this,
    exact this },
  -- denote by `G` the change of coordinate, i.e., the composition of the two extended charts and
  -- of `e`
  let G := F.symm ≫ e.to_local_equiv ≫ (ext_chart_at I' x),
  -- `G` is differentiable
  have M : ((chart_at H z).symm ≫ₕ e ≫ₕ (chart_at H' x)).mdifferentiable I I',
  { have A := mdifferentiable_of_mem_atlas I (chart_mem_atlas H z),
    have B := mdifferentiable_of_mem_atlas I' (chart_mem_atlas H' x),
    exact A.symm.trans (he.trans B) },
  have Mmem : (chart_at H z).to_fun z ∈ ((chart_at H z).symm ≫ₕ e ≫ₕ (chart_at H' x)).source,
    by simp [local_equiv.trans_source, local_equiv.map_source, z_source, zx],
  have A : differentiable_within_at 𝕜 G.to_fun (range I.to_fun) (F.to_fun z),
  { refine (M.mdifferentiable_at_to_fun Mmem).2.congr (λp hp, _) _;
    simp [G, written_in_ext_chart_at, ext_chart_at, F] },
  -- let `G'` be its derivative
  let G' := fderiv_within 𝕜 G.to_fun (range I.to_fun) (F.to_fun z),
  have D₁ : has_fderiv_within_at G.to_fun G' (range I.to_fun) (F.to_fun z) :=
    A.has_fderiv_within_at,
  have D₂ : has_fderiv_within_at G.to_fun G'
    (F.inv_fun ⁻¹' (s ∩ (e.source ∩ e.to_fun ⁻¹' ((ext_chart_at I' x).source))) ∩ F.target) (F.to_fun z),
  { apply D₁.mono,
    refine subset.trans (inter_subset_right _ _) _,
    simp [F, ext_chart_at, local_equiv.trans_target] },
  -- The derivative `G'` is onto, as it is the derivative of a local diffeomorphism, the composition
  -- of the two charts and of `e`.
  have C₁ : range (G' : E → E') = univ,
  { have : G' = mfderiv I I' ((chart_at H z).symm ≫ₕ e ≫ₕ (chart_at H' x)).to_fun ((chart_at H z).to_fun z),
      by { rw (M.mdifferentiable_at_to_fun Mmem).mfderiv, refl },
    rw this,
    exact M.range_mfderiv_eq_univ Mmem },
  have C₂ : closure (range (G' : E → E')) = univ, by rw [C₁, closure_univ],
  -- key step: thanks to what we have proved about it, `G` preserves the unique derivative property
  have key : unique_diff_within_at 𝕜
    (G.to_fun '' (F.inv_fun ⁻¹' (s ∩ (e.source ∩ e.to_fun ⁻¹' ((ext_chart_at I' x).source))) ∩ F.target))
    (G.to_fun (F.to_fun z)) := D₂.unique_diff_within_at B C₂,
  have : G.to_fun (F.to_fun z) = (ext_chart_at I' x).to_fun x, by { dsimp [G, F], simp [hx.1] },
  rw this at key,
  apply key.mono,
  show G.to_fun '' (F.inv_fun ⁻¹' (s ∩ (e.source ∩ e.to_fun ⁻¹' ((ext_chart_at I' x).source))) ∩ F.target) ⊆
    (ext_chart_at I' x).inv_fun ⁻¹' e.target ∩ (ext_chart_at I' x).inv_fun ⁻¹' (e.inv_fun ⁻¹' s) ∩
      range (I'.to_fun),
  rw image_subset_iff,
  rintros p ⟨⟨hp₁, ⟨hp₂, hp₄⟩⟩, hp₃⟩,
  simp [G, local_equiv.map_source, hp₂, hp₁, mem_preimage.1 hp₄, -mem_range, mem_range_self],
  exact mem_range_self _
end

/-- If a set in a manifold has the unique derivative property, then its pullback by any extended
chart, in the vector space, also has the unique derivative property. -/
lemma unique_mdiff_on.unique_diff_on (hs : unique_mdiff_on I s) (x : M) :
  unique_diff_on 𝕜 ((ext_chart_at I x).target ∩ ((ext_chart_at I x).inv_fun ⁻¹' s)) :=
begin
  -- this is just a reformulation of `unique_mdiff_on.unique_mdiff_on_preimage`, using as `e`
  -- the local chart at `x`.
  assume z hz,
  simp [ext_chart_at, local_equiv.trans_target, -mem_range] at hz,
  have : (chart_at H x).mdifferentiable I I := mdifferentiable_chart _ _,
  have T := (hs.unique_mdiff_on_preimage this) (I.inv_fun z),
  simp only [ext_chart_at, (hz.left).left, (hz.left).right, hz.right, local_equiv.trans_target,
    unique_mdiff_on, unique_mdiff_within_at, local_equiv.refl_trans, forall_prop_of_true,
    model_with_corners_target, mem_inter_eq, preimage_inter, mem_preimage, chart_at_model_space_eq,
    local_homeomorph.refl_local_equiv, and_self, model_with_corners_right_inv,
    local_equiv.trans_inv_fun] at ⊢ T,
  convert T using 1,
  rw @preimage_comp _ _ _ _ (chart_at H x).inv_fun,
  -- it remains to show that `(a ∩ b) ∩ c` = `(b ∩ c) ∩ a`, which finish can do but very slowly
  ext p,
  split;
  { assume hp, simp at hp, simp [hp] }
end

/-- When considering functions between manifolds, this statement shows up often. It entails
the unique differential of the pullback in extended charts of the set where the function can
be read in the charts. -/
lemma unique_mdiff_on.unique_diff_on_inter_preimage (hs : unique_mdiff_on I s) (x : M) (y : M')
  {f : M → M'} (hf : continuous_on f s) :
  unique_diff_on 𝕜 ((ext_chart_at I x).target
    ∩ ((ext_chart_at I x).inv_fun ⁻¹' (s ∩ f⁻¹' (ext_chart_at I' y).source))) :=
begin
  have : unique_mdiff_on I (s ∩ f ⁻¹' (ext_chart_at I' y).source),
  { assume z hz,
    apply (hs z hz.1).inter',
    apply (hf z hz.1).preimage_mem_nhds_within,
    exact mem_nhds_sets (ext_chart_at_open_source I' y) hz.2 },
  exact this.unique_diff_on _
end

variables {F : Type u} [normed_group F] [normed_space 𝕜 F]
(Z : basic_smooth_bundle_core I M F)

/-- In a smooth fiber bundle constructed from core, the preimage under the projection of a set with
unique differential in the basis also has unique differential. -/
lemma unique_mdiff_on.smooth_bundle_preimage (hs : unique_mdiff_on I s) :
  unique_mdiff_on (I.prod (model_with_corners_self 𝕜 F))
  (Z.to_topological_fiber_bundle_core.proj ⁻¹' s) :=
begin
  /- Using a chart (and the fact that unique differentiability is invariant under charts), we
  reduce the situation to the model space, where we can use the fact that products respect
  unique differentiability. -/
  assume p hp,
  replace hp : p.fst ∈ s, by simpa using hp,
  let e₀ := chart_at H p.1,
  let e := chart_at (H × F) p,
  -- It suffices to prove unique differentiability in a chart
  suffices h : unique_mdiff_on (I.prod (model_with_corners_self 𝕜 F))
    (e.target ∩ e.inv_fun⁻¹' (Z.to_topological_fiber_bundle_core.proj ⁻¹' s)),
  { have A : unique_mdiff_on (I.prod (model_with_corners_self 𝕜 F)) (e.symm.target ∩
      e.symm.inv_fun ⁻¹' (e.target ∩ e.inv_fun⁻¹' (Z.to_topological_fiber_bundle_core.proj ⁻¹' s))),
    { apply h.unique_mdiff_on_preimage,
      exact (mdifferentiable_of_mem_atlas _ (chart_mem_atlas _ _)).symm,
      apply_instance },
    have : p ∈ e.symm.target ∩
      e.symm.inv_fun ⁻¹' (e.target ∩ e.inv_fun⁻¹' (Z.to_topological_fiber_bundle_core.proj ⁻¹' s)),
        by simp [e, hp],
    apply (A _ this).mono,
    assume q hq,
    simp [e, local_equiv.left_inv _ hq.1] at hq,
    simp [hq] },
  -- rewrite the relevant set in the chart as a direct product
  have : (λ (p : E × F), (I.inv_fun p.1, p.snd)) ⁻¹' e.target ∩
         (λ (p : E × F), (I.inv_fun p.1, p.snd)) ⁻¹' (e.inv_fun ⁻¹' (prod.fst ⁻¹' s)) ∩
         range (λ (p : H × F), (I.to_fun p.1, p.snd))
    = set.prod (I.inv_fun ⁻¹' (e₀.target ∩ e₀.inv_fun⁻¹' s) ∩ range I.to_fun) univ,
  { ext q,
    split;
    { assume hq,
      simp [-mem_range, mem_range_self, prod_range_univ_eq.symm] at hq,
      simp [-mem_range, mem_range_self, hq, prod_range_univ_eq.symm] } },
  assume q hq,
  replace hq : q.1 ∈ (chart_at H p.1).target ∧ (chart_at H p.1).inv_fun q.1 ∈ s,
    by simpa using hq,
  simp only [unique_mdiff_within_at, ext_chart_at, model_with_corners.prod, local_equiv.refl_trans,
             local_equiv.refl_to_fun, topological_fiber_bundle_core.proj, id.def, range_id,
             model_with_corners_self_local_equiv, local_equiv.refl_inv_fun, preimage_inter,
             chart_at_model_space_eq, local_homeomorph.refl_local_equiv, this],
  -- apply unique differentiability of products to conclude
  apply unique_diff_on.prod _ is_open_univ.unique_diff_on,
  { simp [-mem_range, mem_range_self, hq] },
  { assume x hx,
    have A : unique_mdiff_on I (e₀.target ∩ e₀.inv_fun⁻¹' s),
    { apply hs.unique_mdiff_on_preimage,
      exact (mdifferentiable_of_mem_atlas _ (chart_mem_atlas _ _)),
      apply_instance },
    simp [unique_mdiff_on, unique_mdiff_within_at, ext_chart_at] at A,
    have B := A (I.inv_fun x) hx.1.1 hx.1.2,
    rwa [← preimage_inter, model_with_corners_right_inv _ hx.2] at B }
end

lemma unique_mdiff_on.tangent_bundle_proj_preimage (hs : unique_mdiff_on I s):
  unique_mdiff_on I.tangent ((tangent_bundle.proj I M) ⁻¹' s) :=
hs.smooth_bundle_preimage _

end unique_mdiff
