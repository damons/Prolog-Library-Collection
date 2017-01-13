:- module(
  http_download,
  [
    file_download/2, % +Source, ?File
    file_download/3, % +Source, ?File, +Opts
    html_download/2, % +Source, -Dom
    html_download/3, % +Source, -Dom,  +Opts
    xml_download/2,  % +Source, -Dom
    xml_download/3   % +Source, -Dom,  +Opts
  ]
).

/** <module> HTTP download

Support for downloading files and datastructures over HTTP(S).

@author Wouter Beek
@version 2015/07-2015/11, 2016/01, 2016/04, 2016/12
*/

:- use_module(library(atom_ext)).
:- use_module(library(error)).
:- use_module(library(hash_ext)).
:- use_module(library(http/http_ext)).
:- use_module(library(http/http_io)).
:- use_module(library(os/file_ext)).
:- use_module(library(os/io)).
:- use_module(library(option)).
:- use_module(library(sgml)).
:- use_module(library(uri)).
:- use_module(library(yall)).





%! file_download(+Uri, +File) is det.
%! file_download(+Uri, +File, +Opts) is det.
%
% Downloads the contents stored at the given URI to either the a File
% with either a given file name or a file name that is created based
% on the URI.
%
% The following options are supported:
%
%   * freshness_lifetime(+or([between(0.0,inf),oneof([inf])])) Sets
%   whether -- and if so, when -- files that were downloaded in the
%   past are redownloaded and overwritten.  Default is `inf`.
%
%   * Other options are passed to http_get/3.
%
% @throws type_error if Uri is not an absolute URI.

file_download(Uri, File) :-
  file_download(Uri, File, []).


% The file was already downloaded in the past.
file_download(Uri, File, Opts) :-
  nonvar(File),
  exists_file(File), !,
  (   option(freshness_lifetime(FL), Opts, inf),
      is_fresh_file(File, FL)
  ->  access_file(File, read)
  ;   delete_file(File),
      file_download(Uri, File, Opts)
  ).
% Throw an exception if Uri is not absolute.
file_download(Uri, _, _) :-
  \+ uri_is_global(Uri), !,
  type_error(absolute_uri, Uri).
% A file name is given.
file_download(Uri, File, Opts) :-
  iri_normalized(Uri, NormUri),
  md5(NormUri, Hash),
  thread_file(Hash, TmpFile),
  call_onto_stream(
    Uri,
    TmpFile,
    [In,InPath,InPath,Out]>>copy_stream_data(In, Out),
    [metadata(InPath)|Opts],
    Opts
  ),
  rename_file(TmpFile, File).



%! html_download(+Source, -Dom) is det.
%! html_download(+Source, -Dom, +Opts) is det.

html_download(Source, Dom) :-
  html_download(Source, Dom, []).


html_download(Source, Dom, Opts1) :-
  merge_options([encoding('utf-8'),max_errors(-1)], Opts1, Opts2),
  http_get(Source, html_download_stream(Dom, Opts2)).

html_download_stream(Dom, Opts, In, InPath, InPath) :-
  load_html(In, DirtyDom, Opts),
  clean_dom(DirtyDom, Dom).



%! xml_download(+Source, -Dom) is det.
%! xml_download(+Source, -Dom, +Opts) is det.
%
% Returns the HTML Document Object Model (DOM) for the website with
% the given URI.

xml_download(Source, Dom) :-
  xml_download(Source, Dom, []).


xml_download(Source, Dom, Opts) :-
  http_get(Source, {Dom,Opts}/[In,InPath,InPath]>>load_xml(In, Dom, Opts)).





% HELPERS %

%! clean_dom(+Dom1, -Dom2) is det.
%
% Clean the given DOM tree in the following two ways:
%
%   1. Strip all blanks from the beginning and end of all strings.
%
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
