:- module(
  rfc3987,
  [
    'absolute-IRI'//1,  % -Uri
    ipchar//1,          % ?Code
    iprivate//1,        % ?Code
    'IRI'//1,           % -Uri
    'IRI-reference'//1, % -Uri
    iunreserved//1      % ?Code
  ]
).
:- reexport(library(uri/rfc3986)).

/** <module> RFC 3987: Internationalized Resource Identifiers (IRIs)

# Why we need uir_iuserinfo//1 etc.

The following is not enough:

```prolog
(iuserinfo(U), "@" ; {var(U)})
```

When `iuserinfo//1' is defined as `dcg_atom(*(<SOME-CODE>), U)' then
the generating case will produce `"@"' with instantiation `U = '''.

We therefore need the (cumbersome) following:

```prolog
uri_iuserinfo(U) --> parsing, !, (iuserinfo(U), "@" ; "").
uri_iuserinfo(U) --> {var(U)}.
uri_iuserinfo(U) --> iuserinfo(U), "@".
```

# Definitions

  * *Character*
    A member of a set of elements used for the organization,
    control, or representation of data.

  * *|character encoding|*
    A method of representing a sequence of characters as a sequence of octets.
    Also, a method of (unambiguously) converting a sequence of octets into
    a sequence of characters.

  * *|Character repertoire|*
    A set of characters.

  * *Charset*
    The name of a parameter or attribute used to identify
    a character encoding.

  * *|IRI reference|*
    An IRI reference may be absolute or relative.
    However, the "IRI" that results from such a reference only includes
    absolute IRIs; any relative IRI references are resolved to their
    absolute form.

  * *Octet*
    An ordered sequence of eight bits considered as a unit.

  * *|Presentation element|*
    A presentation form corresponding to a protocol element; for example,
    using a wider range of characters.

  * *|Protocol element|*
    Any portion of a message that affects processing of that message
    by the protocol in question.

  * *|Running text|*
    Human text (paragraphs, sentences, phrases) with syntax according to
    orthographic conventions of a natural language, as opposed to syntax
    defined for ease of processing by machines (e.g., markup,
    programming languages).

  * *|UCS: Universal Character Set|*
    The coded character set defined by ISO/IEC 10646 and the Unicode Standard.

@author Wouter Beek
@compat RFC 3987
@see http://tools.ietf.org/html/rfc3987
@version 2017/08-2017/09
*/

:- use_module(library(apply)).
:- use_module(library(dcg)).





%! 'absolute-IRI'(-Uri:compound)// is det.
%
% ```abnf
% absolute-IRI = scheme ":" ihier-part [ "?" iquery ]
% ```

'absolute-IRI'(uri(Scheme,Authority,Segments,Query,_)) -->
  scheme(Scheme),
  ":",
  'ihier-part'(Scheme, Authority, Segments),
  uri_iquery(Query).



%! iauthority(?Scheme:atom, -Authority:compound)// is det.
%
% ```abnf
% iauthority = [ iuserinfo "@" ] ihost [ ":" port ]
% ```

iauthority(Scheme, auth(User,_Password,Host,Port)) -->
  uri_iuserinfo(User),
  ihost(Host),
  uri_port(Scheme, Port).



%! ifragment(?Fragment:atom)// .
%
% ```abnf
% ifragment = *( ipchar / "/" / "?" )
% ```

ifragment(Fragment) -->
  dcg_atom(*(ifragment_), Fragment).

ifragment_(0'/) --> "/".
ifragment_(0'?) --> "?".
ifragment_(Code) -->
  ipchar(Code).



%! 'ihier-part'(?Scheme:atom, -Authority:compound,
%!              -Segments:list(atom))// is det.
%
% ```abnf
% ihier-part = "//" iauthority ipath-abempty
%            / ipath-absolute
%            / ipath-rootless
%            / ipath-empty
% ```

'ihier-part'(Scheme, Authority, Segments) -->
  "//",
  iauthority(Scheme, Authority),
  'ipath-abempty'(Segments).
'ihier-part'(_, _, Segments) -->
  'ipath-absolute'(Segments).
'ihier-part'(_, _, Segments) -->
  'ipath-rootless'(Segments).
'ihier-part'(_, _, Segments) -->
  'ipath-empty'(Segments).



%! ihost(-Host:term)// is det.
%
% ```abnf
% ihost = IP-literal / IPv4address / ireg-name
% ```

ihost(Ip) -->
  'IP-literal'(Ip), !.
ihost(Ip) -->
  'IPv4address'(Ip), !.
ihost(Host) -->
  'ireg-name'(Host).



%! ipath(-Segments:list(atom))// is det.
%
% ```abnf
% ipath = ipath-abempty    ; begins with "/" or is empty
%       / ipath-absolute   ; begins with "/" but not "//"
%       / ipath-noscheme   ; begins with a non-colon segment
%       / ipath-rootless   ; begins with a segment
%       / ipath-empty      ; zero characters
% ```

% begins with "/" or is empty
ipath(Segments) -->
  'ipath-abempty'(Segments), !.
% begins with "/" but not "//"
ipath(Segments) -->
  'ipath-absolute'(Segments), !.
% begins with a non-colon segment
ipath(Segments) -->
  'ipath-noscheme'(Segments), !.
% begins with a segment
ipath(Segments) -->
  'ipath-rootless'(Segments), !.
% empty path (i.e., no segments)
ipath(Segments) -->
  'ipath-empty'(Segments).



%! 'ipath-abempty'(?Segments:list(atom))// .
%
% ```abnf
% ipath-abempty = *( "/" isegment )
% ```

'ipath-abempty'(Segments) -->
  *(sep_isegment, Segments).



%! 'ipath-absolute'(?Segments:list(atom))// .
%
% ```abnf
% ipath-absolute = "/" [ isegment-nz *( "/" isegment ) ]
% ```

'ipath-absolute'(L) -->
  "/",
  ('isegment-nz'(H) -> *(sep_isegment, T), !, {L = [H|T]} ; {L = []}).



%! 'ipath-empty'(?Segments:list(atom))// .
%
% ```abnf
% ipath-empty = 0<ipchar>
% ```

'ipath-empty'([]) --> "".



%! 'ipath-noscheme'(?Segments:list(atom))// .
%
% ```abnf
% ipath-noscheme = isegment-nz-nc *( "/" isegment )
% ```

'ipath-noscheme'([H|T]) -->
  'isegment-nz-nc'(H),
  *(sep_isegment, T).



%! 'ipath-rootless'(?Segments:list(atom))// .
%
% ```abnf
% ipath-rootless = isegment-nz *( "/" isegment )
% ```

'ipath-rootless'([H|T]) -->
  'segment-nz'(H),
  *(sep_isegment, T).



%! ipchar(?Code:code)// .
%
% ```abnf
% ipchar = iunreserved / pct-encoded / sub-delims / ":" / "@"
% ```

ipchar(0':) --> ":".
ipchar(0'@) --> "@".
ipchar(Code) --> 'sub-delims'(Code).
ipchar(Code) --> iunreserved(Code).
ipchar(Code) --> 'pct-encoded'(Code).



%! iprivate(?Code:code)// .
%
% ```abnf
% iprivate = %xE000-F8FF / %xF0000-FFFFD / %x100000-10FFFD
% ```

iprivate(Code) --> dcg_between(0xE000, 0xF8FF, Code).
iprivate(Code) --> dcg_between(0xF0000,  0xFFFFD,  Code).
iprivate(Code) --> dcg_between(0x100000, 0x10FFFD, Code).



%! iquery(?Query:atom)// .
%
% ``abnf
% iquery = *( ipchar / iprivate / "/" / "?" )
% ```

iquery(Query) -->
  dcg_atom(*(iquery_), Query).

iquery_(0'/) --> "/".
iquery_(0'?) --> "?".
iquery_(Code)   --> iprivate(Code).
iquery_(Code)   --> ipchar(Code).



%! 'ireg-name'(?Host:atom)// .
%
% ```abnf
% ireg-name = *( iunreserved / pct-encoded / sub-delims )
% ```

'ireg-name'(Host) -->
  dcg_atom(*(ireg_name_), Host).

ireg_name_(Code) --> 'sub-delims'(Code).
ireg_name_(Code) --> iunreserved(Code).
ireg_name_(Code) --> 'pct-encoded'(Code).



%! 'irelative-part'(?Scheme:atom, -Authority:compound,
%!                  -Segments:list(atom))// is det.
%
% ```abnf
% irelative-part = "//" iauthority ipath-abempty
%                / ipath-absolute
%                / ipath-noscheme
%                / ipath-empty
% ```

'irelative-part'(Scheme, Authority, Segments) -->
  "//",
  iauthority(Scheme, Authority),
  'ipath-abempty'(Segments), !.
'irelative-part'(_, _, Segments) -->
  'ipath-absolute'(Segments), !.
'irelative-part'(_, _, Segments) -->
  'ipath-noscheme'(Segments), !.
'irelative-part'(_, _, Segments) -->
  'ipath-empty'(Segments).



%! 'irelative-ref'(-Uri:compound)// is det.
%
% Relative IRI reference.
%
% ```abnf
% irelative-ref = irelative-part [ "?" iquery ] [ "#" ifragment ]
% ```

'irelative-ref'(uri(Scheme,Authority,Segments,Query,Fragment)) -->
  'irelative-part'(Scheme, Authority, Segments),
  uri_iquery(Query),
  uri_ifragment(Fragment).



%! 'IRI'(-Uri:compound)// is det.
%
% ```abnf
% IRI = scheme ":" ihier-part [ "?" iquery ] [ "#" ifragment ]
% ```

'IRI'(uri(Scheme,Authority,Segments,Query,Fragment)) -->
  scheme(Scheme),
  ":",
  'ihier-part'(Scheme, Authority, Segments),
  uri_iquery(Query),
  uri_ifragment(Fragment).



%! 'IRI-reference'(-Uri:compound)// is det.
%
% There are two types of IRI reference: (1) IRI, (2) IRI relative
% reference.
%
% ```abnf
% IRI-reference = IRI / irelative-ref
% ```

'IRI-reference'(Uri) --> 'IRI'(Uri).
'IRI-reference'(Uri) --> 'irelative-ref'(Uri).



%! isegment(?Segment:atom)// .
%
% ```abnf
% isegment = *ipchar
% ```

isegment(Segment) -->
  dcg_atom(*(ipchar), Segment).



%! 'isegment-nz'(?Segment:atom)// .
%
% ```abnf
% isegment-nz = 1*ipchar
% ```

'isegment-nz'(Segment) -->
  dcg_atom(+(ipchar), Segment).



%! 'isegment-nz-nc'(?Segment:atom)// .
%
% ```abnf
% isegment-nz-nc = 1*( iunreserved / pct-encoded / sub-delims / "@" )
%                ; non-zero-length segment without any colon ":"
% ```

'isegment-nz-nc'(Segment) -->
  dcg_atom(+('isegment-nz-nc_'), Segment).

'isegment-nz-nc_'(0'@) --> "@".
'isegment-nz-nc_'(Code) --> 'sub-delims'(Code).
'isegment-nz-nc_'(Code) --> iunreserved(Code).
'isegment-nz-nc_'(Code) --> 'pct-encoded'(Code).



%! iunreserved(?Code:code)// .
%
% ```abnf
% iunreserved = ALPHA / DIGIT / "-" / "." / "_" / "~" / ucschar
% ```

iunreserved(Code) --> unreserved(Code).
iunreserved(Code) --> ucschar(Code).



%! iuserinfo(?User:atom)// .
%
% ```abnf
% iuserinfo = *( iunreserved / pct-encoded / sub-delims / ":" )
% ```

iuserinfo(User) -->
  dcg_atom(*(iuserinfo_), User).

iuserinfo_(0':) --> ":".
iuserinfo_(Code) --> 'sub-delims'(Code).
iuserinfo_(Code) --> iunreserved(Code).
iuserinfo_(Code) --> 'pct-encoded'(Code).



%! ucschar(?Code:code)// .
%
% ```abnf
% ucschar = %xA0-D7FF / %xF900-FDCF / %xFDF0-FFEF
%         / %x10000-1FFFD / %x20000-2FFFD / %x30000-3FFFD
%         / %x40000-4FFFD / %x50000-5FFFD / %x60000-6FFFD
%         / %x70000-7FFFD / %x80000-8FFFD / %x90000-9FFFD
%         / %xA0000-AFFFD / %xB0000-BFFFD / %xC0000-CFFFD
%         / %xD0000-DFFFD / %xE1000-EFFFD
% ```

ucschar(Code) --> dcg_between(0xA0, 0xD7FF, Code).
ucschar(Code) --> dcg_between(0xF900, 0xFDCF, Code).
ucschar(Code) --> dcg_between(0xFDF0, 0xFFEF, Code).
ucschar(Code) --> dcg_between(0x10000, 0x1FFFD, Code).
ucschar(Code) --> dcg_between(0x20000, 0x2FFFD, Code).
ucschar(Code) --> dcg_between(0x30000, 0x3FFFD, Code).
ucschar(Code) --> dcg_between(0x40000, 0x4FFFD, Code).
ucschar(Code) --> dcg_between(0x50000, 0x5FFFD, Code).
ucschar(Code) --> dcg_between(0x60000, 0x6FFFD, Code).
ucschar(Code) --> dcg_between(0x70000, 0x7FFFD, Code).
ucschar(Code) --> dcg_between(0x80000, 0x8FFFD, Code).
ucschar(Code) --> dcg_between(0x90000, 0x9FFFD, Code).
ucschar(Code) --> dcg_between(0xA0000, 0xAFFFD, Code).
ucschar(Code) --> dcg_between(0xB0000, 0xBFFFD, Code).
ucschar(Code) --> dcg_between(0xC0000, 0xCFFFD, Code).
ucschar(Code) --> dcg_between(0xD0000, 0xDFFFD, Code).
ucschar(Code) --> dcg_between(0xE1000, 0xEFFFD, Code).





% HELPERS %

%! sep_isegment(?Segment:list)// .

sep_isegment(Segment) -->
  "/",
  isegment(Segment).



%! uri_ifragment(?Fragment:atom)// .

uri_ifragment(Fragment) --> parsing, !, ("#", ifragment(Fragment) ; "").
uri_ifragment(Fragment) --> {var(Fragment)}.
uri_ifragment(Fragment) --> "#", ifragment(Fragment).



%! uri_iquery(?Query:atom)// .

uri_iquery(Query) --> parsing, !, ("?", iquery(Query) ; "").
uri_iquery(Query) --> {var(Query)}.
uri_iquery(Query) --> "?", iquery(Query).



%! uri_iuserinfo(?User:atom)// .

uri_iuserinfo(User) --> parsing, !, (iuserinfo(User), "@" ; "").
uri_iuserinfo(User) --> {var(User)}.
uri_iuserinfo(User) --> iuserinfo(User), "@".
