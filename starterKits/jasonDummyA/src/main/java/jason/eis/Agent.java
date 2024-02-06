package jason.eis;

import java.util.Arrays;
import java.util.List;
import java.lang.reflect.Array;
import java.util.ArrayList;

import jason.eis.Agent;
import eis.AgentListener;
import eis.EnvironmentInterfaceStandard;
import eis.EnvironmentListener;
import eis.exceptions.*;
import eis.iilang.*;
import jason.JasonException;
import jason.NoValueException;
import jason.asSyntax.*;
import jason.environment.Environment;
import massim.eismassim.EnvironmentInterface;
import jason.asSyntax.NumberTerm;
import jason.asSyntax.NumberTerm;
import jason.asSyntax.Structure;
import jason.asSyntax.Term;
import jason.asSyntax.ListTerm; 


public class Agent {
    private String name;
    private String[][] map;
    private int[] position;
    private final int MAP_WIDTH = 64;
    private final int MAP_HEIGHT = 64;
    private int updates;
    private ArrayList<String> directions; 
    private List<List<Object>> dispenserList;
    private List<List<Object>> goalList;


    public Agent(String name) {
        this.name = name;
        this.position = new int[2];
        this.position[0] = 64;  //assuming the map is at most 64x64, this ensures that no index of our map becomes lower than 0
        this.position[1] = 64;
        this.updates = 0;   //keep track of when to print the map
        this.map = new String[MAP_WIDTH*2][MAP_HEIGHT*2];
        this.dispenserList = new ArrayList<>();
        this.goalList = new ArrayList<>();
        for (int i = 0; i < MAP_WIDTH*2; i++) {
            Arrays.fill(map[i], "unknown");
        }
        this.directions = new ArrayList<String>();
    }
    public void updatePosition(int x, int y) {
        this.position[0] = x;
        this.position[1] = y;
    }

    public void setDirections(ArrayList<String> directions) {
        this.directions = directions;
    }

    public String popDirection() {
        if (this.directions.size() > 0) {
            return this.directions.remove(0);
        }
        return "none";
    }

    public String[][] getMap() {
        return this.map;
    }

    public void updateMap(ListTerm things, ListTerm obstacles, ListTerm goals, NumberTerm currX, NumberTerm currY) {
        try{
            updatePosition((int)currX.solve(), (int)currY.solve());
            for (Term t : things) { //dispensers
                Structure s = (Structure) t;
                String type = s.getTerm(2).toString() + s.getTerm(3).toString(); //dispenserb0
                int x =  (int) ((NumberTerm) s.getTerm(0)).solve() + this.position[0];
                int y = (int) ((NumberTerm) s.getTerm(1)).solve() + this.position[1];
                updateMapTile(x, y, type);
                this.dispenserList.add(List.of(x,y,type));
            }
            for (Term t : obstacles) {  //obstacles - for pathfinding avoidance
                Structure s = (Structure) t;
                String type = s.getFunctor().toString();
                int x =  (int) ((NumberTerm) s.getTerm(0)).solve() + this.position[0];
                int y = (int) ((NumberTerm) s.getTerm(1)).solve() + this.position[1];
                updateMapTile(x, y, type);
            }
            for (Term t : goals) {  //goals
                Structure s = (Structure) t;
                String type = s.getFunctor().toString();
                int x =  (int) ((NumberTerm) s.getTerm(0)).solve() + this.position[0];
                int y = (int) ((NumberTerm) s.getTerm(1)).solve() + this.position[1];
                updateMapTile(x, y, type);
                this.goalList.add(List.of(x,y));
            }
        
        //printPosition();
        
        this.updates+=1;
        if(this.updates % 20 == 0 && this.name.equals("connectionA1")){         //Debugging stuff
            //printMap();
            //printDispenserList();
        }
        
        
        } catch (Exception e) {
            System.out.println("Error updating map:");
            e.printStackTrace();
        }

    }

    public void updateMapTile(int x, int y, String tileType) {
        map[x][y] = tileType;
    }

    public ArrayList<Integer> findClosestDispenserOfType(String dispenserType){ //either "bo" or "b1"
        String dispenserToMatch = "dispenser" + dispenserType;
        int currentShortestDistance = 9999;         //inf
        int thisDistance, xToReturn = -1, yToReturn = -1;   //-1 indicates that no dispensers were found
        ArrayList<Integer>result = new ArrayList<>();
        for (List<Object> data : this.dispenserList) {      //run through entire list, update dispenser that's closest over time
            String thisDispenser = (String) data.get(2);
            if(thisDispenser.equals(dispenserToMatch))  {    //dispenser of type that we want to find
                int xDisp = (int) data.get(0);
                int yDisp = (int) data.get(1);
                //heuristic same as in Pathfinding.java class
                thisDistance = Math.abs(this.position[0] - xDisp) + Math.abs(this.position[1] - yDisp);
                if (thisDistance < currentShortestDistance){
                    xToReturn = xDisp;
                    yToReturn = yDisp;
                }
            }
        }
        result.add(xToReturn);
        result.add(yToReturn);
        return result;
    }
    public ArrayList<Integer> findClosestGoal(){ //Same function as above
        int currentShortestDistance = 9999;         //inf
        int thisDistance, xToReturn = -1, yToReturn = -1;   //-1 - no goal found
        ArrayList<Integer>result = new ArrayList<>();
        for (List<Object> data : this.goalList) {      //run through entire list, update goal that is closest
            int xGoal = (int) data.get(0);
            int yGoal = (int) data.get(1);
            //heuristic same as in Pathfinding.java class
            thisDistance = Math.abs(this.position[0] - xGoal) + Math.abs(this.position[1] - yGoal);
            if (thisDistance < currentShortestDistance){
                xToReturn = xGoal;
                yToReturn = yGoal;
            }
        }
        result.add(xToReturn);
        result.add(yToReturn);
        return result;
    }


 
    // --------------------------Debugging functions--------------------------------
    public void printPosition(){
        System.out.println(name + "position - X: " +position[0] + "Y: "+ position[1]);  
    }
    public void printMap(){
         for (int i = 0; i < map.length; i++){
            System.out.print("-");
         }
         System.out.println();
        for (int i = 0; i <map.length; i++) {
            for (int j = 0; j < map[i].length; j++) {
                if(i == position[0] && j == position[1]){
                    System.out.print("A");
                }
                else if(map[j][i].equals("unknown")){
                   System.out.print(".."); 
                }
                else if(map[j][i].equals("dispenserb0")){
                    System.out.print("0");
                }
                else if(map[j][i].equals("dispenserb1")){
                    System.out.print("1");
                }
                else if(map[j][i].equals("goal")){
                    System.out.print("G");
                }
                else if(map[j][i].equals("obstacle")){
                    System.out.print("O");
                }
            }
            System.out.println();
        }
        for (int i = 0; i < map.length; i++){
            System.out.print("-");
         }
         System.out.println();
        
    }
    public void printDispenserList(){
        for (List<Object> data : this.dispenserList) {
            int x = (int) data.get(0);
            int y = (int) data.get(1);
            String stringValue = (String) data.get(2);
            System.out.println("X: " + x + ", Y: " + y + ", String: " + stringValue);
            }
    }

    public void addBoundry(int position, String orientation){
        if(orientation.equals("horizontal")){
            for (int i = 0; i < MAP_WIDTH*2; i++){
                map[i][position] = "obstacle";
            }
        }
        else if(orientation.equals("vertical")){
            for (int i = 0; i < MAP_HEIGHT*2; i++){
                map[position][i] = "obstacle";
            }
        }
    }
}