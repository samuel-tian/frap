Require Import Frap.


(** * Finite sets as inductive predicates *)

Inductive my_favorite_numbers : nat -> Prop :=
| ILike17 : my_favorite_numbers 17
| ILike23 : my_favorite_numbers 23
| ILike42 : my_favorite_numbers 42.

Check my_favorite_numbers_ind.

Theorem favorites_below_50 : forall n, my_favorite_numbers n -> n < 50.
Proof.
  intros.
  induct H; linear_arithmetic.
Qed.

(** * Transitive closure of relations *)

Inductive tc {A} (R : A -> A -> Prop) : A -> A -> Prop :=
| TcBase : forall x y, R x y -> tc R x y
| TcTrans : forall x y z, tc R x y -> tc R y z -> tc R x z.

(** ** Less-than reimagined *)

Definition oneApart (n m : nat) : Prop :=
  n + 1 = m.

Definition lt' : nat -> nat -> Prop := tc oneApart.

Theorem lt'_lt : forall n m, lt' n m -> n < m.
Proof.
  intros.
  induct H.
  { unfold oneApart in H; linear_arithmetic. }
  { linear_arithmetic. }
Qed.

Lemma lt_lt'_O : forall m, 0 < m -> lt' 0 m.
Proof.
  intros.
  induct m; simplify.
  { invert H. }
  { cases m.
    { unfold lt'.
      apply TcBase.
      unfold oneApart.
      linear_arithmetic.
    }
    { assert (0 < S m).
      linear_arithmetic.
      apply IHm in H0.
      apply TcTrans with (y := S m).
      apply H0.
      apply TcBase.
      unfold oneApart.
      linear_arithmetic.
    }
  }
Qed.

Lemma lt_lt'' : forall n k, lt' n (S k + n).
Proof.
  intros.
  induct k; simplify.
  { unfold lt'.
    apply TcBase.
    unfold oneApart.
    linear_arithmetic. }
  { apply TcTrans with (y := S (k + n)); trivial.
    unfold lt'.
    apply TcBase.
    unfold oneApart.
    linear_arithmetic. }
Qed.

Theorem lt_lt' : forall n m, n < m -> lt' n m.
Proof.
  intros.
  replace m with (S (m - n - 1) + n).
  apply lt_lt''.
  linear_arithmetic.
Qed.
  
(** ** Transitive closure is idempotent. *)

Theorem tc_tc2 : forall A (R : A -> A -> Prop) x y, tc R x y -> tc (tc R) x y.
Proof.
  intros.
  induct H.
  { apply TcBase. apply TcBase. trivial. }
  { apply TcTrans with (y0:=y); trivial. }
Qed.

Theorem tc2_tc : forall A (R : A -> A -> Prop) x y, tc (tc R) x y -> tc R x y.
Proof.
  intros.
  induct H.
  { trivial. }
  { apply TcTrans with (y0:=y); trivial. }
Qed.

(** * Permutation *)

(* Lifted from the Coq standard library: *)
Inductive Permutation {A} : list A -> list A -> Prop :=
| perm_nil :
    Permutation [] []
| perm_skip : forall x l l',
    Permutation l l' -> Permutation (x::l) (x::l')
| perm_swap : forall x y l,
    Permutation (y::x::l) (x::y::l)
| perm_trans : forall l l' l'',
    Permutation l l' -> Permutation l' l'' -> Permutation l l''.

Lemma Permutation_cons : forall A (a : A) (ls : list A),
    Permutation (a :: ls) (ls ++ [a]).
Proof.
  intros.
  induct ls.
  { simplify. apply perm_skip. apply perm_nil. }
  { apply perm_trans with (a0 :: a :: ls).
    apply perm_swap.
    apply perm_skip.
    equality. }
Qed.
  
Theorem Permutation_rev : forall A (ls : list A),
    Permutation ls (rev ls).
Proof.
  intros.
  induct ls.
  { simplify. apply perm_nil. }
  { simplify.
    apply perm_trans with (a :: rev ls).
    apply perm_skip; trivial.
    apply Permutation_cons. }
Qed.

Theorem Permutation_length : forall A (ls1 ls2 : list A),
    Permutation ls1 ls2 -> length ls1 = length ls2.
Proof.
  intros.
  induct H; simplify; try equality.
Qed.

Lemma Permutation_comm : forall A (ls1 ls2 : list A),
    Permutation ls1 ls2 -> Permutation ls2 ls1.
Proof.
  intros.
  induct H.
  { apply perm_nil. }
  { apply perm_skip. assumption. }
  { apply perm_swap. }
  { apply perm_trans with (l'0 := l'); assumption. }
Qed.

Lemma Permutation_refl : forall A (ls : list A),
    Permutation ls ls.
Proof.
  intros.
  induct ls; simplify; try (apply perm_nil).
  { apply perm_skip. apply IHls. }
Qed.

Lemma Permutation_app1 : forall A (l ls1 ls2 : list A),
    Permutation ls1 ls2
    -> Permutation (ls1 ++ l) (ls2 ++ l).
Proof.
  intros.
  induct H; simplify; try equality.
  { apply Permutation_refl. }
  { apply perm_skip. assumption. }
  { apply perm_swap. }
  { apply perm_trans with (l'0 := l' ++ l); trivial. }
Qed.

Lemma Permutation_app2 : forall A (l ls1 ls2 : list A),
    Permutation ls1 ls2
    -> Permutation (l ++ ls1) (l ++ ls2).
Proof.
  intros.
  induct l; simplify; try equality.
  { apply perm_skip. apply IHl; trivial. }
Qed.

Theorem Permutation_app : forall A (ls1 ls1' ls2 ls2' : list A),
    Permutation ls1 ls1'
    -> Permutation ls2 ls2'
    -> Permutation (ls1 ++ ls2) (ls1' ++ ls2').
Proof.
  intros.
  induct H; simplify; try equality.
  { apply perm_skip.
    apply IHPermutation.
    apply H0. }
  { apply perm_trans with (y :: x :: l ++ ls2').
    apply perm_skip. apply perm_skip.
    apply Permutation_app2; trivial.

    apply perm_swap. }
  { apply perm_trans with (l' ++ ls2').
    apply IHPermutation1; trivial.
    apply Permutation_app1; trivial. }
Qed.

(** * Simple propositional logic *)

Inductive prop :=
| Truth
| Falsehood
| And (p1 p2 : prop)
| Or (p1 p2 : prop).

Inductive valid : prop -> Prop :=
| ValidTruth :
    valid Truth
| ValidAnd : forall p1 p2,
    valid p1
    -> valid p2
    -> valid (And p1 p2)
| ValidOr1 : forall p1 p2,
    valid p1
    -> valid (Or p1 p2)
| ValidOr2 : forall p1 p2,
    valid p2
    -> valid (Or p1 p2).

Fixpoint interp (p : prop) : Prop :=
  match p with
  | Truth => True
  | Falsehood => False
  | And p1 p2 => interp p1 /\ interp p2
  | Or p1 p2 => interp p1 \/ interp p2
  end.

Theorem interp_valid : forall p, interp p -> valid p.
Proof.
  intros.
  induct p; simplify.
  { apply ValidTruth. }
  { linear_arithmetic. }
  { apply ValidAnd. 
    apply IHp1.
    apply H.
    apply IHp2.
    apply H. }
  { cases H.
    { apply ValidOr1. apply IHp1; trivial. }
    { apply ValidOr2. apply IHp2; trivial. }
  }
Qed.

Theorem valid_interp : forall p, valid p -> interp p.
Proof.
  intros.
  induct p; simplify.
  { equality. }
  { invert H. }
  { invert H.
    { apply IHp1 in H2.
      apply IHp2 in H3.
      equality. }
  }
  { invert H.
    { apply IHp1 in H1.
      equality. }
    { apply IHp2 in H1.
      equality. }
  }
Qed.

Fixpoint commuter (p : prop) : prop :=
  match p with
  | Truth => Truth
  | Falsehood => Falsehood
  | And p1 p2 => And (commuter p2) (commuter p1)
  | Or p1 p2 => Or (commuter p2) (commuter p1)
  end.

Theorem valid_commuter_fwd : forall p, valid p -> valid (commuter p).
Proof.
  intros.
  induct p; simplify; try equality.
  { invert H.
    apply ValidAnd.
    apply IHp2; trivial.
    apply IHp1; trivial. }
  { invert H.
    apply ValidOr2.
    apply IHp1; trivial.
    apply ValidOr1.
    apply IHp2; trivial. }
Qed.

Theorem valid_commuter_bwd : forall p, valid (commuter p) -> valid p.
Proof.
  intros p.
  induct p; simplify.
  { apply ValidTruth. }
  { invert H. }
  { invert H.
    apply ValidAnd.
    apply IHp1; trivial.
    apply IHp2; trivial. }
  { invert H.
    apply ValidOr2.
    apply IHp2; trivial.
    apply ValidOr1.
    apply IHp1; trivial. }
Qed.

(* Proofs for an extension I hope we'll get to:

Fixpoint interp (vars : var -> Prop) (p : prop) : Prop :=
  match p with
  | Truth => True
  | Falsehood => False
  | Var x => vars x
  | And p1 p2 => interp vars p1 /\ interp vars p2
  | Or p1 p2 => interp vars p1 \/ interp vars p2
  | Imply p1 p2 => interp vars p1 -> interp vars p2
  end.

Theorem valid_interp : forall vars hyps p,
    valid hyps p
    -> (forall h, hyps h -> interp vars h)
    -> interp vars p.
Proof.
  induct 1; simplify.

  apply H0.
  assumption.

  propositional.

  propositional.

  propositional.

  propositional.

  propositional.

  propositional.

  propositional.

  propositional.
  apply IHvalid2.
  propositional.
  equality.
  apply H2.
  assumption.
  apply IHvalid3.
  propositional.
  equality.
  apply H2.
  assumption.

  apply IHvalid.
  propositional.
  equality.
  apply H0.
  assumption.

  propositional.

  excluded_middle (interp vars p); propositional.
  (* Note that use of excluded middle is a bit controversial in Coq,
   * and we'll generally be trying to avoid it,
   * but it helps enough with this example that we don't sweat the details. *)
Qed.

Lemma valid_weaken : forall hyps1 p,
    valid hyps1 p
    -> forall hyps2 : prop -> Prop,
      (forall h, hyps1 h -> hyps2 h)
      -> valid hyps2 p.
Proof.
  induct 1; simplify.

  apply ValidHyp.
  apply H0.
  assumption.

  apply ValidTruthIntro.

  apply ValidFalsehoodElim.
  apply IHvalid.
  assumption.

  apply ValidAndIntro.
  apply IHvalid1.
  assumption.
  apply IHvalid2.
  assumption.

  apply ValidAndElim1 with p2.
  apply IHvalid.
  assumption.

  apply ValidAndElim2 with p1.
  apply IHvalid.
  assumption.

  apply ValidOrIntro1.
  apply IHvalid.
  assumption.

  apply ValidOrIntro2.
  apply IHvalid.
  assumption.

  apply ValidOrElim with p1 p2.
  apply IHvalid1.
  assumption.
  apply IHvalid2.
  first_order.
  apply IHvalid3.
  first_order.

  apply ValidImplyIntro.
  apply IHvalid.
  propositional.
  right.
  apply H0.
  assumption.

  apply ValidImplyElim with p1.
  apply IHvalid1.
  assumption.
  apply IHvalid2.
  assumption.

  apply ValidExcludedMiddle.
Qed.

Lemma valid_cut : forall hyps1 p p',
    valid hyps1 p
    -> forall hyps2, valid hyps2 p'
                     -> (forall h, hyps1 h -> hyps2 h \/ h = p')
                     -> valid hyps2 p.
Proof.
  induct 1; simplify.

  apply H1 in H.
  propositional.
  apply ValidHyp.
  assumption.
  equality.

  apply ValidTruthIntro.

  apply ValidFalsehoodElim.
  apply IHvalid; assumption.

  apply ValidAndIntro.
  apply IHvalid1; assumption.
  apply IHvalid2; assumption.

  apply ValidAndElim1 with p2.
  apply IHvalid; assumption.

  apply ValidAndElim2 with p1.
  apply IHvalid; assumption.

  apply ValidOrIntro1.
  apply IHvalid; assumption.

  apply ValidOrIntro2.
  apply IHvalid; assumption.

  apply ValidOrElim with p1 p2.
  apply IHvalid1; assumption.
  apply IHvalid2.
  apply valid_weaken with hyps2.
  assumption.
  propositional.
  first_order.
  apply IHvalid3.
  apply valid_weaken with hyps2.
  assumption.
  propositional.
  first_order.

  apply ValidImplyIntro.
  apply IHvalid.
  apply valid_weaken with hyps2.
  assumption.
  propositional.
  first_order.

  apply ValidImplyElim with p1.
  apply IHvalid1; assumption.
  apply IHvalid2; assumption.

  apply ValidExcludedMiddle.
Qed.

Fixpoint varsOf (p : prop) : list var :=
  match p with
  | Truth
  | Falsehood => []
  | Var x => [x]
  | And p1 p2
  | Or p1 p2
  | Imply p1 p2 => varsOf p1 ++ varsOf p2
  end.

Lemma interp_valid'' : forall p hyps,
    (forall x, In x (varsOf p) -> hyps (Var x) \/ hyps (Not (Var x)))
    -> (forall x, hyps (Var x) -> ~hyps (Not (Var x)))
    -> IFF interp (fun x => hyps (Var x)) p
       then valid hyps p
       else valid hyps (Not p).
Proof.
  induct p; unfold IF_then_else; simplify.

  left; propositional.
  apply ValidTruthIntro.

  right; propositional.
  apply ValidImplyIntro.
  apply ValidHyp.
  propositional.

  specialize (H x); propositional.
  left; propositional.
  apply ValidHyp.
  assumption.
  right; first_order.
  apply ValidHyp.
  assumption.

  excluded_middle (interp (fun x => hyps (Var x)) p1).
  excluded_middle (interp (fun x => hyps (Var x)) p2).
  left; propositional.
  apply ValidAndIntro.
  assert (IFF interp (fun x : var => hyps (Var x)) p1 then valid hyps p1 else valid hyps (Not p1)).
  apply IHp1; propositional.
  apply H.
  apply in_or_app; propositional.
  unfold IF_then_else in H3; propositional.
  assert (IFF interp (fun x : var => hyps (Var x)) p2 then valid hyps p2 else valid hyps (Not p2)).
  apply IHp2; propositional.
  apply H.
  apply in_or_app; propositional.
  unfold IF_then_else in H3; propositional.
  right; propositional.
  assert (IFF interp (fun x : var => hyps (Var x)) p2 then valid hyps p2 else valid hyps (Not p2)).
  apply IHp2; propositional.
  apply H.
  apply in_or_app; propositional.
  unfold IF_then_else in H3; propositional.
  apply ValidImplyIntro.
  apply ValidImplyElim with p2.
  apply valid_weaken with hyps.
  assumption.
  propositional.
  apply ValidAndElim2 with p1.
  apply ValidHyp.
  propositional.
  right; propositional.
  assert (IFF interp (fun x : var => hyps (Var x)) p1 then valid hyps p1 else valid hyps (Not p1)).
  apply IHp1; propositional.
  apply H.
  apply in_or_app; propositional.
  unfold IF_then_else in H2; propositional.
  apply ValidImplyIntro.
  apply ValidImplyElim with p1.
  apply valid_weaken with hyps.
  assumption.
  propositional.
  apply ValidAndElim1 with p2.
  apply ValidHyp.
  propositional.

  excluded_middle (interp (fun x => hyps (Var x)) p1).
  left; propositional.
  apply ValidOrIntro1.
  assert (IFF interp (fun x : var => hyps (Var x)) p1 then valid hyps p1 else valid hyps (Not p1)).
  apply IHp1; propositional.
  apply H.
  apply in_or_app; propositional.
  unfold IF_then_else in H2; propositional.
  excluded_middle (interp (fun x => hyps (Var x)) p2).
  left; propositional.
  apply ValidOrIntro2.
  assert (IFF interp (fun x : var => hyps (Var x)) p2 then valid hyps p2 else valid hyps (Not p2)).
  apply IHp2; propositional.
  apply H.
  apply in_or_app; propositional.
  unfold IF_then_else in H3; propositional.
  right; propositional.
  apply ValidImplyIntro.
  apply ValidOrElim with p1 p2.
  apply ValidHyp.
  propositional.
  assert (IFF interp (fun x : var => hyps (Var x)) p1 then valid hyps p1 else valid hyps (Not p1)).
  apply IHp1; propositional.
  apply H.
  apply in_or_app; propositional.
  unfold IF_then_else in H3; propositional.
  apply ValidImplyElim with p1.
  apply valid_weaken with hyps.
  assumption.
  propositional.
  apply ValidHyp.
  propositional.
  assert (IFF interp (fun x : var => hyps (Var x)) p2 then valid hyps p2 else valid hyps (Not p2)).
  apply IHp2; propositional.
  apply H.
  apply in_or_app; propositional.
  unfold IF_then_else in H3; propositional.
  apply ValidImplyElim with p2.
  apply valid_weaken with hyps.
  assumption.
  propositional.
  apply ValidHyp.
  propositional.

  excluded_middle (interp (fun x => hyps (Var x)) p1).
  excluded_middle (interp (fun x => hyps (Var x)) p2).
  left; propositional.
  apply ValidImplyIntro.
  assert (IFF interp (fun x : var => hyps (Var x)) p2 then valid hyps p2 else valid hyps (Not p2)).
  apply IHp2; propositional.
  apply H.
  apply in_or_app; propositional.
  unfold IF_then_else in H3; propositional.
  apply valid_weaken with hyps.
  assumption.
  propositional.
  right; propositional.
  apply ValidImplyIntro.
  assert (IFF interp (fun x : var => hyps (Var x)) p1 then valid hyps p1 else valid hyps (Not p1)).
  apply IHp1; propositional.
  apply H.
  apply in_or_app; propositional.
  unfold IF_then_else in H3; propositional.
  assert (IFF interp (fun x : var => hyps (Var x)) p2 then valid hyps p2 else valid hyps (Not p2)).
  apply IHp2; propositional.
  apply H.
  apply in_or_app; propositional.
  unfold IF_then_else in H4; propositional.
  apply ValidImplyElim with p2.
  apply valid_weaken with hyps.
  assumption.
  propositional.
  apply ValidImplyElim with p1.
  apply ValidHyp.
  propositional.
  apply valid_weaken with hyps.
  assumption.
  propositional.
  left; propositional.
  apply ValidImplyIntro.
  assert (IFF interp (fun x : var => hyps (Var x)) p1 then valid hyps p1 else valid hyps (Not p1)).
  apply IHp1; propositional.
  apply H.
  apply in_or_app; propositional.
  unfold IF_then_else in H2; propositional.
  apply ValidFalsehoodElim.
  apply ValidImplyElim with p1.
  apply valid_weaken with hyps.
  assumption.
  propositional.
  apply ValidHyp.
  propositional.
Qed.

Lemma interp_valid' : forall p leftToDo alreadySplit,
    (forall x, In x (varsOf p) -> In x (alreadySplit ++ leftToDo))
    -> forall hyps, (forall x, In x alreadySplit -> hyps (Var x) \/ hyps (Not (Var x)))
    -> (forall x, hyps (Var x) \/ hyps (Not (Var x)) -> In x alreadySplit)
    -> (forall x, hyps (Var x) -> ~hyps (Not (Var x)))
    -> (forall vars : var -> Prop,
           (forall x, hyps (Var x) -> vars x)
           -> (forall x, hyps (Not (Var x)) -> ~vars x)
           -> interp vars p)
    -> valid hyps p.
Proof.
  induct leftToDo; simplify.

  rewrite app_nil_r in H.
  assert (IFF interp (fun x : var => hyps (Var x)) p then valid hyps p else valid hyps (Not p)).
  apply interp_valid''; first_order.
  unfold IF_then_else in H4; propositional.
  exfalso.
  apply H4.
  apply H3.
  propositional.
  first_order.

  excluded_middle (In a alreadySplit).

  apply IHleftToDo with alreadySplit; simplify.
  apply H in H5.
  apply in_app_or in H5.
  simplify.
  apply in_or_app.
  propositional; subst.
  propositional.
  first_order.
  first_order.
  first_order.
  first_order.

  apply ValidOrElim with (Var a) (Not (Var a)).
  apply ValidExcludedMiddle.

  apply IHleftToDo with (alreadySplit ++ [a]); simplify.
  apply H in H5.
  apply in_app_or in H5.
  simplify.
  apply in_or_app.
  propositional; subst.
  left; apply in_or_app; propositional.
  left; apply in_or_app; simplify; propositional.
  apply in_app_or in H5.
  simplify.
  propositional; subst.
  apply H0 in H6.
  propositional.
  propositional.
  propositional.
  invert H5.
  apply in_or_app.
  simplify.
  propositional.
  apply in_or_app.
  simplify.
  first_order.
  invert H5.
  apply in_or_app.
  simplify.
  first_order.
  propositional.
  invert H5.
  invert H7.
  first_order.
  invert H5.
  first_order.
  apply H3.
  first_order.
  first_order.

  apply IHleftToDo with (alreadySplit ++ [a]); simplify.
  apply H in H5.
  apply in_app_or in H5.
  simplify.
  apply in_or_app.
  propositional; subst.
  left; apply in_or_app; propositional.
  left; apply in_or_app; simplify; propositional.
  apply in_app_or in H5.
  simplify.
  propositional; subst.
  apply H0 in H6.
  propositional.
  propositional.
  propositional.
  invert H5.
  apply in_or_app.
  simplify.
  first_order.
  invert H5.
  apply in_or_app.
  simplify.
  propositional.
  apply in_or_app.
  simplify.
  first_order.
  propositional.
  invert H7.
  invert H7.
  invert H5.
  first_order.
  first_order.
  apply H3.
  first_order.
  first_order.
Qed.

Theorem interp_valid : forall p,
    (forall vars, interp vars p)
    -> valid (fun _ => False) p.
Proof.
  simplify.
  apply interp_valid' with (varsOf p) []; simplify; first_order.
Qed.
*)
