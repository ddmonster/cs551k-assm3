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
    private final int MAP_WIDTH = 60;
    private final int MAP_HEIGHT = 60;


    public Agent(String name) {
        this.name = name;
        this.position = new int[2];
        this.position[0] = 0;
        this.position[1] = 0;
        this.map = new String[MAP_WIDTH][MAP_HEIGHT];
        for (int i = 0; i < MAP_WIDTH; i++) {
            Arrays.fill(map[i], "unknown");
        }
    }
    public void updatePosition(int x, int y) {
        this.position[0] = x;
        this.position[1] = y;
    }

    public void updateMap(ListTerm things, ListTerm obstacles, ListTerm goals) {
        try{
        for (Term t : things) {
            Structure s = (Structure) t;
            String type = s.getTerm(2).toString();
            int x =  (int) ((NumberTerm) s.getTerm(0)).solve() - this.position[0];
            int y = (int) ((NumberTerm) s.getTerm(1)).solve() - this.position[1];
            updateMapTile(x, y, type);
        }
        for (Term t : obstacles) {
            Structure s = (Structure) t;
            String type = s.getFunctor().toString();
            int x =  (int) ((NumberTerm) s.getTerm(0)).solve() - this.position[0];
            int y = (int) ((NumberTerm) s.getTerm(1)).solve() - this.position[1];
            updateMapTile(x, y, type);
        }
    } catch (Exception e) {
        System.out.println("Error updating map");
    }

    }


    public void updateMapTile(int x, int y, String tileType) {
        map[x][y] = tileType;
    }

}