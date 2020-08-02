# CW Lean3 Setup Example

An example of how Lean v3.18.4 support could be added to Codewars

## Initial Setup

1. Install [`elan`](https://github.com/Kha/elan)
2. Run `pip3 install mathlibtools`, with `sudo` if necessary
3. Run `leanproject new kata`. This automatically creates a Lean3 project in `kata/` with the latest Lean3 community version (3.18.4 at the time of writing) and the corresponding pre-compiled mathlib
4. Run `cd kata/` and create a `main.js` file as in this repo
5. Run `cd src/` and populate the directory with `.lean` files

## Proposed Workflow

1. Write a definitions file `Preloaded.lean` with the following format:

  ```lean
  -- Task 1
  def TASK_1 := <theorem_statement_1>
  notation `TASK_1` := TASK_1

  -- Task 2
  def TASK_2 := <theorem_statement_2>
  notation `TASK_2` := TASK_2

  /- ... -/

  -- Task n
  def TASK_n := <theorem_statement_n>
  notation `TASK_n` := TASK_n
  ```
2. Write a solution file `Solution.lean` with the following format:

  ```lean
  import Preloaded

  -- Task 1: <description_for_task_1>
  theorem proof_of_statement_1 : <theorem_statement_1> :=
  begin
    <insert_proof_here>
  end

  -- Task 2: <description_for_task_2>
  theorem proof_of_statement_2 : <theorem_statement_2> :=
  begin
    <insert_proof_here>
  end

  /- ... -/

  -- Task n: <description_for_task_n>
  theorem proof_of_statement_n : <theorem_statement_n> :=
  begin
    <insert_proof_here>
  end
  ```
3. Write a check file `SolutionTest.lean` with the following format:

  ```lean
  import Preloaded Solution

  -- Task 1
  theorem task_1 : TASK_1 := proof_of_statement_1
  #print axioms task_1

  -- Task 2
  theorem task_2 : TASK_2 := proof_of_statement_2
  #print axioms task_2

  /- ... -/

  -- Task n
  theorem task_n : TASK_n := proof_of_statement_n
  #print axioms task_n
  ```
4. On "Run Sample Tests" / "Attempt", run `cd ..; node main.js; cd src/`

## Examples

- `kata1` - Solution contains forbidden axiom `1 + 1 = 3`, resulting in a failed test
- `kata2` - Solution uses `sorry`, leading to a failed test
- `kata3` - Solution uses all three core axioms, resulting in a passed test
- `kata4` - Solution uses no axioms at all, resulting in a passed test
- `kata5` - Solution contains forbidden axioms `1 + 1 = 3` and `2 + 2 = 5`, resulting in a failed test

## `leanpkg.toml`

```toml
[package]
name = "kata"
version = "0.1"
lean_version = "leanprover-community/lean:3.18.4"
path = "src"

[dependencies]
mathlib = {git = "https://github.com/leanprover-community/mathlib", rev = "78655b6eef558ccb36772934ed98ed83d9a56802"}
```
