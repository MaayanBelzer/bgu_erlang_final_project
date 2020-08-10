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
-export([close_to_car/2,close_to_junction/2]).

close_to_car(Pid,'$end_of_table') -> close_to_car(Pid,ets:first(cars));
close_to_car(Pid,FirstKey) -> [{_,[{X,Y},Dir1,_,_,_]}] = ets:lookup(cars,Pid),
  [{P2,[{X2,Y2},Dir2,_,_,_]}] = ets:lookup(cars,FirstKey),
  case Dir1 == Dir2 of
    false -> close_to_car(Pid,ets:next(cars,P2));
    _ ->  case Dir1 of
            left -> case Y==Y2 of
                      false -> close_to_car(Pid,ets:next(cars,P2));
                      _ -> D = X-X2, if
                                       D =< 60 , D >= 0, P2 /= Pid -> cars:close_to_car(Pid,P2);
                                       true -> close_to_car(Pid,ets:next(cars,P2))
                                     end
                    end;
            right -> case Y==Y2 of
                       false -> close_to_car(Pid,ets:next(cars,P2));
                       _ -> D = X2-X, if
                                        D =< 60 , D >= 0, P2 /= Pid -> cars:close_to_car(Pid,P2);
                                        true -> close_to_car(Pid,ets:next(cars,P2))
                                      end
                     end;
            up -> case X==X2 of
                    false -> close_to_car(Pid,ets:next(cars,P2));
                    _ -> D = Y-Y2, if
                                     D =< 60 , D >= 0, P2 /= Pid -> cars:close_to_car(Pid,P2);
                                     true -> close_to_car(Pid,ets:next(cars,P2))
                                   end
                  end;
            down -> case X==X2 of
                      false -> close_to_car(Pid,ets:next(cars,P2));
                      _ -> D = Y2-Y, if
                                       D =< 60 , D >= 0, P2 /= Pid -> cars:close_to_car(Pid,P2);
                                       true -> close_to_car(Pid,ets:next(cars,P2))
                                     end
                    end
          end



  end.


close_to_junction(Pid,'$end_of_table') -> close_to_junction(Pid,ets:first(junction));
close_to_junction(Pid,FirstKey) ->  [{_,[{X,Y},Dir1,R1,_,_]}] = ets:lookup(cars,Pid),
  [{{R2,_},[{X2,Y2},LightPid]}] = ets:lookup(junction,FirstKey),
  case R1==R2 of
    false -> close_to_junction(Pid,ets:next(junction,FirstKey));
    _ -> case Dir1 of
           left -> D = X-X2, if
                               D =< 60 , D >= 0-> case LightPid of
                                                    nal -> cars:close_to_junc(Pid,green,FirstKey),
                                                      timer:sleep(2000),
                                                      close_to_junction(Pid,ets:first(junction));
                                                    LP -> cars:close_to_junc(Pid,sys:get_state(LP),FirstKey),
                                                      timer:sleep(2000),
                                                      close_to_junction(Pid,ets:first(junction))
                                                  end;
                               true -> close_to_junction(Pid,ets:next(junction,FirstKey))
                             end;
           right -> D = X2-X, if
                                D =< 60 , D >= 0-> case LightPid of
                                                     nal -> cars:close_to_junc(Pid,green,FirstKey),
                                                       timer:sleep(2000),
                                                       close_to_junction(Pid,ets:first(junction));
                                                     LP -> cars:close_to_junc(Pid,sys:get_state(LP),FirstKey),
                                                       timer:sleep(2000),
                                                       close_to_junction(Pid,ets:first(junction))
                                                   end;
                                true -> close_to_junction(Pid,ets:next(junction,FirstKey))
                              end;
           up -> D = Y-Y2, if
                             D =< 60 , D >= 0-> case LightPid of
                                                  nal -> cars:close_to_junc(Pid,green,FirstKey),
                                                    timer:sleep(2000),
                                                    close_to_junction(Pid,ets:first(junction));
                                                  LP -> cars:close_to_junc(Pid,sys:get_state(LP),FirstKey),
                                                    timer:sleep(2000),
                                                    close_to_junction(Pid,ets:first(junction))
                                                end;
                             true -> close_to_junction(Pid,ets:next(junction,FirstKey))
                           end;
           down -> D = Y2-Y, if
                               D =< 60 , D >= 0-> case LightPid of
                                                    nal -> cars:close_to_junc(Pid,green,FirstKey),
                                                      timer:sleep(2000),
                                                      close_to_junction(Pid,ets:first(junction));
                                                    LP -> cars:close_to_junc(Pid,sys:get_state(LP),FirstKey),
                                                      timer:sleep(2000),
                                                      close_to_junction(Pid,ets:first(junction))
                                                  end;
                               true -> close_to_junction(Pid,ets:next(junction,FirstKey))
                             end

         end
  end.



