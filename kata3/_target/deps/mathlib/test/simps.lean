import tactic.simps

open function tactic expr
structure equiv (α : Sort*) (β : Sort*) :=
(to_fun    : α → β)
(inv_fun   : β → α)
(left_inv  : left_inverse inv_fun to_fun)
(right_inv : right_inverse inv_fun to_fun)

infix ` ≃ `:25 := equiv

namespace foo

@[simps] protected def rfl {α} : α ≃ α :=
⟨id, λ x, x, λ x, rfl, λ x, rfl⟩

/- simps adds declarations -/
run_cmd do
  e ← get_env,
  e.get `foo.rfl_to_fun,
  e.get `foo.rfl_inv_fun,
  success_if_fail (e.get `foo.rfl_left_inv),
  success_if_fail (e.get `foo.rfl_right_inv)

example (n : ℕ) : foo.rfl.to_fun n = n := by rw [foo.rfl_to_fun, id]
example (n : ℕ) : foo.rfl.inv_fun n = n := by rw [foo.rfl_inv_fun]

/- the declarations are simp-lemmas -/
@[simps] def foo : ℕ × ℤ := (1, 2)

example : foo.1 = 1 := by simp
example : foo.2 = 2 := by simp
example : foo.1 = 1 := by { dsimp, refl } -- check that dsimp also unfolds
example : foo.2 = 2 := by { dsimp, refl }
example {α} (x : α) : foo.rfl.to_fun x = x := by simp
example {α} (x : α) : foo.rfl.inv_fun x = x := by simp
example {α} (x : α) : foo.rfl.to_fun = @id α := by { success_if_fail {simp}, refl }

/- check some failures -/
def bar1 : ℕ := 1 -- type is not a structure
def bar2 : ℕ × ℤ := prod.map (λ x, x + 2) (λ y, y - 3) (3, 4) -- value is not a constructor
noncomputable def bar3 {α} : α ≃ α :=
classical.choice ⟨foo.rfl⟩

run_cmd do
  success_if_fail_with_msg (simps_tac `foo.bar1 tt)
    "Invalid `simps` attribute. Target is not a structure",
  success_if_fail_with_msg (simps_tac `foo.bar2 tt)
    "Invalid `simps` attribute. Body is not a constructor application",
  success_if_fail_with_msg (simps_tac `foo.bar3 tt)
    "Invalid `simps` attribute. Body is not a constructor application",
  e ← get_env,
  let nm := `foo.bar1,
  d ← e.get nm,
  let lhs : expr := const d.to_name (d.univ_params.map level.param),
  simps_add_projections e nm "" d.type lhs d.value [] d.univ_params tt ff ff []

end foo

/- we reduce the type when applying [simps] -/
def my_equiv := equiv
@[simps] def baz : my_equiv ℕ ℕ := ⟨id, λ x, x, λ x, rfl, λ x, rfl⟩

/- test name clashes -/
def name_clash_fst := 1
def name_clash_snd := 1
def name_clash_snd_2 := 1
@[simps] def name_clash := (2, 3)

run_cmd do
  e ← get_env,
  e.get `name_clash_fst_2,
  e.get `name_clash_snd_3

/- check projections for nested structures -/

namespace count_nested
@[simps] def nested1 : ℕ × ℤ × ℕ :=
⟨2, -1, 1⟩

@[simps lemmas_only] def nested2 : ℕ × ℕ × ℕ :=
⟨2, prod.map nat.succ nat.pred (1, 2)⟩

end count_nested

run_cmd do
  e ← get_env,
  e.get `count_nested.nested1_fst,
  e.get `count_nested.nested1_snd_fst,
  e.get `count_nested.nested1_snd_snd,
  e.get `count_nested.nested2_fst,
  e.get `count_nested.nested2_snd,
  is_simp_lemma `count_nested.nested1_fst >>= λ b, guard b, -- simp attribute is global
  is_simp_lemma `count_nested.nested2_fst >>= λ b, guard $ ¬b, --lemmas_only doesn't add simp lemma
  guard $ 7 = e.fold 0 -- there are no other lemmas generated
    (λ d n, n + if d.to_name.components.init.ilast = `count_nested then 1 else 0)

-- testing with arguments
@[simps] def bar {α : Type*} (n m : ℕ) : ℕ × ℤ :=
⟨n - m, n + m⟩

structure equiv_plus_data (α β) extends α ≃ β :=
(P : (α → β) → Prop)
(data : P to_fun)

structure automorphism_plus_data α extends α ⊕ α ≃ α ⊕ α :=
(P : (α ⊕ α → α ⊕ α) → Prop)
(data : P to_fun)
(extra : bool → ℕ × ℕ)

@[simps]
def refl_with_data {α} : equiv_plus_data α α :=
{ P := λ f, f = id,
  data := rfl,
  ..foo.rfl }

@[simps]
def refl_with_data' {α} : equiv_plus_data α α :=
{ P := λ f, f = id,
  data := rfl,
  to_equiv := foo.rfl }

/- test whether eta expansions are reduced correctly -/
@[simps]
def test {α} : automorphism_plus_data α :=
{ P := λ f, f = id,
  data := rfl,
  extra := λ b, ((3,5).1,(3,5).2),
  ..foo.rfl }

run_cmd do
  e ← get_env,
  e.get `refl_with_data_to_equiv,
  e.get `refl_with_data'_to_equiv,
  e.get `test_extra,
  success_if_fail (e.get `refl_with_data_to_equiv_to_fun),
  success_if_fail (e.get `refl_with_data'_to_equiv_to_fun),
  success_if_fail (e.get `test_extra_fst)

structure partially_applied_str :=
(data : ℕ → ℕ × ℕ)

/- if we have a partially applied constructor, we treat it as if it were eta-expanded -/
@[simps]
def partially_applied_term : partially_applied_str := ⟨prod.mk 3⟩

run_cmd do
  e ← get_env,
  e.get `partially_applied_term_data_fst,
  e.get `partially_applied_term_data_snd

structure very_partially_applied_str :=
(data : ∀β, ℕ → β → ℕ × β)

/- if we have a partially applied constructor, we treat it as if it were eta-expanded -/
@[simps]
def very_partially_applied_term : very_partially_applied_str := ⟨@prod.mk ℕ⟩

run_cmd do
  e ← get_env,
  e.get `very_partially_applied_term_data_fst,
  e.get `very_partially_applied_term_data_snd

@[simps] def let1 : ℕ × ℤ :=
let n := 3 in ⟨n + 4, 5⟩

@[simps] def let2 : ℕ × ℤ :=
let n := 3, m := 4 in let k := 5 in ⟨n + m, k⟩

@[simps] def let3 : ℕ → ℕ × ℤ :=
λ n, let m := 4, k := 5 in ⟨n + m, k⟩

@[simps] def let4 : ℕ → ℕ × ℤ :=
let m := 4, k := 5 in λ n, ⟨n + m, k⟩

run_cmd do
  e ← get_env,
  e.get `let1_fst, e.get `let2_fst, e.get `let3_fst, e.get `let4_fst,
  e.get `let1_snd, e.get `let2_snd, e.get `let3_snd, e.get `let4_snd


namespace specify
@[simps fst] def specify1 : ℕ × ℕ × ℕ := (1, 2, 3)
@[simps snd] def specify2 : ℕ × ℕ × ℕ := (1, 2, 3)
@[simps snd_fst] def specify3 : ℕ × ℕ × ℕ := (1, 2, 3)
@[simps snd snd_snd snd_snd] def specify4 : ℕ × ℕ × ℕ := (1, 2, 3) -- last argument is ignored
@[simps] def specify5 : ℕ × ℕ × ℕ := (1, prod.map (λ x, x) (λ y, y) (2, 3))
end specify

run_cmd do
  e ← get_env,
  e.get `specify.specify1_fst, e.get `specify.specify2_snd,
  e.get `specify.specify3_snd_fst, e.get `specify.specify4_snd_snd, e.get `specify.specify4_snd,
  e.get `specify.specify5_fst, e.get `specify.specify5_snd,
  guard $ 12 = e.fold 0 -- there are no other lemmas generated
    (λ d n, n + if d.to_name.components.init.ilast = `specify then 1 else 0),
  success_if_fail_with_msg (simps_tac `specify.specify1 tt ff ["fst_fst"])
    "Invalid simp-lemma specify.specify1_fst_fst. Too many projections given.",
  success_if_fail_with_msg (simps_tac `specify.specify1 tt ff ["foo_fst"])
    "Invalid simp-lemma specify.specify1_foo_fst. Projection foo doesn't exist.",
  success_if_fail_with_msg (simps_tac `specify.specify1 tt ff ["snd_bar"])
    "Invalid simp-lemma specify.specify1_snd_bar. Projection bar doesn't exist.",
  success_if_fail_with_msg (simps_tac `specify.specify5 tt ff ["snd_snd"])
    "Invalid simp-lemma specify.specify5_snd_snd. Too many projections given."


/- We also eta-reduce if we explicitly specify the projection. -/
attribute [simps extra] test
run_cmd do
  e ← get_env,
  d1 ← e.get `test_extra,
  d2 ← e.get `test_extra_2,
  guard $ d1.type =ₐ d2.type,
  skip

/- check short_name option -/
@[simps short_name] def short_name1 : (ℕ × ℕ) × ℕ × ℕ := ((1, 2), 3, 4)
run_cmd do
  e ← get_env,
  e.get `short_name1_fst, e.get `short_name1_fst_2,
  e.get `short_name1_snd, e.get `short_name1_snd_2
