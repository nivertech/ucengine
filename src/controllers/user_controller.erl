-module(user_controller).

-export([init/0, add/3, update/3, get/3, list/3, delete/3]).

-include("uce.hrl").

init() ->
    [#uce_route{module="Users",
		method='GET',
		regexp="/user/",
		callbacks=[{presence_controller, check,
			    ["uid", "sid"],
			    [required, required],
			    [string, string]},
			   {?MODULE, list,
			    ["uid"],
			    [required],
			    [string]}]},
     
     #uce_route{module="Users",
		method='PUT',
		regexp="/user/([^/]+)",
		callbacks=[{?MODULE, add,
			    ["auth", "credential", "metadata"],
			    [required, "", []],
			    [string, string, dictionary]}]},
     
     #uce_route{module="Users",
		method='POST',
		regexp="/user/([^/]+)",
		callbacks=[{presence_controller, check,
			    ["uid", "sid"],
			    [required, required],
			    [string, string]},
			   {?MODULE, update,
			    ["uid", "auth", "credential", "metadata"],
			    [required, required, "", []],
			    [string, string, string, dictionary]}]},
     
     #uce_route{module="Users",
		method='GET',
		regexp="/user/([^/]+)",
		callbacks=[{presence_controller, check,
			    ["uid", "sid"],
			    [required, required],
			    [string, string]},
			   {?MODULE, get,
			    ["uid"],
			    [required],
			    [string]}]},
     
     #uce_route{module="Users",
		method='DELETE',
		regexp="/user/([^/]+)",
		callbacks=[{presence_controller, check,
			    ["uid", "sid"],
			    [required, required],
			    [string, string]},
			   {?MODULE, delete,
			    ["uid"],
				     [required],
			    [string]}]}].

list([], [Uid], _) ->
    case uce_acl:check(Uid, "user", "list", ["", ""], []) of
	true ->
	    case uce_user:list() of
		Users when is_list(Users) ->
		    JSONUsers = [ user_helpers:to_json(User) || User <- Users],
		    json_helpers:json({array, JSONUsers});
		Error ->
		    Error
	    end;
	false ->
	    {error, unauthorized}
    end.

add([Uid], [Auth, Credential, Metadata], _) ->
    case uce_user:add(#uce_user{uid=Uid, auth=Auth, credential=Credential, metadata=Metadata}) of
	ok ->
	    uce_event:add(#uce_event{from=Uid,
				     type="internal.user.add",
				     metadata=Metadata}),
	    json_helpers:created();
	Error ->
	    Error
    end.

update([To], [Uid, Auth, Credential, Metadata], _) ->
    case uce_acl:check(Uid, "update", "user", ["", ""], [{"user", To},
							 {"auth", Auth}]) of
	true ->
	    case uce_user:update(To, Auth, Credential, Metadata) of
		ok ->
		    uce_event:add(#uce_event{from=To,
					     type="internal.user.update",
					     metadata=Metadata}),
		    json_helpers:ok();
		Error ->
		    Error
	    end;
	false ->
	    {error, unauthorized}
    end.

get([To], [Uid], _) ->
    case uce_acl:check(Uid, "get", "user", ["", ""], [{"user", To}]) of
	true ->
	    case uce_user:get(To) of
		User when is_record(User, uce_user) ->
		    UserJson = {struct, [{uid, User#uce_user.uid},
					 {auth, User#uce_user.auth},
					 {metadata, {struct, User#uce_user.metadata}}]},
		    json_helpers:json(UserJson);
		Error ->
		    Error
	    end;
	false ->
	    {error, unauthorized}
    end.

delete([To], [Uid], _) ->
    case uce_acl:check(Uid, "delete", "user", ["", ""], [{"user", To}]) of
	true ->
	    case uce_user:delete(To) of
		ok ->
		    json_helpers:ok();
		Error ->
		    Error
	    end;
	false ->
	    {error, unauthorized}
    end.
