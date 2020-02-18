# cw-lean-setup-example

An example of how Lean v3.5.c support could be added to Codewars

## Proposed Workflow

1. Write a definitions file `Preloaded.lean` with the following format:

  ```lean
  -- Task 1
  def task_1 := <theorem_statement_1>

  -- Task 2
  def task_2 := <theorem_statement_2>

  /- ... -/

  -- Task n
  def task_n := <theorem_statement_n>

  -- Boilerplate code for tying all the tasks together
  def SUBMISSION := task_1 ∧ task_2 ∧ ... ∧ task_n

  -- Now, to prevent cheating:
  notation `SUBMISSION` := SUBMISSION
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

  -- Do NOT modify this section
  theorem solution : SUBMISSION := ⟨
    proof_of_statement_1,
    proof_of_statement_2,
    ...,
    proof_of_statement_n
  ⟩
  ```
3. Write a check file `SolutionTest.lean` with the following format:

  ```lean
  import Preloaded
  import Solution

  theorem submission : SUBMISSION := solution
  ```
4. `cd` to root of Kata directory and run

  ```bash
  $ node main.js
  ```

  This executes the command

  ```bash
  $ cd src/ && lean SolutionTest.lean -E SolutionTest.out && leanchecker SolutionTest.out submission
  ```

  and post-processes its output to check for forbidden axioms, resulting in a passed test if none are found and fails otherwise.

## Examples

- `kata1` - Solution contains forbidden axiom `1 + 1 = 3`, resulting in a failed test
- `kata2` - Use of `sorry` causes `lean SolutionTest.lean -E SolutionTest.out` to fail with an error
- `kata3` - Solution uses all three core axioms, resulting in a passed test
- `kata4` - Solution uses no axioms at all, resulting in a passed test
- `kata5` - Solution contains forbidden axioms `1 + 1 = 3` and `2 + 2 = 5`, resulting in a failed test
