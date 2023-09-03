% Declaring most predicates as dynamic:
:- dynamic visited/2.
:- dynamic current/3.
:- dynamic wumpus/2.
:- dynamic confundus/2.
:- dynamic tingle/2.
:- dynamic glitter/2.
:- dynamic stench/2.
:- dynamic safe/2.
:- dynamic wall/2.
:- dynamic hasarrow/1.
:- dynamic explore/1.

current(0,0,rnorth).

different(X,Y) :- X = Y, !, fail ; true.
% Taken from:
% https://www.tutorialspoint.com/prolog/prolog_different_and_not.htm

equals(A, B) :-
    not(different(A,B)).

% Information about assertz keyword
% http://aspc.cs.upt.ro/~calin/lab09.html

% Use DFS/Backtracking to find a path to each safe, unvisited cell
% Instead of using actual visited/2 and current/3, we created
% sim_visited and sim_current for use in the DFS simulation.
% However, actual visited is still needed for us to know whether
% a new Sequence L needs to be asserted or not.
dfs(L) :-
    sim_current(X,Y,D),
    (visited(X,Y);
    assertz(explore(L))),
    % Only add the current path to explore(L) if current location is unvisited
    (
    sim_current(X,Y,D),
    assertz(sim_visited(X,Y)), % update (simulation) visited

    % get positions of next 4 neighbours(above, right, below, left)
    % =============================================================
    equals(D,rnorth),
    X1 is X, Y1 is Y+1,
    X2 is X+1, Y2 is Y,
    X3 is X, Y3 is Y-1,
    X4 is X-1, Y4 is Y;

    sim_current(X,Y,D),
    equals(D,rsouth),
    X1 is X, Y1 is Y-1,
    X2 is X-1, Y2 is Y,
    X3 is X, Y3 is Y+1,
    X4 is X+1, Y4 is Y;

    sim_current(X,Y,D),
    equals(D,reast),
    X1 is X+1, Y1 is Y,
    X2 is X, Y2 is Y-1,
    X3 is X-1, Y3 is Y,
    X4 is X, Y4 is Y+1;

    sim_current(X,Y,D),
    equals(D,rwest),
    X1 is X-1, Y1 is Y,
    X2 is X, Y2 is Y+1,
    X3 is X+1, Y3 is Y,
    X4 is X, Y4 is Y-1),
    % =============================================================

    % Forward neighbour
    % =============================================================
    (
    retractall(sim_current(_,_,_)),
    equals(D,rnorth),assertz(sim_current(X1,Y1,rnorth));
    equals(D,rsouth),assertz(sim_current(X1,Y1,rsouth));
    equals(D,reast),assertz(sim_current(X1,Y1,reast));
    equals(D,rwest),assertz(sim_current(X1,Y1,rwest))),

    ((not(safe(X1,Y1));wall(X1,Y1);sim_visited(X1,Y1));
    append(L,[moveforward],Z),dfs(Z)),
    % =============================================================

    % Right neighbour
    % =============================================================
    (
    retractall(sim_current(_,_,_)),
    equals(D,rnorth),assertz(sim_current(X2,Y2,reast));
    equals(D,rsouth),assertz(sim_current(X2,Y2,rwest));
    equals(D,reast),assertz(sim_current(X2,Y2,rsouth));
    equals(D,rwest),assertz(sim_current(X2,Y2,rnorth))),

    ((not(safe(X2,Y2));wall(X2,Y2);sim_visited(X2,Y2));
    append(L,[turnright,moveforward],Z2),dfs(Z2)),
    % =============================================================

    % Reverse neighbour
    % =============================================================
    (
    retractall(sim_current(_,_,_)),
    equals(D,rnorth),assertz(sim_current(X3,Y3,rsouth));
    equals(D,rsouth),assertz(sim_current(X3,Y3,rnorth));
    equals(D,reast),assertz(sim_current(X3,Y3,rwest));
    equals(D,rwest),assertz(sim_current(X3,Y3,reast))),

    ((not(safe(X3,Y3));wall(X3,Y3);sim_visited(X3,Y3));
    append(L,[turnright,turnright,moveforward],Z3),dfs(Z3)),
    % =============================================================

    % Left neighbour
    % =============================================================
    (
    retractall(sim_current(_,_,_)),
    equals(D,rnorth),assertz(sim_current(X4,Y4,rwest));
    equals(D,rsouth),assertz(sim_current(X4,Y4,reast));
    equals(D,reast),assertz(sim_current(X4,Y4,rnorth));
    equals(D,rwest),assertz(sim_current(X4,Y4,rsouth))),

    ((not(safe(X4,Y4));wall(X4,Y4);sim_visited(X4,Y4));
    append(L,[turnleft,moveforward],Z4),dfs(Z4)).
    % =============================================================

reborn() :-
    assertz(hasarrow), % return arrow to Agent
    reposition([on,off,off,off,off,off]),!.

reposition([_,Stench,Tingle,Glitter,_,_]) :-
    retractall(current(_,_,_)),
    assertz(current(0,0,rnorth)), % reset relative position

    % reset all previous knowledge about the Map
    % ======================================================
    retractall(visited(_,_)),
    retractall(wumpus(_,_)),
    retractall(confundus(_,_)),
    retractall(tingle(_,_)),
    retractall(glitter(_,_)),
    retractall(stench(_,_)),
    retractall(wall(_,_)),
    retractall(safe(_,_)),
    retractall(no_confundus(_,_)),
    retractall(no_wumpus(_,_)),
    % ======================================================

    % mark new position as safe and visited
    % ======================================================
    assertz(visited(0,0)),
    assertz(safe(0,0)),
    assertz(no_confundus(0,0)),
    assertz(no_wumpus(0,0)),
    % ======================================================
    update_map(Stench,Tingle,Glitter),
    retractall(sim_current(_,_,_)),assertz(sim_current(0,0,rnorth)),
    retractall(sim_visited(_,_)),retractall(explore(_)),dfs([]),!.

put_wumpus(X,Y) :-
    no_wumpus(X,Y);
    wumpus(X,Y);
    assertz(wumpus(X,Y)). % update possible wumpus location

put_no_wumpus(X,Y) :-
    no_wumpus(X,Y);
    assertz(no_wumpus(X,Y)), % update impossible wumpus location
    update_safe(X,Y), % update safe location if necessary
    not(wumpus(X,Y));
    wumpus(X,Y),retract(wumpus(X,Y)). % remove possible wumpus location

put_conf(X,Y) :-
    no_confundus(X,Y);
    confundus(X,Y);
    assertz(confundus(X,Y)). % update possible confundus location

put_no_conf(X,Y) :-
    no_confundus(X,Y);
    assertz(no_confundus(X,Y)), % update impossible confundus location
    update_safe(X,Y), % update safe location if necessary
    not(confundus(X,Y));
    confundus(X,Y),retract(confundus(X,Y)). % remove possible confundus location

 % Update knowledge base based on sensory input data and current
 % relative position. If stench/tingle is/are on, update possible
 % wumpus/confundus locations. If stench/tingle is/are off, update
 % impossible wumpus/confundus locations.
update_map(Stench,Tingle,Glitter) :-
    equals(Stench,on),equals(Tingle,on),equals(Glitter,on),
    current(X,Y,_),
    assertz(stench(X,Y)),assertz(tingle(X,Y)),assertz(glitter(X,Y)),
    Above_y is Y+1, Right_x is X+1,
    Below_y is Y-1, Left_x is X-1,
    put_wumpus(X,Above_y),put_wumpus(X,Below_y),
    put_wumpus(Right_x,Y),put_wumpus(Left_x,Y),
    put_conf(X,Above_y),put_conf(X,Below_y),
    put_conf(Right_x,Y),put_conf(Left_x,Y),
    put_no_wumpus(X,Y),put_no_conf(X,Y);

    equals(Stench,on),equals(Tingle,on),
    current(X,Y,_),
    assertz(stench(X,Y)),assertz(tingle(X,Y)),
    Above_y is Y+1, Right_x is X+1,
    Below_y is Y-1, Left_x is X-1,
    put_wumpus(X,Above_y),put_wumpus(X,Below_y),
    put_wumpus(Right_x,Y),put_wumpus(Left_x,Y),
    put_conf(X,Above_y),put_conf(X,Below_y),
    put_conf(Right_x,Y),put_conf(Left_x,Y),
    put_no_wumpus(X,Y),put_no_conf(X,Y);

    equals(Glitter,on),equals(Tingle,on),
    current(X,Y,_),
    assertz(glitter(X,Y)),assertz(tingle(X,Y)),
    Above_y is Y+1, Right_x is X+1,
    Below_y is Y-1, Left_x is X-1,
    put_no_wumpus(X,Above_y),put_no_wumpus(X,Below_y),
    put_no_wumpus(Right_x,Y),put_no_wumpus(Left_x,Y),
    put_conf(X,Above_y),put_conf(X,Below_y),
    put_conf(Right_x,Y),put_conf(Left_x,Y),
    put_no_wumpus(X,Y),put_no_conf(X,Y);

    equals(Glitter,on),equals(Stench,on),
    current(X,Y,_),
    assertz(glitter(X,Y)),assertz(stench(X,Y)),
    Above_y is Y+1, Right_x is X+1,
    Below_y is Y-1, Left_x is X-1,
    put_no_conf(X,Above_y),put_no_conf(X,Below_y),
    put_no_conf(Right_x,Y),put_no_conf(Left_x,Y),
    put_wumpus(X,Above_y),put_wumpus(X,Below_y),
    put_wumpus(Right_x,Y),put_wumpus(Left_x,Y),
    put_no_wumpus(X,Y),put_no_conf(X,Y);

    equals(Stench,on),
    current(X,Y,_),
    assertz(stench(X,Y)),
    Above_y is Y+1, Right_x is X+1,
    Below_y is Y-1, Left_x is X-1,
    put_no_conf(X,Above_y),put_no_conf(X,Below_y),
    put_no_conf(Right_x,Y),put_no_conf(Left_x,Y),
    put_wumpus(X,Above_y),put_wumpus(X,Below_y),
    put_wumpus(Right_x,Y),put_wumpus(Left_x,Y),
    put_no_wumpus(X,Y),put_no_conf(X,Y);

    equals(Tingle,on),
    current(X,Y,_),
    assertz(tingle(X,Y)),
    Above_y is Y+1, Right_x is X+1,
    Below_y is Y-1, Left_x is X-1,
    put_no_wumpus(X,Above_y),put_no_wumpus(X,Below_y),
    put_no_wumpus(Right_x,Y),put_no_wumpus(Left_x,Y),
    put_conf(X,Above_y),put_conf(X,Below_y),
    put_conf(Right_x,Y),put_conf(Left_x,Y),
    put_no_wumpus(X,Y),put_no_conf(X,Y);

    equals(Glitter,on),
    current(X,Y,_),
    assertz(glitter(X,Y)),
    Above_y is Y+1, Right_x is X+1,
    Below_y is Y-1, Left_x is X-1,
    put_no_conf(X,Above_y),put_no_conf(X,Below_y),
    put_no_conf(Right_x,Y),put_no_conf(Left_x,Y),
    put_no_wumpus(X,Above_y),put_no_wumpus(X,Below_y),
    put_no_wumpus(Right_x,Y),put_no_wumpus(Left_x,Y);

    equals(Stench,off),equals(Tingle,off),equals(Glitter,off),
    current(X,Y,_),
    Above_y is Y+1, Right_x is X+1,
    Below_y is Y-1, Left_x is X-1,
    put_no_conf(X,Above_y),put_no_conf(X,Below_y),
    put_no_conf(Right_x,Y),put_no_conf(Left_x,Y),
    put_no_wumpus(X,Above_y),put_no_wumpus(X,Below_y),
    put_no_wumpus(Right_x,Y),put_no_wumpus(Left_x,Y),
    put_no_wumpus(X,Y),put_no_conf(X,Y).

move(A,[_,Stench,Tingle,Glitter,Bump,Scream]) :-
    (   %equals(Confounded,on),
    %reposition([Confounded,Stench,Tingle,Glitter,Bump,Scream]);

    equals(Bump,on),just_bumped(),
    retractall(sim_current(_,_,_)),
    current(X,Y,D),assertz(sim_current(X,Y,D)),
    retractall(sim_visited(_,_)),retractall(explore(_)),dfs([]),
    (explore(_); % if no path returned, find a path to origin instead
    retract(visited(0,0)),retractall(sim_current(_,_,_)),
    assertz(sim_current(X,Y,D)),
    retractall(sim_visited(_,_)),dfs([]),assertz(visited(0,0)));

    equals(A,shoot),just_shot(Scream),
    retractall(sim_current(_,_,_)),
    current(X,Y,D),assertz(sim_current(X,Y,D)),
    retractall(sim_visited(_,_)),retractall(explore(_)),dfs([]),
    (explore(_);
    retract(visited(0,0)),retractall(sim_current(_,_,_)),
    assertz(sim_current(X,Y,D)),
    retractall(sim_visited(_,_)),dfs([]),assertz(visited(0,0)));

    just_turned(A),
    retractall(sim_current(_,_,_)),
    current(X,Y,D),assertz(sim_current(X,Y,D)),
    retractall(sim_visited(_,_)),retractall(explore(_)),dfs([]),
    (explore(_);
    retract(visited(0,0)),retractall(sim_current(_,_,_)),
    assertz(sim_current(X,Y,D)),
    retractall(sim_visited(_,_)),dfs([]),assertz(visited(0,0)));

    equals(A,pickup),just_picked_up();

    just_moved(Stench,Tingle,Glitter),
    retractall(sim_current(_,_,_)),
    current(X,Y,D),assertz(sim_current(X,Y,D)),
    retractall(sim_visited(_,_)),retractall(explore(_)),dfs([]),
    (explore(_);
    retract(visited(0,0)),retractall(sim_current(_,_,_)),
    assertz(sim_current(X,Y,D)),
    retractall(sim_visited(_,_)),dfs([]),assertz(visited(0,0)))
    ),!.

just_moved(Stench,Tingle,Glitter) :-
    current(X,Y,D),equals(D,rnorth),Above_y is Y+1,
    retractall(current(_,_,_)),assertz(current(X,Above_y,D)),
    assertz(safe(X,Above_y)),
    (visited(X,Above_y);assertz(visited(X,Above_y))),
    update_map(Stench,Tingle,Glitter);

    current(X,Y,D),equals(D,rsouth),Below_y is Y-1,
    retractall(current(_,_,_)),assertz(current(X,Below_y,D)),
    assertz(safe(X,Below_y)),
    (visited(X,Below_y);assertz(visited(X,Below_y))),
    update_map(Stench,Tingle,Glitter);

    current(X,Y,D),equals(D,reast),Right_x is X+1,
    retractall(current(_,_,_)),assertz(current(Right_x,Y,D)),
    assertz(safe(Right_x,Y)),
    (visited(Right_x,Y);assertz(visited(Right_x,Y))),
    update_map(Stench,Tingle,Glitter);

    current(X,Y,D),equals(D,rwest),Left_x is X-1,
    retractall(current(_,_,_)),assertz(current(Left_x,Y,D)),
    assertz(safe(Left_x,Y)),
    (visited(Left_x,Y);assertz(visited(Left_x,Y))),
    update_map(Stench,Tingle,Glitter).

just_picked_up() :-
    current(X,Y,_),
    not(glitter(X,Y));
    glitter(X,Y),retract(glitter(X,Y)),just_picked_up.
    % recurse to remove duplicates

% Update Agent's orientation based on turn direction and
% his current orientation.
just_turned(A) :-
    current(X,Y,D),
    equals(A,turnleft),equals(D,rnorth),
    retract(current(X,Y,D)), assertz(current(X,Y,rwest));

    current(X,Y,D),
    equals(A,turnleft),equals(D,rsouth),
    retract(current(X,Y,D)), assertz(current(X,Y,reast));

    current(X,Y,D),
    equals(A,turnleft),equals(D,reast),
    retract(current(X,Y,D)), assertz(current(X,Y,rnorth));

    current(X,Y,D),
    equals(A,turnleft),equals(D,rwest),
    retract(current(X,Y,D)), assertz(current(X,Y,rsouth));

    current(X,Y,D),
    equals(A,turnright),equals(D,rnorth),
    retract(current(X,Y,D)), assertz(current(X,Y,reast));

    current(X,Y,D),
    equals(A,turnright),equals(D,rsouth),
    retract(current(X,Y,D)), assertz(current(X,Y,rwest));

    current(X,Y,D),
    equals(A,turnright),equals(D,reast),
    retract(current(X,Y,D)), assertz(current(X,Y,rsouth));

    current(X,Y,D),
    equals(A,turnright),equals(D,rwest),
    retract(current(X,Y,D)), assertz(current(X,Y,rnorth)).

just_bumped :-
    current(X,Y,D),
    equals(D,rnorth),Above_y is Y+1,assertz(wall(X,Above_y));

    current(X,Y,D),
    equals(D,rsouth),Below_y is Y-1,assertz(wall(X,Below_y));

    current(X,Y,D),
    equals(D,reast),Right_x is X+1,assertz(wall(Right_x,Y));

    current(X,Y,D),
    equals(D,rwest),Left_x is X-1,assertz(wall(Left_x,Y)).

just_shot(Scream) :-
    equals(Scream,on),
    retractall(hasarrow),retractall(stench(_,_)),not(remove_wumpus);
    different(Scream,on),
    retractall(hasarrow).

remove_wumpus :-
    wumpus(X,Y),put_no_wumpus(X,Y),
    remove_wumpus.

update_safe(X,Y) :-
    not(is_safe(X,Y));
    is_safe(X,Y),assertz(safe(X,Y)).

is_safe(X,Y) :-
    no_wumpus(X,Y),no_confundus(X,Y).
