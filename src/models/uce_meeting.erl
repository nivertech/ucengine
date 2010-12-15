-module(uce_meeting).

-author('victor.goya@af83.com').

-export([add/1, delete/1, update/1, get/1, list/2, join/2, leave/2, roster/1, exists/1]).

-include("uce.hrl").
-include("uce_models.hrl").

add(#uce_meeting{} = Meeting) ->
    case ?MODULE:exists(Meeting#uce_meeting.id) of
	true ->
	    {error, conflict};
	false ->
	    [Org, _] = Meeting#uce_meeting.id,
	    case uce_org:exists(Org) of
		false ->
		    {error, not_found};
		true ->
		    ?DB_MODULE:add(Meeting)
	    end
    end.

delete(Id) ->
    case ?MODULE:exists(Id) of
	false ->
	    {error, not_found};
	true ->
	    ?DB_MODULE:delete(Id)
    end.


get(Id) ->
    ?DB_MODULE:get(Id).

update(#uce_meeting{} = Meeting) ->
    case ?MODULE:get(Meeting#uce_meeting.id) of
	{error, Reason} ->
	    {error, Reason};
	{ok, _} ->
	    ?DB_MODULE:update(Meeting)
    end.

list(Org, Status) ->
    case uce_org:exists(Org) of
	false ->
	    {error, not_found};
	true ->
	    Now = utils:now(),
	    case ?DB_MODULE:list(Org) of
		{error, Reason} ->
		    {error, Reason};
		{ok, Meetings} ->
		    if
			Status == "all"; Status=="upcoming"; Status=="opened"; Status=="closed" ->
			    FilteredMeetings =
				lists:filter(fun(#uce_meeting{start_date=Start, end_date=End}) ->
						     case Status of
							 "all" ->
							     true;
							 "upcoming" ->
							     Now < Start;
							 "opened" ->
							     case Now >= Start of
								 true ->
								     if					     
									 End == ?NEVER_ENDING_MEETING -> true;
									 Now =< End -> true;
									 true -> false
								     end;
								 false ->
								     false
							     end;
							 "closed" ->
							     if
								 End == ?NEVER_ENDING_MEETING -> false;
								 Now >= End -> true;
								 true -> false
							     end;
							 _ ->
							     false
						     end
					     end,
					     Meetings),
			    {ok, FilteredMeetings};
			true ->
			    {error, bad_parameters}
		    end
	    end
    end.

exists(Id) ->
    case ?MODULE:get(Id) of
	{error, _} ->
	    false;
	_ ->
	    true
    end.

join(Id, Uid) when is_list(Uid) ->
    case uce_user:exists(Uid) of
	false ->
	    {error, not_found};
	true ->
	    case ?MODULE:get(Id) of
		{error, Reason} ->
		    {error, Reason};
		{ok, #uce_meeting{} = Meeting} ->
		    case lists:member(Uid, Meeting#uce_meeting.roster) of
			false ->
			    Roster = Meeting#uce_meeting.roster ++ [Uid],
			    ?MODULE:update(Meeting#uce_meeting{roster=Roster});
			true ->
			    {ok, updated}
		    end
	    end
    end.	

leave(Id, Uid) when is_list(Uid) ->
    case uce_user:exists(Uid) of
	false ->
	    {error, not_found};
	true ->
	    case ?MODULE:get(Id) of
		{error, Reason} ->
		    {error, Reason};
		{ok, #uce_meeting{} = Meeting} ->
		    case lists:member(Uid, Meeting#uce_meeting.roster) of
			false ->
			    {error, not_found};
			true ->
			    Roster = lists:subtract(Meeting#uce_meeting.roster, [Uid]),
			    ?MODULE:update(Meeting#uce_meeting{roster=Roster})
		    end
	    end
    end.

roster(Id) ->
    case ?MODULE:get(Id) of
	{error, Reason} ->
	    {error, Reason};
	{ok, #uce_meeting{} = Meeting} ->
	    {ok, Meeting#uce_meeting.roster}
    end.
