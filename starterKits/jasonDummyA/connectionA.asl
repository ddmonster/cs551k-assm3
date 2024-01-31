/* Initial beliefs and rules */
random_dir(DirList,RandomNumber,Dir) :- (RandomNumber <= 0.25 & .nth(0,DirList,Dir)) | (RandomNumber <= 0.5 & .nth(1,DirList,Dir)) | (RandomNumber <= 0.75 & .nth(2,DirList,Dir)) | (.nth(3,DirList,Dir)).
currentPosition(64,64).
previousPosition(64,64).
/* Initial goals */

!start.


/*    Percepts updates - now done through !reportBeliefs    */
/*
+thing(X,Y, dispenser, T)[source(percept)] <- !updateDispensers(X,Y,T).
+thing(X,Y, block, T)[source(percept)] <- !updateBlocks(X,Y,T).
+obstacle(X,Y)[source(percept)] <- !updateObstacles(X,Y).
+goal(X,Y)[source(percept)] <- !updateGoals(X,Y).
*/


/* Plans */

+!start : true <- 
	//.print("hello massim world.").
	true.

+step(Xstep) : true <-
	//.print("Received step percept.");
	//check if last move was successful
	!revertPositionIfUnsuccessful;
	//update the internal maps with percepts
	!reportBeliefs.


	
+actionID(Xactionid) : true <- 
	//.print("Determining my action");
	!move_random.
//	skip.

+!move_random : .random(RandomNumber) & random_dir([n,s,e,w],RandomNumber,Dir) & currentPosition(X,Y)
<-	
	!moveAndUpdate(Dir, X, Y).

//plan to use for moving, which includes positional updates.
+!moveAndUpdate(Dir, X, Y): true <-
	move(Dir);!updatePosition(Dir); -previousPosition(_,_); +previousPosition(X,Y).

// update position after submitting the "move" action.
//if move action is unsuccessful, this will be reverted after percepting NEEDS MORE TESTING
@updatePosition[atomic]
+!updatePosition(V) : currentPosition(X,Y) & V = n <-
	-currentPosition(X,Y);+currentPosition(X, Y - 1).
+!updatePosition(V) : currentPosition(X,Y) & V = s <-
	-currentPosition(X,Y);+currentPosition(X, Y + 1).
+!updatePosition(V) : currentPosition(X,Y) & V = e <-
	-currentPosition(X,Y);+currentPosition(X + 1, Y).
+!updatePosition(V) : currentPosition(X,Y) & V = w <-
	-currentPosition(X,Y);+currentPosition(X - 1, Y).

//revert to last position if move was unsuccessful.
@revertPositionIfUnsuccessful[atomic]
+!revertPositionIfUnsuccessful: lastAction(move) & not lastActionResult(success) & previousPosition(X,Y) <-
	//.print("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAReverting position");
	-currentPosition(_,_); +currentPosition(X,Y).
//otherwise OK, no action needed.
+!revertPositionIfUnsuccessful: true <- true.

/*
+!updateDispensers(X,Y,T): currentPosition(X1,Y1) <-
	+coordinate(X+X1, Y+Y1, dispenser, T).

+!updateBlocks(X,Y,T): currentPosition(X1,Y1) <- true.
	//TODO - blocks are not constant in the worldy

+!updateObstacles(X,Y): currentPosition(X1,Y1) <-
	+coordinate(X+ X1, Y+Y1, obstacle, none).

+!updateGoals(X,Y): currentPosition(X1,Y1) <-
	+coordinate(X + X1, Y+Y1, goal, none).
*/

+!reportBeliefs : currentPosition(X,Y) <- 
    .findall(thing(A,B,dispenser,D),thing(A,B,dispenser,D), Things);	//for mapping, we are only concerned with static objects
	.findall(obstacle(A,B),obstacle(A,B), Obstacles);
	.findall(goal(A,B),goal(A,B), Goals);
	report(Things, Obstacles, Goals,X,Y).				//internal action - see syntax in EISAdapter.java, under ExecuteAction()

	
    