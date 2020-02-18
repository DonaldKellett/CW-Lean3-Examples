/-
Copyright (c) 2019 Robert Y. Lewis. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Robert Y. Lewis
-/
import data.set

@[derive has_coe_to_sort] def X : Type := set ℕ

@[derive ring] def T := ℤ

class binclass (T1 T2 : Type)

instance : binclass ℤ ℤ := ⟨_, _⟩

@[derive [ring, binclass ℤ]] def U := ℤ

@[derive λ α, binclass α ℤ] def V := ℤ

@[derive ring] def id_ring (α) [ring α] : Type := α

@[derive decidable_eq] def S := ℕ

@[derive decidable_eq] inductive P | a | b | c
