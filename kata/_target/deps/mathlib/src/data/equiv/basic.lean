/-
Copyright (c) 2015 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Leonardo de Moura, Mario Carneiro

In the standard library we cannot assume the univalence axiom.
We say two types are equivalent if they are isomorphic.

Two equivalent types have the same cardinality.
-/
import tactic.split_ifs logic.function logic.unique data.set.function data.bool data.quot

open function

universes u v w
variables {α : Sort u} {β : Sort v} {γ : Sort w}

/-- `α ≃ β` is the type of functions from `α → β` with a two-sided inverse. -/
structure equiv (α : Sort*) (β : Sort*) :=
(to_fun    : α → β)
(inv_fun   : β → α)
(left_inv  : left_inverse inv_fun to_fun)
(right_inv : right_inverse inv_fun to_fun)

infix ` ≃ `:25 := equiv

def function.involutive.to_equiv {f : α → α} (h : involutive f) : α ≃ α :=
⟨f, f, h.left_inverse, h.right_inverse⟩

namespace equiv

/-- `perm α` is the type of bijections from `α` to itself. -/
@[reducible] def perm (α : Sort*) := equiv α α

instance : has_coe_to_fun (α ≃ β) :=
⟨_, to_fun⟩

@[simp] theorem coe_fn_mk (f : α → β) (g l r) : (equiv.mk f g l r : α → β) = f :=
rfl

theorem eq_of_to_fun_eq : ∀ {e₁ e₂ : equiv α β}, (e₁ : α → β) = e₂ → e₁ = e₂
| ⟨f₁, g₁, l₁, r₁⟩ ⟨f₂, g₂, l₂, r₂⟩ h :=
  have f₁ = f₂, from h,
  have g₁ = g₂, from funext $ assume x,
    have f₁ (g₁ x) = f₂ (g₂ x), from (r₁ x).trans (r₂ x).symm,
    have f₁ (g₁ x) = f₁ (g₂ x), by { subst f₂, exact this },
    show g₁ x = g₂ x,           from injective_of_left_inverse l₁ this,
  by simp *

@[ext] lemma ext (f g : equiv α β) (H : ∀ x, f x = g x) : f = g :=
eq_of_to_fun_eq (funext H)

@[ext] lemma perm.ext (σ τ : equiv.perm α) (H : ∀ x, σ x = τ x) : σ = τ :=
equiv.ext _ _ H

@[refl] protected def refl (α : Sort*) : α ≃ α := ⟨id, id, λ x, rfl, λ x, rfl⟩

@[symm] protected def symm (e : α ≃ β) : β ≃ α := ⟨e.inv_fun, e.to_fun, e.right_inv, e.left_inv⟩

@[trans] protected def trans (e₁ : α ≃ β) (e₂ : β ≃ γ) : α ≃ γ :=
⟨e₂.to_fun ∘ e₁.to_fun, e₁.inv_fun ∘ e₂.inv_fun,
  e₂.left_inv.comp e₁.left_inv, e₂.right_inv.comp e₁.right_inv⟩

protected theorem injective : ∀ f : α ≃ β, injective f
| ⟨f, g, h₁, h₂⟩ := injective_of_left_inverse h₁

protected theorem surjective : ∀ f : α ≃ β, surjective f
| ⟨f, g, h₁, h₂⟩ := surjective_of_has_right_inverse ⟨_, h₂⟩

protected theorem bijective (f : α ≃ β) : bijective f :=
⟨f.injective, f.surjective⟩

@[simp] lemma range_eq_univ {α : Type*} {β : Type*} (e : α ≃ β) : set.range e = set.univ :=
set.eq_univ_of_forall e.surjective

protected theorem subsingleton (e : α ≃ β) : ∀ [subsingleton β], subsingleton α
| ⟨H⟩ := ⟨λ a b, e.injective (H _ _)⟩

protected def decidable_eq (e : α ≃ β) [H : decidable_eq β] : decidable_eq α
| a b := decidable_of_iff _ e.injective.eq_iff

lemma nonempty_iff_nonempty : α ≃ β → (nonempty α ↔ nonempty β)
| ⟨f, g, _, _⟩ := nonempty.congr f g

protected def cast {α β : Sort*} (h : α = β) : α ≃ β :=
⟨cast h, cast h.symm, λ x, by { cases h, refl }, λ x, by { cases h, refl }⟩

@[simp] theorem coe_fn_symm_mk (f : α → β) (g l r) : ((equiv.mk f g l r).symm : β → α) = g :=
rfl

@[simp] theorem refl_apply (x : α) : equiv.refl α x = x := rfl

@[simp] theorem trans_apply (f : α ≃ β) (g : β ≃ γ) (a : α) : (f.trans g) a = g (f a) := rfl

@[simp] theorem apply_symm_apply : ∀ (e : α ≃ β) (x : β), e (e.symm x) = x
| ⟨f₁, g₁, l₁, r₁⟩ x := by { simp [equiv.symm], rw r₁ }

@[simp] theorem symm_apply_apply : ∀ (e : α ≃ β) (x : α), e.symm (e x) = x
| ⟨f₁, g₁, l₁, r₁⟩ x := by { simp [equiv.symm], rw l₁ }

@[simp] lemma symm_trans_apply (f : α ≃ β) (g : β ≃ γ) (a : γ) :
  (f.trans g).symm a = f.symm (g.symm a) := rfl

@[simp] theorem apply_eq_iff_eq : ∀ (f : α ≃ β) (x y : α), f x = f y ↔ x = y
| ⟨f₁, g₁, l₁, r₁⟩ x y := (injective_of_left_inverse l₁).eq_iff

@[simp] theorem cast_apply {α β} (h : α = β) (x : α) : equiv.cast h x = cast h x := rfl

lemma symm_apply_eq {α β} (e : α ≃ β) {x y} : e.symm x = y ↔ x = e y :=
⟨λ H, by simp [H.symm], λ H, by simp [H]⟩

lemma eq_symm_apply {α β} (e : α ≃ β) {x y} : y = e.symm x ↔ e y = x :=
(eq_comm.trans e.symm_apply_eq).trans eq_comm

@[simp] theorem symm_symm (e : α ≃ β) : e.symm.symm = e := by { cases e, refl }

@[simp] theorem symm_symm_apply (e : α ≃ β) (a : α) : e.symm.symm a = e a := by { cases e, refl }

@[simp] theorem trans_refl (e : α ≃ β) : e.trans (equiv.refl β) = e := by { cases e, refl }

@[simp] theorem refl_symm : (equiv.refl α).symm = equiv.refl α := rfl

@[simp] theorem refl_trans (e : α ≃ β) : (equiv.refl α).trans e = e := by { cases e, refl }

@[simp] theorem symm_trans (e : α ≃ β) : e.symm.trans e = equiv.refl β :=  ext _ _ (by simp)

@[simp] theorem trans_symm (e : α ≃ β) : e.trans e.symm = equiv.refl α := ext _ _ (by simp)

lemma trans_assoc {δ} (ab : α ≃ β) (bc : β ≃ γ) (cd : γ ≃ δ) :
  (ab.trans bc).trans cd = ab.trans (bc.trans cd) :=
equiv.ext _ _ $ assume a, rfl

theorem left_inverse_symm (f : equiv α β) : left_inverse f.symm f := f.left_inv

theorem right_inverse_symm (f : equiv α β) : function.right_inverse f.symm f := f.right_inv

def equiv_congr {δ} (ab : α ≃ β) (cd : γ ≃ δ) : (α ≃ γ) ≃ (β ≃ δ) :=
⟨ λac, (ab.symm.trans ac).trans cd, λbd, ab.trans $ bd.trans $ cd.symm,
  assume ac, begin simp [trans_assoc], rw [← trans_assoc], simp end,
  assume ac, begin simp [trans_assoc], rw [← trans_assoc], simp end, ⟩

def perm_congr {α : Type*} {β : Type*} (e : α ≃ β) : perm α ≃ perm β :=
equiv_congr e e

protected lemma image_eq_preimage {α β} (e : α ≃ β) (s : set α) : e '' s = e.symm ⁻¹' s :=
set.ext $ assume x, set.mem_image_iff_of_inverse e.left_inv e.right_inv

protected lemma subset_image {α β} (e : α ≃ β) (s : set α) (t : set β) : t ⊆ e '' s ↔ e.symm '' t ⊆ s :=
by rw [set.image_subset_iff, e.image_eq_preimage]

lemma symm_image_image {α β} (f : equiv α β) (s : set α) : f.symm '' (f '' s) = s :=
by { rw [← set.image_comp], simp }

protected lemma image_compl {α β} (f : equiv α β) (s : set α) :
  f '' -s = -(f '' s) :=
set.image_compl_eq f.bijective

/- The group of permutations (self-equivalences) of a type `α` -/

namespace perm

instance perm_group {α : Type u} : group (perm α) :=
begin
  refine { mul := λ f g, equiv.trans g f, one := equiv.refl α, inv:= equiv.symm, ..};
  intros; apply equiv.ext; try { apply trans_apply },
  apply symm_apply_apply
end

@[simp] theorem mul_apply {α : Type u} (f g : perm α) (x) : (f * g) x = f (g x) :=
equiv.trans_apply _ _ _

@[simp] theorem one_apply {α : Type u} (x) : (1 : perm α) x = x := rfl

@[simp] lemma inv_apply_self {α : Type u} (f : perm α) (x) :
  f⁻¹ (f x) = x := equiv.symm_apply_apply _ _

@[simp] lemma apply_inv_self {α : Type u} (f : perm α) (x) :
  f (f⁻¹ x) = x := equiv.apply_symm_apply _ _

lemma one_def {α : Type u} : (1 : perm α) = equiv.refl α := rfl

lemma mul_def {α : Type u} (f g : perm α) : f * g = g.trans f := rfl

lemma inv_def {α : Type u} (f : perm α) : f⁻¹ = f.symm := rfl

end perm

def equiv_empty (h : α → false) : α ≃ empty :=
⟨λ x, (h x).elim, λ e, e.rec _, λ x, (h x).elim, λ e, e.rec _⟩

def false_equiv_empty : false ≃ empty :=
equiv_empty _root_.id

def equiv_pempty (h : α → false) : α ≃ pempty :=
⟨λ x, (h x).elim, λ e, e.rec _, λ x, (h x).elim, λ e, e.rec _⟩

def false_equiv_pempty : false ≃ pempty :=
equiv_pempty _root_.id

def empty_equiv_pempty : empty ≃ pempty :=
equiv_pempty $ empty.rec _

def pempty_equiv_pempty : pempty.{v} ≃ pempty.{w} :=
equiv_pempty pempty.elim

def empty_of_not_nonempty {α : Sort*} (h : ¬ nonempty α) : α ≃ empty :=
equiv_empty $ assume a, h ⟨a⟩

def pempty_of_not_nonempty {α : Sort*} (h : ¬ nonempty α) : α ≃ pempty :=
equiv_pempty $ assume a, h ⟨a⟩

def prop_equiv_punit {p : Prop} (h : p) : p ≃ punit :=
⟨λ x, (), λ x, h, λ _, rfl, λ ⟨⟩, rfl⟩

def true_equiv_punit : true ≃ punit := prop_equiv_punit trivial

protected def ulift {α : Type u} : ulift α ≃ α :=
⟨ulift.down, ulift.up, ulift.up_down, λ a, rfl⟩

protected def plift : plift α ≃ α :=
⟨plift.down, plift.up, plift.up_down, plift.down_up⟩

@[congr] def arrow_congr {α₁ β₁ α₂ β₂ : Sort*} (e₁ : α₁ ≃ α₂) (e₂ : β₁ ≃ β₂) :
  (α₁ → β₁) ≃ (α₂ → β₂) :=
{ to_fun := λ f, e₂.to_fun ∘ f ∘ e₁.inv_fun,
  inv_fun := λ f, e₂.inv_fun ∘ f ∘ e₁.to_fun,
  left_inv := λ f, funext $ λ x, by { dsimp, rw [e₂.left_inv, e₁.left_inv] },
  right_inv := λ f, funext $ λ x, by { dsimp, rw [e₂.right_inv, e₁.right_inv] } }

@[simp] lemma arrow_congr_apply {α₁ β₁ α₂ β₂ : Sort*} (e₁ : α₁ ≃ α₂) (e₂ : β₁ ≃ β₂)
  (f : α₁ → β₁) (x : α₂) :
  arrow_congr e₁ e₂ f x = (e₂ $ f $ e₁.symm x) :=
rfl

lemma arrow_congr_comp {α₁ β₁ γ₁ α₂ β₂ γ₂ : Sort*}
  (ea : α₁ ≃ α₂) (eb : β₁ ≃ β₂) (ec : γ₁ ≃ γ₂) (f : α₁ → β₁) (g : β₁ → γ₁) :
  arrow_congr ea ec (g ∘ f) = (arrow_congr eb ec g) ∘ (arrow_congr ea eb f) :=
by { ext, simp only [comp, arrow_congr_apply, eb.symm_apply_apply] }

@[simp] lemma arrow_congr_refl {α β : Sort*} :
  arrow_congr (equiv.refl α) (equiv.refl β) = equiv.refl (α → β) := rfl

@[simp] lemma arrow_congr_trans {α₁ β₁ α₂ β₂ α₃ β₃ : Sort*}
  (e₁ : α₁ ≃ α₂) (e₁' : β₁ ≃ β₂) (e₂ : α₂ ≃ α₃) (e₂' : β₂ ≃ β₃) :
  arrow_congr (e₁.trans e₂) (e₁'.trans e₂') = (arrow_congr e₁ e₁').trans (arrow_congr e₂ e₂') :=
rfl

@[simp] lemma arrow_congr_symm {α₁ β₁ α₂ β₂ : Sort*} (e₁ : α₁ ≃ α₂) (e₂ : β₁ ≃ β₂) :
  (arrow_congr e₁ e₂).symm = arrow_congr e₁.symm e₂.symm :=
rfl

def conj (e : α ≃ β) : (α → α) ≃ (β → β) := arrow_congr e e

@[simp] lemma conj_apply (e : α ≃ β) (f : α → α) (x : β) :
  e.conj f x = (e $ f $ e.symm x) :=
rfl

@[simp] lemma conj_refl : conj (equiv.refl α) = equiv.refl (α → α) := rfl

@[simp] lemma conj_symm (e : α ≃ β) : e.conj.symm = e.symm.conj := rfl

@[simp] lemma conj_trans (e₁ : α ≃ β) (e₂ : β ≃ γ) :
  (e₁.trans e₂).conj = e₁.conj.trans e₂.conj :=
rfl

@[simp] lemma conj_comp (e : α ≃ β) (f₁ f₂ : α → α) :
  e.conj (f₁ ∘ f₂) = (e.conj f₁) ∘ (e.conj f₂) :=
by apply arrow_congr_comp

def punit_equiv_punit : punit.{v} ≃ punit.{w} :=
⟨λ _, punit.star, λ _, punit.star, λ u, by { cases u, refl }, λ u, by { cases u, reflexivity }⟩

section
@[simp] def arrow_punit_equiv_punit (α : Sort*) : (α → punit.{v}) ≃ punit.{w} :=
⟨λ f, punit.star, λ u f, punit.star,
  λ f, by { funext x, cases f x, refl }, λ u, by { cases u, reflexivity }⟩

@[simp] def punit_arrow_equiv (α : Sort*) : (punit.{u} → α) ≃ α :=
⟨λ f, f punit.star, λ a u, a, λ f, by { funext x, cases x, refl }, λ u, rfl⟩

@[simp] def empty_arrow_equiv_punit (α : Sort*) : (empty → α) ≃ punit.{u} :=
⟨λ f, punit.star, λ u e, e.rec _, λ f, funext $ λ x, x.rec _, λ u, by { cases u, refl }⟩

@[simp] def pempty_arrow_equiv_punit (α : Sort*) : (pempty → α) ≃ punit.{u} :=
⟨λ f, punit.star, λ u e, e.rec _, λ f, funext $ λ x, x.rec _, λ u, by { cases u, refl }⟩

@[simp] def false_arrow_equiv_punit (α : Sort*) : (false → α) ≃ punit.{u} :=
calc (false → α) ≃ (empty → α) : arrow_congr false_equiv_empty (equiv.refl _)
             ... ≃ punit       : empty_arrow_equiv_punit _

end

@[congr] def prod_congr {α₁ β₁ α₂ β₂ : Sort*} (e₁ : α₁ ≃ α₂) (e₂ :β₁ ≃ β₂) : α₁ × β₁ ≃ α₂ × β₂ :=
⟨λp, (e₁ p.1, e₂ p.2), λp, (e₁.symm p.1, e₂.symm p.2),
   λ ⟨a, b⟩, show (e₁.symm (e₁ a), e₂.symm (e₂ b)) = (a, b), by rw [symm_apply_apply, symm_apply_apply],
   λ ⟨a, b⟩, show (e₁ (e₁.symm a), e₂ (e₂.symm b)) = (a, b), by rw [apply_symm_apply, apply_symm_apply]⟩

@[simp] theorem prod_congr_apply {α₁ β₁ α₂ β₂ : Sort*} (e₁ : α₁ ≃ α₂) (e₂ : β₁ ≃ β₂) (a : α₁) (b : β₁) :
  prod_congr e₁ e₂ (a, b) = (e₁ a, e₂ b) :=
rfl

@[simp] def prod_comm (α β : Sort*) : α × β ≃ β × α :=
⟨λ p, (p.2, p.1), λ p, (p.2, p.1), λ⟨a, b⟩, rfl, λ⟨a, b⟩, rfl⟩

@[simp] def prod_assoc (α β γ : Sort*) : (α × β) × γ ≃ α × (β × γ) :=
⟨λ p, ⟨p.1.1, ⟨p.1.2, p.2⟩⟩, λp, ⟨⟨p.1, p.2.1⟩, p.2.2⟩, λ ⟨⟨a, b⟩, c⟩, rfl, λ ⟨a, ⟨b, c⟩⟩, rfl⟩

@[simp] theorem prod_assoc_apply {α β γ : Sort*} (p : (α × β) × γ) :
  prod_assoc α β γ p = ⟨p.1.1, ⟨p.1.2, p.2⟩⟩ := rfl

section
@[simp] def prod_punit (α : Sort*) : α × punit.{u+1} ≃ α :=
⟨λ p, p.1, λ a, (a, punit.star), λ ⟨_, punit.star⟩, rfl, λ a, rfl⟩

@[simp] theorem prod_punit_apply {α : Sort*} (a : α × punit.{u+1}) : prod_punit α a = a.1 := rfl

@[simp] def punit_prod (α : Sort*) : punit.{u+1} × α ≃ α :=
calc punit × α ≃ α × punit : prod_comm _ _
           ... ≃ α         : prod_punit _

@[simp] theorem punit_prod_apply {α : Sort*} (a : punit.{u+1} × α) : punit_prod α a = a.2 := rfl

@[simp] def prod_empty (α : Sort*) : α × empty ≃ empty :=
equiv_empty (λ ⟨_, e⟩, e.rec _)

@[simp] def empty_prod (α : Sort*) : empty × α ≃ empty :=
equiv_empty (λ ⟨e, _⟩, e.rec _)

@[simp] def prod_pempty (α : Sort*) : α × pempty ≃ pempty :=
equiv_pempty (λ ⟨_, e⟩, e.rec _)

@[simp] def pempty_prod (α : Sort*) : pempty × α ≃ pempty :=
equiv_pempty (λ ⟨e, _⟩, e.rec _)
end

section
open sum
def psum_equiv_sum (α β : Sort*) : psum α β ≃ α ⊕ β :=
⟨λ s, psum.cases_on s inl inr,
 λ s, sum.cases_on s psum.inl psum.inr,
 λ s, by cases s; refl,
 λ s, by cases s; refl⟩

def sum_congr {α₁ β₁ α₂ β₂ : Sort*} : α₁ ≃ α₂ → β₁ ≃ β₂ → α₁ ⊕ β₁ ≃ α₂ ⊕ β₂
| ⟨f₁, g₁, l₁, r₁⟩ ⟨f₂, g₂, l₂, r₂⟩ :=
  ⟨λ s, match s with inl a₁ := inl (f₁ a₁) | inr b₁ := inr (f₂ b₁) end,
   λ s, match s with inl a₂ := inl (g₁ a₂) | inr b₂ := inr (g₂ b₂) end,
   λ s, match s with inl a := congr_arg inl (l₁ a) | inr a := congr_arg inr (l₂ a) end,
   λ s, match s with inl a := congr_arg inl (r₁ a) | inr a := congr_arg inr (r₂ a) end⟩

@[simp] theorem sum_congr_apply_inl {α₁ β₁ α₂ β₂ : Sort*} (e₁ : α₁ ≃ α₂) (e₂ : β₁ ≃ β₂) (a : α₁) :
  sum_congr e₁ e₂ (inl a) = inl (e₁ a) :=
by { cases e₁, cases e₂, refl }

@[simp] theorem sum_congr_apply_inr {α₁ β₁ α₂ β₂ : Sort*} (e₁ : α₁ ≃ α₂) (e₂ : β₁ ≃ β₂) (b : β₁) :
  sum_congr e₁ e₂ (inr b) = inr (e₂ b) :=
by { cases e₁, cases e₂, refl }

@[simp] lemma sum_congr_symm {α β γ δ : Type u} (e : α ≃ β) (f : γ ≃ δ) (x) :
  (equiv.sum_congr e f).symm x = (equiv.sum_congr (e.symm) (f.symm)) x :=
by { cases e, cases f, cases x; refl }

def bool_equiv_punit_sum_punit : bool ≃ punit.{u+1} ⊕ punit.{v+1} :=
⟨λ b, cond b (inr punit.star) (inl punit.star),
 λ s, sum.rec_on s (λ_, ff) (λ_, tt),
 λ b, by cases b; refl,
 λ s, by rcases s with ⟨⟨⟩⟩ | ⟨⟨⟩⟩; refl⟩

noncomputable def Prop_equiv_bool : Prop ≃ bool :=
⟨λ p, @to_bool p (classical.prop_decidable _),
 λ b, b, λ p, by simp, λ b, by simp⟩

@[simp] def sum_comm (α β : Sort*) : α ⊕ β ≃ β ⊕ α :=
⟨λ s, match s with inl a := inr a | inr b := inl b end,
 λ s, match s with inl b := inr b | inr a := inl a end,
 λ s, by cases s; refl,
 λ s, by cases s; refl⟩

@[simp] def sum_assoc (α β γ : Sort*) : (α ⊕ β) ⊕ γ ≃ α ⊕ (β ⊕ γ) :=
⟨λ s, match s with inl (inl a) := inl a | inl (inr b) := inr (inl b) | inr c := inr (inr c) end,
 λ s, match s with inl a := inl (inl a) | inr (inl b) := inl (inr b) | inr (inr c) := inr c end,
 λ s, by rcases s with ⟨_ | _⟩ | _; refl,
 λ s, by rcases s with _ | _ | _; refl⟩

@[simp] theorem sum_assoc_apply_in1 {α β γ} (a) : sum_assoc α β γ (inl (inl a)) = inl a := rfl
@[simp] theorem sum_assoc_apply_in2 {α β γ} (b) : sum_assoc α β γ (inl (inr b)) = inr (inl b) := rfl
@[simp] theorem sum_assoc_apply_in3 {α β γ} (c) : sum_assoc α β γ (inr c) = inr (inr c) := rfl

@[simp] def sum_empty (α : Sort*) : α ⊕ empty ≃ α :=
⟨λ s, match s with inl a := a | inr e := empty.rec _ e end,
 inl,
 λ s, by { rcases s with _ | ⟨⟨⟩⟩, refl },
 λ a, rfl⟩

@[simp] def empty_sum (α : Sort*) : empty ⊕ α ≃ α :=
(sum_comm _ _).trans $ sum_empty _

@[simp] def sum_pempty (α : Sort*) : α ⊕ pempty ≃ α :=
⟨λ s, match s with inl a := a | inr e := pempty.rec _ e end,
 inl,
 λ s, by { rcases s with _ | ⟨⟨⟩⟩, refl },
 λ a, rfl⟩

@[simp] def pempty_sum (α : Sort*) : pempty ⊕ α ≃ α :=
(sum_comm _ _).trans $ sum_pempty _

@[simp] def option_equiv_sum_punit (α : Sort*) : option α ≃ α ⊕ punit.{u+1} :=
⟨λ o, match o with none := inr punit.star | some a := inl a end,
 λ s, match s with inr _ := none | inl a := some a end,
 λ o, by cases o; refl,
 λ s, by rcases s with _ | ⟨⟨⟩⟩; refl⟩

def sum_equiv_sigma_bool (α β : Sort*) : α ⊕ β ≃ (Σ b: bool, cond b α β) :=
⟨λ s, match s with inl a := ⟨tt, a⟩ | inr b := ⟨ff, b⟩ end,
 λ s, match s with ⟨tt, a⟩ := inl a | ⟨ff, b⟩ := inr b end,
 λ s, by cases s; refl,
 λ s, by rcases s with ⟨_|_, _⟩; refl⟩

def sigma_preimage_equiv {α β : Type*} (f : α → β) :
  (Σ y : β, {x // f x = y}) ≃ α :=
⟨λ x, x.2.1, λ x, ⟨f x, x, rfl⟩, λ ⟨y, x, rfl⟩, rfl, λ x, rfl⟩

end

section

def Pi_congr_right {α} {β₁ β₂ : α → Sort*} (F : ∀ a, β₁ a ≃ β₂ a) : (Π a, β₁ a) ≃ (Π a, β₂ a) :=
⟨λ H a, F a (H a), λ H a, (F a).symm (H a),
 λ H, funext $ by simp, λ H, funext $ by simp⟩

def Pi_curry {α} {β : α → Sort*} (γ : Π a, β a → Sort*) : (Π x : sigma β, γ x.1 x.2) ≃ (Π a b, γ a b) :=
{ to_fun := λ f x y, f ⟨x,y⟩,
  inv_fun := λ f x, f x.1 x.2,
  left_inv := λ f, funext $ λ ⟨x,y⟩, rfl,
  right_inv := λ f, funext $ λ x, funext $ λ y, rfl }

end

section
def psigma_equiv_sigma {α} (β : α → Sort*) : psigma β ≃ sigma β :=
⟨λ ⟨a, b⟩, ⟨a, b⟩, λ ⟨a, b⟩, ⟨a, b⟩, λ ⟨a, b⟩, rfl, λ ⟨a, b⟩, rfl⟩

def sigma_congr_right {α} {β₁ β₂ : α → Sort*} (F : ∀ a, β₁ a ≃ β₂ a) : sigma β₁ ≃ sigma β₂ :=
⟨λ ⟨a, b⟩, ⟨a, F a b⟩, λ ⟨a, b⟩, ⟨a, (F a).symm b⟩,
 λ ⟨a, b⟩, congr_arg (sigma.mk a) $ symm_apply_apply (F a) b,
 λ ⟨a, b⟩, congr_arg (sigma.mk a) $ apply_symm_apply (F a) b⟩

def sigma_congr_left {α₁ α₂} {β : α₂ → Sort*} : ∀ f : α₁ ≃ α₂, (Σ a:α₁, β (f a)) ≃ (Σ a:α₂, β a)
| ⟨f, g, l, r⟩ :=
  ⟨λ ⟨a, b⟩, ⟨f a, b⟩, λ ⟨a, b⟩, ⟨g a, @@eq.rec β b (r a).symm⟩,
   λ ⟨a, b⟩, match g (f a), l a : ∀ a' (h : a' = a),
       @sigma.mk _ (β ∘ f) _ (@@eq.rec β b (congr_arg f h.symm)) = ⟨a, b⟩ with
     | _, rfl := rfl end,
   λ ⟨a, b⟩, match f (g a), _ : ∀ a' (h : a' = a), sigma.mk a' (@@eq.rec β b h.symm) = ⟨a, b⟩ with
     | _, rfl := rfl end⟩

def sigma_equiv_prod (α β : Sort*) : (Σ_:α, β) ≃ α × β :=
⟨λ ⟨a, b⟩, ⟨a, b⟩, λ ⟨a, b⟩, ⟨a, b⟩, λ ⟨a, b⟩, rfl, λ ⟨a, b⟩, rfl⟩

def sigma_equiv_prod_of_equiv {α β} {β₁ : α → Sort*} (F : ∀ a, β₁ a ≃ β) : sigma β₁ ≃ α × β :=
(sigma_congr_right F).trans (sigma_equiv_prod α β)

end

section
def arrow_prod_equiv_prod_arrow (α β γ : Type*) : (γ → α × β) ≃ (γ → α) × (γ → β) :=
⟨λ f, (λ c, (f c).1, λ c, (f c).2),
 λ p c, (p.1 c, p.2 c),
 λ f, funext $ λ c, prod.mk.eta,
 λ p, by { cases p, refl }⟩

def arrow_arrow_equiv_prod_arrow (α β γ : Sort*) : (α → β → γ) ≃ (α × β → γ) :=
⟨λ f, λ p, f p.1 p.2,
 λ f, λ a b, f (a, b),
 λ f, rfl,
 λ f, by { funext p, cases p, refl }⟩

open sum
def sum_arrow_equiv_prod_arrow (α β γ : Type*) : ((α ⊕ β) → γ) ≃ (α → γ) × (β → γ) :=
⟨λ f, (f ∘ inl, f ∘ inr),
 λ p s, sum.rec_on s p.1 p.2,
 λ f, by { funext s, cases s; refl },
 λ p, by { cases p, refl }⟩

def sum_prod_distrib (α β γ : Sort*) : (α ⊕ β) × γ ≃ (α × γ) ⊕ (β × γ) :=
⟨λ p, match p with (inl a, c) := inl (a, c) | (inr b, c) := inr (b, c) end,
 λ s, match s with inl (a, c) := (inl a, c) | inr (b, c) := (inr b, c) end,
 λ p, by rcases p with ⟨_ | _, _⟩; refl,
 λ s, by rcases s with ⟨_, _⟩ | ⟨_, _⟩; refl⟩

@[simp] theorem sum_prod_distrib_apply_left {α β γ} (a : α) (c : γ) :
   sum_prod_distrib α β γ (sum.inl a, c) = sum.inl (a, c) := rfl
@[simp] theorem sum_prod_distrib_apply_right {α β γ} (b : β) (c : γ) :
   sum_prod_distrib α β γ (sum.inr b, c) = sum.inr (b, c) := rfl

def prod_sum_distrib (α β γ : Sort*) : α × (β ⊕ γ) ≃ (α × β) ⊕ (α × γ) :=
calc α × (β ⊕ γ) ≃ (β ⊕ γ) × α       : prod_comm _ _
            ...   ≃ (β × α) ⊕ (γ × α) : sum_prod_distrib _ _ _
            ...   ≃ (α × β) ⊕ (α × γ) : sum_congr (prod_comm _ _) (prod_comm _ _)

@[simp] theorem prod_sum_distrib_apply_left {α β γ} (a : α) (b : β) :
   prod_sum_distrib α β γ (a, sum.inl b) = sum.inl (a, b) := rfl
@[simp] theorem prod_sum_distrib_apply_right {α β γ} (a : α) (c : γ) :
   prod_sum_distrib α β γ (a, sum.inr c) = sum.inr (a, c) := rfl

def sigma_prod_distrib {ι : Type*} (α : ι → Type*) (β : Type*) :
  ((Σ i, α i) × β) ≃ (Σ i, (α i × β)) :=
⟨λ p, ⟨p.1.1, (p.1.2, p.2)⟩,
 λ p, (⟨p.1, p.2.1⟩, p.2.2),
 λ p, by { rcases p with ⟨⟨_, _⟩, _⟩, refl },
 λ p, by { rcases p with ⟨_, ⟨_, _⟩⟩, refl }⟩

def bool_prod_equiv_sum (α : Type u) : bool × α ≃ α ⊕ α :=
calc bool × α ≃ (unit ⊕ unit) × α       : prod_congr bool_equiv_punit_sum_punit (equiv.refl _)
      ...     ≃ α × (unit ⊕ unit)       : prod_comm _ _
      ...     ≃ (α × unit) ⊕ (α × unit) : prod_sum_distrib _ _ _
      ...     ≃ α ⊕ α                   : sum_congr (prod_punit _) (prod_punit _)
end

section
open sum nat
def nat_equiv_nat_sum_punit : ℕ ≃ ℕ ⊕ punit.{u+1} :=
⟨λ n, match n with zero := inr punit.star | succ a := inl a end,
 λ s, match s with inl n := succ n | inr punit.star := zero end,
 λ n, begin cases n, repeat { refl } end,
 λ s, begin cases s with a u, { refl }, {cases u, { refl }} end⟩

@[simp] def nat_sum_punit_equiv_nat : ℕ ⊕ punit.{u+1} ≃ ℕ :=
nat_equiv_nat_sum_punit.symm

def int_equiv_nat_sum_nat : ℤ ≃ ℕ ⊕ ℕ :=
by refine ⟨_, _, _, _⟩; intro z; {cases z; [left, right]; assumption} <|> {cases z; refl}

end

def list_equiv_of_equiv {α β : Type*} : α ≃ β → list α ≃ list β
| ⟨f, g, l, r⟩ :=
  by refine ⟨list.map f, list.map g, λ x, _, λ x, _⟩;
     simp [id_of_left_inverse l, id_of_right_inverse r]

def fin_equiv_subtype (n : ℕ) : fin n ≃ {m // m < n} :=
⟨λ x, ⟨x.1, x.2⟩, λ x, ⟨x.1, x.2⟩, λ ⟨a, b⟩, rfl,λ ⟨a, b⟩, rfl⟩

def decidable_eq_of_equiv [decidable_eq β] (e : α ≃ β) : decidable_eq α
| a₁ a₂ := decidable_of_iff (e a₁ = e a₂) e.injective.eq_iff

def inhabited_of_equiv [inhabited β] (e : α ≃ β) : inhabited α :=
⟨e.symm (default _)⟩

def unique_of_equiv (e : α ≃ β) (h : unique β) : unique α :=
unique.of_surjective e.symm.surjective

def unique_congr (e : α ≃ β) : unique α ≃ unique β :=
{ to_fun := e.symm.unique_of_equiv,
  inv_fun := e.unique_of_equiv,
  left_inv := λ _, subsingleton.elim _ _,
  right_inv := λ _, subsingleton.elim _ _ }

section
open subtype

def subtype_congr {p : α → Prop} {q : β → Prop}
  (e : α ≃ β) (h : ∀ a, p a ↔ q (e a)) : {a : α // p a} ≃ {b : β // q b} :=
⟨λ x, ⟨e x.1, (h _).1 x.2⟩,
 λ y, ⟨e.symm y.1, (h _).2 (by { simp, exact y.2 })⟩,
 λ ⟨x, h⟩, subtype.eq' $ by simp,
 λ ⟨y, h⟩, subtype.eq' $ by simp⟩

def subtype_congr_right {p q : α → Prop} (e : ∀x, p x ↔ q x) : subtype p ≃ subtype q :=
subtype_congr (equiv.refl _) e

@[simp] lemma subtype_congr_right_mk {p q : α → Prop} (e : ∀x, p x ↔ q x)
  {x : α} (h : p x) : subtype_congr_right e ⟨x, h⟩ = ⟨x, (e x).1 h⟩ := rfl

def subtype_equiv_of_subtype' {p : α → Prop} (e : α ≃ β) :
  {a : α // p a} ≃ {b : β // p (e.symm b)} :=
subtype_congr e $ by simp

def subtype_congr_prop {α : Type*} {p q : α → Prop} (h : p = q) : subtype p ≃ subtype q :=
subtype_congr (equiv.refl α) (assume a, h ▸ iff.rfl)

def set_congr {α : Type*} {s t : set α} (h : s = t) : s ≃ t :=
subtype_congr_prop h

def subtype_subtype_equiv_subtype_exists {α : Type u} (p : α → Prop) (q : subtype p → Prop) :
  subtype q ≃ {a : α // ∃h:p a, q ⟨a, h⟩ } :=
⟨λ⟨⟨a, ha⟩, ha'⟩, ⟨a, ha, ha'⟩,
  λ⟨a, ha⟩, ⟨⟨a, ha.cases_on $ assume h _, h⟩, by { cases ha, exact ha_h }⟩,
  assume ⟨⟨a, ha⟩, h⟩, rfl, assume ⟨a, h₁, h₂⟩, rfl⟩

def subtype_subtype_equiv_subtype_inter {α : Type u} (p q : α → Prop) :
  {x : subtype p // q x.1} ≃ subtype (λ x, p x ∧ q x) :=
(subtype_subtype_equiv_subtype_exists p _).trans $
subtype_congr_right $ λ x, exists_prop

/-- If the outer subtype has more restrictive predicate than the inner one,
then we can drop the latter. -/
def subtype_subtype_equiv_subtype {α : Type u} {p q : α → Prop} (h : ∀ {x}, q x → p x) :
  {x : subtype p // q x.1} ≃ subtype q :=
(subtype_subtype_equiv_subtype_inter p _).trans $
subtype_congr_right $
assume x,
⟨and.right, λ h₁, ⟨h h₁, h₁⟩⟩

/-- If a proposition holds for all elements, then the subtype is
equivalent to the original type. -/
def subtype_univ_equiv {α : Type u} {p : α → Prop} (h : ∀ x, p x) :
  subtype p ≃ α :=
⟨λ x, x, λ x, ⟨x, h x⟩, λ x, subtype.eq rfl, λ x, rfl⟩

/-- A subtype of a sigma-type is a sigma-type over a subtype. -/
def subtype_sigma_equiv {α : Type u} (p : α → Type v) (q : α → Prop) :
  { y : sigma p // q y.1 } ≃ Σ(x : subtype q), p x.1 :=
⟨λ x, ⟨⟨x.1.1, x.2⟩, x.1.2⟩,
 λ x, ⟨⟨x.1.1, x.2⟩, x.1.2⟩,
 λ ⟨⟨x, h⟩, y⟩, rfl,
 λ ⟨⟨x, y⟩, h⟩, rfl⟩

/-- A sigma type over a subtype is equivalent to the sigma set over the original type,
if the fiber is empty outside of the subset -/
def sigma_subtype_equiv_of_subset {α : Type u} (p : α → Type v) (q : α → Prop)
  (h : ∀ x, p x → q x) :
  (Σ x : subtype q, p x) ≃ Σ x : α, p x :=
(subtype_sigma_equiv p q).symm.trans $ subtype_univ_equiv $ λ x, h x.1 x.2

def sigma_subtype_preimage_equiv {α : Type u} {β : Type v} (f : α → β) (p : β → Prop)
  (h : ∀ x, p (f x)) :
  (Σ y : subtype p, {x : α // f x = y}) ≃ α :=
calc _ ≃ Σ y : β, {x : α // f x = y} : sigma_subtype_equiv_of_subset _ p (λ y ⟨x, h'⟩, h' ▸ h x)
   ... ≃ α                           : sigma_preimage_equiv f

def sigma_subtype_preimage_equiv_subtype {α : Type u} {β : Type v} (f : α → β)
  {p : α → Prop} {q : β → Prop} (h : ∀ x, p x ↔ q (f x)) :
  (Σ y : subtype q, {x : α // f x = y}) ≃ subtype p :=
calc (Σ y : subtype q, {x : α // f x = y}) ≃
  Σ y : subtype q, {x : subtype p // subtype.mk (f x) ((h x).1 x.2) = y} :
  begin
    apply sigma_congr_right,
    assume y,
    symmetry,
    refine (subtype_subtype_equiv_subtype_exists _ _).trans (subtype_congr_right _),
    assume x,
    exact ⟨λ ⟨hp, h'⟩, congr_arg subtype.val h', λ h', ⟨(h x).2 (h'.symm ▸ y.2), subtype.eq h'⟩⟩
  end

   ... ≃ subtype p : sigma_preimage_equiv (λ x : subtype p, (⟨f x, (h x).1 x.property⟩ : subtype q))

def pi_equiv_subtype_sigma (ι : Type*) (π : ι → Type*) :
  (Πi, π i) ≃ {f : ι → Σi, π i | ∀i, (f i).1 = i } :=
⟨ λf, ⟨λi, ⟨i, f i⟩, assume i, rfl⟩, λf i, begin rw ← f.2 i, exact (f.1 i).2 end,
  assume f, funext $ assume i, rfl,
  assume ⟨f, hf⟩, subtype.eq $ funext $ assume i, sigma.eq (hf i).symm $
    eq_of_heq $ rec_heq_of_heq _ $ rec_heq_of_heq _ $ heq.refl _⟩

def subtype_pi_equiv_pi {α : Sort u} {β : α → Sort v} {p : Πa, β a → Prop} :
  {f : Πa, β a // ∀a, p a (f a) } ≃ Πa, { b : β a // p a b } :=
⟨λf a, ⟨f.1 a, f.2 a⟩, λf, ⟨λa, (f a).1, λa, (f a).2⟩,
  by { rintro ⟨f, h⟩, refl },
  by { rintro f, funext a, exact subtype.eq' rfl }⟩

end

namespace set
open set

protected def univ (α) : @univ α ≃ α :=
⟨subtype.val, λ a, ⟨a, trivial⟩, λ ⟨a, _⟩, rfl, λ a, rfl⟩

@[simp] lemma univ_apply {α : Type u} (x : @univ α) :
  equiv.set.univ α x = x := rfl

@[simp] lemma univ_symm_apply {α : Type u} (x : α) :
  (equiv.set.univ α).symm x = ⟨x, trivial⟩ := rfl

protected def empty (α) : (∅ : set α) ≃ empty :=
equiv_empty $ λ ⟨x, h⟩, not_mem_empty x h

protected def pempty (α) : (∅ : set α) ≃ pempty :=
equiv_pempty $ λ ⟨x, h⟩, not_mem_empty x h

protected def union' {α} {s t : set α}
  (p : α → Prop) [decidable_pred p]
  (hs : ∀ x ∈ s, p x)
  (ht : ∀ x ∈ t, ¬ p x) : (s ∪ t : set α) ≃ s ⊕ t :=
{ to_fun := λ x, if hp : p x.1
    then sum.inl ⟨_, x.2.resolve_right (λ xt, ht _ xt hp)⟩
    else sum.inr ⟨_, x.2.resolve_left (λ xs, hp (hs _ xs))⟩,
  inv_fun := λ o, match o with
    | (sum.inl x) := ⟨x.1, or.inl x.2⟩
    | (sum.inr x) := ⟨x.1, or.inr x.2⟩
  end,
  left_inv := λ ⟨x, h'⟩, by by_cases p x; simp [union'._match_1, h]; congr,
  right_inv := λ o, begin
    rcases o with ⟨x, h⟩ | ⟨x, h⟩;
    dsimp [union'._match_1];
    [simp [hs _ h], simp [ht _ h]]
  end }

protected def union {α} {s t : set α} [decidable_pred s] (H : s ∩ t = ∅) :
  (s ∪ t : set α) ≃ s ⊕ t :=
set.union' s (λ _, id) (λ x xt xs, subset_empty_iff.2 H ⟨xs, xt⟩)

lemma union_apply_left {α} {s t : set α} [decidable_pred s] (H : s ∩ t = ∅)
  {a : (s ∪ t : set α)} (ha : ↑a ∈ s) : equiv.set.union H a = sum.inl ⟨a, ha⟩ :=
dif_pos ha

lemma union_apply_right {α} {s t : set α} [decidable_pred s] (H : s ∩ t = ∅)
  {a : (s ∪ t : set α)} (ha : ↑a ∈ t) : equiv.set.union H a = sum.inr ⟨a, ha⟩ :=
dif_neg (show ↑a ∉ s, by finish [set.ext_iff])

protected def singleton {α} (a : α) : ({a} : set α) ≃ punit.{u} :=
⟨λ _, punit.star, λ _, ⟨a, mem_singleton _⟩,
 λ ⟨x, h⟩, by { simp at h, subst x },
 λ ⟨⟩, rfl⟩

protected def of_eq {α : Type u} {s t : set α} (h : s = t) : s ≃ t :=
{ to_fun := λ x, ⟨x.1, h ▸ x.2⟩,
  inv_fun := λ x, ⟨x.1, h.symm ▸ x.2⟩,
  left_inv := λ _, subtype.eq rfl,
  right_inv := λ _, subtype.eq rfl }

@[simp] lemma of_eq_apply {α : Type u} {s t : set α} (h : s = t) (a : s) :
  equiv.set.of_eq h a = ⟨a, h ▸ a.2⟩ := rfl

@[simp] lemma of_eq_symm_apply {α : Type u} {s t : set α} (h : s = t) (a : t) :
  (equiv.set.of_eq h).symm a = ⟨a, h.symm ▸ a.2⟩ := rfl

protected def insert {α} {s : set.{u} α} [decidable_pred s] {a : α} (H : a ∉ s) :
  (insert a s : set α) ≃ s ⊕ punit.{u+1} :=
calc (insert a s : set α) ≃ ↥(s ∪ {a}) : equiv.set.of_eq (by simp)
... ≃ s ⊕ ({a} : set α) : equiv.set.union (by finish [set.ext_iff])
... ≃ s ⊕ punit.{u+1} : sum_congr (equiv.refl _) (equiv.set.singleton _)

protected def sum_compl {α} (s : set α) [decidable_pred s] : s ⊕ (-s : set α) ≃ α :=
calc s ⊕ (-s : set α) ≃ ↥(s ∪ -s) : (equiv.set.union (by simp [set.ext_iff])).symm
... ≃ @univ α : equiv.set.of_eq (by simp)
... ≃ α : equiv.set.univ _

@[simp] lemma sum_compl_apply_inl {α : Type u} (s : set α) [decidable_pred s] (x : s) :
  equiv.set.sum_compl s (sum.inl x) = x := rfl

@[simp] lemma sum_compl_apply_inr {α : Type u} (s : set α) [decidable_pred s] (x : -s) :
  equiv.set.sum_compl s (sum.inr x) = x := rfl

lemma sum_compl_symm_apply_of_mem {α : Type u} {s : set α} [decidable_pred s] {x : α}
  (hx : x ∈ s) : (equiv.set.sum_compl s).symm x = sum.inl ⟨x, hx⟩ :=
have ↑(⟨x, or.inl hx⟩ : (s ∪ -s : set α)) ∈ s, from hx,
by { rw [equiv.set.sum_compl], simpa using set.union_apply_left _ this }

lemma sum_compl_symm_apply_of_not_mem {α : Type u} {s : set α} [decidable_pred s] {x : α}
  (hx : x ∉ s) : (equiv.set.sum_compl s).symm x = sum.inr ⟨x, hx⟩ :=
have ↑(⟨x, or.inr hx⟩ : (s ∪ -s : set α)) ∈ -s, from hx,
by { rw [equiv.set.sum_compl], simpa using set.union_apply_right _ this }

protected def union_sum_inter {α : Type u} (s t : set α) [decidable_pred s] :
  (s ∪ t : set α) ⊕ (s ∩ t : set α) ≃ s ⊕ t :=
calc  (s ∪ t : set α) ⊕ (s ∩ t : set α)
    ≃ (s ∪ t \ s : set α) ⊕ (s ∩ t : set α) : by rw [union_diff_self]
... ≃ (s ⊕ (t \ s : set α)) ⊕ (s ∩ t : set α) :
  sum_congr (set.union (inter_diff_self _ _)) (equiv.refl _)
... ≃ s ⊕ (t \ s : set α) ⊕ (s ∩ t : set α) : sum_assoc _ _ _
... ≃ s ⊕ (t \ s ∪ s ∩ t : set α) : sum_congr (equiv.refl _) begin
    refine (set.union' (∉ s) _ _).symm,
    exacts [λ x hx, hx.2, λ x hx, not_not_intro hx.1]
  end
... ≃ s ⊕ t : by { rw (_ : t \ s ∪ s ∩ t = t), rw [union_comm, inter_comm, inter_union_diff] }

protected def prod {α β} (s : set α) (t : set β) :
  s.prod t ≃ s × t :=
⟨λp, ⟨⟨p.1.1, p.2.1⟩, ⟨p.1.2, p.2.2⟩⟩,
 λp, ⟨⟨p.1.1, p.2.1⟩, ⟨p.1.2, p.2.2⟩⟩,
 λ ⟨⟨x, y⟩, ⟨h₁, h₂⟩⟩, rfl,
 λ ⟨⟨x, h₁⟩, ⟨y, h₂⟩⟩, rfl⟩

protected noncomputable def image_of_inj_on {α β} (f : α → β) (s : set α) (H : inj_on f s) :
  s ≃ (f '' s) :=
⟨λ ⟨x, h⟩, ⟨f x, mem_image_of_mem f h⟩,
 λ ⟨y, h⟩, ⟨classical.some h, (classical.some_spec h).1⟩,
 λ ⟨x, h⟩, subtype.eq (H (classical.some_spec (mem_image_of_mem f h)).1 h
   (classical.some_spec (mem_image_of_mem f h)).2),
 λ ⟨y, h⟩, subtype.eq (classical.some_spec h).2⟩

protected noncomputable def image {α β} (f : α → β) (s : set α) (H : injective f) : s ≃ (f '' s) :=
equiv.set.image_of_inj_on f s (λ x y hx hy hxy, H hxy)

@[simp] theorem image_apply {α β} (f : α → β) (s : set α) (H : injective f) (a h) :
  set.image f s H ⟨a, h⟩ = ⟨f a, mem_image_of_mem _ h⟩ := rfl

protected noncomputable def range {α β} (f : α → β) (H : injective f) :
  α ≃ range f :=
{ to_fun := λ x, ⟨f x, mem_range_self _⟩,
  inv_fun := λ x, classical.some x.2,
  left_inv := λ x, H (classical.some_spec (show f x ∈ range f, from mem_range_self _)),
  right_inv := λ x, subtype.eq $ classical.some_spec x.2 }

@[simp] theorem range_apply {α β} (f : α → β) (H : injective f) (a) :
  set.range f H a = ⟨f a, set.mem_range_self _⟩ := rfl

protected def congr {α β : Type*} (e : α ≃ β) : set α ≃ set β :=
⟨λ s, e '' s, λ t, e.symm '' t, symm_image_image e, symm_image_image e.symm⟩

protected def sep {α : Type u} (s : set α) (t : α → Prop) :
  ({ x ∈ s | t x } : set α) ≃ { x : s | t x.1 } :=
(equiv.subtype_subtype_equiv_subtype_inter s t).symm

end set

noncomputable def of_bijective {α β} {f : α → β} (hf : bijective f) : α ≃ β :=
⟨f, λ x, classical.some (hf.2 x), λ x, hf.1 (classical.some_spec (hf.2 (f x))),
  λ x, classical.some_spec (hf.2 x)⟩

@[simp] theorem of_bijective_to_fun {α β} {f : α → β} (hf : bijective f) : (of_bijective hf : α → β) = f := rfl

def subtype_quotient_equiv_quotient_subtype (p₁ : α → Prop) [s₁ : setoid α]
  [s₂ : setoid (subtype p₁)] (p₂ : quotient s₁ → Prop) (hp₂ :  ∀ a, p₁ a ↔ p₂ ⟦a⟧)
  (h : ∀ x y : subtype p₁, @setoid.r _ s₂ x y ↔ (x : α) ≈ y) :
  {x // p₂ x} ≃ quotient s₂ :=
{ to_fun := λ a, quotient.hrec_on a.1 (λ a h, ⟦⟨a, (hp₂ _).2 h⟩⟧)
    (λ a b hab, hfunext (by rw quotient.sound hab)
    (λ h₁ h₂ _, heq_of_eq (quotient.sound ((h _ _).2 hab)))) a.2,
  inv_fun := λ a, quotient.lift_on a (λ a, (⟨⟦a.1⟧, (hp₂ _).1 a.2⟩ : {x // p₂ x}))
    (λ a b hab, subtype.eq' (quotient.sound ((h _ _).1 hab))),
  left_inv := λ ⟨a, ha⟩, quotient.induction_on a (λ a ha, rfl) ha,
  right_inv := λ a, quotient.induction_on a (λ ⟨a, ha⟩, rfl) }

section swap
variable [decidable_eq α]
open decidable

def swap_core (a b r : α) : α :=
if r = a then b
else if r = b then a
else r

theorem swap_core_self (r a : α) : swap_core a a r = r :=
by { unfold swap_core, split_ifs; cc }

theorem swap_core_swap_core (r a b : α) : swap_core a b (swap_core a b r) = r :=
by { unfold swap_core, split_ifs; cc }

theorem swap_core_comm (r a b : α) : swap_core a b r = swap_core b a r :=
by { unfold swap_core, split_ifs; cc }

/-- `swap a b` is the permutation that swaps `a` and `b` and
  leaves other values as is. -/
def swap (a b : α) : perm α :=
⟨swap_core a b, swap_core a b, λr, swap_core_swap_core r a b, λr, swap_core_swap_core r a b⟩

theorem swap_self (a : α) : swap a a = equiv.refl _ :=
eq_of_to_fun_eq $ funext $ λ r, swap_core_self r a

theorem swap_comm (a b : α) : swap a b = swap b a :=
eq_of_to_fun_eq $ funext $ λ r, swap_core_comm r _ _

theorem swap_apply_def (a b x : α) : swap a b x = if x = a then b else if x = b then a else x :=
rfl

@[simp] theorem swap_apply_left (a b : α) : swap a b a = b :=
if_pos rfl

@[simp] theorem swap_apply_right (a b : α) : swap a b b = a :=
by { by_cases b = a; simp [swap_apply_def, *] }

theorem swap_apply_of_ne_of_ne {a b x : α} : x ≠ a → x ≠ b → swap a b x = x :=
by simp [swap_apply_def] {contextual := tt}

@[simp] theorem swap_swap (a b : α) : (swap a b).trans (swap a b) = equiv.refl _ :=
eq_of_to_fun_eq $ funext $ λ x, swap_core_swap_core _ _ _

theorem swap_comp_apply {a b x : α} (π : perm α) :
  π.trans (swap a b) x = if π x = a then b else if π x = b then a else π x :=
by { cases π, refl }

@[simp] lemma swap_inv {α : Type*} [decidable_eq α] (x y : α) :
  (swap x y)⁻¹ = swap x y := rfl

@[simp] lemma symm_trans_swap_trans [decidable_eq β] (a b : α)
  (e : α ≃ β) : (e.symm.trans (swap a b)).trans e = swap (e a) (e b) :=
equiv.ext _ _ (λ x, begin
  have : ∀ a, e.symm x = a ↔ x = e a :=
    λ a, by { rw @eq_comm _ (e.symm x), split; intros; simp * at * },
  simp [swap_apply_def, this],
  split_ifs; simp
end)

@[simp] lemma swap_mul_self {α : Type*} [decidable_eq α] (i j : α) : swap i j * swap i j = 1 :=
equiv.swap_swap i j

@[simp] lemma swap_apply_self {α : Type*} [decidable_eq α] (i j a : α) : swap i j (swap i j a) = a :=
by rw [← perm.mul_apply, swap_mul_self, perm.one_apply]

/-- Augment an equivalence with a prescribed mapping `f a = b` -/
def set_value (f : α ≃ β) (a : α) (b : β) : α ≃ β :=
(swap a (f.symm b)).trans f

@[simp] theorem set_value_eq (f : α ≃ β) (a : α) (b : β) : set_value f a b a = b :=
by { dsimp [set_value], simp [swap_apply_left] }

end swap

protected lemma forall_congr {p : α → Prop} {q : β → Prop} (f : α ≃ β)
  (h : ∀{x}, p x ↔ q (f x)) : (∀x, p x) ↔ (∀y, q y) :=
begin
  split; intros h₂ x,
  { rw [←f.right_inv x], apply h.mp, apply h₂ },
  apply h.mpr, apply h₂
end

end equiv

instance {α} [subsingleton α] : subsingleton (ulift α) := equiv.ulift.subsingleton
instance {α} [subsingleton α] : subsingleton (plift α) := equiv.plift.subsingleton

instance {α} [decidable_eq α] : decidable_eq (ulift α) := equiv.ulift.decidable_eq
instance {α} [decidable_eq α] : decidable_eq (plift α) := equiv.plift.decidable_eq

def unique_unique_equiv : unique (unique α) ≃ unique α :=
{ to_fun := λ h, h.default,
  inv_fun := λ h, { default := h, uniq := λ _, subsingleton.elim _ _ },
  left_inv := λ _, subsingleton.elim _ _,
  right_inv := λ _, subsingleton.elim _ _ }

def equiv_of_unique_of_unique [unique α] [unique β] : α ≃ β :=
{ to_fun := λ _, default β,
  inv_fun := λ _, default α,
  left_inv := λ _, subsingleton.elim _ _,
  right_inv := λ _, subsingleton.elim _ _ }

def equiv_punit_of_unique [unique α] : α ≃ punit.{v} :=
equiv_of_unique_of_unique

namespace quot

/-- An equivalence `e : α ≃ β` generates an equivalence between quotient spaces,
if `ra a₁ a₂ ↔ rb (e a₁) (e a₂). -/
protected def congr {ra : α → α → Prop} {rb : β → β → Prop} (e : α ≃ β)
  (eq : ∀a₁ a₂, ra a₁ a₂ ↔ rb (e a₁) (e a₂)) :
  quot ra ≃ quot rb :=
{ to_fun := quot.map e (assume a₁ a₂, (eq a₁ a₂).1),
  inv_fun := quot.map e.symm
    (assume b₁ b₂ h,
     (eq (e.symm b₁) (e.symm b₂)).2
       ((e.apply_symm_apply b₁).symm ▸ (e.apply_symm_apply b₂).symm ▸ h)),
  left_inv := by { rintros ⟨a⟩, dunfold quot.map, simp only [equiv.symm_apply_apply] },
  right_inv := by { rintros ⟨a⟩, dunfold quot.map, simp only [equiv.apply_symm_apply] } }

/-- Quotients are congruent on equivalences under equality of their relation.
An alternative is just to use rewriting with `eq`, but then computational proofs get stuck. -/
protected def congr_right {r r' : α → α → Prop} (eq : ∀a₁ a₂, r a₁ a₂ ↔ r' a₁ a₂) :
  quot r ≃ quot r' :=
quot.congr (equiv.refl α) eq

/-- An equivalence `e : α ≃ β` generates an equivalence between the quotient space of `α`
by a relation `ra` and the quotient space of `β` by the image of this relation under `e`. -/
protected def congr_left {r : α → α → Prop} (e : α ≃ β) :
  quot r ≃ quot (λ b b', r (e.symm b) (e.symm b')) :=
@quot.congr α β r (λ b b', r (e.symm b) (e.symm b')) e (λ a₁ a₂, by simp only [e.symm_apply_apply])

end quot

namespace quotient
/-- An equivalence `e : α ≃ β` generates an equivalence between quotient spaces,
if `ra a₁ a₂ ↔ rb (e a₁) (e a₂). -/
protected def congr {ra : setoid α} {rb : setoid β} (e : α ≃ β)
  (eq : ∀a₁ a₂, @setoid.r α ra a₁ a₂ ↔ @setoid.r β rb (e a₁) (e a₂)) :
  quotient ra ≃ quotient rb :=
quot.congr e eq

/-- Quotients are congruent on equivalences under equality of their relation.
An alternative is just to use rewriting with `eq`, but then computational proofs get stuck. -/
protected def congr_right {r r' : setoid α}
  (eq : ∀a₁ a₂, @setoid.r α r a₁ a₂ ↔ @setoid.r α r' a₁ a₂) : quotient r ≃ quotient r' :=
quot.congr_right eq
end quotient
