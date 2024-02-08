


current_location(0,0).
random_move(DirList,Dir):- (.shuffle(DirList,Result) & .nth(0,Result,Dir)).
+vision(X)[source(percept)]: not vision(X)[source(self)] <- +vision(X)[source(self)].
+steps(X)[source(percept)]: not steps(X)[source(self)] <- +steps(X)[source(self)].
+team(X)[source(percept)]: not team(X)[source(self)] <- +team(X)[source(self)].
+name(X)[source(percept)]: not name(X)[source(self)] <- +name(X)[source(self)].
step(0).
// +step(N)[source(percept)]: N>0 & lastAction(X) & lastActionParams(Params) & lastActionResult(Result)  <-
//              .print("percept step ",N); -+stepResult(N,X,Params,Result)[source(self)].
// +stepResult(N,X,Params,Result)<- 
+step(X) <- -+step(X)[source(self)].            


+!update_location(Dir, Step): current_location(X,Y) & not .intend(update_location(Dir,Step)) <- 
    for (.member(D,[n,s,w,e]) & .member(Xu,[0,0,-1,1]) & .member(Yu,[1,-1,0,0])) {
        if (Dir == D){
            -+current_location(Xu+X,Yu+Y);

        };
    }.
+!update_location(Dir, Step)<- .suspend;!!update_location(Dir, Step).
+!resume(G)<- .resume(G).
+current_location(X,Y)[source(self)]<- .print("location update ",X," ",Y).

+!make_move(Dir,ID)<-
    move(Dir).

@update[atomic]
+lastActionResultIdentifier(Time,move,success,[Dir],Step) <- 
                    .print("last  ", Time , "move success :  ", Dir ," ", Step);
                    !update_location(Dir,Step).
                    


+actionID(ID):random_move([n,s,w,e],Dir) <-
    !make_move(Dir,ID).

+task(Name,Deadline,Reward,Reqs)[source(percept)]: not task(Name,_,_,_,_) <- -+task(Name,Deadline,Reward,Reqs)[source(self)].


+requestAction<-.print("need to go ").

