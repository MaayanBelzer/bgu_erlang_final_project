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
  update_ets/2,list_to_ets/1,start_smoke/4,del_smoke/1,main_navigation/6,check_cars/1,
  main_cars_mon/5,check_PC/6,server_down/1,main_search_close_car/2]).
-define(max_x, 1344).
-define(max_y,890).
-define(Timer,67).

-define(SERVER, ?MODULE).
-record(state, {frame, panel, dc, paint, list,bmpRmap,bmpCar1,bmpCar2,bmpCar3,bmpAntenna,bmpTrafficLight ,bmpTrafficLightGreen ,bmpTrafficLightRed ,bmpCommTower,key,bmpsmoke,bmpCar1b,bmpCar2b,
  bmpCar3b}).
%%%-------------------------------------------------------------------

start() ->
  wx_object:start({local,?SERVER},?MODULE,[],[]).

init([]) ->
  ets:new(cars,[set,public,named_table]), % initialize car ets
  ets:new(smoke,[set,public,named_table]),
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
  {BmpRmap,BmpCar1,BmpCar2,BmpCar3,BmpAntenna,BmpTrafficLight,BmpTrafficLightGreen,BmpTrafficLightRed,BmpCommTower,BmpSmoke,BmpCar1b,BmpCar2b,BmpCar3b}=createBitMaps(),


  % connect panel
  wxFrame:show(Frame),
  erlang:send_after(?Timer, self(), timer),




  wxPanel:connect(Panel, paint, [callback]),
  wxPanel:connect (Panel, left_down),
  wxPanel:connect (Panel, right_down),
  wxFrame:connect(Frame, close_window),

  % start all servers
  rpc:call(?PC1,server,start,[?PC1,?PC2,?PC3,?PC4,?Home]),
  rpc:call(?PC2,server,start,[?PC1,?PC2,?PC3,?PC4,?Home]),
  rpc:call(?PC3,server,start,[?PC1,?PC2,?PC3,?PC4,?Home]),
  rpc:call(?PC4,server,start,[?PC1,?PC2,?PC3,?PC4,?Home]),

  % start all cars
  rpc:call(?PC1,server,start_car,[f,20,[{1344,93},left,r1,yellow,st],?PC1]),
  rpc:call(?PC1,server,start_car,[a,10,[{874,0},down,r18,grey,st],?PC1]),
  rpc:call(?PC2,server,start_car,[e,10,[{101,0},down,r2,yellow,st],?PC2]),
  rpc:call(?PC2,server,start_car,[g,10,[{0,417},right,r3,red,st],?PC2]),
  rpc:call(?PC3,server,start_car,[b,20,[{0,651},right,r9,grey,st],?PC3]),
  rpc:call(?PC3,server,start_car,[c,10,[{405,890},up,r14,grey,st],?PC3]),
  rpc:call(?PC3,server,start_car,[d,20,[{623,890},up,r4,red,st],?PC3]),
  rpc:call(?PC1,server,start_car,[h,20,[{1117,890},up,r6,red,st],?PC1]),

% spawn the car monitor
  spawn(main,main_cars_mon,[ets:first(cars),?PC1,?PC2,?PC3,?PC4]),

  {Frame,#state{frame = Frame, panel = Panel, dc=DC, paint = Paint,
    bmpRmap = BmpRmap,bmpCar1 =BmpCar1 ,bmpCar2 = BmpCar2,
    bmpCar3 = BmpCar3,bmpAntenna = BmpAntenna,bmpTrafficLight = BmpTrafficLight,bmpTrafficLightGreen = BmpTrafficLightGreen,bmpTrafficLightRed = BmpTrafficLightRed,bmpCommTower = BmpCommTower, bmpsmoke= BmpSmoke
    ,bmpCar1b =BmpCar1b ,bmpCar2b = BmpCar2b,
    bmpCar3b = BmpCar3b}}.

%%%-------------------------------------------------------------------

handle_event(#wx{event = #wxClose{}},State = #state {frame = Frame}) -> % close window event
  io:format("Exiting\n"),
  wxWindow:destroy(Frame),
  wx:destroy(),
  {stop,normal,State};

handle_event(#wx{event = #wxMouse{type=left_down, x=X, y=Y}},State) ->

  % main_navigation(X,Y,get(?PC1),get(?PC2),get(?PC3),get(?PC4)),
  spawn(main,main_navigation,[X,Y,get(?PC1),get(?PC2),get(?PC3),get(?PC4)]),



%  if
%    X >= 780, Y =< 472 -> rpc:call(get(?PC1),server,navigation,[X,Y]);
%    X >= 780, Y >= 472 -> rpc:call(get(?PC4),server,navigation,[X,Y]);
%    X =< 780, Y =< 472 -> rpc:call(get(?PC2),server,navigation,[X,Y]);
%    X =< 780, Y >= 472 -> rpc:call(get(?PC3),server,navigation,[X,Y]);
%    true -> error
%  end,

  io:format("~p~n", [{X,Y}]),
%  search_close_car(ets:first(cars),{X,Y}),
%  search_close_junction(ets:first(junction),{X,Y}),
  {noreply,State};

handle_event(#wx{event = #wxMouse{type=right_down, x=X, y=Y}},State) ->
  io:format("~p~n", [{X,Y}]),
  if
    X >= 780, Y =< 472 -> rpc:call(get(?PC1),server,print_light,[X,Y]);
    X >= 780, Y >= 472 -> rpc:call(get(?PC4),server,print_light,[X,Y]);
    X =< 780, Y =< 472 -> rpc:call(get(?PC2),server,print_light,[X,Y]);
    X =< 780, Y >= 472 -> rpc:call(get(?PC3),server,print_light,[X,Y]);
    true -> error
  end,

  {noreply,State}.

handle_sync_event(#wx{event=#wxPaint{}}, _,  _State = #state{
  panel = Panel,
  bmpRmap = BmpRmap,bmpCar1 =BmpCar1 ,bmpCar2 = BmpCar2,
  bmpCar3 = BmpCar3,
  %bmpTrafficLight = BmpTrafficLight,
  %bmpCommTower = BmpCommTower,
  bmpsmoke = BmpSmoke
  ,bmpCar1b =BmpCar1b ,bmpCar2b = BmpCar2b,
  bmpCar3b = BmpCar3b}) ->


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

  printCars(ets:first(cars),Panel,BmpCar1,BmpCar2,BmpCar3,BmpCar1b,BmpCar2b,BmpCar3b),
  printsmoke(ets:first(smoke),Panel,BmpSmoke);

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

printsmoke('$end_of_table',_,_) -> ok; % this function paints all of the cars
printsmoke(Key,Panel,BmpSmoke) ->
  DI =wxClientDC:new(Panel),
  case ets:member(smoke,Key) of
    true -> [{_,{A,B}}] = ets:lookup(smoke,Key),
      wxDC:drawBitmap(DI, BmpSmoke, {A - 10, B - 10}),
      printsmoke(ets:next(smoke,Key),Panel,BmpSmoke);
    _-> printsmoke(ets:first(smoke),Panel,BmpSmoke)
  end.
%  [{_,{A,B}}] = ets:lookup(smoke,Key),
%  wxDC:drawBitmap(DI, BmpSmoke, {A - 10, B - 10}).


printCars('$end_of_table',_,_,_,_,_,_,_) -> ok; % this function paints all of the cars
printCars(Key,Panel,BmpCar1,BmpCar2,BmpCar3,BmpCar1b,BmpCar2b,BmpCar3b) ->
  [{_,[{A,B},D,_,Type,_],_,_,_,_,PC,Nev}] = ets:lookup(cars,Key),
  DI =wxClientDC:new(Panel),
  case Type of
    red -> case D of
             left -> case Nev of
                       null-> wxDC:drawBitmap(DI, BmpCar1, {A, B});
                       _->   wxDC:drawBitmap(DI, BmpCar1b, {A, B})
                     end;

             down ->case Nev of
                      null-> Im = wxBitmap:convertToImage(BmpCar1), Im2 = wxImage:rotate(Im,-300,{A,B}),
                        BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B});
                      _-> Im = wxBitmap:convertToImage(BmpCar1b), Im2 = wxImage:rotate(Im,-300,{A,B}),
                        BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B})
                    end;

             right ->case Nev of
                       null-> Im = wxBitmap:convertToImage(BmpCar1), Im2 = wxImage:rotate(Im,600,{A,B}),
                         BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B});
                       _->  Im = wxBitmap:convertToImage(BmpCar1b), Im2 = wxImage:rotate(Im,600,{A,B}),
                         BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B})
                     end;

             up ->case Nev of
                    null-> Im = wxBitmap:convertToImage(BmpCar1), Im2 = wxImage:rotate(Im,300,{A,B}),
                      BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B});
                    _-> Im = wxBitmap:convertToImage(BmpCar1b), Im2 = wxImage:rotate(Im,300,{A,B}),
                      BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B})
                  end;


             Error -> io:format("error in printCars, D = ~p~n",[Error]),
               io:format("cars ets inf: ~p~n",[ets:lookup(cars,Key)]),
               io:format("cars state inf: ~p~n",[rpc:call(PC, sys, get_state, [Key])]),
               ets:delete(cars,Key)
           end;
    grey -> case D of
              left -> case Nev of
                        null-> wxDC:drawBitmap(DI, BmpCar2, {A, B});
                        _->   wxDC:drawBitmap(DI, BmpCar2b, {A, B})
                      end;

              down ->case Nev of
                       null-> Im = wxBitmap:convertToImage(BmpCar2), Im2 = wxImage:rotate(Im,-300,{A,B}),
                         BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B});
                       _-> Im = wxBitmap:convertToImage(BmpCar2b), Im2 = wxImage:rotate(Im,-300,{A,B}),
                         BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B})
                     end;

              right ->case Nev of
                        null-> Im = wxBitmap:convertToImage(BmpCar2), Im2 = wxImage:rotate(Im,600,{A,B}),
                          BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B});
                        _->  Im = wxBitmap:convertToImage(BmpCar2b), Im2 = wxImage:rotate(Im,600,{A,B}),
                          BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B})
                      end;

              up ->case Nev of
                     null-> Im = wxBitmap:convertToImage(BmpCar2), Im2 = wxImage:rotate(Im,300,{A,B}),
                       BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B});
                     _-> Im = wxBitmap:convertToImage(BmpCar2b), Im2 = wxImage:rotate(Im,300,{A,B}),
                       BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B})
                   end;


              Error -> io:format("error in printCars, D = ~p~n",[Error]),
                io:format("cars ets inf: ~p~n",[ets:lookup(cars,Key)]),
                io:format("cars state inf: ~p~n",[rpc:call(PC, sys, get_state, [Key])]),
                ets:delete(cars,Key)
            end;
    yellow ->  case D of
                 left -> case Nev of
                           null-> wxDC:drawBitmap(DI, BmpCar3, {A, B});
                           _->   wxDC:drawBitmap(DI, BmpCar3b, {A, B})
                         end;

                 down ->case Nev of
                          null-> Im = wxBitmap:convertToImage(BmpCar3), Im2 = wxImage:rotate(Im,-300,{A,B}),
                            BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B});
                          _-> Im = wxBitmap:convertToImage(BmpCar3b), Im2 = wxImage:rotate(Im,-300,{A,B}),
                            BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B})
                        end;

                 right ->case Nev of
                           null-> Im = wxBitmap:convertToImage(BmpCar3), Im2 = wxImage:rotate(Im,600,{A,B}),
                             BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B});
                           _->  Im = wxBitmap:convertToImage(BmpCar3b), Im2 = wxImage:rotate(Im,600,{A,B}),
                             BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B})
                         end;

                 up ->case Nev of
                        null-> Im = wxBitmap:convertToImage(BmpCar3), Im2 = wxImage:rotate(Im,300,{A,B}),
                          BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B});
                        _-> Im = wxBitmap:convertToImage(BmpCar3b), Im2 = wxImage:rotate(Im,300,{A,B}),
                          BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B})
                      end;


                 Error -> io:format("error in printCars, D = ~p~n",[Error]),
                   io:format("cars ets inf: ~p~n",[ets:lookup(cars,Key)]),
                   io:format("cars state inf: ~p~n",[rpc:call(PC, sys, get_state, [Key])]),
                   ets:delete(cars,Key)
               end;
    Error ->  io:format("error in printCar for reason ~p~n",[Error]),
      io:format("cars ets inf: ~p~n",[ets:lookup(cars,Key)]),
      io:format("cars state inf: ~p~n",[rpc:call(PC, sys, get_state, [Key])]),
      ets:delete(cars,Key)
  end,

  case ets:member(cars,Key) of
    true -> printCars(ets:next(cars,Key),Panel,BmpCar1,BmpCar2,BmpCar3,BmpCar1b,BmpCar2b,BmpCar3b);
    _ -> ok
  end.






handle_info(timer, State=#state{frame = Frame}) ->  % refresh screen for graphics

  spawn(main,update_ets,[get(?PC1),?Home]),
  spawn(main,update_ets,[get(?PC2),?Home]),
  spawn(main,update_ets,[get(?PC3),?Home]),
  spawn(main,update_ets,[get(?PC4),?Home]),
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
  {noreply,State};

handle_cast({smoke,Car1,L1,Car2,L2},State) -> % insert smoke location to the ets
  ets:insert(smoke,{Car1,L1}),
  ets:insert(smoke,{Car2,L2}),
  {noreply,State};


handle_cast({server_down,PC},State) -> % if a server is down check which server, move responsibilities to different PC and update monitors

  io:format("server down in: ~p~n",[PC]),
  case PC of
    ?PC1 -> backup_pc(?PC1,get(?PC2)),
      rpc:call(get(?PC2),server,update_monitor,[pc_1]),
      rpc:call(get(?PC3),server,update_monitor,[pc_1]),
      rpc:call(get(?PC4),server,update_monitor,[pc_1]),
      move_car(?PC1,ets:first(cars));

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
  {noreply,State};




handle_cast({del_smoke,_},State) -> % delete smoke from ets
  ets:delete_all_objects(smoke),
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

  Car3 = wxImage:new("car3.png"),
  Car3c = wxImage:scale(Car3,45,25),
  BmpCar3 = wxBitmap:new(Car3c),
  wxImage:destroy(Car3),
  wxImage:destroy(Car3c),


  Car1b = wxImage:new("car1b.png"),
  Car1bc = wxImage:scale(Car1b,45,25),
  BmpCar1b = wxBitmap:new(Car1bc),
  wxImage:destroy(Car1b),
  wxImage:destroy(Car1bc),

  Car2b = wxImage:new("car2b.png"),
  Car2bc = wxImage:scale(Car2b,43,25),
  BmpCar2b = wxBitmap:new(Car2bc),
  wxImage:destroy(Car2b),
  wxImage:destroy(Car2bc),

  Car3b = wxImage:new("car3b.png"),
  Car3bc = wxImage:scale(Car3b,45,25),
  BmpCar3b = wxBitmap:new(Car3bc),
  wxImage:destroy(Car3b),
  wxImage:destroy(Car3bc),

  Smoke = wxImage:new("smoke.png"),
  Smokec = wxImage:scale(Smoke,50,50),
  BmpSmoke = wxBitmap:new(Smokec),
  wxImage:destroy(Smoke),
  wxImage:destroy(Smokec),


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

  {BmpRmap,BmpCar1,BmpCar2,BmpCar3,BmpAntenna,BmpTrafficLight,BmpTrafficLightGreen,BmpTrafficLightRed,BmpCommTower,BmpSmoke,BmpCar1b,BmpCar2b,BmpCar3b}.


% this function requests the ets from each server and calls to function to update ets
update_ets(PC,Home) ->
  List=
    try
      rpc:call(PC,server,update_car_location,[])
    catch _:_ -> problem
    end,
  case List of
%    problem -> ok;
    {ok, List1} -> list_to_ets(List1);
    Else-> io:format("there is a problem~n"),io:format("~p~n",[Else]),
      Res = net_adm:ping(PC),
      case Res of
        pong -> rpc:call(PC, erlang, disconnect_node, [Home]);
%          main:server_down(PC);
        _-> ok
      end,
      ok
  end.

% this function adds the ets received to main ets
list_to_ets('$end_of_table') ->
  ok;
list_to_ets(List) ->
%  ets:delete_all_objects(cars),
  lists:foreach(fun(Key_Value) -> ets:insert(cars, Key_Value) end, List).


delete_car(Pid) -> wx_object:cast(main,{delete_car, Pid}). % create delete car event
start_smoke(Car1,L1,Car2,L2) -> wx_object:cast(main,{smoke,Car1,L1,Car2,L2}).% create start smoke event
del_smoke(Pid) -> wx_object:cast(main,{del_smoke,Pid}).% create delete smoke event
server_down(PC) -> wx_object:cast(main,{server_down,PC}).

% this function checks which PC is down and moves all car from fallen PC to new PC
move_car(_,'$end_of_table') -> ok;
move_car(PcDown,Key) ->
  [{_,Location,Name,Start,Type,Con,PC,Nev}] = ets:lookup(cars,Key),

  case PcDown of
    ?PC1 -> if
              PC == ?PC1  -> rpc:call(get(?PC2),server,moved_car,[Name,Type,Start,Location,Con,get(?PC2),Nev]), % call to function in server
                Next = ets:next(cars,Key), % get next car
                ets:delete(cars,Key), % delete car from ets
                move_car(PcDown,Next) ; % move next car
              true ->move_car(PcDown,ets:next(cars,Key))
            end;

    ?PC2 -> if

              PC == ?PC2 -> rpc:call(get(?PC3),server,moved_car,[Name,Type,Start,Location,Con,get(?PC3),Nev]),
                Next = ets:next(cars,Key),
                ets:delete(cars,Key),
                move_car(PcDown,Next);
              true -> move_car(PcDown,ets:next(cars,Key))
            end;

    ?PC3 -> if

              PC == ?PC3 -> rpc:call(get(?PC4),server,moved_car,[Name,Type,Start,Location,Con,get(?PC4),Nev]),
                Next = ets:next(cars,Key),
                ets:delete(cars,Key),
                move_car(PcDown,Next) ;
              true -> move_car(PcDown,ets:next(cars,Key))
            end;

    ?PC4 -> if

              PC == ?PC4 -> rpc:call(get(?PC1),server,moved_car,[Name,Type,Start,Location,Con,get(?PC1),Nev]),
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

%this function is the navigation system
main_navigation(X,Y,PC1,PC2,PC3,PC4) ->
  Result =  check_cars(ets:first(cars)), % check if there is a car that already selected
  case Result of
    null -> if % in case there isn't a car that already selected,pick the close car
              X >= 780, Y =< 472 -> rpc:call(PC1,server,server_search_close_car,[X,Y]);
              X >= 780, Y >= 472 -> rpc:call(PC4,server,server_search_close_car,[X,Y]);
              X =< 780, Y =< 472 -> rpc:call(PC2,server,server_search_close_car,[X,Y]);
              X =< 780, Y >= 472 -> rpc:call(PC3,server,server_search_close_car,[X,Y]);
              true -> error
            end;

    % in case there isn't a car that already selected, search a close junction
    Pid -> io:format("Pid was founded: ~p~n",[Pid]), Result2 = rpc:call(PC1,server,server_search_close_junc,[X,Y]),



      case Result2 of
        null -> io:format("error in navigation, cant find close junction");
        Dest ->io:format("Dest was founded: ~p~n",[Dest]), [{_,[_,_,_,_,_],_,_,_,_,PC,_}] = ets:lookup(cars,Pid), % in case there is a close junction update the car destination
          rpc:call(PC,server,update_car_nev,[Pid,Dest])

      end
  end,
  ok.




%this function check if there is a car that already selected
check_cars('$end_of_table') -> io:format("there is no car in process ~n"), null;
check_cars(Key) ->  [{_,[_,_,_,_,_],_,_,_,_,_,Nev}] = ets:lookup(cars,Key),
  case Nev of
    in_process -> Key;
    _-> check_cars(ets:next(cars,Key))
  end.

% this function goes over the car ets and checks whether the car processes are still alive
main_cars_mon('$end_of_table',PC1,PC2,PC3,PC4) -> main_cars_mon(ets:first(cars),PC1,PC2,PC3,PC4);
main_cars_mon(Key,PC1,PC2,PC3,PC4)->

  Ans = ets:member(cars,Key),
  if
    Ans == true -> Next = ets:next(cars,Key);
    true -> Next = ets:first(cars),
      main_cars_mon(ets:first(cars),PC1,PC2,PC3,PC4)
  end,
  [{_,_,Name,_,_,_,PC,_}] = ets:lookup(cars,Key),
  Res =  check_PC(Key,PC,PC1,PC2,PC3,PC4),
  case Res of
    {_,true} -> main_cars_mon(Next,PC1,PC2,PC3,PC4);
    {PC,false}->
      timer:sleep(2000),

      case ets:member(cars,Key) of
        true -> io:format("PPPPPPPPPPPPPPPPPPPPPPPPPP process ~p killed in his PC ~n",[Key]),
          io:format("PPPPPPPPPPPPPPPPPPPPPPPPPP Res is ~p~n",[Res]),
%          ets:delete(cars,Key),
          rpc:call(PC,server,deleteCar,[Key]),

          case PC of
            PC1 -> main_search_close_car(ets:first(cars),{1344,93}), rpc:call(PC,server,start_car,[Name,20,[{1344,93},left,r1,yellow,st],PC]);
            PC2 -> main_search_close_car(ets:first(cars),{0,417}), rpc:call(PC,server,start_car,[Name,10,[{0,417},right,r3,red,st],PC]);
            PC3 -> main_search_close_car(ets:first(cars),{0,651}),rpc:call(PC,server,start_car,[Name,20,[{0,651},right,r9,grey,st],PC]);
            PC4 -> main_search_close_car(ets:first(cars),{0,651}), rpc:call(PC,server,start_car,[Name,20,[{0,651},right,r9,grey,st],PC])
          end,
          main_cars_mon(Next,PC1,PC2,PC3,PC4);
        _ -> main_cars_mon(Next,PC1,PC2,PC3,PC4)
      end;
    _ -> main_cars_mon(ets:first(cars),PC1,PC2,PC3,PC4)
  end.

% this function checks if a car is alive on its PC
check_PC(Key,PC_to_check,PC1,PC2,PC3,PC4) ->
  Res = net_adm:ping(PC_to_check), % check if the PC the car is on is alive
  case Res of
    pong -> case PC_to_check of % if it is, call to check if the car process is alive
              PC1 -> {PC1,rpc:call(PC1, erlang, is_process_alive, [Key])};
              PC2 -> {PC2,rpc:call(PC2, erlang, is_process_alive, [Key])};
              PC3 -> {PC3,rpc:call(PC3, erlang, is_process_alive, [Key])};
              PC4 -> {PC4,rpc:call(PC4, erlang, is_process_alive, [Key])}


            end;

    _-> case PC_to_check of % if the PC is not alive, check the backup PC
          PC1 -> check_PC(Key,PC2,PC1,PC2,PC3,PC4);
          PC2 -> check_PC(Key,PC3,PC1,PC2,PC3,PC4);
          PC3 -> check_PC(Key,PC4,PC1,PC2,PC3,PC4);
          PC4 -> check_PC(Key,PC1,PC1,PC2,PC3,PC4)
        end
  end.

% this function searches a close car, if there is a close car, the function waits 0.5 sec and start over
main_search_close_car('$end_of_table',_)  -> ok;
main_search_close_car(Key,{X,Y}) ->
  Ans = ets:member(cars,Key),
  if
    Ans == true -> [{_,[{X2,Y2},_,_,_,_],_,_,_,_,_,_}] = ets:lookup(cars,Key),
      Next = ets:next(cars,Key) ;
    true-> {X2,Y2} = {0,0} ,Next = ets:first(cars),
      main_search_close_car(ets:first(cars),{X,Y})
  end,
  D = math:sqrt(math:pow(X-X2,2) + math:pow(Y-Y2,2)),
  if
    D =< 30 -> timer:sleep(500),main_search_close_car(Key,{X,Y});
    true -> main_search_close_car(Next,{X,Y})
  end.
