/-
Copyright (c) 2018 Simon Hudon. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Simon Hudon, Scott Morrison
-/

import tactic.interactive tactic.finish tactic.ext tactic.lift tactic.apply
       tactic.reassoc_axiom tactic.tfae tactic.elide tactic.ring_exp
       tactic.clear tactic.simp_rw

example (m n p q : nat) (h : m + n = p) : true :=
begin
  have : m + n = q,
  { generalize_hyp h' : m + n = x at h,
    guard_hyp h' := m + n = x,
    guard_hyp h := x = p,
    guard_target m + n = q,
    admit },
  have : m + n = q,
  { generalize_hyp h' : m + n = x at h ⊢,
    guard_hyp h' := m + n = x,
    guard_hyp h := x = p,
    guard_target x = q,
    admit },
  trivial
end

example (α : Sort*) (L₁ L₂ L₃ : list α)
  (H : L₁ ++ L₂ = L₃) : true :=
begin
  have : L₁ ++ L₂ = L₂,
  { generalize_hyp h : L₁ ++ L₂ = L at H,
    induction L with hd tl ih,
    case list.nil
    { tactic.cleanup,
      change list.nil = L₃ at H,
      admit },
    case list.cons
    { change list.cons hd tl = L₃ at H,
      admit } },
  trivial
end

example (x y : ℕ) (p q : Prop) (h : x = y) (h' : p ↔ q) : true :=
begin
  symmetry' at h,
  guard_hyp' h := y = x,
  guard_hyp' h' := p ↔ q,
  symmetry' at *,
  guard_hyp' h := x = y,
  guard_hyp' h' := q ↔ p,
  trivial
end

section apply_rules

example {a b c d e : nat} (h1 : a ≤ b) (h2 : c ≤ d) (h3 : 0 ≤ e) :
a + c * e + a + c + 0 ≤ b + d * e + b + d + e :=
add_le_add (add_le_add (add_le_add (add_le_add h1 (mul_le_mul_of_nonneg_right h2 h3)) h1 ) h2) h3

example {a b c d e : nat} (h1 : a ≤ b) (h2 : c ≤ d) (h3 : 0 ≤ e) :
a + c * e + a + c + 0 ≤ b + d * e + b + d + e :=
by apply_rules [add_le_add, mul_le_mul_of_nonneg_right]

@[user_attribute]
meta def mono_rules : user_attribute :=
{ name := `mono_rules,
  descr := "lemmas usable to prove monotonicity" }
attribute [mono_rules] add_le_add mul_le_mul_of_nonneg_right

example {a b c d e : nat} (h1 : a ≤ b) (h2 : c ≤ d) (h3 : 0 ≤ e) :
a + c * e + a + c + 0 ≤ b + d * e + b + d + e :=
by apply_rules [mono_rules]

example {a b c d e : nat} (h1 : a ≤ b) (h2 : c ≤ d) (h3 : 0 ≤ e) :
a + c * e + a + c + 0 ≤ b + d * e + b + d + e :=
by apply_rules mono_rules

end apply_rules

section h_generalize

variables {α β γ φ ψ : Type} (f : α → α → α → φ → γ)
          (x y : α) (a b : β) (z : φ)
          (h₀ : β = α) (h₁ : β = α) (h₂ : φ = β)
          (hx : x == a) (hy : y == b) (hz : z == a)
include f x y z a b hx hy hz

example : f x y x z = f (eq.rec_on h₀ a) (cast h₀ b) (eq.mpr h₁.symm a) (eq.mpr h₂ a) :=
begin
  guard_hyp_nums 16,
  h_generalize hp : a == p with hh,
  guard_hyp_nums 19,
  guard_hyp' hh := β = α,
  guard_target f x y x z = f p (cast h₀ b) p (eq.mpr h₂ a),
  h_generalize hq : _ == q,
  guard_hyp_nums 21,
  guard_target f x y x z = f p q p (eq.mpr h₂ a),
  h_generalize _ : _ == r,
  guard_hyp_nums 23,
  guard_target f x y x z = f p q p r,
  casesm* [_ == _, _ = _], refl
end

end h_generalize

section h_generalize

variables {α β γ φ ψ : Type} (f : list α → list α → γ)
          (x : list α) (a : list β) (z : φ)
          (h₀ : β = α) (h₁ : list β = list α)
          (hx : x == a)
include f x z a hx h₀ h₁

example : true :=
begin
  have : f x x = f (eq.rec_on h₀ a) (cast h₁ a),
  { guard_hyp_nums 11,
    h_generalize : a == p with _,
    guard_hyp_nums 13,
    guard_hyp' h := β = α,
    guard_target f x x = f p (cast h₁ a),
    h_generalize! : a == q ,
    guard_hyp_nums 13,
    guard_target ∀ q, f x x = f p q,
    casesm* [_ == _, _ = _],
    success_if_fail { refl },
    admit },
  trivial
end

end h_generalize

section tfae

example (p q r s : Prop)
  (h₀ : p ↔ q)
  (h₁ : q ↔ r)
  (h₂ : r ↔ s) :
  p ↔ s :=
begin
  scc,
end

example (p' p q r r' s s' : Prop)
  (h₀ : p' → p)
  (h₀ : p → q)
  (h₁ : q → r)
  (h₁ : r' → r)
  (h₂ : r ↔ s)
  (h₂ : s → p)
  (h₂ : s → s') :
  p ↔ s :=
begin
  scc,
end

example (p' p q r r' s s' : Prop)
  (h₀ : p' → p)
  (h₀ : p → q)
  (h₁ : q → r)
  (h₁ : r' → r)
  (h₂ : r ↔ s)
  (h₂ : s → p)
  (h₂ : s → s') :
  p ↔ s :=
begin
  scc',
  assumption
end

example : tfae [true, ∀ n : ℕ, 0 ≤ n * n, true, true] := begin
  tfae_have : 3 → 1, { intro h, constructor },
  tfae_have : 2 → 3, { intro h, constructor },
  tfae_have : 2 ← 1, { intros h n, apply nat.zero_le },
  tfae_have : 4 ↔ 2, { tauto },
  tfae_finish,
end

example : tfae [] := begin
  tfae_finish,
end

variables P Q R : Prop

example : tfae [P, Q, R] :=
begin
  have : P → Q := sorry, have : Q → R := sorry, have : R → P := sorry,
  --have : R → Q := sorry, -- uncommenting this makes the proof fail
  tfae_finish
end

example : tfae [P, Q, R] :=
begin
  have : P → Q := sorry, have : Q → R := sorry, have : R → P := sorry,
  have : R → Q := sorry, -- uncommenting this makes the proof fail
  tfae_finish
end

example : tfae [P, Q, R] :=
begin
  have : P ↔ Q := sorry, have : Q ↔ R := sorry,
  tfae_finish -- the success or failure of this tactic is nondeterministic!
end

example (p : unit → Prop) : tfae [p (), p ()] :=
begin
  tfae_have : 1 ↔ 2, from iff.rfl,
  tfae_finish
end

end tfae

section clear_aux_decl

example (n m : ℕ) (h₁ : n = m) (h₂ : ∃ a : ℕ, a = n ∧ a = m) : 2 * m = 2 * n :=
let ⟨a, ha⟩ := h₂ in
begin
  clear_aux_decl, -- subst will fail without this line
  subst h₁
end

example (x y : ℕ) (h₁ : ∃ n : ℕ, n * 1 = 2) (h₂ : 1 + 1 = 2 → x * 1 = y) : x = y :=
let ⟨n, hn⟩ := h₁ in
begin
  clear_aux_decl, -- finish produces an error without this line
  finish
end

end clear_aux_decl

section congr

example (c : Prop → Prop → Prop → Prop) (x x' y z z' : Prop)
  (h₀ : x ↔ x')
  (h₁ : z ↔ z') :
  c x y z ↔ c x' y z' :=
begin
  congr',
  { guard_target x = x', ext, assumption },
  { guard_target z = z', ext, assumption },
end

end congr

section convert_to

example {a b c d : ℕ} (H : a = c) (H' : b = d) : a + b = d + c :=
by {convert_to c + d = _ using 2, from H, from H', rw[add_comm]}

example {a b c d : ℕ} (H : a = c) (H' : b = d) : a + b = d + c :=
by {convert_to c + d = _ using 0, congr' 2, from H, from H', rw[add_comm]}

example (a b c d e f g N : ℕ) : (a + b) + (c + d) + (e + f) + g ≤ a + d + e + f + c + g + b :=
by {ac_change a + d + e + f + c + g + b ≤ _, refl}

end convert_to

section swap

example {α₁ α₂ α₃ : Type} : true :=
by {have : α₁, have : α₂, have : α₃, swap, swap,
    rotate, rotate, rotate, rotate 2, rotate 2, triv, recover}

end swap

section lift

example (n m k x z u : ℤ) (hn : 0 < n) (hk : 0 ≤ k + n) (hu : 0 ≤ u) (h : k + n = 2 + x) :
  k + n = m + x :=
begin
  lift n to ℕ using le_of_lt hn,
    guard_target (k + ↑n = m + x), guard_hyp hn := (0 : ℤ) < ↑n,
  lift m to ℕ,
    guard_target (k + ↑n = ↑m + x), tactic.swap, guard_target (0 ≤ m), tactic.swap,
    tactic.num_goals >>= λ n, guard (n = 2),
  lift (k + n) to ℕ using hk with l hl,
    guard_hyp l := ℕ, guard_hyp hl := ↑l = k + ↑n, guard_target (↑l = ↑m + x),
    tactic.success_if_fail (tactic.get_local `hk),
  lift x to ℕ with y hy,
    guard_hyp y := ℕ, guard_hyp hy := ↑y = x, guard_target (↑l = ↑m + x),
  lift z to ℕ with w,
    guard_hyp w := ℕ, tactic.success_if_fail (tactic.get_local `z),
  lift u to ℕ using hu with u rfl hu,
    guard_hyp hu := (0 : ℤ) ≤ ↑u,
  all_goals { admit }
end

-- test lift of functions
example (α : Type*) (f : α → ℤ) (hf : ∀ a, 0 ≤ f a) (hf' : ∀ a, f a < 1) (a : α) : 0 ≤ 2 * f a :=
begin
  lift f to α → ℕ using hf,
    guard_target ((0:ℤ) ≤ 2 * (λ i : α, (f i : ℤ)) a),
    guard_hyp hf' := ∀ a, ((λ i : α, (f i:ℤ)) a) < 1,
  trivial
end

instance can_lift_unit : can_lift unit unit :=
⟨id, λ x, true, λ x _, ⟨x, rfl⟩⟩

/- test whether new instances of `can_lift` are added as simp lemmas -/
run_cmd do l ← can_lift_attr.get_cache, guard (`can_lift_unit ∈ l)

/- test error messages -/
example (n : ℤ) (hn : 0 < n) : true :=
begin
  success_if_fail_with_msg {lift n to ℕ using hn} "lift tactic failed. The type of\n  hn\nis
  0 < n\nbut it is expected to be\n  0 ≤ n",
  success_if_fail_with_msg {lift (n : option ℤ) to ℕ}
    "Failed to find a lift from option ℤ to ℕ. Provide an instance of\n  can_lift (option ℤ) ℕ",
  trivial
end

example (n : ℤ) : ℕ :=
begin
  success_if_fail_with_msg {lift n to ℕ}
    "lift tactic failed. Tactic is only applicable when the target is a proposition.",
  exact 0
end

end lift

private meta def get_exception_message (t : lean.parser unit) : lean.parser string
| s := match t s with
       | result.success a s' := result.success "No exception" s
       | result.exception none pos s' := result.success "Exception no msg" s
       | result.exception (some msg) pos s' := result.success (msg ()).to_string s
       end

@[user_command] meta def test_parser1_fail_cmd
(_ : interactive.parse (lean.parser.tk "test_parser1")) : lean.parser unit :=
do
  let msg := "oh, no!",
  let t : lean.parser unit := tactic.fail msg,
  s ← get_exception_message t,
  if s = msg then tactic.skip
  else interaction_monad.fail "Message was corrupted while being passed through `lean.parser.of_tactic`"
.

-- Due to `lean.parser.of_tactic'` priority, the following *should not* fail with
-- a VM check error, and instead catch the error gracefully and just
-- run and succeed silently.
test_parser1

section category_theory
open category_theory
variables {C : Type} [category.{1} C]

example (X Y Z W : C) (x : X ⟶ Y) (y : Y ⟶ Z) (z z' : Z ⟶ W) (w : X ⟶ Z)
  (h : x ≫ y = w)
  (h' : y ≫ z = y ≫ z') :
  x ≫ y ≫ z = w ≫ z' :=
begin
  rw [h',reassoc_of h],
end

end category_theory

section is_eta_expansion
/- test the is_eta_expansion tactic -/
open function tactic
structure my_equiv (α : Sort*) (β : Sort*) :=
(to_fun    : α → β)
(inv_fun   : β → α)
(left_inv  : left_inverse inv_fun to_fun)
(right_inv : right_inverse inv_fun to_fun)

infix ` my≃ `:25 := my_equiv

protected def my_rfl {α} : α my≃ α :=
⟨id, λ x, x, λ x, rfl, λ x, rfl⟩

def eta_expansion_test : ℕ × ℕ := ((1,0).1,(1,0).2)
run_cmd do e ← get_env, x ← e.get `eta_expansion_test,
  let v := (x.value.get_app_args).drop 2,
  let nms := [`prod.fst, `prod.snd],
  guard $ expr.is_eta_expansion_test (nms.zip v) = some `((1, 0))

def eta_expansion_test2 : ℕ my≃ ℕ :=
⟨my_rfl.to_fun, my_rfl.inv_fun, λ x, rfl, λ x, rfl⟩

run_cmd do e ← get_env, x ← e.get `eta_expansion_test2,
  let v := (x.value.get_app_args).drop 2,
  projs ← e.structure_fields_full `my_equiv,
  b ← expr.is_eta_expansion_aux x.value (projs.zip v),
  guard $ b = some `(@my_rfl ℕ)

run_cmd do e ← get_env, x1 ← e.get `eta_expansion_test, x2 ← e.get `eta_expansion_test2,
  b1 ← expr.is_eta_expansion x1.value,
  b2 ← expr.is_eta_expansion x2.value,
  guard $ b1 = some `((1, 0)) ∧ b2 = some `(@my_rfl ℕ)

structure my_str (n : ℕ) := (x y : ℕ)

def dummy : my_str 3 := ⟨3, 1, 1⟩
def wrong_param : my_str 2 := ⟨2, dummy.1, dummy.2⟩
def right_param : my_str 3 := ⟨3, dummy.1, dummy.2⟩

run_cmd do e ← get_env,
  x ← e.get `wrong_param, o ← x.value.is_eta_expansion,
  guard o.is_none,
  x ← e.get `right_param, o ← x.value.is_eta_expansion,
  guard $ o = some `(dummy)


end is_eta_expansion

section elide

variables {x y z w : ℕ}
variables (h  : x + y + z ≤ w)
          (h' : x ≤ y + z + w)
include h h'

example : x + y + z ≤ w :=
begin
  elide 0 at h,
  elide 2 at h',
  guard_hyp h := @hidden _ (x + y + z ≤ w),
  guard_hyp h' := x ≤ @has_add.add (@hidden Type nat) (@hidden (has_add nat) nat.has_add)
                                   (@hidden ℕ (y + z)) (@hidden ℕ w),
  unelide at h,
  unelide at h',
  guard_hyp h' := x ≤ y + z + w,
  exact h, -- there was a universe problem in `elide`. `exact h` lets the kernel check
           -- the consistency of the universes
end

end elide

section struct_eq

@[ext]
structure foo (α : Type*) :=
(x y : ℕ)
(z : {z // z < x})
(k : α)
(h : x < y)

example {α : Type*} : Π (x y : foo α), x.x = y.x → x.y = y.y → x.z == y.z → x.k = y.k → x = y :=
foo.ext

example {α : Type*} : Π (x y : foo α), x = y ↔ x.x = y.x ∧ x.y = y.y ∧ x.z == y.z ∧ x.k = y.k :=
foo.ext_iff

example {α} (x y : foo α) (h : x = y) : y = x :=
begin
  ext,
  { guard_target' y.x = x.x, rw h },
  { guard_target' y.y = x.y, rw h },
  { guard_target' y.z == x.z, rw h },
  { guard_target' y.k = x.k, rw h },
end

end struct_eq

section ring_exp
  example (a b : ℤ) (n : ℕ) : (a + b)^(n + 2) = (a^2 + 2 * a * b + b^2) * (a + b)^n := by ring_exp
end ring_exp

section clear'

example {α} {β : α → Type} (a : α) (b : β a) : unit :=
begin
  success_if_fail { clear a b }, -- fails since `b` depends on `a`
  success_if_fail { clear' a },  -- fails since `b` depends on `a`
  clear' a b,
  guard_hyp_nums 2,
  exact ()
end

example {α} {β : α → Type} (a : α) : β a → unit :=
begin
  success_if_fail { clear' a }, -- fails since the target depends on `a`
  exact λ _, ()
end

end clear'

section clear_dependent

example {α} {β : α → Type} (a : α) (b : β a) : unit :=
begin
  success_if_fail { clear' a }, -- fails since `b` depends on `a`
  clear_dependent a,
  guard_hyp_nums 2,
  exact ()
end

example {α} {β : α → Type} (a : α) : β a → unit :=
begin
  success_if_fail { clear_dependent a }, -- fails since the target depends on `a`
  exact λ _, ()
end

end clear_dependent

section simp_rw
  example {α β : Type} {f : α → β} {t : set β} :
    (∀ s, f '' s ⊆ t) = ∀ s : set α, ∀ x ∈ s, x ∈ f ⁻¹' t :=
  by simp_rw [set.image_subset_iff, set.subset_def]
end simp_rw

section rename'

example {α β} (a : α) (b : β) : unit :=
begin
  rename' a a',              -- rename-compatible syntax
  guard_hyp a' := α,

  rename' a' → a,            -- more suggestive syntax
  guard_hyp a := α,

  rename' [a a', b b'],      -- parallel renaming
  guard_hyp a' := α,
  guard_hyp b' := β,

  rename' [a' → a, b' → b],  -- ditto with alternative syntax
  guard_hyp a := α,
  guard_hyp b := β,

  rename' [a → b, b → a],    -- renaming really is parallel
  guard_hyp a := β,
  guard_hyp b := α,

  rename' b a,               -- shadowing is allowed (but guard_hyp doesn't like it)

  success_if_fail { rename' d e }, -- cannot rename nonexistent hypothesis
  exact ()
end

end rename'
