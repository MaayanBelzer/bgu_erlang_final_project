%%%-------------------------------------------------------------------
%%% @author Maayan Belzer, Nir Tapiero
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Jul 2020 3:53 AM
%%%-------------------------------------------------------------------
-module(server).
-author("Maayan Belzer, Nir Tapiero").

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
-export([s_close_to_car/3,s_light/3,start/0,start/5,
%  car_finish_bypass/2,car_finish_turn/2
  deleteCar/1,deletePid/1,update_car_location/0,start_car/4,moved_car/7,update_monitor/1,smoke/4,deletesmoke/1,print_light/2,
  search_close_car/2,search_close_junc/2,update_car_nev/2,server_search_close_car/2,server_search_close_junc/2,light/4,ctc/3,checkBypass/3,checkBypass2/2]).

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
start(PC1,PC2,PC3,PC4,Home) ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [PC1,PC2,PC3,PC4,Home], []).

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

init([PC1,PC2,PC3,PC4,Home]) ->
  put(pc1,PC1), put(pc2,PC2), put(pc3,PC3), put(pc4,PC4), put(home,Home), % put PCs address in process dictionary
  ets:new(cars,[set,public,named_table]), % initialize new ets for cars

  net_kernel:connect_node(PC1), % connect PCs
  net_kernel:connect_node(PC2),
  net_kernel:connect_node(PC3),
  net_kernel:connect_node(PC4),

  ets:new(junction,[set,public,named_table]), % initialize ets for junctions and add all traffic lights

  traffic_light:start(r1a,{{r1,a},[{1137,120}]}),%%%%%%%%%%%%%%%%%%%%%%%%%5
%  traffic_light:start(r1a,{{r1,a},[{1137,120},{1130, 35}]}),
  traffic_light:start(r1b,{{r1,b},[{938,120}]}),%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%  traffic_light:start(r1b,{{r1,b},[{938,120},{847, 35}]}),
  ets:insert(junction,{{r1,t},[{799,120},nal]}),%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ets:insert(junction,{{r1,t},[{799,120},nal,{nal,nal}]}),
  traffic_light:start(r1c,{{r1,c},[{638,120}]}),%%%%%%%%%%%%%%%%%%%%%%%%%%5
%  traffic_light:start(r1c,{{r1,c},[{638,120},{634, 35}]}),
  ets:insert(junction,{{r1,s},[{420,120},nal]}),%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ets:insert(junction,{{r1,s},[{420,120},nal,{nal,nal}]}),
  traffic_light:start(r1d,{{r1,d},[{302,120}]}),%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  traffic_light:start(r1d,{{r1,d},[{302,120},{280, 35}]}),
  traffic_light:start(r1e,{{r1,e},[{164,120}]}),%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  traffic_light:start(r1e,{{r1,e},[{164,120},{138, 35}]}),
  traffic_light:start(r2e,{{r2,e},[{128,75}]}),%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%  traffic_light:start(r2e,{{r2,e},[{128,75},{75, 35}]}),
  traffic_light:start(r2f,{{r2,f},[{128,355}]}),%%%%%%%%%%%%%%%%%%%%%%%%%%
%  traffic_light:start(r2f,{{r2,f},[{128,355},{75, 330}]}),
  traffic_light:start(r2o,{{r2,o},[{128,590}]}),%%%%%%%%%%%%%%%%%%%%%%
%  traffic_light:start(r2o,{{r2,o},[{128,590},{75, 575}]}),
  traffic_light:start(r3f,{{r3,f},[{81,418}]}),%%%%%%%%%%%%%%%%%%%%%%
%  traffic_light:start(r3f,{{r3,f},[{81,418},{75, 426}]}),
  ets:insert(junction,{{r3,r},[{204,418},nal]}),%%%%%%%%%%%%%%%%%%%%%
%  ets:insert(junction,{{r3,r},[{204,418},nal,{nal,nal}]}),
  traffic_light:start(r3g,{{r3,g},[{372,418}]}),%%%%%%%%%%%%%%%%%%%%%5
%  traffic_light:start(r3g,{{r3,g},[{372,418},{355, 426}]}),
  traffic_light:start(r3h,{{r3,h},[{560,418}]}),%%%%%%%%%%%%%%%%%%%%%%%%%%5
%  traffic_light:start(r3h,{{r3,h},[{560,418},{571, 426}]}),
  traffic_light:start(r3i,{{r3,i},[{728,418}]}),%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%  traffic_light:start(r3i,{{r3,i},[{728,418},{713, 420}]}),
  ets:insert(junction,{{r3,u},[{860,418},nal]}),%%%%%%%%%%%%%%%%%%%%%%
%  ets:insert(junction,{{r3,u},[{860,418},nal,{nal,nal}]}),
  traffic_light:start(r3j,{{r3,j},[{1055,418}]}),%%%%%%%%%%%%%%%%%%%
%  traffic_light:start(r3j,{{r3,j},[{1055,418},{1067, 426}]}),
  traffic_light:start(r4l,{{r4,l},[{625,820}]}),%%%%%%%%%%%%%%%%%%%%%%
%  traffic_light:start(r4l,{{r4,l},[{625,820},{634, 790}]}),
  traffic_light:start(r4m,{{r4,m},[{625,689}]}),%%%%%%%%%%%%%%%%%%%%%%%
%  traffic_light:start(r4m,{{r4,m},[{625,689},{418, 660}]}),
  traffic_light:start(r4h,{{r4,h},[{590,433}]}),%%%%%%%%%%%%%%%%%%%%%%%%%%
%  traffic_light:start(r4h,{{r4,h},[{590,433},{634, 426}]}),
  traffic_light:start(r4c,{{r4,c},[{625,154}]}),%%%%%%%%%%%%%%%%%%%%%%%%
%  traffic_light:start(r4c,{{r4,c},[{625,154},{634, 135}]}),
  traffic_light:start(r5k,{{r5,k},[{1058,640}]}),%%%%%%%%%%%%%%%%%%%%%%%%%
%  traffic_light:start(r5k,{{r5,k},[{1058,640},{1067, 660}]}),
  traffic_light:start(r6k,{{r6,k},[{1122,671}]}),%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  traffic_light:start(r6k,{{r6,k},[{1122,671},{1130, 660}]}),
  traffic_light:start(r6j,{{r6,j},[{1122,434}]}),%%%%%%%%%%%%%%%%%%%%%%%%
%  traffic_light:start(r6j,{{r6,j},[{1122,434},{1130, 426}]}),
  traffic_light:start(r6a,{{r6,a},[{1122,154}]}),%%%%%%%%%%%%%%%%%%%%%
%  traffic_light:start(r6a,{{r6,a},[{1122,154},{1130, 135}]}),
  traffic_light:start(r7l,{{r7,l},[{640,787}]}),%%%%%%%%%%%%%%%%%%%%%%%%%%
%  traffic_light:start(r7l,{{r7,l},[{640,787},{634, 710}]}),
  traffic_light:start(r8d,{{r8,d},[{266,154}]}),%%%%%%%%%%%%%%%%%%%%%%%
%  traffic_light:start(r8d,{{r8,d},[{266,154},{280, 135}]}),
  traffic_light:start(r9o,{{r9,o},[{80,655}]}),%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% traffic_light:start(r9o,{{r9,o},[{80,655},{75, 660}]}),
  traffic_light:start(r9n,{{r9,n},[{342,655}]}),%%%%%%%%%%%%%%%%%%%%%%%%%%5
%  traffic_light:start(r9n,{{r9,n},[{342,655},{571, 660}]}),
  traffic_light:start(r9m,{{r9,m},[{560,655}]}),%%%%%%%%%%%%%%%%%%%%%%
%  traffic_light:start(r9m,{{r9,m},[{560,655},{355, 660}]}),
  traffic_light:start(r10i,{{r10,i},[{763,355}]}),%%%%%%%%%%%%%%%%%%%%%%%%
%  traffic_light:start(r10i,{{r10,i},[{763,355},{713, 330}]}),
  ets:insert(junction,{{r12,p},[{902,590},nal]}),%%%%%%%%%%%%%%%%%%%%%%%%
%  ets:insert(junction,{{r12,p},[{902,590},nal,{nal,nal}]}),
  ets:insert(junction,{{r12,q},[{902,745},nal]}),%%%%%%%%%%%%%%%%%%%%%
%  ets:insert(junction,{{r12,q},[{902,745},nal,{nal,nal}]}),
  traffic_light:start(r14n,{{r14,n},[{407,670}]}),%%%%%%%%%%%%%%%%%%%%%%%
%  traffic_light:start(r14n,{{r14,n},[{407,670},{634, 660}]}),
  traffic_light:start(r14g,{{r14,g},[{407,433}]}),%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  traffic_light:start(r14g,{{r14,g},[{407,433},{418, 426}]}),
  traffic_light:start(r18b,{{r18,b},[{902,75}]}),%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  traffic_light:start(r18b,{{r18,b},[{902,66},{847, 35}]}),

  FirstKey = ets:first(junction),
  KeyList = keys(junction, FirstKey, [FirstKey]),
  spawn(sensors,traffic_light_sensor,[KeyList,ets:first(junction)]), % spawn traffic light sensor

  ets:new(comms,[set,public,named_table]), % initialize ets for communication towers and insert all of them
  communication_tower:start(com1_1,{1121,111}),
  communication_tower:start(com1_2,{850,105}),
  communication_tower:start(com1_3,{838,377}),
  communication_tower:start(com1_4,{1124,341}),
  communication_tower:start(com2_1,{550,123}),
  communication_tower:start(com2_2,{219,120}),
  communication_tower:start(com2_3,{197,374}),
  communication_tower:start(com2_4,{480,395}),
  communication_tower:start(com3_1,{589,557}),
  communication_tower:start(com3_2,{392,623}),
  communication_tower:start(com3_3,{157,632}),
  communication_tower:start(com3_4,{561,784}),
  communication_tower:start(com4_1,{1025,519}),
  communication_tower:start(com4_2,{868,717}),
  communication_tower:start(com4_3,{1121,707}),

  CarMonitor = spawn(sensors,car_monitor,[PC1,PC2,PC3,PC4]), % spawn car monitor
  put(car_monitor,CarMonitor),

  ets:new(sensors,[set,public,named_table]), % initialize sensors ets
  roadGraph(), % make graph for roads
  {ok, #state{}}.



%% Events
s_light(Comm,Who,{R,J}) -> gen_server:cast(?MODULE,{light,Comm,Who,{R,J}}). % car is close to junction
s_close_to_car(Comm,Who,OtherCar) -> gen_server:cast(?MODULE,{ctc,Comm,Who,OtherCar}). % car is close to another car
%car_finish_bypass(Comm,Who) -> case Comm of % car finished bypassing
%                                null -> cars:f_bypass(Who);
%                                 _-> communication_tower:receive_message(Comm,Who,{f_bypass})
%                              end.
%car_finish_turn(Comm,Who) -> % car finished turning
%  case Comm of
%    null -> cars:f_turn(Who);
%    _-> communication_tower:receive_message(Comm,Who,{f_turn})
%  end.
deleteCar(Pid)-> gen_server:cast(?MODULE,{del,Pid}). % delete car from ets
deletePid(Pid)-> gen_server:cast(?MODULE,{delP,Pid}). % kill pid
update_car_location() -> gen_server:call(?MODULE,update_car). % main requests car ets
start_car(Name,Type,Start,PC)-> gen_server:cast(?MODULE,{start_car,Name,Type,Start,PC}). % initialize car process
moved_car(Name,Type,Start,Location,Con,PC,Nev) -> gen_server:cast(?MODULE,{movedCar,Name,Type,Start,Location,Con,PC,Nev}). % car moved from one PC to another
update_monitor(PC) -> gen_server:cast(?MODULE,{nodedown,PC}). % update the car monitor that a PC is down
smoke(Car1,L1,Car2,L2)-> gen_server:cast(?MODULE,{smoke,Car1,L1,Car2,L2}).
deletesmoke(Pid) -> gen_server:cast(?MODULE,{delsmoke,Pid}).
print_light(X,Y) -> printTrafficLight(ets:first(junction),X,Y).
update_car_nev(Pid,Dest) -> ets:update_element(cars,Pid,[{8,Dest}]).
server_search_close_car(X,Y) -> gen_server:cast(?MODULE,{server_search_close_car,X,Y}).
server_search_close_junc(X,Y) -> gen_server:call(?MODULE,{server_search_close_junc,X,Y}).



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

handle_call(update_car, _, State) -> % return list of car ets to main
  Car = ets:tab2list(cars),
  {reply, {ok,Car}, State};

handle_call({server_search_close_junc,X,Y},_,State) ->
  Res = search_close_junc(ets:first(junction),{X,Y}),
  {reply, Res, State};


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

handle_cast({server_search_close_car,X,Y},State) ->
  io:format("KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK~n"),
  search_close_car(ets:first(cars),{X,Y}),

  {noreply, State};

handle_cast({smoke,Car1,L1,Car2,L2},State) -> % send message to car monitor about a nodedown
  rpc:call(get(home),main,start_smoke,[Car1,L1,Car2,L2]),
  {noreply, State};

handle_cast({delsmoke,Pid},State) -> % send message to car monitor about a nodedown
  rpc:call(get(home),main,del_smoke,[Pid]),
  {noreply, State};


handle_cast({nodedown,PC},State) -> % send message to car monitor about a nodedown
  Pid = get(car_monitor),
  Pid ! {nodedown,PC},
  {noreply, State};

handle_cast({del,Pid},State) -> % call main to delete car from ets and delete from local ets
  timer:sleep(320),
  % io:format("~p is alive? ~p~n",[Pid,is_process_alive(Pid)]) ,
  rpc:call(get(home),main,delete_car,[Pid]),
  ets:delete(cars,Pid),
  {noreply, State};

handle_cast({delP,Pid},State) -> % kill process with pid PID
  exit(Pid,kill),
%  io:format("~p is alive? ~p~n",[Pid,is_process_alive(Pid)]) ,
  {noreply, State};

handle_cast({movedCar,Name,Type,Start,Location,Con,PC,Nev},State) -> % start a car in local PC when it moved into range
  cars:start(Name,get(car_monitor),Type,Start,Location,Con,PC,Nev),
  {noreply, State};

handle_cast({light,Comm,Who,{_,J}}, State) -> % decide whether the car turns left, right or straight

  spawn(server,light,[get(graph),Comm,Who,J]),

%  List =  digraph:out_neighbours(get(graph),J), % get all possible directions the car can continue towards using digraph
%  [{_,[_,_,_,_,_],_,_,_,_,_,Nev}] = ets:lookup(cars,Who),% get the cars navigation status
%  case Nev of
%    null   -> E = lists:nth(rand:uniform(length(List)),List),% in case the navigation status is null or in_process, pick a random direction
%      {Dir, Road} = getEdgeLabel(get(graph),digraph:out_edges(get(graph),J),E),
%      case Comm of
%        null -> cars:turn(Who, {Dir, Road});
%        _-> communication_tower:receive_message(Comm,Who,{turn,{Dir, Road}})
%      end;

%    in_process -> E = lists:nth(rand:uniform(length(List)),List),
%      {Dir, Road} = getEdgeLabel(get(graph),digraph:out_edges(get(graph),J),E),
%      case Comm of
%        null -> cars:turn(Who, {Dir, Road});
%        _-> communication_tower:receive_message(Comm,Who,{turn,{Dir, Road}})
%      end;

%    Dest   -> if % in case the navigation status is a destination Junction and the car isn't reached its destination yet, find a trail
%                Dest /= J -> Trail = digraph:get_short_path(get(graph),J,Dest),io:format(" Trail : ~p~n",[Trail]),
%                  case Trail of
%                    false -> io:format("The trail isn't exists, pick a new junction"),ets:update_element(cars,Who,[{8,null}]), % in case the trail isn't exists, pick a random direction
%                      E = lists:nth(rand:uniform(length(List)),List),
%                      {Dir, Road} = getEdgeLabel(get(graph),digraph:out_edges(get(graph),J),E),
%                      case Comm of
%                        null -> cars:turn(Who, {Dir, Road});
%                        _-> communication_tower:receive_message(Comm,Who,{turn,{Dir, Road}})
%                      end;
%                    _->  Next = hd(tl(Trail)),% in case the trail is exists, get the next junction
%                      {Dir, Road} = getEdgeLabel(get(graph),digraph:out_edges(get(graph),J),Next),
%                      case Comm of
%                        null -> cars:turn(Who, {Dir, Road});
%                        _-> communication_tower:receive_message(Comm,Who,{turn,{Dir, Road}})
%                      end
%                  end;
%                true -> ets:update_element(cars,Who,[{8,null}]),io:format("~p is reached its destination~n",[Who]),% in case the car reached its destination, pick a random direction
%                 E = lists:nth(rand:uniform(length(List)),List),
%                 {Dir, Road} = getEdgeLabel(get(graph),digraph:out_edges(get(graph),J),E),
%                 case Comm of
%                    null -> cars:turn(Who, {Dir, Road});
%                   _-> communication_tower:receive_message(Comm,Who,{turn,{Dir, Road}})
%                  end
%              end
%  end,






%  E = lists:nth(rand:uniform(length(List)),List),
%  {Dir, Road} = getEdgeLabel(get(graph),digraph:out_edges(get(graph),J),E),


  % case Comm of
  %   null -> cars:turn(Who, {Dir, Road});
  %   _-> communication_tower:receive_message(Comm,Who,{turn,{Dir, Road}})
  % end,
  {noreply, State};


handle_cast({ctc,Comm,Who,OtherCar}, State) -> % decide whether the car bypasses the other car or stops

%  spawn(server,ctc,[Comm,Who,OtherCar]),
  Ans = ets:member(cars,Who),
  Ans2 =ets:member(cars,OtherCar),
  if
     Ans == true, Ans2 == true ->
  
  [{_,_,_,_,_,_,_,Nev}] = ets:lookup(cars,Who),
  Bool1 = checkBypass(Who,OtherCar,ets:first(cars)), % check if the car can bypass
  Bool2 = checkBypass2(Who,ets:first(junction)),

  if
    Nev == null; Nev == in_process  -> Bool3 = true ;
    true -> Bool3 = false
  end,
  case {Bool1,Bool2,Bool3} of
    {true,true,true} -> % if it can, bypass
      case Comm of
        null -> cars:bypass(Who);
        _-> communication_tower:receive_message(Comm,Who,{bypass})
      end;

    _ ->     case Comm of % if it can't, stop
               null -> cars:stop(Who,OtherCar);
               _-> communication_tower:receive_message(Comm,Who,{stop,OtherCar})
             end
  end,
  {noreply, State};
    true -> {noreply, State}
  end;

handle_cast({start_car,Name,Type,Start,PC},State) -> % starts car in local PC
  cars:start(Name,get(car_monitor),Type,Start,PC),
  {noreply, State};

handle_cast(Else,State) -> % starts car in local PC
 io:format("error in server: ~p~n",[Else]),
  {noreply, State}.


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

% this function checks if there is another car in front of the car he wants to bypass, and if there isn't, return true
checkBypass(_,_,'$end_of_table') -> true;
checkBypass(Who,OtherCar,FirstKey) -> [{_,[{X,Y},Dir1,R,_,_],_,_,_,_,_,_}] =  ets:lookup(cars,Who),
  [{P2,[{X2,Y2},_,R2,_,_],_,_,_,_,_,_}] = ets:lookup(cars,FirstKey),
  if
    R == R2, P2 /= Who, P2 /= OtherCar ->
      case Dir1 of % checks all cars that are going the same direction and same road
        left -> D = X-X2, if
                            D =< 200 , D >= 0 -> false;
                            true -> checkBypass(Who,OtherCar,ets:next(cars,P2))
                          end;

        right ->  D = X2-X, if
                              D =< 200 , D >= 0 -> false;
                              true -> checkBypass(Who,OtherCar,ets:next(cars,P2))
                            end;
        up ->  D = Y-Y2, if
                           D =< 200 , D >= 0 -> false;
                           true -> checkBypass(Who,OtherCar,ets:next(cars,P2))
                         end;
        down -> D = Y2-Y, if
                            D =< 200 , D >= 0 -> false;
                            true -> checkBypass(Who,OtherCar,ets:next(cars,P2))
                          end
      end;

    true -> checkBypass(Who,OtherCar,ets:next(cars,FirstKey))
  end.

% this function checks if there is a close junction when a car wants to bypass and if it can go straight if there is
checkBypass2(_,'$end_of_table') -> true;
checkBypass2(Who,Key) ->
  [{_,[{X,Y},Dir1,R,_,_],_,_,_,_,_,_}] =  ets:lookup(cars,Who),
  [{{R2,J},[{X2,Y2},_]}] = ets:lookup(junction,Key),
%  [{{R2,J},[{X2,Y2},_,{_,_}]}] = ets:lookup(junction,Key),
  case R == R2 of
    false -> checkBypass2(Who,ets:next(junction,Key));
    _ -> case Dir1 of % checks distance from junctions on the same road
           left -> D = X-X2, if

                               D >= 400  -> checkBypass2(Who,ets:next(junction,Key)); % if it's far, check the next junction
                               D >= 50 -> List =  digraph:out_neighbours(get(graph),J), % if it's close, check if it can go straight
                                 L = [getEdgeLabel(get(graph),digraph:out_edges(get(graph),J),E)||E <- List],
                                 L2 = [{Dir,Road}|| {Dir,Road} <- L, R==Road],
                                 case L2 of % if it can go straight, check next junction and if it can't, don't bypass
                                   [] -> false;
                                   _ -> checkBypass2(Who,ets:next(junction,Key))
                                 end;
                               D =< 0 -> checkBypass2(Who,ets:next(junction,Key));
                               true -> false % if junction is too close, don't bypass
                             end;

           right ->  D = X2-X, if
                                 D >= 400  -> checkBypass2(Who,ets:next(junction,Key));
                                 D >= 50 -> List =  digraph:out_neighbours(get(graph),J),
                                   L = [getEdgeLabel(get(graph),digraph:out_edges(get(graph),J),E)||E <- List],
                                   L2 = [{Dir,Road}|| {Dir,Road} <- L, R==Road],
                                   case L2 of
                                     [] -> false;
                                     _ -> checkBypass2(Who,ets:next(junction,Key))
                                   end;
                                 D =< 0 -> checkBypass2(Who,ets:next(junction,Key));
                                 true -> false
                               end;
           up ->  D = Y-Y2, if
                              D >= 400  -> checkBypass2(Who,ets:next(junction,Key));
                              D >= 50 -> List =  digraph:out_neighbours(get(graph),J),
                                L = [getEdgeLabel(get(graph),digraph:out_edges(get(graph),J),E)||E <- List],
                                L2 = [{Dir,Road}|| {Dir,Road} <- L, R==Road],
                                case L2 of
                                  [] -> false;
                                  _ -> checkBypass2(Who,ets:next(junction,Key))
                                end;
                              D =< 0 -> checkBypass2(Who,ets:next(junction,Key));
                              true ->false
                            end;
           down -> D = Y2-Y, if
                               D >= 400  -> checkBypass2(Who,ets:next(junction,Key));
                               D >= 50 -> List =  digraph:out_neighbours(get(graph),J),
                                 L = [getEdgeLabel(get(graph),digraph:out_edges(get(graph),J),E)||E <- List],
                                 L2 = [{Dir,Road}|| {Dir,Road} <- L, R==Road],
                                 case L2 of
                                   [] -> false;
                                   _ -> checkBypass2(Who,ets:next(junction,Key))
                                 end;
                               D =< 0 -> checkBypass2(Who,ets:next(junction,Key));
                               true ->false
                             end

         end
  end.

% this function creates a graph with junctions as nodes and roads as edges
roadGraph()->
  G =  digraph:new(),
  digraph:add_vertex(G,a),
  digraph:add_vertex(G,b),
  digraph:add_vertex(G,c),
  digraph:add_vertex(G,d),
  digraph:add_vertex(G,e),
  digraph:add_vertex(G,f),
  digraph:add_vertex(G,g),
  digraph:add_vertex(G,h),
  digraph:add_vertex(G,i),
  digraph:add_vertex(G,j),
  digraph:add_vertex(G,k),
  digraph:add_vertex(G,l),
  digraph:add_vertex(G,m),
  digraph:add_vertex(G,n),
  digraph:add_vertex(G,o),
  digraph:add_vertex(G,p),
  digraph:add_vertex(G,q),
  digraph:add_vertex(G,r),
  digraph:add_vertex(G,s),
  digraph:add_vertex(G,t),
  digraph:add_vertex(G,u),
  digraph:add_vertex(G,"out1"),
  digraph:add_vertex(G,"out4"),
  digraph:add_vertex(G,"out6"),
  digraph:add_vertex(G,"out3"),
  digraph:add_vertex(G,"out5"),
  digraph:add_vertex(G,"out12"),
  digraph:add_vertex(G,"out2"),
  digraph:add_vertex(G,"out16"),
  digraph:add_vertex(G,"in2"),
  digraph:add_vertex(G,"in6"),
  digraph:add_vertex(G,"in9"),
  digraph:add_vertex(G,"in14"),
  digraph:add_vertex(G,"in4"),
  digraph:add_vertex(G,"in6"),
  digraph:add_vertex(G,"in1"),
  digraph:add_vertex(G,"in18"),
  digraph:add_edge(G,a,b,{left,r1}),
  digraph:add_edge(G,a,"out6",{up,r6}),
  digraph:add_edge(G,b,t,{left,r1}),
  digraph:add_edge(G,t,i,{down,r10}),
  digraph:add_edge(G,t,c,{left,r1}),
  digraph:add_edge(G,c,"out4",{up,r4}),
  digraph:add_edge(G,c,s,{left,r1}),
  digraph:add_edge(G,s,"out16",{up,r16}),
  digraph:add_edge(G,s,d,{left,r1}),
  digraph:add_edge(G,d,e,{left,r1}),
  digraph:add_edge(G,e,"out1",{left,r1}),
  digraph:add_edge(G,e,f,{down,r2}),
  digraph:add_edge(G,f,r,{right,r3}),
  digraph:add_edge(G,f,o,{down,r2}),
  digraph:add_edge(G,r,g,{right,r3}),
  digraph:add_edge(G,r,d,{up,r8}),
  digraph:add_edge(G,g,h,{right,r3}),
  digraph:add_edge(G,h,i,{right,r3}),
  digraph:add_edge(G,h,l,{up,r4}),
  digraph:add_edge(G,i,u,{right,r3}),
  digraph:add_edge(G,u,j,{right,r3}),
  digraph:add_edge(G,u,p,{down,r12}),
  digraph:add_edge(G,j,"out3",{right,r3}),
  digraph:add_edge(G,j,a,{up,r6}),
  digraph:add_edge(G,k,j,{up,r6}),
  digraph:add_edge(G,k,"out5",{right,r5}),
  digraph:add_edge(G,p,k,{right,r5}),
  digraph:add_edge(G,p,q,{down,r12}),
  digraph:add_edge(G,q,l,{left,r7}),
  digraph:add_edge(G,q,"out12",{down,r12}),
  digraph:add_edge(G,l,m,{up,r4}),
  digraph:add_edge(G,m,h,{up,r4}),
  digraph:add_edge(G,n,m,{right,r9}),
  digraph:add_edge(G,n,g,{up,r14}),
  digraph:add_edge(G,o,n,{right,r9}),
  digraph:add_edge(G,o,"out2",{down,r2}),

  put(graph,G).

% this function gets the label from and edge which includes the direction and road
getEdgeLabel(_,[],_) -> io:format("error");
getEdgeLabel(G,[H|T],V) ->
  {_,_,V2,Label} = digraph:edge(G,H),
  case V == V2 of
    true -> Label;
    _ -> getEdgeLabel(G,T,V)
  end.

% this function gets all keys of ets
keys(_TableName, '$end_of_table', ['$end_of_table'|Acc]) ->
  Acc;
keys(TableName, CurrentKey, Acc) ->
  NextKey = ets:next(TableName, CurrentKey),
  keys(TableName, NextKey, [NextKey|Acc]).

% this function search a close traffic light, in case there is a close traffic light the function print the traffic light color
printTrafficLight('$end_of_table',_,_) ->io:format("there is no close traffic light ~n"),
  % io:format("the number of the traffic light is: ~p~n",[length(keys(junction,ets:first(junction),[]))]),
  ok;
printTrafficLight(Key,X,Y) ->
  [{_,[{XP,YP},LightPid]}] =  ets:lookup(junction,Key),
  case LightPid of
    nal-> printTrafficLight(ets:next(junction,Key),X,Y);
    _-> %D = math:sqrt(math:pow(X-(XP + 15),2) + math:pow(Y-(YP + 17),2)),
      D = math:sqrt(math:pow(X-XP ,2) + math:pow(Y-YP ,2)),
      if
        D =< 80 -> {C,_} =sys:get_state(LightPid),
          io:format("the color of the traffic light is: ~p~n",[C]);
%          io:format("the traffic light loction: ~p~n",[{XP,YP}]);
        true -> printTrafficLight(ets:next(junction,Key),X,Y)
      end
  end.

% this function search a close car, in case there is a close car the function update his ETS
search_close_car('$end_of_table',_)  -> io:format("error in nev, cant find close car~n");
search_close_car(Key,{X,Y}) ->  [{Pid,[{X2,Y2},_,_,_,_],_,_,_,_,_,_}] = ets:lookup(cars,Key),
  D = math:sqrt(math:pow(X-X2,2) + math:pow(Y-Y2,2)),
  if
    D =< 100 ->io:format("find a close car: ~p~n",[Key]),
      io:format("car state: ~p~n",[sys:get_state(Key)]),
      io:format("car ETS: ~p~n",[ets:lookup(cars,Key)]),
      ets:update_element(cars,Pid,[{8,in_process}]);
    true -> search_close_car(ets:next(cars,Key),{X,Y})
  end.

% this function search a close junction, in case there is a close junction the function return his name
search_close_junc('$end_of_table',_)  -> null;
search_close_junc(Key,{X,Y}) -> [{{_,J},[{XP,YP},_]}] =  ets:lookup(junction,Key),
  D = math:sqrt(math:pow(X-(XP-10),2) + math:pow(Y-(YP-10),2)),
  if
    D =< 100 -> J;
    true -> search_close_junc(ets:next(junction,Key),{X,Y})
  end.

% this function decides in which direction the car will continue and sends the response to the car
light(Graph,Comm,Who,J) ->   List =  digraph:out_neighbours(Graph,J), % get all possible directions the car can continue towards using digraph
  [{_,[_,_,_,_,_],_,_,_,_,_,Nev}] = ets:lookup(cars,Who),% get the cars navigation status
  case Nev of
    null   -> E = lists:nth(rand:uniform(length(List)),List),% in case the navigation status is null or in_process, pick a random direction
      {Dir, Road} = getEdgeLabel(Graph,digraph:out_edges(Graph,J),E),
      case Comm of
        null -> cars:turn(Who, {Dir, Road});
        _-> communication_tower:receive_message(Comm,Who,{turn,{Dir, Road}})
      end;

    in_process -> E = lists:nth(rand:uniform(length(List)),List),
      {Dir, Road} = getEdgeLabel(Graph,digraph:out_edges(Graph,J),E),
      case Comm of
        null -> cars:turn(Who, {Dir, Road});
        _-> communication_tower:receive_message(Comm,Who,{turn,{Dir, Road}})
      end;

    Dest   -> if % in case the navigation status is a destination Junction and the car isn't reached its destination yet, find a trail
                Dest /= J -> Trail = digraph:get_short_path(Graph,J,Dest),io:format(" Trail : ~p~n",[Trail]),
                  case Trail of
                    false -> io:format("The trail isn't exists, pick a new junction"),ets:update_element(cars,Who,[{8,null}]), % in case the trail isn't exists, pick a random direction
                      E = lists:nth(rand:uniform(length(List)),List),
                      {Dir, Road} = getEdgeLabel(Graph,digraph:out_edges(Graph,J),E),
                      case Comm of
                        null -> cars:turn(Who, {Dir, Road});
                        _-> communication_tower:receive_message(Comm,Who,{turn,{Dir, Road}})
                      end;
                    _->  Next = hd(tl(Trail)),% in case the trail is exists, get the next junction
                      {Dir, Road} = getEdgeLabel(Graph,digraph:out_edges(Graph,J),Next),
                      case Comm of
                        null -> cars:turn(Who, {Dir, Road});
                        _-> communication_tower:receive_message(Comm,Who,{turn,{Dir, Road}})
                      end
                  end;
                true -> ets:update_element(cars,Who,[{8,null}]),io:format("~p is reached its destination~n",[Who]),% in case the car reached its destination, pick a random direction
                  E = lists:nth(rand:uniform(length(List)),List),
                  {Dir, Road} = getEdgeLabel(Graph,digraph:out_edges(Graph,J),E),
                  case Comm of
                    null -> cars:turn(Who, {Dir, Road});
                    _-> communication_tower:receive_message(Comm,Who,{turn,{Dir, Road}})
                  end
              end
  end.

% this function checks if the car can bypass and sends a response to the car accordingly
ctc(Comm,Who,OtherCar) ->
  Bool1 = checkBypass(Who,OtherCar,ets:first(cars)), % check if the car can bypass
  Bool2 = checkBypass2(Who,ets:first(junction)),
  case {Bool1,Bool2} of
    {true,true} -> % if it can, bypass
      case Comm of
        null -> cars:bypass(Who);
        _-> communication_tower:receive_message(Comm,Who,{bypass})
      end;

    _ ->     case Comm of % if it can't, stop
               null -> cars:stop(Who,OtherCar);
               _-> communication_tower:receive_message(Comm,Who,{stop,OtherCar})
             end
  end.
