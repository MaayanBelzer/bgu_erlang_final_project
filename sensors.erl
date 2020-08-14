%%%-------------------------------------------------------------------
%%% @author maayan
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. Jul 2020 1:47 AM
%%%-------------------------------------------------------------------
-module(sensors).
-author("maayan").

%% API
-export([close_to_car/2,close_to_junction/2,far_from_car/2,outOfRange/1,traffic_light_sensor/2]).

close_to_car(Pid,'$end_of_table') -> close_to_car(Pid,ets:first(cars));
close_to_car(Pid,FirstKey) -> link(Pid),

  [{_,[{X,Y},Dir1,_,_,_]}] = ets:lookup(cars,Pid),
  [{P2,[{X2,Y2},Dir2,_,_,_]}] = ets:lookup(cars,FirstKey),
  case Dir1 == Dir2 of
    false -> close_to_car(Pid,ets:next(cars,P2));
    _ ->  case Dir1 of
            left -> case abs(Y-Y2)=<5  of
                      false -> close_to_car(Pid,ets:next(cars,P2));
                      _ -> D = X-X2, if
                                       D =< 60 , D >= 0, P2 /= Pid -> cars:close_to_car(Pid,P2),
                                         timer:sleep(3000),
                                         close_to_car(Pid,ets:first(cars));
                                       true -> close_to_car(Pid,ets:next(cars,P2))
                                     end
                    end;
            right -> case abs(Y-Y2)=<5 of
                       false -> close_to_car(Pid,ets:next(cars,P2));
                       _ -> D = X2-X, if
                                        D =< 60 , D >= 0, P2 /= Pid -> cars:close_to_car(Pid,P2),
                                          timer:sleep(3000),
                                          close_to_car(Pid,ets:first(cars));
                                        true -> close_to_car(Pid,ets:next(cars,P2))
                                      end
                     end;
            up -> case abs(X-X2)=<5  of
                    false -> close_to_car(Pid,ets:next(cars,P2));
                    _ -> D = Y-Y2, if
                                     D =< 60 , D >= 0, P2 /= Pid -> cars:close_to_car(Pid,P2),
                                       timer:sleep(3000),
                                       close_to_car(Pid,ets:first(cars));
                                     true -> close_to_car(Pid,ets:next(cars,P2))
                                   end
                  end;
            down -> case abs(X-X2)=<5 of
                      false -> close_to_car(Pid,ets:next(cars,P2));
                      _ -> D = Y2-Y, if
                                       D =< 60 , D >= 0, P2 /= Pid -> cars:close_to_car(Pid,P2),
                                         timer:sleep(3000),
                                         close_to_car(Pid,ets:first(cars));
                                       true -> close_to_car(Pid,ets:next(cars,P2))
                                     end
                    end
          end



  end.


close_to_junction(Pid,'$end_of_table') -> close_to_junction(Pid,ets:first(junction));
close_to_junction(Pid,FirstKey) ->link(Pid),


  [{_,[{X,Y},Dir1,R1,_,_]}] = ets:lookup(cars,Pid),
  [{{R2,_},[{X2,Y2},LightPid]}] = ets:lookup(junction,FirstKey),
  case R1==R2 of
    false -> close_to_junction(Pid,ets:next(junction,FirstKey));
    _ -> case Dir1 of
           left -> D = X-X2, if
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



far_from_car(Who,Other_car) ->link(Who),
  [{_,[{X,Y},Dir1,_,_,_]}] = ets:lookup(cars,Who),
  [{_,[{X2,Y2},_,_,_,_]}] = ets:lookup(cars,Other_car),
  case Dir1 of
    left -> D = X-X2, if
                        D >= 100  -> cars:far_from_car(Who);
                        true -> far_from_car(Who,Other_car)
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

  end.

outOfRange(Pid)-> link(Pid),
  [{_,[{X,Y},Dir,Road,_,_]}] = ets:lookup(cars,Pid),
  if
    X < 0; Y < 0; X > 1344; Y > 890 ->cars:kill(Pid);

    true -> outOfRange(Pid)
  end.


traffic_light_sensor(KeyList,'$end_of_table') -> traffic_light_sensor(KeyList,ets:first(junction));
traffic_light_sensor(KeyList,Key) ->
  [{{R2,J},[{X2,Y2},LightPid]}] =  ets:lookup(junction,Key),

  case LightPid of
    nal -> traffic_light_sensor(KeyList,ets:next(junction,Key));
    _-> case sys:get_state(LightPid) of
          {green,_} -> L = [{Road,Junc}|| {Road,Junc} <- KeyList, J == Junc, Road /= R2],
          sync_traffic(L), traffic_light:sensor_msg(LightPid,green), timer:sleep(200), traffic_light_sensor(KeyList,ets:next(junction,Key));
          _-> traffic_light_sensor(KeyList,ets:next(junction,Key))
        end
  end.

sync_traffic([]) -> ok;
sync_traffic([H|T]) ->  [{{_,_},[{_,_},LightPid]}] =  ets:lookup(junction,H),
  traffic_light:sensor_msg(LightPid,red),sync_traffic(T).


