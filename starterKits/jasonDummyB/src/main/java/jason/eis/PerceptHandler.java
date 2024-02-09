
package jason.eis;

import jason.JasonException;
import jason.NoValueException;
import jason.asSyntax.*;
import java.awt.Point;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Scanner;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;
import java.util.logging.Logger;
import java.math.*;
class LocationList {
    public List<List<Integer>> store = new ArrayList<>();

    public void add(Integer x, Integer y) {
        List<Integer> xy = new ArrayList<>();
        xy.add(x);
        xy.add(y);
        store.add(xy);
    }

    boolean isEmpty() {
        return store.isEmpty();
    }

    boolean contains(Integer x, Integer y) {
        for (List<Integer> xy : store) {
            if ((xy.get(0) == x) && (xy.get(1) == y)) {
                return true;
            }
        }
        return false;
    }


    public List<Integer> nearest(Integer x, Integer y) {
        List<Integer> rxy = new ArrayList<>();
        Integer dis=Integer.MAX_VALUE;
        for (List<Integer> xy : store) {
            Integer i = Math.abs(x - xy.get(0)) + Math.abs(y - xy.get(1));
            if (dis > i) {
                rxy.clear();
                rxy.add(xy.get(0)); // Add x coordinate of the nearest point
                rxy.add(xy.get(1));
                dis = i;
            }
        }
        return rxy;
    }

    public void addNearestToPercept(String Name, Collection<Literal> percepts, Integer X, Integer Y) {
        if (!isEmpty()) {
            Literal l = ASSyntax.createLiteral(Name);
            List<Integer> ngxy =  nearest(X, Y);
            l.addTerm(ASSyntax.createNumber(ngxy.get(0)));
            l.addTerm(ASSyntax.createNumber(ngxy.get(1)));
            percepts.add(l);
        }

    }
}
public class PerceptHandler {
    public Integer X = 0;
    public Integer Y = 0;
    public Integer actionNum = -1;
    public boolean getActResult = false;
    private Integer vision = null;
    public String step = "";
    public String prestep = "";
    public String Name = "";
    private LocationList obstacleList = new LocationList();
    private List<Literal> blockList = new ArrayList<Literal>();
    private LocationList dispenser0List = new LocationList();
    private LocationList dispenser1List = new LocationList();
    private LocationList goalsList = new LocationList();
    private List<Literal> tasks = new ArrayList<Literal>();
    private List<Literal> attach = new ArrayList<Literal>();

    public void setActionNum() {
        actionNum += 1;
        getActResult = false;
    }

    PerceptHandler(String name) {
        Name= name;
    }
    static Set<String> match_obs_prop = new HashSet<String>( Arrays.asList(new String[] {
		"name",
		"steps",
		"team",
		"vision",
	}));
	
	static Set<String> step_obs_prop = new HashSet<String>( Arrays.asList(new String[] {
		"actionID",
		"step",
		"simEnd",
		"lastAction",
		"lastActionResult",
		"score",
		"thing",
		"task",
		"obstacle",
		"goal",
		"attached",
		"lastActionParams",
		"energy",
		"disabled",
//		"timestamp",
//		"deadline",
	}));
    public  Collection<Literal> handlePercepts(Collection<Literal> percepts) {
        for (Literal next : percepts) {
            if (next.getFunctor().equals("thing")) {
                Term x = next.getTerm(0);
                Term y = next.getTerm(1);
                Term type = next.getTerm(2);
                Term details = next.getTerm(3);
            }
            if (next.getFunctor().equals("step")) {
                Term t = next.getTerm(0);
            }
            if (next.getFunctor().equals("step")) {
                Term t = next.getTerm(0);
            }
        }
        return percepts;
    }

    public  Collection<Literal> updatePercepts(Collection<Literal> percepts) {
        String lastAction			= "";
		String lastActionResult 	= "";
		String lastActionParams	    = "";
        List<Literal> goal = new ArrayList<>();
        List<Literal> dispenser = new ArrayList<>();
        LocationList attached = new LocationList();
        LocationList cantgo =  new LocationList();
        for (Literal next : percepts) {
            if (next.getFunctor().equals("obstacle") ) {
                Integer x = Integer.valueOf(next.getTerm(0).toString());
                Integer y = Integer.valueOf(next.getTerm(1).toString());
                cantgo.add(x,y);
            }
            if (next.getFunctor().equals("actionID")) {
                prestep = next.getTerm(0).toString();
                
            }
            if (next.getFunctor().equals("lastAction")) {
                lastAction = next.getTerm(0).toString();
            }
            if (next.getFunctor().equals("lastActionResult")) {
                lastActionResult = next.getTerm(0).toString();
            }
            if (next.getFunctor().equals("lastActionParams")) {
                lastActionParams = next.getTerm(0).toString();
            }
            if (next.getFunctor().equals("goal")) {
                goal.add(next);
            }
            if (next.getFunctor().equals("attached")) {
                System.out.println(next.toString());
            }
            if (next.getFunctor().equals("thing")) {
                if (next.getTerm(2).toString().equals("entity")) {
                    Integer x = Integer.valueOf(next.getTerm(0).toString());
                    Integer y = Integer.valueOf(next.getTerm(1).toString());
                    cantgo.add(x,y);
                }
                if (next.getTerm(2).toString().equals("dispenser")) {
                    dispenser.add(next);
                }
            }
            if (next.getFunctor().equals("attached")) {
                Integer x = Integer.valueOf(next.getTerm(0).toString());
                Integer y = Integer.valueOf(next.getTerm(1).toString());
                attached.add(x,y);
            }
            

        }
        if (!getActResult) {
            
            // System.err.println("step n   nnnn "+ prestep + X.toString()+ "  " + Y.toString() + lastAction + lastActionResult);
            if (lastAction.equals("move") && lastActionResult.equals("success")) {
                getActResult = true;
                if (lastActionParams.contains("n")) {
                    Y++;
                } else if (lastActionParams.contains("s")) {
                    Y--;
                } else if (lastActionParams.contains("e")) {
                    X++;
                } else if (lastActionParams.contains("w")) {
                    X--;
                }
                
                
            }

            for (Literal g : goal) {
                Integer x = Integer.valueOf(g.getTerm(0).toString());
                Integer y = Integer.valueOf(g.getTerm(1).toString());
                // System.out.println(Name + " goal X "+ x.toString() + "Y " + y.toString());
                if (x == X && y == Y) {
                    Literal l = ASSyntax.createLiteral("onGoalArea");
                    percepts.add(l);
                }
                ;

                if (!goalsList.contains(x + X, Y-y)) {
                    goalsList.add(x+X,Y-y); 
                    
                }
            }
            for (Literal d : dispenser) {
                Integer x = Integer.valueOf(d.getTerm(0).toString());
                Integer y = Integer.valueOf(d.getTerm(1).toString());
                String name = d.getTerm(3).toString();
                Literal l = ASSyntax.createLiteral("nextToDispenser");
                if (x == 0 && y ==1){
                    l .addTerm(ASSyntax.createString("s"));
                    
                } else if (x == 0 && y == -1) {
                    l .addTerm(ASSyntax.createString("n"));

                } else if (x == 1 && y == 0) {
                    l .addTerm(ASSyntax.createString("e"));
                }else if (x == -1 && y == 0) {

                    l.addTerm(ASSyntax.createString("w"));
                }
                // System.err.println("dispensor  "+ name) ;
                if (name.contains("b0")) {
                    l.addTerm(ASSyntax.createString("b0"));
                    if (!dispenser0List.contains(x + X, Y - y)) {
                        dispenser0List.add(x + X, Y -y);
                    }
                }
                if (name.contains("b1")) {
                    l.addTerm(ASSyntax.createString("b1"));
                    if (!dispenser1List.contains(x + X, Y - y)) {
                        dispenser1List.add(x + X, Y - y);
                    }
                }
                percepts.add(l);

            }
            HashSet<String> avaliable_dir = new HashSet<>();
            avaliable_dir.add("n");
            avaliable_dir.add("s");
            avaliable_dir.add("w");
            avaliable_dir.add("e");
            for (List<Integer> l : cantgo.store) {
                
            }

        goalsList.addNearestToPercept("nearestGoal", percepts, X, Y);
        dispenser0List.addNearestToPercept("nearestDispenser0", percepts, X, Y);
        dispenser1List.addNearestToPercept("nearestDispenser1", percepts, X, Y);

        }
        Literal l = ASSyntax.createLiteral("perceptLocation");
        l.addTerm(ASSyntax.createNumber(X));
        l.addTerm(ASSyntax.createNumber(Y));
        percepts.add(l);

        return percepts;
    }

}
