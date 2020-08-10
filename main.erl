%%%-------------------------------------------------------------------
%%% @author maayan
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. Jul 2020 1:57 AM
%%%-------------------------------------------------------------------
-module(main).
-author("maayan").


-behaviour(wx_object).
-include_lib("wx/include/wx.hrl").
%-export([start/0, init/1, terminate/2, code_change/3,
%  handle_info/2, handle_call/3, handle_cast/2, handle_event/2, handle_sync_event/3, close/0, pass_soldier/2]).
%-include("header.hrl").
-export([start/0,init/1,handle_event/2,handle_sync_event/3,handle_info/2]).
-define(max_x, 1344).
-define(max_y,890).
-define(Timer,66).

-define(SERVER, ?MODULE).
-record(state, {frame, panel, dc, paint, list,bmpRmap,bmpCar1,bmpCar2,bmpTruck,bmpAntenna,bmpTrafficLight ,key}).
%%%-------------------------------------------------------------------
start() ->
  wx_object:start({local,?SERVER},?MODULE,[],[]).

init([]) ->
  % graphics
  WxServer = wx:new(),
  Frame = wxFrame:new(WxServer, ?wxID_ANY, "MAP", [{size,{?max_x, ?max_y}}]),
  Panel  = wxPanel:new(Frame),
  DC=wxPaintDC:new(Panel),
  Paint = wxBufferedPaintDC:new(Panel),
  % create bitmap to all images
  {BmpRmap,BmpCar1,BmpCar2,BmpTruck,BmpAntenna,BmpTrafficLight}=createBitMaps(),

  % connect panel
  wxFrame:show(Frame),
  erlang:send_after(?Timer, self(), timer),



  % erlang:send_after(?TIMER, self(), timer),
  wxPanel:connect(Panel, paint, [callback]),
  wxPanel:connect (Panel, left_down),
%  wxPanel:connect (Panel, right_down),
  wxFrame:connect(Frame, close_window),

  % create ets
%ets:new(?ets_name, [set,named_table,public]),

%  erlang:send_after(?money_timer, self(), money),

  {ok,Pi} = server:start(),


  {Frame,#state{frame = Frame, panel = Panel, dc=DC, paint = Paint,
    bmpRmap = BmpRmap,bmpCar1 =BmpCar1 ,bmpCar2 = BmpCar2,
    bmpTruck = BmpTruck,bmpAntenna = BmpAntenna,bmpTrafficLight = BmpTrafficLight }}.
%%%-------------------------------------------------------------------

handle_event(#wx{event = #wxClose{}},State = #state {frame = Frame}) ->                                                 % close window event
  io:format("Exiting\n"),
  wxWindow:destroy(Frame),
  wx:destroy(),
  {stop,normal,State};

handle_event(#wx{event = #wxMouse{type=left_down, x=X, y=Y}},State) ->
  io:format("~p~n", [{X,Y}]),
  {noreply,State}.


handle_sync_event(#wx{event=#wxPaint{}}, _,  _State = #state{frame = Frame, panel = Panel, dc=DC, paint = Paint,
  bmpRmap = BmpRmap,bmpCar1 =BmpCar1 ,bmpCar2 = BmpCar2,
  bmpTruck = BmpTruck,bmpAntenna = BmpAntenna,bmpTrafficLight = BmpTrafficLight}) ->
  DC2=wxPaintDC:new(Panel),
  wxDC:clear(DC2),
  wxDC:drawBitmap(DC2,BmpRmap,{0,0}),


  DrawImage = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawImage, BmpCar1, {160, 93}),
  DrawImage2 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawImage2, BmpCar2, {160, 118}),
  DrawTrafficA1 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficA1, BmpTrafficLight, {1130, 35}),
  DrawTrafficA2 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficA2, BmpTrafficLight, {1130, 135}),
  DrawTrafficB = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficB, BmpTrafficLight, {847, 35}),
  DrawTrafficC1 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficC1, BmpTrafficLight, {634, 35}),
  DrawTrafficC2 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficC2, BmpTrafficLight, {634, 135}),
  DrawTrafficD1 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficD1, BmpTrafficLight, {280, 35}),
  DrawTrafficD2 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficD2, BmpTrafficLight, {280, 135}),
  DrawTrafficE1 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficE1, BmpTrafficLight, {138, 35}),
  DrawTrafficE2 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficE2, BmpTrafficLight, {75, 35}),
  DrawTrafficF1 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficF1, BmpTrafficLight, {75, 330}),
  DrawTrafficF2 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficF2, BmpTrafficLight, {75, 426}),
  DrawTrafficG1 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficG1, BmpTrafficLight, {355, 426}),
  DrawTrafficG2 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficG2, BmpTrafficLight, {418, 426}),
  DrawTrafficH1 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficH1, BmpTrafficLight, {571, 426}),
  DrawTrafficH2 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficH2, BmpTrafficLight, {634, 426}),
  DrawTrafficI1 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficI1, BmpTrafficLight, {713, 330}),
  DrawTrafficI2 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficI2, BmpTrafficLight, {713, 420}),
  DrawTrafficJ1 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficJ1, BmpTrafficLight, {1067, 426}),
  DrawTrafficJ2 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficJ2, BmpTrafficLight, {1130, 426}),
  DrawTrafficK1 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficK1, BmpTrafficLight, {1067, 660}),
  DrawTrafficK2 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficK2, BmpTrafficLight, {1130, 660}),
  DrawTrafficL1 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficL1, BmpTrafficLight, {634, 710}),
  DrawTrafficL2 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficL2, BmpTrafficLight, {634, 790}),
  DrawTrafficM1 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficM1, BmpTrafficLight, {355, 660}),
  DrawTrafficM2 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficM2, BmpTrafficLight, {418, 660}),
  DrawTrafficN1 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficN1, BmpTrafficLight, {571, 660}),
  DrawTrafficN2 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficN2, BmpTrafficLight, {634, 660}),
  DrawTrafficO1 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficO1, BmpTrafficLight, {75, 575}),
  DrawTrafficO2 = wxClientDC:new(Panel),
  wxDC:drawBitmap(DrawTrafficO2, BmpTrafficLight, {75, 660}),


  % printCars(ets:first(cars),Panel,BmpCar1);


  [{_,[{A,B},D,_,Type,Turn]}] = ets:lookup(cars,ets:first(cars)),
  DI =wxClientDC:new(Panel),
  case Turn of
    st-> case Type of
          red -> case D of
                   left -> wxDC:drawBitmap(DI, BmpCar1, {A, B});
                   down -> Im = wxBitmap:convertToImage(BmpCar1), Im2 = wxImage:rotate(Im,-300,{A,B}),
                     BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B});
                   right -> Im = wxBitmap:convertToImage(BmpCar1), Im2 = wxImage:rotate(Im,600,{A,B}),
                     BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B});
                   up -> Im = wxBitmap:convertToImage(BmpCar1), Im2 = wxImage:rotate(Im,300,{A,B}),
                     BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B})
                 end;
          grey -> wxDC:drawBitmap(DI, BmpCar2, {A, B});
          truck ->  wxDC:drawBitmap(DI, BmpTruck, {A, B})
        end;
    right -> case Type of
               red -> Im = wxBitmap:convertToImage(BmpCar1), Im2 = wxImage:rotate(Im,0,{A,B}),
                 BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B});
               grey -> Im = wxBitmap:convertToImage(BmpCar2), Im2 = wxImage:rotate(Im,-18,{A,B}),
                 BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B});
               truck ->  Im = wxBitmap:convertToImage(BmpTruck), Im2 = wxImage:rotate(Im,-18,{A,B}),
                 BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B})
             end;
    left -> case Type of
              red -> Im = wxBitmap:convertToImage(BmpCar1), Im2 = wxImage:rotate(Im,0,{A,B}),
                BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B});
              grey -> Im = wxBitmap:convertToImage(BmpCar2), Im2 = wxImage:rotate(Im,18,{A,B}),
                BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B});
              truck ->  Im = wxBitmap:convertToImage(BmpTruck), Im2 = wxImage:rotate(Im,18,{A,B}),
                BitIm = wxBitmap:new(Im2), wxDC:drawBitmap(DI, BitIm, {A, B})
            end

  end;
%  wxDC:drawBitmap(DI, BmpCar1, {A, B});

% [{_,[{A2,B2},_,_]}] = ets:lookup(cars,ets:next(cars,K)),
% DI2 =wxClientDC:new(Panel),
% wxDC:drawBitmap(DI2, BmpCar1, {A2, B2});


%paint(Panel,DC,BmpCoin,BmpCastle,BmpZombie,BmpStrongZombie,BmpSkeleton,BmpStrongSkeleton,BmpZombie_f,BmpStrongZombie_f,BmpSkeleton_f,BmpStrongSkeleton_f,BmpLeftWin, BmpRightWin,ets:first(?ets_name));



handle_sync_event(_Event,_,State) ->
  {noreply, State}.

%printCars('$end_of_table',_,_) -> done;
%printCars(Key,Panel,BmpCar1) ->
%  [{_,[{A,B},_,_,Type,Turn]}] = ets:lookup(cars,Key),
%  DI =wxClientDC:new(Panel),
%  wxDC:drawBitmap(DI, BmpCar1, {A, B}),
%  printCars(ets:next(cars,Key),Panel,BmpCar1).


handle_info(timer, State=#state{frame = Frame}) ->                    % refresh screen for graphics

%  checkUpdateCall(?PC1),
%  checkUpdateCall(?PC2),
%  checkUpdateCall(?PC3),
%  checkUpdateCall(?PC4),
%io:format("fdsnjkdsnskj"),
  wxWindow:refresh(Frame),
  erlang:send_after(66,self(),timer),
  {noreply, State}.











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
  TrafficLightc = wxImage:scale(TrafficLight,40,50),
  BmpTrafficLight = wxBitmap:new(TrafficLightc),
  wxImage:destroy(TrafficLight),
  wxImage:destroy(TrafficLightc),


  {BmpRmap,BmpCar1,BmpCar2,BmpTruck,BmpAntenna,BmpTrafficLight}.




