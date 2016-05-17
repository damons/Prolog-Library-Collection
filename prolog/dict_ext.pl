:- module(
  dict_ext,
  [
    atomize_dict/2,         % +D, -AtomizedD
    create_dict/3,          % +Pairs, +Tag, -D
    create_grouped_sorted_dict/2, % +Pairs, -GroupedSortedD
    create_grouped_sorted_dict/3, % +Pairs, +Tag, -GroupedSortedD
    dict_has_key/2,         % +Key, +D
    dict_inc/2,             % +Key, +D
    dict_inc/3,             % +Key, +D, -Value
    dict_inc/4,             % +Key, +D, +Diff, -Value
    dict_pairs/2,           % ?D, ?Pairs
    dict_prepend/3,         % +Key, +D, +Elem
    dict_put_pairs/3,       % +D1, +Pairs, -D2
    dict_remove_uninstantiated/2, % +D1, -D2
    dict_sum/3,             % +D1, +D2, -D3
    dict_tag/3,             % +D1, +Tag, ?D2
    get_dict/4,             % +Key, +D, -Value, +Default
    is_empty_dict/1,        % @Term
    merge_dict/3,           % +D1, +D2, -D3
    mod_dict/4,             % +Key, +D1,           -Value, -D2
    mod_dict/5              % +Key, +D1, +Default, -Value, -D2
  ]
).
:- reexport(library(dicts)).

/** <module> Dictionary extensions

@author Wouter Beek
@version 2015/08-2015/11, 2016/01, 2016/03-2016/04
*/

:- use_module(library(apply)).
:- use_module(library(dcg/dcg_ext)).
:- use_module(library(list_ext)).
:- use_module(library(pairs)).
:- use_module(library(yall)).





%! atomize_dict(+D, -AtomizedD) is det.

atomize_dict(D1, D2):-
  atomize_dict0(D1, D2).

atomize_dict0(D1, D2):-
  is_dict(D1), !,
  dict_pairs(D1, Tag, L1),
  maplist(atomize_dict0, L1, L2),
  dict_pairs(D2, Tag, L2).
atomize_dict0(S, A):-
  string(S), !,
  atom_string(A, S).
atomize_dict0(X, X).



%! create_dict(+Pairs, +Tag, -D) is det.

create_dict(Pairs, Tag, D):-
  maplist(dict_pair, Pairs, Ds),
  create_grouped_sorted_dict(Ds, Tag, D).


dict_pair(Key1-Val1, Key2-Val2):-
  atom_string(Key2, Key1),
  (singleton_list(Val2, Val1), ! ; Val2 = Val1).



%! create_grouped_sorted_dict(+Pairs, -GroupedSortedD) is det.
%! create_grouped_sorted_dict(+Pairs, ?Tag, -GroupedSortedD) is det.

create_grouped_sorted_dict(Pairs, D):-
  create_grouped_sorted_dict(Pairs, _, D).

create_grouped_sorted_dict(Pairs, Tag, D):-
  sort(Pairs, SortedPairs),
  group_pairs_by_key(SortedPairs, GroupedPairs),
  dict_pairs(D, Tag, GroupedPairs).



%! dict_has_key(+Key, +D) is semidet.

dict_has_key(Key, D) :-
  catch(get_dict(Key, D, _), _, fail).



%! dict_inc(+Key, +D) is det.
%! dict_inc(+Key, +D, -Value) is det.
%! dict_inc(+Key, +D, +Diff, -Value) is det.

dict_inc(Key, D) :-
  dict_inc(Key, D, _).


dict_inc(Key, D, Val) :-
  dict_inc(Key, D, 1, Val).

dict_inc(Key, D, Diff, Val2) :-
  get_dict(Key, D, Val1),
  Val2 is Val1 + Diff,
  nb_set_dict(Key, D, Val2).



%! dict_pairs(+D, +Pairs) is semidet.
%! dict_pairs(+D, -Pairs) is det.
%! dict_pairs(-D, +Pairs) is det.

dict_pairs(D, L):-
  dict_pairs(D, _, L).



%! dict_put_pairs(+D1, +Pairs, -D2) is det.

dict_put_pairs(D1, L, D2) :-
  dict_pairs(D1, L1),
  append(L1, L, L2),
  dict_pairs(D2, L2).



%! dict_prepend(+Key, +D, +Elem) is det.

dict_prepend(Key, D, H) :-
  get_dict(Key, D, T),
  nb_set_dict(Key, D, [H|T]).



%! dict_remove_uninstantiated(+D1, -D2) is det.

dict_remove_uninstantiated(D1, D2):-
  dict_pairs(D1, Tag, L1),
  exclude(var_val, L1, L2),
  dict_pairs(D2, Tag, L2).
var_val(_-Val):- var(Val).



%! dict_sum(+Ds, -D) is det.
%! dict_sum(+D1, +D2, -D3) is det.

dict_sum(Ds, D) :-
  dict_sum0(Ds, _{}, D).

dict_sum0([], D, D) :- !.
dict_sum0([D1|T], D2, D4) :-
  dict_sum(D1, D2, D3),
  dict_sum0(T, D3, D4).


dict_sum(D1, D2, D3) :-
  maplist(dict_pairs, [D1,D2], [Pairs1,Pairs2]),
  pairs_sum(Pairs1, Pairs2, Pairs3),
  dict_pairs(D3, Pairs3).


pairs_sum([], Pairs, Pairs) :- !.
pairs_sum([Key-Val1|T1], L2a, [Key-Val3|T3]) :- !,
  selectchk(Key-Val2, L2a, L2b),
  Val3 is Val1 + Val2,
  pairs_sum(T1, L2b, T3).
pairs_sum([Key-Val|T1], L2, [Key-Val|T3]) :-
  pairs_sum(T1, L2, T3).



%! dict_tag(+D1, +Tag, +D2) is semidet.
%! dict_tag(+D1, +Tag, -D2) is det.
% Converts between dictionaries that differ only in their outer tag name.

dict_tag(D1, Tag, D2):-
  dict_pairs(D1, _, Ps),
  dict_pairs(D2, Tag, Ps).



%! get_dict(+Key, +D, -Value, +Default) is det.

get_dict(K, D, V, _) :-
  dict_has_key(K, D), !,
  get_dict(K, D, V).
get_dict(_, _, Def, Def).



%! is_empty_dict(@Term) is semidet.

is_empty_dict(D):-
  is_dict(D),
  dict_pairs(D, _, L),
  empty_list(L).



%! merge_dict(+D1, +D2, -D3) is det.
% Merges two dictionaries into one new dictionary.
% If D1 and D2 contain the same key then the value from D2 is used.
% If D1 and D2 do not have the same tag then the tag of D2 is used.

merge_dict(D1, D2, D3):-
  dict_pairs(D1, Tag1, Ps1),
  dict_pairs(D2, Tag2, Ps2),
  dict_keys(D2, Keys2),
  exclude(key_in_keys0(Keys2), Ps1, OnlyPs1),
  append(OnlyPs1, Ps2, Ps3),
  (Tag1 = Tag2 -> true ; Tag3 = Tag2),
  dict_pairs(D3, Tag3, Ps3).

key_in_keys0(Keys, Key-_) :- memberchk(Key, Keys).



%! mod_dict(+Key, +D1, -Value, -D2) is det.

mod_dict(Key, D1, Val, D2) :-
  dict_has_key(Key, D1),
  del_dict(Key, D1, Val, D2).


%! mod_dict(+Key, +D1, +Default, -Value, -D2) is det.

mod_dict(Key, D1, _, Val, D2) :-
  mod_dict(Key, D1, Val, D2), !.
mod_dict(_, D, Def, Def, D).
