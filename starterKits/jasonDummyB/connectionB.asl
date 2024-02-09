/* Initial beliefs and rules */
random_dir(DirList,RandomNumber,Dir) :- (RandomNumber <= 0.25 & .nth(0,DirList,Dir)) | (RandomNumber <= 0.5 & .nth(1,DirList,Dir)) | (RandomNumber <= 0.75 & .nth(2,DirList,Dir)) | (.nth(3,DirList,Dir)).


random_move(DirList,Dir) :- (.shuffle(DirList,Result) & .nth(0,Result,Dir)).
/* Initial goals */
main_task(explore).
next_action(move,dir).
!start.


+nearestDispenser0(X,Y) <- .print("ds0>>>>> ",X," ", Y).
+nearestDispenser1(X,Y) <- .print("ds1>>>>> ",X," ", Y).
+nearestGoal(X,Y) <- .print("goal ",X," ",Y).
+perceptLocation(X,Y) <- .print("location ",X," ",Y).
/* Plans */
+task(Name,DD,Rewards,Reqs) <- +task(Name,DD,Rewards,Reqs).


+!decide_action: not nearestGoal(_,_) | not nearestDispenser0(_,_) | not nearestDispenser1(_,_) <-
				-+main_task(explore);

+!move_towards(X,Y): perceptLocation(Xc,Yc) &  <- 


+!decide_action<- !decide_action;


+!commit_action(Step): nearestDispenser0(X,Y) & perceptLocation(Xc,Yc) <-
					if (Xc-X>0 & Yc-Y >0){
						!move_random([w,s]);
					};
					if (Xc-X>0 & Yc-Y <0){
						!move_random([w,s]);
					};


+!commit_action(Step): main_task(explore) <-
	!move_random({n,s,w,e}).

+!start : true <- 
	.print("hello massim world.").

+step(X) : true <-
	.print("Received step percept.").

+actionID(X) : main_task(explore). <- 
	.print("explore");
	!commit_action(X).
//	skip.

+!move_random(DirList) : random_move(DirList,Dir)
<-	move(Dir).