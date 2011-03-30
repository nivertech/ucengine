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
-module(uce_role).

-author('victor.goya@af83.com').

-export([add/2,
         delete/2,
         update/2,
         get/2,
         exists/2,
         acl/2,
         add_access/3,
         delete_access/3]).

-include("uce.hrl").

add(Domain, #uce_role{id=Id} = Role) ->
    case exists(Domain, Id) of
        true ->
            {error, conflict};
        false ->
            apply(db:get(?MODULE, Domain), add, [Domain, Role])
    end.

update(Domain, #uce_role{id=Id} = Role) ->
    case exists(Domain, Id) of
        true ->
            apply(db:get(?MODULE, Domain), update, [Domain, Role]);
        false ->
            {error, not_found}
    end.

delete(Domain, Id) ->
    case exists(Domain, Id) of
        true ->
            apply(db:get(?MODULE, Domain), delete, [Domain, Id]);
        false -> {error, not_found}
    end.

get(Domain, Id) ->
    apply(db:get(?MODULE, Domain), get, [Domain, Id]).

exists(Domain, Id) ->
    case ?MODULE:get(Domain, Id) of
        {error, not_found} ->
            false;
        {ok, _} -> true
    end.

acl(Domain, Id) ->
    {ok, Role} = ?MODULE:get(Domain, Id),
    {ok, Role#uce_role.acl}.

add_access(Domain, Id, #uce_access{} = Access) ->
    case ?MODULE:get(Domain, Id) of 
        {ok, Role} -> 
            ?MODULE:get(Domain, Id),
            case uce_access:exists(Access, Role#uce_role.acl) of
                true ->
                    {ok, updated};
                false ->
                    ?MODULE:update(Domain, Role#uce_role{acl=(Role#uce_role.acl ++ [Access])})
            end;
        {error, _Reason} = Error -> Error
    end.

delete_access(Domain, Id, #uce_access{} = Access) ->
    case ?MODULE:get(Domain, Id) of 
        {ok, Role} -> 
            ACL = case uce_access:exists(Access, Role#uce_role.acl) of
                      true ->
                          uce_access:delete(Access, Role#uce_role.acl);
                      false ->
                          Role#uce_role.acl
                  end,
            ?MODULE:update(Domain, Role#uce_role{acl=ACL});
        {error, _Reason} = Error -> Error
    end.
