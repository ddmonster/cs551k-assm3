/* Initial beliefs and rules */
random_dir(DirList,RandomNumber,Dir) :- (RandomNumber <= 0.25 & .nth(0,DirList,Dir)) | (RandomNumber <= 0.5 & .nth(1,DirList,Dir)) | (RandomNumber <= 0.75 & .nth(2,DirList,Dir)) | (.nth(3,DirList,Dir)).
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
	if(Xstep > 13 & Xstep mod 7 = 0 & currentState(exploring)){	//stop exploring past step 14, if no appropriate tasks found it will return to exploration and revisit each 7 steps
		-currentState(exploring);		
		+currentState(deliberating);
		!findDispenser;											//find the closest dispenser and do something about it
		
	}.


+actionID(Xactionid): currentState(travellingToGoal) <-
	print("I would be travelling to goal, but I haven't been programmed to do so yet.");
	!skip.

//if there is a block next to the agent, pick it up
+actionID(Xactionid): currentState(pickingUpBlock) & focusOnTask(_,_,DType) & (thing(0,1,block,BType) | thing(0,-1,block,BType) | thing(1,0,block,BType) | thing(-1,0,block,BType)) <-
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
	-currentState(pickingUpBlock);
	+currentState(travellingToGoal).
	

//Move towards the dispenser & see if you land next to a dispenser
+actionID(Xactionid) : goTo(_,_) & focusOnTask(_,_,DType) & (thing(0,1,dispenser,DType) | thing(0,-1,dispenser,DType) | thing(1,0,dispenser,DType) | thing(-1,0,dispenser,DType))<- 
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

//Any other plan to move somewhere.
+actionID(Xactionid) : goTo(_,_) <- 
	.print("Determining my action");
	!move1.

//If we're still exploring, TODO EXPLORATION PLAN.
+actionID(Xactionid) : currentState(exploring) <- 
	.print("Determining my action");
	!move_random.

//for testing
+actionID(Xactionid) : currentState(chilling) <- 
	.print("Determining my action");
	!skip.

//	Otherwise, move randomly.
+actionID(Xactionid) : true <- 
	.print("Determining my action");
	!move_random.


//if following a path, continue down it.
+!move1 : currentPosition(X,Y) & goTo(Xg,Yg) & nextMove(Dir) <- 
	-nextMove(Dir);
	if(not(X = Xg) & not(Y = Yg)){
		getNextMovePath;
	};
	if(X = Xg & Y = Yg){	//reached goal, get rid of the goal
							//Note: the goal should be get rid of with other functions anyway
		-goTo(Xg, Yg);
		-currentState(deliberating);
		+currentState(chilling);
	}.
	


+!move1 : currentPosition(X,Y) & goTo(Xg,Yg) <- 
	calculateRoute(X,Y,Xg,Yg);			//Calculate route to given objective,
	getNextMovePath.					//add percept nextMove(X), which activates function below
	
+nextMove(Dir) : currentPosition(X,Y) <-
	!moveAndUpdate(Dir, X, Y).
	

+!move_random : .random(RandomNumber) & random_dir([n,s,e,w],RandomNumber,Dir) & currentPosition(X,Y)
<-	
	!moveAndUpdate(Dir, X, Y).

//plan to use for moving, which includes positional updates.
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
+!revertPositionIfUnsuccessful: lastAction(move) & not lastActionResult(success) & previousPosition(X,Y) <-
	//.print("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAReverting position");
	-currentPosition(_,_); +currentPosition(X,Y).
//otherwise OK, no action needed.
+!revertPositionIfUnsuccessful: true <- true.

//if deliberating and there is an appropriate 1-block task, take it and go to the nearest dispenser
+!findDispenser: currentState(deliberating) &task(_,_,10, ReqList) & req1FromTask(ReqList, req(Xrel,Yrel,DispType)) <-
	+focusOnTask(Xrel,Yrel,DispType);					//This agent is now focusing on the task at hand
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






+!reportBeliefs : currentPosition(X,Y) <- 
    .findall(thing(A,B,dispenser,D),thing(A,B,dispenser,D), Things);	//for mapping, we are only concerned with static objects
	.findall(obstacle(A,B),obstacle(A,B), Obstacles);
	.findall(goal(A,B),goal(A,B), Goals);
	report(Things, Obstacles, Goals,X,Y).				//internal action - see syntax in EISAdapter.java, under ExecuteAction()

	
    