%%
%%  U.C.Engine - Unified Colloboration Engine
%%  Copyright (C) 2011 af83
%%
%%  This program is free software: you can redistribute it and/or modify
%%  it under the terms of the GNU Affero General Public License as published by
%%  the Free Software Foundation, either version 3 of the License, or
%%  (at your option) any later version.
%%
%%  This program is distributed in the hope that it will be useful,
%%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%  GNU Affero General Public License for more details.
%%
%%  You should have received a copy of the GNU Affero General Public License
%%  along with this program.  If not, see <http://www.gnu.org/licenses/>.
%%
-module(ctl_tests).

-include("uce.hrl").
-include_lib("eunit/include/eunit.hrl").

ctl_meeting_test_() ->
    { setup
      , fun fixtures:setup/0
      , fun fixtures:teardown/1
      , fun(_Testers) ->
        [ ?_test(test_meeting_add())
        , ?_test(test_meeting_add_missing_parameter())
        % TODO: Test the conflict case
        , ?_test(test_meeting_get())
        , ?_test(test_meeting_get_missing_parameter())
        , ?_test(test_meeting_get_not_found())
        , ?_test(test_meeting_update())
        , ?_test(test_meeting_update_missing_parameter())
        , ?_test(test_meeting_update_not_found())
        , ?_test(test_meeting_delete())
        , ?_test(test_meeting_delete_missing_parameter())
        , ?_test(test_meeting_delete_not_found())
        , ?_test(test_meeting_list())
        , ?_test(test_meeting_list_missing_parameter())
        , ?_test(test_meeting_list_not_found())
        ]
      end
    }.

ctl_user_test_() ->
    { setup
      , fun fixtures:setup/0
      , fun fixtures:teardown/1
      , fun(_Testers) ->
        [ ?_test(test_user_add())
        , ?_test(test_user_add_missing_parameter())
        % TODO: Test the conflict case
        , ?_test(test_user_get())
        , ?_test(test_user_get_missing_parameter())
        , ?_test(test_user_get_not_found())
        , ?_test(test_user_update())
        , ?_test(test_user_update_missing_parameter())
        , ?_test(test_user_update_not_found())
        , ?_test(test_user_delete())
        , ?_test(test_user_delete_missing_parameter())
        , ?_test(test_user_delete_not_found())
        , ?_test(test_user_list())
        ]
      end
    }.

ctl_acl_test_() ->
    { setup
      , fun fixtures:setup/0
      , fun fixtures:teardown/1
      , fun(_Testers) ->
        [ ?_test(test_acl_add())
        , ?_test(test_acl_add_missing_parameter())
        % TODO: Test the conflict case
        , ?_test(test_acl_check())
        , ?_test(test_acl_check_missing_parameter())
        , ?_test(test_acl_delete())
        , ?_test(test_acl_delete_missing_parameter())
        , ?_test(test_acl_delete_not_found())
        ]
      end
    }.

ctl_infos_test_() ->
    { setup
      , fun fixtures:setup/0
      , fun fixtures:teardown/1
      , fun(_Tester) ->
                [ ?_test(test_infos_get())
                ,  ?_test(test_infos_update())
                ]
        end
    }.

%%
%% Meeting
%%

test_meeting_add() ->
    {error, not_found} = uce_meeting:get(["newmeeting"]),
    Params = [{"name", ["newmeeting"]}, {"description", [""]}],
    ok = uce_ctl:action(meeting, add, Params),
    Expected = {ok, #uce_meeting{id=["newmeeting"],
                                 start_date=0, end_date=0,
                                 metadata=[{"description", ""}]}},
    Expected = uce_meeting:get(["newmeeting"]).
test_meeting_add_missing_parameter() ->
    error = uce_ctl:action(meeting, add, []).

test_meeting_get() ->
    Params = [{"name", ["testmeeting"]}],
    ok = uce_ctl:action(meeting, get, Params).
test_meeting_get_missing_parameter() ->
    error = uce_ctl:action(meeting, get, []).
test_meeting_get_not_found() ->
    Params = [{"name", ["meeting that doesn't exists"]}],
    error = uce_ctl:action(meeting, get, Params).

test_meeting_update() ->
    {ok, #uce_meeting{ id=["testmeeting"]
                     , start_date=Start
                     , end_date=End
                     , metadata=[{"description", _Description}]
                     }} = uce_meeting:get(["testmeeting"]),
    StartDate = uce_ctl:timestamp_to_iso(Start),
    EndDate = uce_ctl:timestamp_to_iso(End),
    Params = [{"name", ["testmeeting"]}
             , {"start", StartDate}
             , {"end", EndDate}
             , {"description", ["A new description"]}
             ],
    ok = uce_ctl:action(meeting, update, Params),
    Expected = {ok, #uce_meeting{ id=["testmeeting"]
                                , start_date=uce_ctl:parse_date(StartDate)
                                , end_date=uce_ctl:parse_date(EndDate)
                                , metadata=[{"description", "A new description"}]
                                }},
    Expected = uce_meeting:get(["testmeeting"]).
test_meeting_update_missing_parameter() ->
    error = uce_ctl:action(meeting, update, []).
test_meeting_update_not_found() ->
    Params = [{"name", ["meeting that doesnt exists"]}],
    error = uce_ctl:action(meeting, update, Params).

test_meeting_delete() ->
    {ok, #uce_meeting{ id=["testmeeting"]
                     , start_date=_Start
                     , end_date=_End
                     , metadata=[{"description", _Description}]
                     }} = uce_meeting:get(["testmeeting"]),
    Params = [{"name", ["testmeeting"]}],
    ok = uce_ctl:action(meeting, delete, Params),
    {error, not_found} = uce_meeting:get(["testmeeting"]).
test_meeting_delete_missing_parameter() ->
    error = uce_ctl:action(meeting, delete, []).
test_meeting_delete_not_found() ->
    Params = [{"name", ["meeting that doesn't exists"]}],
    error = uce_ctl:action(meeting, delete, Params).

test_meeting_list() ->
    Params = [{"status", ["all"]}],
    ok = uce_ctl:action(meeting, list, Params).
test_meeting_list_missing_parameter() ->
    error = uce_ctl:action(meeting, list, []).
test_meeting_list_not_found() ->
    error = uce_ctl:action(meeting, list, []).

%%
%% User
%%

test_user_add() ->
    {error, not_found} = uce_user:get("test.user@af83.com"),
    Params = [ {"uid", ["test.user@af83.com"]}
             , {"auth", ["password"]}
             , {"credential", ["pwd"]}
             ],
    ok = uce_ctl:action(user, add, Params),
    {ok, #uce_user{uid="test.user@af83.com",
                   auth="password",
                   credential="pwd"}} = uce_user:get("test.user@af83.com").
test_user_add_missing_parameter() ->
    Params = [ {"auth", ["password"]}
             , {"credential", ["pwd"]}
             ],
    error = uce_ctl:action(user, add, Params).

test_user_get() ->
    Params = [ {"uid", ["participant.user@af83.com"]}
             , {"auth", ["password"]}
             , {"credential", ["pwd"]}
             ],
    ok = uce_ctl:action(user, get, Params).
test_user_get_missing_parameter() ->
    Params = [{"auth", ["password"]}, {"credential", ["pwd"]}],
    error = uce_ctl:action(user, get, Params).
test_user_get_not_found() ->
    Params = [ {"uid", ["nobody@af83.com"]}
             , {"auth", ["password"]}
             , {"credential", ["pwd"]}
             ],
    error = uce_ctl:action(user, get, Params).

test_user_update() ->
    {ok, #uce_user{uid="anonymous.user@af83.com",
                   auth="anonymous",
                   credential=""}} =
        uce_user:get("anonymous.user@af83.com"),
    Params = [ {"uid", ["anonymous.user@af83.com"]}
             , {"auth", ["password"]}
             , {"credential", ["pwd"]}
             ],
    ok = uce_ctl:action(user, update, Params),
    {ok, #uce_user{uid="anonymous.user@af83.com",
                   auth="password",
                   credential="pwd"}} =
        uce_user:get("anonymous.user@af83.com").
test_user_update_missing_parameter() ->
    error = uce_ctl:action(user, update, []).
test_user_update_not_found() ->
    Params = [ {"uid", ["nobody@af83.com"]}
             , {"auth", ["password"]}
             , {"credential", ["passwd"]}
             ],
    error = uce_ctl:action(user, update, Params).

test_user_delete() ->
    {ok, #uce_user{uid="participant.user@af83.com",
                   auth="password",
                   credential="pwd"}} = uce_user:get("participant.user@af83.com"),
    Params = [{"uid", ["participant.user@af83.com"]}],
    ok = uce_ctl:action(user, delete, Params),
    {error, not_found} = uce_user:get("participant.user@af83.com").
test_user_delete_missing_parameter() ->
    error = uce_ctl:action(user, delete, []).
test_user_delete_not_found() ->
    Params = [ {"uid", ["nobody@af83.com"]}
             , {"auth", ["password"]}
             , {"credential", ["passwd"]}
             ],
    error = uce_ctl:action(user, delete, Params).


test_user_list() ->
    ok = uce_ctl:action(user, list, []).

%%
%% ACL
%%

test_acl_add() ->
    Params = [ "participant.user@af83.com"
             , "user"
             , "add"
             , [""]
             , []
             ],
    {ok, false} = erlang:apply(uce_acl, check, Params),
    ACL = [ {"uid", ["participant.user@af83.com"]}
          , {"action", ["add"]}
          , {"object", ["user"]}
          ],
    ok = uce_ctl:action(acl, add, ACL),
    {ok, true} = erlang:apply(uce_acl, check, Params).
test_acl_add_missing_parameter() ->
    Params = [ {"action", ["add"]}
             , {"object", ["user"]}
             , {"org", ["testorg"]}
             , {"meeting", ["testmeeting"]}
             ],
    error = uce_ctl:action(acl, add, Params).

test_acl_check() ->
    Params = [ {"uid", ["participant.user@af83.com"]}
             , {"action", ["delete"]}
             , {"object", ["presence"]}
             , {"user", ["participant.user@af83.com"]}
             ],
    ok = uce_ctl:action(acl, check, Params).
test_acl_check_missing_parameter() ->
    Params = [ {"action", ["delete"]}
             , {"object", ["presence"]}
             , {"user", ["participant.user@af83.com"]}
             ],
    error = uce_ctl:action(acl, check, Params).

test_acl_delete() ->
    Params = [ {"uid", ["participant.user@af83.com"]}
             , {"action", ["add"]}
             , {"object", ["presence"]}
             ],
    ok = uce_ctl:action(acl, delete, Params).
test_acl_delete_missing_parameter() ->
    Params = [ {"action", ["delete"]}
             , {"object", ["presence"]}
             ],
    error = uce_ctl:action(acl, delete, Params).
test_acl_delete_not_found() ->
    Params = [ {"uid", ["nobody@af83.com"]}
             , {"action", ["add"]}
             , {"object", ["presence"]}
             ],
    error = uce_ctl:action(acl, delete, Params).


%%
%% Infos
%%

test_infos_get() ->
    ok = uce_ctl:action(infos, get, []).

test_infos_update() ->
    {ok, []} = uce_infos:get(),
    Params = [{"description", ["Informations"]}],
    ok = uce_ctl:action(infos, update, Params),
    {ok, [{"description", "Informations"}]} = uce_infos:get().
