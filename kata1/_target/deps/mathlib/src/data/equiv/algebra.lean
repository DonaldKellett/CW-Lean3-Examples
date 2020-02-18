/-
Copyright (c) 2018 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl, Callum Sutton
-/

import data.equiv.basic algebra.field

/-!
# equivs in the algebraic hierarchy

In the first part there are theorems of the following
form: if `α` has a group structure and `α ≃ β` then `β` has a group structure, and
similarly for monoids, semigroups, rings, integral domains, fields and so on.

In the second part there are extensions of `equiv` called `add_equiv`,
`mul_equiv`, and `ring_equiv`, which are datatypes representing
isomorphisms of add_monoids/add_groups, monoids/groups and rings. We
also introduce the corresponding groups of automorphisms `add_aut`,
`mul_aut`, and `ring_aut`.

## Notations

The extended equivs all have coercions to functions, and the coercions are the canonical
notation when treating the isomorphisms as maps.

## Implementation notes

The fields for `mul_equiv`, `add_equiv`, and `ring_equiv` now avoid
the unbundled `is_mul_hom` and `is_add_hom`, as these are deprecated.

Definition of multiplication in the groups of automorphisms agrees
with function composition, multiplication in `equiv.perm`, and
multiplication in `category_theory.End`, not with
`category_theory.comp`.

## Tags

equiv, mul_equiv, add_equiv, ring_equiv, mul_aut, add_aut, ring_aut
-/

universes u v w x
variables {α : Type u} {β : Type v} {γ : Type w} {δ : Type x}

namespace equiv

section group
variables [group α]

@[to_additive]
protected def mul_left (a : α) : α ≃ α :=
{ to_fun    := λx, a * x,
  inv_fun   := λx, a⁻¹ * x,
  left_inv  := assume x, show a⁻¹ * (a * x) = x, from inv_mul_cancel_left a x,
  right_inv := assume x, show a * (a⁻¹ * x) = x, from mul_inv_cancel_left a x }

@[to_additive]
protected def mul_right (a : α) : α ≃ α :=
{ to_fun    := λx, x * a,
  inv_fun   := λx, x * a⁻¹,
  left_inv  := assume x, show (x * a) * a⁻¹ = x, from mul_inv_cancel_right x a,
  right_inv := assume x, show (x * a⁻¹) * a = x, from inv_mul_cancel_right x a }

@[to_additive]
protected def inv (α) [group α] : α ≃ α :=
{ to_fun    := λa, a⁻¹,
  inv_fun   := λa, a⁻¹,
  left_inv  := assume a, inv_inv a,
  right_inv := assume a, inv_inv a }

end group

section field

variables (α) [field α]

def units_equiv_ne_zero : units α ≃ {a : α | a ≠ 0} :=
⟨λ a, ⟨a.1, units.ne_zero _⟩, λ a, units.mk0 _ a.2, λ ⟨_, _, _, _⟩, units.ext rfl, λ ⟨_, _⟩, rfl⟩

variable {α}

@[simp] lemma coe_units_equiv_ne_zero (a : units α) :
  ((units_equiv_ne_zero α a) : α) = a := rfl

end field

section instances

variables (e : α ≃ β)

protected def has_zero [has_zero β] : has_zero α := ⟨e.symm 0⟩
lemma zero_def [has_zero β] : @has_zero.zero _ (equiv.has_zero e) = e.symm 0 := rfl

protected def has_one [has_one β] : has_one α := ⟨e.symm 1⟩
lemma one_def [has_one β] : @has_one.one _ (equiv.has_one e) = e.symm 1 := rfl

protected def has_mul [has_mul β] : has_mul α := ⟨λ x y, e.symm (e x * e y)⟩
lemma mul_def [has_mul β] (x y : α) :
  @has_mul.mul _ (equiv.has_mul e) x y = e.symm (e x * e y) := rfl

protected def has_add [has_add β] : has_add α := ⟨λ x y, e.symm (e x + e y)⟩
lemma add_def [has_add β] (x y : α) :
  @has_add.add _ (equiv.has_add e) x y = e.symm (e x + e y) := rfl

protected def has_inv [has_inv β] : has_inv α := ⟨λ x, e.symm (e x)⁻¹⟩
lemma inv_def [has_inv β] (x : α) : @has_inv.inv _ (equiv.has_inv e) x = e.symm (e x)⁻¹ := rfl

protected def has_neg [has_neg β] : has_neg α := ⟨λ x, e.symm (-e x)⟩
lemma neg_def [has_neg β] (x : α) : @has_neg.neg _ (equiv.has_neg e) x = e.symm (-e x) := rfl

protected def semigroup [semigroup β] : semigroup α :=
{ mul_assoc := by simp [mul_def, mul_assoc],
  ..equiv.has_mul e }

protected def comm_semigroup [comm_semigroup β] : comm_semigroup α :=
{ mul_comm := by simp [mul_def, mul_comm],
  ..equiv.semigroup e }

protected def monoid [monoid β] : monoid α :=
{ one_mul := by simp [mul_def, one_def],
  mul_one := by simp [mul_def, one_def],
  ..equiv.semigroup e,
  ..equiv.has_one e }

protected def comm_monoid [comm_monoid β] : comm_monoid α :=
{ ..equiv.comm_semigroup e,
  ..equiv.monoid e }

protected def group [group β] : group α :=
{ mul_left_inv := by simp [mul_def, inv_def, one_def],
  ..equiv.monoid e,
  ..equiv.has_inv e }

protected def comm_group [comm_group β] : comm_group α :=
{ ..equiv.group e,
  ..equiv.comm_semigroup e }

protected def add_semigroup [add_semigroup β] : add_semigroup α :=
@additive.add_semigroup _ (@equiv.semigroup _ _ e multiplicative.semigroup)

protected def add_comm_semigroup [add_comm_semigroup β] : add_comm_semigroup α :=
@additive.add_comm_semigroup _ (@equiv.comm_semigroup _ _ e multiplicative.comm_semigroup)

protected def add_monoid [add_monoid β] : add_monoid α :=
@additive.add_monoid _ (@equiv.monoid _ _ e multiplicative.monoid)

protected def add_comm_monoid [add_comm_monoid β] : add_comm_monoid α :=
@additive.add_comm_monoid _ (@equiv.comm_monoid _ _ e multiplicative.comm_monoid)

protected def add_group [add_group β] : add_group α :=
@additive.add_group _ (@equiv.group _ _ e multiplicative.group)

protected def add_comm_group [add_comm_group β] : add_comm_group α :=
@additive.add_comm_group _ (@equiv.comm_group _ _ e multiplicative.comm_group)

protected def semiring [semiring β] : semiring α :=
{ right_distrib := by simp [mul_def, add_def, add_mul],
  left_distrib := by simp [mul_def, add_def, mul_add],
  zero_mul := by simp [mul_def, zero_def],
  mul_zero := by simp [mul_def, zero_def],
  ..equiv.has_zero e,
  ..equiv.has_mul e,
  ..equiv.has_add e,
  ..equiv.monoid e,
  ..equiv.add_comm_monoid e }

protected def comm_semiring [comm_semiring β] : comm_semiring α :=
{ ..equiv.semiring e,
  ..equiv.comm_monoid e }

protected def ring [ring β] : ring α :=
{ ..equiv.semiring e,
  ..equiv.add_comm_group e }

protected def comm_ring [comm_ring β] : comm_ring α :=
{ ..equiv.comm_monoid e,
  ..equiv.ring e }

protected def zero_ne_one_class [zero_ne_one_class β] : zero_ne_one_class α :=
{ zero_ne_one := by simp [zero_def, one_def],
  ..equiv.has_zero e,
  ..equiv.has_one e }

protected def nonzero_comm_ring [nonzero_comm_ring β] : nonzero_comm_ring α :=
{ ..equiv.zero_ne_one_class e,
  ..equiv.comm_ring e }

protected def domain [domain β] : domain α :=
{ eq_zero_or_eq_zero_of_mul_eq_zero := by simp [mul_def, zero_def, equiv.eq_symm_apply],
  ..equiv.has_zero e,
  ..equiv.zero_ne_one_class e,
  ..equiv.has_mul e,
  ..equiv.ring e }

protected def integral_domain [integral_domain β] : integral_domain α :=
{ ..equiv.domain e,
  ..equiv.nonzero_comm_ring e }

protected def division_ring [division_ring β] : division_ring α :=
{ inv_mul_cancel := λ _,
    by simp [mul_def, inv_def, zero_def, one_def, (equiv.symm_apply_eq _).symm];
      exact inv_mul_cancel,
  mul_inv_cancel := λ _,
    by simp [mul_def, inv_def, zero_def, one_def, (equiv.symm_apply_eq _).symm];
      exact mul_inv_cancel,
  ..equiv.has_zero e,
  ..equiv.has_one e,
  ..equiv.domain e,
  ..equiv.has_inv e }

protected def field [field β] : field α :=
{ ..equiv.integral_domain e,
  ..equiv.division_ring e }

protected def discrete_field [discrete_field β] : discrete_field α :=
{ has_decidable_eq := equiv.decidable_eq e,
  inv_zero := by simp [mul_def, inv_def, zero_def],
  ..equiv.has_mul e,
  ..equiv.has_inv e,
  ..equiv.has_zero e,
  ..equiv.field e }

end instances
end equiv

set_option old_structure_cmd true

/-- add_equiv α β is the type of an equiv α ≃ β which preserves addition. -/
structure add_equiv (α β : Type*) [has_add α] [has_add β] extends α ≃ β :=
(map_add' : ∀ x y : α, to_fun (x + y) = to_fun x + to_fun y)

/-- `mul_equiv α β` is the type of an equiv `α ≃ β` which preserves multiplication. -/
@[to_additive "`add_equiv α β` is the type of an equiv `α ≃ β` which preserves addition."]
structure mul_equiv (α β : Type*) [has_mul α] [has_mul β] extends α ≃ β :=
(map_mul' : ∀ x y : α, to_fun (x * y) = to_fun x * to_fun y)

infix ` ≃* `:25 := mul_equiv
infix ` ≃+ `:25 := add_equiv

namespace mul_equiv

@[to_additive]
instance {α β} [has_mul α] [has_mul β] : has_coe_to_fun (α ≃* β) := ⟨_, mul_equiv.to_fun⟩

variables [has_mul α] [has_mul β] [has_mul γ]

/-- A multiplicative isomorphism preserves multiplication (canonical form). -/
@[to_additive]
lemma map_mul (f : α ≃* β) :  ∀ x y : α, f (x * y) = f x * f y := f.map_mul'

/-- A multiplicative isomorphism preserves multiplication (deprecated). -/
@[to_additive]
instance (h : α ≃* β) : is_mul_hom h := ⟨h.map_mul⟩

/-- Makes a multiplicative isomorphism from a bijection which preserves multiplication. -/
@[to_additive]
def mk' (f : α ≃ β) (h : ∀ x y, f (x * y) = f x * f y) : α ≃* β :=
⟨f.1, f.2, f.3, f.4, h⟩

/-- The identity map is a multiplicative isomorphism. -/
@[refl, to_additive]
def refl (α : Type*) [has_mul α] : α ≃* α :=
{ map_mul' := λ _ _,rfl,
..equiv.refl _}

/-- The inverse of an isomorphism is an isomorphism. -/
@[symm, to_additive]
def symm (h : α ≃* β) : β ≃* α :=
{ map_mul' := λ n₁ n₂, function.injective_of_left_inverse h.left_inv begin
    show h.to_equiv (h.to_equiv.symm (n₁ * n₂)) =
      h ((h.to_equiv.symm n₁) * (h.to_equiv.symm n₂)),
   rw h.map_mul,
   show _ = h.to_equiv (_) * h.to_equiv (_),
   rw [h.to_equiv.apply_symm_apply, h.to_equiv.apply_symm_apply, h.to_equiv.apply_symm_apply], end,
  ..h.to_equiv.symm}

@[simp, to_additive]
theorem to_equiv_symm (f : α ≃* β) : f.symm.to_equiv = f.to_equiv.symm := rfl

/-- Transitivity of multiplication-preserving isomorphisms -/
@[trans, to_additive]
def trans (h1 : α ≃* β) (h2 : β ≃* γ) : (α ≃* γ) :=
{ map_mul' := λ x y, show h2 (h1 (x * y)) = h2 (h1 x) * h2 (h1 y),
    by rw [h1.map_mul, h2.map_mul],
  ..h1.to_equiv.trans h2.to_equiv }

/-- e.right_inv in canonical form -/
@[simp, to_additive]
lemma apply_symm_apply (e : α ≃* β) : ∀ (y : β), e (e.symm y) = y :=
e.to_equiv.apply_symm_apply

/-- e.left_inv in canonical form -/
@[simp, to_additive]
lemma symm_apply_apply (e : α ≃* β) : ∀ (x : α), e.symm (e x) = x :=
equiv.symm_apply_apply (e.to_equiv)

/-- a multiplicative equiv of monoids sends 1 to 1 (and is hence a monoid isomorphism) -/
@[simp, to_additive]
lemma map_one {α β} [monoid α] [monoid β] (h : α ≃* β) : h 1 = 1 :=
by rw [←mul_one (h 1), ←h.apply_symm_apply 1, ←h.map_mul, one_mul]

@[simp, to_additive]
lemma map_eq_one_iff {α β} [monoid α] [monoid β] (h : α ≃* β) {x : α} :
  h x = 1 ↔ x = 1 :=
h.map_one ▸ h.to_equiv.apply_eq_iff_eq x 1

@[to_additive]
lemma map_ne_one_iff {α β} [monoid α] [monoid β] (h : α ≃* β) {x : α} :
  h x ≠ 1 ↔ x ≠ 1 :=
⟨mt h.map_eq_one_iff.2, mt h.map_eq_one_iff.1⟩

/--
Extract the forward direction of a multiplicative equivalence
as a multiplication preserving function.
-/
@[to_additive to_add_monoid_hom]
def to_monoid_hom {α β} [monoid α] [monoid β] (h : α ≃* β) : (α →* β) :=
{ to_fun := h,
  map_mul' := h.map_mul,
  map_one' := h.map_one }

@[simp, to_additive]
lemma to_monoid_hom_apply_symm_to_monoid_hom_apply {α β} [monoid α] [monoid β] (e : α ≃* β) :
  ∀ (y : β), e.to_monoid_hom (e.symm.to_monoid_hom y) = y :=
e.to_equiv.apply_symm_apply

@[simp, to_additive]
lemma symm_to_monoid_hom_apply_to_monoid_hom_apply {α β} [monoid α] [monoid β] (e : α ≃* β) :
  ∀ (x : α), e.symm.to_monoid_hom (e.to_monoid_hom x) = x :=
equiv.symm_apply_apply (e.to_equiv)

/-- A multiplicative equivalence of groups preserves inversion. -/
@[to_additive]
lemma map_inv {α β} [group α] [group β] (h : α ≃* β) (x : α) : h x⁻¹ = (h x)⁻¹ :=
h.to_monoid_hom.map_inv x

/-- A multiplicative bijection between two monoids is a monoid hom
  (deprecated -- use to_monoid_hom). -/
@[to_additive is_add_monoid_hom]
instance is_monoid_hom {α β} [monoid α] [monoid β] (h : α ≃* β) : is_monoid_hom h :=
⟨h.map_one⟩

/-- A multiplicative bijection between two groups is a group hom
  (deprecated -- use to_monoid_hom). -/
@[to_additive is_add_group_hom]
instance is_group_hom {α β} [group α] [group β] (h : α ≃* β) :
  is_group_hom h := { map_mul := h.map_mul }

/-- Two multiplicative isomorphisms agree if they are defined by the
    same underlying function. -/
@[ext, to_additive
  "Two additive isomorphisms agree if they are defined by the same underlying function."]
lemma ext {α β : Type*} [has_mul α] [has_mul β]
  {f g : mul_equiv α β} (h : ∀ x, f x = g x) : f = g :=
begin
  have h₁ := equiv.ext f.to_equiv g.to_equiv h,
  cases f, cases g, congr,
  { exact (funext h) },
  { exact congr_arg equiv.inv_fun h₁ }
end

attribute [ext] add_equiv.ext

end mul_equiv

/-- An additive equivalence of additive groups preserves subtraction. -/
lemma add_equiv.map_sub {α β} [add_group α] [add_group β] (h : α ≃+ β) (x y : α) :
  h (x - y) = h x - h y :=
h.to_add_monoid_hom.map_sub x y


/-- The group of multiplicative automorphisms. -/
@[to_additive "The group of additive automorphisms."]
def mul_aut (α : Type u) [has_mul α] := α ≃* α

namespace mul_aut

variables (α) [has_mul α]

/--
The group operation on multiplicative automorphisms is defined by
`λ g h, mul_equiv.trans h g`.
This means that multiplication agrees with composition, `(g*h)(x) = g (h x)`.
-/
instance : group (mul_aut α) :=
by refine_struct
{ mul := λ g h, mul_equiv.trans h g,
  one := mul_equiv.refl α,
  inv := mul_equiv.symm };
intros; ext; try { refl }; apply equiv.left_inv

instance : inhabited (mul_aut α) := ⟨1⟩

/-- Monoid hom from the group of multiplicative automorphisms to the group of permutations. -/
def to_perm : mul_aut α →* equiv.perm α :=
by refine_struct { to_fun := mul_equiv.to_equiv }; intros; refl

end mul_aut

namespace add_aut

variables (α) [has_add α]

/--
The group operation on additive automorphisms is defined by
`λ g h, mul_equiv.trans h g`.
This means that multiplication agrees with composition, `(g*h)(x) = g (h x)`.
-/
instance group : group (add_aut α) :=
by refine_struct
{ mul := λ g h, add_equiv.trans h g,
  one := add_equiv.refl α,
  inv := add_equiv.symm };
intros; ext; try { refl }; apply equiv.left_inv

instance : inhabited (add_aut α) := ⟨1⟩

/-- Monoid hom from the group of multiplicative automorphisms to the group of permutations. -/
def to_perm : add_aut α →* equiv.perm α :=
by refine_struct { to_fun := add_equiv.to_equiv }; intros; refl

end add_aut

/-- A group is isomorphic to its group of units. -/
def to_units (α) [group α] : α ≃* units α :=
{ to_fun := λ x, ⟨x, x⁻¹, mul_inv_self _, inv_mul_self _⟩,
  inv_fun := coe,
  left_inv := λ x, rfl,
  right_inv := λ u, units.ext rfl,
  map_mul' := λ x y, units.ext rfl }

namespace units

variables [monoid α] [monoid β] [monoid γ]
(f : α → β) (g : β → γ) [is_monoid_hom f] [is_monoid_hom g]

def map_equiv (h : α ≃* β) : units α ≃* units β :=
{ inv_fun := map h.symm.to_monoid_hom,
  left_inv := λ u, ext $ h.left_inv u,
  right_inv := λ u, ext $ h.right_inv u,
  .. map h.to_monoid_hom }

end units

/- (semi)ring equivalence. -/
structure ring_equiv (α β : Type*) [has_mul α] [has_add α] [has_mul β] [has_add β]
  extends α ≃ β, α ≃* β, α ≃+ β

infix ` ≃+* `:25 := ring_equiv

namespace ring_equiv

section basic

variables [has_mul α] [has_add α] [has_mul β] [has_add β] [has_mul γ] [has_add γ]

instance : has_coe_to_fun (α ≃+* β) := ⟨_, ring_equiv.to_fun⟩

instance has_coe_to_mul_equiv : has_coe (α ≃+* β) (α ≃* β) := ⟨ring_equiv.to_mul_equiv⟩

instance has_coe_to_add_equiv : has_coe (α ≃+* β) (α ≃+ β) := ⟨ring_equiv.to_add_equiv⟩

@[squash_cast] lemma coe_mul_equiv (f : α ≃+* β) (a : α) :
  (f : α ≃* β) a = f a := rfl

@[squash_cast] lemma coe_add_equiv (f : α ≃+* β) (a : α) :
  (f : α ≃+ β) a = f a := rfl

variable (α)

/-- The identity map is a ring isomorphism. -/
@[refl] protected def refl : α ≃+* α := { .. mul_equiv.refl α, .. add_equiv.refl α }

variables {α}

/-- The inverse of a ring isomorphism is a ring isomorphis. -/
@[symm] protected def symm (e : α ≃+* β) : β ≃+* α :=
{ .. e.to_mul_equiv.symm, .. e.to_add_equiv.symm }

/-- Transitivity of `ring_equiv`. -/
@[trans] protected def trans (e₁ : α ≃+* β) (e₂ : β ≃+* γ) : α ≃+* γ :=
{ .. (e₁.to_mul_equiv.trans e₂.to_mul_equiv), .. (e₁.to_add_equiv.trans e₂.to_add_equiv) }

@[simp] lemma apply_symm_apply (e : α ≃+* β) : ∀ x, e (e.symm x) = x := e.to_equiv.apply_symm_apply
@[simp] lemma symm_apply_apply (e : α ≃+* β) : ∀ x, e.symm (e x) = x := e.to_equiv.symm_apply_apply

lemma image_eq_preimage (e : α ≃+* β) (s : set α) : e '' s = e.symm ⁻¹' s :=
e.to_equiv.image_eq_preimage s

end basic

section

variables [semiring α] [semiring β] (f : α ≃+* β) (x y : α)

/-- A ring isomorphism preserves multiplication. -/
@[simp] lemma map_mul : f (x * y) = f x * f y := f.map_mul' x y

/-- A ring isomorphism sends one to one. -/
@[simp] lemma map_one : f 1 = 1 := (f : α ≃* β).map_one

/-- A ring isomorphism preserves addition. -/
@[simp] lemma map_add : f (x + y) = f x + f y := f.map_add' x y

/-- A ring isomorphism sends zero to zero. -/
@[simp] lemma map_zero : f 0 = 0 := (f : α ≃+ β).map_zero

variable {x}

@[simp] lemma map_eq_one_iff : f x = 1 ↔ x = 1 := (f : α ≃* β).map_eq_one_iff
@[simp] lemma map_eq_zero_iff : f x = 0 ↔ x = 0 := (f : α ≃+ β).map_eq_zero_iff

lemma map_ne_one_iff : f x ≠ 1 ↔ x ≠ 1 := (f : α ≃* β).map_ne_one_iff
lemma map_ne_zero_iff : f x ≠ 0 ↔ x ≠ 0 := (f : α ≃+ β).map_ne_zero_iff

end

section

variables [ring α] [ring β] (f : α ≃+* β) (x y : α)

@[simp] lemma map_neg : f (-x) = -f x := (f : α ≃+ β).map_neg x

@[simp] lemma map_sub : f (x - y) = f x - f y := (f : α ≃+ β).map_sub x y

@[simp] lemma map_neg_one : f (-1) = -1 := f.map_one ▸ f.map_neg 1

end

section semiring_hom

variables [semiring α] [semiring β]

/-- Reinterpret a ring equivalence as a ring homomorphism. -/
def to_ring_hom (e : α ≃+* β) : α →+* β :=
{ .. e.to_mul_equiv.to_monoid_hom, .. e.to_add_equiv.to_add_monoid_hom }

/-- Reinterpret a ring equivalence as a monoid homomorphism. -/
abbreviation to_monoid_hom (e : α ≃+* β) : α →* β := e.to_ring_hom.to_monoid_hom

/-- Reinterpret a ring equivalence as an `add_monoid` homomorphism. -/
abbreviation to_add_monoid_hom (e : α ≃+* β) : α →+ β := e.to_ring_hom.to_add_monoid_hom

/-- Interpret an equivalence `f : α ≃ β` as a ring equivalence `α ≃+* β`. -/
def of (e : α ≃ β) [is_semiring_hom e] : α ≃+* β :=
{ .. e, .. monoid_hom.of e, .. add_monoid_hom.of e }

instance (e : α ≃+* β) : is_semiring_hom e := e.to_ring_hom.is_semiring_hom

@[simp]
lemma to_ring_hom_apply_symm_to_ring_hom_apply {α β} [semiring α] [semiring β] (e : α ≃+* β) :
  ∀ (y : β), e.to_ring_hom (e.symm.to_ring_hom y) = y :=
e.to_equiv.apply_symm_apply

@[simp]
lemma symm_to_ring_hom_apply_to_ring_hom_apply {α β} [semiring α] [semiring β] (e : α ≃+* β) :
  ∀ (x : α), e.symm.to_ring_hom (e.to_ring_hom x) = x :=
equiv.symm_apply_apply (e.to_equiv)

end semiring_hom

end ring_equiv

namespace mul_equiv

/-- Gives an `is_semiring_hom` instance from a `mul_equiv` of semirings that preserves addition. -/
protected lemma to_semiring_hom {R : Type*} {S : Type*} [semiring R] [semiring S]
  (h : R ≃* S) (H : ∀ x y : R, h (x + y) = h x + h y) : is_semiring_hom h :=
⟨add_equiv.map_zero $ add_equiv.mk' h.to_equiv H, h.map_one, H, h.5⟩

/-- Gives a `ring_equiv` from a `mul_equiv` preserving addition.-/
def to_ring_equiv {R : Type*} {S : Type*} [has_add R] [has_add S] [has_mul R] [has_mul S]
  (h : R ≃* S) (H : ∀ x y : R, h (x + y) = h x + h y) : R ≃+* S :=
{..h.to_equiv, ..h, ..add_equiv.mk' h.to_equiv H }

end mul_equiv

namespace add_equiv

/-- Gives an `is_semiring_hom` instance from a `mul_equiv` of semirings that preserves addition. -/
protected lemma to_semiring_hom {R : Type*} {S : Type*} [semiring R] [semiring S]
  (h : R ≃+ S) (H : ∀ x y : R, h (x * y) = h x * h y) : is_semiring_hom h :=
⟨h.map_zero, mul_equiv.map_one $ mul_equiv.mk' h.to_equiv H, h.5, H⟩

end add_equiv

namespace ring_equiv

section ring_hom

variables [ring α] [ring β]

/-- Interpret an equivalence `f : α ≃ β` as a ring equivalence `α ≃+* β`. -/
def of' (e : α ≃ β) [is_ring_hom e] : α ≃+* β :=
{ .. e, .. monoid_hom.of e, .. add_monoid_hom.of e }

instance (e : α ≃+* β) : is_ring_hom e := e.to_ring_hom.is_ring_hom

end ring_hom

/-- Two ring isomorphisms agree if they are defined by the
    same underlying function. -/
@[ext] lemma ext {R S : Type*} [has_mul R] [has_add R] [has_mul S] [has_add S]
  {f g : R ≃+* S} (h : ∀ x, f x = g x) : f = g :=
begin
  have h₁ := equiv.ext f.to_equiv g.to_equiv h,
  cases f, cases g, congr,
  { exact (funext h) },
  { exact congr_arg equiv.inv_fun h₁ }
end

end ring_equiv

/-- The group of ring automorphisms. -/
def ring_aut (R : Type u) [has_mul R] [has_add R] := ring_equiv R R

namespace ring_aut

variables (R : Type u) [has_mul R] [has_add R]

/--
The group operation on automorphisms of a ring is defined by
λ g h, ring_equiv.trans h g.
This means that multiplication agrees with composition, (g*h)(x) = g (h x) .
-/
instance : group (ring_aut R) :=
by refine_struct
{ mul := λ g h, ring_equiv.trans h g,
  one := ring_equiv.refl R,
  inv := ring_equiv.symm };
intros; ext; try { refl }; apply equiv.left_inv

instance : inhabited (ring_aut R) := ⟨1⟩

/-- Monoid homomorphism from ring automorphisms to additive automorphisms. -/
def to_add_aut : ring_aut R →* add_aut R :=
by refine_struct { to_fun := ring_equiv.to_add_equiv }; intros; refl

/-- Monoid homomorphism from ring automorphisms to multiplicative automorphisms. -/
def to_mul_aut : ring_aut R →* mul_aut R :=
by refine_struct { to_fun := ring_equiv.to_mul_equiv }; intros; refl

/-- Monoid homomorphism from ring automorphisms to permutations. -/
def to_perm : ring_aut R →* equiv.perm R :=
by refine_struct { to_fun := ring_equiv.to_equiv }; intros; refl

end ring_aut
