/-
Copyright (c) 2019 Floris van Doorn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Floris van Doorn
-/

import tactic.core meta.rb_map

/-!
# Localized notation

This consists of two user-commands which allow you to declare notation and commands localized to a namespace.

* Declare notation which is localized to a namespace using:
```
localized "infix ` ⊹ `:60 := my_add" in my.add
```
* After this command it will be available in the same section/namespace/file, just as if you wrote `local infix ` ⊹ `:60 := my_add`
* You can open it in other places. The following command will declare the notation again as local notation in that section/namespace/files:
```
open_locale my.add
```
* More generally, the following will declare all localized notation in the specified namespaces.
```
open_locale namespace1 namespace2 ...
```
* You can also declare other localized commands, like local attributes
```
localized "attribute [simp] le_refl" in le
```
The code is inspired by code from Gabriel Ebner from the hott3 repository.
-/

open lean lean.parser interactive tactic native

reserve notation `localized`

@[user_attribute]
meta def localized_attr : user_attribute (rb_lmap name string) unit := {
  name := "_localized",
  descr := "(interal) attribute that flags localized commands",
  cache_cfg := ⟨λ ns, (do dcls ← ns.mmap (λ n, mk_const n >>= eval_expr (name × string)),
                          return $ rb_lmap.of_list dcls), []⟩
}

/-- Get all commands in the given notation namespace and return them as a list of strings -/
meta def get_localized (ns : list name) : tactic (list string) :=
do m ← localized_attr.get_cache,
   return (ns.bind $ λ nm, m.find nm)

/-- Execute all commands in the given notation namespace -/
@[user_command] meta def open_locale_cmd (meta_info : decl_meta_info)
  (_ : parse $ tk "open_locale") : parser unit :=
do ns ← many ident,
   cmds ← get_localized ns,
   cmds.mmap' emit_code_here

/-- Add a new command to a notation namespace and execute it right now.
  The new command is added as a declaration to the environment with name `_localized_decl.<number>`.
  This declaration has attribute `_localized` and as value a name-string pair. -/
@[user_command] meta def localized_cmd (meta_info : decl_meta_info)
  (_ : parse $ tk "localized") : parser unit :=
do cmd ← parser.pexpr, cmd ← i_to_expr cmd, cmd ← eval_expr string cmd,
   let cmd := "local " ++ cmd,
   emit_code_here cmd,
   tk "in",
   nm ← ident,
   env ← get_env,
   let dummy_decl_name := mk_num_name `_localized_decl
     ((string.hash (cmd ++ nm.to_string) + env.fingerprint) % unsigned_sz),
   add_decl (declaration.defn dummy_decl_name [] `(name × string)
    (reflect (⟨nm, cmd⟩ : name × string)) (reducibility_hints.regular 1 tt) ff),
   localized_attr.set dummy_decl_name unit.star tt

/-- Print all commands in a given notation namespace -/
meta def print_localized_commands (ns : list name) : tactic unit :=
do cmds ← get_localized ns, cmds.mmap' trace

-- you can run `open_locale classical` to get the decidability of all propositions.
localized "attribute [instance, priority 9] classical.prop_decidable" in classical

localized "postfix `?`:9001 := optional" in parser
localized "postfix *:9001 := lean.parser.many" in parser
