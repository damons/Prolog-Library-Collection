:- module(
  rest,
  [
    rest_exception/2,  % +MTs, +E
    rest_exception/3,  % +Req, +MTs, +E
    rest_media_type/4, % +Req, +Method, +MTs, :Goal_2
    rest_method/3,     % +Req, +Methods, :Plural_3
    rest_method/4,     % +Req, +Methods, +HandleId, :Singular_4
    rest_method/5      % +Req, +Methods, :Plural_3, +HandleId, :Singular_4
  ]
).

/** <module> REST

There are two phases in handling REST requests:

  1. rest_method/[3-5] where we can answer an OPTIONS reply or
     determine the method and throw an error if that method is not
     supported.

     The following two calls are made:
     
       - call(Singular_4, Res, Req, Method, MTs)

       - call(Plural_3, Req, Method, MTs)

     This allows additional errors (e.g., authentication) that are
     method-specific to be thrown while still holding on to all media
     types to take media type preferences into account.

  2. rest_method_type/3 where we have covered all method-specific
     errors (for which we need the full list of media types) and where
     we can now make calls for specific media types.

     The following call is made:
     
       - call(Goal_2, Method, MT)

@author Wouter Beek
@version 2016/02, 2016/04-2016/06, 2016/08-2016/09
*/

:- use_module(library(http/html_write)). % HTML meta.
:- use_module(library(http/http_ext)).
:- use_module(library(http/http_wrapper)).
:- use_module(library(http/http_write)).
:- use_module(library(http/json)).
:- use_module(library(iri/iri_ext)).
:- use_module(library(lists)).

:- html_meta
   rest_media_type(+, +, +, 2),
   rest_method(+, +, 3),
   rest_method(+, +, +, 4),
   rest_method(+, +, 3, +, 4),
   rest_method0(+, +, +, 3, +, 4).





%! rest_exception(+MTs, +E) is det.
%! rest_exception(+Req, +MTs, +E) is det.

rest_exception(MTs, E) :-
  http_current_request(Req),
  rest_exception(Req, MTs, E).


rest_exception(Req, MTs, error(E,_)) :- !,
  rest_exception(Req, MTs, E).
% The exception reply can be returned in an acceptable media type.
rest_exception(Req, MTs, E) :-
  member(MT, MTs),
  rest_exception_media_type(Req, MT, E), !.
% The exception reply cannot be returned in an acceptable media type,
% so just pick one.
rest_exception(Req, _, E) :-
  once(rest_exception_media_type(Req, _, E)).



% HTML errors are already generated by default.
rest_exception_media_type(Req, text/html, 401) :-
  http_status_reply(Req, authorise(basic,'')).
rest_exception_media_type(Req, text/html, bad_request(E)) :-
  http_status_reply(Req, bad_request(E)).
rest_exception_media_type(_, text/html, E) :-
  throw(E).
% 400 “Bad Request”
rest_exception_media_type(Req, MT, existence_error(http_parameter,Key)) :- !,
  (   MT == application/json
  ->  Headers = ['Content-Type'-media_type(application/json,[])],
      Dict = _{message: "Missing parameter", value: Key},
      with_output_to(codes(Cs), json_write_dict(current_output, Dict))
  ;   Headers = [],
      Cs = []
  ),
  reply_http_message(Req, 400, Headers, Cs).



%! rest_media_type(+Req, +Method, +MTs, :Goal_2) is det.
%
% @tbd Add body for 405 code in multiple media types.

% Media type accepted, on to application-specific reply.
rest_media_type(_, Method, MTs, Goal_2) :-
  member(MT, MTs),
  call(Goal_2, Method, MT), !.
% 406 “Not Acceptable”
rest_media_type(Req, _, MTs, _) :-
  rest_exception(Req, MTs, 406).



%! rest_method(+Req, +Methods, :Plural_3) is det.
%! rest_method(+Req, +Methods, +HandleId, :Singular_4) is det.
%! rest_method(+Req, +Methods, :Plural_3, +HandleId, :Singular_4) is det.
%
% @tbd Return info for 405 status code.

rest_method(Req, Methods, Plural_3) :-
  rest_method(Req, Methods, Plural_3, _, _).


rest_method(Req, Methods, HandleId, Singular_4) :-
  rest_method(Req, Methods, _, HandleId, Singular_4).


rest_method(Req, Methods, Plural_3, HandleId, Singular_4) :-
  memberchk(method(Method), Req),
  rest_method0(Req, Method, Methods, Plural_3, HandleId, Singular_4).


% “OPTIONS”
rest_method0(Req, options, Methods1, _, _, _) :- !,
  sort([head,options|Methods1], Methods2),
  reply_http_message(Req, 200, ['Allow'-Methods2]).
% Method accepted, on to media types.
rest_method0(Req, Method, Methods, Plural_3, HandleId, Singular_4) :-
  memberchk(Method, Methods), !,
  http_relative_iri(Req, Iri1),
  http_accept(Req, MTs),
  iri_to_resource(Iri1, Res, _, _),
  (   ground(HandleId),
      http_link_to_id(HandleId, Iri2),
      \+ iri_to_resource(Iri2, Res, _, _)
  ->  call(Singular_4, Res, Req, Method, MTs)
  ;   call(Plural_3, Req, Method, MTs)
  ).
% 405 “Method Not Allowed”
rest_method0(Req, _, _, _, _, _) :-
  reply_http_message(Req, 405).
