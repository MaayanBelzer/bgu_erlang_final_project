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
-export([close_to_car/2,close_to_junction/2,far_from_car/2,outOfRange/1,
  traffic_light_sensor/2,car_accident/2,car_monitor/0]).

close_to_car(Pid,'$end_of_table') -> close_to_car(Pid,ets:first(cars));
close_to_car(Pid,FirstKey) ->


  [{_,[{X,Y},Dir1,_,_,_]}] = ets:lookup(cars,Pid),
  Bool = ets:member(cars,FirstKey),
  if
    Bool == true->
      Bool2 = ets:member(cars,FirstKey),
      if
        Bool2 == true -> [{P2,[{X2,Y2},Dir2,_,_,_]}] = ets:lookup(cars,FirstKey);
        true -> [{P2,[{X2,Y2},Dir2,_,_,_]}] = ets:lookup(cars,ets:first(cars))
      end;


    true -> [{P2,[{X2,Y2},Dir2,_,_,_]}] = ets:lookup(cars,ets:first(cars))
  end,
%  [{P2,[{X2,Y2},Dir2,_,_,_]}] = ets:lookup(cars,FirstKey),
  case Dir1 == Dir2 of
    false -> case ets:member(cars,P2) of
               true -> close_to_car(Pid,ets:next(cars,P2));
               _-> close_to_car(Pid,ets:first(cars))
             end;
    %close_to_car(Pid,ets:next(cars,P2));
    _ ->  case Dir1 of
            left -> case abs(Y-Y2)=<7  of
                      false -> case ets:member(cars,P2) of
                                 true -> close_to_car(Pid,ets:next(cars,P2));
                                 _-> close_to_car(Pid,ets:first(cars))
                               end;
                      %close_to_car(Pid,ets:next(cars,P2));
                      _ -> D = X-X2, if
                                       D =< 60 , D >= 0, P2 /= Pid -> cars:close_to_car(Pid,P2),
                                         timer:sleep(3000),
                                         close_to_car(Pid,ets:first(cars));
                                       true -> case ets:member(cars,P2) of
                                                 true -> close_to_car(Pid,ets:next(cars,P2));
                                                 _-> close_to_car(Pid,ets:first(cars))
                                               end
                      %close_to_car(Pid,ets:next(cars,P2))
                                     end
                    end;
            right -> case abs(Y-Y2)=<7 of
                       false -> case ets:member(cars,P2) of
                                  true -> close_to_car(Pid,ets:next(cars,P2));
                                  _-> close_to_car(Pid,ets:first(cars))
                                end;
                       %close_to_car(Pid,ets:next(cars,P2));
                       _ -> D = X2-X, if
                                        D =< 60 , D >= 0, P2 /= Pid -> cars:close_to_car(Pid,P2),
                                          timer:sleep(3000),
                                          close_to_car(Pid,ets:first(cars));
                                        true -> case ets:member(cars,P2) of
                                                  true -> close_to_car(Pid,ets:next(cars,P2));
                                                  _-> close_to_car(Pid,ets:first(cars))
                                                end
                       %close_to_car(Pid,ets:next(cars,P2))
                                      end
                     end;
            up -> case abs(X-X2)=<7  of
                    false -> case ets:member(cars,P2) of
                               true -> close_to_car(Pid,ets:next(cars,P2));
                               _-> close_to_car(Pid,ets:first(cars))
                             end;
                    %close_to_car(Pid,ets:next(cars,P2));
                    _ -> D = Y-Y2, if
                                     D =< 60 , D >= 0, P2 /= Pid -> cars:close_to_car(Pid,P2),
                                       timer:sleep(3000),
                                       close_to_car(Pid,ets:first(cars));
                                     true -> case ets:member(cars,P2) of
                                               true -> close_to_car(Pid,ets:next(cars,P2));
                                               _-> close_to_car(Pid,ets:first(cars))
                                             end
                    %close_to_car(Pid,ets:next(cars,P2))
                                   end
                  end;
            down -> case abs(X-X2)=<7 of
                      false -> case ets:member(cars,P2) of
                                 true -> close_to_car(Pid,ets:next(cars,P2));
                                 _-> close_to_car(Pid,ets:first(cars))
                               end;
                      %close_to_car(Pid,ets:next(cars,P2));
                      _ -> D = Y2-Y, if
                                       D =< 60 , D >= 0, P2 /= Pid -> cars:close_to_car(Pid,P2),
                                         timer:sleep(3000),
                                         close_to_car(Pid,ets:first(cars));
                                       true -> case ets:member(cars,P2) of
                                                 true -> close_to_car(Pid,ets:next(cars,P2));
                                                 _-> close_to_car(Pid,ets:first(cars))
                                               end
                      %close_to_car(Pid,ets:next(cars,P2))
                                     end
                    end
          end



  end.


close_to_junction(Pid,'$end_of_table') -> close_to_junction(Pid,ets:first(junction));
close_to_junction(Pid,FirstKey) ->



  [{_,[{X,Y},Dir1,R1,_,_]}] = ets:lookup(cars,Pid),

  [{{R2,_},[{X2,Y2},LightPid]}] = ets:lookup(junction,FirstKey),

%  [{{R2,_},[{X2,Y2},LightPid,{_,_}]}] = ets:lookup(junction,FirstKey),
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
%  [{{R2,J},[{X2,Y2},LightPid,{_,_}]}] =  ets:lookup(junction,Key),

  case LightPid of
    nal -> traffic_light_sensor(KeyList,ets:next(junction,Key));
    _-> case sys:get_state(LightPid) of
          {green,_} -> L = [{Road,Junc}|| {Road,Junc} <- KeyList, J == Junc, Road /= R2],
            sync_traffic(L), traffic_light:sensor_msg(LightPid,green), timer:sleep(200), traffic_light_sensor(KeyList,ets:next(junction,Key));
          _-> traffic_light_sensor(KeyList,ets:next(junction,Key))
        end
  end.

sync_traffic([]) -> ok;
sync_traffic([H|T]) ->
  [{{_,_},[{_,_},LightPid]}] =  ets:lookup(junction,H),
%  [{{_,_},[{_,_},LightPid,{_,_}]}] =  ets:lookup(junction,H),
  traffic_light:sensor_msg(LightPid,red),sync_traffic(T).


car_accident(Pid,'$end_of_table') -> car_accident(Pid,ets:first(cars));
car_accident(Pid,Key) ->
  [{_,[{X,Y},_,_,_,_]}] = ets:lookup(cars,Pid),
  Bool = ets:member(cars,Key),
  if
    Bool == true->
      Bool2 = ets:member(cars,Key),
      if
        Bool2 == true -> [{P2,[{X2,Y2},_,_,_,_]}] = ets:lookup(cars,Key);
        true -> [{P2,[{X2,Y2},_,_,_,_]}] = ets:lookup(cars,ets:first(cars))
      end;
    true -> [{P2,[{X2,Y2},_,_,_,_]}] = ets:lookup(cars,ets:first(cars))
  end,

  D = math:sqrt(math:pow(X-X2,2) + math:pow(Y-Y2,2)),
  if
    D =< 20, Pid /= P2 -> %io:format("ACCIDENT between ~p and ~p ~n",[Pid,P2]),
      cars:accident(Pid,P2),cars:accident(P2,Pid);
      % cars:kill(Pid),cars:kill(P2);%cars:accident(Pid,P2) ;
    true ->  case ets:member(cars,P2) of
               true ->  car_accident(Pid,ets:next(cars,P2));
               _-> car_accident(Pid,ets:first(cars))
             end

  end.



car_monitor() ->

  receive
    {add_to_monitor,Pid} -> monitor(process, Pid),car_monitor();
      %io:format("~p is alive ~n",[Pid]),car_monitor();
    {_, _, _, Pid, Reason} ->  case Reason of
                                 {outOfRange,E1,E2,E3,E4} ->
                                   %io:format("~p killed with reason outOfRange ~n",[Pid]),
                                   %io:format("~p~n~p~n~p~n~p~n",[E1,E2,E3,E4]),
                                   cars:start(E1,E2,E4,E3),car_monitor();


                                 move_to_comp1 -> [];
                                 move_to_comp2 -> [];
                                 move_to_comp3 -> [];
                                 move_to_comp4 -> [];
                                 {accident,E1,E2,E3,E4} -> io:format("~p killed in accident ~n",[Pid]),
                                   case ets:member(cars,Pid) of
                                     true -> timer:sleep(1000),
                                       ets:delete(cars,Pid);
                                     _->io:format("~p is in ets: ~p ~n",[Pid,ets:member(cars,Pid)])
                                   end,


                                   car_monitor();
                                 Else->  io:format("~p killed in reason ~p ~n",[Pid,Else]),car_monitor()
                               end

    after 0 -> car_monitor()
  end .
