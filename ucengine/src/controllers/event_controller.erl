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
-module(event_controller).

-export([init/0, get/4, list/4, add/4]).

-include("uce.hrl").
-include_lib("yaws/include/yaws_api.hrl").

init() ->
    [#uce_route{method='POST',
                path=["event", '...'],
                callback={?MODULE, add,
                          [{"uid", required, string},
                           {"sid", required, string},
                           {"type", required, string},
                           {"to", "", string},
                           {"parent", "", string},
                           {"metadata", [], dictionary}]}},

     #uce_route{method='GET',
                path=["event", meeting, id],
                callback={?MODULE, get,
                          [{"uid", required, string},
                           {"sid", required, string}]}},

     #uce_route{method='GET',
                path=["event", '...'],
                callback={?MODULE, list,
                          [{"uid", required, string},
                           {"sid", required, string},
                           {"search", "", string},
                           {"type", "", string},
                           {"from", "", string},
                           {"start", 0, integer},
                           {"end", infinity, [integer, atom]},
                           {"count", infinity, [integer, atom]},
                           {"page", 1, integer},
                           {"order", asc, atom},
                           {"parent", "", string},
                           {"_async", "no", string}]}}].

add(Domain, [], Params, Arg) ->
    add(Domain, [""], Params, Arg);
add(Domain, [Meeting], [Uid, Sid, Type, To, Parent, Metadata], _) ->
    {ok, true} = uce_presence:assert(Domain, Uid, Sid),
    {ok, true} = uce_access:assert(Domain, Uid, Meeting, "event", "add",
                                   [{"type", Type}, {"to", To}]),
    case Type of
        "internal."++ _Rest ->
            throw({error, unauthorized});
        _OtherEvent ->
            {ok, Id} = uce_event:add(Domain,
                                     #uce_event{id=none,
                                                location=Meeting,
                                                from=Uid,
                                                type=Type,
                                                to=To,
                                                parent=Parent,
                                                metadata=Metadata}),
            json_helpers:created(Domain, Id)
    end.

get(Domain, [_, {id, Id}], [Uid, Sid], _) ->
    {ok, true} = uce_presence:assert(Domain, Uid, Sid),
    {ok, true} = uce_access:assert(Domain, Uid, "", "event", "get", [{"id", Id}]),
    {ok, #uce_event{to=To} = Event} = uce_event:get(Domain, Id),
    case To of
        "" ->
            json_helpers:json(Domain, Event);
        Uid ->
            json_helpers:json(Domain, Event);
        _ ->
            throw({error, unauthorized})
    end.

list(Domain, [], Params, Arg) ->
    list(Domain, [""], Params, Arg);
list(Domain, [Meeting],
     [Uid, Sid, Search, Type, From, DateStart, DateEnd, Count, Page, Order, Parent, Async], _Arg) ->

    {ok, true} = uce_presence:assert(Domain, Uid, Sid),
    {ok, true} = uce_access:assert(Domain, Uid, Meeting, "event", "list", [{"from", From}]),

    Keywords = string:tokens(Search, ","),
    Types = string:tokens(Type, ","),

    Start = uce_paginate:index(Count, 0, Page),
    case uce_event:list(Domain,
                        Meeting,
                        Keywords,
                        From,
                        Types,
                        Uid,
                        DateStart,
                        DateEnd,
                        Parent,
                        Start,
                        Count,
                        Order) of
        {ok, []} ->
            case Async of
                "no" ->
                    json_helpers:json(Domain, []);
                "lp" ->
                    uce_async_lp:wait(Domain,
                                      Meeting,
                                      Keywords,
                                      From,
                                      Types,
                                      Uid,
                                      DateStart,
                                      DateEnd,
                                      Parent);
                _ ->
                    {error, bad_parameters}
            end;
        {ok, Events} -> json_helpers:json(Domain, Events)
    end.
