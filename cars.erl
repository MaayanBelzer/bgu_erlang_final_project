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
-export([close_to_car/0,close_to_junc/0,accident/0,slow_down/0,speed_up/0,turn/1,go_straight/0,bypass/0,far_from_car/0]).
-export([max_speed/0,finish_turn/0,green_light/1,f_bypass/0]).

%% States
-export([drive_straight/3,idle/3,slowing/3,accelerating/3,turning/3,turn_after_stop/3,stop/3,bypassing/3]).


-define(SERVER, ?MODULE).

-record(cars_state, {}).

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
init([]) ->
  %%----------------process_flag??
  {ok,drive_straight, #cars_state{}}.


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
close_to_car() -> gen_statem:cast(?MODULE,{ctc}).
close_to_junc() -> gen_statem:cast(?MODULE,{ctj}).
accident() -> gen_statem:cast(?MODULE,{acc}).
slow_down() -> gen_statem:cast(?MODULE,{slow}).
speed_up() -> gen_statem:cast(?MODULE,{speed}).
turn(left) -> gen_statem:cast(?MODULE,{turnL});
turn(right) -> gen_statem:cast(?MODULE,{turnR}).
go_straight() -> gen_statem:cast(?MODULE,{str8}).
bypass() -> gen_statem:cast(?MODULE,{byp}).
f_bypass() -> gen_statem:cast(?MODULE,{fByp}).
far_from_car() -> gen_statem:cast(?MODULE,{far}).
max_speed() -> gen_statem:cast(?MODULE,{maxS}).
finish_turn() -> gen_statem:cast(?MODULE,{fTurn}).
green_light(straight) -> gen_statem:cast(?MODULE,{greenS});
green_light(left) -> gen_statem:cast(?MODULE,{greenL});
green_light(right) -> gen_statem:cast(?MODULE,{greenR}).


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

drive_straight(cast,{ctc},State = #cars_state{}) ->
  % TODO: send message to server
  NextStateName = idle,
  {next_state, NextStateName, State};
drive_straight(cast,{ctj},State = #cars_state{}) ->
  % TODO: slow down, send message to server and stop\keep going according to traffic light
  NextStateName = idle,
  {next_state, NextStateName, State};
drive_straight(cast,{acc},State = #cars_state{}) ->
  % TODO: stop and send message to server
  NextStateName = idle,
  {next_state, NextStateName, State}.
idle(cast,{slow},State = #cars_state{}) ->
  % TODO: slow down
  NextStateName = slowing,
  {next_state, NextStateName, State};
idle(cast,{speed},State = #cars_state{}) ->
  % TODO: accelerate
  NextStateName = accelerating,
  {next_state, NextStateName, State};
idle(cast,{turnL},State = #cars_state{}) ->
  % TODO: start turning left
  NextStateName = turning,
  {next_state, NextStateName, State};
idle(cast,{turnR},State = #cars_state{}) ->
  % TODO: start turning right
  NextStateName = turning,
  {next_state, NextStateName, State};
idle(cast,{str8},State = #cars_state{}) ->
  % TODO: go straight
  NextStateName = accelerating,
  {next_state, NextStateName, State};
idle(cast,{byp},State = #cars_state{}) ->
  % TODO: start bypassing
  NextStateName = bypassing,
  {next_state, NextStateName, State};
idle(cast,{acc},State = #cars_state{}) ->
  % TODO: stop and send message to server
  NextStateName = idle,
  {next_state, NextStateName, State}.
slowing(cast,{ctc},State = #cars_state{}) ->
  % TODO: send message to server
  NextStateName = idle,
  {next_state, NextStateName, State};
slowing(cast,{ctj},State = #cars_state{}) ->
  % TODO: slow down, send message to server and stop\keep going according to traffic light
  NextStateName = idle,
  {next_state, NextStateName, State};
slowing(cast,{far},State = #cars_state{}) ->
  % TODO: start accelerating
  NextStateName = accelerating,
  {next_state, NextStateName, State};
slowing(cast,{acc},State = #cars_state{}) ->
  % TODO: stop and send message to server
  NextStateName = idle,
  {next_state, NextStateName, State}.
accelerating(cast,{ctc},State = #cars_state{}) ->
  % TODO: stop accelerating and send message to server
  NextStateName = idle,
  {next_state, NextStateName, State};
accelerating(cast,{ctj},State = #cars_state{}) ->
  % TODO: slow down, send message to server and stop\keep going according to traffic light
  NextStateName = idle,
  {next_state, NextStateName, State};
accelerating(cast,{maxS},State = #cars_state{}) ->
  % TODO: stop accelerating
  NextStateName = drive_straight,
  {next_state, NextStateName, State};
accelerating(cast,{acc},State = #cars_state{}) ->
  % TODO: stop and send message to server
  NextStateName = idle,
  {next_state, NextStateName, State}.
turning(cast,{ctc},State = #cars_state{}) ->
  % TODO: send message to server
  NextStateName = idle,
  {next_state, NextStateName, State};
turning(cast,{fTurn},State = #cars_state{}) ->
  % TODO: start accelerating
  NextStateName = accelerating,
  {next_state, NextStateName, State};
turning(cast,{acc},State = #cars_state{}) ->
  % TODO: stop and send message to server
  NextStateName = idle,
  {next_state, NextStateName, State}.
turn_after_stop(cast,{acc},State = #cars_state{}) ->
  % TODO: send message to server
  NextStateName = idle,
  {next_state, NextStateName, State};
turn_after_stop(cast,{fTurn},State = #cars_state{}) ->
  % TODO: start accelerating
  NextStateName = accelerating,
  {next_state, NextStateName, State};
turn_after_stop(cast,{acc},State = #cars_state{}) ->
  % TODO: stop and send message to server
  NextStateName = idle,
  {next_state, NextStateName, State}.
stop(cast,{greenS},State = #cars_state{}) ->
  % TODO: accelerate
  NextStateName = accelerating,
  {next_state, NextStateName, State};
stop(cast,{greenL},State = #cars_state{}) ->
  % TODO: start accelerating and turning left
  NextStateName = turn_after_stop,
  {next_state, NextStateName, State};
stop(cast,{greenR},State = #cars_state{}) ->
  % TODO: start accelerating and turning right
  NextStateName = turn_after_stop,
  {next_state, NextStateName, State};
stop(cast,{far},State = #cars_state{}) ->
  % TODO: send message to server
  NextStateName = idle,
  {next_state, NextStateName, State};
stop(cast,{acc},State = #cars_state{}) ->
  % TODO: stop and send message to server
  NextStateName = idle,
  {next_state, NextStateName, State}.
bypassing(cast,{ctc},State = #cars_state{}) ->
  % TODO: slow down and send message to server
  NextStateName = idle,
  {next_state, NextStateName, State};
bypassing(cast,{ctj},State = #cars_state{}) ->
  % TODO: slow down, send message to server and stop\keep going according to traffic light
  NextStateName = idle,
  {next_state, NextStateName, State};
bypassing(cast,{fByp},State = #cars_state{}) ->
  % TODO: return to right lane and drive straight
  NextStateName = drive_straight,
  {next_state, NextStateName, State};
bypassing(cast,{acc},State = #cars_state{}) ->
  % TODO: stop and send message to server
  NextStateName = idle,
  {next_state, NextStateName, State}.


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
