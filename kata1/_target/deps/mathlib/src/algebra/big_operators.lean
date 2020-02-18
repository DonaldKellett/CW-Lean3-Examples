/-
Copyright (c) 2017 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl

Some big operators for lists and finite sets.
-/
import tactic.tauto data.list.basic data.finset data.nat.enat
import algebra.group algebra.ordered_group algebra.group_power

universes u v w
variables {α : Type u} {β : Type v} {γ : Type w}

theorem directed.finset_le {r : α → α → Prop} [is_trans α r]
  {ι} (hι : nonempty ι) {f : ι → α} (D : directed r f) (s : finset ι) :
  ∃ z, ∀ i ∈ s, r (f i) (f z) :=
show ∃ z, ∀ i ∈ s.1, r (f i) (f z), from
multiset.induction_on s.1 (let ⟨z⟩ := hι in ⟨z, λ _, false.elim⟩) $
λ i s ⟨j, H⟩, let ⟨k, h₁, h₂⟩ := D i j in
⟨k, λ a h, or.cases_on (multiset.mem_cons.1 h)
  (λ h, h.symm ▸ h₁)
  (λ h, trans (H _ h) h₂)⟩

theorem finset.exists_le {α : Type u} [nonempty α] [directed_order α] (s : finset α) :
  ∃ M, ∀ i ∈ s, i ≤ M :=
directed.finset_le (by apply_instance) directed_order.directed s

namespace finset
variables {s s₁ s₂ : finset α} {a : α} {f g : α → β}

/-- `prod s f` is the product of `f x` as `x` ranges over the elements of the finite set `s`. -/
@[to_additive]
protected def prod [comm_monoid β] (s : finset α) (f : α → β) : β := (s.1.map f).prod

@[to_additive] lemma prod_eq_multiset_prod [comm_monoid β] (s : finset α) (f : α → β) :
  s.prod f = (s.1.map f).prod := rfl

@[to_additive]
theorem prod_eq_fold [comm_monoid β] (s : finset α) (f : α → β) : s.prod f = s.fold (*) 1 f := rfl

section comm_monoid
variables [comm_monoid β]

@[simp, to_additive]
lemma prod_empty {α : Type u} {f : α → β} : (∅:finset α).prod f = 1 := rfl

@[simp, to_additive]
lemma prod_insert [decidable_eq α] : a ∉ s → (insert a s).prod f = f a * s.prod f := fold_insert

@[simp, to_additive]
lemma prod_singleton : (singleton a).prod f = f a :=
eq.trans fold_singleton $ mul_one _

@[to_additive]
lemma prod_pair [decidable_eq α] {a b : α} (h : a ≠ b) :
  ({a, b} : finset α).prod f = f a * f b :=
by simp [prod_insert (not_mem_singleton.2 h.symm), mul_comm]

@[simp] lemma prod_const_one : s.prod (λx, (1 : β)) = 1 :=
by simp only [finset.prod, multiset.map_const, multiset.prod_repeat, one_pow]
@[simp] lemma sum_const_zero {β} {s : finset α} [add_comm_monoid β] : s.sum (λx, (0 : β)) = 0 :=
@prod_const_one _ (multiplicative β) _ _
attribute [to_additive] prod_const_one

@[simp, to_additive]
lemma prod_image [decidable_eq α] {s : finset γ} {g : γ → α} :
  (∀x∈s, ∀y∈s, g x = g y → x = y) → (s.image g).prod f = s.prod (λx, f (g x)) :=
fold_image

@[simp, to_additive]
lemma prod_map (s : finset α) (e : α ↪ γ) (f : γ → β) :
  (s.map e).prod f = s.prod (λa, f (e a)) :=
by rw [finset.prod, finset.map_val, multiset.map_map]; refl

@[congr, to_additive]
lemma prod_congr (h : s₁ = s₂) : (∀x∈s₂, f x = g x) → s₁.prod f = s₂.prod g :=
by rw [h]; exact fold_congr
attribute [congr] finset.sum_congr

@[to_additive]
lemma prod_union_inter [decidable_eq α] : (s₁ ∪ s₂).prod f * (s₁ ∩ s₂).prod f = s₁.prod f * s₂.prod f :=
fold_union_inter

@[to_additive]
lemma prod_union [decidable_eq α] (h : disjoint s₁ s₂) : (s₁ ∪ s₂).prod f = s₁.prod f * s₂.prod f :=
by rw [←prod_union_inter, (disjoint_iff_inter_eq_empty.mp h)]; exact (mul_one _).symm

@[to_additive]
lemma prod_sdiff [decidable_eq α] (h : s₁ ⊆ s₂) : (s₂ \ s₁).prod f * s₁.prod f = s₂.prod f :=
by rw [←prod_union sdiff_disjoint, sdiff_union_of_subset h]

@[simp, to_additive]
lemma prod_sum_elim [decidable_eq (α ⊕ γ)]
  (s : finset α) (t : finset γ) (f : α → β) (g : γ → β) :
  (s.image sum.inl ∪ t.image sum.inr).prod (sum.elim f g) = s.prod f * t.prod g :=
begin
  rw [prod_union, prod_image, prod_image],
  { simp only [sum.elim_inl, sum.elim_inr] },
  { exact λ _ _ _ _, sum.inr.inj },
  { exact λ _ _ _ _, sum.inl.inj },
  { rintros i hi,
    erw [finset.mem_inter, finset.mem_image, finset.mem_image] at hi,
    rcases hi with ⟨⟨i, hi, rfl⟩, ⟨j, hj, H⟩⟩,
    cases H }
end

@[to_additive]
lemma prod_bind [decidable_eq α] {s : finset γ} {t : γ → finset α} :
  (∀x∈s, ∀y∈s, x ≠ y → disjoint (t x) (t y)) → (s.bind t).prod f = s.prod (λx, (t x).prod f) :=
by haveI := classical.dec_eq γ; exact
finset.induction_on s (λ _, by simp only [bind_empty, prod_empty])
  (assume x s hxs ih hd,
  have hd' : ∀x∈s, ∀y∈s, x ≠ y → disjoint (t x) (t y),
    from assume _ hx _ hy, hd _ (mem_insert_of_mem hx) _ (mem_insert_of_mem hy),
  have ∀y∈s, x ≠ y,
    from assume _ hy h, by rw [←h] at hy; contradiction,
  have ∀y∈s, disjoint (t x) (t y),
    from assume _ hy, hd _ (mem_insert_self _ _) _ (mem_insert_of_mem hy) (this _ hy),
  have disjoint (t x) (finset.bind s t),
    from (disjoint_bind_right _ _ _).mpr this,
  by simp only [bind_insert, prod_insert hxs, prod_union this, ih hd'])

@[to_additive]
lemma prod_product {s : finset γ} {t : finset α} {f : γ×α → β} :
  (s.product t).prod f = s.prod (λx, t.prod $ λy, f (x, y)) :=
begin
  haveI := classical.dec_eq α, haveI := classical.dec_eq γ,
  rw [product_eq_bind, prod_bind],
  { congr, funext, exact prod_image (λ _ _ _ _ H, (prod.mk.inj H).2) },
  simp only [disjoint_iff_ne, mem_image],
  rintros _ _ _ _ h ⟨_, _⟩ ⟨_, _, ⟨_, _⟩⟩ ⟨_, _⟩ ⟨_, _, ⟨_, _⟩⟩ _,
  apply h, cc
end

@[to_additive]
lemma prod_sigma {σ : α → Type*}
  {s : finset α} {t : Πa, finset (σ a)} {f : sigma σ → β} :
  (s.sigma t).prod f = s.prod (λa, (t a).prod $ λs, f ⟨a, s⟩) :=
by haveI := classical.dec_eq α; haveI := (λ a, classical.dec_eq (σ a)); exact
calc (s.sigma t).prod f =
       (s.bind (λa, (t a).image (λs, sigma.mk a s))).prod f : by rw sigma_eq_bind
  ... = s.prod (λa, ((t a).image (λs, sigma.mk a s)).prod f) :
    prod_bind $ assume a₁ ha a₂ ha₂ h,
    by simp only [disjoint_iff_ne, mem_image];
    rintro ⟨_, _⟩ ⟨_, _, _⟩ ⟨_, _⟩ ⟨_, _, _⟩ ⟨_, _⟩; apply h; cc
  ... = (s.prod $ λa, (t a).prod $ λs, f ⟨a, s⟩) :
    prod_congr rfl $ λ _ _, prod_image $ λ _ _ _ _ _, by cc

@[to_additive]
lemma prod_image' [decidable_eq α] {s : finset γ} {g : γ → α} (h : γ → β)
  (eq : ∀c∈s, f (g c) = (s.filter (λc', g c' = g c)).prod h) :
  (s.image g).prod f = s.prod h :=
begin
  letI := classical.dec_eq γ,
  rw [← image_bind_filter_eq s g] {occs := occurrences.pos [2]},
  rw [finset.prod_bind],
  { refine finset.prod_congr rfl (assume a ha, _),
    rcases finset.mem_image.1 ha with ⟨b, hb, rfl⟩,
    exact eq b hb },
  assume a₀ _ a₁ _ ne,
  refine (disjoint_iff_ne.2 _),
  assume c₀ h₀ c₁ h₁,
  rcases mem_filter.1 h₀ with ⟨h₀, rfl⟩,
  rcases mem_filter.1 h₁ with ⟨h₁, rfl⟩,
  exact mt (congr_arg g) ne
end

@[to_additive]
lemma prod_mul_distrib : s.prod (λx, f x * g x) = s.prod f * s.prod g :=
eq.trans (by rw one_mul; refl) fold_op_distrib

@[to_additive]
lemma prod_comm [decidable_eq γ] {s : finset γ} {t : finset α} {f : γ → α → β} :
  s.prod (λx, t.prod $ f x) = t.prod (λy, s.prod $ λx, f x y) :=
finset.induction_on s (by simp only [prod_empty, prod_const_one]) $
λ _ _ H ih, by simp only [prod_insert H, prod_mul_distrib, ih]

@[to_additive]
lemma prod_hom [comm_monoid γ] (s : finset α) {f : α → β} (g : β → γ) [is_monoid_hom g] :
  s.prod (λx, g (f x)) = g (s.prod f) :=
by { delta finset.prod, rw [← multiset.map_map, multiset.prod_hom _ g] }

@[to_additive]
lemma prod_hom_rel [comm_monoid γ] {r : β → γ → Prop} {f : α → β} {g : α → γ} {s : finset α}
  (h₁ : r 1 1) (h₂ : ∀a b c, r b c → r (f a * b) (g a * c)) : r (s.prod f) (s.prod g) :=
by { delta finset.prod, apply multiset.prod_hom_rel; assumption }

@[to_additive]
lemma prod_subset (h : s₁ ⊆ s₂) (hf : ∀x∈s₂, x ∉ s₁ → f x = 1) : s₁.prod f = s₂.prod f :=
by haveI := classical.dec_eq α; exact
have (s₂ \ s₁).prod f = (s₂ \ s₁).prod (λx, 1),
  from prod_congr rfl $ by simpa only [mem_sdiff, and_imp],
by rw [←prod_sdiff h]; simp only [this, prod_const_one, one_mul]

-- If we use `[decidable_eq β]` here, some rewrites fail because they find a wrong `decidable`
-- instance first; `{∀x, decidable (f x ≠ 1)}` doesn't work with `rw ← prod_filter_ne_one`
@[to_additive]
lemma prod_filter_ne_one [∀ x, decidable (f x ≠ 1)] : (s.filter $ λx, f x ≠ 1).prod f = s.prod f :=
prod_subset (filter_subset _) $ λ x,
  by { classical, rw [not_imp_comm, mem_filter], exact and.intro }

@[to_additive]
lemma prod_filter (p : α → Prop) [decidable_pred p] (f : α → β) :
  (s.filter p).prod f = s.prod (λa, if p a then f a else 1) :=
calc (s.filter p).prod f = (s.filter p).prod (λa, if p a then f a else 1) :
    prod_congr rfl (assume a h, by rw [if_pos (mem_filter.1 h).2])
  ... = s.prod (λa, if p a then f a else 1) :
    begin
      refine prod_subset (filter_subset s) (assume x hs h, _),
      rw [mem_filter, not_and] at h,
      exact if_neg (h hs)
    end

@[to_additive]
lemma prod_eq_single {s : finset α} {f : α → β} (a : α)
  (h₀ : ∀b∈s, b ≠ a → f b = 1) (h₁ : a ∉ s → f a = 1) : s.prod f = f a :=
by haveI := classical.dec_eq α;
from classical.by_cases
  (assume : a ∈ s,
    calc s.prod f = ({a} : finset α).prod f :
      begin
        refine (prod_subset _ _).symm,
        { intros _ H, rwa mem_singleton.1 H },
        { simpa only [mem_singleton] }
      end
      ... = f a : prod_singleton)
  (assume : a ∉ s,
    (prod_congr rfl $ λ b hb, h₀ b hb $ by rintro rfl; cc).trans $
      prod_const_one.trans (h₁ this).symm)

@[to_additive] lemma prod_ite [comm_monoid γ] {s : finset α}
  {p : α → Prop} {hp : decidable_pred p} (f g : α → γ) (h : γ → β) :
  s.prod (λ x, h (if p x then f x else g x)) =
  (s.filter p).prod (λ x, h (f x)) * (s.filter (λ x, ¬ p x)).prod (λ x, h (g x)) :=
by letI := classical.dec_eq α; exact
calc s.prod (λ x, h (if p x then f x else g x))
    = (s.filter p ∪ s.filter (λ x, ¬ p x)).prod (λ x, h (if p x then f x else g x)) :
  by rw [filter_union_filter_neg_eq]
... = (s.filter p).prod (λ x, h (if p x then f x else g x)) *
    (s.filter (λ x, ¬ p x)).prod (λ x, h (if p x then f x else g x)) :
  prod_union (by simp [disjoint_right] {contextual := tt})
... = (s.filter p).prod (λ x, h (f x)) * (s.filter (λ x, ¬ p x)).prod (λ x, h (g x)) :
  congr_arg2 _
    (prod_congr rfl (by simp {contextual := tt}))
    (prod_congr rfl (by simp {contextual := tt}))

@[simp, to_additive] lemma prod_ite_eq [decidable_eq α] (s : finset α) (a : α) (b : α → β) :
  s.prod (λ x, (ite (a = x) (b x) 1)) = ite (a ∈ s) (b a) 1 :=
begin
  rw ←finset.prod_filter,
  split_ifs;
  simp only [filter_eq, if_true, if_false, h, prod_empty, prod_singleton, insert_empty_eq_singleton],
end

/--
  When a product is taken over a conditional whose condition is an equality test on the index
  and whose alternative is 1, then the product's value is either the term at that index or `1`.

  The difference with `prod_ite_eq` is that the arguments to `eq` are swapped.
-/
@[simp, to_additive] lemma prod_ite_eq' [decidable_eq α] (s : finset α) (a : α) (b : α → β) :
  s.prod (λ x, (ite (x = a) (b x) 1)) = ite (a ∈ s) (b a) 1 :=
begin
  rw ←prod_ite_eq,
  congr, ext x,
  by_cases x = a; finish
end

@[to_additive]
lemma prod_attach {f : α → β} : s.attach.prod (λx, f x.val) = s.prod f :=
by haveI := classical.dec_eq α; exact
calc s.attach.prod (λx, f x.val) = ((s.attach).image subtype.val).prod f :
    by rw [prod_image]; exact assume x _ y _, subtype.eq
  ... = _ : by rw [attach_image_val]

@[to_additive]
lemma prod_bij {s : finset α} {t : finset γ} {f : α → β} {g : γ → β}
  (i : Πa∈s, γ) (hi : ∀a ha, i a ha ∈ t) (h : ∀a ha, f a = g (i a ha))
  (i_inj : ∀a₁ a₂ ha₁ ha₂, i a₁ ha₁ = i a₂ ha₂ → a₁ = a₂) (i_surj : ∀b∈t, ∃a ha, b = i a ha) :
  s.prod f = t.prod g :=
congr_arg multiset.prod
  (multiset.map_eq_map_of_bij_of_nodup f g s.2 t.2 i hi h i_inj i_surj)

@[to_additive]
lemma prod_bij_ne_one {s : finset α} {t : finset γ} {f : α → β} {g : γ → β}
  (i : Πa∈s, f a ≠ 1 → γ) (hi₁ : ∀a h₁ h₂, i a h₁ h₂ ∈ t)
  (hi₂ : ∀a₁ a₂ h₁₁ h₁₂ h₂₁ h₂₂, i a₁ h₁₁ h₁₂ = i a₂ h₂₁ h₂₂ → a₁ = a₂)
  (hi₃ : ∀b∈t, g b ≠ 1 → ∃a h₁ h₂, b = i a h₁ h₂)
  (h : ∀a h₁ h₂, f a = g (i a h₁ h₂)) :
  s.prod f = t.prod g :=
by classical; exact
calc s.prod f = (s.filter $ λx, f x ≠ 1).prod f : prod_filter_ne_one.symm
  ... = (t.filter $ λx, g x ≠ 1).prod g :
    prod_bij (assume a ha, i a (mem_filter.mp ha).1 (mem_filter.mp ha).2)
      (assume a ha, (mem_filter.mp ha).elim $ λh₁ h₂, mem_filter.mpr
        ⟨hi₁ a h₁ h₂, λ hg, h₂ (hg ▸ h a h₁ h₂)⟩)
      (assume a ha, (mem_filter.mp ha).elim $ h a)
      (assume a₁ a₂ ha₁ ha₂,
        (mem_filter.mp ha₁).elim $ λha₁₁ ha₁₂, (mem_filter.mp ha₂).elim $ λha₂₁ ha₂₂, hi₂ a₁ a₂ _ _ _ _)
      (assume b hb, (mem_filter.mp hb).elim $ λh₁ h₂,
        let ⟨a, ha₁, ha₂, eq⟩ := hi₃ b h₁ h₂ in ⟨a, mem_filter.mpr ⟨ha₁, ha₂⟩, eq⟩)
  ... = t.prod g : prod_filter_ne_one

@[to_additive]
lemma nonempty_of_prod_ne_one (h : s.prod f ≠ 1) : s.nonempty :=
s.eq_empty_or_nonempty.elim (λ H, false.elim $ h $ H.symm ▸ prod_empty) id

@[to_additive]
lemma exists_ne_one_of_prod_ne_one (h : s.prod f ≠ 1) : ∃a∈s, f a ≠ 1 :=
begin
  classical,
  rw ← prod_filter_ne_one at h,
  rcases nonempty_of_prod_ne_one h with ⟨x, hx⟩,
  exact ⟨x, (mem_filter.1 hx).1, (mem_filter.1 hx).2⟩
end

@[to_additive]
lemma prod_range_succ (f : ℕ → β) (n : ℕ) :
  (range (nat.succ n)).prod f = f n * (range n).prod f :=
by rw [range_succ, prod_insert not_mem_range_self]

lemma prod_range_succ' (f : ℕ → β) :
  ∀ n : ℕ, (range (nat.succ n)).prod f = (range n).prod (f ∘ nat.succ) * f 0
| 0       := (prod_range_succ _ _).trans $ mul_comm _ _
| (n + 1) := by rw [prod_range_succ (λ m, f (nat.succ m)), mul_assoc, ← prod_range_succ'];
                 exact prod_range_succ _ _

lemma sum_Ico_add {δ : Type*} [add_comm_monoid δ] (f : ℕ → δ) (m n k : ℕ) :
  (Ico m n).sum (λ l, f (k + l)) = (Ico (m + k) (n + k)).sum f :=
Ico.image_add m n k ▸ eq.symm $ sum_image $ λ x hx y hy h, nat.add_left_cancel h

@[to_additive]
lemma prod_Ico_add (f : ℕ → β) (m n k : ℕ) :
  (Ico m n).prod (λ l, f (k + l)) = (Ico (m + k) (n + k)).prod f :=
Ico.image_add m n k ▸ eq.symm $ prod_image $ λ x hx y hy h, nat.add_left_cancel h

lemma sum_Ico_succ_top {δ : Type*} [add_comm_monoid δ] {a b : ℕ}
  (hab : a ≤ b) (f : ℕ → δ) : (Ico a (b + 1)).sum f = (Ico a b).sum f + f b :=
by rw [Ico.succ_top hab, sum_insert Ico.not_mem_top, add_comm]

@[to_additive]
lemma prod_Ico_succ_top {a b : ℕ} (hab : a ≤ b) (f : ℕ → β) :
  (Ico a b.succ).prod f = (Ico a b).prod f * f b :=
@sum_Ico_succ_top (additive β) _ _ _ hab _

lemma sum_eq_sum_Ico_succ_bot {δ : Type*} [add_comm_monoid δ] {a b : ℕ}
  (hab : a < b) (f : ℕ → δ) : (Ico a b).sum f = f a + (Ico (a + 1) b).sum f :=
have ha : a ∉ Ico (a + 1) b, by simp,
by rw [← sum_insert ha, Ico.insert_succ_bot hab]

@[to_additive]
lemma prod_eq_prod_Ico_succ_bot {a b : ℕ} (hab : a < b) (f : ℕ → β) :
  (Ico a b).prod f = f a * (Ico (a + 1) b).prod f :=
@sum_eq_sum_Ico_succ_bot (additive β) _ _ _ hab _

@[to_additive]
lemma prod_Ico_consecutive (f : ℕ → β) {m n k : ℕ} (hmn : m ≤ n) (hnk : n ≤ k) :
  (Ico m n).prod f * (Ico n k).prod f = (Ico m k).prod f :=
Ico.union_consecutive hmn hnk ▸ eq.symm $ prod_union $ Ico.disjoint_consecutive m n k

@[to_additive]
lemma prod_range_mul_prod_Ico (f : ℕ → β) {m n : ℕ} (h : m ≤ n) :
  (range m).prod f * (Ico m n).prod f = (range n).prod f :=
Ico.zero_bot m ▸ Ico.zero_bot n ▸ prod_Ico_consecutive f (nat.zero_le m) h

@[to_additive sum_Ico_eq_add_neg]
lemma prod_Ico_eq_div {δ : Type*} [comm_group δ] (f : ℕ → δ) {m n : ℕ} (h : m ≤ n) :
  (Ico m n).prod f = (range n).prod f * ((range m).prod f)⁻¹ :=
eq_mul_inv_iff_mul_eq.2 $ by rw [mul_comm]; exact prod_range_mul_prod_Ico f h

lemma sum_Ico_eq_sub {δ : Type*} [add_comm_group δ] (f : ℕ → δ) {m n : ℕ} (h : m ≤ n) :
  (Ico m n).sum f = (range n).sum f - (range m).sum f :=
sum_Ico_eq_add_neg f h

@[to_additive]
lemma prod_Ico_eq_prod_range (f : ℕ → β) (m n : ℕ) :
  (Ico m n).prod f = (range (n - m)).prod (λ l, f (m + l)) :=
begin
  by_cases h : m ≤ n,
  { rw [← Ico.zero_bot, prod_Ico_add, zero_add, nat.sub_add_cancel h] },
  { replace h : n ≤ m :=  le_of_not_ge h,
     rw [Ico.eq_empty_of_le h, nat.sub_eq_zero_of_le h, range_zero, prod_empty, prod_empty] }
end

@[to_additive]
lemma prod_range_zero (f : ℕ → β) :
 (range 0).prod f = 1 :=
by rw [range_zero, prod_empty]

lemma prod_range_one (f : ℕ → β) :
  (range 1).prod f = f 0 :=
by { rw [range_one], apply @prod_singleton ℕ β 0 f }

lemma sum_range_one {δ : Type*} [add_comm_monoid δ] (f : ℕ → δ) :
  (range 1).sum f = f 0 :=
by { rw [range_one], apply @sum_singleton ℕ δ 0 f }

attribute [to_additive finset.sum_range_one] prod_range_one

@[simp] lemma prod_const (b : β) : s.prod (λ a, b) = b ^ s.card :=
by haveI := classical.dec_eq α; exact
finset.induction_on s rfl (λ a s has ih,
by rw [prod_insert has, card_insert_of_not_mem has, pow_succ, ih])

lemma prod_pow (s : finset α) (n : ℕ) (f : α → β) :
  s.prod (λ x, f x ^ n) = s.prod f ^ n :=
by haveI := classical.dec_eq α; exact
finset.induction_on s (by simp) (by simp [_root_.mul_pow] {contextual := tt})

lemma prod_nat_pow (s : finset α) (n : ℕ) (f : α → ℕ) :
  s.prod (λ x, f x ^ n) = s.prod f ^ n :=
by haveI := classical.dec_eq α; exact
finset.induction_on s (by simp) (by simp [nat.mul_pow] {contextual := tt})

@[to_additive]
lemma prod_involution {s : finset α} {f : α → β} :
  ∀ (g : Π a ∈ s, α)
  (h₁ : ∀ a ha, f a * f (g a ha) = 1)
  (h₂ : ∀ a ha, f a ≠ 1 → g a ha ≠ a)
  (h₃ : ∀ a ha, g a ha ∈ s)
  (h₄ : ∀ a ha, g (g a ha) (h₃ a ha) = a),
  s.prod f = 1 :=
by haveI := classical.dec_eq α;
haveI := classical.dec_eq β; exact
finset.strong_induction_on s
  (λ s ih g h₁ h₂ h₃ h₄,
    s.eq_empty_or_nonempty.elim (λ hs, hs.symm ▸ rfl)
      (λ ⟨x, hx⟩,
      have hmem : ∀ y ∈ (s.erase x).erase (g x hx), y ∈ s,
        from λ y hy, (mem_of_mem_erase (mem_of_mem_erase hy)),
      have g_inj : ∀ {x hx y hy}, g x hx = g y hy → x = y,
        from λ x hx y hy h, by rw [← h₄ x hx, ← h₄ y hy]; simp [h],
      have ih': (erase (erase s x) (g x hx)).prod f = (1 : β) :=
        ih ((s.erase x).erase (g x hx))
          ⟨subset.trans (erase_subset _ _) (erase_subset _ _),
            λ h, not_mem_erase (g x hx) (s.erase x) (h (h₃ x hx))⟩
          (λ y hy, g y (hmem y hy))
          (λ y hy, h₁ y (hmem y hy))
          (λ y hy, h₂ y (hmem y hy))
          (λ y hy, mem_erase.2 ⟨λ (h : g y _ = g x hx), by simpa [g_inj h] using hy,
            mem_erase.2 ⟨λ (h : g y _ = x),
              have y = g x hx, from h₄ y (hmem y hy) ▸ by simp [h],
              by simpa [this] using hy, h₃ y (hmem y hy)⟩⟩)
          (λ y hy, h₄ y (hmem y hy)),
      if hx1 : f x = 1
      then ih' ▸ eq.symm (prod_subset hmem
        (λ y hy hy₁,
          have y = x ∨ y = g x hx, by simp [hy] at hy₁; tauto,
          this.elim (λ h, h.symm ▸ hx1)
            (λ h, h₁ x hx ▸ h ▸ hx1.symm ▸ (one_mul _).symm)))
      else by rw [← insert_erase hx, prod_insert (not_mem_erase _ _),
        ← insert_erase (mem_erase.2 ⟨h₂ x hx hx1, h₃ x hx⟩),
        prod_insert (not_mem_erase _ _), ih', mul_one, h₁ x hx]))

@[to_additive]
lemma prod_eq_one {f : α → β} {s : finset α} (h : ∀x∈s, f x = 1) : s.prod f = 1 :=
calc s.prod f = s.prod (λx, 1) : finset.prod_congr rfl h
  ... = 1 : finset.prod_const_one

/-- A product over all subsets of `s ∪ {x}` is obtained by multiplying the product over all subsets
of `s`, and over all subsets of `s` to which one adds `x`. -/
@[to_additive]
lemma prod_powerset_insert [decidable_eq α] {s : finset α} {x : α} (h : x ∉ s) (f : finset α → β) :
  (insert x s).powerset.prod f = s.powerset.prod f * s.powerset.prod (λt, f (insert x t)) :=
begin
  rw [powerset_insert, finset.prod_union, finset.prod_image],
  { assume t₁ h₁ t₂ h₂ heq,
    rw [← finset.erase_insert (not_mem_of_mem_powerset_of_not_mem h₁ h),
        ← finset.erase_insert (not_mem_of_mem_powerset_of_not_mem h₂ h), heq] },
  { rw finset.disjoint_iff_ne,
    assume t₁ h₁ t₂ h₂,
    rcases finset.mem_image.1 h₂ with ⟨t₃, h₃, H₃₂⟩,
    rw ← H₃₂,
    exact ne_insert_of_not_mem _ _ (not_mem_of_mem_powerset_of_not_mem h₁ h) }
end

@[to_additive]
lemma prod_piecewise [decidable_eq α] (s t : finset α) (f g : α → β) :
  s.prod (t.piecewise f g) = (s ∩ t).prod f * (s \ t).prod g :=
by { rw [piecewise, prod_ite _ _ (λ x, x), filter_mem_eq_inter, ← sdiff_eq_filter], assumption }

/-- If we can partition a product into subsets that cancel out, then the whole product cancels. -/
@[to_additive]
lemma prod_cancels_of_partition_cancels (R : setoid α) [decidable_rel R.r]
  (h : ∀ x ∈ s, (s.filter (λy, y ≈ x)).prod f = 1) : s.prod f = 1 :=
begin
  suffices : (s.image quotient.mk).prod (λ xbar, (s.filter (λ y, ⟦y⟧ = xbar)).prod f) = s.prod f,
  { rw [←this, ←finset.prod_eq_one],
    intros xbar xbar_in_s,
    rcases (mem_image).mp xbar_in_s with ⟨x, x_in_s, xbar_eq_x⟩,
    rw [←xbar_eq_x, filter_congr (λ y _, @quotient.eq _ R y x)],
    apply h x x_in_s },
  apply finset.prod_image' f,
  intros,
  refl
end

@[to_additive]
lemma prod_update_of_not_mem [decidable_eq α] {s : finset α} {i : α}
  (h : i ∉ s) (f : α → β) (b : β) : s.prod (function.update f i b) = s.prod f :=
begin
  apply prod_congr rfl (λj hj, _),
  have : j ≠ i, by { assume eq, rw eq at hj, exact h hj },
  simp [this]
end

lemma prod_update_of_mem [decidable_eq α] {s : finset α} {i : α} (h : i ∈ s) (f : α → β) (b : β) :
  s.prod (function.update f i b) = b * (s \ (singleton i)).prod f :=
by { rw [update_eq_piecewise, prod_piecewise], simp [h] }

end comm_monoid

lemma sum_update_of_mem [add_comm_monoid β] [decidable_eq α] {s : finset α} {i : α}
  (h : i ∈ s) (f : α → β) (b : β) :
  s.sum (function.update f i b) = b + (s \ (singleton i)).sum f :=
by { rw [update_eq_piecewise, sum_piecewise], simp [h] }
attribute [to_additive] prod_update_of_mem

lemma sum_smul' [add_comm_monoid β] (s : finset α) (n : ℕ) (f : α → β) :
  s.sum (λ x, add_monoid.smul n (f x)) = add_monoid.smul n (s.sum f) :=
@prod_pow _ (multiplicative β) _ _ _ _
attribute [to_additive sum_smul'] prod_pow

@[simp] lemma sum_const [add_comm_monoid β] (b : β) :
  s.sum (λ a, b) = add_monoid.smul s.card b :=
@prod_const _ (multiplicative β) _ _ _
attribute [to_additive] prod_const

lemma sum_range_succ' [add_comm_monoid β] (f : ℕ → β) :
  ∀ n : ℕ, (range (nat.succ n)).sum f = (range n).sum (f ∘ nat.succ) + f 0 :=
@prod_range_succ' (multiplicative β) _ _
attribute [to_additive] prod_range_succ'

lemma sum_nat_cast [add_comm_monoid β] [has_one β] (s : finset α) (f : α → ℕ) :
  ↑(s.sum f) = s.sum (λa, f a : α → β) :=
(s.sum_hom _).symm

lemma prod_nat_cast [comm_semiring β] (s : finset α) (f : α → ℕ) :
  ↑(s.prod f) = s.prod (λa, f a : α → β) :=
(s.prod_hom _).symm

protected lemma sum_nat_coe_enat [decidable_eq α] (s : finset α) (f : α → ℕ) :
  s.sum (λ x, (f x : enat)) = (s.sum f : ℕ) :=
begin
  induction s using finset.induction with a s has ih h,
  { simp },
  { simp [has, ih] }
end

theorem dvd_sum [comm_semiring α] {a : α} {s : finset β} {f : β → α}
  (h : ∀ x ∈ s, a ∣ f x) : a ∣ s.sum f :=
multiset.dvd_sum (λ y hy, by rcases multiset.mem_map.1 hy with ⟨x, hx, rfl⟩; exact h x hx)

lemma le_sum_of_subadditive [add_comm_monoid α] [ordered_comm_monoid β]
  (f : α → β) (h_zero : f 0 = 0) (h_add : ∀x y, f (x + y) ≤ f x + f y) (s : finset γ) (g : γ → α) :
  f (s.sum g) ≤ s.sum (λc, f (g c)) :=
begin
  refine le_trans (multiset.le_sum_of_subadditive f h_zero h_add _) _,
  rw [multiset.map_map],
  refl
end

lemma abs_sum_le_sum_abs [discrete_linear_ordered_field α] {f : β → α} {s : finset β} :
  abs (s.sum f) ≤ s.sum (λa, abs (f a)) :=
le_sum_of_subadditive _ abs_zero abs_add s f

section comm_group
variables [comm_group β]

@[simp, to_additive]
lemma prod_inv_distrib : s.prod (λx, (f x)⁻¹) = (s.prod f)⁻¹ :=
s.prod_hom has_inv.inv

end comm_group

@[simp] theorem card_sigma {σ : α → Type*} (s : finset α) (t : Π a, finset (σ a)) :
  card (s.sigma t) = s.sum (λ a, card (t a)) :=
multiset.card_sigma _ _

lemma card_bind [decidable_eq β] {s : finset α} {t : α → finset β}
  (h : ∀ x ∈ s, ∀ y ∈ s, x ≠ y → disjoint (t x) (t y)) :
  (s.bind t).card = s.sum (λ u, card (t u)) :=
calc (s.bind t).card = (s.bind t).sum (λ _, 1) : by simp
... = s.sum (λ a, (t a).sum (λ _, 1)) : finset.sum_bind h
... = s.sum (λ u, card (t u)) : by simp

lemma card_bind_le [decidable_eq β] {s : finset α} {t : α → finset β} :
  (s.bind t).card ≤ s.sum (λ a, (t a).card) :=
by haveI := classical.dec_eq α; exact
finset.induction_on s (by simp)
  (λ a s has ih,
    calc ((insert a s).bind t).card ≤ (t a).card + (s.bind t).card :
    by rw bind_insert; exact finset.card_union_le _ _
    ... ≤ (insert a s).sum (λ a, card (t a)) :
    by rw sum_insert has; exact add_le_add_left ih _)

theorem card_eq_sum_card_image [decidable_eq β] (f : α → β) (s : finset α) :
  s.card = (s.image f).sum (λ a, (s.filter (λ x, f x = a)).card) :=
by letI := classical.dec_eq α; exact
calc s.card = ((s.image f).bind (λ a, s.filter (λ x, f x = a))).card :
  congr_arg _ (finset.ext.2 $ λ x,
    ⟨λ hs, mem_bind.2 ⟨f x, mem_image_of_mem _ hs,
      mem_filter.2 ⟨hs, rfl⟩⟩,
    λ h, let ⟨a, ha₁, ha₂⟩ := mem_bind.1 h in by convert filter_subset s ha₂⟩)
... = (s.image f).sum (λ a, (s.filter (λ x, f x = a)).card) :
  card_bind (by simp [disjoint_left, finset.ext] {contextual := tt})

lemma gsmul_sum [add_comm_group β] {f : α → β} {s : finset α} (z : ℤ) :
  gsmul z (s.sum f) = s.sum (λa, gsmul z (f a)) :=
(s.sum_hom (gsmul z)).symm

end finset

namespace finset
variables {s s₁ s₂ : finset α} {f g : α → β} {b : β} {a : α}

@[simp] lemma sum_sub_distrib [add_comm_group β] : s.sum (λx, f x - g x) = s.sum f - s.sum g :=
sum_add_distrib.trans $ congr_arg _ sum_neg_distrib

section semiring
variables [semiring β]

lemma sum_mul : s.sum f * b = s.sum (λx, f x * b) :=
(s.sum_hom (λ x, x * b)).symm

lemma mul_sum : b * s.sum f = s.sum (λx, b * f x) :=
(s.sum_hom _).symm

@[simp] lemma sum_mul_boole [decidable_eq α] (s : finset α) (f : α → β) (a : α) :
  s.sum (λ x, (f x * ite (a = x) 1 0)) = ite (a ∈ s) (f a) 0 :=
begin
  convert sum_ite_eq s a f,
  funext,
  split_ifs with h; simp [h],
end
@[simp] lemma sum_boole_mul [decidable_eq α] (s : finset α) (f : α → β) (a : α) :
  s.sum (λ x, (ite (a = x) 1 0) * f x) = ite (a ∈ s) (f a) 0 :=
begin
  convert sum_ite_eq s a f,
  funext,
  split_ifs with h; simp [h],
end

end semiring

section comm_semiring
variables [decidable_eq α] [comm_semiring β]

lemma prod_eq_zero (ha : a ∈ s) (h : f a = 0) : s.prod f = 0 :=
calc s.prod f = (insert a (erase s a)).prod f : by rw insert_erase ha
  ... = 0 : by rw [prod_insert (not_mem_erase _ _), h, zero_mul]

lemma prod_sum {δ : α → Type*} [∀a, decidable_eq (δ a)]
  {s : finset α} {t : Πa, finset (δ a)} {f : Πa, δ a → β} :
  s.prod (λa, (t a).sum (λb, f a b)) =
    (s.pi t).sum (λp, s.attach.prod (λx, f x.1 (p x.1 x.2))) :=
begin
  induction s using finset.induction with a s ha ih,
  { rw [pi_empty, sum_singleton], refl },
  { have h₁ : ∀x ∈ t a, ∀y ∈ t a, ∀h : x ≠ y,
        disjoint (image (pi.cons s a x) (pi s t)) (image (pi.cons s a y) (pi s t)),
    { assume x hx y hy h,
      simp only [disjoint_iff_ne, mem_image],
      rintros _ ⟨p₂, hp, eq₂⟩ _ ⟨p₃, hp₃, eq₃⟩ eq,
      have : pi.cons s a x p₂ a (mem_insert_self _ _) = pi.cons s a y p₃ a (mem_insert_self _ _),
      { rw [eq₂, eq₃, eq] },
      rw [pi.cons_same, pi.cons_same] at this,
      exact h this },
    rw [prod_insert ha, pi_insert ha, ih, sum_mul, sum_bind h₁],
    refine sum_congr rfl (λ b _, _),
    have h₂ : ∀p₁∈pi s t, ∀p₂∈pi s t, pi.cons s a b p₁ = pi.cons s a b p₂ → p₁ = p₂, from
      assume p₁ h₁ p₂ h₂ eq, injective_pi_cons ha eq,
    rw [sum_image h₂, mul_sum],
    refine sum_congr rfl (λ g _, _),
    rw [attach_insert, prod_insert, prod_image],
    { simp only [pi.cons_same],
      congr', ext ⟨v, hv⟩, congr',
      exact (pi.cons_ne (by rintro rfl; exact ha hv)).symm },
    { exact λ _ _ _ _, subtype.eq ∘ subtype.mk.inj },
    { simp only [mem_image], rintro ⟨⟨_, hm⟩, _, rfl⟩, exact ha hm } }
end

end comm_semiring

section integral_domain /- add integral_semi_domain to support nat and ennreal -/
variables [decidable_eq α] [integral_domain β]

lemma prod_eq_zero_iff : s.prod f = 0 ↔ (∃a∈s, f a = 0) :=
finset.induction_on s ⟨not.elim one_ne_zero, λ ⟨_, H, _⟩, H.elim⟩ $ λ a s ha ih,
by rw [prod_insert ha, mul_eq_zero_iff_eq_zero_or_eq_zero,
  bex_def, exists_mem_insert, ih, ← bex_def]

end integral_domain

section ordered_comm_monoid
variables [decidable_eq α] [ordered_comm_monoid β]

lemma sum_le_sum : (∀x∈s, f x ≤ g x) → s.sum f ≤ s.sum g :=
finset.induction_on s (λ _, le_refl _) $ assume a s ha ih h,
  have f a + s.sum f ≤ g a + s.sum g,
    from add_le_add' (h _ (mem_insert_self _ _)) (ih $ assume x hx, h _ $ mem_insert_of_mem hx),
  by simpa only [sum_insert ha]

lemma sum_nonneg (h : ∀x∈s, 0 ≤ f x) : 0 ≤ s.sum f := le_trans (by rw [sum_const_zero]) (sum_le_sum h)

lemma sum_nonpos (h : ∀x∈s, f x ≤ 0) : s.sum f ≤ 0 := le_trans (sum_le_sum h) (by rw [sum_const_zero])

lemma sum_le_sum_of_subset_of_nonneg
  (h : s₁ ⊆ s₂) (hf : ∀x∈s₂, x ∉ s₁ → 0 ≤ f x) : s₁.sum f ≤ s₂.sum f :=
calc s₁.sum f ≤ (s₂ \ s₁).sum f + s₁.sum f :
    le_add_of_nonneg_left' $ sum_nonneg $ by simpa only [mem_sdiff, and_imp]
  ... = (s₂ \ s₁ ∪ s₁).sum f : (sum_union sdiff_disjoint).symm
  ... = s₂.sum f : by rw [sdiff_union_of_subset h]

lemma sum_eq_zero_iff_of_nonneg : (∀x∈s, 0 ≤ f x) → (s.sum f = 0 ↔ ∀x∈s, f x = 0) :=
finset.induction_on s (λ _, ⟨λ _ _, false.elim, λ _, rfl⟩) $ λ a s ha ih H,
have ∀ x ∈ s, 0 ≤ f x, from λ _, H _ ∘ mem_insert_of_mem,
by rw [sum_insert ha,
  add_eq_zero_iff' (H _ $ mem_insert_self _ _) (sum_nonneg this),
  forall_mem_insert, ih this]

lemma sum_eq_zero_iff_of_nonpos : (∀x∈s, f x ≤ 0) → (s.sum f = 0 ↔ ∀x∈s, f x = 0) :=
@sum_eq_zero_iff_of_nonneg _ (order_dual β) _ _ _ _

lemma single_le_sum (hf : ∀x∈s, 0 ≤ f x) {a} (h : a ∈ s) : f a ≤ s.sum f :=
have (singleton a).sum f ≤ s.sum f,
  from sum_le_sum_of_subset_of_nonneg
  (λ x e, (mem_singleton.1 e).symm ▸ h) (λ x h _, hf x h),
by rwa sum_singleton at this

end ordered_comm_monoid

section canonically_ordered_monoid
variables [decidable_eq α] [canonically_ordered_monoid β]

lemma sum_le_sum_of_subset (h : s₁ ⊆ s₂) : s₁.sum f ≤ s₂.sum f :=
sum_le_sum_of_subset_of_nonneg h $ assume x h₁ h₂, zero_le _

lemma sum_le_sum_of_ne_zero [@decidable_rel β (≤)] (h : ∀x∈s₁, f x ≠ 0 → x ∈ s₂) :
  s₁.sum f ≤ s₂.sum f :=
calc s₁.sum f = (s₁.filter (λx, f x = 0)).sum f + (s₁.filter (λx, f x ≠ 0)).sum f :
    by rw [←sum_union, filter_union_filter_neg_eq];
       exact disjoint_filter.2 (assume _ _ h n_h, n_h h)
  ... ≤ s₂.sum f : add_le_of_nonpos_of_le'
      (sum_nonpos $ by simp only [mem_filter, and_imp]; exact λ _ _, le_of_eq)
      (sum_le_sum_of_subset $ by simpa only [subset_iff, mem_filter, and_imp])

end canonically_ordered_monoid

section ordered_cancel_comm_monoid

variables [ordered_cancel_comm_monoid β]

theorem sum_lt_sum (Hle : ∀ i ∈ s, f i ≤ g i) (Hlt : ∃ i ∈ s, f i < g i) :
  s.sum f < s.sum g :=
begin
  classical,
  rcases Hlt with ⟨i, hi, hlt⟩,
  rw [← insert_erase hi, sum_insert (not_mem_erase _ _), sum_insert (not_mem_erase _ _)],
  exact add_lt_add_of_lt_of_le hlt (sum_le_sum $ λ j hj, Hle j  $ mem_of_mem_erase hj)
end

end ordered_cancel_comm_monoid

section decidable_linear_ordered_cancel_comm_monoid

variables [decidable_linear_ordered_cancel_comm_monoid β]

theorem exists_le_of_sum_le (hs : s.nonempty) (Hle : s.sum f ≤ s.sum g) :
  ∃ i ∈ s, f i ≤ g i :=
begin
  classical,
  contrapose! Hle with Hlt,
  rcases hs with ⟨i, hi⟩,
  exact sum_lt_sum (λ i hi, le_of_lt (Hlt i hi)) ⟨i, hi, Hlt i hi⟩
end

end decidable_linear_ordered_cancel_comm_monoid

section linear_ordered_comm_ring
variables [decidable_eq α] [linear_ordered_comm_ring β]

/- this is also true for a ordered commutative multiplicative monoid -/
lemma prod_nonneg {s : finset α} {f : α → β}
  (h0 : ∀(x ∈ s), 0 ≤ f x) : 0 ≤ s.prod f :=
begin
  induction s using finset.induction with a s has ih h,
  { simp [zero_le_one] },
  { simp [has], apply mul_nonneg, apply h0 a (mem_insert_self a s),
    exact ih (λ x H, h0 x (mem_insert_of_mem H)) }
end

/- this is also true for a ordered commutative multiplicative monoid -/
lemma prod_pos {s : finset α} {f : α → β} (h0 : ∀(x ∈ s), 0 < f x) : 0 < s.prod f :=
begin
  induction s using finset.induction with a s has ih h,
  { simp [zero_lt_one] },
  { simp [has], apply mul_pos, apply h0 a (mem_insert_self a s),
    exact ih (λ x H, h0 x (mem_insert_of_mem H)) }
end

/- this is also true for a ordered commutative multiplicative monoid -/
lemma prod_le_prod {s : finset α} {f g : α → β} (h0 : ∀(x ∈ s), 0 ≤ f x)
  (h1 : ∀(x ∈ s), f x ≤ g x) : s.prod f ≤ s.prod g :=
begin
  induction s using finset.induction with a s has ih h,
  { simp },
  { simp [has], apply mul_le_mul,
      exact h1 a (mem_insert_self a s),
      apply ih (λ x H, h0 _ _) (λ x H, h1 _ _); exact (mem_insert_of_mem H),
      apply prod_nonneg (λ x H, h0 x (mem_insert_of_mem H)),
      apply le_trans (h0 a (mem_insert_self a s)) (h1 a (mem_insert_self a s)) }
end

end linear_ordered_comm_ring

@[simp] lemma card_pi [decidable_eq α] {δ : α → Type*}
  (s : finset α) (t : Π a, finset (δ a)) :
  (s.pi t).card = s.prod (λ a, card (t a)) :=
multiset.card_pi _ _

theorem card_le_mul_card_image [decidable_eq β] {f : α → β} (s : finset α)
  (n : ℕ) (hn : ∀ a ∈ s.image f, (s.filter (λ x, f x = a)).card ≤ n) :
  s.card ≤ n * (s.image f).card :=
calc s.card = (s.image f).sum (λ a, (s.filter (λ x, f x = a)).card) :
  card_eq_sum_card_image _ _
... ≤ (s.image f).sum (λ _, n) : sum_le_sum hn
... = _ : by simp [mul_comm]

@[simp] lemma prod_Ico_id_eq_fact : ∀ n : ℕ, (Ico 1 n.succ).prod (λ x, x) = nat.fact n
| 0 := rfl
| (n+1) := by rw [prod_Ico_succ_top $ nat.succ_le_succ $ zero_le n,
  nat.fact_succ, prod_Ico_id_eq_fact n, nat.succ_eq_add_one, mul_comm]

end finset


namespace finset
section gauss_sum

/-- Gauss' summation formula -/
lemma sum_range_id_mul_two :
  ∀(n : ℕ), (finset.range n).sum (λi, i) * 2 = n * (n - 1)
| 0       := rfl
| 1       := rfl
| ((n + 1) + 1) :=
  begin
    rw [sum_range_succ, add_mul, sum_range_id_mul_two (n + 1), mul_comm, two_mul,
      nat.add_sub_cancel, nat.add_sub_cancel, mul_comm _ n],
    simp only [add_mul, one_mul, add_comm, add_assoc, add_left_comm]
  end

/-- Gauss' summation formula -/
lemma sum_range_id (n : ℕ) : (finset.range n).sum (λi, i) = (n * (n - 1)) / 2 :=
by rw [← sum_range_id_mul_two n, nat.mul_div_cancel]; exact dec_trivial

end gauss_sum

lemma card_eq_sum_ones (s : finset α) : s.card = s.sum (λ _, 1) :=
by simp

end finset

section group

open list
variables [group α] [group β]

theorem is_group_anti_hom.map_prod (f : α → β) [is_group_anti_hom f] (l : list α) :
  f (prod l) = prod (map f (reverse l)) :=
by induction l with hd tl ih; [exact is_group_anti_hom.map_one f,
  simp only [prod_cons, is_group_anti_hom.map_mul f, ih, reverse_cons, map_append, prod_append, map_singleton, prod_cons, prod_nil, mul_one]]

theorem inv_prod : ∀ l : list α, (prod l)⁻¹ = prod (map (λ x, x⁻¹) (reverse l)) :=
λ l, @is_group_anti_hom.map_prod _ _ _ _ _ inv_is_group_anti_hom l -- TODO there is probably a cleaner proof of this

end group

@[to_additive]
lemma monoid_hom.map_prod [comm_monoid β] [comm_monoid γ] (g : β →* γ) (f : α → β) (s : finset α) :
  g (s.prod f) = s.prod (λx, g (f x)) :=
(s.prod_hom g).symm


@[to_additive is_add_group_hom_finset_sum]
lemma is_group_hom_finset_prod {α β γ} [group α] [comm_group β] (s : finset γ)
  (f : γ → α → β) [∀c, is_group_hom (f c)] : is_group_hom (λa, s.prod (λc, f c a)) :=
{ map_mul := assume a b, by simp only [λc, is_mul_hom.map_mul (f c), finset.prod_mul_distrib] }

attribute [instance] is_group_hom_finset_prod is_add_group_hom_finset_sum

namespace multiset
variables [decidable_eq α]

@[simp] lemma to_finset_sum_count_eq (s : multiset α) :
  s.to_finset.sum (λa, s.count a) = s.card :=
multiset.induction_on s rfl
  (assume a s ih,
    calc (to_finset (a :: s)).sum (λx, count x (a :: s)) =
      (to_finset (a :: s)).sum (λx, (if x = a then 1 else 0) + count x s) :
        finset.sum_congr rfl $ λ _ _, by split_ifs;
        [simp only [h, count_cons_self, nat.one_add], simp only [count_cons_of_ne h, zero_add]]
      ... = card (a :: s) :
      begin
        by_cases a ∈ s.to_finset,
        { have : (to_finset s).sum (λx, ite (x = a) 1 0) = (finset.singleton a).sum (λx, ite (x = a) 1 0),
          { apply (finset.sum_subset _ _).symm,
            { intros _ H, rwa mem_singleton.1 H },
            { exact λ _ _ H, if_neg (mt finset.mem_singleton.2 H) } },
          rw [to_finset_cons, finset.insert_eq_of_mem h, finset.sum_add_distrib, ih, this, finset.sum_singleton, if_pos rfl, add_comm, card_cons] },
        { have ha : a ∉ s, by rwa mem_to_finset at h,
          have : (to_finset s).sum (λx, ite (x = a) 1 0) = (to_finset s).sum (λx, 0), from
            finset.sum_congr rfl (λ x hx, if_neg $ by rintro rfl; cc),
          rw [to_finset_cons, finset.sum_insert h, if_pos rfl, finset.sum_add_distrib, this, finset.sum_const_zero, ih, count_eq_zero_of_not_mem ha, zero_add, add_comm, card_cons] }
      end)

end multiset

namespace with_top
open finset
variables [decidable_eq α]

/-- sum of finte numbers is still finite -/
lemma sum_lt_top [ordered_comm_monoid β] {s : finset α} {f : α → with_top β} :
  (∀a∈s, f a < ⊤) → s.sum f < ⊤ :=
finset.induction_on s (by { intro h, rw sum_empty, exact coe_lt_top _ })
  (λa s ha ih h,
  begin
    rw [sum_insert ha, add_lt_top], split,
    { apply h, apply mem_insert_self },
    { apply ih, intros a ha, apply h, apply mem_insert_of_mem ha }
  end)

/-- sum of finte numbers is still finite -/
lemma sum_lt_top_iff [canonically_ordered_monoid β] {s : finset α} {f : α → with_top β} :
  s.sum f < ⊤ ↔ (∀a∈s, f a < ⊤) :=
iff.intro (λh a ha, lt_of_le_of_lt (single_le_sum (λa ha, zero_le _) ha) h) sum_lt_top

end with_top
