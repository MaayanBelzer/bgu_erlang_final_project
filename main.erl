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
-export([start/0,init/1,handle_event/2,handle_sync_event/3]).
-define(max_x, 768).
-define(max_y,576 ).
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

%    DrawImage = wxClientDC:new(Panel),
%      wxDC:drawBitmap(DrawImage, BmpRmap, {0, 0}),


 % erlang:send_after(?TIMER, self(), timer),
  wxPanel:connect(Panel, paint, [callback]),
%  wxPanel:connect (Panel, left_down),
%  wxPanel:connect (Panel, right_down),
  wxFrame:connect(Frame, close_window),

  % create ets
 % ets:new(?ets_name, [set,named_table,public]),
  % create money
%  ets:insert(?ets_name,{money_left,?start_amount}),
%  ets:insert(?ets_name,{money_right,?start_amount}),
%  erlang:send_after(?money_timer, self(), money),

  {Frame,#state{frame = Frame, panel = Panel, dc=DC, paint = Paint,
    bmpRmap = BmpRmap,bmpCar1 =BmpCar1 ,bmpCar2 = BmpCar2,
    bmpTruck = BmpTruck,bmpAntenna = BmpAntenna,bmpTrafficLight = BmpTrafficLight }}.
%%%-------------------------------------------------------------------

handle_event(#wx{event = #wxClose{}},State = #state {frame = Frame}) ->                                                 % close window event
  io:format("Exiting\n"),
  wxWindow:destroy(Frame),
  wx:destroy(),
  {stop,normal,State}.


handle_sync_event(#wx{event=#wxPaint{}}, _,  _State = #state{frame = Frame, panel = Panel, dc=DC, paint = Paint,
    bmpRmap = BmpRmap,bmpCar1 =BmpCar1 ,bmpCar2 = BmpCar2,
    bmpTruck = BmpTruck,bmpAntenna = BmpAntenna,bmpTrafficLight = BmpTrafficLight}) ->
  DC2=wxPaintDC:new(Panel),
  wxDC:clear(DC2),
  wxDC:drawBitmap(DC2,BmpRmap,{0,0}),

DrawImage = wxClientDC:new(Panel),
      wxDC:drawBitmap(DrawImage, BmpCar1, {70, 40});
  %paint(Panel,DC,BmpCoin,BmpCastle,BmpZombie,BmpStrongZombie,BmpSkeleton,BmpStrongSkeleton,BmpZombie_f,BmpStrongZombie_f,BmpSkeleton_f,BmpStrongSkeleton_f,BmpLeftWin, BmpRightWin,ets:first(?ets_name));

handle_sync_event(_Event,_,State) ->
  {noreply, State}.

createBitMaps() ->         % create bitmap to all images
  Rmap = wxImage:new("rmap.jpg"),
  Rmapc = wxImage:scale(Rmap,?max_x,?max_y),
  BmpRmap = wxBitmap:new(Rmapc),
  wxImage:destroy(Rmap),
  wxImage:destroy(Rmapc),

  Car1 = wxImage:new("car1.png"),
  Car1c = wxImage:scale(Car1,37,22),
  BmpCar1 = wxBitmap:new(Car1c),
  wxImage:destroy(Car1),
  wxImage:destroy(Car1c),

  Car2 = wxImage:new("car2.png"),
  Car2c = wxImage:scale(Car2,100,70),
  BmpCar2 = wxBitmap:new(Car2c),
  wxImage:destroy(Car2),
  wxImage:destroy(Car2c),

  Truck = wxImage:new("truck.png"),
  Truckc = wxImage:scale(Truck,150,105),
  BmpTruck = wxBitmap:new(Truckc),
  wxImage:destroy(Truck),
  wxImage:destroy(Truckc),


  Antenna = wxImage:new("antenna.png"),
  Antennac = wxImage:scale(Antenna,40,50),
  BmpAntenna = wxBitmap:new(Antennac),
  wxImage:destroy(Antenna),
  wxImage:destroy(Antennac),


  TrafficLight = wxImage:new("trafficLight.png"),
  TrafficLightc = wxImage:scale(TrafficLight,30,40),
  BmpTrafficLight = wxBitmap:new(TrafficLightc),
  wxImage:destroy(TrafficLight),
  wxImage:destroy(TrafficLightc),


  {BmpRmap,BmpCar1,BmpCar2,BmpTruck,BmpAntenna,BmpTrafficLight}.




