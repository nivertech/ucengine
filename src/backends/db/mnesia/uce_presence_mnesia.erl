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
-module(uce_presence_mnesia).

-author('victor.goya@af83.com').

-behaviour(gen_uce_presence).

-export([init/0, drop/0]).

-export([add/1,
	 list/1,
	 get/1,
	 delete/1,
	 update/1,
         all/0]).

-include("uce.hrl").

init() ->
    mnesia:create_table(uce_presence,
			[{disc_copies, [node()]},
			 {type, set},
			 {attributes, record_info(fields, uce_presence)}]).

add(#uce_presence{}=Presence) ->
    case mnesia:transaction(fun() ->
				    mnesia:write(Presence)
			    end) of
	{atomic, _} ->
	    {ok, Presence#uce_presence.sid};
	{aborted, Reason} ->
	    {error, Reason}
    end.

list(EUid) ->
    case mnesia:transaction(fun() ->
				    mnesia:match_object(#uce_presence{sid='_',
								      uid=EUid,
								      auth='_',
								      last_activity='_',
								      resource='_',
								      metadata='_'})
			    end) of
	{atomic, []} ->
	    {ok, []};
	{atomic, Records} ->
	    {ok, Records};
	{aborted, Reason} ->
	    {error, Reason}
    end.

all() ->
    {ok, ets:tab2list(uce_presence)}.

get(ESid) ->
    case mnesia:transaction(fun() ->
				    mnesia:read(uce_presence, ESid)
			    end) of
	{atomic, [Record]} ->
	    {ok, Record};
	{atomic, _} ->
	    {error, not_found};
	{aborted, Reason} ->
	    {error, Reason}
    end.

delete(Sid) ->
    case mnesia:transaction(fun() ->
				     mnesia:delete({uce_presence, Sid})
			     end) of
	{atomic, _} ->
	    {ok, deleted};
	{aborted, Reason} ->
	    {error, Reason}
    end.

update(#uce_presence{}=Presence) ->
    case mnesia:transaction(fun() ->
				       mnesia:write(Presence)
			    end) of
	{atomic, _} ->
	    {ok, updated};
	{aborted, Reason} ->
	    {error, Reason}
    end.

drop() ->
    mnesia:clear_table(uce_presence).
