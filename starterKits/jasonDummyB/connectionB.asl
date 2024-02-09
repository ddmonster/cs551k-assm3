/* Initial beliefs and rules */
random_dir(DirList,RandomNumber,Dir) :- (RandomNumber <= 0.25 & .nth(0,DirList,Dir)) | (RandomNumber <= 0.5 & .nth(1,DirList,Dir)) | (RandomNumber <= 0.75 & .nth(2,DirList,Dir)) | (.nth(3,DirList,Dir)).


random_move(DirList,Dir) :- (.shuffle(DirList,Result) & .nth(0,Result,Dir)).
/* Initial goals */
main_task(explore). //request(n) explore  main_task(submit) main_task(goto(_)) finish_task

hold_task(null).


!start.

perceptLocation(0,0).

!plan_engine.


+nearestDispenser0(X,Y)[source(percept)] <- -+nearestDispenser0(X,Y).
+nearestDispenser1(X,Y)[source(percept)]  <--+nearestDispenser1(X,Y).
+nearestGoal(X,Y)[source(percept)]  <- -+nearestGoal(X,Y).
+perceptLocation(X,Y)[source(percept)]: perceptLocation(Xs,Ys)[source(self)]& (Xs \== X | Ys \== Y) <- .print("location ",X," ",Y).
/* Plans */
+task(Name,DD,Rewards,[Req]) <- 
				// .print("taslk  ", Name);
				-ptask(Name,_,_,_);
				+ptask(Name,DD,Rewards,Req).

// +nearestDispenser0(X,Y): main_task(explore) & hold_task(Name,DD,Rewards,req(_,_,b0)) <-
// 						.print("goto ",X ," ",Y);
// 						-+main_task(goto(b0)).
// +nearestDispenser1(X,Y): main_task(explore) & hold_task(Name,DD,Rewards,req(_,_,b1)) <-
// 						.print("goto ",X ," ",Y);
// 						-+main_task(goto(b1)).
// +!plan_engine : .intend(plan_engine).
+!plan_engine: hold_task(null) & ptask(Name,DD,Rewards,Req) & step(S) & DD > S <-
				.wait(100);
				.print("hold task ", Name , " ",DD,  " " , Rewards," ",Req );
				-+hold_task(Name,DD,Rewards,Req).
// +nextToDispenser(Dir)<- .print("next to ", Dir, Type).
+nextToDispenser(Dir,Type)<- 
					-+main_task(request(Dir)).
+onGoalArea :  hold_task(Name,DD,Rewards,req(X,Y,b0)) <- 
					.print("stand on goal").

+!plan_engine:  hold_task(Name,DD,Rewards,req(_,_,b0)) & nearestDispenser0(X,Y)[source(self)]  <-
				// .nth(0,Reqs,req(X,Y,Type));
				?nearestDispenser0(X,Y)[source(self)];
				.print("pgoto ",X ," ",Y);
				-+main_task(goto(b0)).
// +!plan_engine: main_task(goto(Gtype)) & thing(X,Y,despensor,Type) <-
// 						.print("try netxt to ");
// 						if (X = 0 & Y =1 ){
// 							-+main_task(request(n));
// 						};
// 						if (X = 1 & Y =0 ){
// 							-+main_task(request(e));
// 						};
// 						if (X =0 & Y = -1 ){
// 							-+main_task(request(s));
// 						};
// 						if (X = -1 & Y = 0 ){
// 							-+main_task(request(w));
// 						}.
+!plan_engine: main_task(explore)  & hold_task(Name,DD,Rewards,req(_,_,b1)) & nearestDispenser1(X,Y)[source(self)] <-
				// .nth(0,Reqs,req(X,Y,Type));
				.print("pgoto ",X ," ",Y);
				-+main_task(goto(b1)).
// +!plan_engine: main_task(explore)  &  hold_task(Name,DD,Rewards,Reqs) &  nearestDispenser1(X,Y)<-
// 				-+main_task(goto(b1)).
+!plan_engine <- !plan_engine.
-!plan_engine <- !plan_engine.

+!move_towards(X,Y): perceptLocation(Xc,Yc)  <- 
								if(Xc-X >= 0 & Yc-Y >=0 ){
									!move_random([w,s]);
								};
								if(X >= 0 & Yc-Y<0){
									!move_random([w,n]);
								};
								if(Xc-X < 0 & Yc-Y >=0 ){
									!move_random([e,s]);
								};
								if(Xc-X < 0 & Yc-Y < 0){
									!move_random([e,n]);
								}.





// +!commit_action(Step): main_task(request(Dir)) & attached <-
+!commit_action(Step): main_task(to_submit) & nearestGoal(X,Y) & hold_task(Name,DD,Rewards,req(X,Y,b0)) & step(S)<-
					// .print("go to b0");
					!move_towards(X,Y).
+!commit_action(Step): main_task(request(Dir)) <-
					// .print("go to b0");
					request(Dir);
					-+main_task(to_submit).

+!commit_action(Step): main_task(goto(b0)) & nearestDispenser0(X,Y) <-
					// .print("go to b0");
					!move_towards(X,Y).		

+!commit_action(Step): main_task(goto(b1)) & nearestDispenser1(X,Y) <-
					// .print("go to b1");
					!move_towards(X,Y).	

+!commit_action(Step): main_task(submit) & nearestGoal(X,Y) <-
					!move_towards(X,Y).

+!commit_action(Step): main_task(explore) <-
	!move_random([n,s,w,e]).

+!commit_action(Step) <- skip;.print("skip").

+!start : true <- 
	.print("hello massim world.").

+step(X) : nearestDispenser1(X,Y)  <-
	.print("Received step percept.", X).

+actionID(X): main_task(Main) & hold_task(Name,DD,Rewards,req(_,_,Type))  <- 
	.print("Main Task ",Main, "hold ",Name , " " , Type);
	// -+main_task(goto(Type));
	// !!plan_engine;
	!plan_engine.
	!commit_action(X).
//	skip.
// +actionID(X): true <- 
// 	// .print("Main Task ",Main, "hold ",Name , " " , Type);
// 	!move_random([w,e,s,n]).
+!move_random(DirList) : random_move(DirList,Dir)
<-	.print("move ", Dir);move(Dir).