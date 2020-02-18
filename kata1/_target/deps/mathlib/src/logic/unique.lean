/-
Copyright (c) 2019 Johan Commelin. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johan Commelin
-/

universes u v w

variables {α : Sort u} {β : Sort v} {γ : Sort w}

structure unique (α : Sort u) extends inhabited α :=
(uniq : ∀ a:α, a = default)

attribute [class] unique

instance punit.unique : unique punit.{u} :=
{ default := punit.star,
  uniq := λ x, punit_eq x _ }

instance fin.unique : unique (fin 1) :=
{ default := 0,
  uniq := λ ⟨n, hn⟩, fin.eq_of_veq
    (nat.eq_zero_of_le_zero (nat.le_of_lt_succ hn)) }

namespace unique
open function

section

variables [unique α]

@[priority 100] -- see Note [lower instance priority]
instance : inhabited α := to_inhabited ‹unique α›

lemma eq_default (a : α) : a = default α := uniq _ a

lemma default_eq (a : α) : default α = a := (uniq _ a).symm

@[priority 100] -- see Note [lower instance priority]
instance : subsingleton α := ⟨λ a b, by rw [eq_default a, eq_default b]⟩

lemma forall_iff {p : α → Prop} : (∀ a, p a) ↔ p (default α) :=
⟨λ h, h _, λ h x, by rwa [unique.eq_default x]⟩

lemma exists_iff {p : α → Prop} : Exists p ↔ p (default α) :=
⟨λ ⟨a, ha⟩, eq_default a ▸ ha, exists.intro (default α)⟩

end

protected lemma subsingleton_unique' : ∀ (h₁ h₂ : unique α), h₁ = h₂
| ⟨⟨x⟩, h⟩ ⟨⟨y⟩, _⟩ := by congr; rw [h x, h y]

instance subsingleton_unique : subsingleton (unique α) :=
⟨unique.subsingleton_unique'⟩

def of_surjective {f : α → β} (hf : surjective f) [unique α] : unique β :=
{ default := f (default _),
  uniq := λ b,
  begin
    cases hf b with a ha,
    subst ha,
    exact congr_arg f (eq_default a)
  end }

end unique
