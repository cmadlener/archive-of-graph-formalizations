theory DFS
  imports Pair_Graph_Specs
begin

datatype return = Reachable | NotReachable

record ('ver, 'neighb) DFS_state = stack:: "'ver list" seen:: "'neighb"  return:: return

locale DFS =
  (*set_ops: Set2 where empty = empty and insert = neighb_insert and isin = neighb_isin +*)
  Graph: Pair_Graph_Specs
    where lookup = lookup +
 set_ops: Set2 neighb_empty neighb_delete _ t_set neighb_inv neighb_insert


for lookup :: "'adj \<Rightarrow> 'a \<Rightarrow> 'neighb option" +

fixes G::"'adj" and s::"'a" and t::"'a"                                                                    
assumes 
        graph_inv[simp,intro]:
          "Graph.graph_inv G"
          "Graph.finite_graph G"
          "Graph.finite_neighbs" and
        s_in_G[simp,intro]: "s \<in> dVs (Graph.digraph_abs G)"
begin

lemma finite_neighbourhoods[simp]:                                                 
          "finite (t_set N)"
  using graph_inv(3)
  by fastforce

abbreviation "neighbourhood' \<equiv> Graph.neighbourhood G"

notation "neighbourhood'" ("\<N>\<^sub>G _" 100)

notation "inter" (infixl "\<inter>\<^sub>G" 100)

notation "diff" (infixl "-\<^sub>G" 100)

notation "union" (infixl "\<union>\<^sub>G" 100)

declare set_ops.set_union[simp] set_ops.set_inter[simp] set_ops.set_diff[simp] set_ops.invar_union[simp]
        set_ops.invar_inter[simp] set_ops.invar_diff[simp]

lemmas simps[simp] = Graph.neighbourhood_abs[OF graph_inv(1)] Graph.are_connected_abs[OF graph_inv(1)]

function (domintros) DFS::"('a, 'neighb) DFS_state \<Rightarrow> ('a, 'neighb) DFS_state" where
  "DFS dfs_state = 
     (case (stack dfs_state) of (v # stack_tl) \<Rightarrow>
       (if v = t then 
          (dfs_state \<lparr>return := Reachable\<rparr>)
        else ((if (\<N>\<^sub>G v -\<^sub>G (seen dfs_state)) \<noteq> \<emptyset>\<^sub>N then
                  let u = (sel ((\<N>\<^sub>G v) -\<^sub>G (seen dfs_state))) in
                    (DFS (dfs_state \<lparr>stack := u# (stack dfs_state),
                                     seen := neighb_insert u (seen dfs_state)\<rparr>))
                 else DFS (dfs_state \<lparr>stack := stack_tl \<rparr>))
              )
      )
     | _ \<Rightarrow> (dfs_state \<lparr>return := NotReachable\<rparr>)
    )"
  by pat_completeness auto

named_theorems call_cond_elims
named_theorems call_cond_intros
named_theorems ret_holds_intros
named_theorems invar_props_intros
named_theorems invar_props_elims
named_theorems invar_holds_intros
named_theorems state_rel_intros
named_theorems state_rel_holds_intros 

definition "DFS_call_1_conds dfs_state \<equiv> 
    (case stack dfs_state of (v # stack_tl) \<Rightarrow>
       (if v = t then 
          False
        else ((if ((\<N>\<^sub>G v) -\<^sub>G (seen dfs_state)) \<noteq> (\<emptyset>\<^sub>N) then
                  True
                 else False)
              )
      )
     | _ \<Rightarrow> False
    )"

lemma DFS_call_1_conds[call_cond_elims]: 
  "DFS_call_1_conds dfs_state \<Longrightarrow> 
   \<lbrakk>\<lbrakk>\<exists>v stack_tl. stack dfs_state = v # stack_tl;
    hd (stack dfs_state) \<noteq> t;
    (\<N>\<^sub>G (hd (stack dfs_state))) -\<^sub>G (seen dfs_state) \<noteq> (\<emptyset>\<^sub>N)\<rbrakk> \<Longrightarrow> P\<rbrakk> \<Longrightarrow> 
   P"
  by(auto simp: DFS_call_1_conds_def split: list.splits option.splits if_splits)

definition "DFS_upd1 dfs_state \<equiv> (
    let
      N = (\<N>\<^sub>G (hd (stack dfs_state)));
      u = (sel ((N -\<^sub>G (seen dfs_state)))) 
    in
      dfs_state \<lparr>stack := u # (stack dfs_state), seen := neighb_insert u (seen dfs_state)\<rparr>)" 

definition "DFS_call_2_conds dfs_state \<equiv>
(case stack dfs_state of (v # stack_tl) \<Rightarrow>
       (if v = t then 
          False
        else (
                (if ((\<N>\<^sub>G v) -\<^sub>G (seen dfs_state)) \<noteq> (\<emptyset>\<^sub>N) then
                  False
                 else True)
              )
      )
     | _ \<Rightarrow> False
    )"

term "{}"

lemma DFS_call_2_conds[call_cond_elims]: 
  "DFS_call_2_conds dfs_state \<Longrightarrow> 
   \<lbrakk>\<lbrakk>\<exists>v stack_tl. stack dfs_state = v # stack_tl;
    hd (stack dfs_state) \<noteq> t;
    (\<N>\<^sub>G (hd (stack dfs_state))) -\<^sub>G (seen dfs_state) = (\<emptyset>\<^sub>N)\<rbrakk> \<Longrightarrow> P\<rbrakk> \<Longrightarrow> 
   P"
  by(auto simp: DFS_call_2_conds_def split: list.splits option.splits if_splits)

definition "DFS_upd2 dfs_state \<equiv> 
  ((dfs_state \<lparr>stack := tl (stack dfs_state)\<rparr>))"


definition "DFS_ret_1_conds dfs_state \<equiv>
   (case stack dfs_state of (v # stack_tl) \<Rightarrow>
       (if v = t then 
          False
        else (
                (if ((\<N>\<^sub>G v) -\<^sub>G (seen dfs_state)) \<noteq> \<emptyset>\<^sub>N then
                  False
                 else False)
              )
      )
     | _ \<Rightarrow> True
   )"

lemma DFS_ret_1_conds[call_cond_elims]:
  "DFS_ret_1_conds dfs_state \<Longrightarrow> 
   \<lbrakk>\<lbrakk>stack dfs_state = []\<rbrakk> \<Longrightarrow> P\<rbrakk> \<Longrightarrow> 
   P"
  by(auto simp: DFS_ret_1_conds_def split: list.splits option.splits if_splits)

lemma DFS_call_4_condsI[call_cond_intros]:
  "\<lbrakk>stack dfs_state = []\<rbrakk> \<Longrightarrow> DFS_ret_1_conds dfs_state"
  by(auto simp: DFS_ret_1_conds_def split: list.splits option.splits if_splits)

abbreviation "DFS_ret1 dfs_state \<equiv> (dfs_state \<lparr>return := NotReachable\<rparr>)"

definition "DFS_ret_2_conds dfs_state \<equiv>
   (case stack dfs_state of (v # stack_tl) \<Rightarrow>
       (if v = t then 
          True
        else (
                (if (\<N>\<^sub>G v -\<^sub>G (seen dfs_state)) \<noteq> \<emptyset>\<^sub>N then
                  False
                 else False)
              )
      )
     | _ \<Rightarrow> False
   )"


lemma DFS_ret_2_conds[call_cond_elims]:
  "DFS_ret_2_conds dfs_state \<Longrightarrow> 
   \<lbrakk>\<And>v stack_tl. \<lbrakk>stack dfs_state = v # stack_tl;
    (hd (stack dfs_state)) = t\<rbrakk> \<Longrightarrow> P\<rbrakk> \<Longrightarrow> 
   P"
  by(auto simp: DFS_ret_2_conds_def split: list.splits option.splits if_splits)

lemma DFS_ret_2_condsI[call_cond_intros]:
  "\<And>v stack_tl. \<lbrakk>stack dfs_state = v # stack_tl; (hd (stack dfs_state)) = t\<rbrakk> \<Longrightarrow> DFS_ret_2_conds dfs_state"
  by(auto simp: DFS_ret_2_conds_def split: list.splits option.splits if_splits)

abbreviation "DFS_ret2 dfs_state \<equiv> (dfs_state \<lparr>return := Reachable\<rparr>)"

lemma DFS_cases:
  assumes "DFS_call_1_conds dfs_state \<Longrightarrow> P"
      "DFS_call_2_conds dfs_state \<Longrightarrow> P"
      "DFS_ret_1_conds dfs_state \<Longrightarrow> P"
      "DFS_ret_2_conds dfs_state \<Longrightarrow> P"
  shows "P"
proof-
  have "DFS_call_1_conds dfs_state \<or> DFS_call_2_conds dfs_state \<or>
        DFS_ret_1_conds dfs_state \<or> DFS_ret_2_conds dfs_state"
    by (auto simp add: DFS_call_1_conds_def DFS_call_2_conds_def
                        DFS_ret_1_conds_def DFS_ret_2_conds_def
           split: list.split_asm option.split_asm if_splits)
  then show ?thesis
    using assms
    by auto
qed

lemma DFS_simps:
  assumes "DFS_dom dfs_state" 
  shows"DFS_call_1_conds dfs_state \<Longrightarrow> DFS dfs_state = DFS (DFS_upd1 dfs_state)"
      "DFS_call_2_conds dfs_state \<Longrightarrow> DFS dfs_state = DFS (DFS_upd2 dfs_state)"
      "DFS_ret_1_conds dfs_state \<Longrightarrow> DFS dfs_state = DFS_ret1 dfs_state"
      "DFS_ret_2_conds dfs_state \<Longrightarrow> DFS dfs_state = DFS_ret2 dfs_state"
  by (auto simp add: DFS.psimps[OF assms] Let_def
                       DFS_call_1_conds_def DFS_upd1_def DFS_call_2_conds_def DFS_upd2_def
                       DFS_ret_1_conds_def
                       DFS_ret_2_conds_def
            split: list.splits option.splits if_splits )

lemma DFS_induct: 
  assumes "DFS_dom dfs_state"
  assumes "\<And>dfs_state. \<lbrakk>DFS_dom dfs_state;
                        DFS_call_1_conds dfs_state \<Longrightarrow> P (DFS_upd1 dfs_state);
                        DFS_call_2_conds dfs_state \<Longrightarrow> P (DFS_upd2 dfs_state)\<rbrakk> \<Longrightarrow> P dfs_state"
  shows "P dfs_state"
  apply(rule DFS.pinduct[OF assms(1)])
  apply(rule assms(2)[simplified DFS_call_1_conds_def DFS_upd1_def DFS_call_2_conds_def DFS_upd2_def])
  by (auto simp: Let_def split: list.splits option.splits if_splits)

lemma DFS_domintros: 
  assumes "DFS_call_1_conds dfs_state \<Longrightarrow> DFS_dom (DFS_upd1 dfs_state)"
  assumes "DFS_call_2_conds dfs_state \<Longrightarrow> DFS_dom (DFS_upd2 dfs_state)"
  shows "DFS_dom dfs_state"
proof(rule DFS.domintros, goal_cases)
  case (1 x21 x22)
  then show ?case
    using assms(1)[simplified DFS_call_1_conds_def DFS_upd1_def]
    by (force simp: Let_def split: list.splits option.splits if_splits)
next
  case (2 x21 x22)
  then show ?case
    using assms(2)[simplified DFS_call_2_conds_def DFS_upd2_def]
    by (force split: list.splits option.splits if_splits)
qed

definition "invar_1 dfs_state \<equiv> neighb_inv (seen dfs_state)"

lemma invar_1_props[invar_props_elims]:
  "invar_1 dfs_state \<Longrightarrow>
     (\<lbrakk>neighb_inv (seen dfs_state)\<rbrakk> \<Longrightarrow> P) \<Longrightarrow>
     P"
  by (auto simp: invar_1_def)

lemma invar_1_intro[invar_props_intros]: "\<lbrakk>neighb_inv (seen dfs_state)\<rbrakk>
                     \<Longrightarrow> invar_1 dfs_state"
  by (auto simp: invar_1_def)

lemma invar_1_holds_1[invar_holds_intros]:
  "\<lbrakk>DFS_call_1_conds dfs_state; invar_1 dfs_state\<rbrakk> \<Longrightarrow> 
      invar_1 (DFS_upd1 dfs_state)"
  by (auto simp: Let_def DFS_upd1_def elim!: invar_props_elims intro!: invar_props_intros)

lemma invar_1_holds_2[invar_holds_intros]: "\<lbrakk>DFS_call_2_conds dfs_state; invar_1 dfs_state\<rbrakk> \<Longrightarrow> invar_1 (DFS_upd2 dfs_state)"
  by (auto simp: DFS_upd2_def elim!: invar_props_elims intro: invar_props_intros)

lemma invar_1_holds_4[invar_holds_intros]: "\<lbrakk>DFS_ret_1_conds dfs_state; invar_1 dfs_state\<rbrakk> \<Longrightarrow> invar_1 (DFS_ret1 dfs_state)"
  by (auto elim!: invar_props_elims  intro: invar_props_intros)

lemma invar_1_holds_5[invar_holds_intros]: "\<lbrakk>DFS_ret_2_conds dfs_state; invar_1 dfs_state\<rbrakk> \<Longrightarrow> invar_1 (DFS_ret2 dfs_state)"
  by (auto elim!: invar_props_elims intro: invar_props_intros)

declare[[simp_trace_depth_limit=1000]]

lemma invar_1_holds[invar_holds_intros]: 
   assumes "DFS_dom dfs_state" "invar_1 dfs_state"
   shows "invar_1 (DFS dfs_state)"
  using assms(2)
proof(induction rule: DFS_induct[OF assms(1)])
  case IH: (1 dfs_state)
  show ?case
    apply(rule DFS_cases[where dfs_state = dfs_state])
    by (auto intro!: IH(2-4) invar_holds_intros  simp: DFS_simps[OF IH(1)])
qed

definition "invar_2 dfs_state = (Vwalk.vwalk (Graph.digraph_abs G) (rev (stack dfs_state)))"

lemma invar_2_props[invar_props_elims]: 
  "invar_2 dfs_state \<Longrightarrow>
     ((Vwalk.vwalk (Graph.digraph_abs G) (rev (stack dfs_state))) \<Longrightarrow> P) \<Longrightarrow> P"
  by (auto simp: invar_2_def)

lemma invar_2_intro[invar_props_intros]: "Vwalk.vwalk (Graph.digraph_abs G) (rev (stack dfs_state)) \<Longrightarrow> invar_2 dfs_state"
  by (auto simp: invar_2_def)


lemma invar_2_holds_1[invar_holds_intros]:
  assumes "DFS_call_1_conds dfs_state" "invar_1 dfs_state" "invar_2 dfs_state"
  shows "invar_2 (DFS_upd1 dfs_state)"
    using assms graph_inv
    by (force simp: Let_def DFS_upd1_def elim!: call_cond_elims elim!: invar_props_elims
                intro!: invar_props_intros Vwalk.vwalk_append2 neighbourhoodI)

lemma invar_2_holds_2[invar_holds_intros]: "\<lbrakk>DFS_call_2_conds dfs_state; invar_2 dfs_state\<rbrakk> \<Longrightarrow> invar_2 (DFS_upd2 dfs_state)"
  by (auto simp: DFS_upd2_def dest!: append_vwalk_pref elim!: invar_props_elims intro!: invar_props_intros elim: call_cond_elims)

lemma invar_2_holds_4[invar_holds_intros]: "\<lbrakk>DFS_ret_1_conds dfs_state; invar_2 dfs_state\<rbrakk> \<Longrightarrow> invar_2 (DFS_ret1 dfs_state)"
  by (auto elim!: invar_props_elims intro: invar_props_intros)

lemma invar_2_holds_5[invar_holds_intros]: "\<lbrakk>DFS_ret_2_conds dfs_state; invar_2 dfs_state\<rbrakk> \<Longrightarrow> invar_2 (DFS_ret2 dfs_state)"
  by (auto elim!: invar_props_elims intro: invar_props_intros)

lemma invar_2_holds[invar_holds_intros]:
   assumes "DFS_dom dfs_state" "invar_1 dfs_state" "invar_2 dfs_state"
   shows "invar_2 (DFS dfs_state)"
  using assms(2-3)
proof(induction rule: DFS_induct[OF assms(1)])
  case IH: (1 dfs_state)
  show ?case
    apply(rule DFS_cases[where dfs_state = dfs_state])
    by (auto intro!: IH(2-5) invar_holds_intros simp: DFS_simps[OF IH(1)])
qed

definition "invar_seen_stack dfs_state \<longleftrightarrow> 
    distinct (stack dfs_state)
    \<and> set (stack dfs_state) \<subseteq> t_set (seen dfs_state)
    \<and> t_set (seen dfs_state) \<subseteq> dVs (Graph.digraph_abs G)"

lemma invar_seen_stack_props[invar_props_elims]:
   "invar_seen_stack dfs_state \<Longrightarrow> 
     (\<lbrakk>distinct (stack dfs_state); set (stack dfs_state) \<subseteq> t_set (seen dfs_state);
       t_set (seen dfs_state) \<subseteq> dVs (Graph.digraph_abs G)\<rbrakk> \<Longrightarrow> P) \<Longrightarrow> P "
  by (auto simp: invar_seen_stack_def)

lemma invar_seen_stack_intro[invar_props_intros]:
  "\<lbrakk>distinct (stack dfs_state); set (stack dfs_state) \<subseteq> t_set (seen dfs_state); t_set (seen dfs_state) \<subseteq> dVs (Graph.digraph_abs G)\<rbrakk> \<Longrightarrow> invar_seen_stack dfs_state"
  by (auto simp: invar_seen_stack_def)

lemma invar_seen_stack_holds_1[invar_holds_intros]:
  "\<lbrakk>DFS_call_1_conds dfs_state; invar_1 dfs_state; invar_seen_stack dfs_state\<rbrakk> \<Longrightarrow> invar_seen_stack (DFS_upd1 dfs_state)"
  by (force simp: Let_def DFS_upd1_def dest!: append_vwalk_pref elim!: call_cond_elims
            elim!: invar_props_elims intro!: invar_props_intros)

lemma invar_seen_stack_holds_2[invar_holds_intros]: 
  "\<lbrakk>DFS_call_2_conds dfs_state; invar_1 dfs_state; invar_seen_stack dfs_state\<rbrakk> \<Longrightarrow>
     invar_seen_stack (DFS_upd2 dfs_state)"
  by (auto elim!: call_cond_elims simp: DFS_upd2_def elim: vwalk_betE
           elim!: invar_props_elims dest!: Graph.neighb.emptyD append_vwalk_pref intro!: invar_props_intros)

lemma invar_seen_stack_holds_4[invar_holds_intros]:
   "\<lbrakk>DFS_ret_1_conds dfs_state; invar_seen_stack dfs_state\<rbrakk> \<Longrightarrow>
       invar_seen_stack (DFS_ret1 dfs_state)"
  by (auto elim!: invar_props_elims intro!: invar_props_intros)

lemma invar_seen_stack_holds_5[invar_holds_intros]: "\<lbrakk>DFS_ret_2_conds dfs_state; invar_seen_stack dfs_state\<rbrakk> \<Longrightarrow> invar_seen_stack (DFS_ret2 dfs_state)"
  by (auto elim!: invar_props_elims intro!: invar_props_intros)

lemma invar_seen_stack_holds[invar_holds_intros]:
   assumes "DFS_dom dfs_state" "invar_1 dfs_state" "invar_seen_stack dfs_state"
   shows "invar_seen_stack (DFS dfs_state)" 
   using assms(2-)
proof(induction rule: DFS_induct[OF assms(1)])
  case IH: (1 dfs_state)
  show ?case
    apply(rule DFS_cases[where dfs_state = dfs_state])
    by (auto intro!: IH(2-5) invar_holds_intros simp: DFS_simps[OF IH(1)])
qed

definition "invar_s_in_stack dfs_state \<longleftrightarrow> 
  (stack (dfs_state) \<noteq> [] \<longrightarrow> last (stack dfs_state) = s)"

lemma invar_s_in_stack_props[invar_props_elims]:
   "invar_s_in_stack dfs_state \<Longrightarrow> 
     (\<lbrakk>(stack (dfs_state) \<noteq> [] \<Longrightarrow> last (stack dfs_state) = s)\<rbrakk> \<Longrightarrow> P) \<Longrightarrow> P "
  by (auto simp: invar_s_in_stack_def)

lemma invar_s_in_stack_intro[invar_props_intros]:
  "\<lbrakk>(stack (dfs_state) \<noteq> [] \<Longrightarrow> last (stack dfs_state) = s)\<rbrakk> \<Longrightarrow> invar_s_in_stack dfs_state"
  by (auto simp: invar_s_in_stack_def)

lemma invar_s_in_stack_holds_1[invar_holds_intros]:
  "\<lbrakk>DFS_call_1_conds dfs_state; invar_1 dfs_state; invar_s_in_stack dfs_state\<rbrakk> \<Longrightarrow> invar_s_in_stack (DFS_upd1 dfs_state)"
  by (force simp: Let_def DFS_upd1_def dest!: append_vwalk_pref elim!: call_cond_elims
            elim!: invar_props_elims intro!: invar_props_intros)

lemma invar_s_in_stack_holds_2[invar_holds_intros]: 
  "\<lbrakk>DFS_call_2_conds dfs_state; invar_1 dfs_state; invar_s_in_stack dfs_state\<rbrakk> \<Longrightarrow>
     invar_s_in_stack (DFS_upd2 dfs_state)"
  by (auto elim!: call_cond_elims simp: DFS_upd2_def elim: vwalk_betE
           elim!: invar_props_elims dest!: Graph.neighb.emptyD append_vwalk_pref intro!: invar_props_intros)

lemma invar_s_in_stack_holds_4[invar_holds_intros]:
   "\<lbrakk>DFS_ret_1_conds dfs_state; invar_s_in_stack dfs_state\<rbrakk> \<Longrightarrow>
       invar_s_in_stack (DFS_ret1 dfs_state)"
  by (auto elim!: invar_props_elims intro!: invar_props_intros)

lemma invar_s_in_stack_holds_5[invar_holds_intros]: "\<lbrakk>DFS_ret_2_conds dfs_state; invar_s_in_stack dfs_state\<rbrakk> \<Longrightarrow> invar_s_in_stack (DFS_ret2 dfs_state)"
  by (auto elim!: invar_props_elims intro!: invar_props_intros)

lemma invar_s_in_stack_holds[invar_holds_intros]: 
   assumes "DFS_dom dfs_state" "invar_1 dfs_state" "invar_s_in_stack dfs_state"
   shows "invar_s_in_stack (DFS dfs_state)" 
   using assms(2-)
proof(induction rule: DFS_induct[OF assms(1)])
  case IH: (1 dfs_state)
  show ?case
    apply(rule DFS_cases[where dfs_state = dfs_state])
    by (auto intro!: IH(2-5) invar_holds_intros simp: DFS_simps[OF IH(1)])
qed


definition "invar_visited_through_seen dfs_state = 
    (\<forall>v \<in> t_set (seen dfs_state).
       (\<forall>p. Vwalk.vwalk_bet (Graph.digraph_abs G) v p t \<and> distinct p \<longrightarrow> (set p \<inter> set (stack dfs_state) \<noteq> {})))"

lemma invar_visited_through_seen_props[elim!]:
   "invar_visited_through_seen dfs_state \<Longrightarrow> 
     (\<lbrakk>\<And>v p. \<lbrakk>v \<in> t_set (seen dfs_state);
              (Vwalk.vwalk_bet (Graph.digraph_abs G) v p t); distinct p \<rbrakk> \<Longrightarrow>
              set p \<inter> set (stack dfs_state) \<noteq> {}\<rbrakk> \<Longrightarrow> P) \<Longrightarrow> P "
  by (auto simp: invar_visited_through_seen_def)


lemma invar_visited_through_seen_intro[invar_props_intros]:
  "\<lbrakk>\<And>v p. \<lbrakk>v \<in> t_set (seen dfs_state);
           (Vwalk.vwalk_bet (Graph.digraph_abs G) v p t); distinct p\<rbrakk> \<Longrightarrow>
           set p \<inter> set (stack dfs_state) \<noteq> {}\<rbrakk> \<Longrightarrow> invar_visited_through_seen dfs_state"
  by (auto simp: invar_visited_through_seen_def)


lemma invar_visited_through_seen_holds_1[invar_holds_intros]:
  "\<lbrakk>DFS_call_1_conds dfs_state; invar_1 dfs_state; invar_seen_stack dfs_state;
    invar_visited_through_seen dfs_state\<rbrakk> 
    \<Longrightarrow> invar_visited_through_seen (DFS_upd1 dfs_state)"
  by(fastforce simp: Let_def DFS_upd1_def dest: append_vwalk_pref hd_of_vwalk_bet''
               elim!: invar_props_elims intro!: invar_props_intros)


lemma invar_visited_through_seen_holds_2[invar_holds_intros]: 
  "\<lbrakk>DFS_call_2_conds dfs_state; invar_1 dfs_state; invar_seen_stack dfs_state;
    invar_visited_through_seen dfs_state\<rbrakk> \<Longrightarrow> invar_visited_through_seen (DFS_upd2 dfs_state)"
proof(rule invar_props_intros, elim invar_visited_through_seen_props call_cond_elims exE,  goal_cases)
  case (1 v1 p v2 stack_tl)
  text \<open>We know one thing: a path starting at @{term v1} and ending at @{term t} intersects with the
        old stack @{term "v2 # stack_tl"}.
        We have two cases:\<close>
  hence "set p \<inter> set (stack dfs_state) \<noteq> {}"
    by (auto simp: DFS_upd2_def)
  then obtain u where "u \<in> set p \<inter> set (stack dfs_state)"
    by auto
  show ?case
  proof(cases "u \<in> set stack_tl")
    case True
    text \<open>
        Case 1: If the point of intersection of the path is in @{term stack_tl}, then we are done.\<close>
    thus ?thesis
      using 1 \<open>u \<in> set p \<inter> set (stack dfs_state)\<close>
      by (auto simp: DFS_upd2_def)
  next
    case False
    hence "u = v2"
      using 1 \<open>u \<in> set p \<inter> set (stack dfs_state)\<close>
      by auto
    
    text \<open>
        Case 2: If it intersects the old stack at @{term v2}, which is the more interesting case as
                @{term v2} will not be in the new stack.\<close>
    then obtain p1 p2 where [simp]: "p = p1 @ [v2] @ p2"
      using \<open>u \<in> set p \<inter> set (stack dfs_state)\<close>
      by (auto simp: in_set_conv_decomp)
    text \<open>
                Let @{term "p = p1 @ [v2] @ p2"}.\<close>

    hence "set (v2 # p2) \<inter> set (stack dfs_state) \<noteq> {}"
      using 1
      by (auto simp: DFS_upd2_def)
    text \<open>
                Since the invariant holds for the old state, then @{term "[v2] @ p2"}
                intersects the old stack @{term "v2 # stack_tl"}.\<close>

    show ?thesis
    proof(cases "p2 = []")
      case True
    text \<open>
                There are two cases we need to consider
                here:
                Case a: @{term "p2 = []"} This cannot be the case, since it would imply that @{term "v2 = t"}, which 
                        violates the assumption of us being in this execution branch.\<close>
      thus ?thesis
        using 1
          by (auto simp: vwalk_bet_snoc)
    next
      case False
      text \<open>
                Case b: @{term "p2 \<noteq> []"} From the current branch's assumptions, we know that @{term "hd p2"}, who
                        is a neighbour of @{term v2}, is in @{term "seen dfs_state"}. This means that, from the 
                        invariant at @{term dfs_state}, we can conclude that @{term "v2#p2"} intersects with the
                        old stack. However, since it is distinct, that means that @{term p2}
                        cannot contain @{term v2}. This means that it intersects @{term stack_tl},
                        which implies that @{term p} with @{term stack_tl}. This finishes our proof.\<close>
      hence "hd p2 \<in> t_set (\<N>\<^sub>G v2)"
        using \<open>vwalk_bet (Graph.digraph_abs G) v1 p t\<close> 
        by (auto dest!: split_vwalk simp:  neq_Nil_conv)
      hence "hd p2 \<in> t_set (seen dfs_state)"
        using 1
        by (fastforce elim!: invar_props_elims simp del: \<open>p = p1 @ [v2] @ p2\<close>)
      hence "set p2 \<inter> set (stack dfs_state) \<noteq> {}" 
        using 1 False 
        by (fastforce simp: DFS_upd2_def neq_Nil_conv dest!: split_vwalk)
      moreover have "v2 \<notin> set p2"
        using \<open>distinct p\<close>
        by auto
      ultimately have "set p2 \<inter> set (stack (DFS_upd2 dfs_state)) \<noteq> {}" 
        using 1 
        by (auto simp: DFS_upd2_def)
      thus ?thesis
        by auto
    qed
  qed
qed

lemma invar_visited_through_seen_holds_4[invar_holds_intros]: "\<lbrakk>DFS_ret_1_conds dfs_state; invar_visited_through_seen dfs_state\<rbrakk> \<Longrightarrow> invar_visited_through_seen (DFS_ret1 dfs_state)"
  by (auto simp: intro: invar_props_intros)

lemma invar_visited_through_seen_holds_5[invar_holds_intros]: "\<lbrakk>DFS_ret_2_conds dfs_state; invar_visited_through_seen dfs_state\<rbrakk> \<Longrightarrow> invar_visited_through_seen (DFS_ret2 dfs_state)"
  by (auto simp: intro: invar_props_intros)

lemma invar_visited_through_seen_holds[invar_holds_intros]: 
   assumes "DFS_dom dfs_state" "invar_1 dfs_state" "invar_seen_stack dfs_state"
           "invar_visited_through_seen dfs_state"
   shows "invar_visited_through_seen (DFS dfs_state)" 
   using assms(2-)
proof(induction rule: DFS_induct[OF assms(1)])
  case IH: (1 dfs_state)
  show ?case
    apply(rule DFS_cases[where dfs_state = dfs_state])
    by (auto intro!: IH(2-6) invar_holds_intros simp: DFS_simps[OF IH(1)])
qed

(*abbreviation "seen_verts dfs_state \<equiv> (set (stack dfs_state) \<union> t_set (visited dfs_state))"*)
                                      
definition "state_rel_1 dfs_state_1 dfs_state_2 
              \<equiv> t_set (seen dfs_state_1) \<subseteq> t_set (seen dfs_state_2)"

lemma state_rel_1_props[elim!]: "state_rel_1 dfs_state_1 dfs_state_2 \<Longrightarrow>
                                  (t_set (seen dfs_state_1) \<subseteq> t_set (seen dfs_state_2) \<Longrightarrow> P) \<Longrightarrow> P "
  by (auto simp: state_rel_1_def)

lemma state_rel_1_intro[state_rel_intros]:
  "\<lbrakk>t_set (seen dfs_state_1) \<subseteq> t_set (seen dfs_state_2)\<rbrakk> \<Longrightarrow> state_rel_1 dfs_state_1 dfs_state_2"
  by (auto simp: state_rel_1_def)

lemma state_rel_1_trans:
  "\<lbrakk>state_rel_1 dfs_state_1 dfs_state_2; state_rel_1 dfs_state_2 dfs_state_3\<rbrakk> \<Longrightarrow>
   state_rel_1 dfs_state_1 dfs_state_3"
  by (auto intro!: state_rel_intros)

lemma state_rel_1_holds_1[state_rel_holds_intros]:
  "\<lbrakk>DFS_call_1_conds dfs_state; invar_1 dfs_state\<rbrakk> \<Longrightarrow> state_rel_1 dfs_state (DFS_upd1 dfs_state)"
  by (auto simp: Let_def DFS_upd1_def elim!: invar_props_elims intro!: state_rel_intros)

lemma state_rel_1_holds_2[state_rel_holds_intros]:
  "\<lbrakk>DFS_call_2_conds dfs_state; invar_1 dfs_state\<rbrakk> \<Longrightarrow> state_rel_1 dfs_state (DFS_upd2 dfs_state)"
  by (auto simp: DFS_upd2_def intro!: state_rel_intros elim: call_cond_elims)

lemma state_rel_1_holds_4[state_rel_holds_intros]:
  "\<lbrakk>DFS_ret_1_conds dfs_state\<rbrakk> \<Longrightarrow> state_rel_1 dfs_state (DFS_ret1 dfs_state)"
  by (auto simp: intro!: state_rel_intros)

lemma state_rel_1_holds_5[state_rel_holds_intros]:
  "\<lbrakk>DFS_ret_2_conds dfs_state\<rbrakk> \<Longrightarrow> state_rel_1 dfs_state (DFS_ret2 dfs_state)"
  by (auto simp: intro!: state_rel_intros)

lemma state_rel_1_holds[state_rel_holds_intros]:
   assumes "DFS_dom dfs_state" "invar_1 dfs_state"
   shows "state_rel_1 dfs_state (DFS dfs_state)" 
   using assms(2-)
proof(induction rule: DFS_induct[OF assms(1)])
  case IH: (1 dfs_state)
  show ?case
    apply(rule DFS_cases[where dfs_state = dfs_state])
    by (auto intro: state_rel_1_trans invar_holds_intros state_rel_holds_intros intro!: IH(2-) simp: DFS_simps[OF IH(1)])
qed

lemma DFS_ret_1[ret_holds_intros]: "DFS_ret_1_conds (dfs_state) \<Longrightarrow> DFS_ret_1_conds (DFS_ret1 dfs_state)"
  by (auto simp: elim!: call_cond_elims intro!: call_cond_intros)

lemma ret1_holds[ret_holds_intros]:
   assumes "DFS_dom dfs_state" "return (DFS dfs_state) = NotReachable"
   shows "DFS_ret_1_conds (DFS dfs_state)" 
   using assms(2-)
proof(induction  rule: DFS_induct[OF assms(1)])
  case IH: (1 dfs_state)
  show ?case
    apply(rule DFS_cases[where dfs_state = dfs_state])
    using IH(4)                                                                
    by (auto intro: ret_holds_intros intro!: IH(2-) simp: DFS_simps[OF IH(1)])
qed

lemma DFS_correct_ret_1:
  "\<lbrakk>invar_visited_through_seen dfs_state; DFS_ret_1_conds dfs_state; u \<in> t_set (seen dfs_state)\<rbrakk>
         \<Longrightarrow> \<nexists>p. distinct p \<and> vwalk_bet (Graph.digraph_abs G) u p t"
  by (auto elim!: call_cond_elims invar_props_elims)

lemma DFS_ret_2[ret_holds_intros]: "DFS_ret_2_conds (dfs_state) \<Longrightarrow> DFS_ret_2_conds (DFS_ret2 dfs_state)"
  by (auto simp: elim!: call_cond_elims intro!: call_cond_intros)

lemma ret2_holds[ret_holds_intros]:
   assumes "DFS_dom dfs_state" "return (DFS dfs_state) = Reachable"
   shows "DFS_ret_2_conds (DFS dfs_state)" 
   using assms(2-)
proof(induction  rule: DFS_induct[OF assms(1)])
  case IH: (1 dfs_state)
  show ?case
    apply(rule DFS_cases[where dfs_state = dfs_state])
    using IH(4)                                                                
    by (auto intro: ret_holds_intros intro!: IH(2-) simp: DFS_simps[OF IH(1)])
qed

lemma DFS_correct_ret_2:
  "\<lbrakk>invar_2 dfs_state; DFS_ret_2_conds dfs_state\<rbrakk>
         \<Longrightarrow> vwalk_bet (Graph.digraph_abs G) (last (stack dfs_state)) (rev (stack dfs_state)) t"
  by (auto elim!: call_cond_elims invar_props_elims simp: hd_rev vwalk_bet_def)

subsection \<open>Termination\<close>

named_theorems termination_intros

declare termination_intros

lemma in_prod_relI[intro!,termination_intros]:
  "\<lbrakk>f1 a = f1 a'; (a, a') \<in> f2 <*mlex*> r\<rbrakk> \<Longrightarrow> (a,a') \<in> (f1 <*mlex*> f2 <*mlex*> r)"
   by (simp add: mlex_iff)+

definition "less_rel \<equiv> {(x::nat, y::nat). x < y}"

lemma wf_less_rel[intro!]: "wf less_rel"
  by(auto simp: less_rel_def wf_less)

definition "state_measure_rel call_measure \<equiv> inv_image less_rel call_measure"

definition "call_1_measure \<equiv> \<lambda>dfs_state. card (dVs (Graph.digraph_abs G) -  t_set (seen dfs_state))"

lemma call_1_measure_nonsym[simp]: "(call_1_measure dfs_state, call_1_measure dfs_state) \<notin> less_rel"
  by (auto simp: less_rel_def)

lemma call_1_terminates[termination_intros]:
  "\<lbrakk>DFS_call_1_conds dfs_state; invar_1 dfs_state; invar_seen_stack dfs_state\<rbrakk> \<Longrightarrow>
     (DFS_upd1 dfs_state, dfs_state) \<in> call_1_measure <*mlex*> r"
  by(fastforce elim!: invar_props_elims call_cond_elims
          simp add: DFS_upd1_def call_1_measure_def Let_def 
          intro!: mlex_less psubset_card_mono
          dest!: Graph.neighb.choose')

definition "call_2_measure \<equiv> \<lambda>dfs_state. card (set (stack dfs_state))"

lemma call_2_measure_nonsym[simp]: "(call_2_measure dfs_state, call_2_measure dfs_state) \<notin> less_rel"
  by (auto simp: less_rel_def)

lemma call_2_measure_1[termination_intros]:
  "\<lbrakk>DFS_call_2_conds dfs_state; invar_1 dfs_state\<rbrakk> \<Longrightarrow>
    call_1_measure dfs_state = call_1_measure (DFS_upd2 dfs_state)"
  by(auto simp add: DFS_upd2_def call_1_measure_def Let_def
          intro!: psubset_card_mono)

lemma call_2_terminates[termination_intros]:
  "\<lbrakk>DFS_call_2_conds dfs_state; invar_1 dfs_state; invar_seen_stack dfs_state\<rbrakk> \<Longrightarrow>
     (DFS_upd2 dfs_state, dfs_state) \<in> call_2_measure <*mlex*> r"
  by(auto elim!: invar_props_elims elim!: call_cond_elims
          simp add: DFS_upd2_def call_2_measure_def
          intro!: mlex_less)

definition
  "DFS_term_rel' \<equiv> (call_1_measure) <*mlex*> (call_2_measure) <*mlex*> {}"

lemma wf_term_rel: "wf DFS_term_rel'"
  by(auto simp: wf_mlex DFS_term_rel'_def)

lemma in_DFS_term_rel'[termination_intros]:
  "\<lbrakk>DFS_call_1_conds dfs_state; invar_1 dfs_state; invar_seen_stack dfs_state\<rbrakk> \<Longrightarrow>
            (DFS_upd1 dfs_state, dfs_state) \<in> DFS_term_rel'" 
  "\<lbrakk>DFS_call_2_conds dfs_state; invar_1 dfs_state; invar_seen_stack dfs_state\<rbrakk> \<Longrightarrow>
            (DFS_upd2 dfs_state, dfs_state) \<in> DFS_term_rel'"
  by (simp add: DFS_term_rel'_def termination_intros)+

lemma DFS_terminates[termination_intros]:
  assumes "invar_1 dfs_state" "invar_seen_stack dfs_state"
  shows "DFS_dom dfs_state"
  using wf_term_rel assms
proof(induction rule: wf_induct_rule)
  case (less x)
  show ?case
    by (rule DFS_domintros) (auto intro!: invar_holds_intros less in_DFS_term_rel')
qed

definition "initial_state \<equiv> \<lparr>stack = [s], seen = neighb_insert s \<emptyset>\<^sub>N, return = undefined\<rparr>"

lemma initial_state_props[invar_holds_intros, termination_intros]:
  "invar_1 (initial_state)" "invar_2 (initial_state)" "invar_seen_stack (initial_state)"
  "invar_visited_through_seen (initial_state)" "invar_s_in_stack initial_state" 
  "DFS_dom initial_state"
  by (auto simp: initial_state_def
                 hd_of_vwalk_bet''
           elim: vwalk_betE
           intro!: termination_intros invar_props_intros)

lemma DFS_correct_1:
  assumes "return (DFS initial_state) = NotReachable"
  shows   "\<nexists>p. distinct p \<and> vwalk_bet (Graph.digraph_abs G) s p t"
proof-
  have "s \<in> t_set (seen (DFS initial_state))"
    by(auto intro!: invar_holds_intros ret_holds_intros state_rel_holds_intros
            intro: state_rel_1_props[where ?dfs_state_1.0 = initial_state]
            simp add: initial_state_def)
  thus ?thesis
    using assms
    by(intro DFS_correct_ret_1[where dfs_state = "DFS initial_state"])
      (auto intro!: invar_holds_intros ret_holds_intros state_rel_holds_intros)
qed

lemma DFS_correct_2:
  assumes  "return (DFS initial_state) = Reachable"
  shows "vwalk_bet (Graph.digraph_abs G) s (rev (stack (DFS initial_state))) t"
proof-
  have "vwalk_bet
              (Graph.digraph_abs G)
              (last (stack (DFS initial_state)))
              (rev (stack (DFS initial_state))) t"
    using assms
    by(auto intro!: invar_holds_intros ret_holds_intros state_rel_holds_intros
                       DFS_correct_ret_2[where dfs_state = "DFS initial_state"])
  moreover hence "(last (stack (DFS initial_state))) = s"
    by(fastforce intro!: invar_holds_intros
                 intro: invar_s_in_stack_props[where dfs_state = "DFS initial_state"])+
  ultimately show ?thesis
    by auto
qed

end
end
