package jason.eis;

import java.util.Arrays;
import java.util.List;
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


    public Agent(String name) {
        this.name = name;
        this.position = new int[2];
        this.position[0] = 64;  //assuming the map is at most 64x64, this ensures that no index of our map becomes lower than 0
        this.position[1] = 64;
        this.updates = 0;   //keep track of when to print the map
        this.map = new String[MAP_WIDTH*2][MAP_HEIGHT*2];
        for (int i = 0; i < MAP_WIDTH*2; i++) {
            Arrays.fill(map[i], "unknown");
        }
    }
    public void updatePosition(int x, int y) {
        this.position[0] = x;
        this.position[1] = y;
    }

    public void updateMap(ListTerm things, ListTerm obstacles, ListTerm goals, NumberTerm currX, NumberTerm currY) {
        try{
            updatePosition((int)currX.solve(), (int)currY.solve());
            for (Term t : things) {
                Structure s = (Structure) t;
                String type = s.getTerm(2).toString() + s.getTerm(3).toString(); //dispenserb0
                int x =  (int) ((NumberTerm) s.getTerm(0)).solve() + this.position[0];
                int y = (int) ((NumberTerm) s.getTerm(1)).solve() + this.position[1];
                updateMapTile(x, y, type);
            }
            for (Term t : obstacles) {
                Structure s = (Structure) t;
                String type = s.getFunctor().toString();
                int x =  (int) ((NumberTerm) s.getTerm(0)).solve() + this.position[0];
                int y = (int) ((NumberTerm) s.getTerm(1)).solve() + this.position[1];
                updateMapTile(x, y, type);
            }
            for (Term t : goals) {
                Structure s = (Structure) t;
                String type = s.getFunctor().toString();
                int x =  (int) ((NumberTerm) s.getTerm(0)).solve() + this.position[0];
                int y = (int) ((NumberTerm) s.getTerm(1)).solve() + this.position[1];
                updateMapTile(x, y, type);
            }
        
        //printPosition();
        /*
        this.updates+=1;
        if(this.updates % 20 == 0 && this.name.equals("connectionA1")){
            printMap();
        }
        */
        
        } catch (Exception e) {
            System.out.println("Error updating map:");
            e.printStackTrace();
        }

    }

    public void updateMapTile(int x, int y, String tileType) {
        map[x][y] = tileType;
    }

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

}