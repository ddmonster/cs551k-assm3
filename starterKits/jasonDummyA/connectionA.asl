/* Initial beliefs and rules */
random_dir(DirList,RandomNumber,Dir) :- 
(RandomNumber <= 0.25 & .nth(0,DirList,Dir)) |
(RandomNumber <= 0.5 & .nth(1,DirList,Dir))  |
(RandomNumber <= 0.75 & .nth(2,DirList,Dir)) | 
(.nth(3,DirList,Dir)).
//random dir that takes into account the boundaries
randomDispType(DList, RandomNumber, DType) :- (RandomNumber <= 0.5 & .nth(0,DList, DType) | .nth(1, DList, DType)).
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
	!move_random.



@step[atomic]	//atomic because currentPosition(X,Y) can confuse the agent as step(X) and actionID(X) can have interleaved execution
+step(Xstep) : true <-
	.print("Received step percept.");
	!revertPositionIfUnsuccessful;								//check if last move was successful	
	!reportBeliefs;												//update the internal maps with percepts
	!removeTasksWithPassedDeadline;								//remove the tasks the deadline of which is passed already

	if(Xstep > 13 & Xstep mod 7 = 0 & currentState(exploring)){	//stop exploring past step 14, if no appropriate tasks found it will return to exploration and revisit each 7 steps
		-currentState(exploring);		
		+currentState(deliberating);
		!findDispenser;											//find the closest dispenser and do something about it
	}.


//activate !makeAction after percepts have been updated
+actionID(Xactionid): true <-
	.wait({+step(Xstep)});
	if(lastAction(submit) & not(lastActionResult(failed_target))){
		.print("Submit Successful!");
		-closestDispenser(_);		//cleaning up variables that were used for this task.
		-nearestGoal(_);			//nearest goal will probably stay the same, but still doesn't hurt to clean up.
		-focusOnTask(Name,_,_,_);
		-blockAttached(yes);
		-goTo(_,_);
		-currentState(travellingToGoal);
		+currentState(deliberating);
		!findDispenser;				//find next task to do.
	};
	!makeAction.

//if submission fails find another task with same block
/*
+!makeAction: lastAction(submit) & lastActionResult(failed_target) & focusOnTask(Name,_,_,DType) <- 
	!findTask(DType);
	submitOrRotate.
	*/

//if agent is travelling to goal and reached goal.
+!makeAction: currentState(travellingToGoal) & blockAttached(yes) & goal(0,0)  <-			
	!checkIfTaskStillAvailable;							     	//Check if the task that the agent is focusing on is still available - if not, change to another task 
	.print("I am at goal, will attempt to submit now");
	!submitOrRotate.		//agent is now in position for submission.


//if there is a block next to the agent, pick it up
+!makeAction: currentState(pickingUpBlock) & focusOnTask(_,_,_,DType) & (thing(0,1,block,BType) | thing(0,-1,block,BType) | thing(1,0,block,BType) | thing(-1,0,block,BType)) <-
	.print("Block next to me.");
	if(thing(0,1,dispenser,DType)){	//request blocks	//I was thinking of giving way to other agents from other teams, but then if both teams are attached to a block, that's
														//both agents messed up, so the overall score is not influenced
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
+!makeAction : not(blockAttached(yes)) & goTo(_,_) & focusOnTask(_,_,_,DType) & (thing(0,1,dispenser,DType) | thing(0,-1,dispenser,DType) | thing(1,0,dispenser,DType) | thing(-1,0,dispenser,DType))<- 
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

//Action above, if two agents of the same team request a block from the same dispenser, one of them will get a "success" and the rest "failure"
//the one that was successful can feel free to take the block and leave; the blocked one - wait for the dispenser to be clear and 
+lastActionResult(failed_blocked):lastAction(request) & currentPosition(X,Y) <-
	-currentState(pickingUpBlock);
	+goTo(X,Y);
	+currentState(travellingToDisp).

//Any other plan to move somewhere (right now includes moving to goal unimpeded).
+!makeAction : goTo(_,_) <- 
	.print("Moving according to plan");
	!intentionalMove.

//If we're still exploring, TODO EXPLORATION PLAN.
+!makeAction : currentState(exploring) <- 
	.print("Exploring");
	!move_random.

//for testing
+!makeAction : currentState(chilling) <- 
	.print("Skipping my action");
	!skip.

//	Otherwise, move randomly.
+!makeAction : true <- 
	.print("Moving randomly");
	!move_random.


+!submitOrRotate: focusOnTask(Name, Xrel, Yrel, _) <-
	if(thing(Xrel,Yrel, block, _)){
		.print("Attempting to submit a task...");
		submit(Name);

	}elif(attached(X,Y)){
		!rotation(X,Y, Xrel, Yrel);
	}.


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
	//check if there are any immediate entities around the agent...
	if(thing(0,1,entity,_) & Dir = s){
		!moveAndUpdate(w, X, Y); -nextMove(_);
	}elif(thing(0,-1,entity,_) & Dir = n){
		!moveAndUpdate(e, X, Y); -nextMove(_);
	}elif(thing(1,0,entity,_) & Dir = e){
		!moveAndUpdate(s, X, Y); -nextMove(_);
	}elif(thing(-1,0,entity,_) & Dir = w){
		!moveAndUpdate(n, X, Y); -nextMove(_);
	}else{
	//however, we might have been unable to move because of the block being in a wrong position, unable to be transported.
	if(lastAction(move) & lastActionResult(failed_path) & lastActionParams(DirP) & .nth(0, DirP, Dir) & attached(Xa, Ya)){
		if(Dir = n){
			!rotation(Xa, Ya, 0, 1);
		}elif(Dir = e){
			!rotation(Xa, Ya, -1,0);
		}elif(Dir = s){
			!rotation(Xa, Ya, 0, -1);
		}else{
			!rotation(Xa, Ya, 1, 0);
		};
	}
	else{			//otherwise all is good.
		!moveAndUpdate(Dir, X, Y)};	//move to the next position in the path.
	}.


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

+!moveAndUpdate2: nextMove(Dir) & currentPosition(X,Y) <-
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

+lastActionResult(failed_forbidden) : currentPosition(X,Y) & lastAction(move) & lastActionParams([Dir]) <-
	if(Dir = n){ 
	+boundary(Y, n);
	addBoundary(Y, horizontal);	//this one is Y instead of Y-1, as in case our agent goes to a goal at the bottom fo the map he will be unable to rotate block appropriately
	};  
	if(Dir = s){ 
	+boundary(Y+1, s);
	addBoundary(Y+1, horizontal);			
	};
	if(Dir = e){ 
	+boundary(X+1, e);
	addBoundary(X+1, vertical);
	};
	if(Dir = w){ 
	+boundary(X-1, w);
	addBoundary(X-1, vertical);
	};

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
+!findDispenser: currentState(deliberating) &task(Name,_,10, ReqList) & req1FromTask(ReqList, req(Xrel,Yrel,DispType)) &blockAttached(yes) & .random(N) & randomDispType([b0,b1], N, DispType)  <-
	-currentState(deliberating);
	+currentState(travellingToGoal);
	!findGoal.	
//if deliberating and there is an appropriate 1-block task, take it and go to the nearest dispenser
+!findDispenser: currentState(deliberating) &task(Name,_,10, ReqList) & req1FromTask(ReqList, req(Xrel,Yrel,DispType)) &.random(N) & randomDispType([b0,b1], N, DispType) <-
	+focusOnTask(Name,Xrel,Yrel,DispType);					//This agent is now focusing on the task at hand
	findNearestDispenser(DispType).						//adds belief nearestDispenser(Xnew,Ynew), which triggers function below

					
+nearestDispenser(Xn,Yn) :true <-
	-currentState(deliberating);
	if(Xn = -1 & Yn = -1){				//error code - no dispensers of this type found - continue exploring
		-focusOnTask(_,_,_,_);
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

+!rotation(X,Y, GoalX, GoalY): true <-
	if(X = GoalX & Y < GoalY){	//rotate clockwise (shouldn't matter)
		if(lastAction(rotate) & not(lastActionResult(success))){	//spin the other way (if on edge of the map, or failed for whatever other reason)
			rotate(ccw);
		}else{
			rotate(cw);
		};
	}elif(X = GoalX & Y > GoalY){	//rotate counterclockwise (shouldn't matter)
		if(lastAction(rotate) & not(lastActionResult(success))){
			rotate(cw);
		}else{
			rotate(ccw);
		};
	}elif(X < GoalX & Y = GoalY){	//rotate clockwise	(shouldn't matter)
		if(lastAction(rotate) & not(lastActionResult(success))){
			rotate(ccw);
		}else{
			rotate(cw);
		};
	}elif(X > GoalX & Y = GoalY){	//rotate counterclockwise	(shouldn't matter)
		if(lastAction(rotate) & not(lastActionResult(success))){
			rotate(cw);
		}else{
			rotate(ccw);
		};
	}elif(X < GoalX & Y < GoalY){	//rotate counterclockwise - fastest
		rotate(ccw);
	}elif(X > GoalX & Y > GoalY){	//rotate counterclockwise - fastest
		rotate(ccw);
	}elif(X > GoalX & Y < GoalY){	//rotate clockwise - fastest
		rotate(cw);
	}elif(X < GoalX & Y > GoalY){	//rotate clockwise - fastest
		rotate(cw);
	}.

//remove tasks that the deadline for which is already passed.	//TODO this is terrible, the env adds the beliefs back anyway even if expired
@removeTasksWithPassedDeadline[atomic]
+!removeTasksWithPassedDeadline: step(X) <-
	for(task(Name,Deadline,_,_)){
		if(Deadline < X){
			//.print("Task with a deadline removed!");
			-task(Name,Deadline,_,_);
		};
	}.


	
@checkIfTaskStillAvailable[atomic] 		//atomic so that the update happens before next plan is called. Agent needs to know the name of task for submission - task still exists, all good
+!checkIfTaskStillAvailable: focusOnTask(Name, Xrel, Yrel, Dtype) & task(Name,_,10, ReqList) & req1FromTask(ReqList, req(NewXrel,NewYrel,DispType)) <-
	.print("I think I still have the task").	//task with the Name is still available - submit

//no match found between focusOnTask() and task()
+!checkIfTaskStillAvailable: focusOnTask(Name, Xrel, Yrel, Dtype) & task(NewName,_,10, ReqList) & req1FromTask(ReqList, req(NewXrel,NewYrel,DispType)) <-
	if(Name = NewName){}	//all ok, task still available within deadline - it shouldn't be possible here though
	else{	//the topmost task is no longer available:
		.print("Task no longer available. Will attempt to change.");
		-focusOnTask(Name,_,_,_);
		if(Dtype = DispType){	//new task found has the same type of block - we are happy
			+focusOnTask(NewName, NewXrel, NewYrel, DispType);
		}elif(task(SameType,_,10, ReqList2) & req1FromTask(ReqList2, req(Xr2,Yr2,Dtype))){			//task is not topmost, but still exists - take it
			+focusOnTask(SameType, Xr2, Yr2, Dtype);	
		}elif(not(Dtype = DispType) & not(blockAttached(yes))){	//block is not attached - we can switch the plan to another one
			+focusOnTask(NewName, NewXrel, NewYrel, DispType);
		}else{													//we have a block attached, but the current topmost task is of another type - then, wait for another task.
			.print("Waiting for another task of attached block type to become available");
			+focusOnTask(Name, Xrel, Yrel, Dtype);				//"technological debt" - agent will attempt to submit a task that is already gone (which is ok)
		};
	}.print("Finished amending tasks").
+!checkIfTaskStillAvailable: true <- true.			//no task that's being focused on right now

//Currently unused
+!findTask(Dtype) : task(Name,Deadline,10, ReqList) & req1FromTask(ReqList, req(Xrel,Yrel,Dtype)) & step(Step) <-
	-focusOnTask(Name2,_,_,_);
		if (Name = Name2){
			-task(Name,Deadline,10, ReqList);
			!findTask(Dtype);
		}elif (Deadline <= Step){
			-task(Name,Deadline,10, ReqList);
			!findTask(Dtype);
		}else{
			+focusOnTask(Name,Xrel,Yrel,Dtype);
		}.
