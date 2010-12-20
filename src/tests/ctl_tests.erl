-module(ctl_tests).

-include("uce.hrl").
-include_lib("eunit/include/eunit.hrl").

ctl_test_() ->
    { setup
      , fun fixtures:setup/0
      , fun fixtures:teardown/1
      , fun(_Testers) ->
        [ ?_test(test_org_add())
        , ?_test(test_org_add_missing_parameter())
        , ?_test(test_org_get())
        , ?_test(test_org_get_missing_parameter())
        , ?_test(test_org_get_not_found())
        , ?_test(test_org_update())
        , ?_test(test_org_update_missing_parameter())
        , ?_test(test_org_update_not_found())
        , ?_test(test_org_delete())
        , ?_test(test_org_delete_missing_parameter())
        , ?_test(test_org_delete_not_found())
        ]
      end
    }.

%%
%% Org
%%
test_org_add() ->
    {error, not_found} = uce_org:get("neworg"),
    Params = [{"name", ["neworg"]}, {"description", [""]}],
    ok = uce_ctl:action(org, add, Params),
    Expected = {ok, #uce_org{name="neworg", metadata=[{"description", ""}]}},
    Expected = uce_org:get("neworg").
test_org_add_missing_parameter() ->
    Params = [{"description", [""]}],
    error = uce_ctl:action(org, add, Params).

test_org_get() ->
    Params = [{"name", ["testorg"]}],
    ok = uce_ctl:action(org, get, Params).
test_org_get_missing_parameter() ->
    error = uce_ctl:action(org, get, []).
test_org_get_not_found() ->
    Params = [{"name", ["org that doesnt exists"]}],
    error = uce_ctl:action(org, get, Params).

test_org_update() ->
    Before = {ok, #uce_org{name="testorg", metadata=[{"description", "testorg"}]}},
    Before = uce_org:get("testorg"),
    Params = [{"name", ["testorg"]}, {"description", ["A new description"]}],
    ok = uce_ctl:action(org, update, Params),
    Expected = {ok, #uce_org{name="testorg", metadata=[{"description", "A new description"}]}},
    Expected = uce_org:get("testorg").
test_org_update_missing_parameter() ->
    error = uce_ctl:action(org, update, []).
test_org_update_not_found() ->
    Params = [{"name", ["org that doesnt exists"]}],
    error = uce_ctl:action(org, update, Params).

test_org_delete() ->
    Before = {ok, #uce_org{name="testorg", metadata=[{"description", "A new description"}]}},
    Before = uce_org:get("testorg"),
    Params = [{"name", ["testorg"]}],
    ok = uce_ctl:action(org, delete, Params),
    {error, not_found} = uce_org:get("testorg").
test_org_delete_missing_parameter() ->
    error = uce_ctl:action(org, delete, []).
test_org_delete_not_found() ->
    Params = [{"name", ["org that doesnt exists"]}],
    error = uce_ctl:action(org, delete, Params).

test_org_list() ->
    ok = uce_ctl:action(org, list, []).
