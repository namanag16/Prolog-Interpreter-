(* type variable = A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z;; *)

type variable = string;;

type symbol = string;;

type constant = string;;

type signature  = (symbol * int) list;; (*Defines the arity of each predicate eg. male-1, child-2 *)

type term = V of variable |C of constant | Node of symbol * (term list);;  (*here symbol is function symbol - k ary*) (*C of constant is redundant if a zero ary symbol is used*)

type head = symbol * (term list);;   (*here symbol is predicate symbol - k ary*)

type body = head list;;

type goal = head list;;

type fact = head list;;

type rule = (head*body) list;;

type program = F of fact |R of rule;;


(*********************************************************************Helper functions***************************************************************************)

let rec check_dup sim = match sim with
		[] -> false
		|h::tl -> if (List.mem h tl) then true 
					else (check_dup tl);;




let rec check_sig (s:signature) : bool = 
	(*are we checking any other condition for a valid signature other than these *)
	let (sim,ar) = (List.split s) in

	if ((List.exists (fun x -> x < 0) ar)) then false
	else not (check_dup sim);;




let rec wfterm (s:signature) (t:term) : bool = 
	(*in our case t will be a list of head clauses(type goal).. change later*)
	(*do we need to check the check_sig condition inside this function*)
	match t with 
	V var -> true
	|C const -> true
	|Node (x,y) ->  let arity = (try(List.assoc x s) with Not_found -> -1) in 

					if arity = List.length(y) then (List.fold_right (fun elem acc -> (wfterm s elem) && acc) y true)
					else false;;





type substitution = variable -> term;;  

let rec subst (sigma:substitution) (t:term) : term = 
	(*t will be the list of head clauses type(goal) ... change if necessary*)
	match t with 
	V var -> (sigma var)
	|C const -> t
	|Node(x,y) -> if List.length(y) = 0 then Node(x,y) else Node(x,(List.map (fun elem -> (subst sigma elem)) y));;


let rec list_subst (vt_list:(variable*term) list) (t:term) : term = 
	(List.fold_right (fun elem acc -> (match elem with (var,trm) -> (subst (fun (x:variable) -> if (x = var) then trm else (V x)) acc) ) )  vt_list t);;


exception Not_Unifiable of string;;

let rec occurs (v:variable) (t:term) : bool = 
	match t with 
	V var -> var = v
	|C const -> false
	|Node(x,y) -> (List.fold_right (fun elem acc -> (occurs v elem) || acc) y false);;




let rec mgu p q = match (p,q) with 
(V x,V y) -> if x = y then [] else [(x,q)] 
|((V x,(Node(_,_) as t)) |((Node(_,_) as t), V x)) -> if (occurs x t) then raise (Not_Unifiable "due to occurs check") else [(x,t)]
|(Node(x,y),Node(p,q)) -> if (x=p && List.length(y) = List.length(q)) then unify_term_pair_list (List.combine y q)
							else raise (Not_Unifiable "due to symbol conflict")
|(C x,C y) -> if x =y then [] else raise (Not_Unifiable "due to symbol conflict")
|(V x,C y) | (C y,V x) -> [(x,C y)] 
|(_,C y) | (C y, _) -> raise (Not_Unifiable "due to symbol conflict")

and unify_term_pair_list (ls:(term*term) list) = 
(*Is order of execution to be handled here *)
List.fold_right (fun elem acc -> 
							(match elem with (a,b) -> 
							 let p = (list_subst acc a) 
							 and q = (list_subst acc b) in 
					 		(mgu p q) @ acc)) ls [];;  




let rec htoterm (h:head) : term =
	(*This is a useful function dude*)
	match h with 
	(x,y) -> Node (x,y)
;;

let rec ttohead (t:term) : head = 
	match t with 
	Node(x,y) -> (x,y)
;;

(* let rec change_var_names (f:fact) (r:rule) (g:goal) = 


;; *)
(****************************************************Family Tree********************************************************************************************)

let (f:fact) = [   ("female",[C "sita"]);
				   ("female",[C "urmila"]);
				   ("female",[C "mom"]);
				   ("male",[C "dad"]); 
				   ("male",[C "laxman"]);
				   ("male",[C "bro1"]);
				   ("child",[C "me";C "dad"]);
				   ("child",[C "me";C "mom"]);
				   ("child",[C "sis";C "mom"]);	
				   ("child",[C "dad";C "dada"]);
				   ("child",[C "dada";C "pardada"]);
				   ("child",[C "mom";C "nana"]);
				   ("child",[C "nana";C "parnana"]);
				   ("married",[C "dad";C "mom"]);
				   ("married",[C "mom";C "dad"]);
				   ("married",[C "laxman";C "urmila"]);
				   ("married",[C "urmila";C "laxman"]);
				   ("sibling",[C "mom";C "urmila"]);
				   ("sibling",[C "urmila";C "mom"]);
				   ("sibling",[C "sita";C "urmila"]);
				   ("sibling",[C "urmila";C "sita"]);
				   ("sibling",[C "mom";C "bro1"]);
				   ("sibling",[C "bro1";C "mom"]);
				   ("sibling",[C "dad";C "bharat"]);

				];;

let (r:rule) = [  ( ("uncle",[V "X";V "Y"])  ,  [ ("male",[V "X"])  ;  ("married",[V "X";V "Z"]) ; ("sibling",[V "Z";V "Z1"]) ; ("child",[V "Y";V "Z1"]) ] );
				  ( ("uncle",[V "X";V "Y"])  ,  [ ("male",[V "X"])  ;  ("sibling",[V "X";V "Z"]) ; ("child",[V "Y";V "Z"]) ] );
				  ( ("ancestor",[V "X";V "Y"]) ,[ ("child",[V "Y";V "X"]) ]  );
				  ( ("ancestor",[V "X";V "Y"]) ,[ ("child",[V "Y";V "Z"]) ; ("ancestor",[V "X";V "Z"]) ]  );


	 	       ];;

(****************************************************For Graph********************************************************************************************)
(* 
let (f:fact) = [   ("edge",[C "a";C "b"]);
				   ("edge",[C "a";C "g"]);
				   ("edge",[C "b";C "d"]);
				   ("edge",[C "d";C "c"]);
				   ("edge",[C "g";C "c"]);
				   ("edge",[C "g";C "f"]);
				   ("edge",[C "c";C "e"]);
				   (* ("edge",[C "e";C "d"]); *)	
				   ("edge",[C "h";C "i"]);
				   ("path",[V "X";V "X"]);

				];;

let (r:rule) = [  ( ("path",[V "X";V "Y"])  ,  [ ("edge",[V "X";V "Z"]) ; ("path",[V "Z";V "Y"]) ] );
				  ( ("cycle",[V "X"]) ,[ ("edge",[V "X";V "Z"]) ; ("path",[V "Z";V "X"]) ]  );

	 	       ];;

(* let (r:rule) = [  ( ("path",[V "A";V "B"])  ,  [ ("walk",[V "A";V "B";C "[]"]) ] );
				  ( ("walk",[V "A";V "B";V "V"]) , [ ("edge",[V "A";V "X"]) ]							)
				  ( ("cycle",[V "X"]) ,[ ("edge",[V "X";V "Z"]) ; ("path",[V "Z";V "X"]) ]  );

	 	       ];; *)

 *)
(****************************************************For lists********************************************************************************************)











(****************************************************end ********************************************************************************************)
exception Eval_error of string;;




let rec unify (facts:fact) (rules:rule) (g:goal) : bool = 
	match g with 
	[] -> true
	|h::tl -> if ((unify_facts facts rules g) = true) then true
			  else 
			  	if ( (unify_rules facts rules g) = true) then true
				else false


and unify_facts (facts:fact) (rules:rule) (g:goal) : bool = 
	match g with 
	|h::tl -> match facts with 
			[] -> false
			|x::xs -> try 
						let uni = (mgu (htoterm h) (htoterm x) ) in 
						let g1 = List.map (fun elem -> htoterm elem) g in 
						let g2 = List.map (fun elem -> (list_subst uni elem)) g1 in 
						let g3 = List.map (fun elem -> ttohead elem) g2 in 
						if (unify f r (List.tl g3) = true) then 
							true
						else 
							(unify_facts xs rules g)


					  with 
						Not_Unifiable "due to symbol conflict"
						|Not_Unifiable "due to occurs check" -> (unify_facts xs rules g)

and unify_rules (facts:fact) (rules:rule) (g:goal) : bool = 
	match g with
	| h::tl -> match rules with 
			 [] -> false 
			 |x::xs -> match x with 
			 			(p,q) -> try 
			 						let uni = (mgu (htoterm h) (htoterm p) ) in 
			 						let gnew = q @ (List.tl g) in 
									let g1 = List.map (fun elem -> htoterm elem) gnew in 
									let g2 = List.map (fun elem -> (list_subst uni elem)) g1 in (*Do substitution in evry goal ? or only in subgoals? *) 
									let g3 = List.map (fun elem -> ttohead elem) g2 in 
									if (unify f r (g3) = true) then 
										true
									else 
										(unify_rules facts xs g)



								 with 
									Not_Unifiable "due to symbol conflict"
									|Not_Unifiable "due to occurs check" -> (unify_rules facts xs g)
;;


let rec eval_goals (facts:fact) (rules:rule) (goals:goal) : bool = 
	match goals with 
	[] -> raise (Eval_error "Empty goal clause not allowed")
	|h::tl -> (unify facts rules goals)
;;

(* let gls = [ ("male",[V "x"]) ; ("child",[V "x";C "kunti"]) ];;
let gls = [ ("father",[C "kunti";C "nakula"])  ];;

let gls = [ ("female",[C "nakula"])  ; ("father",[C "kunti";C "nakula"])  ];;
let gls = [ ("father",[C "kunti";C "nakula"]) ; ("male",[C "nakula"]) ];;
 *)
(**********************Family tree goals*************************)
 


 let gls = [ ("uncle",[V "X"; C "me"]) ] ;; 
eval_goals f r gls;;

let gls = [ ("uncle",[C "laxman";V "T"]) ] ;;
eval_goals f r gls;;

let gls = [ ("ancestor",[V "X";C "me"]) ] ;;
eval_goals f r gls;;

let gls = [ ("ancestor",[C "parnana";V "X"]) ] ;;
eval_goals f r gls;;

let gls = [ ("ancestor",[V "X";V "Y"]) ] ;;
eval_goals f r gls;;


(**********************Graph Goals*************************)

(* let gls = [("path",[C "f";C "d"])];;
eval_goals f r gls;; *)

(* let gls = [("path",[C "a";C "h"])];;
eval_goals f r gls;;

let gls = [("path",[C "g";C "e"])];;
eval_goals f r gls;;

let gls = [("cycle",[V "G"])];;
eval_goals f r gls;;

let gls = [("cycle",[C "a"])];;
eval_goals f r gls;; *)



(**********************Graph Goals*************************)



(* mgu ( htoterm ( "uncle",[C "laxman";V "X"] ) ) ( htoterm( "uncle",[V "X";V "Y"] ) ) ;;
mgu ( htoterm ( "path",[V "X";V "Y"] ) ) ( htoterm( "path",[C "a";C "h"] ) ) ;;
 *)