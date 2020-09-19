%%%-------------------------------------------------------------------
%%% @author Maayan Belzer, Nir Tapiero
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. Jul 2020 1:57 AM
%%%-------------------------------------------------------------------
-module(main).
-author("Maayan Belzer, Nir Tapiero").


-behaviour(wx_object).
-include_lib("wx/include/wx.hrl").
-include("header.hrl").
-export([start/0,init/1,handle_event/2,handle_sync_event/3,handle_info/2,delete_car/1,handle_cast/2,
  update_ets/1,list_to_ets/1]).
-define(max_x, 1344).
-define(max_y,890).
-define(Timer,67).

-define(SERVER, ?MODULE).
-record(state, {frame, panel, dc, paint, list,bmpRmap,bmpCar1,bmpCar2,bmpTruck,bmpAntenna,bmpTrafficLight ,bmpTrafficLightGreen ,bmpTrafficLightRed ,bmpCommTower,key}).
%%%-------------------------------------------------------------------

start() ->
  wx_object:start({local,?SERVER},?MODULE,[],[]).

init([]) ->
  ets:new(cars,[set,public,named_table]), % initialize car ets
  net_kernel:monitor_nodes(true), % monitor nodes
  timer:sleep(200),
  net_kernel:connect_node(?PC1), % connect all nodes
  timer:sleep(200),
  net_kernel:connect_node(?PC2),
  timer:sleep(200),
  net_kernel:connect_node(?PC3),
  timer:sleep(200),
  net_kernel:connect_node(?PC4),
  timer:sleep(200),

  put(?PC1,?PC1), % put all PCs in process dictionary
  put(?PC2,?PC2),
  put(?PC3,?PC3),
  put(?PC4,?PC4),

  % graphics
  WxServer = wx:new(),
  Frame = wxFrame:new(WxServer, ?wxID_ANY, "MAP", [{size,{?max_x, ?max_y}}]),
  Panel  = wxPanel:new(Frame),
  DC=wxPaintDC:new(Panel),
  Paint = wxBufferedPaintDC:new(Panel),
  % create bitmap to all images
  {BmpRmap,BmpCar1,BmpCar2,BmpTruck,BmpAntenna,BmpTrafficLight,BmpTrafficLightGreen,BmpTrafficLightRed,BmpCommTower}=createBitMaps(),


  % connect panel
  wxFrame:show(Frame),
  erlang:send_after(?Timer, self(), timer),




  wxPanel:connect(Panel, paint, [callback]),
  wxPanel:connect (Panel, left_down),
%  wxPanel:connect (Panel, right_down),
  wxFrame:connect(Frame, close_window),

  % start all servers
  {ok,_}=rpc:call(?PC1,server,start,[?PC1,?PC2,?PC3,?PC4,?Home]),
  {ok,_}=rpc:call(?PC2,server,start,[?PC1,?PC2,?PC3,?PC4,?Home]),
  {ok,_}=rpc:call(?PC3,server,start,[?PC1,?PC2,?PC3,?PC4,?Home]),
  {ok,_}=rpc:call(?PC4,server,start,[?PC1,?PC2,?PC3,?PC4,?Home]),

  % start all cars
  rpc:call(?PC1,server,start_car,[f,20,[{1344,93},left,r1,red,st],?PC1]),
  rpc:call(?PC1,server,start_car,[a,10,[{874,0},down,r18,red,st],?PC1]),
  rpc:call(?PC2,server,start_car,[e,10,[{101,0},down,r2,red,st],?PC2]),
  rpc:call(?PC2,server,start_car,[g,10,[{0,417},right,r3,red,st],?PC2]),
  rpc:call(?PC3,server,start_car,[b,20,[{0,651},right,r9,grey,st],?PC3]),
  rpc:call(?PC3,server,start_car,[c,10,[{405,890},up,r14,grey,st],?PC3]),
  rpc:call(?PC3,server,start_car,[d,20,[{623,890},up,r4,red,st],?PC3]),
  rpc:call(?PC1,server,start_car,[h,20,[{1117,890},up,r6,red,st],?PC1]),

%  {Frame,#state{frame = Frame, panel = Panel, dc=DC, paint = Paint,
%    bmpRmap = BmpRmap,bmpCar1 =BmpCar1 ,bmpCar2 = BmpCar2,
%    bmpTruck = BmpTruck,bmpAntenna = BmpAntenna,bmpTrafficLight = BmpTrafficLight }}.
  {Frame,#state{frame = Frame, panel = Panel, dc=DC, paint = Paint,
    bmpRmap = BmpRmap,bmpCar1 =BmpCar1 ,bmpCar2 = BmpCar2,

    bmpTruck = BmpTruck,bmpAntenna = BmpAntenna,bmpTrafficLight = BmpTrafficLight,bmpTrafficLightGreen = BmpTrafficLightGreen,bmpTrafficLightRed = BmpTrafficLightRed,bmpCommTower = BmpCommTower}}.

%%%-------------------------------------------------------------------

handle_event(#wx{event = #wxClose{}},State = #state {frame = Frame}) -> % close window event
  io:format("Exiting\n"),
  wxWindow:destroy(Frame),
  wx:destroy(),
  {stop,normal,State};

handle_event(#wx{event = #wxMouse{type=left_down, x=X, y=Y}},State) ->
  io:format("~p~n", [{X,Y}]),
  search_close_car(ets:first(cars),{X,Y}),
%  search_close_junction(ets:first(junction),{X,Y}),
  {noreply,State}.

handle_sync_event(#wx{event=#wxPaint{}}, _,  _State = #state{
  panel = Panel,
  bmpRmap = BmpRmap,bmpCar1 =BmpCar1 ,bmpCar2 = BmpCar2,
  bmpTruck = BmpTruck,bmpTrafficLight = BmpTrafficLight,
  bmpCommTower = BmpCommTower}) ->


  DC2=wxPaintDC:new(Panel),
  wxDC:clear(DC2),
  wxDC:drawBitmap(DC2,BmpRmap,{0,0}),

  % draw all traffic lights
%  DrawTrafficA1 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficA1, BmpTrafficLight, {1130, 35}),
%  DrawTrafficA2 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficA2, BmpTrafficLight, {1130, 135}),
%  DrawTrafficB1 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficB1, BmpTrafficLight, {847, 35}),
%  DrawTrafficB2 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficB2, BmpTrafficLight, {917, 35}),
%  DrawTrafficC1 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficC1, BmpTrafficLight, {634, 35}),
%  DrawTrafficC2 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficC2, BmpTrafficLight, {634, 135}),
%  DrawTrafficD1 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficD1, BmpTrafficLight, {280, 35}),
%  DrawTrafficD2 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficD2, BmpTrafficLight, {280, 135}),
%  DrawTrafficE1 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficE1, BmpTrafficLight, {138, 35}),
%  DrawTrafficE2 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficE2, BmpTrafficLight, {75, 35}),
%  DrawTrafficF1 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficF1, BmpTrafficLight, {75, 330}),
%  DrawTrafficF2 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficF2, BmpTrafficLight, {75, 426}),
%  DrawTrafficG1 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficG1, BmpTrafficLight, {355, 426}),
%  DrawTrafficG2 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficG2, BmpTrafficLight, {418, 426}),
%  DrawTrafficH1 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficH1, BmpTrafficLight, {571, 426}),
%  DrawTrafficH2 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficH2, BmpTrafficLight, {634, 426}),
%  DrawTrafficI1 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficI1, BmpTrafficLight, {713, 330}),
%  DrawTrafficI2 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficI2, BmpTrafficLight, {713, 420}),
%  DrawTrafficJ1 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficJ1, BmpTrafficLight, {1067, 426}),
%  DrawTrafficJ2 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficJ2, BmpTrafficLight, {1130, 426}),
%  DrawTrafficK1 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficK1, BmpTrafficLight, {1067, 660}),
%  DrawTrafficK2 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficK2, BmpTrafficLight, {1130, 660}),
%  DrawTrafficL1 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficL1, BmpTrafficLight, {634, 710}),
%  DrawTrafficL2 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficL2, BmpTrafficLight, {634, 790}),
%  DrawTrafficM1 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficM1, BmpTrafficLight, {355, 660}),
%  DrawTrafficM2 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficM2, BmpTrafficLight, {418, 660}),
%  DrawTrafficN1 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficN1, BmpTrafficLight, {571, 660}),
%  DrawTrafficN2 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficN2, BmpTrafficLight, {634, 660}),
%  DrawTrafficO1 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficO1, BmpTrafficLight, {75, 575}),
%  DrawTrafficO2 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawTrafficO2, BmpTrafficLight, {75, 660}),

  % draw all communication towers
%  DrawComm1 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawComm1, BmpCommTower, {1036, 38}),
%  DrawComm2 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawComm2, BmpCommTower, {793, 38}),
%  DrawComm3 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawComm3, BmpCommTower, {822, 336}),
%  DrawComm4 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawComm4, BmpCommTower, {1200, 336}),
%  DrawComm5 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawComm5, BmpCommTower, {483, 38}),
%  DrawComm6 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawComm6, BmpCommTower, {180, 38}),
%  DrawComm7 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawComm7, BmpCommTower, {483, 336}),
%  DrawComm8 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawComm8, BmpCommTower, {180, 336}),
%  DrawComm9 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawComm9, BmpCommTower, {20, 580}),
%  DrawComm10 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawComm10, BmpCommTower, {255, 580}),
%  DrawComm11 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawComm11, BmpCommTower, {547, 523}),
%  DrawComm12 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawComm12, BmpCommTower, {547, 763}),
%  DrawComm13 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawComm13, BmpCommTower, {817, 711}),
%  DrawComm14 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawComm14, BmpCommTower, {988, 550}),
%  DrawComm15 = wxClientDC:new(Panel),
%  wxDC:drawBitmap(DrawComm15, BmpCommTower, {1151, 743}),

%  printTtafficLight(ets:first(junction),Panel,BmpTrafficLight,BmpTrafficLightGreen,BmpTrafficLightRed),

  printCars(ets:first(cars),Panel,BmpCar1,BmpCar2,BmpTruck);

handle_sync_event(_Event,_,State) ->
  {noreply, State}.

%printTtafficLight('$end_of_table',_,_,_,_) -> ok;
%printTtafficLight(Key,Panel,BmpTrafficLight,BmpTrafficLightGreen,BmpTrafficLightRed) ->
%  [{{_,_},[{_,_},LightPid,{XP,YP}]}] =  ets:lookup(junction,Key),
%  case LightPid of
%    nal-> printTtafficLight(ets:next(junction,Key),Panel,BmpTrafficLight,BmpTrafficLightGreen,BmpTrafficLightRed);
%    _-> case sys:get_state(LightPid) of
%          {green,_} ->DrawTraffic = wxClientDC:new(Panel),
%            wxDC:drawBitmap(DrawTraffic, BmpTrafficLightGreen, {XP,YP}),
%            printTtafficLight(ets:next(junction,Key),Panel,BmpTrafficLight,BmpTrafficLightGreen,BmpTrafficLightRed) ;

%          {red,_} ->DrawTraffic = wxClientDC:new(Panel),
%            wxDC:drawBitmap(DrawTraffic, BmpTrafficLightRed, {XP,YP}),
%            printTtafficLight(ets:next(junction,Key),Panel,BmpTrafficLight,BmpTrafficLightGreen,BmpTrafficLightRed) ;

%          _->DrawTraffic = wxClientDC:new(Panel),
%            wxDC:drawBitmap(DrawTraffic, BmpTrafficLight,{XP,YP}),
%            printTtafficLight(ets:next(junction,Key),Panel,BmpTrafficLight,BmpTrafficLightGreen,BmpTrafficLightRed)
%end
%end.

printCars('$end_of_table',_,_,_,_) -> ok; % this function paints all of the cars
printCars(Key,Panel,BmpCar1,BmpCar2,BmpTruck) ->
  [{_,[{A,B},D,_,Type,_],_,_,_,_,_}] = ets:lookup(cars,Key),
  DI =wxClientDC:new(Panel),
  case Type of
    red -> case D of
             left -> wxDC:drawBitmap(DI, BmpCar1, {A, B});
             down -> Im = wxBitmap:convertToImage(BmpCar1), Im2 = wxImage:rotate(Im,-300,{A,B}),
               BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B});
             right -> Im = wxBitmap:convertToImage(BmpCar1), Im2 = wxImage:rotate(Im,600,{A,B}),
               BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B});
             up -> Im = wxBitmap:convertToImage(BmpCar1), Im2 = wxImage:rotate(Im,300,{A,B}),
               BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B})
           end;
    grey -> case D of
              left -> wxDC:drawBitmap(DI, BmpCar2, {A, B});
              down -> Im = wxBitmap:convertToImage(BmpCar2), Im2 = wxImage:rotate(Im,-300,{A,B}),
                BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B});
              right -> Im = wxBitmap:convertToImage(BmpCar2), Im2 = wxImage:rotate(Im,600,{A,B}),
                BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B});
              up -> Im = wxBitmap:convertToImage(BmpCar2), Im2 = wxImage:rotate(Im,300,{A,B}),
                BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B})
            end;
    truck ->  case D of
                left -> wxDC:drawBitmap(DI, BmpTruck, {A, B});
                down -> Im = wxBitmap:convertToImage(BmpTruck), Im2 = wxImage:rotate(Im,-300,{A,B}),
                  BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B});
                right -> Im = wxBitmap:convertToImage(BmpTruck), Im2 = wxImage:rotate(Im,600,{A,B}),
                  BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B});
                up -> Im = wxBitmap:convertToImage(BmpTruck), Im2 = wxImage:rotate(Im,300,{A,B}),
                  BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B})
              end
  end,

  printCars(ets:next(cars,Key),Panel,BmpCar1,BmpCar2,BmpTruck).



handle_info(timer, State=#state{frame = Frame}) ->  % refresh screen for graphics

  spawn(main,update_ets,[get(?PC1)]),
  spawn(main,update_ets,[get(?PC2)]),
  spawn(main,update_ets,[get(?PC3)]),
  spawn(main,update_ets,[get(?PC4)]),
 % update_ets(get(?PC1)),
 % update_ets(get(?PC2)),
 % update_ets(get(?PC3)),
 % update_ets(get(?PC4)),

  wxWindow:refresh(Frame),
  erlang:send_after(?Timer,self(),timer),
  {noreply, State};

handle_info({nodeup,PC},State)->
  io:format("~p nodeup ~n",[PC]),
  {noreply, State};

handle_info({nodedown,PC},State)-> % if a node is down check which PC, move responsibilities to different PC and update monitors
  io:format("~p nodedown ~n",[PC]),
  case PC of
    ?PC1 -> backup_pc(?PC1,get(?PC2)),
      rpc:call(get(?PC2),server,update_monitor,[pc_1]),
      rpc:call(get(?PC3),server,update_monitor,[pc_1]),
      rpc:call(get(?PC4),server,update_monitor,[pc_1]),
      move_car(?PC1,ets:first(cars))     ;

    ?PC2 ->backup_pc(?PC2,get(?PC3)),
      rpc:call(get(?PC1),server,update_monitor,[pc_2]),
      rpc:call(get(?PC3),server,update_monitor,[pc_2]),
      rpc:call(get(?PC4),server,update_monitor,[pc_2]),
      move_car(?PC2,ets:first(cars));

    ?PC3 ->backup_pc(?PC3,get(?PC4)),
      rpc:call(get(?PC2),server,update_monitor,[pc_3]),
      rpc:call(get(?PC1),server,update_monitor,[pc_3]),
      rpc:call(get(?PC4),server,update_monitor,[pc_3]),
      move_car(?PC3,ets:first(cars));

    ?PC4 ->backup_pc(?PC4,get(?PC1)),
      rpc:call(get(?PC2),server,update_monitor,[pc_4]),
      rpc:call(get(?PC3),server,update_monitor,[pc_4]),
      rpc:call(get(?PC1),server,update_monitor,[pc_4]),
      move_car(?PC4,ets:first(cars))

  end,

  {noreply, State}.

handle_cast({delete_car, Pid},State) -> % delete car from ets
  ets:delete(cars,Pid),
  {noreply,State}.

createBitMaps() ->         % create bitmap to all images
  Rmap = wxImage:new("rmap.jpg"),
  Rmapc = wxImage:scale(Rmap,?max_x,?max_y),
  BmpRmap = wxBitmap:new(Rmapc),
  wxImage:destroy(Rmap),
  wxImage:destroy(Rmapc),

  Car1 = wxImage:new("car1.png"),
  Car1c = wxImage:scale(Car1,45,25),
  BmpCar1 = wxBitmap:new(Car1c),
  wxImage:destroy(Car1),
  wxImage:destroy(Car1c),

  Car2 = wxImage:new("car2.png"),
  Car2c = wxImage:scale(Car2,43,25),
  BmpCar2 = wxBitmap:new(Car2c),
  wxImage:destroy(Car2),
  wxImage:destroy(Car2c),

  Truck = wxImage:new("truck.png"),
  Truckc = wxImage:scale(Truck,170,15),
  BmpTruck = wxBitmap:new(Truckc),
  wxImage:destroy(Truck),
  wxImage:destroy(Truckc),


  Antenna = wxImage:new("antenna.png"),
  Antennac = wxImage:scale(Antenna,40,50),
  BmpAntenna = wxBitmap:new(Antennac),
  wxImage:destroy(Antenna),
  wxImage:destroy(Antennac),

  TrafficLight = wxImage:new("trafficLight2.png"),
%  TrafficLight = wxImage:new("trafficLightYellow.png"),
  TrafficLightc = wxImage:scale(TrafficLight,40,50),
  BmpTrafficLight = wxBitmap:new(TrafficLightc),
  wxImage:destroy(TrafficLight),
  wxImage:destroy(TrafficLightc),

  TrafficLightG = wxImage:new("trafficLightGreen.png"),
  TrafficLightcG = wxImage:scale(TrafficLightG,40,50),
  BmpTrafficLightGreen = wxBitmap:new(TrafficLightcG),
  wxImage:destroy(TrafficLightG),
  wxImage:destroy(TrafficLightcG),

  TrafficLightR = wxImage:new("trafficLightRed.png"),
  TrafficLightcR = wxImage:scale(TrafficLightR,40,50),
  BmpTrafficLightRed = wxBitmap:new(TrafficLightcR),
  wxImage:destroy(TrafficLightR),
  wxImage:destroy(TrafficLightcR),

  CommTower = wxImage:new("comm.png"),
  CommTowerc = wxImage:scale(CommTower,40,50),
  BmpCommTower = wxBitmap:new(CommTowerc),
  wxImage:destroy(CommTower),
  wxImage:destroy(CommTowerc),

  {BmpRmap,BmpCar1,BmpCar2,BmpTruck,BmpAntenna,BmpTrafficLight,BmpTrafficLightGreen,BmpTrafficLightRed,BmpCommTower}.

% this function prints a car pid and state if user clicked on it
search_close_car('$end_of_table',_) ->io:format("there is no close car ~n") ,ok;
search_close_car(Key,{X,Y}) ->
  [{_,[{X2,Y2},_,_,_,_],_,_,_,_,_}] = ets:lookup(cars,Key),
  D = math:sqrt(math:pow(X-X2,2) + math:pow(Y-Y2,2)),
  if

    D =< 40 -> io:format("~p~n",[Key]),io:format("~p~n",[sys:get_state(Key)]), ok;

    true-> search_close_car(ets:next(cars,Key),{X,Y})
  end.

%search_close_junction('$end_of_table',_) ->io:format("there is no close junction ~n") ,ok;
%search_close_junction(Key,{X,Y}) ->
%  [{{R,J},[{X2,Y2},_]}] =  ets:lookup(junction,Key),
%  D = math:sqrt(math:pow(X-X2,2) + math:pow(Y-Y2,2)),
%  if
%    D =< 70 -> io:format("~p~n",[{R,J}]), ok;
%    true-> search_close_junction(ets:next(junction,Key),{X,Y})
%  end.

% this function requests the ets from each server and calls to function to update ets
update_ets(PC) ->
  List=
    try
      rpc:call(PC,server,update_car_location,[])
    catch _:_ -> problem
    end,
  case List of
    problem -> ok;
    {ok, List1} -> list_to_ets(List1);
    Else-> io:format("there is a problem~n"),io:format("~p~n",[Else]),
      ok
  end.

% this function adds the ets received to main ets
list_to_ets('$end_of_table') ->
  ok;
list_to_ets(List) ->
  lists:foreach(fun(Key_Value) -> ets:insert(cars, Key_Value) end, List).


delete_car(Pid) -> wx_object:cast(main,{delete_car, Pid}). % create delete car event

% this function checks which PC is down and moves all car from fallen PC to new PC
move_car(_,'$end_of_table') -> ok;
move_car(PcDown,Key) ->
  [{_,Location,Name,Start,Type,Con,PC}] = ets:lookup(cars,Key),

  case PcDown of
    ?PC1 -> if
              PC == ?PC1  -> rpc:call(?PC2,server,moved_car,[Name,Type,Start,Location,Con,?PC2]), % call to function in server
                Next = ets:next(cars,Key), % get next car
                ets:delete(cars,Key), % delete car from ets
                move_car(PcDown,Next) ; % move next car
              true ->move_car(PcDown,ets:next(cars,Key))
            end;

    ?PC2 -> if

              PC == ?PC2 -> rpc:call(?PC3,server,moved_car,[Name,Type,Start,Location,Con,?PC3]),
                Next = ets:next(cars,Key),
                ets:delete(cars,Key),
                move_car(PcDown,Next);
              true -> move_car(PcDown,ets:next(cars,Key))
            end;

    ?PC3 -> if

              PC == ?PC3 -> rpc:call(?PC4,server,moved_car,[Name,Type,Start,Location,Con,?PC4]),
                Next = ets:next(cars,Key),
                ets:delete(cars,Key),
                move_car(PcDown,Next) ;
              true -> move_car(PcDown,ets:next(cars,Key))
            end;

    ?PC4 -> if

              PC == ?PC4 -> rpc:call(?PC1,server,moved_car,[Name,Type,Start,Location,Con,?PC1]),
                Next = ets:next(cars,Key),
                ets:delete(cars,Key),
                move_car(PcDown,Next) ;
              true -> move_car(PcDown,ets:next(cars,Key))
            end
  end.

% this function which PCs are combined
backup_pc(PCDown,NewPC) ->
  L = [?PC1,?PC2,?PC3,?PC4],
  L2 = [PC||PC <-L, get(PC) == PCDown], io:format("~p~n",[L2]),
  Fun = fun(E) -> put(E,NewPC) end,
  lists:foreach(Fun,L2), ok.

