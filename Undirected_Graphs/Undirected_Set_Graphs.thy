theory Undirected_Set_Graphs
imports "enat_misc" "HOL-Eisbach.Eisbach_Tools"
begin

subsection \<open>Misc\<close>


text\<open>Since one of the matchings is bigger, there must be one edge equivalence class
  that has more edges from the bigger matching.\<close>

lemma lt_sum:
  "(\<Sum>x\<in>s. g x) < (\<Sum>x\<in>s. f x) \<Longrightarrow> \<exists>(x::'a ) \<in> s. ((g::'a \<Rightarrow> nat) x < f x)"
  by (auto simp add: not_le[symmetric] intro: sum_mono)

lemma Union_lt:
  assumes finite: "finite S" "finite t" "finite u" and
    card_lt: "card ((\<Union> S) \<inter> t) < card ((\<Union> S) \<inter> u)" and 
    disj: "\<forall>s\<in>S.\<forall>s'\<in>S. s \<noteq> s' \<longrightarrow> s \<inter> s' = {}"
  shows "\<exists>s\<in>S. card (s \<inter> t) < card (s \<inter> u)"
proof-
  {
    fix t::"'a set"
    assume ass: "finite t"
    have "card (\<Union>s\<in>S. s \<inter> t) = (\<Sum>s\<in>S. card (s \<inter> t))"
      using ass disj
      by(fastforce intro!: card_UN_disjoint finite)
  }note * = this
  show ?thesis
    using card_lt *[OF finite(2)] *[OF finite(3)]
    by (auto intro: lt_sum)
qed

subsection\<open>Paths, connected components, and symmetric differences\<close>

text\<open>Some basic definitions about the above concepts. One interesting point is the use of the
     concepts of connected components, which partition the set of vertices, and the analogous
     partition of edges. Juggling around between the two partitions, we get a much shorter proof for
     the first direction of Berge's lemma, which is the harder one.\<close>

definition Vs where "Vs E \<equiv> \<Union> E"

lemma vs_member[iff?]: "v \<in> Vs E \<longleftrightarrow> (\<exists>e \<in> E. v \<in> e)"
  unfolding Vs_def by simp

lemma vs_member_elim[elim?]:
  assumes "v \<in> Vs E"
  obtains e where "v \<in> e" "e \<in> E"
  using assms
  by(auto simp: vs_member)

lemma vs_member_intro[intro]:
  "\<lbrakk>v \<in> e; e \<in> E\<rbrakk> \<Longrightarrow> v \<in> Vs E"
  using vs_member
  by force

lemma vs_transport:
  "\<lbrakk>u \<in> Vs E; \<And>e. \<lbrakk>u \<in> e; e \<in> E\<rbrakk> \<Longrightarrow> \<exists>g \<in> F. u \<in> g\<rbrakk> \<Longrightarrow>u \<in> Vs F"
  by (auto simp: vs_member)

lemma edges_are_Vs:
  assumes "{v, v'} \<in> E"
  shows "v \<in> Vs E"
  using assms by blast

lemma finite_Vs_then_finite:
  assumes "finite (Vs E)"
  shows "finite E"
  using assms
  by (metis Vs_def finite_UnionD)

locale graph_defs =
  fixes E :: "'a set set"

definition "dblton_graph E \<equiv> (\<forall>e\<in>E. \<exists>u v. e = {u, v} \<and> u \<noteq> v)"

lemma dblton_graphE[elim]:
  assumes "dblton_graph E" "e \<in> E"
  obtains u v where "e = {u,v}" "u \<noteq> v"
  using assms
  by (auto simp: dblton_graph_def)

lemma dblton_graphI:
 assumes "\<And>e. e \<in> E \<Longrightarrow> \<exists>u v. e = {u, v} \<and> u \<noteq> v"
  shows "dblton_graph E"
  using assms
  by (auto simp: dblton_graph_def)

lemma dblton_graph_finite_Vs:
 assumes "dblton_graph E"
  shows "finite E \<longleftrightarrow> finite (Vs E)"
  using assms
  by (auto simp: dblton_graph_def Vs_def dest: finite_UnionD)

lemma dblton_graph_subset[intro]:
  "\<lbrakk>dblton_graph G1; G2 \<subseteq> G1\<rbrakk> \<Longrightarrow> dblton_graph G2"
  by (auto elim!: dblton_graphE intro!: dblton_graphI) 

abbreviation "graph_invar E \<equiv> dblton_graph E \<and> finite (Vs E)"

lemma graph_invar_finite_Vs:
 assumes "graph_invar E"
  shows "finite (Vs E)"
  using assms dblton_graph_finite_Vs
  by auto

lemma graph_invar_dblton:
 assumes "graph_invar E"
  shows "dblton_graph E"
  using assms dblton_graph_finite_Vs
  by auto

lemma graph_invar_finite:
 assumes "graph_invar E"
  shows "finite E"
  using assms dblton_graph_finite_Vs
  by auto
   
lemma graph_invar_subset[intro]:
  "\<lbrakk>graph_invar G1; G2 \<subseteq> G1\<rbrakk> \<Longrightarrow> graph_invar G2"
  using dblton_graph_subset
  by (metis dblton_graph_finite_Vs finite_subset)


locale graph_abs =
  graph_defs +
  assumes graph: "graph_invar E"
begin

lemma finite_E: "finite E"
  using finite_UnionD graph
  unfolding Vs_def
  by blast

lemma dblton_E: "dblton_graph E"
  using finite_UnionD graph
  unfolding Vs_def
  by blast

lemma finite_Vs: "finite (Vs E)"
  by (simp add: graph)

end

context fixes X :: "'a set set" begin
inductive path where
  path0: "path []" |
  path1: "v \<in> Vs X \<Longrightarrow> path [v]" |
  path2: "{v,v'} \<in> X \<Longrightarrow> path (v'#vs) \<Longrightarrow> path (v#v'#vs)"
end

declare path0

inductive_simps path_1: "path X [v]"

inductive_simps path_2: "path X (v # v' # vs)"

lemmas path_simps[simp] = path0 path_1 path_2


text\<open>
  If a set of edges cannot be partitioned in paths, then it has a junction of 3 or more edges.
  In particular, an edge from one of the two matchings belongs to the path
  equivalent to one connected component. Otherwise, there will be a vertex whose degree is
  more than 2.
\<close>


text\<open>
  Every edge lies completely in a connected component.
\<close>

fun edges_of_path where
"edges_of_path [] = []" |
"edges_of_path [v] = []" |
"edges_of_path (v#v'#l) = {v,v'} # (edges_of_path (v'#l))"

lemma path_ball_edges: "path E p \<Longrightarrow> b \<in> set (edges_of_path p) \<Longrightarrow> b \<in> E"
  by (induction p rule: edges_of_path.induct, auto)

lemma edges_of_path_index:
  "Suc i < length p \<Longrightarrow> edges_of_path p ! i = {p ! i, p ! Suc i}"
proof(induction i arbitrary: p)
  case 0
  then obtain u v ps where "p = u#v#ps" 
    by (auto simp: less_eq_Suc_le Suc_le_length_iff)
  thus ?case by simp
next
  case (Suc i)
  then obtain u v ps where "p = u#v#ps"
    by (auto simp: less_eq_Suc_le Suc_le_length_iff)
  hence "edges_of_path (v#ps) ! i = {(v#ps) ! i, (v#ps) ! Suc i}"
    using Suc.IH Suc.prems
    by simp
  thus ?case using \<open>p = u#v#ps\<close>
    by simp
qed

lemma edges_of_path_length: "length (edges_of_path p) = length p - 1"
  by (induction p rule: edges_of_path.induct, auto)

lemma edges_of_path_length': "p \<noteq> [] \<Longrightarrow> length p = length (edges_of_path p) + 1"
  by (induction p rule: edges_of_path.induct, auto)

lemma edges_of_path_for_inner:
  assumes "v = p ! i" "Suc i < length p"
  obtains u w where "{u, v} = edges_of_path p ! (i - 1)" "{v, w} = edges_of_path p ! i"
proof(cases "i = 0")
  case True thus ?thesis 
    using assms(1) edges_of_path_index[OF assms(2)] that
    by auto
next
  case False thus ?thesis
    by (auto simp add: Suc_lessD assms edges_of_path_index that)
qed

lemma path_vertex_has_edge:
  assumes "length p \<ge> 2" "v \<in> set p"
  obtains e where "e \<in> set (edges_of_path p)" "v \<in> e"
proof-
  have "\<exists>e \<in> set (edges_of_path p). v \<in> e"
    using assms Suc_le_eq 
    by (induction p rule: edges_of_path.induct) fastforce+
  thus ?thesis
    using that
    by rule
qed

lemma v_in_edge_in_path:
  assumes "{u, v} \<in> set (edges_of_path p)"
  shows "u \<in> set p"
  using assms
  by (induction p rule: edges_of_path.induct) auto

lemma v_in_edge_in_path_inj:
  assumes "e \<in> set (edges_of_path p)"
  obtains u v where "e = {u, v}"
  using assms
  by (induction p rule: edges_of_path.induct) auto

lemma v_in_edge_in_path_gen:
  assumes "e \<in> set (edges_of_path p)" "u \<in> e"
  shows "u \<in> set p"
proof-
  obtain u v where "e = {u, v}"
    using assms(1) v_in_edge_in_path_inj
    by blast
  thus ?thesis
    using assms
    by (force simp add: insert_commute intro: v_in_edge_in_path)
qed

lemma distinct_edges_of_vpath:
  "distinct p \<Longrightarrow> distinct (edges_of_path p)"
  using v_in_edge_in_path
  by (induction p rule: edges_of_path.induct) fastforce+

lemma distinct_edges_of_paths_cons:
  assumes "distinct (edges_of_path (v # p))"
  shows "distinct (edges_of_path p)"
  using assms
  by(cases "p"; simp)

lemma hd_edges_neq_last:
  assumes "{hd p, last p} \<notin> set (edges_of_path p)" "hd p \<noteq> last p" "p \<noteq> []"
  shows "hd (edges_of_path (last p # p)) \<noteq> last (edges_of_path (last p # p))"
  using assms
proof(induction p)
  case Nil
  then show ?case by simp
next
  case (Cons)
  then show ?case
    apply (auto split: if_splits)
    using edges_of_path.elims apply blast
    by (simp add: insert_commute)
qed

lemma edges_of_path_append_2:
  assumes "p' \<noteq> []"
  shows "edges_of_path (p @ p') = edges_of_path (p @ [hd p']) @ edges_of_path p'"
  using assms
proof(induction p rule: induct_list012)
  case 2
  obtain a p's where "p' = a # p's" using assms list.exhaust_sel by blast
  thus ?case by simp
qed simp_all

lemma edges_of_path_append_3:
  assumes "p \<noteq> []"
  shows "edges_of_path (p @ p') = edges_of_path p @ edges_of_path (last p # p')"
proof-
  have "edges_of_path (p @ p') = edges_of_path (butlast p @ last p # p')"
    by (subst append_butlast_last_id[symmetric, OF assms], subst append.assoc, simp)
  also have "... = edges_of_path (butlast p @ [last p]) @ edges_of_path (last p # p')"
    using edges_of_path_append_2
    by fastforce
  also have "... = edges_of_path p @ edges_of_path (last p # p')"
    by (simp add: assms)
  finally show ?thesis .
qed

lemma edges_of_path_rev:
  shows "rev (edges_of_path p) = edges_of_path (rev p)"
proof(induction p rule: edges_of_path.induct)
  case (3 v v' l)
  moreover have "edges_of_path (rev l @ [v', v]) = 
                   edges_of_path (rev l @ [v']) @ edges_of_path [v', v]"
    apply(subst edges_of_path_append_2)
    by auto
  ultimately show ?case
    by auto
qed auto

lemma edges_of_path_append: "\<exists>ep. edges_of_path (p @ p') = ep @ edges_of_path p'"
proof(cases p')
  case Nil thus ?thesis by simp
next
  case Cons thus ?thesis using edges_of_path_append_2 by blast
qed

lemma last_v_in_last_e: 
  "length p \<ge> 2 \<Longrightarrow> last p \<in> last (edges_of_path p)"
  by (induction "p" rule: induct_list012) (auto elim: edges_of_path.elims simp add: Suc_leI)

lemma hd_v_in_hd_e: 
  "length p \<ge> 2 \<Longrightarrow> hd p \<in> hd (edges_of_path p)"
  by (auto simp: Suc_le_length_iff numeral_2_eq_2)

lemma last_in_edge:
  assumes "p \<noteq> []"
  shows "\<exists>u. {u, last p} \<in> set (edges_of_path (v # p)) \<and> u \<in> set (v # p)"
  using assms
proof(induction "length p" arbitrary: v p)
  case (Suc x)
  thus ?case
  proof(cases p)
    case p: (Cons _ p')
    thus ?thesis
    proof(cases "p' = []")
      case False
      then show ?thesis
        using Suc
        by(auto simp add: p)
    qed auto
  qed auto
qed simp

find_theorems edges_of_path "(@)"

lemma edges_of_path_append_subset:
  "set (edges_of_path p') \<subseteq> set (edges_of_path (p @ p'))"
proof(cases p')
  case (Cons a list)
  then show ?thesis
    apply(subst edges_of_path_append_2)
    by auto
qed auto

lemma path_edges_subset:
  assumes "path E p"
  shows "set (edges_of_path p) \<subseteq> E"
  using assms
  by (induction, simp_all)

lemma induct_list012[case_names nil single sucsuc]:
  "\<lbrakk>P []; \<And>x. P [x]; \<And>x y zs. \<lbrakk> P zs; P (y # zs) \<rbrakk> \<Longrightarrow> P (x # y # zs)\<rbrakk> \<Longrightarrow> P xs"
  by induction_schema (pat_completeness, lexicographic_order)

lemma induct_list0123[consumes 0, case_names nil list1 list2 list3]:
  "\<lbrakk>P []; \<And>x. P [x]; \<And>x y. P [x, y]; 
    \<And>x y z zs. \<lbrakk> P zs; P (z # zs); P (y # z # zs) \<rbrakk> \<Longrightarrow> P (x # y # z # zs)\<rbrakk>
    \<Longrightarrow> P xs"
by induction_schema (pat_completeness, lexicographic_order)

lemma tl_path_is_path: "path E p \<Longrightarrow> path E (tl p)"
  by (induction p rule: path.induct) (simp_all)

lemma path_concat:
  "\<lbrakk>path E p; path E q; q \<noteq> []; p \<noteq> [] \<Longrightarrow> last p = hd q\<rbrakk> \<Longrightarrow> path E (p @ tl q)"
  by (induction rule: path.induct) (simp_all add: tl_path_is_path)

lemma path_append:
  "\<lbrakk>path E p1; path E p2; \<lbrakk>p1 \<noteq> []; p2 \<noteq> []\<rbrakk> \<Longrightarrow> {last p1, hd p2} \<in> E\<rbrakk> \<Longrightarrow> path E (p1 @ p2)"
  by (induction rule: path.induct) (auto simp add: neq_Nil_conv elim: path.cases)

lemma mem_path_Vs: 
  "\<lbrakk>path E p; a\<in>set p\<rbrakk> \<Longrightarrow> a \<in> Vs E"
  by (induction rule: path.induct) (simp; blast)+

lemma subset_path_Vs: 
  "\<lbrakk>path E p\<rbrakk> \<Longrightarrow> set p \<subseteq> Vs E"
  by (induction rule: path.induct) (simp; blast)+

lemma path_suff:
  assumes "path E (p1 @ p2)"
  shows "path E p2"
  using assms
proof(induction p1)
  case (Cons a p1)
  then show ?case using Cons tl_path_is_path by force
qed simp

lemma path_pref:
  assumes "path E (p1 @ p2)"
  shows "path E p1"
  using assms
proof(induction p1)
  case (Cons a p1)
  then show ?case using Cons by (cases p1; auto simp add: mem_path_Vs)
qed simp

lemma rev_path_is_path:
  assumes "path E p"
  shows "path E (rev p)"
  using assms
proof(induction)
  case (path2 v v' vs)
  moreover hence "{last (rev vs @ [v']), hd [v]} \<in> E"
    by (simp add: insert_commute)
  ultimately show ?case 
    using path_append edges_are_Vs
    by force
qed simp_all

lemma rev_path_is_path_iff:
  "path E (rev p) \<longleftrightarrow> path E p"
  using rev_path_is_path
  by force

lemma Vs_subset:
  "E \<subseteq> E' \<Longrightarrow> Vs E \<subseteq> Vs E'"
  by (auto simp: Vs_def)

lemma path_subset:
  assumes "path E p" "E \<subseteq> E'"
  shows "path E' p"
  using assms Vs_subset
  by (induction, auto)

lemma path_edges_of_path_refl: "length p \<ge> 2 \<Longrightarrow> path (set (edges_of_path p)) p"
proof (induction p rule: edges_of_path.induct)
  case (3 v v' l)
  thus ?case
    apply (cases l)
    by (auto intro: path_subset simp add: edges_are_Vs insert_commute path2)
qed simp_all

lemma edges_of_path_Vs: "Vs (set (edges_of_path p)) \<subseteq> set p"
  by (auto elim: vs_member_elim intro: v_in_edge_in_path_gen)

subsection \<open>Walks, and Connected Components\<close>

definition "walk_betw E u p v \<equiv> (p \<noteq> [] \<and> path E p \<and> hd p = u \<and> last p = v)"

lemma nonempty_path_walk_between:
  "\<lbrakk>path E p; p \<noteq> []; hd p = u; last p = v\<rbrakk> \<Longrightarrow> walk_betw E u p v"
  by (simp add: walk_betw_def)

lemma nonempty_path_walk_betweenE:
  assumes "path E p" "p \<noteq> []" "hd p = u" "last p = v"
  obtains p where "walk_betw E u p v"
  using assms
  by (simp add: walk_betw_def)

lemma walk_nonempty:
  assumes "walk_betw E u p v"
  shows [simp]: "p \<noteq> []"
  using assms walk_betw_def by fastforce

lemma walk_between_nonempty_pathD:
  assumes "walk_betw E u p v"
  shows "path E p" "p \<noteq> []" "hd p = u" "last p = v"
  using assms unfolding walk_betw_def by simp_all

lemma walk_reflexive:
  "w \<in> Vs E \<Longrightarrow> walk_betw E w [w] w"
  by (simp add: nonempty_path_walk_between)

lemma walk_symmetric:
  "walk_betw E u p v \<Longrightarrow> walk_betw E v (rev p) u"
  by (auto simp add: hd_rev last_rev walk_betw_def intro: rev_path_is_path)

lemma walk_transitive:
   "\<lbrakk>walk_betw E u p v; walk_betw E v q w\<rbrakk> \<Longrightarrow> walk_betw E u (p @ tl q) w"
  by (auto simp add: walk_betw_def intro: path_concat elim: path.cases)

lemma walk_transitive_2:
  "\<lbrakk>walk_betw E v q w; walk_betw E u p v\<rbrakk> \<Longrightarrow> walk_betw E u (p @ tl q) w"
  by (auto simp add: walk_betw_def intro: path_concat elim: path.cases)

lemma walk_in_Vs:
  "walk_betw E a p b \<Longrightarrow> set p \<subseteq> Vs E"
  by (simp add: subset_path_Vs walk_betw_def)

lemma walk_endpoints:
  assumes "walk_betw E u p v"
  shows [simp]: "u \<in> Vs E"
  and   [simp]: "v \<in> Vs E"
  using assms mem_path_Vs walk_betw_def
  by fastforce+

lemma walk_pref:
  "walk_betw E u (pr @ [x] @ su) v \<Longrightarrow> walk_betw E u (pr @ [x]) x"
proof(rule nonempty_path_walk_between, goal_cases)
  case 1
  hence "walk_betw E u ((pr @ [x]) @ su) v"
    by auto
  thus ?case
    by (fastforce dest!: walk_between_nonempty_pathD(1) path_pref)
next
  case 3
  then show ?case
    by(cases pr) (auto simp: walk_betw_def)
qed auto

lemma walk_suff:
   "walk_betw E u (pr @ [x] @ su) v \<Longrightarrow> walk_betw E x (x # su) v"
  by (fastforce simp: path_suff walk_betw_def)

lemma edges_are_walks:
  "{v, w} \<in> E \<Longrightarrow> walk_betw E v [v, w] w"
  using edges_are_Vs insert_commute
  by (auto 4 3 intro!: nonempty_path_walk_between)

lemma walk_subset:
  "\<lbrakk>walk_betw E u p v; E \<subseteq> E'\<rbrakk> \<Longrightarrow> walk_betw E' u p v"
  using path_subset
  by (auto simp: walk_betw_def)

lemma induct_walk_betw[case_names path1 path2, consumes 1, induct set: walk_betw]:
  assumes "walk_betw E a p b"
  assumes Path1: "\<And>v. v \<in> Vs E \<Longrightarrow> P v [v] v"
  assumes Path2: "\<And>v v' vs b. {v, v'} \<in> E \<Longrightarrow> walk_betw E v' (v' # vs) b \<Longrightarrow> P v' (v' # vs) b \<Longrightarrow> P v (v # v' # vs) b"
  shows "P a p b"
proof-
  have "path E p" "p \<noteq> []" "hd p = a" "last p = b"
    using assms(1)
    by (auto dest: walk_between_nonempty_pathD)
  thus ?thesis
    by (induction arbitrary: a b rule: path.induct) (auto simp: nonempty_path_walk_between assms(2,3))
qed

definition reachable where
  "reachable E u v = (\<exists>p. walk_betw E u p v)"

lemma reachableE:
  "reachable E u v \<Longrightarrow> (\<And>p. p \<noteq> [] \<Longrightarrow> walk_betw E u p v \<Longrightarrow> P) \<Longrightarrow> P"
  by (auto simp: reachable_def)

lemma reachableD:
  "reachable E u v \<Longrightarrow> \<exists>p. walk_betw E u p v"
  by (auto simp: reachable_def)

lemma reachableI:
  "walk_betw E u p v \<Longrightarrow> reachable E u v"
  by (auto simp: reachable_def)

lemma reachable_trans:
  "\<lbrakk>reachable E u v; reachable E v w\<rbrakk> \<Longrightarrow> reachable E u w"
  apply(erule reachableE)+
  apply (drule walk_transitive)
   apply assumption
  by (rule reachableI)

lemma reachable_sym:
  "reachable E u v \<longleftrightarrow> reachable E v u"
  by(auto simp add: reachable_def dest: walk_symmetric)

lemma reachable_refl:
  "u \<in> Vs E \<Longrightarrow> reachable E u u"
  by(auto simp add: reachable_def dest: walk_reflexive)

definition connected_component where
  "connected_component E v = {v'. v' = v \<or> reachable E v v'}"

text \<open>This is an easier to reason about characterisation, especially with automation\<close>

lemma connected_component_rechability:
  "connected_component E v = {v'. v' = v \<or> (reachable E v v')}"
  by (auto simp add: reachable_def connected_component_def)

definition connected_components where
  "connected_components E \<equiv> {vs. \<exists>v. vs = connected_component E v \<and> v \<in> (Vs E)}"

lemma in_own_connected_component: "v \<in> connected_component E v"
  unfolding connected_component_def by simp

lemma in_connected_componentE:
  "\<lbrakk>v \<in> connected_component E w; \<lbrakk>reachable E w v; w \<in> Vs E\<rbrakk> \<Longrightarrow> P; w = v \<Longrightarrow> P\<rbrakk> \<Longrightarrow> P"
  by (auto simp: connected_component_def reachable_refl elim: reachableE dest: walk_endpoints(1))

lemma in_connected_component_has_walk:
  assumes "v \<in> connected_component E w" "w \<in> Vs E"
  obtains p where "walk_betw E w p v"
proof(cases "v = w")
  case True thus ?thesis
   using that assms(2)
   by (auto dest: walk_reflexive )
next
  case False
  hence "reachable E w v"
    using assms(1) unfolding connected_component_def by blast
  thus ?thesis
    by (auto dest: reachableD that)
qed

(* TODO: Call in_connected_componentI *)

lemma has_path_in_connected_component:
  "walk_betw E u p v \<Longrightarrow> v \<in> connected_component E u"
  by(auto simp: connected_component_def reachable_def)

lemma in_connected_componentI:
  "reachable E w v \<Longrightarrow> v \<in> connected_component E w"
  by (auto simp: connected_component_rechability)

lemma in_connected_componentI2:
  "w = v \<Longrightarrow> v \<in> connected_component E w"
  by (auto simp: connected_component_rechability)

lemma edges_reachable:
  "{v, w} \<in> E \<Longrightarrow> reachable E v w"
  by (auto intro: edges_are_walks reachableI)

(* TODO: Call in_connected_componentI2 *)

lemma has_path_in_connected_component2:
  "(\<exists>p. walk_betw E u p v) \<Longrightarrow> v \<in> connected_component E u"
  unfolding connected_component_def reachable_def
  by blast

lemma connected_components_notE_singletons:
  "x \<notin> Vs E \<Longrightarrow> connected_component E x = {x}"
  by (fastforce simp add: connected_component_def reachable_def)

lemma connected_components_member_sym:
  "v \<in> connected_component E w \<Longrightarrow> w \<in> connected_component E v"
  by (auto elim!: in_connected_componentE intro: in_connected_componentI in_connected_componentI2
           simp: reachable_sym)

lemma connected_components_member_trans:
  "\<lbrakk>x \<in> connected_component E y; y \<in> connected_component E z\<rbrakk> \<Longrightarrow> x \<in> connected_component E z"
  by (auto elim!: in_connected_componentE dest: reachable_trans intro: in_connected_componentI
           simp: reachable_refl)

method in_tc uses tc_thm = 
  (match conclusion in "R x z" for R and x::'a and z::'a \<Rightarrow>
     \<open>match premises in a: "R x y" for  y \<Rightarrow>
       \<open>match premises in b: "R y z" \<Rightarrow>
          \<open>(insert tc_thm[OF a b])\<close>\<close>\<close>)

method in_tc_2 uses tc_thm refl_thm = 
  (match conclusion in "R x z" for R and x::'a and z::'a \<Rightarrow>
     \<open>match premises in a: "R x y" for  y \<Rightarrow>
       \<open>match premises in b: "R z y" \<Rightarrow>
          \<open>(insert tc_thm[OF a refl_thm[OF b]])\<close>\<close>\<close>)

method in_tc_3 uses tc_thm refl_thm = 
  (match conclusion in "R x z" for R and x::'a and z::'a \<Rightarrow>
     \<open>match premises in b: "R y z" for  y \<Rightarrow>
       \<open>match premises in a: "R y x" \<Rightarrow>
          \<open>(insert tc_thm[OF refl_thm[OF a] b])\<close>\<close>\<close>)

method in_tc_4 uses tc_thm refl_thm = 
  (match conclusion in "R x z" for R and x::'a and z::'a \<Rightarrow>
     \<open>match premises in a: "R y x" for  y \<Rightarrow>
       \<open>match premises in b: "R z y" \<Rightarrow>
          \<open>(insert tc_thm[OF refl_thm[OF a] refl_thm[OF b]])\<close>\<close>\<close>)

method in_rtc uses tc_thm refl_thm =
  (safe?; (in_tc tc_thm: tc_thm | in_tc_2 tc_thm: tc_thm refl_thm: refl_thm |
    in_tc_3 tc_thm: tc_thm refl_thm: refl_thm | in_tc_4 tc_thm: tc_thm refl_thm: refl_thm),
    assumption?)+

lemma connected_components_member_eq:
  "v \<in> connected_component E w \<Longrightarrow> connected_component E v = connected_component E w"
  by(in_rtc tc_thm: connected_components_member_trans refl_thm: connected_components_member_sym)

lemma connected_components_closed:
    "\<lbrakk>v1 \<in> connected_component E v4; v3 \<in> connected_component E v4\<rbrakk> \<Longrightarrow> v3 \<in> connected_component E v1"
  by(in_rtc tc_thm: connected_components_member_trans refl_thm: connected_components_member_sym)

lemma C_is_componentE:
  assumes "C \<in> connected_components E"
  obtains v where "C = connected_component E v" "v \<in> Vs E"
  using assms
  by (fastforce simp add: connected_components_def)

lemma connected_components_closed':
  "\<lbrakk>v \<in> C; C \<in> connected_components E\<rbrakk> \<Longrightarrow> C = connected_component E v"
  by (fastforce elim: C_is_componentE simp: connected_components_member_eq)

lemma connected_components_closed'':
  "\<lbrakk>C \<in> connected_components E; v \<in> C\<rbrakk> \<Longrightarrow> C = connected_component E v"
  by (simp add: connected_components_closed')

lemma connected_components_eq:
  "\<lbrakk>v \<in> C ; v \<in> C'; C \<in> connected_components E; C' \<in> connected_components E\<rbrakk> \<Longrightarrow> C = C'"
  using connected_components_closed'[where E = E]
  by auto

lemma connected_components_eq':
  "\<lbrakk>C \<in> connected_components E; C' \<in> connected_components E; v \<in> C ; v \<in> C'\<rbrakk> \<Longrightarrow> C = C'"
  using connected_components_eq .

lemma connected_components_disj:
  "\<lbrakk>C \<noteq> C'; C \<in> connected_components E; C' \<in> connected_components E\<rbrakk> \<Longrightarrow> C \<inter> C' = {}"
  using connected_components_eq[where E = E]
  by auto

lemma own_connected_component_unique:
  assumes "x \<in> Vs E"
  shows "\<exists>!C \<in> connected_components E. x \<in> C"
proof(standard, intro conjI)
  show "connected_component E x \<in> connected_components E"
    using assms connected_components_def
    by blast
  show "x \<in> connected_component E x"
    using in_own_connected_component
    by fastforce
  fix C assume "C \<in> connected_components E \<and> x \<in> C"
  thus "C = connected_component E x"
    by (simp add: connected_components_closed')
qed

lemma edge_in_component:
  assumes "{x,y} \<in> E"
  shows "\<exists>C. C \<in> connected_components E \<and> {x,y} \<subseteq> C"
proof-
  have "y \<in> connected_component E x"
  proof(rule has_path_in_connected_component)
    show "walk_betw E x [x, y] y" 
      apply(rule nonempty_path_walk_between)
      using assms
      by auto
  qed
  moreover have "x \<in> Vs E" using assms
    by (auto dest: edges_are_Vs)
  ultimately show ?thesis
    unfolding connected_components_def
    using in_own_connected_component
    by fastforce
qed

lemma edge_in_unique_component:
  "{x,y} \<in> E \<Longrightarrow> \<exists>!C. C \<in> connected_components E \<and> {x,y} \<subseteq> C"
  by(force dest: connected_components_closed' edge_in_component )

lemma connected_component_set:
  "\<lbrakk>u \<in> Vs E; \<And>x. x \<in> C \<Longrightarrow> reachable E u x; \<And>x. reachable E u x \<Longrightarrow> x \<in> C\<rbrakk> \<Longrightarrow> connected_component E u = C"
  by (auto elim: in_connected_componentE intro: in_connected_componentI dest: reachable_refl)

text\<open>
  Now we should be able to partition the set of edges into equivalence classes
  corresponding to the connected components.\<close>

definition component_edges where
"component_edges E C = {{x, y} | x y.  {x, y} \<subseteq> C \<and> {x, y} \<in> E}"

lemma component_edges_disj_edges:
  assumes "C \<in> connected_components E" "C' \<in> connected_components E" "C \<noteq> C'"
  assumes "v \<in> component_edges E C" "w \<in> component_edges E C'"
  shows "v \<inter> w = {}"
proof(intro equals0I)
  fix x assume "x \<in> v \<inter> w"
  hence "x \<in> C" "x \<in> C'" using assms(4, 5) unfolding component_edges_def by blast+
  thus False
    using assms(1-3)
    by(auto dest: connected_components_closed')
qed

lemma component_edges_disj:
  assumes "C \<in> connected_components E" "C' \<in> connected_components E" "C \<noteq> C'"
  shows "component_edges E C \<inter> component_edges E C' = {}"
proof(intro equals0I, goal_cases)
  case (1 y)
  hence "y = {}"
    apply(subst Int_absorb[symmetric])
    apply(intro component_edges_disj_edges)
    using assms  
    by auto

  thus False using 1 unfolding component_edges_def by blast
qed

lemma reachable_in_Vs:
  assumes "reachable E u v"
  shows "u \<in> Vs E" "v \<in> Vs E"
  using assms
  by(auto dest: reachableD)

lemma connected_component_subs_Vs:
  "C \<in> connected_components E \<Longrightarrow> C \<subseteq> Vs E"
  by (auto simp: dest: reachable_in_Vs(2) elim: in_connected_componentE C_is_componentE)

definition components_edges where
"components_edges E = {component_edges E C| C. C \<in> connected_components E}"

lemma connected_comp_nempty:
  "C \<in> connected_components E \<Longrightarrow> C \<noteq> {}"
  using in_own_connected_component
  by (fastforce simp: connected_components_def)

lemma connected_comp_verts_in_verts:
  "\<lbrakk>v \<in> C; C \<in> connected_components E\<rbrakk> \<Longrightarrow> v \<in> Vs E"
  using connected_component_subs_Vs
  by blast

(* TODO replace  everywhere with C_componentE*)

lemma connected_comp_has_vert:
  assumes "C \<in> connected_components E"
  obtains w where "w \<in> Vs E" "C = connected_component E w"
  using C_is_componentE[OF assms]
  .

lemma component_edges_partition:
  shows "\<Union> (components_edges E) = E \<inter> {{x,y}| x y. True}"
  unfolding components_edges_def
proof(safe)
  fix x y
  assume "{x, y} \<in> E"
  then obtain C where "{x, y} \<subseteq> C" "C \<in> connected_components E"
    by (auto elim!: exE[OF edge_in_component])
  moreover then have "{x, y} \<in> component_edges E C"
    using \<open>{x, y} \<in> E\<close> component_edges_def
    by fastforce
  ultimately show "{x, y} \<in> \<Union> {component_edges E C |C. C \<in> connected_components E}"
    by blast
qed (auto simp add: component_edges_def)

(*
  The edges in that bigger equivalence class can be ordered in a path, since the degree of any
  vertex cannot exceed 2. Also that path should start and end with edges from the bigger matching.
*)

subsection\<open>Every connected component can be linearised in a path.\<close>

lemma path_subset_conn_comp:
  assumes "path E p"
  shows "set p \<subseteq> connected_component E (hd p)"
  using assms
proof(induction)
  case path0
  then show ?case by simp
next
  case path1
  then show ?case using in_own_connected_component by simp
next
  case (path2 v v' vs)
  hence "walk_betw E v' [v',v] v"
    by (simp add: edges_are_walks insert_commute)
  hence "v \<in> connected_component E v'"
    by (auto dest:has_path_in_connected_component) 
  moreover hence "connected_component E v = connected_component E v'"
    by (simp add: connected_components_member_eq)
  ultimately show ?case using path2.IH by fastforce
qed

lemma walk_betw_subset_conn_comp:
  "walk_betw E u p v \<Longrightarrow> set p \<subseteq> connected_component E u"
  using path_subset_conn_comp
  by (auto simp: walk_betw_def)

lemma path_in_connected_component:
  "\<lbrakk>path E p; hd p \<in> connected_component E x\<rbrakk> \<Longrightarrow> set p \<subseteq> connected_component E x"
  by (fastforce dest: path_subset_conn_comp simp: connected_components_member_eq)

lemma component_has_path:
  assumes "finite C'" "C' \<subseteq> C" "C \<in> connected_components E"
  shows "\<exists>p. path E p \<and> C' \<subseteq> (set p) \<and> (set p) \<subseteq> C"
  using assms
proof(induction C')
  case empty thus ?case
    using path0 by fastforce
next
  case ass: (insert x F)
  then obtain p where p: "path E p" "F \<subseteq> set p" "set p \<subseteq> C"
    by auto
  have "x \<in> C" using ass.prems(1) by blast
  hence C_def: "C = connected_component E x"
    by (simp add: assms(3) connected_components_closed')

  show ?case
  proof(cases "p = []")
    case True
    have "path E [x]" using ass connected_comp_verts_in_verts by force
    then show ?thesis using True p ass.prems(1) by fastforce
  next
    case F1: False
    then obtain h t where "p = h # t" using list.exhaust_sel by blast
    hence walkhp: "walk_betw E h p (last p)" using p(1) walk_betw_def by fastforce

    have "h \<in> C" using \<open>p = h # t\<close> p(3) by fastforce
    moreover have "x \<in> Vs E"
      using \<open>x \<in> C\<close> assms(3) connected_component_subs_Vs
      by auto
    ultimately obtain q where walkxh: "walk_betw E x q h"
      by (auto simp: C_def elim: in_connected_component_has_walk)
    hence walkxp: "walk_betw E x (q @ tl p) (last p)"
      by (simp add: walk_transitive walkhp)
    moreover hence "set (q @ tl p) \<subseteq> C"
      by(auto simp: C_def dest!: walk_betw_subset_conn_comp)
    moreover from walkxp have "path E (q @ tl p)"
      by (fastforce dest: walk_between_nonempty_pathD)
    moreover {
      from walkxh have "last q = h" "hd q = x" by (fastforce dest: walk_between_nonempty_pathD)+
      then have "insert x F \<subseteq> set (q @ tl p)" using \<open>p = h # t\<close> walkxh p(2) by fastforce
    }
    ultimately show ?thesis by blast
  qed
qed

lemma component_has_path':
  "\<lbrakk>finite C; C \<in> connected_components E\<rbrakk> \<Longrightarrow> \<exists>p. path E p \<and> C = (set p)"
  using component_has_path
  by fastforce

subsection\<open>Every connected component can be linearised in a simple path\<close>

text\<open>An important part of this proof is setting up and induction on the graph, i.e. on a set of
     edges, and the different cases that could arise.\<close>

definition card' :: "'a set \<Rightarrow> enat" where
  "card' A \<equiv> (if infinite A then \<infinity> else card A)"

lemma card'_finite: "finite A \<Longrightarrow> card' A = card A"
  unfolding card'_def by simp

lemma card'_mono: "A \<subseteq> B \<Longrightarrow> card' A \<le> card' B"
  using finite_subset
  by (auto simp add: card'_def intro: card_mono)

lemma card'_empty[iff]: "(card' A = 0) \<longleftrightarrow> A = {}"
  unfolding card'_def using enat_0_iff(2) by auto

lemma card'_finite_nat[iff]: "(card' A = numeral m) \<longleftrightarrow> (finite A \<and> card A = numeral m)"
  unfolding card'_def
  by (simp add: numeral_eq_enat)

(*TODO: remove the enat notions*)

lemma card'_finite_enat[iff]: "(card' A = enat m) \<longleftrightarrow> (finite A \<and> card A = m)"
  unfolding card'_def by simp

(*TODO: FIX METIS*)

lemma card'_1_singletonE:
  assumes "card' A = 1"
  obtains x where "A = {x}"
  using assms
  unfolding card'_def
  by (fastforce elim!: card_1_singletonE dest: iffD1[OF enat_1_iff(1)] split: if_splits)

lemma card'_insert[simp]: "card' (insert a A) = (if a \<in> A then id else eSuc) (card' A)"
  using card_insert_if finite_insert
  by (simp add: card_insert_if card'_def)

lemma card'_empty_2[simp]: "card' {} = enat 0"
  by (simp add: card'_def)

definition degree where
  "degree E v \<equiv> card' ({e. v \<in> e} \<inter> E)"

lemma degree_def2: "degree E v \<equiv> card' {e \<in> E. v \<in> e}"
  unfolding degree_def
  by (simp add: Collect_conj_eq Int_commute)

lemma degree_Vs: "degree E v \<ge> 1" if "v \<in> Vs E"
proof-
  obtain e where "e \<in> E" "v \<in> e"
    using \<open>v \<in> Vs E\<close>
    by (auto simp: Vs_def)
  hence "{e} \<subseteq> {e \<in> E. v \<in> e}" by simp
  moreover have "card' {e} = 1" by (simp add: one_enat_def)
  ultimately show ?thesis
    by(fastforce dest!: card'_mono simp: degree_def2)
qed

lemma degree_not_Vs: "v \<notin> Vs E \<Longrightarrow> degree E v = 0"
  by (fastforce simp only: Vs_def degree_def)

lemma degree_insert: "\<lbrakk>v \<in> a; a \<notin> E\<rbrakk> \<Longrightarrow> degree (insert a E) v = eSuc (degree E v)"
  by (simp add: degree_def)

lemma degree_empty[simp]: "degree {} a = 0"
  unfolding degree_def by (simp add: zero_enat_def)

lemma degree_card_all:
  assumes "card E \<ge> numeral m"
  assumes "\<forall>e \<in> E. a \<in> e"
  assumes "finite E"
  shows "degree E a \<ge> numeral m"
  using assms unfolding degree_def
  by (simp add: card'_finite inf.absorb2 subsetI)

lemma subset_edges_less_degree:
  "E' \<subseteq> E \<Longrightarrow> degree E' v \<le> degree E v"
  by (auto intro: card'_mono simp: degree_def)

lemma less_edges_less_degree:
  shows "degree (E - E') v \<le> degree E v"
  by (intro subset_edges_less_degree)
     (simp add: subset_edges_less_degree)

lemma in_edges_of_path':
  "\<lbrakk> v \<in> set p; length p \<ge> 2\<rbrakk> \<Longrightarrow> v \<in> Vs (set (edges_of_path p))"
  by(auto dest: path_vertex_has_edge simp: Vs_def)

lemma in_edges_of_path:
  assumes "v \<in> set p" "v \<noteq> hd p"
  shows "v \<in> Vs (set (edges_of_path p))"
proof-
  have "length p \<ge> 2" using assms 
    by(cases p, auto dest!: length_pos_if_in_set simp: neq_Nil_conv)
  thus ?thesis by (simp add: assms(1) in_edges_of_path')
qed

lemma degree_edges_of_path_hd:
  assumes "distinct p" "length p \<ge> 2"
  shows "degree (set (edges_of_path p)) (hd p) = 1"
proof-
  obtain h nxt rest where p_def: "p = h # nxt # rest" using assms(2)
    by (auto simp: Suc_le_length_iff eval_nat_numeral)
  have calc: "{e. hd (h # nxt # rest) \<in> e} \<inter> set (edges_of_path (h # nxt # rest)) = {{h, nxt}}"
  proof(standard; standard)
    fix e assume "e \<in> {e. hd (h # nxt # rest) \<in> e} \<inter> set (edges_of_path (h # nxt # rest))"
    hence "e = {h, nxt} \<or> e \<in> set (edges_of_path (nxt # rest))" "h \<in> e" by fastforce+
    hence "e = {h, nxt}" using assms(1) v_in_edge_in_path_gen unfolding p_def by fastforce
    then show "e \<in> {{h, nxt}}" by simp
  qed simp
  show ?thesis unfolding p_def degree_def calc by (simp add: one_enat_def)
qed

lemma degree_edges_of_path_last:
  assumes "distinct p" "length p \<ge> 2"
  shows "degree (set (edges_of_path p)) (last p) = 1"
proof-
  have "distinct (rev p)" using assms(1) by simp
  moreover have "length (rev p) \<ge> 2" using assms(2) by simp
  ultimately have "degree (set (edges_of_path (rev p))) (hd (rev p)) = 1"
    using degree_edges_of_path_hd by blast
  then show ?thesis
    by(simp add: edges_of_path_rev[symmetric] hd_rev)
qed

lemma degree_edges_of_path_ge_2:
  assumes "distinct p" "v\<in>set p" "v \<noteq> hd p" "v \<noteq> last p"
  shows "degree (set (edges_of_path p)) v = 2"
  using assms
proof(induction p arbitrary: v rule: induct_list012)
  case nil then show ?case by simp
next
  case single then show ?case by simp
next
  case Cons: (sucsuc a a' p v)
  thus ?case
  proof(cases p)
    case Nil thus ?thesis using Cons.prems by simp
  next
    case p: (Cons a'' p')
    let ?goalset = "{e. a' \<in> e} \<inter> set (edges_of_path (a # a' # a'' # p'))"
    {
      have anotaa: "{a, a'} \<noteq> {a', a''}" using p Cons.prems(1) by fastforce
      moreover have "?goalset = {{a, a'}, {a', a''}}"
      proof(standard; standard)
        fix e assume "e \<in> ?goalset"
        moreover have "a' \<notin> f" if "f \<in> set (edges_of_path (a'' # p'))" for f
          using Cons.prems(1) p that v_in_edge_in_path_gen by fastforce
        ultimately show "e \<in> {{a, a'}, {a', a''}}" by force
      qed fastforce
      moreover have "card {{a, a'}, {a', a''}} = 2" using anotaa by simp
      ultimately have "2 = degree (set (edges_of_path (a # a' # p))) a'"
        unfolding degree_def p by (simp add: eval_enat_numeral one_enat_def)
    }
    moreover {
      fix w assume "w \<in> set (a' # p)" "w \<noteq> hd (a' # p)" "w \<noteq> last (a' # p)"
      hence "2 = degree (set (edges_of_path (a' # p))) w"
        using Cons.IH(2) Cons.prems(1) by fastforce
      moreover have "w \<notin> {a, a'}"
        using Cons.prems(1) \<open>w \<in> set (a' # p)\<close> \<open>w \<noteq> hd (a' # p)\<close> by auto
      ultimately have "2 = degree (set (edges_of_path (a # a' # p))) w" unfolding degree_def by simp
    }
    ultimately show ?thesis using Cons.prems(2-4) by auto
  qed
qed

lemma in_Vs_insertE:
  "v \<in> Vs (insert e E) \<Longrightarrow> (v \<in> e \<Longrightarrow> P) \<Longrightarrow> (v \<in> Vs E \<Longrightarrow> P) \<Longrightarrow> P"
  by (auto simp: Vs_def)

lemma list_sing_conv:
  "([x] = ys @ [y]) \<longleftrightarrow> (ys = [] \<and> y = x)"
  "([x] = y#ys) \<longleftrightarrow> (ys = [] \<and> y = x)"
  by (induction ys) auto

lemma path_insertE[case_names nil sing1 sing2 in_e in_E]:
   "\<lbrakk>path (insert e E) p; 
     (p = [] \<Longrightarrow> P);
     (\<And>v. p = [v] \<Longrightarrow> v \<in> e \<Longrightarrow> P);
     (\<And>v. p = [v] \<Longrightarrow> v \<in> Vs E \<Longrightarrow> P);
     (\<And>p' v1 v2. \<lbrakk>path {e} [v1, v2]; path (insert e E) (v2 # p'); p = v1 # v2 # p'\<rbrakk> \<Longrightarrow> P);
     (\<And>p' v1 v2. \<lbrakk>path E [v1,v2]; path (insert e E) (v2 # p'); p = v1 # v2 # p'\<rbrakk> \<Longrightarrow> P )\<rbrakk>
    \<Longrightarrow> P"
proof(induction rule: path.induct)
  case path0
  then show ?case 
    by auto
next
  case (path1 v)
  then show ?case
    by (auto elim!: in_Vs_insertE)
next
  case (path2 v v' vs)
  then show ?case
    apply (auto simp: vs_member)
    by blast
qed

text \<open>A lemma which allows for case splitting over paths when doing induction on graph edges.\<close>

lemma welk_betw_insertE[case_names nil sing1 sing2 in_e in_E]:
   "\<lbrakk>walk_betw (insert e E) v1 p v2; 
     (\<lbrakk>v1\<in>Vs (insert e E); v1 = v2; p = []\<rbrakk> \<Longrightarrow> P);
     (\<And>v. p = [v] \<Longrightarrow> v = v1 \<Longrightarrow> v = v2 \<Longrightarrow> v \<in> e \<Longrightarrow> P);
     (\<And>v. p = [v] \<Longrightarrow> v = v1 \<Longrightarrow> v = v2 \<Longrightarrow> v \<in> Vs E \<Longrightarrow> P);
     (\<And>p' v3. \<lbrakk>walk_betw {e} v1 [v1,v3] v3; walk_betw (insert e E) v3 (v3 # p') v2; p = v1 # v3 # p'\<rbrakk> \<Longrightarrow> P);
     (\<And>p' v3. \<lbrakk>walk_betw E v1 [v1,v3] v3; walk_betw (insert e E) v3 (v3 # p') v2; p = v1 # v3 # p'\<rbrakk> \<Longrightarrow> P)\<rbrakk>
    \<Longrightarrow> P"
  unfolding walk_betw_def
  apply safe
  apply(erule path_insertE)
  by (simp | force)+

lemma reachable_insertE[case_names nil sing1 sing2 in_e in_E]:
   "\<lbrakk>reachable (insert e E) v1 v2;
     (\<lbrakk>v1 \<in> e; v1 = v2\<rbrakk> \<Longrightarrow> P);
     (\<lbrakk>v1 \<in> Vs E; v1 = v2\<rbrakk> \<Longrightarrow> P);
     (\<And>p' v3. \<lbrakk>reachable {e} v1 v3; reachable (insert e E) v3 v2\<rbrakk> \<Longrightarrow> P);
     (\<And>p' v3. \<lbrakk>reachable E v1 v3; reachable (insert e E) v3 v2\<rbrakk> \<Longrightarrow> P)\<rbrakk>
    \<Longrightarrow> P"
  unfolding reachable_def
  apply(erule exE)
  apply(erule welk_betw_insertE)
  by (force simp: Vs_def)+

lemma in_Vs_unionE:
  "v \<in> Vs (E1 \<union> E2) \<Longrightarrow> (v \<in> Vs E1 \<Longrightarrow> P) \<Longrightarrow> (v \<in> Vs E2 \<Longrightarrow> P) \<Longrightarrow> P"
  by (auto simp: Vs_def)

lemma path_unionE[case_names nil sing1 sing2 in_e in_E]:
   "\<lbrakk>path (E1 \<union> E2) p; 
     (p = [] \<Longrightarrow> P);
     (\<And>v. p = [v] \<Longrightarrow> v \<in> Vs E1 \<Longrightarrow> P);
     (\<And>v. p = [v] \<Longrightarrow> v \<in> Vs E2 \<Longrightarrow> P);
     (\<And>p' v1 v2. \<lbrakk>path E1 [v1, v2]; path (E1 \<union> E2) (v2 # p'); p = v1 # v2 # p'\<rbrakk> \<Longrightarrow> P);
     (\<And>p' v1 v2. \<lbrakk>path E2 [v1,v2]; path (E1 \<union> E2) (v2 # p'); p = v1 # v2 # p'\<rbrakk> \<Longrightarrow> P )\<rbrakk>
    \<Longrightarrow> P"
proof(induction rule: path.induct)
  case path0
  then show ?case 
    by auto
next
  case (path1 v)
  then show ?case
    by (auto elim!: in_Vs_unionE)
next
  case (path2 v v' vs)
  then show ?case
    by (simp add: vs_member) blast+
qed

lemma welk_betw_unionE[case_names nil sing1 sing2 in_e in_E]:
   "\<lbrakk>walk_betw (E1 \<union> E2) v1 p v2; 
     (\<lbrakk>v1\<in>Vs (E1 \<union> E2); v1 = v2; p = []\<rbrakk> \<Longrightarrow> P);
     (\<And>v. p = [v] \<Longrightarrow> v = v1 \<Longrightarrow> v = v2 \<Longrightarrow> v \<in> Vs E1 \<Longrightarrow> P);
     (\<And>v. p = [v] \<Longrightarrow> v = v1 \<Longrightarrow> v = v2 \<Longrightarrow> v \<in> Vs E2 \<Longrightarrow> P);
     (\<And>p' v3. \<lbrakk>walk_betw E1 v1 [v1,v3] v3; walk_betw (E1 \<union> E2) v3 (v3 # p') v2; p = v1 # v3 # p'\<rbrakk> \<Longrightarrow> P);
     (\<And>p' v3. \<lbrakk>walk_betw E2 v1 [v1,v3] v3; walk_betw (E1 \<union> E2) v3 (v3 # p') v2; p = v1 # v3 # p'\<rbrakk> \<Longrightarrow> P)\<rbrakk>
    \<Longrightarrow> P"
  unfolding walk_betw_def
  apply safe
  apply(erule path_unionE)
  by (simp | force)+

lemma reachable_unionE[case_names nil sing1 sing2 in_e in_E]:
   "\<lbrakk>reachable (E1 \<union> E2) v1 v2;
     (\<lbrakk>v1 \<in> Vs E2; v1 = v2\<rbrakk> \<Longrightarrow> P);
     (\<lbrakk>v1 \<in> Vs E1; v1 = v2\<rbrakk> \<Longrightarrow> P);
     (\<And>p' v3. \<lbrakk>reachable E1 v1 v3; reachable (E1 \<union> E2) v3 v2\<rbrakk> \<Longrightarrow> P);
     (\<And>p' v3. \<lbrakk>reachable E2 v1 v3; reachable (E1 \<union> E2) v3 v2\<rbrakk> \<Longrightarrow> P)\<rbrakk>
    \<Longrightarrow> P"
  unfolding reachable_def
  apply(erule exE)
  apply(erule welk_betw_unionE)
  by (force simp: Vs_def)+

lemma singleton_subset: "path {e} p \<Longrightarrow> set p \<subseteq> e"
  by (induction rule: path.induct) (auto simp: Vs_def)

lemma path_singletonD: 
  "path {{v1::'a,v2}} p \<Longrightarrow> p \<noteq> [] \<Longrightarrow> (hd p = v1 \<or> hd p = v2) \<and> (last p = v1 \<or> last p = v2)"
  by (induction rule: path.induct) (auto simp: Vs_def)

lemma walk_betw_repl_edge:
  assumes "path (insert {w, x} E) p" "p \<noteq> []" "walk_betw E w puv x"
  shows "\<exists>p'. walk_betw E (hd p) p' (last p)"
  using assms
proof(induction rule: induct_list012)
  case nil
  then show ?case
    by auto
next
  case (single x)
  then show ?case
    using walk_reflexive
    by (fastforce elim!: in_Vs_insertE dest: walk_endpoints)+
next
  case (sucsuc x y zs)
  then show ?case
    apply -
  proof(erule path_insertE, goal_cases)
    case (4 p' v1 v2)
    then show ?case
      using walk_symmetric walk_transitive
      by(fastforce simp del: path_simps dest!: path_singletonD)
  next
    case (5 p' v1 v2)
    then show ?case
      using walk_transitive
      by (fastforce simp del: path_simps elim!: nonempty_path_walk_betweenE)
  qed auto
qed

lemma in_connected_componentI3:
  "\<lbrakk>C \<in> connected_components E; w \<in> C; x \<in> C\<rbrakk> \<Longrightarrow> x \<in> connected_component E w"
  using connected_components_closed'
  by fastforce

lemma same_con_comp_reachable:
  "\<lbrakk>C \<in> connected_components E; w \<in> C; x \<in> C\<rbrakk> \<Longrightarrow> reachable E w x"
  using in_connected_componentI3
  by(fastforce intro: reachable_refl connected_comp_verts_in_verts elim: in_connected_componentE)

lemma same_con_comp_walk:
  assumes "C \<in> connected_components E" "w \<in> C" "x \<in> C"
  obtains pwx where "walk_betw E w pwx x"
proof-
  have "x \<in> connected_component E w" 
    using assms
    by (rule in_connected_componentI3)
  thus ?thesis
    using connected_comp_verts_in_verts[OF \<open>w \<in> C\<close> \<open>C \<in> connected_components E\<close>]
    by (auto elim: that in_connected_component_has_walk)
qed                             

lemma in_connected_componentI4:
  assumes "walk_betw E u puv v" "u \<in> C" "C \<in> connected_components E"
  shows "v \<in> C"
  using assms connected_components_closed'
  by (fastforce intro: has_path_in_connected_component)

lemma walk_betw_singletonD:
  "walk_betw {{v1::'a,v2}} u p v \<Longrightarrow> p \<noteq> [] \<Longrightarrow> (hd p = v1 \<or> hd p = v2) \<and> (last p = v1 \<or> last p = v2) \<and> hd p = u \<and> last p = v"
  by (fastforce simp: walk_betw_def dest: path_singletonD)

(*TODO rename: path_can_be_split \<rightarrow> walk_can_be_split *)

lemma vwalk_betw_can_be_split:
  assumes "walk_betw (insert {w, x} E) u p v" "w \<in> Vs E" "x \<in> Vs E"
  shows "(\<exists>p. walk_betw E u p v) \<or>
         (\<exists>p1 p2. walk_betw E u p1 w \<and> walk_betw E x p2 v) \<or>
         (\<exists>p1 p2. walk_betw E u p1 x \<and> walk_betw E w p2 v)"
  using assms
proof(induction p arbitrary: u v)
  case Nil
  then show ?case
    by (auto simp: walk_betw_def)
next
  case (Cons a zs)
  then show ?case
    apply -
  proof(erule welk_betw_insertE, goal_cases)
    case (4 p' v3)
    (*TODO: Lukas*)
      then show ?case
      apply simp
      using walk_between_nonempty_pathD(4)[OF \<open>walk_betw {{w, x}} u [u, v3] v3\<close>]
            walk_betw_singletonD[OF \<open>walk_betw {{w, x}} u [u, v3] v3\<close>]
      by (auto dest: walk_reflexive)
  next
    case (5 p' v3)
    then show ?case
      (*TODO: Lukas*)
      using walk_transitive[OF \<open>walk_betw E u [u, v3] v3\<close>]
      by blast
  qed (insert walk_reflexive, fastforce)+
qed

lemma reachability_split:
  "\<lbrakk>reachable (insert {w, x} E) u v; w \<in> Vs E; x \<in> Vs E\<rbrakk> \<Longrightarrow>
        (reachable E u v) \<or>
         (reachable E u w \<and> reachable E x v) \<or>
         (reachable E u x \<and> reachable E w v)"
  by(auto simp: reachable_def dest: vwalk_betw_can_be_split)

lemma connected_component_in_components:
  "v \<in> Vs E \<Longrightarrow> connected_component E v \<in> connected_components E"
  by (fastforce simp: connected_components_def)

lemma reachable_subset:
  "\<lbrakk>reachable E u v; E \<subseteq> E'\<rbrakk> \<Longrightarrow> reachable E' u v"
  by (auto dest: walk_subset intro: reachableI elim!: reachableE)

lemma in_Vs_insert: "x \<in> Vs E \<Longrightarrow> x \<in> Vs (insert e E)"
  by (auto simp: Vs_def)
  
lemma vwalk_betw_can_be_split_2:
  assumes "walk_betw (insert {w, x} E) u p v" "w \<in> Vs E" "x \<notin> Vs E"
  shows "(\<exists>p'. walk_betw E u p' v) \<or>
         (\<exists>p'. walk_betw E u p' w \<and> v = x) \<or>
         (\<exists>p'. walk_betw E w p' v \<and> u = x) \<or>
         (u = x \<and> v = x)"
  using assms
proof(induction p arbitrary: u v)
  case Nil
  then show ?case
    by (auto simp: walk_betw_def)
next
  case (Cons a zs)
  then show ?case
    apply -
  proof(erule welk_betw_insertE, goal_cases)
    case (4 p' v3)
    then show ?case
      (*TODO: Lukas*)
      using walk_betw_singletonD[OF \<open>walk_betw {{w, x}} u [u, v3] v3\<close>]
      by (auto dest: walk_endpoints(1) walk_reflexive)
  next
    case (5 p' v3)
    then show ?case
     (*TODO: Lukas*)
      using walk_transitive[OF \<open>walk_betw E u [u, v3] v3\<close>] walk_endpoints(2)
      by (metis list.sel(3))
  qed (auto dest: walk_reflexive)+
qed

lemma reachability_split_2:
  "\<lbrakk>reachable (insert {w, x} E) u v; w \<in> Vs E; x \<notin> Vs E\<rbrakk> \<Longrightarrow>
     (reachable E u v) \<or>
     (reachable E u w \<and> v = x) \<or>
     (reachable E w v \<and> u = x) \<or>
     (u = x \<and> v = x)"
  by(auto simp: reachable_def dest: vwalk_betw_can_be_split_2)

lemma walk_betw_cons:
  "walk_betw E v1 (v2 # v3 # p) v4 \<longleftrightarrow> 
    (walk_betw E v3 (v3 # p) v4 \<and> walk_betw E v1 [v2, v3] v3)"
  by(auto simp: walk_betw_def)

lemma vwalk_betw_can_be_split_3:
  assumes "walk_betw (insert {w, x} E) u p v" "w \<notin> Vs E" "x \<notin> Vs E"
  shows "walk_betw E u p v \<or> walk_betw {{w, x}} u p v"
  using assms
proof(induction p arbitrary: u v)
  case Nil
  then show ?case
    by (auto simp: walk_betw_def)
next
  case (Cons a zs)
  then show ?case
    apply -
  proof(erule welk_betw_insertE, goal_cases)
    case (4 p' v3)
    then show ?case
      (*TODO: Lukas*)
      using walk_betw_singletonD[OF \<open>walk_betw {{w, x}} u [u, v3] v3\<close>]
      by (simp, metis walk_betw_cons walk_endpoints(1))
  next
    case (5 p' v3)
    then show ?case
      (*TODO: Lukas*)
      using walk_transitive[OF \<open>walk_betw E u [u, v3] v3\<close>] walk_betw_singletonD
      by fastforce
  qed (auto simp add: Vs_def walk_reflexive)
qed

lemma reachability_split3:
  "\<lbrakk>reachable (insert {w, x} E) u v; w \<notin> Vs E; x \<notin> Vs E\<rbrakk> \<Longrightarrow> 
  reachable E u v \<or> reachable {{w, x}} u v"
  by(auto simp: reachable_def dest: vwalk_betw_can_be_split_3)

lemma unchanged_connected_component:
  assumes "u \<notin> C" "v \<notin> C" 
  shows "C \<in> connected_components E \<longleftrightarrow> C \<in> connected_components (insert {u, v} E)"
proof-

  text \<open>This is to cover two symmetric cases\<close>
  have unchanged_con_comp_2:
    "C \<in> connected_components E \<longleftrightarrow> C \<in> connected_components (insert {u, v} E)"
    if "u \<notin> C" "v \<notin> C" "u \<in> Vs E" "v \<notin> Vs E"
    for u v
  proof-
    note assms = that
    show ?thesis
    proof(rule iffI, goal_cases)
      case 1
      then obtain v' where *: "C = connected_component E v'" "v' \<in> Vs E"
        by (rule C_is_componentE)
      hence "v' \<in> Vs (insert {u, v} E)"
        by(simp add: Vs_def)
      moreover have "x \<in> C \<Longrightarrow> reachable (insert {u, v} E) v' x"for x
        using *
        by (auto intro: in_Vs_insert reachable_refl dest: reachable_subset elim!: in_connected_componentE)
      moreover have "reachable (insert {u, v} E) v' x \<Longrightarrow> x \<in> C" for x
        using * assms
        by (auto dest: reachability_split_2 intro!: in_connected_componentI)
      ultimately have "connected_component (insert {u,v} E) v' = C"
        by (rule connected_component_set)
      then show ?case
        using \<open>v' \<in> Vs (insert {u, v} E)\<close> connected_component_in_components
        by auto
    next
      case 2
      then obtain v' where *: "C = connected_component (insert {u, v} E) v'" "v' \<in> Vs (insert {u, v} E)"
        by (rule C_is_componentE)
      hence "v' \<in> Vs E"
        using assms in_own_connected_component
        by (fastforce elim: in_Vs_insertE)
      moreover have "reachable (insert {u, v} E) v' x \<Longrightarrow> reachable E v' x" for x
        using *(1) assms \<open>v' \<in> Vs E\<close>
        by (auto dest: in_connected_componentI reachable_subset reachability_split_2) 
      hence "x \<in> C \<Longrightarrow> reachable E v' x" for x
        using *
        by (auto simp: reachable_refl elim: in_connected_componentE)
      moreover have "reachable E v' x \<Longrightarrow> x \<in> C" for x
        using *
        by (auto simp: reachable_refl dest: reachable_subset intro: in_connected_componentI)
      ultimately have "connected_component E v' = C"
        by (rule connected_component_set)
      then show ?case
        using \<open>v' \<in> Vs E\<close> connected_component_in_components
        by auto
    qed
  qed

  show ?thesis
  proof(cases \<open>u \<in> Vs E\<close>)
    assume "u \<in> Vs E"
    then show ?thesis
    proof(cases \<open>v \<in> Vs E\<close>)
      assume "v \<in> Vs E"
      note assms = assms \<open>u \<in> Vs E\<close> \<open>v \<in> Vs E\<close>
      show ?thesis
      proof(rule iffI, goal_cases)
        case 1
        then obtain v' where *: "C = connected_component E v'" "v' \<in> Vs E"
          by (rule C_is_componentE)
        hence "v' \<in> Vs (insert {u, v} E)"
          by(simp add: Vs_def)
        moreover have "x \<in> C \<Longrightarrow> reachable (insert {u, v} E) v' x"for x
          using * 
          by (auto intro: in_Vs_insert reachable_refl dest: reachable_subset
              elim!: in_connected_componentE)
        moreover have "reachable (insert {u, v} E) v' x \<Longrightarrow> x \<in> C" for x
          using *(1) assms
          by (auto dest: reachability_split intro!: in_connected_componentI)
        ultimately have "connected_component (insert {u,v} E) v' = C"
          by (rule connected_component_set)
        then show ?case
          using \<open>v' \<in> Vs (insert {u, v} E)\<close> connected_component_in_components
          by auto
      next
        case 2
        then obtain v' where *: "C = connected_component (insert {u, v} E) v'"
                                "v' \<in> Vs (insert {u, v} E)"
          by (rule C_is_componentE)
        hence "v' \<in> Vs E"
          using assms
          by (auto elim: in_Vs_insertE)
        moreover have "x \<in> C \<Longrightarrow> reachable E v' x" for x    
          using assms \<open>v' \<in> Vs E\<close>
          by (auto simp: *(1) elim!: in_connected_componentE 
              dest!: reachability_split dest: in_connected_componentI reachable_subset
              intro: reachable_refl)
        moreover have "reachable E v' x \<Longrightarrow> x \<in> C" for x
          using *
          by (auto dest: reachable_subset in_connected_componentI)
        ultimately have "connected_component E v' = C"
          by (rule connected_component_set)
        then show ?case
          using \<open>v' \<in> Vs E\<close> connected_component_in_components
          by auto
      qed

    next
      assume "v \<notin> Vs E"
      show ?thesis
        using unchanged_con_comp_2[OF assms \<open>u \<in> Vs E\<close> \<open>v \<notin> Vs E\<close>]
        .
    qed
  next
    assume "u \<notin> Vs E"
    then show ?thesis
    proof(cases \<open>v \<in> Vs E\<close>)
      assume "v \<in> Vs E"
      show ?thesis
        using unchanged_con_comp_2[OF assms(2,1) \<open>v \<in> Vs E\<close> \<open>u \<notin> Vs E\<close>]
        by (subst insert_commute)
    next
      assume "v \<notin> Vs E"
      note assms = assms \<open>u \<notin> Vs E\<close> \<open>v \<notin> Vs E\<close>
      show ?thesis
      proof(rule iffI, goal_cases)
        case 1
        then obtain v' where *: "C = connected_component E v'" "v' \<in> Vs E"
          by (rule C_is_componentE)
        hence "v' \<in> Vs (insert {u, v} E)"
          by(simp add: Vs_def)
        moreover have "x \<in> C \<Longrightarrow> reachable (insert {u, v} E) v' x"for x
          using *
          by (auto intro: reachable_refl in_Vs_insert dest: reachable_subset elim!: in_connected_componentE)
        moreover have "x \<in> C" if "reachable (insert {u, v} E) v' x" for x
        proof-
          have "\<not> reachable {{u, v}} v' x"
            using * assms \<open>u \<notin> Vs E\<close> \<open>v \<notin> Vs E\<close>
            by (auto dest: reachable_in_Vs(1) elim: vs_member_elim)
          thus ?thesis                                     
            using * that assms
            by (fastforce dest!: reachability_split3 simp add: in_connected_componentI)
        qed
        ultimately have "connected_component (insert {u,v} E) v' = C"
          by (rule connected_component_set)
        then show ?case
          using \<open>v' \<in> Vs (insert {u, v} E)\<close> connected_component_in_components
          by auto
      next
        case 2
        then obtain v' where *: "C = connected_component (insert {u, v} E) v'" "v' \<in> Vs (insert {u, v} E)"
          by (rule C_is_componentE)
        hence "v' \<in> Vs E"
          using assms in_own_connected_component
          by (force elim!: in_Vs_insertE)
        moreover have "reachable E v' x" if "reachable (insert {u, v} E) v' x" for x
        proof-
          have "\<not> reachable {{u, v}} v' x"
            using \<open>v' \<in> Vs E\<close> assms
            by (auto dest: reachable_in_Vs(1) elim: vs_member_elim)
          thus ?thesis
            using * assms that
            by (auto dest: reachability_split3)
        qed
        hence "x \<in> C \<Longrightarrow> reachable E v' x" for x
          using *
          by (auto simp: *(1) reachable_refl elim!: in_connected_componentE)
        moreover have "reachable E v' x \<Longrightarrow> x \<in> C" for x
          using *
          by (auto dest: reachable_subset in_connected_componentI)
        ultimately have "connected_component E v' = C"
          by (rule connected_component_set)
        then show ?case
          using \<open>v' \<in> Vs E\<close> connected_component_in_components
          by auto
      qed
    qed
  qed
qed

(*TODO rename connected_components_insert *)

lemma connected_components_union:
  assumes "Cu \<in> connected_components E" "Cv \<in> connected_components E"
  assumes "u \<in> Cu" "v \<in> Cv"
  shows "Cu \<union> Cv \<in> connected_components (insert {u, v} E)"
proof-
  have "u \<in> Vs (insert {u, v} E)" using assms(1) by (simp add: Vs_def)
  have "v \<in> Vs (insert {u, v} E)" using assms(1) by (simp add: Vs_def)

  have "reachable (insert {u, v} E) v x" if x_mem: "x \<in> Cu \<union> Cv" for x
  proof-
    have "reachable E u x \<or> reachable E v x"
      using x_mem assms
      by (auto dest: same_con_comp_reachable)
    then have "reachable (insert {u, v} E) u x \<or> reachable (insert {u, v} E) v x"
      by (auto dest: reachable_subset)
    thus ?thesis
      using edges_reachable[where E = "insert {u,v} E"]
      by (auto dest: reachable_trans)
  qed

  moreover note * = connected_comp_verts_in_verts[OF \<open>u \<in> Cu\<close> \<open>Cu \<in> connected_components E\<close>]
          connected_comp_verts_in_verts[OF \<open>v \<in> Cv\<close> \<open>Cv \<in> connected_components E\<close>]
  hence "reachable (insert {u, v} E) v x \<Longrightarrow> x \<in> Cu \<union> Cv" for x
    by(auto dest: in_connected_componentI reachability_split
            simp: connected_components_closed'[OF \<open>u \<in> Cu\<close> \<open>Cu \<in> connected_components E\<close>]
                  connected_components_closed'[OF \<open>v \<in> Cv\<close> \<open>Cv \<in> connected_components E\<close>])

  ultimately have "Cu \<union> Cv = connected_component (insert {u, v} E) v"
    apply(intro connected_component_set[symmetric])
    by(auto intro: in_Vs_insert)
  thus ?thesis
    using \<open>v \<in> Vs (insert {u, v} E)\<close> 
    by(auto intro: connected_component_in_components)
qed

lemma connected_components_insert_2:
  assumes "Cu \<in> connected_components E" "Cv \<in> connected_components E"
  assumes "u \<in> Cu" "v \<in> Cv"
  shows "connected_components (insert {u, v} E) = 
           insert (Cu \<union> Cv) ((connected_components E) - {Cu, Cv})"
proof-
  have Cuvins: "Cu \<union> Cv \<in> connected_components (insert {u, v} E)"
    by (simp add: assms connected_components_union)
  have "C \<in> connected_components (insert {u, v} E)" 
    if in_comps: "C \<in> insert (Cu \<union> Cv) (connected_components E - {Cu, Cv})" for C
  proof-
    consider (Cuv) "C = (Cu \<union> Cv)" | (other) "C \<in> connected_components E" "C \<noteq> Cu" "C \<noteq> Cv"
      using in_comps
      by blast
    thus ?thesis
    proof cases
      case other
      then show ?thesis
        using assms
        apply(subst unchanged_connected_component[symmetric])
        by (auto dest: connected_components_closed'[where C = C]
            connected_components_closed'[where C = Cu]
            connected_components_closed'[where C = Cv])
    qed (simp add: Cuvins)
  qed
  moreover have "C \<in> insert (Cu \<union> Cv) ((connected_components E) - {Cu, Cv})"
    if in_comps: "C \<in> connected_components (insert {u, v} E)" for C
  proof-
    have "u \<in> C \<or> v \<in> C \<Longrightarrow> C = Cu \<union> Cv"
      using Cuvins in_comps connected_components_closed'[where C = C] \<open>u \<in> Cu\<close> \<open>v \<in> Cv\<close>
            connected_components_closed'[where C = "Cu \<union> Cv"]
      by blast
    moreover have "C \<in> connected_components E" if "u \<notin> C"
    proof(cases \<open>v \<in> C\<close>)
      case True
      then show ?thesis
        using in_comps \<open>u \<in> Cu\<close> calculation that
        by auto
    next
      case False
      then show ?thesis
        apply(subst unchanged_connected_component[where u = u and v = v])
        using that in_comps
        by auto
    qed
    ultimately show ?thesis
      using assms(3, 4) by blast
  qed
  ultimately show ?thesis
    by auto

qed

lemma connected_components_insert_1:
  assumes "C \<in> connected_components E" "u \<in> C" "v \<in> C"
  shows "connected_components (insert {u, v} E) = connected_components E"
  using assms connected_components_insert_2 by fastforce

lemma in_connected_component_in_edges: "v \<in> connected_component E u \<Longrightarrow> v \<in> Vs E \<or> u = v"
  by(auto simp: connected_component_def Vs_def dest: walk_endpoints(2) elim!: reachableE vs_member_elim)

lemma in_con_comp_has_walk: assumes "v \<in> connected_component E u" "v \<noteq> u"
  obtains p where "walk_betw E u p v"
  using assms
  by(auto simp: connected_component_def elim!: reachableE)

find_theorems "(\<subseteq>)" reachable

lemma con_comp_subset: "E1 \<subseteq> E2 \<Longrightarrow> connected_component E1 u \<subseteq> connected_component E2 u"
  by (auto dest: reachable_subset simp: connected_component_def)

lemma in_con_comp_insert: "v \<in> connected_component (insert {u, v} E) u"
  using edges_are_walks[OF insertI1]
  by (force simp add: connected_component_def reachable_def)

lemma connected_components_insert:
  assumes "C \<in> connected_components E" "u \<in> C" "v \<notin> Vs E"
  shows "insert v C \<in> connected_components (insert {u, v} E)"
proof-
  have "u \<in> Vs (insert {u, v} E)" by (simp add: Vs_def)
  moreover have "connected_component (insert {u, v} E) u = insert v C"
  proof(standard, goal_cases)
    case 1
    thus ?case
      using assms
      by (fastforce elim: in_con_comp_has_walk dest!: vwalk_betw_can_be_split_2
                    simp add: in_connected_componentI4 connected_comp_verts_in_verts)
  next
    case 2
    have "C = connected_component E u"
      by (simp add: assms connected_components_closed')
    then show ?case
      by(auto intro!: insert_subsetI con_comp_subset[simplified]
              simp add: in_con_comp_insert)
  qed
  ultimately show ?thesis 
    using connected_components_closed' 
    by (fastforce dest: own_connected_component_unique)
qed

lemma connected_components_insert_3:
  assumes "C \<in> connected_components E" "u \<in> C" "v \<notin> Vs E"
  shows "connected_components (insert {u, v} E) = insert (insert v C) (connected_components E - {C})"
proof-
  have un_con_comp: "insert v C \<in> connected_components (insert {u, v} E)"
    by (simp add: assms connected_components_insert)
  have "D \<in> connected_components (insert {u, v} E)" 
    if "D \<in> insert (insert v C) (connected_components E - {C})"
    for D
  proof-
    from that consider (ins) "D = insert v C" | (other) "D \<in> connected_components E" "D \<noteq> C"
      by blast
    thus ?thesis
    proof cases
      case other
      moreover hence "v \<notin> D"
        using assms
        by (auto intro: connected_comp_verts_in_verts) 
      moreover have "u \<notin> D"
        using other assms 
        by (auto dest: connected_components_closed') 
      ultimately show ?thesis
        by(auto dest: unchanged_connected_component)
    qed (simp add: un_con_comp)
  qed
  moreover have "D \<in> insert (insert v C) (connected_components E - {C})"
    if "D \<in> connected_components (insert {u, v} E)"
    for D
  proof-
    have "u \<in> D \<longleftrightarrow> D = insert v C"
      using that assms(2) un_con_comp
      by (fastforce dest: connected_components_closed'')
    moreover hence "u \<in> D \<longleftrightarrow> v \<in> D"
      using that un_con_comp
      by (auto dest: connected_components_eq')
    ultimately show ?thesis 
        using that assms(2)
        by (auto simp: unchanged_connected_component[symmetric])
    qed
  ultimately show ?thesis by blast
qed

lemma connected_components_insert_1':
  "\<lbrakk>u \<in> Vs E; v \<in> Vs E\<rbrakk> \<Longrightarrow> 
     connected_components (insert {u, v} E)
       = insert (connected_component E u \<union> connected_component E v)
                     ((connected_components E) - {connected_component E u, connected_component E v})"
  by (auto simp add: connected_components_insert_2 in_own_connected_component
           dest!: connected_component_in_components)

lemma connected_components_insert_2':
  "\<lbrakk>u \<in> Vs E; v \<notin> Vs E\<rbrakk> 
   \<Longrightarrow> connected_components (insert {u, v} E)
         = insert (insert v (connected_component E u)) (connected_components E - {connected_component E u})"
  by (fastforce simp add: connected_components_insert_3 in_own_connected_component
                dest!: connected_component_in_components)

(*TODO: replace with connected_components_insert_4 everywhere*)

lemma connected_components_insert_4:
  assumes "u \<notin> Vs E" "v \<notin> Vs E"
  shows "connected_components (insert {u, v} E) = insert {u, v} (connected_components E)"
proof-
  have connected_components_small:
    "{u, v} \<in> connected_components (insert {u, v} E)"
  proof-
    have "u \<in> Vs (insert {u, v} E)"
      by (simp add: Vs_def)
    moreover have "connected_component (insert {u, v} E) u = {u, v}"
    proof(intro connected_component_set, goal_cases)
      case 1
      then show ?case
        by (simp add: Vs_def)
    next
      case (2 x)
      then show ?case
        by (auto simp add: \<open>u \<in> Vs (insert {u, v} E)\<close> reachable_refl edges_reachable)
    next
      case (3 x)
      then show ?case
        using reachable_in_Vs(1)
        by (fastforce simp add: assms dest: reachability_split3 walk_betw_singletonD elim: reachableE)
    qed
    ultimately show ?thesis
      by (fastforce dest: connected_component_in_components)
  qed

  have "{u, v} \<in> connected_components (insert {u, v} E)"
    by (simp add: assms connected_components_small)
  hence "C \<in> insert {u, v} (connected_components E)"
    if "C \<in> connected_components (insert {u, v} E)"
    for C
  proof(cases "C = {u, v}")
    case False
    hence "u \<notin> C" "v \<notin> C"
      using \<open>{u, v} \<in> connected_components (insert {u, v} E)\<close> that
      by (auto dest: connected_components_eq')
    hence "C \<in> connected_components E"
      using that
      by (auto dest: unchanged_connected_component)
    thus ?thesis
      by simp
  qed simp
  moreover have "C \<in> connected_components (insert {u, v} E)"
    if "C \<in> insert {u, v} (connected_components E)"
    for C
  proof(cases "C = {u, v}")
    case True
    thus ?thesis
      by (simp add: \<open>{u, v} \<in> connected_components (insert {u, v} E)\<close>)
  next
    case False
    hence "u \<notin> C" "v \<notin> C"
      using \<open>{u, v} \<in> connected_components (insert {u, v} E)\<close> that assms
      by (force simp add: insert_commute connected_comp_verts_in_verts)+
    thus ?thesis
      using that 
      by (auto dest: unchanged_connected_component)
  qed 
  ultimately show ?thesis
    by auto
qed

lemma connected_components_insert_3':
  "\<lbrakk>u \<notin> Vs E; v \<notin> Vs E\<rbrakk>
   \<Longrightarrow> connected_components (insert {u, v} E) = insert {u, v} (connected_components E)"
  using connected_components_insert_4
  .

text \<open>Elimination rule for proving lemmas about connected components by induction on graph edges.\<close>

lemma in_insert_connected_componentE[case_names both_nin one_in two_in]:
  assumes "C \<in> connected_components (insert {u,v} E)"
    "\<lbrakk>u \<notin> Vs E; v \<notin> Vs E;
     C \<in> insert {u,v} (connected_components E)\<rbrakk>
     \<Longrightarrow> P"
    "\<And>u' v'.
     \<lbrakk>u' \<in> {u,v}; v' \<in> {u, v}; u' \<in> Vs E; v' \<notin> Vs E;
     C \<in> insert (insert v' (connected_component E u')) (connected_components E - {connected_component E u'})\<rbrakk>
     \<Longrightarrow> P"
    "\<lbrakk>u \<in> Vs E; v \<in> Vs E; connected_component E u \<noteq> connected_component E v;
     C \<in> insert (connected_component E u \<union> connected_component E v)
                     ((connected_components E) - {connected_component E u, connected_component E v})\<rbrakk>
     \<Longrightarrow> P"
    "C \<in> (connected_components E) \<Longrightarrow> P"
  shows "P"
proof(cases \<open>u \<in> Vs E\<close>)
  assume \<open>u \<in> Vs E\<close>
  show ?thesis
  proof(cases \<open>v \<in> Vs E\<close>)
    assume \<open>v \<in> Vs E\<close>
    show ?thesis
    proof(cases "connected_component E u = connected_component E v")
      assume \<open>connected_component E u = connected_component E v\<close>
      hence "connected_components (insert {u,v} E) = connected_components E"        
        using \<open>u \<in> Vs E\<close>
        by (subst connected_components_insert_1[OF connected_component_in_components])
           (auto intro!: in_own_connected_component)
      thus ?thesis
        apply -
        apply(rule assms(5))
        using assms(1)
        by simp
    next
      assume \<open>connected_component E u \<noteq> connected_component E v\<close>
      then show ?thesis
      apply(rule assms(4)[OF \<open>u \<in> Vs E\<close> \<open>v \<in> Vs E\<close>])
      using assms(1)
      apply(subst connected_components_insert_1'[OF \<open>u \<in> Vs E\<close> \<open>v \<in> Vs E\<close>, symmetric])
      .
    qed
  next
    assume \<open>v \<notin> Vs E\<close>
    show ?thesis
      apply(rule assms(3)[where u' = u and v' = v])
      using assms(1) \<open>u \<in> Vs E\<close> \<open>v \<notin> Vs E\<close>
      by (auto simp: connected_components_insert_2'[symmetric])
  qed
next
  assume \<open>u \<notin> Vs E\<close>
  show ?thesis
  proof(cases \<open>v \<in> Vs E\<close>)
    assume \<open>v \<in> Vs E\<close>
    show ?thesis
      apply(rule assms(3)[where u' = v and v' = u])
      using assms(1) \<open>u \<notin> Vs E\<close> \<open>v \<in> Vs E\<close>
      by (auto simp: connected_components_insert_2'[symmetric] insert_commute)
  next
    assume \<open>v \<notin> Vs E\<close>
    show ?thesis
      apply(rule assms(2)[OF \<open>u \<notin> Vs E\<close> \<open>v \<notin> Vs E\<close>])
      using assms(1)
      apply(subst connected_components_insert_3'[OF \<open>u \<notin> Vs E\<close> \<open>v \<notin> Vs E\<close>, symmetric])
      .
  qed
qed

lemma exists_Unique_iff: "(\<exists>!x. P x) \<longleftrightarrow> (\<exists>x. P x \<and> (\<forall>y. P y \<longrightarrow> y = x))"
  by auto

lemma degree_one_unique:
  assumes "degree E v = 1"
  shows "\<exists>!e \<in> E. v \<in> e"
  using assms
proof-
  from assms obtain e where "{e} = {e. v \<in> e} \<inter> E"
    by (fastforce simp only: degree_def elim!: card'_1_singletonE)
  thus ?thesis
    by (auto simp: exists_Unique_iff)
qed

lemma complete_path_degree_one_head_or_tail:
  assumes "path E p" "distinct p" "v \<in> set p" "degree E v = 1"
  shows "v = hd p \<or> v = last p"
proof(rule ccontr)
  assume "\<not> (v = hd p \<or> v = last p)"
  hence "v \<noteq> hd p" "v \<noteq> last p" by simp_all
  hence "degree (set (edges_of_path p)) v = 2"
    by (simp add: degree_edges_of_path_ge_2 assms(2) assms(3))
  hence "2 \<le> degree E v"
    using subset_edges_less_degree[OF path_edges_subset[OF assms(1)], where v = v]
    by presburger
  then show False
    using assms(4) not_eSuc_ilei0
    by simp
qed

(*
  The proof of the following theorem should be improved by devising an induction principle for
  edges and connected components.
*)

lemma gr_zeroI: "(x::enat) \<noteq> 0 \<Longrightarrow> 0 < x"
  by auto

lemma degree_neq_zeroI: "\<lbrakk>e \<in> E; v \<in> e\<rbrakk> \<Longrightarrow> degree E v \<noteq> 0"
  by (auto simp add: degree_def)

lemma exists_conj_elim_2_1: "\<lbrakk>\<And>x. \<lbrakk>P x; Q x\<rbrakk> \<Longrightarrow> V x; \<lbrakk>\<And>x. P x \<and> Q x \<Longrightarrow> V x\<rbrakk> \<Longrightarrow> S\<rbrakk> \<Longrightarrow> S"
  by auto

lemma exists_conj_elim_3_1: "\<lbrakk>\<And>x. \<lbrakk>P x; Q x; V x\<rbrakk> \<Longrightarrow> W x; \<lbrakk>\<And>x. P x \<and> Q x \<and> V x \<Longrightarrow> W x\<rbrakk> \<Longrightarrow> S\<rbrakk> \<Longrightarrow> S"
  by auto

lemma exists_conj_elim_4_1: "\<lbrakk>\<And>x. \<lbrakk>P x; Q x; V x; W x\<rbrakk> \<Longrightarrow> X x; \<lbrakk>\<And>x. P x \<and> Q x \<and> V x \<and> W x \<Longrightarrow> X x\<rbrakk> \<Longrightarrow> S\<rbrakk> \<Longrightarrow> S"
  by auto

lemma exists_conj_elim_2_2: "\<lbrakk>\<And>x y. \<lbrakk>P x y; Q x y\<rbrakk> \<Longrightarrow> V x y; \<lbrakk>\<And>x y. P x y \<and> Q x y \<Longrightarrow> V x y\<rbrakk> \<Longrightarrow> S\<rbrakk> \<Longrightarrow> S"
  by auto

lemma exists_conj_elim_3_2: "\<lbrakk>\<And>x y. \<lbrakk>P x y; Q x y; V x y\<rbrakk> \<Longrightarrow> W x y; \<lbrakk>\<And>x y. P x y \<and> Q x y \<and> V x y \<Longrightarrow> W x y\<rbrakk> \<Longrightarrow> S\<rbrakk> \<Longrightarrow> S"
  by auto

lemma exists_conj_elim_4_2: "\<lbrakk>\<And>x y. \<lbrakk>P x y; Q x y; V x y; W x y\<rbrakk> \<Longrightarrow> X x y; \<lbrakk>\<And>x y. P x y \<and> Q x y \<and> V x y \<and> W x y \<Longrightarrow> X x y\<rbrakk> \<Longrightarrow> S\<rbrakk> \<Longrightarrow> S"
  by auto

lemma exists_conj_elim_2_3: "\<lbrakk>\<And>x y z. \<lbrakk>P x y z; Q x y z\<rbrakk> \<Longrightarrow> V x y z; \<lbrakk>\<And>x y z. P x y z \<and> Q x y z \<Longrightarrow> V x y z\<rbrakk> \<Longrightarrow> S\<rbrakk> \<Longrightarrow> S"
  by auto

lemma exists_conj_elim_3_3: "\<lbrakk>\<And>x y z. \<lbrakk>P x y z; Q x y z; V x y z\<rbrakk> \<Longrightarrow> W x y z; \<lbrakk>\<And>x y z. P x y z \<and> Q x y z \<and> V x y z \<Longrightarrow> W x y z\<rbrakk> \<Longrightarrow> S\<rbrakk> \<Longrightarrow> S"
  by auto

lemma exists_conj_elim_4_3: "\<lbrakk>\<And>x y z. \<lbrakk>P x y z; Q x y z; V x y z; W x y z\<rbrakk> \<Longrightarrow> X x y z; \<lbrakk>\<And>x y z. P x y z \<and> Q x y z \<and> V x y z \<and> W x y z \<Longrightarrow> X x y z\<rbrakk> \<Longrightarrow> S\<rbrakk> \<Longrightarrow> S"
  by auto

lemma exists_conj_elim_5_3: "\<lbrakk>\<And>x y z. \<lbrakk>P x y z; Q x y z; V x y z; W x y z; X x y z\<rbrakk> \<Longrightarrow> Y x y z; \<lbrakk>\<And>x y z. P x y z \<and> Q x y z \<and> V x y z \<and> W x y z \<and> X x y z \<Longrightarrow> Y x y z\<rbrakk> \<Longrightarrow> S\<rbrakk> \<Longrightarrow> S"
  by auto

lemma exists_conj_elim_5_3': "\<lbrakk>\<And>x y z. \<lbrakk>P x y z; Q x y z; V x y z; W x y z; X x y z\<rbrakk> \<Longrightarrow> Y x y z; \<lbrakk>\<And>x y z. P x y z \<and> Q x y z \<and> V x y z \<and> W x y z \<and> X x y z \<Longrightarrow> Y x y z\<rbrakk> \<Longrightarrow> S\<rbrakk> \<Longrightarrow> S"
  by auto

lemma exists_conj_elim_6_3: "\<lbrakk>\<And>x y z. \<lbrakk>P x y z; Q x y z; V x y z; W x y z; X x y z; Y x y z\<rbrakk> \<Longrightarrow> Z x y z; \<lbrakk>\<And>x y z. P x y z \<and> Q x y z \<and> V x y z \<and> W x y z \<and> X x y z \<and> Y x y z \<Longrightarrow> Z x y z\<rbrakk> \<Longrightarrow> S\<rbrakk> \<Longrightarrow> S"
  by auto

method instsantiate_obtains =
  (match conclusion in "P" for P
     \<Rightarrow> \<open>(match premises in ass[thin]: "\<And>x. _ x \<Longrightarrow> P" \<Rightarrow> \<open>rule ass\<close>) |
         (match premises in ass[thin]: "\<And>x y. _ x y \<Longrightarrow> P" \<Rightarrow> \<open>rule ass\<close>)\<close>)

lemmas exists_conj_elims = exists_conj_elim_2_1 exists_conj_elim_3_1 exists_conj_elim_4_1
                           exists_conj_elim_2_2 exists_conj_elim_3_2 exists_conj_elim_4_2

lemma edge_mid_path:
  "path E (p1 @ [v1,v2] @ p2) \<Longrightarrow> {v1,v2} \<in> E"
  using path_suff
  by fastforce

lemma snoc_eq_iff_butlast':
  "ys = xs @ [x] \<longleftrightarrow> (ys \<noteq> [] \<and> butlast ys = xs \<and> last ys = x)"
  by fastforce

lemma neq_Nil_conv_snoc: "xs \<noteq> [] \<longleftrightarrow> (\<exists>x ys. xs = ys @ [x])"
  by (auto simp add: snoc_eq_iff_butlast')

lemma degree_2: "\<lbrakk>{u,v} \<in> E; {v,w} \<in> E; distinct [u,v]; u \<noteq> w; v \<noteq> w\<rbrakk> \<Longrightarrow>2 \<le> degree E v"
  using degree_insert[where a = "{u,v}" and E = "E - {{u,v}}"]
  using degree_insert[where a = "{v,w}" and E = "(E - {{u,v}}) - {{v,w}}"]
  by (auto simp: degree_def doubleton_eq_iff eval_enat_numeral one_eSuc split: if_splits)

lemma degree_3:
 "\<lbrakk>{u,v} \<in> E; {v,w} \<in> E; {v, x} \<in> E; distinct [u,v,w]; u \<noteq> x; v \<noteq> x; w \<noteq> x\<rbrakk> \<Longrightarrow> 3 \<le> degree E v"
  using degree_insert[where a = "{u,v}" and E = "E - {{u,v}}"]
  using degree_insert[where a = "{v,w}" and E = "(E - {{u,v}}) - {{v,w}}"]
  using degree_insert[where a = "{v,x}" and E = "((E - {{u,v}}) - {{v,w}}) - {{v, x}}"]
  by (auto simp: degree_def doubleton_eq_iff eval_enat_numeral one_eSuc split: if_splits)

lemma Hilbert_choice_singleton: "(SOME x. x \<in> {y}) = y"
  by force

lemma Hilbert_set_minus: "s - {y} \<noteq>{} \<Longrightarrow> y \<noteq> (SOME x. x \<in> s - {y})"
  by(force dest!: iffD2[OF some_in_eq])

lemma connected_components_empty: "connected_components {} = {}"
  by (auto simp: connected_components_def Vs_def)

theorem component_has_path_distinct:
  assumes "finite E" and
    "C \<in> connected_components E" and
    "\<And>v. v\<in>Vs E \<Longrightarrow> degree E v \<le> 2" and
    "\<And>e. e\<in>E \<Longrightarrow> \<exists>u v. e = {u, v} \<and> u \<noteq> v"
  shows "\<exists>p. path E p \<and> C = (set p) \<and> distinct p"
  using assms
proof(induction "E" arbitrary: C)    
  case (insert e E')
  then obtain u v where uv[simp]: "e = {u,v}" "u \<noteq> v"
    by (force elim!: exists_conj_elims)
  hence "u \<in> Vs (insert e E')" "v \<in> Vs (insert e E')"
    using insert
    by (auto simp: Vs_def)
  moreover have "degree (insert e E') u \<noteq> 0" "degree (insert e E') v \<noteq> 0"
    by(fastforce simp: degree_neq_zeroI[where e = e])+
  moreover have "\<lbrakk>x \<noteq>0; x \<noteq> 1; x \<noteq> 2\<rbrakk> \<Longrightarrow> 2 < x" for x::enat
    by (fastforce simp: eval_enat_numeral one_eSuc dest!: ileI1[simplified order_le_less] dest: gr_zeroI)  
  ultimately have degree_uv:
    "degree (insert e E') u \<le> 2" "degree (insert e E') v \<le> 2"
    by (auto simp: linorder_not_le[symmetric] simp del: \<open>e = {u,v}\<close>
        dest!: \<open>\<And>v'. v' \<in> Vs (insert e E') \<Longrightarrow> degree (insert e E') v' \<le> 2\<close>)

  have "v \<in> Vs E' \<Longrightarrow> degree E' v \<le> 2" for v
    using subset_edges_less_degree[where E' = E' and E = "insert e E'"]
    by (fastforce intro: dual_order.trans dest!: insert.prems(2) dest: in_Vs_insert[where e = e])
  then have IH: "C \<in> connected_components E' \<Longrightarrow> \<exists>p. path E' p \<and> C = set p \<and> distinct p"    
    for C
    by (auto intro: insert)

  have deg_3: False
    if "p1 \<noteq> []" "p2 \<noteq> []" "path E (p1 @ u' # p2)" "{u, v} \<in> E" "v' \<notin> set (p1 @ u' # p2)"
      "distinct (p1 @ u' # p2)" "u' \<in> {u,v}" "u \<noteq> v" "v' \<in> {u, v}"
      "degree E u' \<le> 2"
    for E p1 u' v' p2
  proof-
    obtain v1 p1' where [simp]: "p1 = p1' @ [v1]"
      using \<open>p1 \<noteq> []\<close>
      by (auto simp: neq_Nil_conv_snoc)
    moreover obtain v2 p2' where [simp]: "p2 = v2 # p2'"
      using \<open>p2 \<noteq> []\<close>
      by (auto simp: neq_Nil_conv)
    ultimately have "v1 \<noteq> v2"
      using \<open>distinct (p1 @ u' # p2)\<close> \<open>path E (p1 @ u' # p2)\<close> path_2 path_suff
      by fastforce+
    moreover have "{v1,u'} \<in> E" "{u',v2} \<in> E"
      using \<open>path E (p1 @ u' # p2)\<close> path_2 path_suff
      by fastforce+
    moreover have "v1 \<noteq> v" "v1 \<noteq> u" "v2 \<noteq> v" "v2 \<noteq> u"
      using \<open>u' \<in> {u,v}\<close> \<open>v' \<in> {u, v}\<close> \<open>distinct (p1 @ u' # p2)\<close> \<open>v' \<notin> set (p1 @ u' # p2)\<close>
        mem_path_Vs[OF \<open>path E (p1 @ u' # p2)\<close>] \<open>u \<noteq> v\<close>
      by fastforce+
    moreover have "{u', SOME x. x \<in> {u, v} - {u'}} = {u,v}"
    proof-
      have "{u,v} - {v} = {u}"
        using \<open>u \<noteq> v\<close>
        by auto
      thus ?thesis
        using \<open>u' \<in> {u, v}\<close> \<open>u \<noteq> v\<close>
        by (fastforce simp add: Hilbert_choice_singleton)
    qed
    moreover have "u' \<noteq> (SOME x. x \<in> {u, v} - {u'})"
      using \<open>u' \<in> {u,v}\<close> \<open>u \<noteq> v\<close>
      by (fastforce intro!: Hilbert_set_minus)
    ultimately have "3 \<le> degree E u'"
      using \<open>{u, v} \<in> E\<close> \<open>v' \<notin> set (p1 @ u' # p2)\<close> \<open>distinct (p1 @ u' # p2)\<close>
      by (intro degree_3[where u = v1 and w = v2 and x = "SOME x. x \<in> ({u,v} - {u'})"]) auto
    thus False
      using degree_uv \<open>u' \<in> {u,v}\<close> \<open>degree E u' \<le> 2\<close>
      by(auto simp add: eval_enat_numeral one_eSuc dest: order_trans[where z = "eSuc 1"])
  qed

  from \<open>C \<in> connected_components (insert e E')\<close>[simplified \<open>e = {u, v}\<close>]
  show ?case
  proof(elim in_insert_connected_componentE, goal_cases)
    case 1
    then show ?case
    proof(safe, goal_cases)
      case 1
      then show ?case
        using \<open>u \<noteq> v\<close> \<open>v \<in> Vs (insert e E')\<close> \<open>e = {u,v}\<close>
        by (fastforce intro!: exI[where x = "[u, v]"])
    qed (fastforce dest: IH intro: path_subset)
  next
    case (2 u' v')
    moreover obtain p where "path E' p" "(connected_component E' u') = set p" "distinct p"
      using \<open>u' \<in> Vs E'\<close>
      by (force elim!: exists_conj_elims intro: IH simp add: connected_component_in_components)
    moreover then obtain p1 p2 where [simp]: "p = p1 @ u' # p2" "u' \<notin> set p1"
      using in_own_connected_component iffD1[OF in_set_conv_decomp_first]
      by (force elim!: exists_conj_elims)
    moreover hence "u' \<notin> set p2"
      using \<open>distinct p\<close>
      by auto
    moreover have "v' \<notin> set (p1 @ u' # p2)"
      using \<open>v' \<notin> Vs E'\<close> mem_path_Vs[OF \<open>path E' p\<close> ]
      by auto
    ultimately have False
      if "p1 \<noteq> []" "p2 \<noteq> []"
      by (fastforce intro!: deg_3[OF that, where E = "insert e E'" and v' = v' and u' = u']
          intro!: insert(5) in_Vs_insert dest: path_subset[where E' = "insert e E'"])
    hence "p1 = [] \<or> p2 = []"
      by auto

    from "2"(5) show ?case
    proof(elim insertE[where a = C], goal_cases)
      case 1
      moreover from 2 have "path (insert e E') (v' # u' # p2)"
        using \<open>path E' p\<close>[simplified]
        by (fastforce intro: path_subset dest: path_suff)
      moreover from 2 have "path (insert e E') (p1 @ [u', v'])" if "p2 = []"
        using \<open>path E' p\<close>[simplified ] that 
        by (subst rev_path_is_path_iff[symmetric], subst (asm) rev_path_is_path_iff[symmetric]) (auto intro: path_subset)

      ultimately show ?case
        using \<open>p1 = [] \<or> p2 = []\<close> \<open>distinct p\<close> \<open>u' \<notin> set p2\<close> mem_path_Vs \<open>path E' p\<close> "2"(1-4)
        by (force intro!: exI[where x = "if p1 = [] then  v' # u' # p2 else p1 @ [u', v']"]
            simp add: \<open>connected_component E' u' = set p\<close>)
    qed (fastforce dest: IH intro: path_subset)
  next
    case 3

    from \<open>connected_component E' u \<noteq> connected_component E' v\<close>
    have "v \<notin> connected_component E' u" "u \<notin> connected_component E' v"
      using connected_components_member_eq
      by (fastforce simp only:)+
    from \<open>connected_component E' u \<noteq> connected_component E' v\<close>
    have "connected_component E' u \<inter> connected_component E' v = {}"
      using connected_components_disj
      by(auto intro!: connected_component_in_components 3)

    {
      fix u'
      assume "u' \<in> {u,v}"
      then obtain v' where \<open>v' \<in> {u,v}\<close> \<open>u' \<noteq> v'\<close>
        using uv(2)
        by blast
      obtain p where i: "path E' p" "(connected_component E' u') = set p" "distinct p"
        using \<open>u \<in> Vs E'\<close> \<open>v \<in> Vs E'\<close> \<open>u' \<in> {u,v}\<close>
        by (force elim!: exists_conj_elims intro: IH simp add: connected_component_in_components)
      moreover then obtain p1 p2 where [simp]: "p = p1 @ u' # p2" "u' \<notin> set p1"
        using in_own_connected_component iffD1[OF in_set_conv_decomp_first]
        by (force elim!: exists_conj_elims)
      moreover hence "u' \<notin> set p2"
        using \<open>distinct p\<close>
        by auto
      moreover have "v' \<notin> set (p1 @ u' # p2)"
        using \<open>v \<notin> connected_component E' u\<close> \<open>u \<notin> connected_component E' v\<close>
          \<open>connected_component E' u' = set p\<close> \<open>u' \<in> {u,v}\<close> \<open>v' \<in> {u,v}\<close> \<open>u' \<noteq> v'\<close>
        by auto
      ultimately have False
        if "p1 \<noteq> []" "p2 \<noteq> []"
        using \<open>u' \<in> {u,v}\<close> \<open>v' \<in> {u,v}\<close> degree_uv
        by (intro deg_3[OF that, where E = "insert e E'" and v' = v' and u' = u']) 
          (force intro!: degree_uv(1) in_Vs_insert dest: path_subset[where E' = "insert e E'"])+
      hence "p1 = [] \<or> p2 = []"
        by auto
      hence "\<exists>p p1 p2. path E' p \<and> (connected_component E' u') = set p \<and> distinct p \<and>
                       p = p1 @ u' # p2 \<and> (p1 = [] \<or> p2 = [])"
        by (fastforce intro!: i intro: exI[where x = p])
    } note * = this

    obtain p p1 p2 where
      "path E' p" "(connected_component E' u) = set p" "distinct p" "(p1 = [] \<or> p2 = [])" and
      [simp]: "p = p1 @ u # p2"
      apply (elim exists_conj_elim_5_3)
      using *
      by blast

    obtain p' p1' p2' where
      "path E' p'" "(connected_component E' v) = set p'" "distinct p'" "(p1' = [] \<or> p2' = [])" and
      [simp]: "p' = p1' @ v # p2'"
      apply (elim exists_conj_elim_5_3)
      using *
      by blast
    from "3"(4) show ?case
    proof(elim insertE[where a = C], goal_cases)
      case 1
      define witness_p where
        "witness_p = 
               (if p1 = [] \<and> p1' = [] then
                  (rev p2 @ [u, v] @ p2')
                else if p1 = [] \<and> p2' = [] then
                  (rev p2 @ [u, v] @ rev p1')
                else if p2 = [] \<and> p1' = [] then
                  (p1 @ [u, v] @ p2')
                else if p2 = [] \<and> p2' = [] then
                  (p1 @ [u, v] @ rev p1')
                else
                  undefined)"

      from \<open>p1 = [] \<or> p2 = []\<close> \<open>p1' = [] \<or> p2' = []\<close> have "path (insert e E') witness_p"
        using \<open>path E' p\<close> \<open>path E' p'\<close>
        by (auto intro!: path_subset[where E' = "(insert {u, v} E')"]
            path_concat[where p = "p1 @ [u]" and q = "u # v # rev p1'", simplified]
            path_concat[where p = "rev p2 @ [u]" and q = "u # v # p2'", simplified]
            path_concat[where p = "rev p2 @ [u]" and q = "u # v # rev p1'", simplified]
            path_concat[where p = "p1 @ [u]" and q = "u # v # []", simplified]
            path_concat[where p = "p1 @ [u]" and q = "u # v # p2'", simplified]
            simp: rev_path_is_path_iff[symmetric, where p = "(rev p2 @ [u])"]
            rev_path_is_path_iff[symmetric, where p = "(rev p2 @ [u, v])"]
            rev_path_is_path_iff[symmetric, where p = "(v # rev p1')"]
            witness_p_def
            split: if_splits)
      moreover from \<open>p1 = [] \<or> p2 = []\<close> \<open>p1' = [] \<or> p2' = []\<close> have "distinct witness_p"
        using \<open>distinct p\<close> \<open>distinct p'\<close>
          \<open>(connected_component E' u) = set p\<close>
          \<open>v \<notin> connected_component E' u\<close>
          \<open>(connected_component E' v) = set p'\<close>
          \<open>u \<notin> connected_component E' v\<close>
          \<open>connected_component E' u \<inter> connected_component E' v = {}\<close>
        by (fastforce simp: witness_p_def  split: if_splits)
      moreover from \<open>p1 = [] \<or> p2 = []\<close> \<open>p1' = [] \<or> p2' = []\<close> have "C = set witness_p"
        using \<open>(connected_component E' u) = set p\<close> \<open>(connected_component E' v) = set p'\<close>
          \<open> C = connected_component E' u \<union> connected_component E' v\<close>
        by (fastforce simp: witness_p_def  split: if_splits)
      ultimately show ?case
        by auto
    qed (fastforce dest: IH intro: path_subset)
  qed (fastforce dest: IH intro: path_subset)
qed (auto simp: connected_components_empty intro!: exI[where x = "[]"])


section\<open>Undirected Graphs\<close>

lemma finite_dbl_finite_verts: "finite G \<Longrightarrow> dblton_graph G \<Longrightarrow> finite (Vs G)"
  by (auto simp: Vs_def dblton_graph_def)

definition connected_at where
  "connected_at v e e' \<equiv> (v \<in> (e \<inter> e'))"


lemma nempty_tl_hd_tl:
  "(tl l) \<noteq>[] \<Longrightarrow> l = (hd l) # (tl l)"
  by (induct "l"; simp)

lemma card3_subset:
  assumes "card s \<ge> 3"
  shows "\<exists>x y z. {x, y, z} \<subseteq> s \<and> x \<noteq> y  \<and> x \<noteq> z  \<and> y \<noteq> z"  
  using assms by(auto simp: numeral_3_eq_3 card_le_Suc_iff)


(*subsection \<open>Paths: lists of vertices that are not necessarily simple\<close>

inductive path_abs for P P0 where
  path_abs0: "path_abs P P0 []" |
  path_abs1: "P0 v \<Longrightarrow> path_abs P P0 [v]" |
  path_abs2: "P v v' \<Longrightarrow> path_abs P P0 (v'#vs) \<Longrightarrow> path_abs P P0 (v#v'#vs)"

declare path_abs0[simp]

inductive_simps path_abs1[simp]: "path_abs P P0 [v]"

inductive_simps path_abs2[simp]: "path_abs P P0 (v # v' # vs)"

inductive path_abs_bet for P P0 where
  path_abs_bet0: "path_abs_bet P P0 [] v v'" |
  path_abs_bet1: "P0 v \<Longrightarrow> v = v' \<Longrightarrow> path_abs_bet P P0 [v] v v'" |
  path_abs_bet2: "P0 v \<Longrightarrow> P0 v' \<Longrightarrow> P v v'\<Longrightarrow> path_abs_bet P P0 (v'#vs) v' v'' \<Longrightarrow> path_abs_bet P P0 (v#v'#vs) v v''"

declare path_abs_bet0[simp]

inductive_simps path_abs_bet1[simp]: "path_abs_bet P P0 [v] v v'"

inductive_simps path_abs_bet2[simp]: "path_abs_bet P P0 (v#v'#vs) v v''"*)

lemma mid_path_deg_ge_2:
  assumes "path E p"
    "v \<in> set p"
    "v \<noteq> hd p"
    "v \<noteq> last p"
    "distinct p"
    "finite E"
  shows "degree E v \<ge> 2"
  using assms
  by (metis degree_edges_of_path_ge_2 path_edges_subset subset_edges_less_degree)


lemma path_repl_edge:
  assumes "path E' p" "p \<noteq> []" "E' = (insert {w,x} E)" "path E puv" "hd puv = w" "last puv = x" "puv \<noteq> []"
  shows "\<exists>p'. p' \<noteq> [] \<and> path E p' \<and> hd p' = hd p \<and> last p' = last p"
  using assms
  by (metis walk_betw_repl_edge walk_betw_def)

lemma path_can_be_split:
  assumes "path E' p" "E' = insert {w,x} E" "{w,x} \<subseteq> Vs E" "p \<noteq> []"
  shows "(\<exists>p'. p' \<noteq> [] \<and> path E p' \<and> hd p' = hd p \<and> last p' = last p) \<or>
         (\<exists>p1 p2. p1 \<noteq> [] \<and> p2 \<noteq> [] \<and> path E p1 \<and> path E p2 \<and>
                             ((last p1 = w \<and> hd p2 = x) \<or> (last p1 = x \<and> hd p2 = w)) \<and>
                             hd p1 = hd p \<and> last p2 = last p)"
  using assms
  using vwalk_betw_can_be_split[OF _ , simplified walk_betw_def, where p = p and u = "hd p" and v = "last p"]
  apply simp
  by (smt (verit, ccfv_SIG))

lemma path_can_be_split_2:
  assumes "path (insert {w,x} E) p" "w \<in> Vs E" "x \<notin> Vs E" "p \<noteq> []"
  shows "(\<exists>p'. p' \<noteq> [] \<and> path E p' \<and> hd p' = hd p \<and> last p' = last p) \<or>
         (\<exists>p'. path E p' \<and> (p' \<noteq> [] \<longrightarrow> hd p' = w) \<and> ((hd p = last (x # p') \<and> last p = x) \<or> (hd p = x \<and> last p = last (x # p'))))"
  using vwalk_betw_can_be_split_2[OF _ \<open>w \<in> Vs E\<close> \<open>x \<notin> Vs E\<close>, simplified walk_betw_def, where p = p and u = "hd p" and v = "last p"]
  using assms
  apply simp
  by (smt (verit, del_insts) hd_rev last.simps last_rev path_simps(1) rev_is_Nil_conv rev_path_is_path_iff) 

lemma path_can_be_split_3:
  assumes "path E' p" "E' = insert {w,x} E" "w \<notin> Vs E" "x \<notin> Vs E" "p \<noteq> []"
  shows "path E p \<or> path {{w, x}} p"
  using assms
proof(induction)
  case (path2 v v' vs)
  show ?case
  proof(cases "path E (v' #  vs)")
    case True
    then have "path E (v # v' # vs)"
      using path2
      by (force simp: doubleton_eq_iff mem_path_Vs)
    then show ?thesis
      by auto
  next
    case False
    then have path: "path {{w,x}} (v' # vs)"
      using path2
      by auto
    then have "v' = w \<or> v' = x"
      by (cases "vs"; auto simp add: doubleton_eq_iff Vs_def)
    then have "path {{w,x}} (v # v' # vs)"
      using path path2
      by (auto simp: edges_are_Vs)
    then show ?thesis
      by auto
  qed
qed (auto simp add: Vs_def)

lemma v_in_apath_in_Vs_append:
  "path E (p1 @ v # p2) \<Longrightarrow> v \<in> Vs E"
  by (simp add: mem_path_Vs)

lemma edge_between_pref_suff:
  "\<lbrakk>p1 \<noteq> []; p2 \<noteq> []; path G (p1 @ p2)\<rbrakk>
    \<Longrightarrow> {last p1, hd p2} \<in> G"
  by(induction p1) (auto simp: neq_Nil_conv)+

lemma construct_path:
 "\<lbrakk>path G p1; path G p2; {hd p1, hd p2} \<in> G\<rbrakk>
   \<Longrightarrow> path G ((rev p1) @ p2)"
  by (simp add: last_rev path_append rev_path_is_path)

text \<open>A function to remove a cycle from a path\<close>

fun remove_cycle_pfx where
"remove_cycle_pfx a [] = []" |
"remove_cycle_pfx a (b#l) = (if (a = b) then (remove_cycle_pfx a l) else (b#l))"

lemma remove_cycle_pfx_works:
 "\<exists>pfx. (l = pfx @ (remove_cycle_pfx h l) \<and> (\<forall>x\<in>set pfx. x = h))"
proof(induction l)
  case Nil
  then show ?case by simp
next
  case (Cons a l)
  then obtain pfx where "l = pfx @ remove_cycle_pfx h l \<and> (\<forall>x\<in>set pfx. x = h)"
    by blast
  then have *: "a # l = (a # pfx) @ remove_cycle_pfx a l \<and> (\<forall>x\<in>set pfx. x = a)" if "h = a"
    using append_Cons that by auto
  show ?case
   by (fastforce dest: *)
qed

lemma remove_cycle_pfx_works_card_ge_2:
 "card (set l) \<ge> 2 \<Longrightarrow> (hd (remove_cycle_pfx (last l) l) \<noteq> last (remove_cycle_pfx (last l) l) \<and> (set (remove_cycle_pfx (last l) l) = set l))"
proof(induction l)
  case Nil
  then show ?case by simp
next
  case (Cons a l)
  show ?case
  proof(cases "card (set l) < 2")
    case True
    then show ?thesis
      using Cons(2)
      by (auto simp: insert_absorb)
  next
    case False
    then have *: "card (set l) \<ge> 2"
      by simp
    show ?thesis
      using Cons(1)[OF *]
      using "*" by force
  qed
qed

lemma edges_of_path_nempty:
  "edges_of_path xs \<noteq> [] \<longleftrightarrow> length xs \<ge> 2"
  by(induction xs rule: edges_of_path.induct) auto

lemma degree_edges_of_path_ge_2':
  "\<lbrakk>distinct p; v\<in>set p; v \<noteq> hd p; v \<noteq> last p\<rbrakk>
    \<Longrightarrow> degree (set (edges_of_path p)) v \<ge> 2"
  using degree_edges_of_path_ge_2
  by force

(*
lemma degree_edges_of_path_ge_2_all:
  assumes "distinct p" "length p \<ge> 3" "v\<in>set p"
  shows "degree (set (edges_of_path (last p # p))) v \<ge> 2"
  using assms
proof(cases "v = hd p \<or> v = last p")
  case True
  moreover obtain a a' a'' p' where p: "p = a # a' # a'' # p'"
    using assms(2)
    apply(cases p; simp)
    by (metis One_nat_def Suc_1 Suc_le_length_iff)
  ultimately have "v = a \<or> v = last (a'' # p')"
    by auto
  moreover have "degree (set (edges_of_path (last p # p))) a \<ge> 2"
    using assms(1)
    using v_in_edge_in_path_gen v_in_edge_in_path 
    by (fastforce simp add: eval_nat_numeral eval_enat_numeral insert_Diff_if doubleton_eq_iff one_eSuc p degree_def)

  moreover have "degree (set (edges_of_path (last p # p))) (last (a'' # p')) \<ge> 2"
    unfolding p 
    apply (auto simp add: doubleton_eq_iff split: if_splits)
    subgoal using assms(1)
    using v_in_edge_in_path_gen v_in_edge_in_path 
    by (fastforce simp add: eval_nat_numeral eval_enat_numeral insert_Diff_if doubleton_eq_iff one_eSuc p degree_def)
    subgoal proof-
      assume ass: "p' \<noteq> []"
      define E where "E = {e. last p' \<in> e} \<inter> ((insert {last p', a} (insert {a, a'} (insert {a', a''} (set (edges_of_path (a'' # p')))))))"
      obtain u where u: "{u, last p'} \<in> set (edges_of_path (a'' # p')) \<and> u \<in> set (a'' # p')" "u \<in> set (a'' # p')"
        using last_in_edge[OF ass]
        by auto
      moreover have "{u, last p'} \<noteq> {a, last p'}"
        using assms(1) u
        by (auto simp add: p doubleton_eq_iff)
      moreover have "{u, last p'} \<in> E"
        "{a, last p'} \<in> E"
        using u E_def
        by auto
      moreover have "card s \<ge> 2" if "finite s" "x \<in> s" "y \<in> s" "x \<noteq> y" for x y s
        using that
        by (metis One_nat_def Suc_1 Suc_leI Suc_mono card_gt_0_iff card_insert_disjoint finite_insert insertE mk_disjoint_insert)
      moreover have "finite E"
        using E_def
        by auto
      ultimately show ?thesis
        apply( simp add : degree_def E_def)
        by (smt (verit, ccfv_threshold) Suc_leD ass assms(1) assms(2) degree_def degree_edges_of_path_last distinct.simps(2) distinct_length_2_or_more doubleton_eq_iff edges_of_path.simps(3) eval_enat_numeral(1) eval_enat_numeral(2) last_ConsR list.discI list.simps(15) numeral_3_eq_3 numerals(2) one_eSuc order_le_less p semiring_norm(26) v_in_edge_in_path)
    qed
    done
  ultimately show ?thesis
    by auto
next
  case False
  then show ?thesis
    using degree_edges_of_path_ge_2 assms(1)
    by (smt List.finite_set assms(3) degree_edges_of_path_ge_2 dual_order.trans edges_of_path.simps(3) ex_in_conv in_edges_of_path list.exhaust_sel set_empty set_subset_Cons subset_edges_less_degree)
qed*)

lemma last_edge_in_last_vert_in:
  assumes "length p \<ge> 2" "last (edges_of_path p) \<in> E"
  shows "last p \<in> Vs E"
  using assms
proof(induction p rule: edges_of_path.induct)
  case (3 v v' l)
  then show ?case
  using last_in_edge[where p="v'#l"]
  by( auto split: if_splits simp: neq_Nil_conv)
qed auto
 
lemma hd_edge_in_hd_vert_in:
  assumes "length p \<ge> 2" "hd (edges_of_path p) \<in> E"
  shows "hd p \<in> Vs E"
  using assms
proof(induction p rule: edges_of_path.induct)
  case (3 v v' l)
  then show ?case
  using last_in_edge[where p="v'#l"]
  by( auto split: if_splits simp: neq_Nil_conv)
qed auto

lemma last_vert_in_last_edge:
  assumes "last p \<in> e" "e \<in> set (edges_of_path p)" "distinct p" "length p \<ge> 2"
  shows "e = last (edges_of_path p)"
  using assms
proof(induction p)
  case Nil
  then show ?case by simp
next
  case cons1: (Cons a p)
  then show ?case
  proof(cases p)
    case Nil
    then show ?thesis using cons1 by simp
  next
    case cons2: (Cons a' p')
    then show ?thesis 
      using cons1 cons2 not_less_eq_eq
      by (auto split: if_splits)
  qed
qed

lemma degree_inc:
  assumes "finite E1" "e \<notin> E1" "v \<in> e"
  shows "degree (insert e E1) v = degree E1 v + 1"
  using assms
  by (simp add: degree_insert eSuc_plus_1)


lemma edges_of_path_snoc:
  assumes "p \<noteq> []"
  shows "(edges_of_path p) @ [{last p, a}] = edges_of_path (p @ [a])"
  using assms
  by (simp add: edges_of_path_append_3)

lemma in_edges_of_path_split: "e \<in> set (edges_of_path p) \<Longrightarrow> \<exists>v1 v2 p1 p2. e = {v1, v2} \<and> p = p1 @ [v1, v2] @ p2"
proof(induction p)
  case Nil
  then show ?case
    by auto
next
  case (Cons v p')
  then have "p' \<noteq> []"
    by auto
  show ?case
  proof(cases "e \<in> set (edges_of_path p')")
    case True
    then show ?thesis
      using Cons
      by (metis append_Cons)
  next
    case False
    then have "e = {v, hd p'}"
      using Cons
      by (cases p'; auto)
    moreover have "v # p' = [] @ [v, hd p'] @ tl p'"
      using \<open>p' \<noteq> []\<close>
      by auto
    ultimately show ?thesis
      by metis
  qed
qed

lemma in_edges_of_path_hd_or_tl:
      assumes "e \<in> set (edges_of_path p)"
      shows "e = hd (edges_of_path p) \<or> e \<in> set (edges_of_path (tl p))"
proof-
  obtain v1 v2 p1 p2 where "e = {v1, v2}" "p = p1 @ [v1, v2] @ p2"
    using in_edges_of_path_split[OF assms]
    by auto
  then show ?thesis
    apply(cases "p1 = []"; simp)
    using edges_of_path_append_2
    by (metis edges_of_path.simps(3) in_set_conv_decomp list.distinct(1))
qed

lemma where_is_v:
  assumes "e \<in> set (edges_of_path (p @ (v # p')))" "v \<in> e" "v \<notin> set p" "v \<notin> set p'" "p \<noteq> []"
  shows "e = {last p, v} \<or> e = {v, hd p'}"
proof-
  obtain v1 v2 p1 p2 us
    where v1v2p1p2us:
      "e = {v1, v2}" 
      "p = p1 @ us \<and> us @ v # p' = v1 # v2 # p2 \<or> p @ us = p1 \<and> v # p' = us @ v1 # v2 # p2"
    using in_edges_of_path_split[OF assms(1)]
    apply(simp add: append_eq_append_conv2)
    by metis
  moreover have "v1 = v \<or> v2 = v"
    using assms(2) v1v2p1p2us
    by auto
  ultimately consider
    "p = p1 @ us \<and> us @ v # p' = v # v2 # p2" |
    "p @ us = p1 \<and> v # p' = us @ v # v2 # p2" |
    "p = p1 @ us \<and> us @ v # p' = v1 # v # p2" |
    "p @ us = p1 \<and> v # p' = us @ v1 # v # p2"
    by auto
  then show ?thesis
  proof cases
    case 1
    then show ?thesis
      using assms(3-) v1v2p1p2us(1)
      by (metis \<open>v1 = v \<or> v2 = v\<close> append_eq_Cons_conv in_set_conv_decomp list.sel(1) list.sel(3))
  next
    case 2
    then show ?thesis
      using assms(3-) v1v2p1p2us(1)
      by (metis \<open>v1 = v \<or> v2 = v\<close> append.assoc append_Cons_eq_iff list.sel(1) list.set_intros(1))
  next
    case 3
    then have "v \<notin> set us"
      using assms(3) v1v2p1p2us(1)
      by auto
    then have "e = {last us, v}"
      using assms(4) v1v2p1p2us(1)
      by (metis "3" \<open>v1 = v \<or> v2 = v\<close> hd_append2 last_ConsL list.exhaust_sel list.sel(1) list.sel(3) list.set_intros(1) list.set_sel(2) self_append_conv2 tl_append2)
    then have "e = {last p, v}"
      by (metis "3" assms(4) last_appendR list.inject list.set_intros(1) self_append_conv2)
    then show ?thesis
      by simp
  next
    case 4
    then show ?thesis
      using assms(3-) v1v2p1p2us(1)
      by (metis Cons_in_lists_iff append.left_neutral append_in_lists_conv in_listsI list.sel(3) same_append_eq tl_append2)
  qed
qed

lemma length_edges_of_path_rev[simp]: "length (edges_of_path (rev p)) = length (edges_of_path p)"
  by (simp add: edges_of_path_length)

lemma mem_eq_last_edge:
  "\<lbrakk>distinct p; e \<in> set (edges_of_path p); last p \<in> e\<rbrakk>
           \<Longrightarrow> e = last (edges_of_path p)"
  using edges_of_path_nempty last_vert_in_last_edge
  by fastforce

lemma edges_of_path_disj:
  assumes "set p1 \<inter> set p2 = {}"
  shows "set (edges_of_path p1) \<inter> set (edges_of_path p2) = {}"
  using assms
proof(induction p1 arbitrary: p2)
  case Nil
  then show ?case 
    by auto
next
  case (Cons a1' p1')
  then show ?case
    by (cases p1'; auto simp add: v_in_edge_in_path)
qed

lemma edges_of_path_nempty_edges:
  "e \<in> set (edges_of_path p) \<Longrightarrow> e \<noteq> {}"
  using in_edges_of_path_split
  by auto

lemma edges_of_path_snoc_2:
  "edges_of_path (p @ [v1, v2]) = edges_of_path (p @ [v1]) @ [{v1 ,v2}]"
  apply(subst edges_of_path_append_2)
  by auto

lemma edges_of_path_snoc_3: "p \<noteq> [] \<Longrightarrow> edges_of_path (p @ [v1, v2]) = edges_of_path p @ [{last p, v1}, {v1 ,v2}]"
  apply(subst edges_of_path_append_3)
  by auto

subsection \<open>Connected components: connected components of vertices and of edges\<close>

text\<open>One interesting point is the use of the concepts of connected components, which partition the
     set of vertices, and the analogous partition of edges. Juggling around between the two
     partitions, we get a much shorter proof for the first direction of Berge's lemma, which is the
     harder one.\<close>


text\<open>
  If a set of edges cannot be partitioned in paths, then it has a junction of 3 or more edges.
  In particular, an edge from one of the two matchings belongs to the path
  equivalent to one connected component. Otherwise, there will be a vertex whose degree is
  more than 2.
\<close>

text\<open>
  Every edge lies completely in a connected component.
\<close>

text\<open>Now we should be able to partition the set of edges into equivalence classes
     corresponding to the connected components.\<close>


subsection\<open>Every connected component can be linearised in a path.\<close>

subsection\<open>Every connected component can be linearised in a simple path\<close>

text\<open>An important part of this proof is setting up and induction on the graph, i.e. on a set of
     edges, and the different cases that could arise.\<close>

lemma same_con_comp_path:
  "\<lbrakk>C \<in> connected_components E; w \<in> C; x \<in> C\<rbrakk> 
    \<Longrightarrow>\<exists>pwx. pwx \<noteq> [] \<and> path E pwx \<and> hd pwx = w \<and> last pwx = x"
  by(auto elim!: same_con_comp_walk[where x = x] simp: walk_betw_def)

lemma in_con_compI:
  assumes connected: "puv \<noteq> []" "path E puv" "hd puv = u" "last puv = v" and
    u_mv: "u\<in>Vs E" and
    uC: "u \<in> C" and
    C_in_comp: "C \<in> connected_components E"
  shows "v \<in> C"
proof(cases "u = v")
  case True
  then show ?thesis using assms by simp
next
  obtain w where w: "w \<in> Vs E" "C = connected_component E w"
    using C_in_comp
    by (smt connected_components_def mem_Collect_eq)
  then obtain pwu where pwu: "pwu \<noteq> []" "path E pwu" "hd pwu = w" "last pwu = u"
    using uC C_in_comp
    unfolding connected_components_def connected_component_def
    apply simp
    by (metis (no_types, lifting) C_in_comp in_own_connected_component same_con_comp_path uC w(2))
  moreover case False
  ultimately have "path E (pwu @ (tl puv))" "hd (pwu @ (tl puv)) = w" "last (pwu @ (tl puv)) = v"
    apply(intro path_append connected pwu tl_path_is_path; simp)
    using connected pwu path.simps
    by fastforce+
  then show ?thesis
    using w
    by (metis Nil_is_append_conv contra_subsetD last_in_set path_subset_conn_comp pwu(1))
qed

lemma component_has_path_no_cycle:
  assumes "finite C" "C \<in> connected_components E" "card C \<ge> 2"
  shows "\<exists>p. path E p \<and> C = (set p) \<and> hd p \<noteq> last p"
proof-
  obtain p where p: "path E p" "C = (set p)"
    using assms component_has_path'
    by auto
  then show ?thesis
    using remove_cycle_pfx_works_card_ge_2
    by (metis assms(3) path_suff remove_cycle_pfx_works)
qed

definition component_path where
"component_path E C \<equiv> (SOME p. path E p \<and> C = set p \<and> hd p \<noteq> last p)"

lemma component_path_works:
  assumes "finite C" "C \<in> connected_components E" "card C \<ge> 2"
  shows "path E (component_path E C) \<and> C = set (component_path E C) \<and> hd (component_path E C) \<noteq> last (component_path E C)"
  unfolding component_path_def
  apply(rule someI_ex)
  using component_has_path_no_cycle[OF assms] .

lemma component_edges_subset:
  shows "component_edges E C \<subseteq> E"
  unfolding component_edges_def
  by auto

lemma edges_path_subset_edges:
  "\<lbrakk>path E p; set p \<subseteq> C\<rbrakk> \<Longrightarrow>
    set (edges_of_path p) \<subseteq> component_edges E C"
  by (induction rule: path.induct) (auto simp add:  component_edges_def)


lemma finite_con_comps:
  "finite (Vs E) \<Longrightarrow> finite (connected_components E)"
  by (auto simp: connected_components_def)

definition "neighbourhood G v \<equiv> {u. {u,v} \<in> G}"

lemma in_neighD[dest]: "v \<in> neighbourhood G u \<Longrightarrow> {u, v} \<in> G"
"v \<in> neighbourhood G u \<Longrightarrow> {v, u} \<in> G"
  by (auto simp: neighbourhood_def insert_commute)

end