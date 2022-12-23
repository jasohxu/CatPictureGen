% Client file for catpics.erl (See catpics.erl for further explanation)

-module(catclient).
-export([start/0,setCaption/1,make/0]).
-import(erlang,[send/2]).
-import(catpics,[start_server/0]).

start() ->
    start_server().

setCaption(Caption) ->
    send(catmaker,{self(),msg,Caption}),
    receive
        {catmaker,done} ->
            io:format("Caption added.~n")
        after 10000 ->
            io:format("Error. No response from image server.~n")
        end.   

make() ->
    send(catmaker,{self(),make}),
    receive
        {catmaker,Zipped,Ratio,UCSize} ->
            io:format("File stored as ~p with uncompressed size of ~p bytes.~n(Compression Ratio: ~p)~n",[Zipped,UCSize,Ratio])
        after 10000 ->
            io:format("Error. No response from image server.~n")
        end.