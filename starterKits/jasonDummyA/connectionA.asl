/* Initial beliefs and rules */
random_dir(DirList,RandomNumber,Dir) :- 
(RandomNumber <= 0.25 & .nth(0,DirList,Dir)) |
(RandomNumber <= 0.5 & .nth(1,DirList,Dir))  |
(RandomNumber <= 0.75 & .nth(2,DirList,Dir)) | 
(.nth(3,DirList,Dir)).
//random dir that takes into account the boundaries

req1FromTask(ReqList,req(X,Y,DispType)) :- .nth(0, ReqList, req(X,Y,DispType)).	//task(task77,290,40,[req(-1,1,b1),req(0,1,b1)]) - takes [req(-1,1,b1),req(0,1,b1)], returns req(-1,1,b1)
req2FromTask(ReqList,req(X,Y,DispType)) :- .nth(1, ReqList, req(X,Y,DispType)).
currentPosition(64,64).
previousPosition(64,64).
currentState(exploring).
/* Initial goals */

!start.




/* Plans */

+!start : true <- 
	//.print("hello massim world.").
	true.



@step[atomic]	//atomic because currentPosition(X,Y) can confuse the agent as step(X) and actionID(X) can have interleaved execution
+step(Xstep) : true <-
	.print("Received step percept.");
	!revertPositionIfUnsuccessful;								//check if last move was successful	
	!reportBeliefs;												//update the internal maps with percepts
	//!checkIfTaskStillAvailable;								//Check if the task that the agent is focusing on is still available - if not, change to another task TODO
	if(Xstep > 13 & Xstep mod 7 = 0 & currentState(exploring)){	//stop exploring past step 14, if no appropriate tasks found it will return to exploration and revisit each 7 steps
		-currentState(exploring);		
		+currentState(deliberating);
		!findDispenser;											//find the closest dispenser and do something about it
		
	}.



//if agent is travelling to goal and reached goal.
+actionID(Xactionid): currentState(travellingToGoal) & blockAttached(yes) & goal(0,0)  <-
							//TODO: Currently all agents are focusing on the same task, so after one agent has submitted the rest of them will fail
	!submitOrRotate.		//agent is now in position for submission.

//this should be invoked just after agent has submitted a task - go back to finding a new dispenser (or whatever we set the task allocation algorithm to).
+actionID(Xactionid): currentState(travellingToGoal) & blockAttached(yes) & goal(0, 0) & not(blockAttached(yes)) <-
	-goTo(_,_);
	-currentState(travellingToGoal);
	+currentState(deliberating);
	!findDispenser.


//if there is a block next to the agent, pick it up
+actionID(Xactionid): currentState(pickingUpBlock) & focusOnTask(_,_,_,DType) & (thing(0,1,block,BType) | thing(0,-1,block,BType) | thing(1,0,block,BType) | thing(-1,0,block,BType)) <-
	.print("Block next to me.");
	if(thing(0,1,dispenser,DType)){	//request blocks
		attach(s);
	};
	if(thing(0,-1,dispenser,DType)){	
		attach(n);
	};
	if(thing(1,0,dispenser,DType)){	
		attach(e);
	};
	if(thing(-1,0,dispenser,DType)){	
		attach(w);
	};
	+blockAttached(yes);
	-currentState(pickingUpBlock);
	+currentState(travellingToGoal);
	-nearestDispenser(_,_);				//don't care where nearest dispenser is - after completing a goal there can be another one
	!findGoal.							//call a plan that finds the closest goal.
	

//Move towards the dispenser & see if you land next to a dispenser
+actionID(Xactionid) : not(blockAttached(yes)) & goTo(_,_) & focusOnTask(_,_,_,DType) & (thing(0,1,dispenser,DType) | thing(0,-1,dispenser,DType) | thing(1,0,dispenser,DType) | thing(-1,0,dispenser,DType))<- 
	.print("Dispenser next to me.");
	if(thing(0,1,dispenser,DType)){	//request blocks
		request(s);
	};
	if(thing(0,-1,dispenser,DType)){	
		request(n);
	};
	if(thing(1,0,dispenser,DType)){	
		request(e);
	};
	if(thing(-1,0,dispenser,DType)){	
		request(w);
	};
	-currentState(travellingToDisp);
	-goTo(_,_);
	+currentState(pickingUpBlock).

//Any other plan to move somewhere (right now includes moving to goal unimpeded).
+actionID(Xactionid) : goTo(_,_) <- 
	.print("Moving according to plan");
	!intentionalMove.

//If we're still exploring, TODO EXPLORATION PLAN.
+actionID(Xactionid) : currentState(exploring) <- 
	.print("Exploring");
	!move_random.

//for testing
+actionID(Xactionid) : currentState(chilling) <- 
	.print("Skipping my action");
	!skip.

//	Otherwise, move randomly.
+actionID(Xactionid) : true <- 
	.print("Moving randomly");
	!move_random.


//--------------------------ADD ME--------------------------------

+!submitOrRotate: focusOnTask(Name, Xrel, Yrel, _) <- 
	request(n);		//just to submit any action, while waiting for implementation
	!submitOrRotate.	//loop as placeholder

//----------------------------------------------------------------

//if following a path, continue down it.
+!intentionalMove : currentPosition(X,Y) & goTo(Xg,Yg) & nextMove(Dir) <- 
	-nextMove(Dir);
	if(not(X = Xg) & not(Y = Yg)){
		getNextMovePath;
	};
	if(X = Xg & Y = Yg){	//reached goal, get rid of the goal
		-goTo(Xg, Yg);		//Note: the goal should be get rid of with other functions anyway
		-currentState(deliberating);
		+currentState(chilling);
	}.
	

//start a path from A to B.
+!intentionalMove : currentPosition(X,Y) & goTo(Xg,Yg) <- 
	calculateRoute(X,Y,Xg,Yg);			//Calculate route to given objective,
	getNextMovePath.					//add percept nextMove(X), which activates function below
	
+nextMove(Dir) : currentPosition(X,Y) <-
	!moveAndUpdate(Dir, X, Y).
	

+!move_random : .random(RandomNumber) & random_dir([n,s,e,w],RandomNumber,Dir) & currentPosition(X,Y)
<-	
	if (Dir = n & not (boundary(Y-1, n)) & not (obstacle(X,Y-1))) {!moveAndUpdate(Dir, X, Y)
	}elif (Dir = s & not (boundary(Y+1, s)) & not (obstacle(X,Y+1))) {!moveAndUpdate(Dir, X, Y)
	}elif (Dir = e & not (boundary(X+1, e)) & not (obstacle(X+1,Y))) {!moveAndUpdate(Dir, X, Y)
	}elif (Dir = w & not (boundary(X-1, w)) & not (obstacle(X-1,Y))) {!moveAndUpdate(Dir, X, Y)
	}else{!move_random}.	//if the random move is unsuccessful, try again.
	
	
	

//plan to use for moving, which includes positional updates.
@moveAndUpdate[atomic]
+!moveAndUpdate(Dir, X, Y): true <-
	move(Dir);!updatePosition(Dir); -previousPosition(_,_); +previousPosition(X,Y).

// update position after submitting the "move" action.
//if move action is unsuccessful, this will be reverted after percepting 
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
+!revertPositionIfUnsuccessful:  previousPosition(X,Y) <-
	if(lastAction(move) & not lastActionResult(success)){
		-currentPosition(_,_); +currentPosition(X,Y);
	}.

@addBoundary[atomic]
+lastActionResult(failed_forbidden) : currentPosition(X,Y) & lastAction(move) & lastActionParams([Dir]) <-
	if(Dir = n){ +boundary(Y-1, s)};  
	if(Dir = s){ +boundary(Y+1, n)};
	if(Dir = e){ +boundary(X+1, w)};
	if(Dir = w){ +boundary(X-1, e)};
    .print("Boundary added to prevent moving out of bounds.").
	



//find the closest goal where an objective can be completed.
+!findGoal: true <-
	findNearestGoal.	//adds the nearestGoal() percept.

+nearestGoal(Xn, Yn): true <-
	if(Xn = -1 & Yn = -1){				//error code - no goals found - continue exploring TODO needs investigation if it's actually correct
		+currentState(exploring);
		-currentState(travellingToGoal);	
	};
	if(not(Xn = -1) & not(Yn = -1)){
		+goTo(Xn,Yn);					//Nearest goal found - now go towards it
	}.

//Edge case - if was deliberating but has a block already, go straight to goal
+!findDispenser: currentState(deliberating) &task(Name,_,10, ReqList) & req1FromTask(ReqList, req(Xrel,Yrel,DispType)) & blockAttached(yes) <-
	-currentState(deliberating);
	+currentState(travellingToGoal);
	!findGoal.	
//if deliberating and there is an appropriate 1-block task, take it and go to the nearest dispenser
+!findDispenser: currentState(deliberating) &task(Name,_,10, ReqList) & req1FromTask(ReqList, req(Xrel,Yrel,DispType)) <-
	+focusOnTask(name,Xrel,Yrel,DispType);					//This agent is now focusing on the task at hand
	findNearestDispenser(DispType).						//adds belief nearestDispenser(Xnew,Ynew), which triggers function below

					

+nearestDispenser(Xn,Yn) :true <-
	-currentState(deliberating);
	if(Xn = -1 & Yn = -1){				//error code - no dispensers of this type found - continue exploring
		+currentState(exploring);	
	};
	if(not(Xn = -1) & not(Yn = -1)){
		+goTo(Xn,Yn);					//Nearest dispenser found - now go towards it
		+currentState(travellingToDisp);
	}.


//function for updating the map of the agent (internally).
+!reportBeliefs : currentPosition(X,Y) <- 
    .findall(thing(A,B,dispenser,D),thing(A,B,dispenser,D), Things);	//for mapping, we are only concerned with static objects
	.findall(obstacle(A,B),obstacle(A,B), Obstacles);
	.findall(goal(A,B),goal(A,B), Goals);
	report(Things, Obstacles, Goals,X,Y).				//internal action - see syntax in EISAdapter.java, under ExecuteAction()

	
    