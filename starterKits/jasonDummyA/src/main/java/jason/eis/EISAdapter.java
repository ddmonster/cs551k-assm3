package jason.eis;

import jason.eis.Pathfinding;
import jason.eis.PathfindingTest;


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

import java.nio.file.Path;
import java.util.*;
import java.util.logging.Level;
import java.util.logging.Logger;


/**
 * This class functions as a Jason environment, using EISMASSim to connect to a MASSim server.
 * (see http://cig.in.tu-clausthal.de/eis)
 * (see also https://multiagentcontest.org)
 *
 * @author Jomi
 * - adapted by ta10
 */
public class EISAdapter extends Environment implements AgentListener {

    private Logger logger = Logger.getLogger("EISAdapter." + EISAdapter.class.getName());

    private Map<String, Agent> agents;

    private EnvironmentInterfaceStandard ei;

    public EISAdapter() {
        super(20);
        agents = new HashMap<>();
    }

    @Override
    public void init(String[] args) {

        
        ei = new EnvironmentInterface("conf/eismassimconfig.json");

        try {
            ei.start();
        } catch (ManagementException e) {
            e.printStackTrace();
        }

        ei.attachEnvironmentListener(new EnvironmentListener() {
                public void handleNewEntity(String entity) {}
                public void handleStateChange(EnvironmentState s) {
                    logger.info("new state "+s);
                }
                public void handleDeletedEntity(String arg0, Collection<String> arg1) {}
                public void handleFreeEntity(String arg0, Collection<String> arg1) {}
        });

        for(String e: ei.getEntities()) {
            System.out.println("Register agent " + e);

            agents.put(e, new Agent(e));   // Agent Objects

            try {
                ei.registerAgent(e);
            } catch (AgentException e1) {
                e1.printStackTrace();
            }

            ei.attachAgentListener(e, this);

            try {
                ei.associateEntity(e, e);
            } catch (RelationException e1) {
                e1.printStackTrace();
            }
        }
    }

    @Override
    public void handlePercept(String agent, Percept percept) {}

    @Override
    public List<Literal> getPercepts(String agName) {

        Collection<Literal> ps = super.getPercepts(agName);
        List<Literal> percepts = ps == null? new ArrayList<>() : new ArrayList<>(ps);

        clearPercepts(agName);

        if (ei != null) {
            try {
                Map<String,Collection<Percept>> perMap = ei.getAllPercepts(agName);
                for (String entity: perMap.keySet()) {
                    Structure strcEnt = ASSyntax.createStructure("entity", ASSyntax.createAtom(entity));
                    for (Percept p: perMap.get(entity)) {
                        try {
                            percepts.add(perceptToLiteral(p).addAnnots(strcEnt));
                        } catch (JasonException e) {
                            e.printStackTrace();
                        }
                    }
                }
            } catch (PerceiveException e) {
                logger.log(Level.WARNING, "Could not perceive.");
            }
        }
        return percepts;
    }

    @Override
    public boolean executeAction(String agName, Structure action) {

        if (action.getFunctor().equals("report")) {
            // Extract the beliefs list
            try{
                ListTerm things = (ListTerm) action.getTerm(0);
                ListTerm obstacles = (ListTerm) action.getTerm(1);
                ListTerm goals = (ListTerm) action.getTerm(2);
                NumberTerm currX = (NumberTerm) action.getTerm(3);
                NumberTerm currY = (NumberTerm) action.getTerm(4);
                agents.get(agName).updateMap(things, obstacles, goals, currX, currY);
            }
            catch(Exception e){
                e.printStackTrace();
            }
            
            return true;
        }
        //function for internal route Calculation, used for "getNextMovePath"
        if(action.getFunctor().equals("calculateRoute")){
            try{
                int startX = (int) ((NumberTerm) action.getTerm(0)).solve();
                int startY = (int) ((NumberTerm) action.getTerm(1)).solve();
                int destX = (int) ((NumberTerm) action.getTerm(2)).solve();
                int destY = (int) ((NumberTerm) action.getTerm(3)).solve();
                String[][] map = agents.get(agName).getMap();
                ArrayList<String> directions = Pathfinding.findBestRoute(map, startX, startY, destX, destY);
                agents.get(agName).setDirections(directions);
            }
            catch(Exception e){
                e.printStackTrace();
            }
            return true;
        }
        //adds percept nextMove(Dir), based on calculated path
        if(action.getFunctor().equals("getNextMovePath")){
            try{
            addPercept(agName, ASSyntax.parseLiteral("nextMove(" + agents.get(agName).popDirection() + ")"));
            }
            catch(Exception e){
                e.printStackTrace();
            }
            return true;
        }
        //function to add percept nearestDispenser(X,Y)
        if(action.getFunctor().equals("findNearestDispenser")){
            try{
                String dispenserType = action.getTerm(0).toString();
                ArrayList<Integer> directions = agents.get(agName).findClosestDispenserOfType(dispenserType);
                //System.out.println(agName + directions.get(0) + "       " + directions.get(1));
                Literal literalToAdd = ASSyntax.createLiteral("nearestDispenser",ASSyntax.createNumber(directions.get(0)),ASSyntax.createNumber(directions.get(1)));
                addPercept(agName, literalToAdd);
            }
            catch(Exception e){
                e.printStackTrace();
            }
            return true;
        }



        if (ei == null) {
            logger.warning("There is no environment loaded! Ignoring action " + action);
            return false;
        }

        try {
            ei.performAction(agName, literalToAction(action));
            return true;
        } catch (ActException e) {
            e.printStackTrace();
        }

        return false;
    }

    /** Called before the end of MAS execution */
    @Override
    public void stop() {
        if (ei != null) {
            try {
                if (ei.isKillSupported()) ei.kill();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        super.stop();
    }

    private void handleAgentBeliefs(String agentName, ListTerm beliefs) {
        System.out.println("Beliefs of agent " + agentName + ":");
        for (Term belief : beliefs) {
            System.out.println(" - " + belief);
        }
    }

    private static Literal perceptToLiteral(Percept per) throws JasonException {
        Literal l = ASSyntax.createLiteral(per.getName());
        for (Parameter par: per.getParameters())
            l.addTerm(parameterToTerm(par));
        return l;
    }

    private static Term parameterToTerm(Parameter par) throws JasonException {
        if (par instanceof Numeral) {
            return ASSyntax.createNumber(((Numeral)par).getValue().doubleValue());
        } else if (par instanceof Identifier) {
            try {
                Identifier i = (Identifier)par;
                String a = i.getValue();
                if (!Character.isUpperCase(a.charAt(0)))
                    return ASSyntax.parseTerm(a);
            } catch (Exception ignored) {}
            return ASSyntax.createString(((Identifier)par).getValue());
        } else if (par instanceof ParameterList) {
            ListTerm list = new ListTermImpl();
            ListTerm tail = list;
            for (Parameter p: (ParameterList)par)
                tail = tail.append( parameterToTerm(p) );
            return list;
        } else if (par instanceof Function) {
            Function f = (Function)par;
            Structure l = ASSyntax.createStructure(f.getName());
            for (Parameter p: f.getParameters())
                l.addTerm(parameterToTerm(p));
            return l;
        }
        throw new JasonException("The type of parameter "+par+" is unknown!");
    }

    private static Action literalToAction(Literal action) {
        Parameter[] pars = new Parameter[action.getArity()];
        for (int i = 0; i < action.getArity(); i++)
            pars[i] = termToParameter(action.getTerm(i));
        return new Action(action.getFunctor(), pars);
    }

    private static Parameter termToParameter(Term t) {
        if (t.isNumeric()) {
            try {
                double d = ((NumberTerm) t).solve();
                if((d == Math.floor(d)) && !Double.isInfinite(d)) return new Numeral((int)d);
                return new Numeral(d);
            } catch(NoValueException e){
                e.printStackTrace();
            }
            return new Numeral(null);
        } else if (t.isList()) {
            Collection<Parameter> terms = new ArrayList<>();
            for (Term listTerm: (ListTerm)t)
                terms.add(termToParameter(listTerm));
            return new ParameterList( terms );
        } else if (t.isString()) {
            return new Identifier( ((StringTerm)t).getString() );
        } else if (t.isLiteral()) {
            Literal l = (Literal)t;
            if (!l.hasTerm()) {
                return new Identifier(l.getFunctor());
            } else {
                Parameter[] terms = new Parameter[l.getArity()];
                for (int i = 0; i < l.getArity(); i++)
                    terms[i] = termToParameter(l.getTerm(i));
                return new Function( l.getFunctor(), terms );
            }
        }
        return new Identifier(t.toString());
    }
}
