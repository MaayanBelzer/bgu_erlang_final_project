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
-export([start_link/0,start/5,start/7]).

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
-export([close_to_car/2,close_to_junc/4,accident/2,slow_down/1,speed_up/1,turn/2,go_straight/1,bypass/1,far_from_car/1]).
-export([max_speed/1,finish_turn/1,green_light/2,f_bypass/1,f_turn/1,keepStraight/1,stop/2,kill/1,add_sensor/3,switch_comp/3]).

%% States
-export([drive_straight/3,idle/3,turning/3,stopping/3,bypassing/3,send_msg/2,first_state/3]).


-define(SERVER, ?MODULE).

-record(cars_state, {bypassCounter = 0,turnCounter = 0,nextTurnDir  ,nextTurnRoad, speed,lightPid,sensor1,sensor2,monitor}).

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
start(Name,CarMonitor,Type,Start,PC) ->
  gen_statem:start({local, Name}, ?MODULE, [Name,CarMonitor,Start,Type,PC], []).
start(Name,CarMonitor,Type,Start,Location,Con,PC) -> gen_statem:start({local, Name}, ?MODULE, [Name,CarMonitor,Start,Type,Location,Con,PC], []).


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
init([Name,CarMonitor,Start,Type,PC]) ->
  put(name,Name),
  put(carMon,CarMonitor),
  put(start,Start),
  put(speed ,Type),

  ets:insert(cars,{self(),Start,Name,Start,Type,nal,PC}),
  CarMonitor! {add_to_monitor,self()},
%  spawn_link(sensors,close_to_car,[self(),ets:first(cars)]),
%  spawn_link(sensors,close_to_junction,[self(),ets:first(junction)]),

%  spawn_link(sensors,outOfRange,[self()]),
%  SensorPid = spawn(sensors,close_to_car,[self(),ets:first(cars)]),
%  SensorPid2= spawn(sensors,close_to_junction,[self(),ets:first(junction)]),
%put(sensor1 ,SensorPid),put(sensor2 ,SensorPid2),

%  {ok,drive_straight, #cars_state{speed = Type },Type}.
  {ok,first_state, #cars_state{speed = Type,monitor = CarMonitor},5};

init([Name,CarMonitor,Start,Type,Location,Con,PC]) ->
  io:format("WWWWWWWWWWWWWWWWWWWWWWWWWWWWWW~n~p~n~p~n~p~n~p~n~p~n~p~n",[Name,CarMonitor,Start,Type,Location,Con]),
  put(name,Name),
  put(carMon,CarMonitor),
  put(start,Start),
  put(speed ,Type),

  ets:insert(cars,{self(),Location,Name,Start,Type,Con,PC}),
  CarMonitor! {add_to_monitor,self()},

  SensorPid = spawn(sensors,close_to_car,[self(),ets:first(cars)]),
  SensorPid2 = spawn(sensors,close_to_junction,[self(),ets:first(junction)]),
  SensorPid3 = spawn(sensors,outOfRange,[self()]),
  SensorPid4 = spawn(sensors,car_accident,[self(),ets:first(cars)]),
  SensorPid5 = spawn(sensors,car_dev,[self()]),
  ets:insert(sensors,{SensorPid,self()}), ets:insert(sensors,{SensorPid2,self()}),
  ets:insert(sensors,{SensorPid3,self()}), ets:insert(sensors,{SensorPid4,self()}),
  ets:insert(sensors,{SensorPid5,self()}),
  put(sensor1 ,SensorPid), put(sensor2 ,SensorPid2),
  put(sensor3,SensorPid3), put(sensor4,SensorPid4),
  put(sensor5,SensorPid5),
  Monitor = CarMonitor,
  Monitor ! {add_to_monitor,SensorPid}, Monitor ! {add_to_monitor,SensorPid2},
  Monitor ! {add_to_monitor,SensorPid3}, Monitor ! {add_to_monitor,SensorPid4},
  Monitor ! {add_to_monitor,SensorPid5},

  case Con of
    {drive_straight} -> {ok,drive_straight,#cars_state{},Type};
    {idle} ->{ok,idle, #cars_state{},Type} ;
    {turning,C,Dir,Road} ->{ok,turning, #cars_state{turnCounter = C, nextTurnDir = Dir, nextTurnRoad = Road},Type} ;
    {bypassing,C} -> {ok,bypassing, #cars_state{bypassCounter = C},Type}


  end.

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
close_to_car(Pid,OtherCar) -> gen_statem:cast(Pid,{ctc,Pid,OtherCar}).%
close_to_junc(Pid,LightState,{R,J},LP) -> gen_statem:cast(Pid,{ctj,Pid,LightState,{R,J},LP}).
accident(Pid,OtherCar) ->   io:format("ACCIDENT between ~p and ~p ~n",[Pid,OtherCar]),gen_statem:cast(Pid,{acc,Pid,OtherCar}).
slow_down(Pid) -> gen_statem:cast(Pid,{slow,Pid}).%%%%%%%%%%%%%%%%% delete
speed_up(Pid) -> gen_statem:cast(Pid,{speed,Pid}).%%%%%%%%%%%%%%%%% delete
turn(Pid,{Dir, Road}) ->gen_statem:cast(Pid,{turn,Pid,{Dir, Road}}).
f_turn(Pid) -> gen_statem:cast(Pid,{fturn,Pid}).
go_straight(Pid) -> gen_statem:cast(Pid,{str8,Pid}).
bypass(Pid) -> gen_statem:cast(Pid,{byp,Pid}).
f_bypass(Pid) -> gen_statem:cast(Pid,{fByp,Pid}).
far_from_car(Pid) -> gen_statem:cast(Pid,{far,Pid}).
max_speed(Pid) -> gen_statem:cast(Pid,{maxS,Pid}).%%%%%%%%%%%%%%%%% delete
finish_turn(Pid) -> gen_statem:cast(Pid,{fTurn,Pid}).
green_light(Pid,straight) -> gen_statem:cast(Pid,{greenS,Pid});%%%%%%%%%%%%%%%%% delete
green_light(Pid,left) -> gen_statem:cast(Pid,{greenL,Pid});%%%%%%%%%%%%%%%%% delete
green_light(Pid,right) -> gen_statem:cast(Pid,{greenR,Pid}).%%%%%%%%%%%%%%%%% delete
keepStraight(Pid) -> gen_statem:cast(Pid,{kst,Pid}).
stop(Pid,OtherCar) -> gen_statem:cast(Pid,{stop,Pid,OtherCar}).
kill(Pid) ->  gen_statem:cast(Pid,{kill,Pid}).
send_msg(Pid,{From,Msg}) -> gen_statem:cast(Pid,{send,Pid,From,Msg}).
add_sensor(Pid,Sensor,Type) -> gen_statem:cast(Pid,{add_sensor,Pid,Sensor,Type}).
switch_comp(Pid,From,To) -> gen_statem:cast(Pid,{switch,Pid,From,To}).





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

first_state(timeout,5,State = #cars_state{}) ->
  SensorPid = spawn(sensors,close_to_car,[self(),ets:first(cars)]),
  SensorPid2 = spawn(sensors,close_to_junction,[self(),ets:first(junction)]),
  SensorPid3 = spawn(sensors,outOfRange,[self()]),
  SensorPid4 = spawn(sensors,car_accident,[self(),ets:first(cars)]),
  SensorPid5 = spawn(sensors,car_dev,[self()]),

  ets:insert(sensors,{SensorPid,self()}), ets:insert(sensors,{SensorPid2,self()}),
  ets:insert(sensors,{SensorPid3,self()}), ets:insert(sensors,{SensorPid4,self()}),
  ets:insert(sensors,{SensorPid5,self()}),
  put(sensor1 ,SensorPid), put(sensor2 ,SensorPid2),
  put(sensor3,SensorPid3), put(sensor4,SensorPid4),put(sensor5,SensorPid5),
  Monitor = State#cars_state.monitor,
  Monitor ! {add_to_monitor,SensorPid}, Monitor ! {add_to_monitor,SensorPid2},
  Monitor ! {add_to_monitor,SensorPid3}, Monitor ! {add_to_monitor,SensorPid4},Monitor ! {add_to_monitor,SensorPid5},
  NextStateName = drive_straight,
  {next_state, NextStateName, State,get(speed)}.

drive_straight(cast,{send,Who,From,Msg},State = #cars_state{})->
  {Bool1,To} = check_comms_d(Who,ets:first(comms)),
  case Bool1 of
    true -> communication_tower:receive_message(To,From,Msg);
    _-> {Bool2,To2} = check_close_car(Who,ets:first(cars)),
      case Bool2 of
        true -> cars:send_msg(To2,{From,Msg});

        _-> [{_,[To3]}] = ets:lookup(comms,ets:first(comms)),
          communication_tower:receive_message(To3,From,Msg) % TODO consider computer split

        % io:format("sent message to communication_tower from ~p that on state ~p~n",[self(),sys:get_state(self())])
      end
  end,

  ets:update_element(cars,self(),[{6,{drive_straight}}]) ,%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  NextStateName = drive_straight,
  {next_state, NextStateName, State,get(speed)};



drive_straight(cast,{ctc,Pid,OtherCar},State = #cars_state{}) ->


  {Bool1,To} = check_comms_d(Pid,ets:first(comms)),
  case Bool1 of
    true -> communication_tower:receive_message(To,Pid,{s_close_to_car,OtherCar});
    _-> {Bool2,To2} = check_close_car(Pid,ets:first(cars)),
      case Bool2 of
        true -> cars:send_msg(To2,{Pid,{s_close_to_car,OtherCar}}),io:format("sent message to ~p from ~p~n",[To2,Pid]);
        _->  server:s_close_to_car(null,Pid,OtherCar)
        %io:format("sent message to server from ~p that on state ~p~n",[Pid,sys:get_state(Pid)])
      end
  end,


%  server:s_close_to_car(Pid,OtherCar),
  ets:update_element(cars,self(),[{6,{idle}}]) ,%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  NextStateName = idle, ets:update_element(cars,self(),[{6,{idle}}]) ,
  {next_state, NextStateName, State,get(speed)};

drive_straight(cast,{ctj,Pid,T,{R,J},LP},_) ->
  case T of
    green -> NextStateName = idle,ets:update_element(cars,self(),[{6,{idle}}]) ,

      {Bool1,To} = check_comms_d(Pid,ets:first(comms)),
      case Bool1 of
        true -> communication_tower:receive_message(To,Pid,{s_light,{R,J}});
        _-> {Bool2,To2} = check_close_car(Pid,ets:first(cars)),
          case Bool2 of
            true -> cars:send_msg(To2,{Pid,{s_light,{R,J}}}),io:format("sent message to ~p from ~p~n",[To2,Pid]);
            _->  server:s_light(null,Pid,{R,J})
            %io:format("sent message to server from ~p that on state ~p~n",[Pid,sys:get_state(Pid)])
          end
      end,

%      server:s_light(Pid,{R,J}),
      {next_state, NextStateName, #cars_state{lightPid = LP},get(speed)};

    _ -> NextStateName = stopping,ets:update_element(cars,self(),[{6,{drive_straight}}]) ,

      {Bool1,To} = check_comms_d(Pid,ets:first(comms)),
      case Bool1 of
        true -> communication_tower:receive_message(To,Pid,{s_light,{R,J}});
        _-> {Bool2,To2} = check_close_car(Pid,ets:first(cars)),
          case Bool2 of
            true -> cars:send_msg(To2,{Pid,{s_light,{R,J}}}),io:format("sent message to ~p from ~p~n",[To2,Pid]);
            _->  server:s_light(null,Pid,{R,J})
%io:format("sent message to server from ~p that on state ~p~n",[Pid,sys:get_state(Pid)])
          end
      end,
%      server:s_light(Pid,{R,J}),
      {next_state, NextStateName, #cars_state{lightPid = LP}}

  end;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
drive_straight(cast,{acc,Pid,_},_) ->

  K1 = get(sensor1), K2 = get(sensor2), K3 = get(sensor3), K4 = get(sensor4),K5 = get(sensor5),
  exit(K1,kill),exit(K2,kill),exit(K3,kill),exit(K4,kill),exit(K5,kill),
  ets:delete(sensors,K1), ets:delete(sensors,K2), ets:delete(sensors,K3), ets:delete(sensors,K4),ets:delete(sensors,K5),
  io:format("~p~n~p~n~p~n~p~n~p~n",[K1,K2,K3,K4,K5]),
  io:format("~p~n~p~n~p~n~p~n~p~n",[is_process_alive(K1) ,is_process_alive(K2) ,is_process_alive(K3),is_process_alive(K4),is_process_alive(K5) ]),
  % io:format("ACCIDENT between ~p and ~p ~n",[Pid,OtherCar]),
  E1 = get(name),
  E2 = get(carMon),
  E3 = get(start),
  E4  = get(speed),
  timer:sleep(2000),
  server:deleteCar(Pid),
  {stop,{accident,E1,E2,E3,E4}};

drive_straight(cast,{kst,Pid},State = #cars_state{}) ->
  [{_,[{X,Y},D,R,Type,Turn],_,_,_,_,_}] = ets:lookup(cars,Pid),
  if
    D == up -> ets:update_element(cars,Pid,[{2,[{X,Y -1 },D,R,Type,Turn]}]) ;
    D == down ->ets:update_element(cars,Pid,[{2,[{X,Y +1 },D,R,Type,Turn]}]) ;
    D == right ->ets:update_element(cars,Pid,[{2,[{X + 1,Y },D,R,Type,Turn]}]) ;
    true -> ets:update_element(cars,Pid,[{2,[{X - 1,Y},D,R,Type,Turn]}])
  end,
  NextStateName = drive_straight,ets:update_element(cars,self(),[{6,{drive_straight}}]) ,
  {next_state, NextStateName, State,get(speed)};
drive_straight(timeout,20,State = #cars_state{}) ->
  [{P,[{X,Y},D,R,Type,Turn],_,_,_,_,_}] = ets:lookup(cars,self()),
  if
    D == up -> ets:update_element(cars,P,[{2,[{X,Y -1 },D,R,Type,Turn]}]) ;
    D == down ->ets:update_element(cars,P,[{2,[{X,Y +1 },D,R,Type,Turn]}]) ;
    D == right ->ets:update_element(cars,P,[{2,[{X + 1,Y },D,R,Type,Turn]}]) ;
    true -> ets:update_element(cars,P,[{2,[{X - 1,Y},D,R,Type,Turn]}])
  end,
  NextStateName = drive_straight,ets:update_element(cars,self(),[{6,{drive_straight}}]) ,
  {next_state, NextStateName, State,20};
drive_straight(timeout,10,State = #cars_state{}) ->
  [{P,[{X,Y},D,R,Type,Turn],_,_,_,_,_}] = ets:lookup(cars,self()),
  if
    D == up -> ets:update_element(cars,P,[{2,[{X,Y -1 },D,R,Type,Turn]}]) ;
    D == down ->ets:update_element(cars,P,[{2,[{X,Y +1 },D,R,Type,Turn]}]) ;
    D == right ->ets:update_element(cars,P,[{2,[{X + 1,Y },D,R,Type,Turn]}]) ;
    true -> ets:update_element(cars,P,[{2,[{X - 1,Y},D,R,Type,Turn]}])
  end,
  NextStateName = drive_straight,ets:update_element(cars,self(),[{6,{drive_straight}}]) ,
  {next_state, NextStateName, State,10};
drive_straight(cast,{stop,_},State = #cars_state{}) ->
  NextStateName = stopping,ets:update_element(cars,self(),[{6,{drive_straight}}]) ,
  {next_state, NextStateName, State};
drive_straight(cast,{add_sensor,_,Sensor,Type},State = #cars_state{}) ->
  case Type of
    close_to_car -> erase(sensor1), put(sensor1,Sensor);
    car_accident -> erase(sensor4), put(sensor4,Sensor)
  end,
  io:format("RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR~n"),
  NextStateName = drive_straight,ets:update_element(cars,self(),[{6,{drive_straight}}]) ,
  {next_state, NextStateName, State,get(speed)};

drive_straight(cast,{fturn,_},_) ->
  NextStateName = drive_straight,ets:update_element(cars,self(),[{6,{drive_straight}}]) ,
  {next_state, NextStateName, #cars_state{turnCounter = 0},get(speed)};

drive_straight(cast,{switch,Pid,From,To},_) ->
  K1 = get(sensor1), K2 = get(sensor2), K3 = get(sensor3), K4 = get(sensor4),K5 = get(sensor5),
  exit(K1,kill),exit(K2,kill),exit(K3,kill),exit(K4,kill),exit(K5,kill),
  ets:delete(sensors,K1), ets:delete(sensors,K2), ets:delete(sensors,K3), ets:delete(sensors,K4),ets:delete(sensors,K5),

  E1 =get(name),
  E3 = get(start),
  E4  = get(speed),
  [{_,C,_,_,_,_,_}] = ets:lookup(cars,Pid),
  Con =  {drive_straight},
  case To of
    pc_1 -> server:deleteCar(Pid), {stop,{move_to_comp1,E1,E3,E4,C,From,To,Con}};
    pc_2 -> server:deleteCar(Pid), {stop,{move_to_comp2,E1,E3,E4,C,From,To,Con}};
    pc_3 -> server:deleteCar(Pid), {stop,{move_to_comp3,E1,E3,E4,C,From,To,Con}};
    pc_4 -> server:deleteCar(Pid), {stop,{move_to_comp4,E1,E3,E4,C,From,To,Con}}
  end;


drive_straight(cast,{kill,Pid},_) ->
  K1 = get(sensor1), K2 = get(sensor2), K3 = get(sensor3), K4 = get(sensor4),K5 = get(sensor5),
  exit(K1,kill),exit(K2,kill),exit(K3,kill),exit(K4,kill),exit(K5,kill),
  ets:delete(sensors,K1), ets:delete(sensors,K2), ets:delete(sensors,K3), ets:delete(sensors,K4),ets:delete(sensors,K5),
  io:format("~p~n~p~n~p~n~p~n",[K1,K2,K3,K4]),
  io:format("~p~n~p~n~p~n~p~n",[is_process_alive(K1) ,is_process_alive(K2) ,is_process_alive(K3),is_process_alive(K4) ]),


  E1 =get(name),
  E2 = get(carMon),
  E3 = get(start),
  E4  = get(speed),

  server:deleteCar(Pid),
  {stop,{outOfRange,E1,E2,E3,E4}};

drive_straight(cast,_,State = #cars_state{}) ->
  NextStateName = drive_straight,ets:update_element(cars,self(),[{6,{drive_straight}}]) ,
  {next_state, NextStateName, State,get(speed)}.


idle(cast,{byp,Pid},State = #cars_state{}) ->
  ets:update_element(cars,Pid,[{6,{bypassing,State#cars_state.bypassCounter}}]) ,
  NextStateName = bypassing,
  {next_state, NextStateName, State,get(speed)};

idle(cast,{acc,Pid,_},_) ->
  K1 = get(sensor1), K2 = get(sensor2), K3 = get(sensor3), K4 = get(sensor4),K5 = get(sensor5),
  exit(K1,kill),exit(K2,kill),exit(K3,kill),exit(K4,kill),exit(K5,kill),
  ets:delete(sensors,K1), ets:delete(sensors,K2), ets:delete(sensors,K3), ets:delete(sensors,K4),ets:delete(sensors,K5),
  io:format("~p~n~p~n~p~n~p~n",[K1,K2,K3,K4]),
  io:format("~p~n~p~n~p~n~p~n",[is_process_alive(K1) ,is_process_alive(K2) ,is_process_alive(K3),is_process_alive(K4) ]),
  % io:format("ACCIDENT between ~p and ~p ~n",[Pid,OtherCar]),
  E1 = get(name),
  E2 = get(carMon),
  E3 = get(start),
  E4  = get(speed),
  timer:sleep(2000),
  server:deleteCar(Pid),
  {stop,{accident,E1,E2,E3,E4}};

idle(timeout,20,State = #cars_state{}) ->
  [{P,[{X,Y},D,R,Type,Turn],_,_,_,_,_}] = ets:lookup(cars,self()),
  if
    D == up -> ets:update_element(cars,P,[{2,[{X,Y -1 },D,R,Type,Turn]}]) ;
    D == down ->ets:update_element(cars,P,[{2,[{X,Y +1 },D,R,Type,Turn]}]) ;
    D == right ->ets:update_element(cars,P,[{2,[{X + 1,Y },D,R,Type,Turn]}]) ;
    true -> ets:update_element(cars,P,[{2,[{X - 1,Y},D,R,Type,Turn]}])
  end,
  NextStateName = idle, ets:update_element(cars,self(),[{6,{idle}}]) ,
  {next_state, NextStateName, State,20};
idle(timeout,10,State = #cars_state{}) ->
  [{P,[{X,Y},D,R,Type,Turn],_,_,_,_,_}] = ets:lookup(cars,self()),
  if
    D == up -> ets:update_element(cars,P,[{2,[{X,Y -1 },D,R,Type,Turn]}]) ;
    D == down ->ets:update_element(cars,P,[{2,[{X,Y +1 },D,R,Type,Turn]}]) ;
    D == right ->ets:update_element(cars,P,[{2,[{X + 1,Y },D,R,Type,Turn]}]) ;
    true -> ets:update_element(cars,P,[{2,[{X - 1,Y},D,R,Type,Turn]}])
  end,
  NextStateName = idle, ets:update_element(cars,self(),[{6,{idle}}]) ,
  {next_state, NextStateName, State,10};

idle(cast,{turn,_,{Dir, Road}},State = #cars_state{}) ->
  [{_,[{_,_},D,_,_,_],_,_,_,_,_}] = ets:lookup(cars,self()),
  case D == Dir of
    true ->NextStateName1 = drive_straight,
      {next_state, NextStateName1, State,get(speed)};
    _ ->  NextStateName = turning,ets:update_element(cars,self(),[{6,{turning,State#cars_state.turnCounter,State#cars_state.nextTurnDir,State#cars_state.nextTurnRoad}}])  ,
      {next_state, NextStateName, #cars_state{nextTurnDir = Dir,nextTurnRoad = Road},get(speed)}

  end;

idle(cast,{stop,_,OtherCar},State = #cars_state{}) ->
  spawn(sensors,far_from_car,[self(),OtherCar]),
  NextStateName = stopping, ets:update_element(cars,self(),[{6,{drive_straight}}]) ,
  {next_state, NextStateName, State};

idle(cast,{send,Who,From,Msg},State = #cars_state{})->
  {Bool1,To} = check_comms_d(Who,ets:first(comms)),
  case Bool1 of
    true -> communication_tower:receive_message(To,From,Msg);
    _-> {Bool2,To2} = check_close_car(Who,ets:first(cars)),
      case Bool2 of
        true -> cars:send_msg(To2,{From,Msg});
        _->[{_,[To3]}] = ets:lookup(comms,ets:first(comms)),
          communication_tower:receive_message(To3,From,Msg) % TODO consider computer split


        %  io:format("sent message to communication_tower from ~p that on state ~p~n",[self(),sys:get_state(self())])
      end
  end,
  NextStateName = idle, ets:update_element(cars,self(),[{6,{idle}}]) ,
  {next_state, NextStateName, State,get(speed)};

idle(cast,{add_sensor,_,Sensor,Type},State = #cars_state{}) ->
  case Type of
    close_to_car -> erase(sensor1), put(sensor1,Sensor);
    car_accident -> erase(sensor4), put(sensor4,Sensor)
  end,
  NextStateName = idle, ets:update_element(cars,self(),[{6,{idle}}]) ,
  {next_state, NextStateName, State,get(speed)};

idle(cast,{switch,Pid,From,To},_) ->
  K1 = get(sensor1), K2 = get(sensor2), K3 = get(sensor3), K4 = get(sensor4),K5 = get(sensor5),
  exit(K1,kill),exit(K2,kill),exit(K3,kill),exit(K4,kill),exit(K5,kill),
  ets:delete(sensors,K1), ets:delete(sensors,K2), ets:delete(sensors,K3), ets:delete(sensors,K4),ets:delete(sensors,K5),


  Con =  {idle},
  E1 =get(name),
  E3 = get(start),
  E4  = get(speed),
  [{_,C,_,_,_,_,_}] = ets:lookup(cars,Pid),

  case To of
    pc_1 -> server:deleteCar(Pid), {stop,{move_to_comp1,E1,E3,E4,C,From,To,Con}};
    pc_2 -> server:deleteCar(Pid), {stop,{move_to_comp2,E1,E3,E4,C,From,To,Con}};
    pc_3 -> server:deleteCar(Pid), {stop,{move_to_comp3,E1,E3,E4,C,From,To,Con}};
    pc_4 -> server:deleteCar(Pid), {stop,{move_to_comp4,E1,E3,E4,C,From,To,Con}}
  end;



idle(cast,{kill,Pid},_) ->
  K1 = get(sensor1), K2 = get(sensor2), K3 = get(sensor3), K4 = get(sensor4),K5 = get(sensor5),
  exit(K1,kill),exit(K2,kill),exit(K3,kill),exit(K4,kill),exit(K5,kill),
  ets:delete(sensors,K1), ets:delete(sensors,K2), ets:delete(sensors,K3), ets:delete(sensors,K4),ets:delete(sensors,K5),
  io:format("~p~n~p~n~p~n~p~n",[K1,K2,K3,K4]),
  io:format("~p~n~p~n~p~n~p~n",[is_process_alive(K1) ,is_process_alive(K2) ,is_process_alive(K3),is_process_alive(K4) ]),


  E1 =get(name),
  E2 = get(carMon),
  E3 = get(start),
  E4  = get(speed),

  server:deleteCar(Pid),
  {stop,{outOfRange,E1,E2,E3,E4}};




idle(cast,Else,State = #cars_state{}) ->
  io:format("~p~n",[Else]),
  NextStateName = idle, ets:update_element(cars,self(),[{6,{idle}}]) ,
  {next_state, NextStateName, State,get(speed)}.


turning(cast,{fturn,_},_) ->
  NextStateName = drive_straight, ets:update_element(cars,self(),[{6,{drive_straight}}]) ,



  {next_state, NextStateName, #cars_state{turnCounter = 0},get(speed)};
turning(timeout,10,State = #cars_state{}) ->
  [{P,[{X,Y},D,R,Type,_],_,_,_,_,_}] = ets:lookup(cars,self()), C =State#cars_state.turnCounter,
  Dir = State#cars_state.nextTurnDir,
  Road = State#cars_state.nextTurnRoad,
  if
    D == up, Dir == left, C =< 120 -> ets:update_element(cars,P,[{2,[{X,Y -1 },D,R,Type,st]}]) ;
    D == up, Dir == right, C =< 75 ->ets:update_element(cars,P,[{2,[{X,Y -1 },D,R,Type,st]}]) ;

    D == down, Dir == left, C =< 75 ->ets:update_element(cars,P,[{2,[{X,Y +1 },D,R,Type,st]}]) ;
    D == down, Dir == right, C =< 120 -> ets:update_element(cars,P,[{2,[{X,Y +1 },D,R,Type,st]}]);

    D == right, Dir == up, C =< 120 ->ets:update_element(cars,P,[{2,[{X + 1,Y },D,R,Type,st]}]) ;
    D == right, Dir == down, C =< 75 -> ets:update_element(cars,P,[{2,[{X + 1,Y },D,R,Type,st]}]) ;

    D == left, Dir == up, C =< 75 -> ets:update_element(cars,P,[{2,[{X - 1,Y },D,R,Type,st]}]) ;
    D == left, Dir == down, C =< 120 -> ets:update_element(cars,P,[{2,[{X - 1,Y },D,R,Type,st]}]) ;

    true ->   ets:update_element(cars,P,[{2,[{X ,Y },Dir,Road,Type,st]}]),
      Pid = self(),%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      {Bool1,To} = check_comms_d(Pid,ets:first(comms)),
      case Bool1 of
        true -> communication_tower:receive_message(To,Pid,{car_finish_turn}),
          timer:sleep(10);
        _-> {Bool2,To2} = check_close_car(Pid,ets:first(cars)),
          case Bool2 of
            true -> cars:send_msg(To2,{Pid,{car_finish_turn}}),io:format("sent message to ~p from ~p~n",[To2,Pid]),
              timer:sleep(10);
            _->  server:car_finish_turn(null,self()),timer:sleep(10)
            %io:format("sent message to server from ~p that on state ~p~n",[Pid,sys:get_state(Pid)])
          end
      end
%      server:car_finish_turn(self())
  end,
  NextStateName = turning,ets:update_element(cars,self(),[{6,{turning,State#cars_state.turnCounter,State#cars_state.nextTurnDir,State#cars_state.nextTurnRoad}}])  ,
  {next_state, NextStateName, #cars_state{turnCounter = C + 1,nextTurnDir = Dir , nextTurnRoad = Road },10};

turning(timeout,20,State = #cars_state{}) ->
  [{P,[{X,Y},D,R,Type,_],_,_,_,_,_}] = ets:lookup(cars,self()), C =State#cars_state.turnCounter,

  Dir = State#cars_state.nextTurnDir,
  Road = State#cars_state.nextTurnRoad,


  if
    D == up, Dir == left, C =< 120 -> ets:update_element(cars,P,[{2,[{X,Y -1 },D,R,Type,st]}]) ;
    D == up, Dir == right, C =< 75 ->ets:update_element(cars,P,[{2,[{X,Y -1 },D,R,Type,st]}]) ;

    D == down, Dir == left, C =< 75 ->ets:update_element(cars,P,[{2,[{X,Y +1 },D,R,Type,st]}]) ;
    D == down, Dir == right, C =< 120 -> ets:update_element(cars,P,[{2,[{X,Y +1 },D,R,Type,st]}]);

    D == right, Dir == up, C =< 120 ->ets:update_element(cars,P,[{2,[{X + 1,Y },D,R,Type,st]}]) ;
    D == right, Dir == down, C =< 75 -> ets:update_element(cars,P,[{2,[{X + 1,Y },D,R,Type,st]}]) ;

    D == left, Dir == up, C =< 75 -> ets:update_element(cars,P,[{2,[{X - 1,Y },D,R,Type,st]}]) ;
    D == left, Dir == down, C =< 120 -> ets:update_element(cars,P,[{2,[{X - 1,Y },D,R,Type,st]}]) ;


    true -> ets:update_element(cars,P,[{2,[{X ,Y },Dir,Road,Type,st]}]),
      Pid = self(),%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      {Bool1,To} = check_comms_d(Pid,ets:first(comms)),
      case Bool1 of
        true -> communication_tower:receive_message(To,Pid,{car_finish_turn}),
          timer:sleep(10);
        _-> {Bool2,To2} = check_close_car(Pid,ets:first(cars)),
          case Bool2 of
            true -> cars:send_msg(To2,{Pid,{car_finish_turn}}),io:format("sent message to ~p from ~p~n",[To2,Pid]),
              timer:sleep(10);
            _->  server:car_finish_turn(null,self()),timer:sleep(10)
            %io:format("sent message to server from ~p that on state ~p~n",[Pid,sys:get_state(Pid)])
          end
      end
%      server:car_finish_turn(self())
  end,
  NextStateName = turning,ets:update_element(cars,self(),[{6,{turning,State#cars_state.turnCounter,State#cars_state.nextTurnDir,State#cars_state.nextTurnRoad}}])  ,
  {next_state, NextStateName, #cars_state{turnCounter = C + 1,nextTurnDir = Dir , nextTurnRoad = Road },20};



turning(cast,{ctj,_,_,_,_},State = #cars_state{}) ->
  Dir = State#cars_state.nextTurnDir, Road = State#cars_state.nextTurnRoad, C = State#cars_state.turnCounter,
  NextStateName = turning,ets:update_element(cars,self(),[{6,{turning,State#cars_state.turnCounter,State#cars_state.nextTurnDir,State#cars_state.nextTurnRoad}}])  ,
  {next_state, NextStateName, #cars_state{turnCounter = C + 1,nextTurnDir = Dir , nextTurnRoad = Road },get(speed)};
turning(cast,{ctc,_,OtherCar},State = #cars_state{}) ->
  spawn(sensors,far_from_car,[self(),OtherCar]),
  NextStateName = stopping, ets:update_element(cars,self(),[{6,{drive_straight}}]) ,
  {next_state, NextStateName, State};

turning(cast,{send,Who,From,Msg},State = #cars_state{})->
  {Bool1,To} = check_comms_d(Who,ets:first(comms)),
  case Bool1 of
    true -> communication_tower:receive_message(To,From,Msg);
    _-> {Bool2,To2} = check_close_car(Who,ets:first(cars)),
      case Bool2 of
        true -> cars:send_msg(To2,{From,Msg});
        _->  [{_,[To3]}] = ets:lookup(comms,ets:first(comms)),
          communication_tower:receive_message(To3,From,Msg) % TODO consider computer split

        %  io:format("sent message to communication_tower from ~p that on state ~p~n",[self(),sys:get_state(self())])
      end
  end,
  C =State#cars_state.turnCounter,
  Dir = State#cars_state.nextTurnDir,
  Road = State#cars_state.nextTurnRoad,

  NextStateName = turning,ets:update_element(cars,self(),[{6,{turning,State#cars_state.turnCounter,State#cars_state.nextTurnDir,State#cars_state.nextTurnRoad}}])  ,
  {next_state, NextStateName,#cars_state{turnCounter = C ,nextTurnDir = Dir , nextTurnRoad = Road },get(speed)};




turning(cast,{acc,Pid,_},_) ->

  K1 = get(sensor1), K2 = get(sensor2), K3 = get(sensor3), K4 = get(sensor4),K5 = get(sensor5),
  exit(K1,kill),exit(K2,kill),exit(K3,kill),exit(K4,kill),exit(K5,kill),
  ets:delete(sensors,K1), ets:delete(sensors,K2), ets:delete(sensors,K3), ets:delete(sensors,K4),ets:delete(sensors,K5),
  io:format("~p~n~p~n~p~n~p~n",[K1,K2,K3,K4]),
  io:format("~p~n~p~n~p~n~p~n",[is_process_alive(K1) ,is_process_alive(K2) ,is_process_alive(K3),is_process_alive(K4) ]),
  % io:format("ACCIDENT between ~p and ~p ~n",[Pid,OtherCar]),
  E1 = get(name),
  E2 = get(carMon),
  E3 = get(start),
  E4  = get(speed),
  timer:sleep(2000),
  server:deleteCar(Pid),
  {stop,{accident,E1,E2,E3,E4}};

turning(cast,{add_sensor,_,Sensor,Type},State = #cars_state{}) ->
  C =State#cars_state.turnCounter,
  Dir = State#cars_state.nextTurnDir,
  Road = State#cars_state.nextTurnRoad,
  case Type of
    close_to_car -> erase(sensor1), put(sensor1,Sensor);
    car_accident -> erase(sensor4), put(sensor4,Sensor)
  end,
  NextStateName = turning,ets:update_element(cars,self(),[{6,{turning,State#cars_state.turnCounter,State#cars_state.nextTurnDir,State#cars_state.nextTurnRoad}}])  ,
  {next_state, NextStateName, State = #cars_state{turnCounter = C,nextTurnRoad = Road,nextTurnDir = Dir},get(speed)};

turning(cast,{switch,Pid,From,To},State) ->
  K1 = get(sensor1), K2 = get(sensor2), K3 = get(sensor3), K4 = get(sensor4),K5 = get(sensor5),
  exit(K1,kill),exit(K2,kill),exit(K3,kill),exit(K4,kill),exit(K5,kill),
  ets:delete(sensors,K1), ets:delete(sensors,K2), ets:delete(sensors,K3), ets:delete(sensors,K4),ets:delete(sensors,K5),



  Con =  {turning,State#cars_state.turnCounter,State#cars_state.nextTurnDir,State#cars_state.nextTurnRoad},
  E1 =get(name),
  E3 = get(start),
  E4  = get(speed),
  [{_,C,_,_,_,_,_}] = ets:lookup(cars,Pid),

  case To of
    pc_1 -> server:deleteCar(Pid), {stop,{move_to_comp1,E1,E3,E4,C,From,To,Con}};
    pc_2 -> server:deleteCar(Pid), {stop,{move_to_comp2,E1,E3,E4,C,From,To,Con}};
    pc_3 -> server:deleteCar(Pid), {stop,{move_to_comp3,E1,E3,E4,C,From,To,Con}};
    pc_4 -> server:deleteCar(Pid), {stop,{move_to_comp4,E1,E3,E4,C,From,To,Con}}
  end;



turning(cast,{kill,Pid},_) ->
  K1 = get(sensor1), K2 = get(sensor2), K3 = get(sensor3), K4 = get(sensor4),K5 = get(sensor5),
  exit(K1,kill),exit(K2,kill),exit(K3,kill),exit(K4,kill),exit(K5,kill),
  ets:delete(sensors,K1), ets:delete(sensors,K2), ets:delete(sensors,K3), ets:delete(sensors,K4),ets:delete(sensors,K5),
  io:format("~p~n~p~n~p~n~p~n",[K1,K2,K3,K4]),
  io:format("~p~n~p~n~p~n~p~n",[is_process_alive(K1) ,is_process_alive(K2) ,is_process_alive(K3),is_process_alive(K4) ]),


  E1 =get(name),
  E2 = get(carMon),
  E3 = get(start),
  E4  = get(speed),

  server:deleteCar(Pid),
  {stop,{outOfRange,E1,E2,E3,E4}};

turning(cast,_,State = #cars_state{}) ->
  C =State#cars_state.turnCounter,
  Dir = State#cars_state.nextTurnDir,
  Road = State#cars_state.nextTurnRoad,

  NextStateName = turning,ets:update_element(cars,self(),[{6,{turning,State#cars_state.turnCounter,State#cars_state.nextTurnDir,State#cars_state.nextTurnRoad}}])  ,
  {next_state, NextStateName,#cars_state{turnCounter = C ,nextTurnDir = Dir , nextTurnRoad = Road },get(speed)}.

stopping(cast,{turn,_,{Dir, Road}},State = #cars_state{}) ->
  LP = State#cars_state.lightPid,
  NextStateName = stopping, ets:update_element(cars,self(),[{6,{drive_straight}}]) ,
  {next_state, NextStateName, #cars_state{nextTurnDir = Dir,nextTurnRoad = Road,lightPid = LP},get(speed)};

stopping(timeout,20,State = #cars_state{}) ->
  LP = State#cars_state.lightPid, Dir = State#cars_state.nextTurnDir, Road = State#cars_state.nextTurnRoad,
  case sys:get_state(LP) of
    {green,_} ->   [{_,[{_,_},D,_,_,_],_,_,_,_,_}] = ets:lookup(cars,self()),
      case D == Dir of
        true ->NextStateName1 = drive_straight,
          {next_state, NextStateName1, State,get(speed)};
        _ ->  NextStateName = turning,ets:update_element(cars,self(),[{6,{turning,State#cars_state.turnCounter,State#cars_state.nextTurnDir,State#cars_state.nextTurnRoad}}])  ,
          {next_state, NextStateName, #cars_state{nextTurnDir = Dir,nextTurnRoad = Road},get(speed)}

      end;
    _ -> NextStateName = stopping, ets:update_element(cars,self(),[{6,{drive_straight}}]) ,
      {next_state, NextStateName, #cars_state{nextTurnDir = Dir,nextTurnRoad = Road, lightPid = LP},20}
  end ;
stopping(timeout,10,State = #cars_state{}) ->
  LP = State#cars_state.lightPid, Dir = State#cars_state.nextTurnDir, Road = State#cars_state.nextTurnRoad,
  case sys:get_state(LP) of
    {green,_} ->   [{_,[{_,_},D,_,_,_],_,_,_,_,_}] = ets:lookup(cars,self()),
      case D == Dir of
        true ->NextStateName1 = drive_straight,
          {next_state, NextStateName1, State,get(speed)};
        _ ->  NextStateName = turning,ets:update_element(cars,self(),[{6,{turning,State#cars_state.turnCounter,State#cars_state.nextTurnDir,State#cars_state.nextTurnRoad}}])  ,
          {next_state, NextStateName, #cars_state{nextTurnDir = Dir,nextTurnRoad = Road},get(speed)}

      end;
    _ -> NextStateName = stopping, ets:update_element(cars,self(),[{6,{drive_straight}}]) ,
      {next_state, NextStateName, #cars_state{nextTurnDir = Dir,nextTurnRoad = Road, lightPid = LP},10}
  end ;
stopping(cast,{ctj,_,_,_,_},State = #cars_state{}) ->
  LP = State#cars_state.lightPid, Dir = State#cars_state.nextTurnDir, Road = State#cars_state.nextTurnRoad,
  NextStateName = stopping, ets:update_element(cars,self(),[{6,{drive_straight}}]) ,
  {next_state, NextStateName, #cars_state{nextTurnDir = Dir,nextTurnRoad = Road, lightPid = LP},get(speed)};
stopping(cast,{far,_},State = #cars_state{}) ->
  NextStateName = drive_straight, ets:update_element(cars,self(),[{6,{drive_straight}}]) ,
  {next_state, NextStateName, State,get(speed)};
stopping(cast,{acc,Pid,_},_) ->

  K1 = get(sensor1), K2 = get(sensor2), K3 = get(sensor3), K4 = get(sensor4),K5 = get(sensor5),
  exit(K1,kill),exit(K2,kill),exit(K3,kill),exit(K4,kill),exit(K5,kill),
  ets:delete(sensors,K1), ets:delete(sensors,K2), ets:delete(sensors,K3), ets:delete(sensors,K4),ets:delete(sensors,K5),
  io:format("~p~n~p~n~p~n~p~n",[K1,K2,K3,K4]),
  io:format("~p~n~p~n~p~n~p~n",[is_process_alive(K1) ,is_process_alive(K2) ,is_process_alive(K3),is_process_alive(K4) ]),
  % io:format("ACCIDENT between ~p and ~p ~n",[Pid,OtherCar]),
  E1 = get(name),
  E2 = get(carMon),
  E3 = get(start),
  E4  = get(speed),
  timer:sleep(2000),
  server:deleteCar(Pid),
  {stop,{accident,E1,E2,E3,E4}};


stopping(cast,{send,Who,From,Msg},State = #cars_state{})->
  {Bool1,To} = check_comms_d(Who,ets:first(comms)),
  case Bool1 of
    true -> communication_tower:receive_message(To,From,Msg);
    _-> {Bool2,To2} = check_close_car(Who,ets:first(cars)),
      case Bool2 of
        true -> cars:send_msg(To2,{From,Msg});
        _->  [{_,[To3]}] = ets:lookup(comms,ets:first(comms)),
          communication_tower:receive_message(To3,From,Msg) % TODO consider computer split

        %    io:format("sent message to communication_tower from ~p that on state ~p~n",[self(),sys:get_state(self())])
      end
  end,
  LP = State#cars_state.lightPid, Dir = State#cars_state.nextTurnDir, Road = State#cars_state.nextTurnRoad,
  case Dir of
    undefined -> NextStateName = stopping, ets:update_element(cars,self(),[{6,{drive_straight}}]) ,
      {next_state, NextStateName, State};
    _->  NextStateName = stopping, ets:update_element(cars,self(),[{6,{drive_straight}}]) ,
      {next_state, NextStateName, #cars_state{lightPid = LP, nextTurnDir = Dir,nextTurnRoad = Road },get(speed)}
  end;

stopping(cast,{add_sensor,_,Sensor,Type},State = #cars_state{}) ->
  case Type of
    close_to_car -> erase(sensor1), put(sensor1,Sensor);
    car_accident -> erase(sensor4), put(sensor4,Sensor)
  end,
  LP = State#cars_state.lightPid, Dir = State#cars_state.nextTurnDir, Road = State#cars_state.nextTurnRoad,
  case Dir of
    undefined -> NextStateName = stopping, ets:update_element(cars,self(),[{6,{drive_straight}}]) ,
      {next_state, NextStateName, State};
    _->  NextStateName = stopping, ets:update_element(cars,self(),[{6,{drive_straight}}]) ,
      {next_state, NextStateName, #cars_state{lightPid = LP, nextTurnDir = Dir,nextTurnRoad = Road },get(speed)}
  end;

stopping(cast,{kill,Pid},_) ->
  K1 = get(sensor1), K2 = get(sensor2), K3 = get(sensor3), K4 = get(sensor4),K5 = get(sensor5),
  exit(K1,kill),exit(K2,kill),exit(K3,kill),exit(K4,kill),exit(K5,kill),
  ets:delete(sensors,K1), ets:delete(sensors,K2), ets:delete(sensors,K3), ets:delete(sensors,K4),ets:delete(sensors,K5),
  io:format("~p~n~p~n~p~n~p~n",[K1,K2,K3,K4]),
  io:format("~p~n~p~n~p~n~p~n",[is_process_alive(K1) ,is_process_alive(K2) ,is_process_alive(K3),is_process_alive(K4) ]),


  E1 =get(name),
  E2 = get(carMon),
  E3 = get(start),
  E4  = get(speed),

  server:deleteCar(Pid),
  {stop,{outOfRange,E1,E2,E3,E4}};





stopping(cast,_,State = #cars_state{}) ->
  NextStateName = stopping, ets:update_element(cars,self(),[{6,{drive_straight}}]) ,
  {next_state, NextStateName, State}.



bypassing(cast,{ctc,_,_},State = #cars_state{}) ->
  NextStateName = bypassing, ets:update_element(cars,self(),[{6,{bypassing,State#cars_state.bypassCounter}}]) ,
  {next_state, NextStateName, #cars_state{bypassCounter = 280}};
bypassing(cast,{ctj,_,T,{_,_},LP},State = #cars_state{}) ->
  C =State#cars_state.bypassCounter,
  case T of
    {green,_} -> NextStateName = bypassing, ets:update_element(cars,self(),[{6,{bypassing,State#cars_state.bypassCounter}}]) ,
      {next_state, NextStateName, #cars_state{bypassCounter = C},get(speed)};

    _ -> NextStateName = bypassing, ets:update_element(cars,self(),[{6,{bypassing,State#cars_state.bypassCounter}}]) ,
      {next_state, NextStateName, #cars_state{lightPid = LP,bypassCounter = C},8}

  end;
bypassing(timeout,8,State = #cars_state{}) ->
  LP = State#cars_state.lightPid, C = State#cars_state.bypassCounter,
  case LP of
    nal ->  NextStateName = bypassing, ets:update_element(cars,self(),[{6,{bypassing,State#cars_state.bypassCounter}}]) ,
      {next_state, NextStateName, #cars_state{bypassCounter = C},get(speed)};
    _ -> case sys:get_state(LP) of
           {green,_} -> NextStateName = bypassing, ets:update_element(cars,self(),[{6,{bypassing,State#cars_state.bypassCounter}}]) ,
             {next_state, NextStateName, #cars_state{bypassCounter = 100},get(speed)};
           _ -> NextStateName = bypassing, ets:update_element(cars,self(),[{6,{bypassing,State#cars_state.bypassCounter}}]) ,
             {next_state, NextStateName, #cars_state{lightPid = LP},8}
         end
  end;

bypassing(cast,{fByp,_},_) ->
  NextStateName = drive_straight, ets:update_element(cars,self(),[{6,{drive_straight}}]) ,
  {next_state, NextStateName, #cars_state{bypassCounter = 0},get(speed)};
bypassing(cast,{acc,Pid,_},_) ->

  K1 = get(sensor1), K2 = get(sensor2), K3 = get(sensor3), K4 = get(sensor4),K5 = get(sensor5),
  exit(K1,kill),exit(K2,kill),exit(K3,kill),exit(K4,kill),exit(K5,kill),
  ets:delete(sensors,K1), ets:delete(sensors,K2), ets:delete(sensors,K3), ets:delete(sensors,K4),ets:delete(sensors,K5),
  io:format("~p~n~p~n~p~n~p~n",[K1,K2,K3,K4]),
  io:format("~p~n~p~n~p~n~p~n",[is_process_alive(K1) ,is_process_alive(K2) ,is_process_alive(K3),is_process_alive(K4) ]),
  % io:format("ACCIDENT between ~p and ~p ~n",[Pid,OtherCar]),
  E1 = get(name),
  E2 = get(carMon),
  E3 = get(start),
  E4  = get(speed),
  timer:sleep(2000),
  server:deleteCar(Pid),
  {stop,{accident,E1,E2,E3,E4}};

bypassing(timeout,20,State = #cars_state{}) ->
  [{P,[{X,Y},D,R,Type,Turn],_,_,_,_,_}] = ets:lookup(cars,self()), C =State#cars_state.bypassCounter,
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


    true ->

      Pid = self(),%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      {Bool1,To} = check_comms_d(Pid,ets:first(comms)),
      case Bool1 of
        true -> communication_tower:receive_message(To,Pid,{car_finish_bypass}),
          timer:sleep(10);
        _-> {Bool2,To2} = check_close_car(Pid,ets:first(cars)),
          case Bool2 of
            true -> cars:send_msg(To2,{Pid,{car_finish_bypass}}),io:format("sent message to ~p from ~p~n",[To2,Pid]),
              timer:sleep(10);
            _->   server:car_finish_bypass(null,self())
            %io:format("sent message to server from ~p that on state ~p~n",[Pid,sys:get_state(Pid)])
          end
      end


%      server:car_finish_bypass(self())
  end,
  NextStateName = bypassing, ets:update_element(cars,self(),[{6,{bypassing,State#cars_state.bypassCounter}}]) ,
  {next_state, NextStateName, #cars_state{bypassCounter = C + 1},20};
bypassing(timeout,10,State = #cars_state{}) ->
  [{P,[{X,Y},D,R,Type,Turn],_,_,_,_,_}] = ets:lookup(cars,self()), C =State#cars_state.bypassCounter,
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


    true ->
      Pid = self(),%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      {Bool1,To} = check_comms_d(Pid,ets:first(comms)),
      case Bool1 of
        true -> communication_tower:receive_message(To,Pid,{car_finish_bypass}),
          timer:sleep(10);
        _-> {Bool2,To2} = check_close_car(Pid,ets:first(cars)),
          case Bool2 of
            true -> cars:send_msg(To2,{Pid,{car_finish_bypass}}),io:format("sent message to ~p from ~p~n",[To2,Pid]),
              timer:sleep(10);
            _->   server:car_finish_bypass(null,self())
            %io:format("sent message to server from ~p that on state ~p~n",[Pid,sys:get_state(Pid)])
          end
      end


%      server:car_finish_bypass(self())
  end,
  NextStateName = bypassing, ets:update_element(cars,self(),[{6,{bypassing,State#cars_state.bypassCounter}}]) ,
  {next_state, NextStateName, #cars_state{bypassCounter = C + 1},10};


bypassing(cast,{send,Who,From,Msg},State = #cars_state{})->
  {Bool1,To} = check_comms_d(Who,ets:first(comms)),
  case Bool1 of
    true -> communication_tower:receive_message(To,From,Msg);
    _-> {Bool2,To2} = check_close_car(Who,ets:first(cars)),
      case Bool2 of
        true -> cars:send_msg(To2,{From,Msg});
        _->  [{_,[To3]}] = ets:lookup(comms,ets:first(comms)),
          communication_tower:receive_message(To3,From,Msg) % TODO consider computer split

        %     io:format("sent message to communication_tower from ~p that on state ~p~n",[self(),sys:get_state(self())])
      end
  end,
  C =State#cars_state.bypassCounter,
  NextStateName = bypassing, ets:update_element(cars,self(),[{6,{bypassing,State#cars_state.bypassCounter}}]) ,
  {next_state, NextStateName, #cars_state{bypassCounter =  C},get(speed)};

bypassing(cast,{add_sensor,_,Sensor,Type},State = #cars_state{}) ->
  case Type of
    close_to_car -> erase(sensor1), put(sensor1,Sensor);
    car_accident -> erase(sensor4), put(sensor4,Sensor)
  end,
  C =State#cars_state.bypassCounter,
  NextStateName = bypassing, ets:update_element(cars,self(),[{6,{bypassing,State#cars_state.bypassCounter}}]) ,
  {next_state, NextStateName, #cars_state{bypassCounter =  C},get(speed)};

bypassing(cast,{switch,Pid,From,To},State) ->
  K1 = get(sensor1), K2 = get(sensor2), K3 = get(sensor3), K4 = get(sensor4),K5 = get(sensor5),
  exit(K1,kill),exit(K2,kill),exit(K3,kill),exit(K4,kill),exit(K5,kill),
  ets:delete(sensors,K1), ets:delete(sensors,K2), ets:delete(sensors,K3), ets:delete(sensors,K4),ets:delete(sensors,K5),


  Con =  {bypassing,State#cars_state.bypassCounter},
  E1 =get(name),
  E3 = get(start),
  E4  = get(speed),
  [{_,C,_,_,_,_,_}] = ets:lookup(cars,Pid),

  case To of
    pc_1 -> server:deleteCar(Pid), {stop,{move_to_comp1,E1,E3,E4,C,From,To,Con}};
    pc_2 -> server:deleteCar(Pid), {stop,{move_to_comp2,E1,E3,E4,C,From,To,Con}};
    pc_3 -> server:deleteCar(Pid), {stop,{move_to_comp3,E1,E3,E4,C,From,To,Con}};
    pc_4 -> server:deleteCar(Pid), {stop,{move_to_comp4,E1,E3,E4,C,From,To,Con}}
  end;


bypassing(cast,{kill,Pid},_) ->
  K1 = get(sensor1), K2 = get(sensor2), K3 = get(sensor3), K4 = get(sensor4),K5 = get(sensor5),
  exit(K1,kill),exit(K2,kill),exit(K3,kill),exit(K4,kill),exit(K5,kill),
  ets:delete(sensors,K1), ets:delete(sensors,K2), ets:delete(sensors,K3), ets:delete(sensors,K4),ets:delete(sensors,K5),
  io:format("~p~n~p~n~p~n~p~n",[K1,K2,K3,K4]),
  io:format("~p~n~p~n~p~n~p~n",[is_process_alive(K1) ,is_process_alive(K2) ,is_process_alive(K3),is_process_alive(K4) ]),


  E1 =get(name),
  E2 = get(carMon),
  E3 = get(start),
  E4  = get(speed),

  server:deleteCar(Pid),
  {stop,{outOfRange,E1,E2,E3,E4}};



bypassing(cast,Else,State = #cars_state{}) ->
  io:format("~p~n",[Else]),
  C =State#cars_state.bypassCounter,
  NextStateName = bypassing, ets:update_element(cars,self(),[{6,{bypassing,State#cars_state.bypassCounter}}]) ,
  {next_state, NextStateName, #cars_state{bypassCounter =  C},get(speed)}.



check_comms_d(_,'$end_of_table') -> {false,nal};
check_comms_d(Pid,Key)->
  [{_,[{X,Y},_,_,_,_],_,_,_,_,_}] = ets:lookup(cars,Pid),
  {X2,Y2} = Key,
  [{_,[To]}] = ets:lookup(comms,Key),

  D = math:sqrt(math:pow(X-X2,2) + math:pow(Y-Y2,2)),
  if
    D =< 150 -> {true,To};
    true -> check_comms_d(Pid,ets:next(comms,Key))
  end.


check_close_car(_,'$end_of_table') -> {false,nal};
check_close_car(Pid,Key)->
  [{_,[{X,Y},_,_,_,_],_,_,_,_,_}] = ets:lookup(cars,Pid),
  [{_,[{X2,Y2},_,_,_,_],_,_,_,_,_}] = ets:lookup(cars,Key),

  D = math:sqrt(math:pow(X-X2,2) + math:pow(Y-Y2,2)),
  if
    D =< 130, Pid /= Key -> {true,Key};
    true -> check_close_car(Pid,ets:next(cars,Key))
  end.





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
  % timer:sleep(1500),

  % K1 = get(sensor1), K2 = get(sensor2), K3 = get(sensor3),
  %server:deleteCar(self()),

%  exit(K1,kill),  exit(K2,kill),  exit(K3,kill),
  % io:format("AAAAAAAAAAAAAAAA"),

  %ets:delete(cars,self()),
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
