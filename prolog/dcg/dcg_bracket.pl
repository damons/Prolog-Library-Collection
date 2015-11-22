:- module(
  dcg_bracket,
  [
    bracketed//1, % :Dcg_0
    bracketed//2 % ?Type:oneof([angular,curly,langular,round,square])
                 % :Dcg_0
  ]
).

/** <module> DCG bracketed

Support for bracketed expressions in DCG.

@author Wouter Beek
@version 2015/07-2015/08, 2015/11
*/

:- use_module(library(dcg/dcg_call)).
:- use_module(library(dcg/dcg_unicode)).

:- meta_predicate(bracketed(//,?,?)).
:- meta_predicate(bracketed(+,//,?,?)).
:- meta_predicate(bracketed0(+,//,?,?)).





%! bracketed(:Dcg_0)// .
% Wrapper around bracketed//2 using round brackets.

bracketed(Dcg_0) --> bracketed(round, Dcg_0).


%! bracketed(+Type:oneof([angular,curly,langular,round,square]), :Dcg_0)// is det.
%! bracketed(-Type:oneof([angular,curly,langular,round,square]), :Dcg_0)// is nondet.

bracketed(Type, Dcg_0) -->
  (   {var(Type)}
  ->  bracketed0(Type, Dcg_0)
  ;   dcg_once(bracketed0(Type, Dcg_0))
  ).

bracketed0(Type, Dcg_0) -->
  dcg_between(
    opening_bracket(Type, _),
    Dcg_0,
    closing_bracket(Type, _)
  ).