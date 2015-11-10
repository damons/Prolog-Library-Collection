:- module(
  rfc2616_token,
  [
    attribute//1, % ?Attribute:string
    comment//1, % ?Comment:string
    'language-tag'//1, % ?LanguageTag:list(string)
    'media-type'//1, % ?MediaType:dict
    parameter//1, % ?Parameter:pair(string)
    'primary-tag'//1, % ?PrimaryTag:string
    product//1, % ?Product:dict
    'product-version'//1, % ?ProductVersion:string
    'quoted-string'//1, % ?String:string
    subtag//1, % ?Subtag:string
    subtype//1, % ?Subtype:string
    token//1, % ?Token:string
    type//1, % ?Type:string
    value//1 % ?Value:string
  ]
).

/** <module> RFC 2616: Tokens

@author Wouter Beek
@compat RFC 2616
@deprecated
@version 2015/11
*/

:- use_module(library(dcg/dcg_abnf)).
:- use_module(library(dcg/dcg_word)).
:- use_module(library(http/rfc2616_code)).
:- use_module(library(http/rfc2616_helpers)).
:- use_module(library(string_ext)).





%! attribute(?Attribute:string)// .
% ```abnf
% attribute = token
% ```

attribute(S) --> token(S).



%! comment(?Comment:string)// .
% ```abnf
% comment = "(" *( ctext | quoted-pair | comment ) ")"
% ```

comment(S) --> dcg_string(comment_codes1, S).
comment_codes1(L) --> "(", comment_codes2(L), ")".
comment_codes2([H|T]) --> ctext(H), !, comment_codes2(T).
comment_codes2([H|T]) --> 'quoted-pair'(H), !, comment_codes2(T).
comment_codes2(L) --> comment_codes1(L1), !, comment_codes2(L2), {append(L1, L2, L)}.
comment_codes2([]) --> "".



%! 'language-tag'(?LanguageTag:list(string))// .
% ```abnf
% language-tag = primary-tag *( "-" subtag )
% ```

'language-tag'([H|T]) --> 'primary-tag'(H), subtags(T).
subtags([H|T]) --> "-", !, subtag(H), subtags(T).
subtags([]) --> "".



%! 'media-type'// .
% ```abnf
% media-type = type "/" subtype *( ";" parameter )
% ```

'media-type'('media-type'{type: Type, subtype: Subtype, parameters: L}) -->
  type(Type),
  "/",
  subtype(Subtype),
  parameters(L).



%! parameter(?Parameter:pair(string))// .
% ```abnf
% parameter = attribute "=" value
% ```

parameter(Key-Val) --> attribute(Key), "=", value(Val).



%! 'primary-tag'(?PrimaryTag:string)// .
% ```abnf
% primary-tag = 1*8ALPHA
% ```

'primary-tag'(S) --> 'm*n'(1, 8, 'ALPHA', S, [convert1(codes_string)]).



%! product(?Product:dict)// .
% ```abnf
% product = token ["/" product-version]
% ```

product(D) -->
  token(S1),
  (   "/", 'product-version'(S2), {D = product{name: S1, version: S2}}
  ;   {D = product{name: S1}}
  ).



%! 'product-version'(?ProductVersion:string)// .
% ```abnf
% 'product-version' = token
% ```

'product-version'(S) --> token(S).



%! 'quoted-string'(?String:string)// .
% ```abnf
% quoted-string = ( <"> *(qdtext | quoted-pair ) <"> )
% ```

'quoted-string'(S) --> "\"", dcg_string(quoted_string_codes, S), "\"".
quoted_string_codes([H|T]) --> qdtext(H), !, quoted_string_codes(T).
quoted_string_codes([H|T]) --> 'quoted-pair'(H), !, quoted_string_codes(T).
quoted_string_codes([]) --> "".



%! subtag(?Subtag:string)// .
% ```abnf
% subtag = 1*8ALPHA
% ```

subtag(S) --> 'm*n'(1, 8, 'ALPHA', S, [convert1(codes_string)]).



%! subtype// .
% ```abnf
% subtype = token
% ```

subtype(S) --> token(S).



%! token(?Token:string)// .
% ```abnf
% token = 1*<any CHAR except CTLs or separators>
% ```

token(S) --> +(token_code, S, [convert1(codes_string)]).
token_code(C) --> 'CHAR'(C), {\+ 'CTL'(C, _, _), \+ separators(C, _, _)}.



%! type(?Type:string)// .
% ```abnf
% type = token
% ```

type(S) --> token(S).



%! value(?Value:string)// .
% ```abnf
% value = token | quoted-string
% ```

value(S) --> token(S).
value(S) --> 'quoted-string'(S).