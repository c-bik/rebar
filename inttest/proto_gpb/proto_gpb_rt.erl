%% -*- erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ts=4 sw=4 et
%% -------------------------------------------------------------------
%%
%% rebar: Erlang Build Tools
%%
%% Copyright (c) 2014 Luis Rascão (luis.rascao@gmail.com)
%%
%% Permission is hereby granted, free of charge, to any person obtaining a copy
%% of this software and associated documentation files (the "Software"), to deal
%% in the Software without restriction, including without limitation the rights
%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%% copies of the Software, and to permit persons to whom the Software is
%% furnished to do so, subject to the following conditions:
%%
%% The above copyright notice and this permission notice shall be included in
%% all copies or substantial portions of the Software.
%%
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
%% THE SOFTWARE.
%% -------------------------------------------------------------------
-module(proto_gpb_rt).
-export([files/0,
         run/1]).

-include_lib("eunit/include/eunit.hrl").

-define(MODULES,
        [foo,
         foo_app,
         foo_sup]).

-define(GENERATED_MODULES,
        [test_gpb,
         test2_gpb,
         test3_gpb,
         test4_gpb,
         test5_gpb]).

files() ->
    [
     {copy, "../../rebar", "rebar"},
     {copy, "rebar.config", "rebar.config"},
     {copy, "include", "include"},
     {copy, "src", "src"},
     {create, "ebin/foo.app", app(foo, ?MODULES ++ ?GENERATED_MODULES)}
    ].

run(_Dir) ->
    ?assertMatch({ok, _}, retest_sh:run("./rebar prepare-deps", [])),
    ?assertMatch({ok, _}, retest_sh:run("./rebar clean", [])),
    ?assertMatch({ok, _}, retest_sh:run("./rebar compile", [])),
    %% Foo includes test_gpb.hrl,
    %% So if it compiled, that also means gpb succeeded in
    %% generating the test_gpb.hrl file, and also that it generated
    %% the .hrl file was generated before foo was compiled.
    ok = check_beams_generated(),
    ?assertMatch({ok, _}, retest_sh:run("./rebar clean", [])),
    ok = check_files_deleted(),
    ok.

check_beams_generated() ->
    check(fun filelib:is_regular/1,
          beam_files()).

check_files_deleted() ->
    check(fun file_does_not_exist/1,
          beam_files() ++ generated_erl_files() ++ generated_hrl_files()).

beam_files() ->
    add_dir("ebin", add_ext(?MODULES, ".beam")).

generated_erl_files() ->
    add_dir("src", add_ext(?GENERATED_MODULES, ".erl")).

generated_hrl_files() ->
    add_dir("include", add_ext(?GENERATED_MODULES, ".hrl")).

file_does_not_exist(F) ->
    not filelib:is_regular(F).

add_ext(Modules, Ext) ->
    [lists:concat([Module, Ext]) || Module <- Modules].

add_dir(Dir, Files) ->
    [filename:join(Dir, File) || File <- Files].

check(Check, Files) ->
    lists:foreach(
      fun(F) ->
              ?assertMatch({true, _}, {Check(F), F})
      end,
      Files).

%%
%% Generate the contents of a simple .app file
%%
app(Name, Modules) ->
    App = {application, Name,
           [{description, atom_to_list(Name)},
            {vsn, "1"},
            {modules, Modules},
            {registered, []},
            {applications, [kernel, stdlib, gpb]}]},
    io_lib:format("~p.\n", [App]).
