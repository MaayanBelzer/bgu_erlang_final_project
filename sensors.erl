%%%-------------------------------------------------------------------
%%% @author Maayan Belzer, Nir Tapiero
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. Jul 2020 1:47 AM
%%%-------------------------------------------------------------------
-module(sensors).
-author("Maayan Belzer, Nir Tapiero").

%% API
-export([close_to_car/2,close_to_junction/2,far_from_car/2,outOfRange/1,
  traffic_light_sensor/2,car_accident/2,car_monitor/4,car_dev/1]).

% this function goes over the car ets and checks if there is another car close to the car
close_to_car(Pid,'$end_of_table') -> close_to_car(Pid,ets:first(cars));
close_to_car(Pid,FirstKey) ->

  [{_,[{X,Y},Dir1,_,_,_],_,_,_,_,_,_}] = ets:lookup(cars,Pid), % get car coordinates and direction
  Bool = ets:member(cars,FirstKey), % checks if the next car in ets is alive
  if
    Bool == true->
      Bool2 = ets:member(cars,FirstKey),
      if
        Bool2 == true -> [{P2,[{X2,Y2},Dir2,_,_,_],_,_,_,_,_,_}] = ets:lookup(cars,FirstKey); % if it is, get its coordinates and direction
        true -> [{P2,[{X2,Y2},Dir2,_,_,_],_,_,_,_,_,_}] = ets:lookup(cars,ets:first(cars)) % else, get the first car in ets
      end;


    true -> [{P2,[{X2,Y2},Dir2,_,_,_],_,_,_,_,_,_}] = ets:lookup(cars,ets:first(cars))
  end,
  case Dir1 == Dir2 of % checks if the directions are equal
    false -> case ets:member(cars,P2) of % if not, check next car in ets
               true -> close_to_car(Pid,ets:next(cars,P2));
               _-> close_to_car(Pid,ets:first(cars))
             end;
    _ ->  case Dir1 of % if the cars are in the same direction calculate the distance, if they're close send event to car, else, check next car
            left -> case abs(Y-Y2)=<7  of
                      false -> case ets:member(cars,P2) of
                                 true -> close_to_car(Pid,ets:next(cars,P2));
                                 _-> close_to_car(Pid,ets:first(cars))
                               end;
                      _ -> D = X-X2, if
                                       D =< 60 , D >= 0, P2 /= Pid -> cars:close_to_car(Pid,P2),
                                         timer:sleep(3000),
                                         close_to_car(Pid,ets:first(cars));
                                       true -> case ets:member(cars,P2) of
                                                 true -> close_to_car(Pid,ets:next(cars,P2));
                                                 _-> close_to_car(Pid,ets:first(cars))
                                               end
                                     end
                    end;
            right -> case abs(Y-Y2)=<7 of
                       false -> case ets:member(cars,P2) of
                                  true -> close_to_car(Pid,ets:next(cars,P2));
                                  _-> close_to_car(Pid,ets:first(cars))
                                end;
                       _ -> D = X2-X, if
                                        D =< 60 , D >= 0, P2 /= Pid -> cars:close_to_car(Pid,P2),
                                          timer:sleep(3000),
                                          close_to_car(Pid,ets:first(cars));
                                        true -> case ets:member(cars,P2) of
                                                  true -> close_to_car(Pid,ets:next(cars,P2));
                                                  _-> close_to_car(Pid,ets:first(cars))
                                                end
                                      end
                     end;
            up -> case abs(X-X2)=<7  of
                    false -> case ets:member(cars,P2) of
                               true -> close_to_car(Pid,ets:next(cars,P2));
                               _-> close_to_car(Pid,ets:first(cars))
                             end;
                    _ -> D = Y-Y2, if
                                     D =< 60 , D >= 0, P2 /= Pid -> cars:close_to_car(Pid,P2),
                                       timer:sleep(3000),
                                       close_to_car(Pid,ets:first(cars));
                                     true -> case ets:member(cars,P2) of
                                               true -> close_to_car(Pid,ets:next(cars,P2));
                                               _-> close_to_car(Pid,ets:first(cars))
                                             end
                                   end
                  end;
            down -> case abs(X-X2)=<7 of
                      false -> case ets:member(cars,P2) of
                                 true -> close_to_car(Pid,ets:next(cars,P2));
                                 _-> close_to_car(Pid,ets:first(cars))
                               end;
                      _ -> D = Y2-Y, if
                                       D =< 60 , D >= 0, P2 /= Pid -> cars:close_to_car(Pid,P2),
                                         timer:sleep(3000),
                                         close_to_car(Pid,ets:first(cars));
                                       true -> case ets:member(cars,P2) of
                                                 true -> close_to_car(Pid,ets:next(cars,P2));
                                                 _-> close_to_car(Pid,ets:first(cars))
                                               end
                                     end
                    end
          end



  end.

% this function checks if there is a close junction
close_to_junction(Pid,'$end_of_table') -> close_to_junction(Pid,ets:first(junction));
close_to_junction(Pid,FirstKey) ->



  [{_,[{X,Y},Dir1,R1,_,_],_,_,_,_,_,_}] = ets:lookup(cars,Pid), % get car coordinates, direction and road

  [{{R2,_},[{X2,Y2},LightPid]}] = ets:lookup(junction,FirstKey), % get junction coordinates, road and the  traffic light pid

%  [{{R2,_},[{X2,Y2},LightPid,{_,_}]}] = ets:lookup(junction,FirstKey),
  case R1==R2 of % checks if the car and junction are on the same road
    false -> close_to_junction(Pid,ets:next(junction,FirstKey)); % if they're not, check next  junction
    _ -> case Dir1 of % if they are, check direction of car
           left -> D = X-X2, if % check distance between car and junction, if they're close, send message to car with the state of the light, else check next junction
                               D =< 60 , D >= 0-> case LightPid of
                                                    nal -> cars:close_to_junc(Pid,green,FirstKey,nal),
                                                      timer:sleep(3000),
                                                      close_to_junction(Pid,ets:first(junction));
                                                    LP -> cars:close_to_junc(Pid,sys:get_state(LP),FirstKey,LP),
                                                      timer:sleep(3000),
                                                      close_to_junction(Pid,ets:first(junction))
                                                  end;
                               true -> close_to_junction(Pid,ets:next(junction,FirstKey))
                             end;
           right -> D = X2-X, if
                                D =< 60 , D >= 0-> case LightPid of
                                                     nal -> cars:close_to_junc(Pid,green,FirstKey,nal),
                                                       timer:sleep(3000),
                                                       close_to_junction(Pid,ets:first(junction));
                                                     LP -> cars:close_to_junc(Pid,sys:get_state(LP),FirstKey,LP),
                                                       timer:sleep(3000),
                                                       close_to_junction(Pid,ets:first(junction))
                                                   end;
                                true -> close_to_junction(Pid,ets:next(junction,FirstKey))
                              end;
           up -> D = Y-Y2, if
                             D =< 60 , D >= 0-> case LightPid of
                                                  nal -> cars:close_to_junc(Pid,green,FirstKey,nal),
                                                    timer:sleep(3000),
                                                    close_to_junction(Pid,ets:first(junction));
                                                  LP -> cars:close_to_junc(Pid,sys:get_state(LP),FirstKey,LP),
                                                    timer:sleep(3000),
                                                    close_to_junction(Pid,ets:first(junction))
                                                end;
                             true -> close_to_junction(Pid,ets:next(junction,FirstKey))
                           end;
           down -> D = Y2-Y, if
                               D =< 60 , D >= 0-> case LightPid of
                                                    nal -> cars:close_to_junc(Pid,green,FirstKey,nal),
                                                      timer:sleep(3000),
                                                      close_to_junction(Pid,ets:first(junction));
                                                    LP -> cars:close_to_junc(Pid,sys:get_state(LP),FirstKey,LP),
                                                      timer:sleep(3000),
                                                      close_to_junction(Pid,ets:first(junction))
                                                  end;
                               true -> close_to_junction(Pid,ets:next(junction,FirstKey))
                             end

         end
  end.

% this function checks whether the other car in front of the car is still close
far_from_car(Who,Other_car) ->
  [{_,[{X,Y},Dir1,_,_,_],_,_,_,_,_,_}] = ets:lookup(cars,Who), % get the car coordinates and direction
  Bool = ets:member(cars,Other_car),
  if
    Bool == true -> [{_,[{X2,Y2},_,_,_,_],_,_,_,_,_,_}] = ets:lookup(cars,Other_car), % if other car is still alive, check distance to car
      case Dir1 of
        left -> D = X-X2, if
                            D >= 100  -> cars:far_from_car(Who); % if the other car is far enough, send event to car
                            true -> far_from_car(Who,Other_car) % else, check again
                          end;

        right ->  D = X2-X, if
                              D >= 100  -> cars:far_from_car(Who);
                              true -> far_from_car(Who,Other_car)
                            end;

        up ->  D = Y-Y2, if
                           D >= 100  -> cars:far_from_car(Who);
                           true -> far_from_car(Who,Other_car)
                         end;

        down ->  D = Y2-Y, if
                             D >= 100  -> cars:far_from_car(Who);
                             true -> far_from_car(Who,Other_car)
                           end

      end;
    true -> cars:far_from_car(Who) % if other car is not alive, send far from car event to car
  end.

% this function checks if car is out of range of the screen or if the car has moved to a different PC
outOfRange(Pid)->
  [{_,[{X,Y},Dir,R,Type,Turn],_,_,_,_,_,_}] = ets:lookup(cars,Pid), % get car info
  Dx = X - 735, % check distance from borders of different PCs
  Dy = Y - 472,
  if % check if the car is close enough to borders of PC, if it is, send event to car to change PC according to coordinates

    X >= 735,Y =< 472, Dir == left, Dx =< 1 ->  ets:update_element(cars,Pid,[{2,[{X - 2,Y},Dir,R,Type,Turn]}]),
      cars:switch_comp(Pid,pc_1,pc_2),
%      io:format("move from pc_1 to pc_2~n"),
      outOfRange(Pid);
    X >= 735,Y =< 472, Dir == down, Dy >= -1 ->ets:update_element(cars,Pid,[{2,[{X,Y + 2},Dir,R,Type,Turn]}]),
      cars:switch_comp(Pid,pc_1,pc_4),
%      io:format("move from pc_1 to pc_4~n"),
      outOfRange(Pid);

    X =< 735,Y =< 472 , Dir == right, Dx >= -1 -> ets:update_element(cars,Pid,[{2,[{X + 2,Y},Dir,R,Type,Turn]}]),
      cars:switch_comp(Pid,pc_2,pc_1),
%      io:format("move from pc_2 to pc_1~n"),
      outOfRange(Pid);
    X =< 735,Y =< 472 , Dir == down, Dy >= -1 ->ets:update_element(cars,Pid,[{2,[{X,Y + 2 },Dir,R,Type,Turn]}]),
      cars:switch_comp(Pid,pc_2,pc_3),
%      io:format("move from pc_2 to pc_3~n"),
      outOfRange(Pid);

    X =< 735,Y >= 472,  Dir == up,   Dy =< 1 -> ets:update_element(cars,Pid,[{2,[{X,Y - 2 },Dir,R,Type,Turn]}]),
      cars:switch_comp(Pid,pc_3,pc_2),
%      io:format("move from pc_3 to pc_2~n"),
      outOfRange(Pid);

    X >= 735,Y >= 472,  Dir == left, Dx =< 1 -> ets:update_element(cars,Pid,[{2,[{X - 2,Y},Dir,R,Type,Turn]}]),
      cars:switch_comp(Pid,pc_4,pc_3),
%      io:format("move from pc_4 to pc_3~n"),
      outOfRange(Pid);
    X >= 735,Y >= 472,  Dir == up,   Dy =< 1 -> ets:update_element(cars,Pid,[{2,[{X ,Y - 2},Dir,R,Type,Turn]}]),
      cars:switch_comp(Pid,pc_4,pc_1),
%      io:format("move from pc_4 to pc_1~n"),
      outOfRange(Pid);

    X < 0; Y < 0; X > 1344; Y > 890 -> cars:kill(Pid); % if car has left the screen, send event to kill it

    true -> outOfRange(Pid) % if car is not close to borders, check again
  end.

% this function checks if a traffic light is green and if it is it checks which other traffic lights are in hte junction and calls to another function
traffic_light_sensor(KeyList,'$end_of_table') -> traffic_light_sensor(KeyList,ets:first(junction));
traffic_light_sensor(KeyList,Key) ->
  [{{R2,J},[{_,_},LightPid]}] =  ets:lookup(junction,Key), % get light road, junction and pid
%  [{{R2,J},[{X2,Y2},LightPid,{_,_}]}] =  ets:lookup(junction,Key),

  case LightPid of
    nal -> traffic_light_sensor(KeyList,ets:next(junction,Key)); % if there is no traffic light, check next junction
    _-> case sys:get_state(LightPid) of % else, check state of light
          {green,_} -> L = [{Road,Junc}|| {Road,Junc} <- KeyList, J == Junc, Road /= R2], % if light is green, call function with list of all of the traffic lights of this junction
            sync_traffic(L), traffic_light:sensor_msg(LightPid,green), timer:sleep(200), traffic_light_sensor(KeyList,ets:next(junction,Key));
          _-> traffic_light_sensor(KeyList,ets:next(junction,Key)) % if the light is not green, check next junction
        end
  end.

% this function sends messages to other traffic lights in junction so they turn red
sync_traffic([]) -> ok;
sync_traffic([H|T]) ->
  [{{_,_},[{_,_},LightPid]}] =  ets:lookup(junction,H),
%  [{{_,_},[{_,_},LightPid,{_,_}]}] =  ets:lookup(junction,H),
  traffic_light:sensor_msg(LightPid,red),sync_traffic(T).

% this function checks if there has been an accident
car_accident(Pid,'$end_of_table') -> car_accident(Pid,ets:first(cars));
car_accident(Pid,Key) ->
  [{_,[{X,Y},_,_,_,_],_,_,_,_,_,_}] = ets:lookup(cars,Pid), % get car coordinates
  Bool = ets:member(cars,Key),
  if
    Bool == true->
      Bool2 = ets:member(cars,Key),
      if % get other car coordinates
        Bool2 == true -> [{P2,[{X2,Y2},_,_,_,_],_,_,_,_,_,_}] = ets:lookup(cars,Key);
        true -> [{P2,[{X2,Y2},_,_,_,_],_,_,_,_,_,_}] = ets:lookup(cars,ets:first(cars))
      end;
    true -> [{P2,[{X2,Y2},_,_,_,_],_,_,_,_,_,_}] = ets:lookup(cars,ets:first(cars))
  end,

  D = math:sqrt(math:pow(X-X2,2) + math:pow(Y-Y2,2)), % calculate distance between cars
  if
    D =< 24, Pid /= P2 -> % if cars are too close, send accident event to cars
      cars:accident(Pid,P2),server:smoke(Pid,{X,Y},Key,{X2,Y2});
    true ->  case ets:member(cars,P2) of % if cars are not close, check next car
               true ->  car_accident(Pid,ets:next(cars,P2));
               _-> car_accident(Pid,ets:first(cars))
             end

  end.

% this function checks if a car has deviated from the road
car_dev(Pid) ->
  [{_,[{X,Y},Dir,Road,Type,_],_,_,_,_,_,_}] = ets:lookup(cars,Pid), % get car info
  case Road of % checks which road the car is on and then checks distance from the center of the road, if it's too far, correct the coordinates
    r1-> D = abs(Y - 106), if
                             D >= 18 -> ets:update_element(cars,Pid,[{2,[{X,93},Dir,Road,Type,st]}]),car_dev(Pid) ;
                             true -> car_dev(Pid)
                           end  ;
    r2->  D = abs(X - 114), if
                              D >= 18 -> ets:update_element(cars,Pid,[{2,[{101,Y },Dir,Road,Type,st]}]),car_dev(Pid) ;
                              true -> car_dev(Pid)
                            end  ;
    r3->  D = abs(Y - 404), if
                              D >= 18 -> ets:update_element(cars,Pid,[{2,[{X,417},Dir,Road,Type,st]}]),car_dev(Pid) ;
                              true -> car_dev(Pid)
                            end  ;
    r4->  D =abs( X - 610), if
                              D >= 18 -> ets:update_element(cars,Pid,[{2,[{623,Y },Dir,Road,Type,st]}]),car_dev(Pid) ;
                              true -> car_dev(Pid)
                            end  ;
    r5->  D = abs(Y - 641), if
                              D >= 18 -> ets:update_element(cars,Pid,[{2,[{X,654},Dir,Road,Type,st]}]),car_dev(Pid) ;
                              true -> car_dev(Pid)
                            end  ;
    r6->  D = abs(X - 1104), if
                               D >= 18 -> ets:update_element(cars,Pid,[{2,[{1117,Y},Dir,Road,Type,st]}]),car_dev(Pid) ;
                               true -> car_dev(Pid)
                             end  ;
    r7-> D =abs( Y - 779), if
                             D >= 18 -> ets:update_element(cars,Pid,[{2,[{X,766},Dir,Road,Type,st]}]),car_dev(Pid) ;
                             true -> car_dev(Pid)
                           end  ;
    r8->  D = abs(X - 249), if
                              D >= 18 -> ets:update_element(cars,Pid,[{2,[{262,Y},Dir,Road,Type,st]}]),car_dev(Pid) ;
                              true -> car_dev(Pid)
                            end  ;
    r9-> D = abs(Y - 638), if
                             D >= 18 -> ets:update_element(cars,Pid,[{2,[{X,651},Dir,Road,Type,st]}]),car_dev(Pid) ;
                             true -> car_dev(Pid)
                           end  ;
    r10->  D = abs(X - 750), if
                               D >= 18 -> ets:update_element(cars,Pid,[{2,[{737,Y },Dir,Road,Type,st]}]),car_dev(Pid) ;
                               true -> car_dev(Pid)
                             end  ;
    r12->  D = abs(X - 888), if
                               D >= 18 -> ets:update_element(cars,Pid,[{2,[{875,Y },Dir,Road,Type,st]}]),car_dev(Pid) ;
                               true -> car_dev(Pid)
                             end  ;
    r14->  D = abs(X - 392), if
                               D >= 18 -> ets:update_element(cars,Pid,[{2,[{405,Y},Dir,Road,Type,st]}]),car_dev(Pid) ;
                               true -> car_dev(Pid)
                             end  ;
    r16->  D = abs(X - 392), if
                               D >= 18 -> ets:update_element(cars,Pid,[{2,[{405,Y},Dir,Road,Type,st]}]),car_dev(Pid) ;
                               true -> car_dev(Pid)
                             end  ;
    r18-> D = abs(X - 887), if
                              D >= 18 -> ets:update_element(cars,Pid,[{2,[{874,Y },Dir,Road,Type,st]}]),car_dev(Pid) ;
                              true -> car_dev(Pid)
                            end

  end.

% this function monitors the cars and sensors and deals with exit messages
car_monitor(PC1,PC2,PC3,PC4) ->
  receive
    {nodedown,PC} -> case PC of % if a PC is down, it checks which PC it was and transfers its responsibilities to different PC
                       pc_1 -> if
                                 PC3 == PC1, PC4 == PC1 -> car_monitor(PC2,PC2,PC2,PC2);
                                 PC3 == PC1 -> car_monitor(PC2,PC2,PC2,PC4);
                                 PC4 == PC1 -> car_monitor(PC2,PC2,PC3,PC2);
                                 true ->   car_monitor(PC2,PC2,PC3,PC4)
                               end;

                       pc_2 -> if
                                 PC1 == PC2, PC4 == PC2 ->  car_monitor(PC3,PC3,PC3,PC3);
                                 PC1 == PC2 ->  car_monitor(PC3,PC3,PC3,PC4);
                                 PC4 == PC2 ->  car_monitor(PC1,PC3,PC3,PC3);
                                 true ->  car_monitor(PC1,PC3,PC3,PC4)
                               end;
                       pc_3 -> if
                                 PC1 == PC3, PC2 == PC3 -> car_monitor(PC4,PC4,PC4,PC4);
                                 PC1 == PC3 -> car_monitor(PC4,PC2,PC4,PC4);
                                 PC2 == PC3 -> car_monitor(PC1,PC4,PC4,PC4);
                                 true -> car_monitor(PC1,PC2,PC4,PC4)
                               end;
                       pc_4 -> if
                                 PC2 == PC4, PC3 == PC4 -> car_monitor(PC1,PC1,PC1,PC1);
                                 PC2 == PC4 -> car_monitor(PC1,PC1,PC3,PC1);
                                 PC3 == PC4 -> car_monitor(PC1,PC2,PC1,PC1);
                                 true -> car_monitor(PC1,PC2,PC3,PC1)
                               end
                     end;

    {add_to_monitor,Pid} -> monitor(process, Pid),car_monitor(PC1,PC2,PC3,PC4); % add a new process to the monitor
    {_, _, _, Pid, Reason} ->  case Reason of % a process is down, check reason
                                 {outOfRange,Name,_,Start,Speed} -> % if a car is out of range start a new car in the PC where the old one started
                                   %io:format("~p killed with reason outOfRange ~n",[Pid]),
                                   [{X,Y},Dir,Road,_,_]  = Start,
                                   E = lists:nth(rand:uniform(3),[yellow,red,grey]),
                                   NewStart = [{X,Y},Dir,Road,E,st],
                                   if
                                     X >= 735, Y =< 472 -> rpc:call(PC1,server,start_car,[Name,Speed,NewStart,PC1]),car_monitor(PC1,PC2,PC3,PC4);
                                     X >= 735, Y >= 472 -> rpc:call(PC4,server,start_car,[Name,Speed,NewStart,PC4]),car_monitor(PC1,PC2,PC3,PC4);
                                     X =< 735, Y =< 472 -> rpc:call(PC2,server,start_car,[Name,Speed,NewStart,PC2]),car_monitor(PC1,PC2,PC3,PC4);
                                     X =< 735, Y >= 472 -> rpc:call(PC3,server,start_car,[Name,Speed,NewStart,PC3]),car_monitor(PC1,PC2,PC3,PC4);
                                     true -> io:format("Error")

                                   end;
                                 % move car to different PC:
                                 {move_to_comp1,Name,Start,Speed,C,_,_,Con,Nev} ->  rpc:call(PC1,server,moved_car,[Name,Speed,Start,C,Con,PC1,Nev]),car_monitor(PC1,PC2,PC3,PC4);
                                 {move_to_comp2,Name,Start,Speed,C,_,_,Con,Nev} ->  rpc:call(PC2,server,moved_car,[Name,Speed,Start,C,Con,PC2,Nev]),car_monitor(PC1,PC2,PC3,PC4);
                                 {move_to_comp3,Name,Start,Speed,C,_,_,Con,Nev} ->  rpc:call(PC3,server,moved_car,[Name,Speed,Start,C,Con,PC3,Nev]),car_monitor(PC1,PC2,PC3,PC4);
                                 {move_to_comp4,Name,Start,Speed,C,_,_,Con,Nev} ->  rpc:call(PC4,server,moved_car,[Name,Speed,Start,C,Con,PC4,Nev]),car_monitor(PC1,PC2,PC3,PC4);


                                 {accident,Name,Mon,Start,Speed} -> io:format("~p killed in accident ~n",[Pid]), % if there was an accident, start a new car where the old one started
                                   cars:start(Name,Mon,Speed,Start,PC1),car_monitor(PC1,PC2,PC3,PC4);

                                 {badarg, [_, {_,close_to_car,_,_}]} -> [{_,Car}] = ets:lookup(sensors,Pid),ets:delete(sensors,Pid), % if a sensor died, spawn a new one
                                   SensorPid = spawn(sensors,close_to_car,[Car,ets:first(cars)]), cars:add_sensor(Car,SensorPid,close_to_car), car_monitor(PC1,PC2,PC3,PC4);
                                 {badarg, [_, {_,car_accident,_,_}]} -> [{_,Car}] = ets:lookup(sensors,Pid),ets:delete(sensors,Pid),
                                   SensorPid = spawn(sensors,car_accident,[Car,ets:first(cars)]), cars:add_sensor(Car,SensorPid,car_accident), car_monitor(PC1,PC2,PC3,PC4);
                                 killed -> car_monitor(PC1,PC2,PC3,PC4);
                                 Else->  io:format("~p killed in reason ~p ~n",[Pid,Else]),
                                   car_monitor(PC1,PC2,PC3,PC4)
                               end

  after 0 -> car_monitor(PC1,PC2,PC3,PC4)
  end.
