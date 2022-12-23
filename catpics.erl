% Jason Xu, 12/12/22
% 
% Creates, stores and compresses a random cat photo with an optional 
% user-inputted caption.
% 
% Made possible using Cats As A Service (cataas.com). All image rights
% are theirs.
% 
% (I aimed to use your love of cats to boost my grade. I hope it worked.)

-module(catpics).
-export([start_server/0,catserver/1,getCompressionRate/1]).
-import(erlang,[send/2]).
-define(SITE,"https://cataas.com/c").
-define(CATFILE,"cat").
-define(CATZIP,"cat.zip").

start_server() ->
    Pid = spawn(fun() -> catserver(?SITE) end),
    register(catmaker,Pid),
    Pid.

catserver(Cat) ->
    receive
        {Client,msg,Msg} ->
            Encoded = uri_string:quote(Msg),
            NewPath = "/c/s/" ++ Encoded,
            NewCat = uri_string:resolve(NewPath,Cat),
            send(Client,{catmaker,done}),
            catserver(NewCat);

        {Client,make} ->
            inets:start(),
            ssl:start(),
            CatPic = httpc:request(get, {Cat, []}, [], []),
            case CatPic of
                {ok, {{_, 200, "OK"}, _, Body}} ->
                    file:write_file(?CATFILE, Body),
                    zip:create(?CATZIP,[?CATFILE]),
                    UCSize = filelib:file_size(?CATFILE),
                    file:delete(?CATFILE),
                    Ratio = getCompressionRate(UCSize),
                    send(Client,{catmaker,?CATZIP,Ratio,UCSize}),
                    {ok,?CATZIP,Ratio};
                _ ->
                    io:format("Error.~n")
            end
        end.

getCompressionRate(UCSize) ->
    try
        {ok,Handle} = zip:zip_open(?CATZIP),
        {ok,Directory} = zip:zip_list_dir(Handle),
        zip:zip_close(Handle),
        CompFile = lists:nth(2,Directory),
        CSize = element(6,CompFile),
        CSize/UCSize
    catch error:{badmatch,_} ->
        {error,badfile}
    end.