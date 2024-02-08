
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
public class PerceptHandler {
    private Integer x = 0;
    private Integer y = 0;
    private Integer actionNum = -1;
    private Integer vision = null;
    private List<Literal> obstacleList = new ArrayList<Literal>();
    private List<Literal> blockList = new ArrayList<Literal>();
    private List<Literal> dispensors = new ArrayList<Literal>();
    private List<Literal> goals = new ArrayList<Literal>();
    private List<Literal> tasks = new ArrayList<Literal>();
    private List<Literal> attachs = new ArrayList<Literal>();

    public Collection<Literal> handlePercepts(Collection<Literal> percepts) {
        for (Literal next : percepts) {
            if (next.getFunctor().equals("thing")) {
                List<Term> params = next.getTerms();

            }
        }
        return percepts;
    }
    

}
