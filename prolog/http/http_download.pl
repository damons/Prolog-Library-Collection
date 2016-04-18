:- module(
  http_download,
  [
    file_download/2, % +Source, ?File
    file_download/3, % +Source, ?File, +Opts
    html_download/2, % +Source, -Dom
    html_download/3, % +Source, -Dom,  +Opts
    json_download/2, % +Source, -Json
    json_download/3, % +Source, -Json, +Opts
    xml_download/2,  % +Source, -Dom
    xml_download/3   % +Source, -Dom,  +Opts
  ]
).

/** <module> HTTP download

Support for downloading files and datastructures over HTTP(S).

@author Wouter Beek
@version 2015/07-2015/11, 2016/01, 2016/04
*/

:- use_module(library(atom_ext)).
:- use_module(library(error)).
:- use_module(library(hash_ext)).
:- use_module(library(http/http_ext)).
:- use_module(library(http/http_request)).
:- use_module(library(http/json)).
:- use_module(library(os/file_ext)).
:- use_module(library(os/io_ext)).
:- use_module(library(option)).
:- use_module(library(sgml)).
:- use_module(library(uri)).





%! file_download(+Iri, ?File) is det.
%! file_download(+Iri, ?File, +Opts) is det.
% Downloads the contents stored at the given URI to either
% the a File with either a given file name or
% a file name that is created based on the URI.
%
% The following options are supported:
%   * freshness_lifetime(+or([between(0.0,inf),oneof([inf])]))
%     Sets whether -- and if so, when -- files that were downloaded
%     in the past are redownloaded and overwritten.
%     Default is `inf`.
%   * Other options are passed to http_get/3.
%
% @throws type_error if Iri is not an absolute URI.

file_download(Iri, File) :-
  file_download(Iri, File, []).


% The file was already downloaded in the past.
file_download(Iri, File, Opts) :-
  nonvar(File),
  exists_file(File), !,
  (   option(freshness_lifetime(FL), Opts, inf),
      is_fresh_file(File, FL)
  ->  access_file(File, read)
  ;   delete_file(File),
      file_download(Iri, File, Opts)
  ).
% Throw an exception if Iri is not absolute.
file_download(Iri, _, _) :-
  \+ uri_is_global(Iri), !,
  type_error(absolute_uri, Iri).
% A file name is given.
file_download(Iri, File0, Opts) :-
  iri_normalized(Iri, NormIri),
  md5(NormIri, Hash),
  thread_file(Hash, TmpFile),
  call_onto_stream(Iri, TmpFile, copy_stream_data0, Opts),
  ignore(option(metadata(M), Opts)),
  (   nonvar(File0)
  ->  File = File0
  ;   (file_name(M, File0) -> true ; File0 = Hash),
      absolute_file_name(File0, File, [access(write)])
  ),
  rename_file(TmpFile, File).

copy_stream_data0(_, In, _, Out) :-
  copy_stream_data(In, Out).



%! html_download(+Source, -Dom) is det.
%! html_download(+Source, -Dom, +Opts) is det.

html_download(Source, Dom) :-
  html_download(Source, Dom, []).


html_download(Source, Dom, Opts) :-
  http_get(Source, load_html0(Dom0, Opts)),
  clean_dom(Dom0, Dom).

load_html0(Dom, Opts, _, Read) :-
  load_html(Read, Dom, Opts).



%! json_download(+Source, -Json) is det.
%! json_download(+Source, -Json, +Opts) is det.

json_download(Source, Json) :-
  json_download(Source, Json, []).


json_download(Source, Json, Opts0) :-
  merge_options([request_header('Accept','application/json')], Opts0, Opts),
  http_get(Source, json_read_dict0(Json, Opts0), Opts).

json_read_dict0(Json, Opts, _, In) :-
  json_read_dict(In, Json, Opts).



%! xml_download(+Source, -Dom) is det.
%! xml_download(+Source, -Dom, +Opts) is det.
% Returns the HTML Document Object Model (DOM)
% for the website with the given IRI.

xml_download(Source, Dom) :-
  xml_download(Source, Dom, []).


xml_download(Source, Dom, Opts) :-
  http_get(Source, load_xml0(Dom, Opts)).

load_xml0(Dom, Opts, _, In) :-
  load_xml(In, Dom, Opts).





% HELPERS %

%! clean_dom(+Dom1, -Dom2) is det.
% Clean the given DOM tree in the following two ways:
%   1. Strip all blanks from the beginning and end of all strings.
%   2. Remove all strings that are empty under (1) from the DOM tree.

clean_dom([H1|T1], L2) :-
  atom(H1), !,
  % Strip all blanks from strings that appear in the DOM.
  strip_atom(H1, H2),
  % Remove empty strings from the DOM.
  (H2 == '' -> L2 = T2 ; L2 = [H2|T2]),
  clean_dom(T1, T2).
clean_dom([element(N,As,Contents1)|T1], [element(N,As,Contents2)|T2]) :- !,
  clean_dom(Contents1, Contents2),
  clean_dom(T1, T2).
clean_dom([], []).
