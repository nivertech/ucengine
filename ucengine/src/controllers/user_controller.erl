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
-module(user_controller).

-export([init/0, add/4, update/4, get/4, list/4, delete/4, check_access/4, add_role/4, delete_role/4]).

-include("uce.hrl").

init() ->
    [#uce_route{method='POST',
                regexp="/user",
                callback={?MODULE, add,
                          [{"name", required, string},
                           {"auth", required, string},
                           {"credential", required, string},
                           {"metadata", [], dictionary}]}},

     #uce_route{method='GET',
                regexp="/user",
                callback={?MODULE, list,
                          [{"uid", required, string},
                           {"sid", required, string}]}},

     #uce_route{method='GET',
                regexp="/user/([^/]+)",
                callback={?MODULE, get,
                          [{"uid", required, string},
                           {"sid", required, string}]}},

     #uce_route{method='PUT',
                regexp="/user/([^/]+)",
                callback={?MODULE, update,
                          [{"uid", required, string},
                           {"sid", required, string},
                           {"name", required, string},
                           {"auth", required, string},
                           {"credential", required, string},
                           {"metadata", [], dictionary}]}},

     #uce_route{method='DELETE',
                regexp="/user/([^/]+)",
                callback={?MODULE, delete,
                          [{"uid", required, string},
                           {"sid", required, string}]}},

     #uce_route{method='GET',
                regexp="/user/([^/]+)/can/([^/]+)/([^/]+)/?([^/]+)?",
                callback={?MODULE, check_access,
                          [{"uid", required, string},
                           {"sid", required, string},
                           {"conditions", [], dictionary}]}},

     #uce_route{method='POST',
                regexp="/user/([^/]+)/roles",
                callback={?MODULE, add_role,
                          [{"uid", required, string},
                           {"sid", required, string},
                           {"role", required, string},
                           {"location", "", string}]}},

     #uce_route{method='DELETE',
                regexp="/user/([^/]+)/roles/([^/]+)/?([^/]+)?",
                callback={?MODULE, delete_role,
                          [{"uid", required, string},
                           {"sid", required, string}]}}].


add(Domain, [], [Name, Auth, Credential, Metadata], _) ->
    {ok, UId} = uce_user:add(Domain, #uce_user{id={none, Domain},
                                               name=Name,
                                               auth=Auth,
                                               credential=Credential,
                                               metadata=Metadata}),

    {ok, _} = uce_event:add(Domain, #uce_event{id={none, Domain},
                                               from={UId, Domain},
                                               location={"", Domain},
                                               type="internal.user.add"}),

    json_helpers:created(Domain, UId).

list(Domain, [], [Uid, Sid], _) ->
    {ok, true} = uce_presence:assert(Domain, {Uid, Domain}, {Sid, Domain}),
    {ok, true} = uce_access:assert(Domain, {Uid, Domain}, {"", ""}, "user", "list"),
    {ok, Users} = uce_user:list(Domain),
    json_helpers:json(Domain, {array, [user_helpers:to_json(User) || User <- Users]}).

get(Domain, [Id], [Uid, Sid], _) ->
    {ok, true} = uce_presence:assert(Domain, {Uid, Domain}, {Sid, Domain}),
    {ok, true} = uce_access:assert(Domain, {Uid, Domain}, {"", ""}, "user", "get", [{"user", Id}]),
    {ok, Record} = uce_user:get(Domain, {Id, Domain}),
    json_helpers:json(Domain, user_helpers:to_json(Record)).

update(Domain, [Id], [Uid, Sid, Name, Auth, Credential, Metadata], _) ->
    {ok, true} = uce_presence:assert(Domain, {Uid, Domain}, {Sid, Domain}),
    {ok, true} = uce_access:assert(Domain, {Uid, Domain}, {"", ""}, "user", "update", [{"user", Id},
                                                                                       {"auth", Auth}]),
    {ok, Record} = uce_user:get(Domain, {Id, Domain}),
    {ok, updated} = uce_user:update(Domain, Record#uce_user{name=Name,
                                                            auth=Auth,
                                                            credential=Credential,
                                                            metadata=Metadata}),

    {ok, _} = uce_event:add(Domain,
                            #uce_event{id={none, Domain},
                                       from={Id, Domain},
                                       location={"", Domain},
                                       type="internal.user.update"}),

    json_helpers:ok(Domain).

delete(Domain, [Id], [Uid, Sid], _) ->
    {ok, true} = uce_presence:assert(Domain, {Uid, Domain}, {Sid, Domain}),
    {ok, true} = uce_access:assert(Domain, {Uid, Domain}, {"", Domain}, "user", "delete", [{"user", Id}]),
    {ok, deleted} = uce_user:delete(Domain, {Id, Domain}),
    json_helpers:ok(Domain).

check_access(Domain, [Name, Action, Object], [Uid, Sid, Conditions], Arg) ->
    check_access(Domain, [Name, Action, Object, ""], [Uid, Sid, Conditions], Arg);
check_access(Domain, [Name, Action, Object, Location], [Uid, Sid, Conditions], _Arg) ->
    {ok, true} = uce_presence:assert(Domain, {Uid, Domain}, {Sid, Domain}),
    {ok, true} = uce_access:assert(Domain, {Uid, Domain}, {"", ""}, "access", "check", [{"user", Name},
                                                                                        {"action", Action},
                                                                                        {"object", Object},
                                                                                        {"location", Location}]),
    case uce_access:check(Domain, {Name, Domain}, {Location, Domain}, Object, Action, Conditions) of
        {ok, true} ->
            json_helpers:true(Domain);
        {ok, false} ->
            json_helpers:false(Domain)
    end.

add_role(Domain, [Name], [Uid, Sid, Role, Location], _) ->
    {ok, true} = uce_presence:assert(Domain, {Uid, Domain}, {Sid, Domain}),
    {ok, true} = uce_access:assert(Domain, {Uid, Domain}, {Location, Domain}, "user.role", "add", [{"user", Name},
                                                                                                   {"role", Role}]),
    {ok, updated} = uce_user:add_role(Domain, {Name, Domain}, {Role, Location}),
    {ok, _} = uce_event:add(Domain,
                            #uce_event{id={none, Domain},
                                       from={Uid, Domain},
                                       location={Location, Domain},
                                       type="internal.user.role.add",
                                       metadata=[{"role", Role},
                                                 {"user", Name}]}),
    json_helpers:ok(Domain).

delete_role(Domain, [User, Role], [Uid, Sid], Arg) ->
    delete_role(Domain, [User, Role, ""], [Uid, Sid], Arg);
delete_role(Domain, [User, Role, Location], [Uid, Sid], _Arg) ->
    {ok, true} = uce_presence:assert(Domain, {Uid, Domain}, {Sid, Domain}),
    {ok, true} = uce_access:assert(Domain, {Uid, Domain}, {Location, Domain}, "user.role", "delete", [{"user", User},
                                                                                                      {"role", Role}]),
    {ok, updated} = uce_user:delete_role(Domain, {User, Domain}, {Role, Location}),
    {ok, _} = uce_event:add(Domain,
                            #uce_event{id={none, Domain},
                                       from={Uid, Domain},
                                       location={Location, Domain},
                                       type="internal.user.role.delete",
                                       metadata=[{"role", Role},
                                                 {"user", User}]}),
    json_helpers:ok(Domain).