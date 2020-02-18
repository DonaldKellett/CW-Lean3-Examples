/-
This file imports many useful tactics ("the kitchen sink").

You can use `import tactic` at the beginning of your file to get everything.
(Although you may want to strip things down when you're polishing.)

Because this file imports some complicated tactics, it has many transitive dependencies
(which of course may not use `import tactic`, and must import selectively).

As (non-exhaustive) examples, these includes things like:
* algebra.group_power
* algebra.ordered_ring
* data.rat
* data.nat.prime
* data.list.perm
* data.set.lattice
* data.equiv.encodable
* order.complete_lattice
-/
import
  tactic.basic
  tactic.monotonicity.interactive
  tactic.finish
  tactic.tauto
  tactic.tidy
  tactic.abel
  tactic.ring
  tactic.ring_exp
  tactic.linarith
  tactic.omega
  tactic.wlog
  tactic.tfae
  tactic.apply_fun
  tactic.apply
  tactic.pi_instances
  tactic.fin_cases
  tactic.reassoc_axiom -- most likely useful only for category_theory
