%%%-------------------------------------------------------------------
%%% @author maayan
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. Jun 2020 12:01 AM
%%%-------------------------------------------------------------------
-module(cars).
-author("maayan").

-behaviour(gen_statem).

%% API
-export([start_link/0]).

%% gen_statem callbacks
-export([
  init/1,
  format_status/2,
  state_name/3,
  handle_event/4,
  terminate/3,
  code_change/4,
  callback_mode/0
]).

%%Events
-export([close_to_car/2,close_to_junc/3,accident/1,slow_down/1,speed_up/1,turn/2,go_straight/1,bypass/1,far_from_car/1]).
-export([max_speed/1,finish_turn/1,green_light/2,f_bypass/1,f_turn/1,keepStraight/1,stop/1]).

%% States
-export([drive_straight/3,idle/3,slowing/3,accelerating/3,turning/3,turn_after_stop/3,stopping/3,bypassing/3,start/3]).


-define(SERVER, ?MODULE).

-record(cars_state, {bypassCounter = 0,turnCounter = 0,nextTurnDir,nextTurnRoad, speed }).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Creates a gen_statem process which calls Module:init/1 to
%% initialize. To ensure a synchronized start-up procedure, this
%% function does not return until Module:init/1 has returned.
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link() ->
  gen_statem:start_link({local, ?SERVER}, ?MODULE, [], []).
start(Name,Type,Start) ->

  gen_statem:start({local, Name}, ?MODULE, [Start,Type], []).

%%%===================================================================
%%% gen_statem callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Whenever a gen_statem is started using gen_statem:start/[3,4] or
%% gen_statem:start_link/[3,4], this function is called by the new
%% process to initialize.
%%
%% @spec init(Args) -> {CallbackMode, StateName, State} |
%%                     {CallbackMode, StateName, State, Actions} |
%%                     ignore |
%%                     {stop, StopReason}
%% @end
%%--------------------------------------------------------------------
init([Start,Type]) ->
  %%----------------process_flag??
  ets:insert(cars,{self(),Start}),
  SensorPid = spawn(sensors,close_to_car,[self(),ets:first(cars)]),
  SensorPid2= spawn(sensors,close_to_junction,[self(),ets:first(junction)]),
  put(speed ,Type),

  {ok,drive_straight, #cars_state{speed = Type},Type}.


%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_statem when it needs to find out
%% the callback mode of the callback module.
%%
%% @spec callback_mode() -> atom().
%% @end
%%--------------------------------------------------------------------
callback_mode() ->
  state_functions.

%% Events
close_to_car(Pid,OtherCar) -> gen_statem:cast(Pid,{ctc,Pid,OtherCar}).
close_to_junc(Pid,LightState,{R,J}) -> gen_statem:cast(Pid,{ctj,Pid,LightState,{R,J}}).
accident(Pid) -> gen_statem:cast(Pid,{acc,Pid}).
slow_down(Pid) -> gen_statem:cast(Pid,{slow,Pid}).
speed_up(Pid) -> gen_statem:cast(Pid,{speed,Pid}).
turn(Pid,{Dir, Road}) ->gen_statem:cast(Pid,{turn,Pid,{Dir, Road}}).
f_turn(Pid) -> gen_statem:cast(Pid,{fturn,Pid}).
%turn(Pid,left) -> gen_statem:cast(Pid,{turnL,Pid});
%turn(Pid,right) -> gen_statem:cast(Pid,{turnR,Pid}).
go_straight(Pid) -> gen_statem:cast(Pid,{str8,Pid}).
bypass(Pid) -> gen_statem:cast(Pid,{byp,Pid}).
f_bypass(Pid) -> gen_statem:cast(Pid,{fByp,Pid}).
far_from_car(Pid) -> gen_statem:cast(Pid,{far,Pid}).
max_speed(Pid) -> gen_statem:cast(Pid,{maxS,Pid}).
finish_turn(Pid) -> gen_statem:cast(Pid,{fTurn,Pid}).
green_light(Pid,straight) -> gen_statem:cast(Pid,{greenS,Pid});
green_light(Pid,left) -> gen_statem:cast(Pid,{greenL,Pid});
green_light(Pid,right) -> gen_statem:cast(Pid,{greenR,Pid}).
keepStraight(Pid) -> gen_statem:cast(Pid,{kst,Pid}).
stop(Pid) -> gen_statem:cast(Pid,{stop,Pid}).



%%--------------------------------------------------------------------
%% @private
%% @doc
%% Called (1) whenever sys:get_status/1,2 is called by gen_statem or
%% (2) when gen_statem terminates abnormally.
%% This callback is optional.
%%
%% @spec format_status(Opt, [PDict, StateName, State]) -> term()
%% @end
%%--------------------------------------------------------------------
format_status(_Opt, [_PDict, _StateName, _State]) ->
  Status = some_term,
  Status.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% There should be one instance of this function for each possible
%% state name.  If callback_mode is statefunctions, one of these
%% functions is called when gen_statem receives and event from
%% call/2, cast/2, or as a normal process message.
%%
%% @spec state_name(Event, From, State) ->
%%                   {next_state, NextStateName, NextState} |
%%                   {next_state, NextStateName, NextState, Actions} |
%%                   {stop, Reason, NewState} |
%%    				 stop |
%%                   {stop, Reason :: term()} |
%%                   {stop, Reason :: term(), NewData :: data()} |
%%                   {stop_and_reply, Reason, Replies} |
%%                   {stop_and_reply, Reason, Replies, NewState} |
%%                   {keep_state, NewData :: data()} |
%%                   {keep_state, NewState, Actions} |
%%                   keep_state_and_data |
%%                   {keep_state_and_data, Actions}
%% @end
%%--------------------------------------------------------------------
state_name(_EventType, _EventContent, State) ->
  NextStateName = next_state,
  {next_state, NextStateName, State}.


drive_straight(cast,{ctc,Pid,OtherCar},State = #cars_state{}) ->
  % TODO: send message to server
  server:s_close_to_car(Pid,OtherCar),
  NextStateName = idle,
  {next_state, NextStateName, State,get(speed)};
drive_straight(cast,{ctj,Pid,T,{R,J}},State = #cars_state{}) ->
  % TODO: slow down, send message to server and stop\keep going according to traffic light

  server:s_light(Pid,{R,J}),

  NextStateName = idle,
  {next_state, NextStateName, State,get(speed)};
drive_straight(cast,{acc,Pid},State = #cars_state{}) ->
  % TODO: stop and send message to server
  NextStateName = idle,
  {next_state, NextStateName, State};
drive_straight(cast,{kst,Pid},State = #cars_state{}) ->
  % TODO: keep straight
  [{_,[{X,Y},D,R,Type,Turn]}] = ets:lookup(cars,Pid),
  if
    D == up -> ets:update_element(cars,Pid,[{2,[{X,Y -1 },D,R,Type,Turn]}]) ;
    D == down ->ets:update_element(cars,Pid,[{2,[{X,Y +1 },D,R,Type,Turn]}]) ;
    D == right ->ets:update_element(cars,Pid,[{2,[{X + 1,Y },D,R,Type,Turn]}]) ;
    true -> ets:update_element(cars,Pid,[{2,[{X - 1,Y},D,R,Type,Turn]}])
  end,
  NextStateName = drive_straight,
  {next_state, NextStateName, State,get(speed)};
drive_straight(timeout,20,State = #cars_state{}) ->
  % TODO: keep straight
  [{P,[{X,Y},D,R,Type,Turn]}] = ets:lookup(cars,self()),
  if
    D == up -> ets:update_element(cars,P,[{2,[{X,Y -1 },D,R,Type,Turn]}]) ;
    D == down ->ets:update_element(cars,P,[{2,[{X,Y +1 },D,R,Type,Turn]}]) ;
    D == right ->ets:update_element(cars,P,[{2,[{X + 1,Y },D,R,Type,Turn]}]) ;
    true -> ets:update_element(cars,P,[{2,[{X - 1,Y},D,R,Type,Turn]}])
  end,
  NextStateName = drive_straight,
  {next_state, NextStateName, State,20};
drive_straight(timeout,10,State = #cars_state{}) ->
  % TODO: keep straight
  [{P,[{X,Y},D,R,Type,Turn]}] = ets:lookup(cars,self()),
  if
    D == up -> ets:update_element(cars,P,[{2,[{X,Y -1 },D,R,Type,Turn]}]) ;
    D == down ->ets:update_element(cars,P,[{2,[{X,Y +1 },D,R,Type,Turn]}]) ;
    D == right ->ets:update_element(cars,P,[{2,[{X + 1,Y },D,R,Type,Turn]}]) ;
    true -> ets:update_element(cars,P,[{2,[{X - 1,Y},D,R,Type,Turn]}])
  end,
  NextStateName = drive_straight,
  {next_state, NextStateName, State,10};
drive_straight(cast,{stop,Pid},State = #cars_state{}) ->
  % TODO: stop
  NextStateName = stopping,
  {next_state, NextStateName, State}.

%drive_straight(cast,{turn,Pid,{Dir, Road}},State = #cars_state{}) ->
%io:format("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"),
%  [{_,[{_,_},D,_]}] = ets:lookup(cars,self()),
% case D == Dir of
% true ->NextStateName1 = drive_straight,
%    {next_state, NextStateName1, State,get(speed)};
%  _ ->  NextStateName = turning,
%     {next_state, NextStateName, #cars_state{nextTurn = [Dir, Road]},get(speed)}

%  end.






idle(cast,{slow,Pid},State = #cars_state{}) ->
  % TODO: slow down
  NextStateName = slowing,
  {next_state, NextStateName, State};
idle(cast,{speed,Pid},State = #cars_state{}) ->
  % TODO: accelerate
  NextStateName = accelerating,
  {next_state, NextStateName, State};
idle(cast,{turnL,Pid},State = #cars_state{}) ->
  % TODO: start turning left
  NextStateName = turning,
  {next_state, NextStateName, State};
idle(cast,{turnR,Pid},State = #cars_state{}) ->
  % TODO: start turning right
  NextStateName = turning,
  {next_state, NextStateName, State};
idle(cast,{str8,Pid},State = #cars_state{}) ->
  % TODO: go straight
  NextStateName = accelerating,
  {next_state, NextStateName, State};
idle(cast,{byp,Pid},State = #cars_state{}) ->
  % TODO: start bypassing
  NextStateName = bypassing,
  {next_state, NextStateName, State,get(speed)};
idle(cast,{acc,Pid},State = #cars_state{}) ->
  % TODO: stop and send message to server
  NextStateName = idle,
  {next_state, NextStateName, State};
idle(timeout,20,State = #cars_state{}) ->
  [{P,[{X,Y},D,R,Type,Turn]}] = ets:lookup(cars,self()),
  if
    D == up -> ets:update_element(cars,P,[{2,[{X,Y -1 },D,R,Type,Turn]}]) ;
    D == down ->ets:update_element(cars,P,[{2,[{X,Y +1 },D,R,Type,Turn]}]) ;
    D == right ->ets:update_element(cars,P,[{2,[{X + 1,Y },D,R,Type,Turn]}]) ;
    true -> ets:update_element(cars,P,[{2,[{X - 1,Y},D,R,Type,Turn]}])
  end,
  NextStateName = idle,
  {next_state, NextStateName, State,20};
idle(timeout,10,State = #cars_state{}) ->
  [{P,[{X,Y},D,R,Type,Turn]}] = ets:lookup(cars,self()),
  if
    D == up -> ets:update_element(cars,P,[{2,[{X,Y -1 },D,R,Type,Turn]}]) ;
    D == down ->ets:update_element(cars,P,[{2,[{X,Y +1 },D,R,Type,Turn]}]) ;
    D == right ->ets:update_element(cars,P,[{2,[{X + 1,Y },D,R,Type,Turn]}]) ;
    true -> ets:update_element(cars,P,[{2,[{X - 1,Y},D,R,Type,Turn]}])
  end,
  NextStateName = idle,
  {next_state, NextStateName, State,10};

idle(cast,{turn,Pid,{Dir, Road}},State = #cars_state{}) ->
  [{_,[{_,_},D,_,_,_]}] = ets:lookup(cars,self()),
  case D == Dir of
    true ->NextStateName1 = drive_straight,
      {next_state, NextStateName1, State,get(speed)};
    _ ->  NextStateName = turning,
      {next_state, NextStateName, #cars_state{nextTurnDir = Dir,nextTurnRoad = Road},get(speed)}

  end;



idle(cast,_,State = #cars_state{}) ->
  NextStateName = idle,
  {next_state, NextStateName, State,get(speed)}.
slowing(cast,{ctc,Pid,OtherCar},State = #cars_state{}) ->
  % TODO: send message to server
  NextStateName = idle,
  {next_state, NextStateName, State};
slowing(cast,{ctj,Pid},State = #cars_state{}) ->
  % TODO: slow down, send message to server and stop\keep going according to traffic light
  NextStateName = idle,
  {next_state, NextStateName, State};
slowing(cast,{far,Pid},State = #cars_state{}) ->
  % TODO: start accelerating
  NextStateName = accelerating,
  {next_state, NextStateName, State};
slowing(cast,{acc,Pid},State = #cars_state{}) ->
  % TODO: stop and send message to server
  NextStateName = idle,
  {next_state, NextStateName, State}.
accelerating(cast,{ctc,Pid,OtherCar},State = #cars_state{}) ->
  % TODO: stop accelerating and send message to server
  NextStateName = idle,
  {next_state, NextStateName, State};
accelerating(cast,{ctj,Pid},State = #cars_state{}) ->
  % TODO: slow down, send message to server and stop\keep going according to traffic light
  NextStateName = idle,
  {next_state, NextStateName, State};
accelerating(cast,{maxS},State = #cars_state{}) ->
  % TODO: stop accelerating
  NextStateName = drive_straight,
  {next_state, NextStateName, State};
accelerating(cast,{acc,Pid},State = #cars_state{}) ->
  % TODO: stop and send message to server
  NextStateName = idle,
  {next_state, NextStateName, State}.

turning(cast,{fturn,_},State = #cars_state{}) ->
  NextStateName = drive_straight,
  {next_state, NextStateName, #cars_state{turnCounter = 0},get(speed)};

turning(timeout,10,State = #cars_state{}) ->
  [{P,[{X,Y},D,R,Type,Turn]}] = ets:lookup(cars,self()), C =State#cars_state.turnCounter,
  %M = State#cars_state.nextTurn,
  %io:format("~p~n",[M]),

  Dir = State#cars_state.nextTurnDir,
  Road = State#cars_state.nextTurnRoad,
  %io:format("~p~n ~p~n",[Dir,Road]),

  if
    D == up, Dir == left, C =< 130 -> ets:update_element(cars,P,[{2,[{X,Y -1 },D,R,Type,left]}]) ;
    D == up, Dir == right, C =< 80 ->ets:update_element(cars,P,[{2,[{X,Y -1 },D,R,Type,right]}]) ;

    D == down, Dir == left, C =< 130 ->ets:update_element(cars,P,[{2,[{X,Y +1 },D,R,Type,left]}]) ;
    D == down, Dir == right, C =< 80 -> ets:update_element(cars,P,[{2,[{X,Y +1 },D,R,Type,right]}]);

    D == right, Dir == up, C =< 130 ->ets:update_element(cars,P,[{2,[{X + 1,Y },D,R,Type,left]}]) ;
    D == right, Dir == down, C =< 80 -> ets:update_element(cars,P,[{2,[{X + 1,Y },D,R,Type,right]}]) ;

    D == left, Dir == up, C =< 80 -> ets:update_element(cars,P,[{2,[{X - 1,Y },D,R,Type,right]}]) ;
    D == left, Dir == down, C =< 130 -> ets:update_element(cars,P,[{2,[{X - 1,Y },D,R,Type,left]}]) ;


    true ->   ets:update_element(cars,P,[{2,[{X ,Y },Dir,Road,Type,st]}]), server:car_finish_turn(self())
  end,
  NextStateName = turning,
  {next_state, NextStateName, #cars_state{turnCounter = C + 1,nextTurnDir = Dir , nextTurnRoad = Road },10};

turning(timeout,20,State = #cars_state{}) ->
  [{P,[{X,Y},D,_,Type,Turn]}] = ets:lookup(cars,self()), C =State#cars_state.turnCounter,

  Dir = State#cars_state.nextTurnDir,
  Road = State#cars_state.nextTurnRoad,
  io:format("~p~n ~p~n",[Dir,Road]),


  if
    D == up, Dir == left, C =< 130 -> ets:update_element(cars,P,[{2,[{X,Y -1 },Dir,Road,Type,Turn]}]) ;
    D == up, Dir == right, C =< 80 ->ets:update_element(cars,P,[{2,[{X,Y -1 },Dir,Road,Type,Turn]}]) ;

    D == down, Dir == left, C =< 130 ->ets:update_element(cars,P,[{2,[{X,Y +1 },Dir,Road,Type,Turn]}]) ;
    D == down, Dir == right, C =< 80 -> ets:update_element(cars,P,[{2,[{X,Y +1 },Dir,Road,Type,Turn]}]);

    D == right, Dir == up, C =< 130 ->ets:update_element(cars,P,[{2,[{X + 1,Y },Dir,Road,Type,Turn]}]) ;
    D == right, Dir == down, C =< 80 -> ets:update_element(cars,P,[{2,[{X + 1,Y },Dir,Road,Type,Turn]}]) ;

    D == left, Dir == up, C =< 80 -> ets:update_element(cars,P,[{2,[{X - 1,Y },Dir,Road,Type,Turn]}]) ;
    D == left, Dir == down, C =< 130 -> ets:update_element(cars,P,[{2,[{X - 1,Y },Dir,Road,Type,Turn]}]) ;


    true ->server:car_finish_turn(self())
  end,
  NextStateName = turning,
  {next_state, NextStateName, #cars_state{turnCounter = C + 1},20};




turning(cast,{ctc,Pid,OtherCar},State = #cars_state{}) ->
  % TODO: send message to server
  NextStateName = idle,
  {next_state, NextStateName, State};
turning(cast,{fTurn,Pid},State = #cars_state{}) ->
  % TODO: start accelerating
  NextStateName = accelerating,
  {next_state, NextStateName, State};
turning(cast,{acc,Pid},State = #cars_state{}) ->
  % TODO: stop and send message to server
  NextStateName = idle,
  {next_state, NextStateName, State}.
turn_after_stop(cast,{acc,Pid},State = #cars_state{}) ->
  % TODO: send message to server
  NextStateName = idle,
  {next_state, NextStateName, State};
turn_after_stop(cast,{fTurn,Pid},State = #cars_state{}) ->
  % TODO: start accelerating
  NextStateName = accelerating,
  {next_state, NextStateName, State};
turn_after_stop(cast,{acc,Pid},State = #cars_state{}) ->
  % TODO: stop and send message to server
  NextStateName = idle,
  {next_state, NextStateName, State}.
stopping(cast,{greenS,Pid},State = #cars_state{}) ->
  % TODO: accelerate
  NextStateName = accelerating,
  {next_state, NextStateName, State};
stopping(cast,{greenL,Pid},State = #cars_state{}) ->
  % TODO: start accelerating and turning left
  NextStateName = turn_after_stop,
  {next_state, NextStateName, State};
stopping(cast,{greenR,Pid},State = #cars_state{}) ->
  % TODO: start accelerating and turning right
  NextStateName = turn_after_stop,
  {next_state, NextStateName, State};
stopping(cast,{far,Pid},State = #cars_state{}) ->
  % TODO: send message to server
  NextStateName = idle,
  {next_state, NextStateName, State};
stopping(cast,{acc,Pid},State = #cars_state{}) ->
  % TODO: stop and send message to server
  NextStateName = idle,
  {next_state, NextStateName, State}.
bypassing(cast,{ctc,Pid,OtherCar},State = #cars_state{}) ->
  % TODO: slow down and send message to server
  NextStateName = idle,
  {next_state, NextStateName, State};
bypassing(cast,{ctj,Pid},State = #cars_state{}) ->
  % TODO: slow down, send message to server and stop\keep going according to traffic light
  NextStateName = idle,
  {next_state, NextStateName, State};
bypassing(cast,{fByp,_},State = #cars_state{}) ->
  % TODO: return to right lane and drive straight

  NextStateName = drive_straight,
  {next_state, NextStateName, #cars_state{bypassCounter = 0},get(speed)};
bypassing(cast,{acc,Pid},State = #cars_state{}) ->
  % TODO: stop and send message to server
  NextStateName = idle,
  {next_state, NextStateName, State};




bypassing(timeout,20,State = #cars_state{}) ->
  [{P,[{X,Y},D,R,Type,Turn]}] = ets:lookup(cars,self()), C =State#cars_state.bypassCounter,
  if
    D == up, C =< 26 -> ets:update_element(cars,P,[{2,[{X - 1,Y -1 },D,R,Type,Turn]}]) ;
    D == down, C =< 26 ->ets:update_element(cars,P,[{2,[{X + 1,Y +1 },D,R,Type,Turn]}]);
    D == right, C =< 26 ->ets:update_element(cars,P,[{2,[{X + 1,Y - 1 },D,R,Type,Turn]}]);
    D == left, C =< 26 ->ets:update_element(cars,P,[{2,[{X - 1,Y + 1},D,R,Type,Turn]}]);


    D == up, C > 26, C =< 300 -> ets:update_element(cars,P,[{2,[{X ,Y -1 },D,R,Type,Turn]}]) ;
    D == down, C > 26,C =< 300 ->ets:update_element(cars,P,[{2,[{X,Y +1 },D,R,Type,Turn]}]);
    D == right, C > 26,C =< 300 ->ets:update_element(cars,P,[{2,[{X + 1,Y},D,R,Type,Turn]}]);
    D == left, C > 26,C =< 300 ->ets:update_element(cars,P,[{2,[{X - 1,Y},D,R,Type,Turn]}]);

    D == up, C > 300  ,C =< 326 -> ets:update_element(cars,P,[{2,[{X + 1 ,Y -1 },D,R,Type,Turn]}]) ;
    D == down, C > 300,C =< 326 ->ets:update_element(cars,P,[{2,[{X - 1,Y +1 },D,R,Type,Turn]}]);
    D == right, C > 300,C =< 326 ->ets:update_element(cars,P,[{2,[{X + 1,Y + 1},D,R,Type,Turn]}]);
    D == left, C > 300,C =< 326 ->ets:update_element(cars,P,[{2,[{X - 1,Y - 1},D,R,Type,Turn]}]);


    true -> server:car_finish_bypass(self())
  end,
  NextStateName = bypassing,
  {next_state, NextStateName, #cars_state{bypassCounter = C + 1},20};


bypassing(timeout,10,State = #cars_state{}) ->
  [{P,[{X,Y},D,R,Type,Turn]}] = ets:lookup(cars,self()), C =State#cars_state.bypassCounter,
  if
    D == up, C =< 26 -> ets:update_element(cars,P,[{2,[{X - 1,Y -1 },D,R,Type,Turn]}]) ;
    D == down, C =< 26 ->ets:update_element(cars,P,[{2,[{X + 1,Y +1 },D,R,Type,Turn]}]);
    D == right, C =< 26 ->ets:update_element(cars,P,[{2,[{X + 1,Y - 1 },D,R,Type,Turn]}]);
    D == left, C =< 26 ->ets:update_element(cars,P,[{2,[{X - 1,Y + 1},D,R,Type,Turn]}]);


    D == up, C > 26, C =< 300 -> ets:update_element(cars,P,[{2,[{X ,Y -1 },D,R,Type,Turn]}]) ;
    D == down, C > 26,C =< 300 ->ets:update_element(cars,P,[{2,[{X,Y +1 },D,R,Type,Turn]}]);
    D == right, C > 26,C =< 300 ->ets:update_element(cars,P,[{2,[{X + 1,Y},D,R,Type,Turn]}]);
    D == left, C > 26,C =< 300 ->ets:update_element(cars,P,[{2,[{X - 1,Y},D,R,Type,Turn]}]);

    D == up, C > 300  ,C =< 326 -> ets:update_element(cars,P,[{2,[{X + 1 ,Y -1 },D,R,Type,Turn]}]) ;
    D == down, C > 300,C =< 326 ->ets:update_element(cars,P,[{2,[{X - 1,Y +1 },D,R,Type,Turn]}]);
    D == right, C > 300,C =< 326 ->ets:update_element(cars,P,[{2,[{X + 1,Y + 1},D,R,Type,Turn]}]);
    D == left, C > 300,C =< 326 ->ets:update_element(cars,P,[{2,[{X - 1,Y - 1},D,R,Type,Turn]}]);


    true -> server:car_finish_bypass(self())
  end,
  NextStateName = bypassing,
  {next_state, NextStateName, #cars_state{bypassCounter = C + 1},10}.


%%--------------------------------------------------------------------
%% @private
%% @doc
%%
%% If callback_mode is handle_event_function, then whenever a
%% gen_statem receives an event from call/2, cast/2, or as a normal
%% process message, this function is called.
%%
%% @spec handle_event(Event, StateName, State) ->
%%                   {next_state, NextStateName, NextState} |
%%                   {next_state, NextStateName, NextState, Actions} |
%%                   {stop, Reason, NewState} |
%%    				 stop |
%%                   {stop, Reason :: term()} |
%%                   {stop, Reason :: term(), NewData :: data()} |
%%                   {stop_and_reply, Reason, Replies} |
%%                   {stop_and_reply, Reason, Replies, NewState} |
%%                   {keep_state, NewData :: data()} |
%%                   {keep_state, NewState, Actions} |
%%                   keep_state_and_data |
%%                   {keep_state_and_data, Actions}
%% @end
%%--------------------------------------------------------------------
handle_event(_EventType, _EventContent, _StateName, State) ->
  NextStateName = the_next_state_name,
  {next_state, NextStateName, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_statem when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_statem terminates with
%% Reason. The return value is ignored.
%%
%% @spec terminate(Reason, StateName, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _StateName, _State) ->
  ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, StateName, State, Extra) ->
%%                   {ok, StateName, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, StateName, State, _Extra) ->
  {ok, StateName, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
