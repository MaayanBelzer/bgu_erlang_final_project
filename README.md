# Car Network Routing System
 Concurrent and Distributed Systems implemented in Erlang OTP 
</br> </br>
## Background
In this project we implemented a car network routing system based on a given road map. The map includes one way streets with two lanes over which cars move and respond to the environment according to external events. 
</br> 
The system is comprised of several main components:
</br>
Cars with accompanied sensors, external servers, communication towers and scattered traffic lights along the road.
</br>
All of the cars are state machines which move independently in parallel to one another.
</br>
Using communication towers along the road, the cars transfer information to external servers which make decisions regarding the continuation of their journey. Each car is accompanied with several processes which mimic sensors that monitor information from the car's surroundings. This information creates an event in the car's state machine, and the car responds according to the event.
</br>
The road map is divided into four regions, so that a different server is responsible for each region and for routing the cars in said region. These servers are located on different computers. Furhtermore, there is a fifth computer which is in charge of the graphic display of the system.
</br>
## The Systems' Components
### 1. Cars
A car is a state machine implemented with gen_statem. The cars ride along the roads on the map and respond to their surrounding using the information which is passed onto them by their sensors. Some of the events require immediate attention and are attended to locally by the vehicle itself. The rest of the events are taken care of by the external servers.
</br>
### 2. Car Sensors
The sensors are parallel processes all of which are spawned when the car is initialized, except for the sensor which indicates when a car in front of the current car has moved away from it. This sensor is spawned when the current car has come close to a different car. 
</br>
The different sensors are: 
- Close to car: this sensor indicates when the car has come close to another car.
- Close to juction: this sensor indicates when the car has come close to a junction.
- Accident: this sensor indicates when the car has crashed into another car.
- Out of range: this sensor indicates when a car has left the map entirely, or has moved from one region to another.
- Car deviation: this sensor indicates when a car has deviated from the road.
- Far from car: as stated above.
### 3. External Server
Each external server is implemented with gen_server and communicates with the different cars through the communication towers which are located along the roads. The server deals with events such as two cars getting close to one another and a car accident. Moreover, the server synchronizes the different traffic lights on the map to prevent accidents and heavy traffic.
</br>
### 4. Communication Towers
The communication towers are secondary servers implemented with gen_server. These towers are scattered on the map and tranfer information between the car and the servers and vice versa. Each communication tower that recieves a message classifies it and transfers it to a car or to the server according to the destination of the message.
</br>
### 5. Traffic Lights
Traffic lights are state machines implemented with gen_statem. The color of the traffic lights change within a set time or according to an event which is triggered by the server.
### 6. Monitor
The monitor is a parallel process which can handle the following situations:
- Fallen computer.
- Adding a process to monitor.
- Fallen process (which can be a car or a sensor).
- Car exiting the map's borders.
- Car moving from one region to another.
- Car accident.
### 7. Navigation System
This system is activated when the user has pressed down on a car using the left click. After a car has been selected, the user can now choose a junction as a destination for the car. The server will then calculate the shortest path to get to the destination and the car will move according to it. 
### 8. Main Computer
This computer is in charge of the graphic display of the different entities and is implemented with wx_object. When the program initializes, this computer connects all of the different computers, it initializes the servers, cars and graphic display. The main computer goes over ETS tables in set time periods and updates the cars' locations. When one of the computers goes down, an event is triggered in the main computer and it informs the other computers about the fallen one, and transfers the cars which were in the fallen computer's region to a backup computer. 
</br></br>
## Activation Instructions
### Multiple Computers
</br>
1. Insert into the file header.hrl the IP addresses of the secondary computers in the following manner:
</br>
-define(PC1, 'PC1@IP_ADDRESS1).
</br>
-define(PC2, 'PC2@IP_ADDRESS2).
</br>
-define(PC3,'PC3@IP_ADDRESS3').
</br>
-define(PC4, 'PC4@ IP_ADDRESS4').
</br>
2. For the main computer, insert the following into the same file:
-define(Home,'home@IP_ADDRESS5').
</br>
3. For each secondary computer, open a terminal and enter the following:
erl -setcookie dough -name PCn@IP_ADDRESS
Where n is the computer's number and IP_ADDRESS is the same IP address as the header.hrl file.
</br>
4. For the main computer, open a terminal and enter the following:
erl -setcookie dough -name home@IP_ADDRESS
Where IP_ADDRESS is the same IP address as the header.hrl file.
</br>
5. In each terminal, enter the following to compile the files:
c(cars).
</br>
c(sensors).
</br>
c(server).
</br>
c(communication_tower).
</br>
c(traffic_light).
</br>
c(main).
</br>
6. In the main computer enter the command:
main:start(). 

### Single Computer 

</br>
1. Insert into the file header.hrl the IP address of the computer in the following manner:
</br>
-define(PC1, 'PC1@127.0.0.1').
</br>
-define(PC2, 'PC2@127.0.0.1').
</br>
-define(PC3,'PC3@127.0.0.1').
</br>
-define(PC4, 'PC4@127.0.0.1').
</br>
-define(Home,'home@127.0.0.1').
</br>
2. Open five nodes and enter the following command into four of them:
</br>
erl -setcookie dough -name PCn@IP_ADDRESS
</br>
Where n is the computer's number and IP_ADDRESS is the same IP address as the header.hrl file.
</br>
3. On the fifth node, enter the following command:
</br>
erl -setcookie dough -name home@IP_ADDRESS
</br>
Where IP_ADDRESS is the same IP address as the header.hrl file.
</br>
4. In each terminal, enter the following to compile the files:
</br>
c(cars).
</br>
c(sensors).
</br>
c(server).
</br>
c(communication_tower).
</br>
c(traffic_light).
</br>
c(main).
</br>
5. In the main computer enter the command:
</br>
main:start().

### Creators
*Maayan Belzer*  
Computer Engineer, Ben-gurion University, Israel

*Nir Tapiero*  
Computer Engineer, Ben-gurion University, Israel
