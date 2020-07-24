%%%-------------------------------------------------------------------
%%% @author MN
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Jul 2020 3:53 AM
%%%-------------------------------------------------------------------
-module(server).
-author("MN").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

% gen_server events
-export([s_accident/2,s_close_to_car/2,s_fallen_car/1,s_into_range/1,s_light/2,s_out_of_range/1,start/0]).

-define(SERVER, ?MODULE).

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @end
%%--------------------------------------------------------------------
-spec(start_link() ->
  {ok, Pid :: pid()} | ignore | {error, Reason :: term()}).
start_link() ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).
start() ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
-spec(init(Args :: term()) ->
  {ok, State :: #state{}} | {ok, State :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term()} | ignore).
init([]) ->
  ets:new(cars,[set,public,named_table]),

  %Pid = spawn(cars,start,[1]),
  %io:format("AAAAAAAAAAAAAAAAAAAAAAAAAA  ~p~n",[Pid]),
  %ets:insert(cars,{Pid,[{1200,120},left,r1]}),
  ets:insert(cars,{1,[{160, 120},left,r1]}),

%c(main).
%c(server).
%c(cars).
%c(sensors).
%main:start().

  ets:new(junction,[set,public,named_table]),

  %ets:insert(junction,{{r1,a},[{1052,120}]}),
  traffic_light:start({{r1,a},[{1052,120}]}),

  traffic_light:start({{r1,b},[{932,120}]}),

  ets:insert(junction,{{r1,t},[{793,120},nal]}),

  traffic_light:start({{r1,c},[{656,120}]}),
  ets:insert(junction,{{r1,s},[{435,120},nal]}),

  traffic_light:start({{r1,d},[{301,120}]}),
  traffic_light:start({{r1,e},[{162,120}]}),
  traffic_light:start({{r2,e},[{128,80}]}),
  traffic_light:start({{r2,f},[{128,380}]}),
  traffic_light:start({{r2,o},[{128,625}]}),
  traffic_light:start({{r3,f},[{92,418}]}),

  ets:insert(junction,{{r3,r},[{236,418},nal]}),
  traffic_light:start({{r3,g},[{376,418}]}),
  traffic_light:start({{r3,h},[{586,418}]}),
  traffic_light:start({{r3,i},[{737,418}]}),
  ets:insert(junction,{{r3,u},[{871,418},nal]}),

  traffic_light:start({{r3,j},[{1088,418}]}),
  traffic_light:start({{r4,l},[{625,819}]}),
  traffic_light:start({{r4,m},[{625,692}]}),
  traffic_light:start({{r4,h},[{625,476}]}),
  traffic_light:start({{r4,c},[{625,121}]}),
  traffic_light:start({{r5,k},[{1086,655}]}),
  traffic_light:start({{r6,k},[{1122,700}]}),
  traffic_light:start({{r6,j},[{1122,466}]}),
  traffic_light:start({{r6,a},[{1122,183}]}),
  traffic_light:start({{r7,l},[{663,787}]}),
  traffic_light:start({{r8,d},[{266,180}]}),
  traffic_light:start({{r9,o},[{92,655}]}),
  traffic_light:start({{r9,n},[{367,655}]}),
  traffic_light:start({{r9,m},[{586,655}]}),
  traffic_light:start({{r10,i},[{763,379}]}),
  ets:insert(junction,{{r12,p},[{902,621},nal]}),

  ets:insert(junction,{{r12,q},[{902,756},nal]}),

  traffic_light:start({{r14,n},[{407,709}]}),
  traffic_light:start({{r14,g},[{407,474}]}),
  traffic_light:start({{r18,b},[{902,82}]}),

  cars:start(1),

  {ok, #state{}}.

%% Events
s_light(Who,Light) -> gen_server:cast(?MODULE,{light,Who,Light}).
s_close_to_car(Who,OtherCar) -> gen_server:cast(?MODULE,{ctc,Who,OtherCar}).
s_fallen_car(Who) -> gen_server:cast(?MODULE,{fallen,Who}).
s_accident(Who,Car2) -> gen_server:cast(?MODULE,{acc,Who,Car2}).
s_out_of_range(Who) -> gen_server:cast(?MODULE,{oor,Who}).
s_into_range(Who) -> gen_server:cast(?MODULE,{inr,Who}).


%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_call(Request :: term(), From :: {pid(), Tag :: term()},
    State :: #state{}) ->
  {reply, Reply :: term(), NewState :: #state{}} |
  {reply, Reply :: term(), NewState :: #state{}, timeout() | hibernate} |
  {noreply, NewState :: #state{}} |
  {noreply, NewState :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term(), Reply :: term(), NewState :: #state{}} |
  {stop, Reason :: term(), NewState :: #state{}}).
handle_call(_Request, _From, State) ->
  {reply, ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_cast(Request :: term(), State :: #state{}) ->
  {noreply, NewState :: #state{}} |
  {noreply, NewState :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term(), NewState :: #state{}}).
%handle_cast(_Request, State) ->
%  {noreply, State}.
handle_cast({light,Who,Light}, State) -> % TODO: decide whether the car turns left, right or straight
  {noreply, State};
handle_cast({ctc,Who,OtherCar}, State) -> % TODO: decide whether the car sloes down or bypasses the other car
  {noreply, State};
handle_cast({fallen,Who}, State) -> % TODO: if car process has fallen with an error, bring it back up if possible
  {noreply, State};
handle_cast({acc,Who,Car2}, State) -> % TODO: remove involved cars from street
  {noreply, State};
handle_cast({oor,Who}, State) -> % TODO: send car details to new server and remove car from ETS
  {noreply, State};
handle_cast({inr,Who}, State) -> % TODO: enter car details to ETS
  {noreply, State}. %%%



%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
-spec(handle_info(Info :: timeout() | term(), State :: #state{}) ->
  {noreply, NewState :: #state{}} |
  {noreply, NewState :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term(), NewState :: #state{}}).
handle_info(_Info, State) ->
  {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
-spec(terminate(Reason :: (normal | shutdown | {shutdown, term()} | term()),
    State :: #state{}) -> term()).
terminate(_Reason, _State) ->
  ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
-spec(code_change(OldVsn :: term() | {down, term()}, State :: #state{},
    Extra :: term()) ->
  {ok, NewState :: #state{}} | {error, Reason :: term()}).
code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
