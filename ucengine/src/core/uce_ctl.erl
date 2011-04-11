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
-module(uce_ctl).

-author('victor.goya@af83.com').

-export([start/0, stop/0, getopt/2, action/2, success/1, error/1]).
-export([parse_date/1, timestamp_to_iso/1]).

-compile({no_auto_import,[error/1]}).

-include("uce.hrl").

get_node() ->
    Command = init:get_arguments(),
    case utils:get(Command, ['-node']) of
        [none] ->
            NodeDomain =
                case re:run(atom_to_list(node()), "@(.*)", [{capture, all, list}]) of
                    {match, [_, Domain]} ->
                        Domain;
                    _ ->
                        "localhost"
                end,
            list_to_atom("ucengine@" ++ NodeDomain);
        [[Node]] ->
            list_to_atom(Node)
    end.

args_to_dictionary([]) ->
    [];
args_to_dictionary([{Key, Value}|Tail]) when is_atom(Key) ->
    args_to_dictionary([{atom_to_list(Key), Value}] ++ Tail);
args_to_dictionary([{[$- | Key], Value} | Tail]) ->
    [{Key, Value}] ++ args_to_dictionary(Tail);
args_to_dictionary([_|Tail]) ->
    [] ++ args_to_dictionary(Tail).

start() ->
    Command = init:get_arguments(),
    case utils:get(Command, [dummy]) of
        [[Object, _|_]] = [Params] ->
            case catch action(Params, args_to_dictionary(Command)) of
                ok ->
                    io:format("~n"),
                    init:stop(0);
                error ->
                    io:format("~n"),
                    init:stop(2);
                {ok, nothing} ->
                    init:stop(0);
                {ok, Result} ->
                    io:format(Result),
                    init:stop(0);
                {'EXIT', {{case_clause, _}, _}} ->
                    usage(list_to_atom(Object));
                Exception when is_list(Exception) ->
                    io:format("Fatal: " ++ Exception ++ "~n"),
                    init:stop(2);
                Exception ->
                    io:format("Fatal: ~p~n", [Exception]),
                    init:stop(2)
            end;
        [[Object|_]] ->
            usage(list_to_atom(Object));
        _ ->
            usage()
    end,
    halt().

stop() ->
    ok.

usage() ->
    usage(none).
usage(Object) ->
    io:format("Usage:~n"),
    io:format("ucengine-admin <object> <action> [--<parameter> <value>]~n~n"),

    if
        Object == none ; Object == meeting ->
            io:format("Meetings:~n"),
            io:format("\tmeeting add --domain <domain> --name <name> --start <date> --end <date> [--<metadata> <value>]~n"),
            io:format("\tmeeting update --domain <domain> --name <name> --start <date> --end <date> [--<metadata> <value>]~n"),
            io:format("\tmeeting get --domain <domain> --name <name>~n"),
            io:format("\tmeeting delete --domain <domain> --name <name>~n"),
            io:format("\tmeeting list --domain <domain> --status <status>~n~n");
        true ->
            nothing
    end,
    if
        Object == none ; Object == user ->
            io:format("Users:~n"),
            io:format("\tuser add --domain <domain> --name <name> --auth <auth> --credential <credential> [--<metadata> <value>]~n"),
            io:format("\tuser update --domain <domain> [--name <name>|--uid <uid>] --auth <auth> --credential <credential> [--<metadata> <value>]~n"),
            io:format("\tuser get --domain <domain> [--name <name>|--uid <uid>]~n"),
            io:format("\tuser delete --domain <domain> [--name <name>|--uid <uid>]~n"),
            io:format("\tuser list --domain <domain>~n"),
            io:format("\tuser role add --domain <domain> [--name <name>|--uid <uid>] --role <role> [--location <location>]~n"),
            io:format("\tuser role delete --domain <domain> [--name <name>|--uid <uid>] --role <role> [--location <location>]~n~n");
        true ->
            nothing
    end,
    if
        Object == none ; Object == role ->
            io:format("Roles:~n"),
            io:format("\trole add --domain <domain> --name <name>~n"),
            io:format("\trole delete --domain <domain> --name <name>~n"),
            io:format("\trole access add --domain <domain> --name <name> --action <action> --object <object> [--<condition> <value>]~n"),
            io:format("\trole access delete --domain <domain> --name <name> --action <action> --object <object> [--<condition> <value>]~n"),
            io:format("\trole access check --domain <domain> --name <name> --action <action> --object <object> [--<condition> <value>]~n~n");
        true ->
            nothing
    end,

    io:format("Formatting:~n"),
    io:format("\t<date>: ISO8601 formatted date (ex. '2010-25-12 00:00:01')~n~n"),
    io:format("U.C.Engine (c) AF83 - http://ucengine.org~n"),
    {ok, nothing}.

getvalues([], _, _) ->
    [];
getvalues([Key|Keys], Args, [Default|Defaults]) ->
    case lists:keyfind(Key, 1, Args) of
        {_, ArgValue} ->
            [string:join(ArgValue, " ")];
        false ->
            [Default]
    end ++ getvalues(Keys, Args, Defaults).

getopt([], Args) ->
    {[], [{Key, string:join(Value, " ")} || {Key, Value} <- Args]};
getopt(Keys, Args) ->
    getopt(Keys, Args, array:to_list(array:new(length(Keys), {default, none}))).
getopt(Keys, Args, Defaults) ->
    Values = getvalues(Keys, Args, Defaults),
    RawRemaining = lists:filter(fun({ArgKey, _}) ->
                                        lists:member(ArgKey, Keys) == false
                                end,
                                Args),
    Remaining = [{Key, string:join(Value, " ")} || {Key, Value} <- RawRemaining],
    {Values, Remaining}.

call(Object, Action, Args) ->
    Module = list_to_atom("uce_" ++ atom_to_list(Object)),
    case catch rpc:call(get_node(), Module, Action, Args) of
        {badrpc, Reason} ->
            throw({error, Reason});
        {error, Reason} ->
            throw({error, Reason});
        Result ->
            Result
    end.

parse_date([Date, Time]) when is_list(Date), is_list(Time) ->
    parse_date(Date ++ " " ++ Time);
parse_date(Datetime) when is_list(Datetime) ->
    case string:tokens(Datetime, "- :") of
        [Year, Month, Day, Hours, Minutes, Seconds] ->
            DateTime = {{list_to_integer(Year),
                         list_to_integer(Day),
                         list_to_integer(Month)},
                        {list_to_integer(Hours),
                         list_to_integer(Minutes),
                         list_to_integer(Seconds)}},
            Epoch =
                calendar:datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}}),
            (calendar:datetime_to_gregorian_seconds(DateTime) - Epoch) * 1000;
        _ ->
            throw({error, bad_date})
    end;
parse_date(none) ->
    0.

timestamp_to_iso(Militimestamp) when is_integer(Militimestamp) ->
    Epoch = calendar:datetime_to_gregorian_seconds({{1970,1,1}, {0,0,0}}),
    Timestamp = Epoch + (Militimestamp div 1000),
    {{Year, Month, Day}, {Hours, Minutes, Seconds}} =
        calendar:gregorian_seconds_to_datetime(Timestamp),
    Date = io_lib:format("~p-~p-~p ~p:~p:~p"
                         , [Year, Day, Month, Hours, Minutes, Seconds]),
    lists:flatten(Date).


success(Result) when is_list(Result) ->
    io:format("Success: ~s", [Result]),
    ok;
success(Result) ->
    io:format("Success: ~p", [Result]),
    ok.

error(Reason) ->
    case Reason of
        nodedown ->
            io:format("Fatal: U.C.Engine node is not running, call 'ucengine start' to start it.");
        _ ->
            io:format("Error: ~p", [Reason])
    end,
    error.

%%
%% Meeting
%%
action(["meeting", "add"], Args) ->
    case getopt(["domain", "name", "start", "end"], Args) of
        {[none, _, _, _], _Metadata} ->
            error(missing_parameter);
        {[_, none, _, _], _Metadata} ->
            error(missing_parameter);
        {[Domain, Name, Start, End], Metadata} ->
            {ok, created} = call(meeting, add, [Domain,
                                                #uce_meeting{id={Name, Domain},
                                                             start_date=parse_date(Start),
                                                             end_date=parse_date(End),
                                                             metadata=Metadata}]),
            success(created)
    end;

action(["meeting", "delete"], Args) ->
    case getopt(["domain", "name"], Args) of
        {[none, _], _} ->
            error(missing_parameter);
        {[_, none], _} ->
            error(missing_parameter);
        {[Domain, Name], _} ->
            {ok, deleted} = call(meeting, delete, [Domain, {Name, Domain}]),
            success(deleted)
    end;

action(["meeting", "get"], Args) ->
    case getopt(["domain", "name"], Args) of
        {[none, _], _} ->
            error(missing_parameter);
        {[_, none], _} ->
            error(missing_parameter);
        {[Domain, Name], _} ->
            {ok, Record} = call(meeting, get, [Domain, {Name, Domain}]),
            {ok, meeting_helpers:pretty_print(Record, flat)}
    end;

action(["meeting", "update"], Args) ->
    case getopt(["domain", "name", "start", "end"], Args) of
        {[none, _, _, _], _Metadata} ->
            error(missing_parameter);
        {[_, none, _, _], _Metadata} ->
            error(missing_parameter);
        {[Domain, Name, Start, End], Metadata} ->
            {ok, updated} = call(meeting, update, [Domain,
                                                   #uce_meeting{id={Name, Domain},
                                                                start_date=parse_date(Start),
                                                                end_date=parse_date(End),
                                                                metadata=Metadata}]),
            success(updated)
    end;

action(["meeting", "list"], Args) ->
    case getopt(["domain", "status"], Args, [none, "all"]) of
        {[none, _], _} ->
            error(missing_parameter);
        {[Domain, Status], _} ->
            {ok, Records} = call(meeting, list, [Domain, Status]),
            {ok, meeting_helpers:pretty_print(Records, flat)}
    end;

%%
%% Users
%%
action(["user", "add"], Args) ->
    case getopt(["domain", "name", "auth", "credential"], Args) of
        {[none, _, _, _], _Metadata} ->
            error(missing_parameter);
        {[_, none, _, _], _Metadata} ->
            error(missing_parameter);
        {[_, _, none, _], _Metadata} ->
            error(missing_parameter);
        {[_, _, _, none], _Metadata} ->
            error(missing_parameter);
        {[Domain, Name, Auth, Credential], Metadata} ->
            {ok, Uid} = call(user, add, [Domain,
                                         #uce_user{id={none, Domain},
                                                   name=Name,
                                                   auth=Auth,
                                                   credential=Credential,
                                                   metadata=Metadata}]),
           success(Uid)
    end;

action(["user", "delete"], Args) ->
    case getopt(["domain", "name", "uid"], Args) of
        {[none, _, _], _} ->
            error(missing_parameter);
        {[Domain, Name, Id], _}
          when is_list(Name) or is_list(Id) ->
            FinalId =
                if
                    Name /= none ->
                        {ok, #uce_user{id={TmpId, _}}} = call(user, get, [Domain, Name]),
                        TmpId;
                    true ->
                        Id
                end,
            {ok, deleted} = call(user, delete, [Domain, {FinalId, Domain}]),
            success(deleted);
        {[_, _, _], _} ->
            error(missing_parameter)
    end;


action(["user", "get"], Args) ->
    case getopt(["domain", "name", "uid"], Args) of
        {[none, _, _], _} ->
            error(missing_parameter);
        {[Domain, Name, Id], _}
          when is_list(Name) or is_list(Id) ->
            {ok, Record} =
                if
                    Name /= none ->
                        call(user, get, [Domain, Name]);
                    true ->
                        call(user, get, [Domain, {Id, Domain}])
                end,
            {ok, user_helpers:pretty_print(Record, flat)};
        {[_, _, _], _} ->
            error(missing_parameter)
    end;

action(["user", "update"], Args) ->
    case getopt(["domain", "name", "uid", "auth", "credential"], Args) of
        {[none, _, _, _, _], _Metadata} ->
            error(missing_parameter);
        {[_, _, _, none, _], _Metadata} ->
            error(missing_parameter);
        {[_, _, _, _, none], _Metadata} ->
            error(missing_parameter);
        {[Domain, Name, Id, Auth, Credential], Metadata}
          when is_list(Name) or is_list(Id) ->
            FinalId =
                if
                    Name /= none ->
                        {ok, #uce_user{id={TmpId, _}}} = call(user, get, [Domain, Name]),
                        TmpId;
                    true ->
                        Id
                end,
            {ok, updated} = call(user, update, [Domain,
                                                #uce_user{id={FinalId, Domain},
                                                          name=Name,
                                                          auth=Auth,
                                                          credential=Credential,
                                                          metadata=Metadata}]),
            success(updated);
        {[_, _, _, _, _], _Metadata} ->
            error(missing_parameter)
    end;

action(["user", "list"], Args) ->
    case getopt(["domain"], Args) of
        {[none], _} ->
            error(missing_parameter);
        {[Domain], _} ->
            {ok, Records} = call(user, list, [Domain]),
            {ok, user_helpers:pretty_print(Records, flat)}
    end;

action(["user", "role", "add"], Args) ->
    case getopt(["domain", "name", "uid", "role", "location"], Args, [none, none, none, none, ""]) of
        {[none, _, _, _, _], _Metadata} ->
            error(missing_parameter);
        {[_, _, _, none, _], _Metadata} ->
            error(missing_parameter);
        {[_, _, _, _, none], _Metadata} ->
            error(missing_parameter);
        {[Domain, Name, Id, Role, Location], _Metadata}
          when is_list(Name) or is_list(Id) ->
            FinalId =
                if
                    Name /= none ->
                        {ok, #uce_user{id={TmpId, _}}} = call(user, get, [Domain, Name]),
                        TmpId;
                    true ->
                        Id
                end,
            {ok, updated} = call(user, add_role, [Domain,
                                                  {FinalId, Domain},
                                                  {Role, Location}]),
            success(updated);
        {[_, _, _, _, _], _Metadata} ->
            error(missing_parameter)
    end;

action(["user", "role", "delete"], Args) ->
    case getopt(["domain", "name", "uid", "role", "location"], Args, [none, none, none, none, ""]) of
        {[none, _, _, _, _], _Metadata} ->
            error(missing_parameter);
        {[_, _, _, none, _], _Metadata} ->
            error(missing_parameter);
        {[_, _, _, _, none], _Metadata} ->
            error(missing_parameter);
        {[Domain, Name, Id, Role, Location], _Metadata}
          when is_list(Name) or is_list(Id) ->
            FinalId =
                if
                    Name /= none ->
                        {ok, #uce_user{id={TmpId, _}}} = call(user, get, [Domain, Name]),
                        TmpId;
                    true ->
                        Id
                end,
            {ok, updated} = call(user, delete_role, [Domain,
                                                     {FinalId, Domain},
                                                     {Role, Location}]),
            success(updated);
        {[_, _, _, _, _], _Metadata} ->
            error(missing_parameter)
    end;

%%
%% Roles
%%
action(["role", "add"], Args) ->
     case getopt(["domain", "name"], Args) of
         {[none, _], _} ->
             error(missing_parameter);
         {[_, none], _} ->
             error(missing_parameter);
         {[Domain, Name], _} ->
             {ok, created} = call(role, add, [Domain, #uce_role{id={Name, Domain}}]),
             success(created)
     end;

action(["role", "delete"], Args) ->
     case getopt(["domain", "name"], Args) of
         {[none, _], _} ->
             error(missing_parameter);
         {[_, none], _} ->
             error(missing_parameter);
         {[Domain, Name], _} ->
             {ok, deleted} = call(role, delete, [Domain, {Name, Domain}]),
             success(deleted)
     end;

action(["role", "access", "add"], Args) ->
     case getopt(["domain", "name", "action", "object"], Args) of
         {[none, _, _, _], _} ->
             error(missing_parameter);
         {[_, none, _, _], _} ->
             error(missing_parameter);
         {[_, _, none, _], _} ->
             error(missing_parameter);
         {[_, _, _, none], _} ->
             error(missing_parameter);
         {[Domain, Name, Action, Object], Conditions} ->
             {ok, updated} = call(role, add_access, [Domain, {Name, Domain},
                                                    #uce_access{action=Action,
                                                                object=Object,
                                                                conditions=Conditions}]),
             success(updated)
     end;

action(["role", "access", "delete"], Args) ->
     case getopt(["domain", "name", "action", "object"], Args) of
         {[none, _, _, _], _} ->
             error(missing_parameter);
         {[_, none, _, _], _} ->
             error(missing_parameter);
         {[_, _, none, _], _} ->
             error(missing_parameter);
         {[_, _, _, none], _} ->
             error(missing_parameter);
         {[Domain, Name, Action, Object], Conditions} ->
             {ok, updated} = call(role, delete_access, [Domain, {Name, Domain},
                                                       #uce_access{action=Action,
                                                                   object=Object,
                                                                   conditions=Conditions}]),
             success(updated)
     end;

action(["role", "access", "check"], Args) ->
     case getopt(["domain", "uid", "location", "action", "object"], Args, [none, none, "", none, none]) of
         {[none, _, _, _, _], _} ->
             error(missing_parameter);
         {[_, none, _, _, _], _} ->
             error(missing_parameter);
         {[_, _, _, none, _], _} ->
             error(missing_parameter);
         {[_, _, _, _, none], _} ->
             error(missing_parameter);
         {[Domain, Uid, Location, Action, Object], Conditions} ->
             {ok, Result} = call(access, check, [Domain,
                                                 {Uid, Domain},
                                                 {Location, Domain},
                                                 Object,
                                                 Action,
                                                 Conditions]),
             success(Result)
     end;

%%
%% Time
%%

action(["time", "get"], _) ->
    io:format("Server time: ~p", [utils:now()]),
    ok;

%%
%% Info
%%
action(["infos", "get"], Args) ->
    case getopt(["domain"], Args) of
        {[none], _} ->
            error(missing_parameter);
        {[Domain], _} ->
            {ok, Infos} = call(infos, get, [Domain]),
            {ok, infos_helpers:pretty_print(Infos, flat)}
    end;

action(["infos", "update"], Args) ->
    case getopt(["domain"], Args) of
        {[Domain], Metadata} ->
            {ok, updated} = call(infos, update, [Domain, #uce_infos{domain=Domain, metadata=Metadata}]),
            success(updated);
        _ ->
            error(missing_parameter)
    end;

%%
%% Utils
%%
action(["demo", "start"], _) ->
    rpc:call(get_node(), demo, start, []),
    success(started);

action([Object|_], _) ->
    usage(list_to_atom(Object)).