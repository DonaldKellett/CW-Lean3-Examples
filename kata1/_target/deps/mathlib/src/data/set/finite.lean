/-
Copyright (c) 2017 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl, Mario Carneiro

Finite sets.
-/
import logic.function
import data.nat.basic data.fintype data.set.lattice data.set.function

open set lattice function

universes u v w x
variables {α : Type u} {β : Type v} {ι : Sort w} {γ : Type x}

namespace set

/-- A set is finite if the subtype is a fintype, i.e. there is a
  list that enumerates its members. -/
def finite (s : set α) : Prop := nonempty (fintype s)

/-- A set is infinite if it is not finite. -/
def infinite (s : set α) : Prop := ¬ finite s

/-- The subtype corresponding to a finite set is a finite type. Note
that because `finite` isn't a typeclass, this will not fire if it
is made into an instance -/
noncomputable def finite.fintype {s : set α} (h : finite s) : fintype s :=
classical.choice h

/-- Get a finset from a finite set -/
noncomputable def finite.to_finset {s : set α} (h : finite s) : finset α :=
@set.to_finset _ _ (finite.fintype h)

@[simp] theorem finite.mem_to_finset {s : set α} {h : finite s} {a : α} : a ∈ h.to_finset ↔ a ∈ s :=
@mem_to_finset _ _ (finite.fintype h) _

lemma finite.coe_to_finset {α} {s : set α} (h : finite s) : ↑h.to_finset = s :=
by { ext, apply mem_to_finset }

theorem finite.exists_finset {s : set α} : finite s →
  ∃ s' : finset α, ∀ a : α, a ∈ s' ↔ a ∈ s
| ⟨h⟩ := by exactI ⟨to_finset s, λ _, mem_to_finset⟩

theorem finite.exists_finset_coe {s : set α} (hs : finite s) :
  ∃ s' : finset α, ↑s' = s :=
⟨hs.to_finset, hs.coe_to_finset⟩

/-- Finite sets can be lifted to finsets. -/
instance : can_lift (set α) (finset α) :=
{ coe := coe,
  cond := finite,
  prf := λ s hs, hs.exists_finset_coe }

theorem finite_mem_finset (s : finset α) : finite {a | a ∈ s} :=
⟨fintype.of_finset s (λ _, iff.rfl)⟩

theorem finite.of_fintype [fintype α] (s : set α) : finite s :=
by classical; exact ⟨set_fintype s⟩

/-- Membership of a subset of a finite type is decidable.

Using this as an instance leads to potential loops with `subtype.fintype` under certain decidability
assumptions, so it should only be declared a local instance. -/
def decidable_mem_of_fintype [decidable_eq α] (s : set α) [fintype s] (a) : decidable (a ∈ s) :=
decidable_of_iff _ mem_to_finset

instance fintype_empty : fintype (∅ : set α) :=
fintype.of_finset ∅ $ by simp

theorem empty_card : fintype.card (∅ : set α) = 0 := rfl

@[simp] theorem empty_card' {h : fintype.{u} (∅ : set α)} :
  @fintype.card (∅ : set α) h = 0 :=
eq.trans (by congr) empty_card

@[simp] theorem finite_empty : @finite α ∅ := ⟨set.fintype_empty⟩

def fintype_insert' {a : α} (s : set α) [fintype s] (h : a ∉ s) : fintype (insert a s : set α) :=
fintype.of_finset ⟨a :: s.to_finset.1,
  multiset.nodup_cons_of_nodup (by simp [h]) s.to_finset.2⟩ $ by simp

theorem card_fintype_insert' {a : α} (s : set α) [fintype s] (h : a ∉ s) :
  @fintype.card _ (fintype_insert' s h) = fintype.card s + 1 :=
by rw [fintype_insert', fintype.card_of_finset];
   simp [finset.card, to_finset]; refl

@[simp] theorem card_insert {a : α} (s : set α)
  [fintype s] (h : a ∉ s) {d : fintype.{u} (insert a s : set α)} :
  @fintype.card _ d = fintype.card s + 1 :=
by rw ← card_fintype_insert' s h; congr

lemma card_image_of_inj_on {s : set α} [fintype s]
  {f : α → β} [fintype (f '' s)] (H : ∀x∈s, ∀y∈s, f x = f y → x = y) :
  fintype.card (f '' s) = fintype.card s :=
by haveI := classical.prop_decidable; exact
calc fintype.card (f '' s) = (s.to_finset.image f).card : fintype.card_of_finset' _ (by simp)
... = s.to_finset.card : finset.card_image_of_inj_on
    (λ x hx y hy hxy, H x (mem_to_finset.1 hx) y (mem_to_finset.1 hy) hxy)
... = fintype.card s : (fintype.card_of_finset' _ (λ a, mem_to_finset)).symm

lemma card_image_of_injective (s : set α) [fintype s]
  {f : α → β} [fintype (f '' s)] (H : function.injective f) :
  fintype.card (f '' s) = fintype.card s :=
card_image_of_inj_on $ λ _ _ _ _ h, H h

section

local attribute [instance] decidable_mem_of_fintype

instance fintype_insert [decidable_eq α] (a : α) (s : set α) [fintype s] : fintype (insert a s : set α) :=
if h : a ∈ s then by rwa [insert_eq, union_eq_self_of_subset_left (singleton_subset_iff.2 h)]
else fintype_insert' _ h

end

@[simp] theorem finite_insert (a : α) {s : set α} : finite s → finite (insert a s)
| ⟨h⟩ := ⟨@set.fintype_insert _ (classical.dec_eq α) _ _ h⟩

lemma to_finset_insert [decidable_eq α] {a : α} {s : set α} (hs : finite s) :
  (finite_insert a hs).to_finset = insert a hs.to_finset :=
finset.ext.mpr $ by simp

@[elab_as_eliminator]
theorem finite.induction_on {C : set α → Prop} {s : set α} (h : finite s)
  (H0 : C ∅) (H1 : ∀ {a s}, a ∉ s → finite s → C s → C (insert a s)) : C s :=
let ⟨t⟩ := h in by exactI
match s.to_finset, @mem_to_finset _ s _ with
| ⟨l, nd⟩, al := begin
    change ∀ a, a ∈ l ↔ a ∈ s at al,
    clear _let_match _match t h, revert s nd al,
    refine multiset.induction_on l _ (λ a l IH, _); intros s nd al,
    { rw show s = ∅, from eq_empty_iff_forall_not_mem.2 (by simpa using al),
      exact H0 },
    { rw ← show insert a {x | x ∈ l} = s, from set.ext (by simpa using al),
      cases multiset.nodup_cons.1 nd with m nd',
      refine H1 _ ⟨finset.subtype.fintype ⟨l, nd'⟩⟩ (IH nd' (λ _, iff.rfl)),
      exact m }
  end
end

@[elab_as_eliminator]
theorem finite.dinduction_on {C : ∀s:set α, finite s → Prop} {s : set α} (h : finite s)
  (H0 : C ∅ finite_empty)
  (H1 : ∀ {a s}, a ∉ s → ∀h:finite s, C s h → C (insert a s) (finite_insert a h)) :
  C s h :=
have ∀h:finite s, C s h,
  from finite.induction_on h (assume h, H0) (assume a s has hs ih h, H1 has hs (ih _)),
this h

instance fintype_singleton (a : α) : fintype ({a} : set α) :=
fintype_insert' _ (not_mem_empty _)

@[simp] theorem card_singleton (a : α) :
  fintype.card ({a} : set α) = 1 :=
by rw [show fintype.card ({a} : set α) = _, from
    card_fintype_insert' ∅ (not_mem_empty a)]; refl

@[simp] theorem finite_singleton (a : α) : finite ({a} : set α) :=
⟨set.fintype_singleton _⟩

instance fintype_pure : ∀ a : α, fintype (pure a : set α) :=
set.fintype_singleton

theorem finite_pure (a : α) : finite (pure a : set α) :=
⟨set.fintype_pure a⟩

instance fintype_univ [fintype α] : fintype (@univ α) :=
fintype.of_equiv α $ (equiv.set.univ α).symm

theorem finite_univ [fintype α] : finite (@univ α) := ⟨set.fintype_univ⟩

theorem infinite_univ_iff : (@univ α).infinite ↔ _root_.infinite α :=
⟨λ h₁, ⟨λ h₂, h₁ $ @finite_univ α h₂⟩,
  λ ⟨h₁⟩ ⟨h₂⟩, h₁ $ @fintype.of_equiv _ _ h₂ $ equiv.set.univ _⟩

theorem infinite_univ [h : _root_.infinite α] : infinite (@univ α) :=
infinite_univ_iff.2 h

instance fintype_union [decidable_eq α] (s t : set α) [fintype s] [fintype t] : fintype (s ∪ t : set α) :=
fintype.of_finset (s.to_finset ∪ t.to_finset) $ by simp

theorem finite_union {s t : set α} : finite s → finite t → finite (s ∪ t)
| ⟨hs⟩ ⟨ht⟩ := ⟨@set.fintype_union _ (classical.dec_eq α) _ _ hs ht⟩

instance fintype_sep (s : set α) (p : α → Prop) [fintype s] [decidable_pred p] : fintype ({a ∈ s | p a} : set α) :=
fintype.of_finset (s.to_finset.filter p) $ by simp

instance fintype_inter (s t : set α) [fintype s] [decidable_pred t] : fintype (s ∩ t : set α) :=
set.fintype_sep s t

def fintype_subset (s : set α) {t : set α} [fintype s] [decidable_pred t] (h : t ⊆ s) : fintype t :=
by rw ← inter_eq_self_of_subset_right h; apply_instance

theorem finite_subset {s : set α} : finite s → ∀ {t : set α}, t ⊆ s → finite t
| ⟨hs⟩ t h := ⟨@set.fintype_subset _ _ _ hs (classical.dec_pred t) h⟩

instance fintype_image [decidable_eq β] (s : set α) (f : α → β) [fintype s] : fintype (f '' s) :=
fintype.of_finset (s.to_finset.image f) $ by simp

instance fintype_range [decidable_eq β] (f : α → β) [fintype α] : fintype (range f) :=
fintype.of_finset (finset.univ.image f) $ by simp [range]

theorem finite_range (f : α → β) [fintype α] : finite (range f) :=
by haveI := classical.dec_eq β; exact ⟨by apply_instance⟩

theorem finite_image {s : set α} (f : α → β) : finite s → finite (f '' s)
| ⟨h⟩ := ⟨@set.fintype_image _ _ (classical.dec_eq β) _ _ h⟩

instance fintype_map {α β} [decidable_eq β] :
  ∀ (s : set α) (f : α → β) [fintype s], fintype (f <$> s) := set.fintype_image

theorem finite_map {α β} {s : set α} :
  ∀ (f : α → β), finite s → finite (f <$> s) := finite_image

def fintype_of_fintype_image (s : set α)
  {f : α → β} {g} (I : is_partial_inv f g) [fintype (f '' s)] : fintype s :=
fintype.of_finset ⟨_, @multiset.nodup_filter_map β α g _
  (@injective_of_partial_inv_right _ _ f g I) (f '' s).to_finset.2⟩ $ λ a,
begin
  suffices : (∃ b x, f x = b ∧ g b = some a ∧ x ∈ s) ↔ a ∈ s,
  by simpa [exists_and_distrib_left.symm, and.comm, and.left_comm, and.assoc],
  rw exists_swap,
  suffices : (∃ x, x ∈ s ∧ g (f x) = some a) ↔ a ∈ s, {simpa [and.comm, and.left_comm, and.assoc]},
  simp [I _, (injective_of_partial_inv I).eq_iff]
end

theorem finite_of_finite_image_on {s : set α} {f : α → β} (hi : set.inj_on f s) :
  finite (f '' s) → finite s | ⟨h⟩ :=
⟨@fintype.of_injective _ _ h (λa:s, ⟨f a.1, mem_image_of_mem f a.2⟩) $
  assume a b eq, subtype.eq $ hi a.2 b.2 $ subtype.ext.1 eq⟩

theorem finite_image_iff_on {s : set α} {f : α → β} (hi : inj_on f s) :
  finite (f '' s) ↔ finite s :=
⟨finite_of_finite_image_on hi, finite_image _⟩

theorem finite_of_finite_image {s : set α} {f : α → β} (I : set.inj_on f s) :
  finite (f '' s) → finite s :=
finite_of_finite_image_on I

theorem finite_preimage {s : set β} {f : α → β}
  (I : set.inj_on f (f⁻¹' s)) (h : finite s) : finite (f ⁻¹' s) :=
finite_of_finite_image I (finite_subset h (image_preimage_subset f s))

instance fintype_Union [decidable_eq α] {ι : Type*} [fintype ι]
  (f : ι → set α) [∀ i, fintype (f i)] : fintype (⋃ i, f i) :=
fintype.of_finset (finset.univ.bind (λ i, (f i).to_finset)) $ by simp

theorem finite_Union {ι : Type*} [fintype ι] {f : ι → set α} (H : ∀i, finite (f i)) : finite (⋃ i, f i) :=
⟨@set.fintype_Union _ (classical.dec_eq α) _ _ _ (λ i, finite.fintype (H i))⟩

def fintype_bUnion [decidable_eq α] {ι : Type*} {s : set ι} [fintype s]
  (f : ι → set α) (H : ∀ i ∈ s, fintype (f i)) : fintype (⋃ i ∈ s, f i) :=
by rw bUnion_eq_Union; exact
@set.fintype_Union _ _ _ _ _ (by rintro ⟨i, hi⟩; exact H i hi)

instance fintype_bUnion' [decidable_eq α] {ι : Type*} {s : set ι} [fintype s]
  (f : ι → set α) [H : ∀ i, fintype (f i)] : fintype (⋃ i ∈ s, f i) :=
fintype_bUnion _ (λ i _, H i)

theorem finite_sUnion {s : set (set α)} (h : finite s) (H : ∀t∈s, finite t) : finite (⋃₀ s) :=
by rw sUnion_eq_Union; haveI := finite.fintype h;
   apply finite_Union; simpa using H

theorem finite_bUnion {α} {ι : Type*} {s : set ι} {f : ι → set α} :
  finite s → (∀i, finite (f i)) → finite (⋃ i∈s, f i)
| ⟨hs⟩ h := by rw [bUnion_eq_Union]; exactI finite_Union (λ i, h _)

theorem finite_bUnion' {α} {ι : Type*} {s : set ι} (f : ι → set α) :
  finite s → (∀i ∈ s, finite (f i)) → finite (⋃ i∈s, f i)
| ⟨hs⟩ h := by { rw [bUnion_eq_Union], exactI finite_Union (λ i, h i.1 i.2) }

instance fintype_lt_nat (n : ℕ) : fintype {i | i < n} :=
fintype.of_finset (finset.range n) $ by simp

instance fintype_le_nat (n : ℕ) : fintype {i | i ≤ n} :=
by simpa [nat.lt_succ_iff] using set.fintype_lt_nat (n+1)

lemma finite_le_nat (n : ℕ) : finite {i | i ≤ n} := ⟨set.fintype_le_nat _⟩

lemma finite_lt_nat (n : ℕ) : finite {i | i < n} := ⟨set.fintype_lt_nat _⟩

instance fintype_prod (s : set α) (t : set β) [fintype s] [fintype t] : fintype (set.prod s t) :=
fintype.of_finset (s.to_finset.product t.to_finset) $ by simp

lemma finite_prod {s : set α} {t : set β} : finite s → finite t → finite (set.prod s t)
| ⟨hs⟩ ⟨ht⟩ := by exactI ⟨set.fintype_prod s t⟩

def fintype_bind {α β} [decidable_eq β] (s : set α) [fintype s]
  (f : α → set β) (H : ∀ a ∈ s, fintype (f a)) : fintype (s >>= f) :=
set.fintype_bUnion _ H

instance fintype_bind' {α β} [decidable_eq β] (s : set α) [fintype s]
  (f : α → set β) [H : ∀ a, fintype (f a)] : fintype (s >>= f) :=
fintype_bind _ _ (λ i _, H i)

theorem finite_bind {α β} {s : set α} {f : α → set β} :
  finite s → (∀ a ∈ s, finite (f a)) → finite (s >>= f)
| ⟨hs⟩ H := ⟨@fintype_bind _ _ (classical.dec_eq β) _ hs _ (λ a ha, (H a ha).fintype)⟩

instance fintype_seq {α β : Type u} [decidable_eq β]
  (f : set (α → β)) (s : set α) [fintype f] [fintype s] :
  fintype (f <*> s) :=
by rw seq_eq_bind_map; apply set.fintype_bind'

theorem finite_seq {α β : Type u} {f : set (α → β)} {s : set α} :
  finite f → finite s → finite (f <*> s)
| ⟨hf⟩ ⟨hs⟩ := by { haveI := classical.dec_eq β, exactI ⟨set.fintype_seq _ _⟩ }

/-- There are finitely many subsets of a given finite set -/
lemma finite_subsets_of_finite {α : Type u} {a : set α} (h : finite a) : finite {b | b ⊆ a} :=
begin
  -- we just need to translate the result, already known for finsets,
  -- to the language of finite sets
  let s := coe '' ((finset.powerset (finite.to_finset h)).to_set),
  have : finite s := finite_image _ (finite_mem_finset _),
  have : {b | b ⊆ a} ⊆ s :=
  begin
    assume b hb,
    rw [set.mem_image],
    rw [set.mem_set_of_eq] at hb,
    let b' : finset α := finite.to_finset (finite_subset h hb),
    have : b' ∈ (finset.powerset (finite.to_finset h)).to_set :=
      show b' ∈ (finset.powerset (finite.to_finset h)),
        by simp [b', finset.subset_iff]; exact hb,
    have : coe b' = b := by ext; simp,
    exact ⟨b', by assumption, by assumption⟩
  end,
  exact finite_subset ‹finite s› this
end

lemma exists_min [decidable_linear_order β] (s : set α) (f : α → β) (h1 : finite s) :
  s.nonempty → ∃ a ∈ s, ∀ b ∈ s, f a ≤ f b
| ⟨x, hx⟩ := by simpa only [exists_prop, finite.mem_to_finset]
  using (finite.to_finset h1).exists_min f ⟨x, finite.mem_to_finset.2 hx⟩

end set

namespace finset
variables [decidable_eq β]
variables {s t u : finset α} {f : α → β} {a : α}

lemma finite_to_set (s : finset α) : set.finite (↑s : set α) :=
set.finite_mem_finset s

@[simp] lemma coe_bind {f : α → finset β} : ↑(s.bind f) = (⋃x ∈ (↑s : set α), ↑(f x) : set β) :=
by simp [set.ext_iff]

@[simp] lemma coe_to_finset {s : set α} {hs : set.finite s} : ↑(hs.to_finset) = s :=
by simp [set.ext_iff]

@[simp] lemma coe_to_finset' (s : set α) [fintype s] : (↑s.to_finset : set α) = s :=
by ext; simp

end finset

namespace set

lemma finite_subset_Union {s : set α} (hs : finite s)
  {ι} {t : ι → set α} (h : s ⊆ ⋃ i, t i) : ∃ I : set ι, finite I ∧ s ⊆ ⋃ i ∈ I, t i :=
begin
  unfreezeI, cases hs,
  choose f hf using show ∀ x : s, ∃ i, x.1 ∈ t i, {simpa [subset_def] using h},
  refine ⟨range f, finite_range f, _⟩,
  rintro x hx,
  simp,
  exact ⟨_, ⟨_, hx, rfl⟩, hf ⟨x, hx⟩⟩
end

lemma finite_range_ite {p : α → Prop} [decidable_pred p] {f g : α → β} (hf : finite (range f))
  (hg : finite (range g)) : finite (range (λ x, if p x then f x else g x)) :=
finite_subset (finite_union hf hg) range_ite_subset

lemma finite_range_const {c : β} : finite (range (λ x : α, c)) :=
finite_subset (finite_singleton c) range_const_subset

lemma range_find_greatest_subset {P : α → ℕ → Prop} [∀ x, decidable_pred (P x)] {b : ℕ}:
  range (λ x, nat.find_greatest (P x) b) ⊆ ↑(finset.range (b + 1)) :=
by { rw range_subset_iff, assume x, simp [nat.lt_succ_iff, nat.find_greatest_le] }

lemma finite_range_find_greatest {P : α → ℕ → Prop} [∀ x, decidable_pred (P x)] {b : ℕ} :
  finite (range (λ x, nat.find_greatest (P x) b)) :=
finite_subset (finset.finite_to_set $ finset.range (b + 1)) range_find_greatest_subset

lemma card_lt_card {s t : set α} [fintype s] [fintype t] (h : s ⊂ t) :
  fintype.card s < fintype.card t :=
begin
  haveI := classical.prop_decidable,
  rw [← finset.coe_to_finset' s, ← finset.coe_to_finset' t, finset.coe_ssubset] at h,
  rw [fintype.card_of_finset' _ (λ x, mem_to_finset),
      fintype.card_of_finset' _ (λ x, mem_to_finset)],
  exact finset.card_lt_card h,
end

lemma card_le_of_subset {s t : set α} [fintype s] [fintype t] (hsub : s ⊆ t) :
  fintype.card s ≤ fintype.card t :=
calc fintype.card s = s.to_finset.card : fintype.card_of_finset' _ (by simp)
... ≤ t.to_finset.card : finset.card_le_of_subset (λ x hx, by simp [set.subset_def, *] at *)
... = fintype.card t : eq.symm (fintype.card_of_finset' _ (by simp))

lemma eq_of_subset_of_card_le {s t : set α} [fintype s] [fintype t]
   (hsub : s ⊆ t) (hcard : fintype.card t ≤ fintype.card s) : s = t :=
(eq_or_ssubset_of_subset hsub).elim id
  (λ h, absurd hcard $ not_le_of_lt $ card_lt_card h)

lemma card_range_of_injective [fintype α] {f : α → β} (hf : injective f)
  [fintype (range f)] : fintype.card (range f) = fintype.card α :=
eq.symm $ fintype.card_congr (@equiv.of_bijective  _ _ (λ a : α, show range f, from ⟨f a, a, rfl⟩)
  ⟨λ x y h, hf $ subtype.mk.inj h, λ b, let ⟨a, ha⟩ := b.2 in ⟨a, by simp *⟩⟩)

lemma finite.exists_maximal_wrt [partial_order β] (f : α → β) (s : set α) (h : set.finite s) :
  s.nonempty → ∃a∈s, ∀a'∈s, f a ≤ f a' → f a = f a' :=
begin
  classical,
  refine h.induction_on _ _,
  { assume h, exact absurd h empty_not_nonempty },
  assume a s his _ ih _,
  cases s.eq_empty_or_nonempty with h h,
  { use a, simp [h] },
  rcases ih h with ⟨b, hb, ih⟩,
  by_cases f b ≤ f a,
  { refine ⟨a, set.mem_insert _ _, assume c hc hac, le_antisymm hac _⟩,
    rcases set.mem_insert_iff.1 hc with rfl | hcs,
    { refl },
    { rwa [← ih c hcs (le_trans h hac)] } },
  { refine ⟨b, set.mem_insert_of_mem _ hb, assume c hc hbc, _⟩,
    rcases set.mem_insert_iff.1 hc with rfl | hcs,
    { exact (h hbc).elim },
    { exact ih c hcs hbc } }
end

section

local attribute [instance, priority 1] classical.prop_decidable

lemma to_finset_card {α : Type*} [fintype α] (H : set α) :
  H.to_finset.card = fintype.card H :=
multiset.card_map subtype.val finset.univ.val

lemma to_finset_inter {α : Type*} [fintype α] (s t : set α) [decidable_eq α] :
  (s ∩ t).to_finset = s.to_finset ∩ t.to_finset :=
by ext; simp

end

section

variables [semilattice_sup α] [nonempty α] {s : set α}

/--A finite set is bounded above.-/
lemma bdd_above_finite (hs : finite s) : bdd_above s :=
finite.induction_on hs bdd_above_empty $ λ a s _ _, bdd_above_insert.2

/--A finite union of sets which are all bounded above is still bounded above.-/
lemma bdd_above_finite_union {I : set β} {S : β → set α} (H : finite I) :
(bdd_above (⋃i∈I, S i)) ↔ (∀i ∈ I, bdd_above (S i)) :=
⟨λ (bdd : bdd_above (⋃i∈I, S i)) i (hi : i ∈ I),
  bdd_above_subset (subset_bUnion_of_mem hi) bdd,
show (∀i ∈ I, bdd_above (S i)) → (bdd_above (⋃i∈I, S i)), from
finite.induction_on H
  (λ _, by rw bUnion_empty; exact bdd_above_empty)
  (λ x s hn hf IH h, by simp only [
      set.mem_insert_iff, or_imp_distrib, forall_and_distrib, forall_eq] at h;
    rw [set.bUnion_insert, bdd_above_union]; exact ⟨h.1, IH h.2⟩)⟩

end

section

variables [semilattice_inf α] [nonempty α] {s : set α}

/--A finite set is bounded below.-/
lemma bdd_below_finite (hs : finite s) : bdd_below s :=
finite.induction_on hs bdd_below_empty $ λ a s _ _, bdd_below_insert.2

/--A finite union of sets which are all bounded below is still bounded below.-/
lemma bdd_below_finite_union {I : set β} {S : β → set α} (H : finite I) :
(bdd_below (⋃i∈I, S i)) ↔ (∀i ∈ I, bdd_below (S i)) :=
⟨λ (bdd : bdd_below (⋃i∈I, S i)) i (hi : i ∈ I),
  bdd_below_subset (subset_bUnion_of_mem hi) bdd,
show (∀i ∈ I, bdd_below (S i)) → (bdd_below (⋃i∈I, S i)), from
finite.induction_on H
  (λ _, by rw bUnion_empty; exact bdd_below_empty)
  (λ x s hn hf IH h, by simp only [
      set.mem_insert_iff, or_imp_distrib, forall_and_distrib, forall_eq] at h;
    rw [set.bUnion_insert, bdd_below_union]; exact ⟨h.1, IH h.2⟩)⟩

end

end set

namespace finset

section preimage

noncomputable def preimage {f : α → β} (s : finset β)
  (hf : set.inj_on f (f ⁻¹' ↑s)) : finset α :=
set.finite.to_finset (set.finite_preimage hf (set.finite_mem_finset s))

@[simp] lemma mem_preimage {f : α → β} {s : finset β} {hf : set.inj_on f (f ⁻¹' ↑s)} {x : α} :
  x ∈ preimage s hf ↔ f x ∈ s :=
by simp [preimage]

@[simp] lemma coe_preimage {f : α → β} (s : finset β)
  (hf : set.inj_on f (f ⁻¹' ↑s)) : (↑(preimage s hf) : set α) = f ⁻¹' ↑s :=
by simp [set.ext_iff]

lemma image_preimage [decidable_eq β] (f : α → β) (s : finset β)
  (hf : set.bij_on f (f ⁻¹' s.to_set) s.to_set) :
  image f (preimage s hf.inj_on) = s :=
finset.coe_inj.1 $
suffices f '' (f ⁻¹' ↑s) = ↑s, by simpa,
(set.subset.antisymm (image_preimage_subset _ _) hf.2.2)

end preimage

@[to_additive]
lemma prod_preimage [comm_monoid β] (f : α → γ) (s : finset γ)
  (hf : set.bij_on f (f ⁻¹' ↑s) ↑s) (g : γ → β) :
  (preimage s hf.inj_on).prod (g ∘ f) = s.prod g :=
by classical;
calc
  (preimage s hf.inj_on).prod (g ∘ f)
      = (image f (preimage s hf.inj_on)).prod g :
          begin
            rw prod_image,
            intros x hx y hy hxy,
            apply hf.inj_on,
            repeat { try { rw mem_preimage at hx hy,
                          rw [set.mem_preimage, mem_coe] },
                    assumption },
          end
  ... = s.prod g : by rw [image_preimage]

end finset

lemma fintype.exists_max [fintype α] [nonempty α]
  {β : Type*} [linear_order β] (f : α → β) :
  ∃ x₀ : α, ∀ x, f x ≤ f x₀ :=
begin
  rcases set.finite_univ.exists_maximal_wrt f _ univ_nonempty with ⟨x, _, hx⟩,
  exact ⟨x, λ y, (le_total (f x) (f y)).elim (λ h, ge_of_eq $ hx _ trivial h) id⟩
end
