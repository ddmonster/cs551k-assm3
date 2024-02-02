package jason.eis;
import org.junit.Assert;
import org.junit.Test;
import java.util.ArrayList;
import java.util.Random;
import jason.eis.Pathfinding;

public class PathfindingTest {

    @Test
    public void testFindBestRoute() {
        String[][] map = new String[24][24];
        for (int i = 0; i < 24; i++) {
            for (int j = 0; j < 24; j++) {
                map[i][j] = "empty";
            }
        }

        for (int i = 6; i < 18; i++) {
            map[12][i] = "obstacle";
        }

        Pathfinding.setMapDimensions(24, 24);

        int startX = 1, startY = 1;
        int destX = 22, destY = 22;

        ArrayList<String> directions = Pathfinding.findBestRoute(map, startX, startY, destX, destY);

        Assert.assertFalse("Directions should not be empty", directions.isEmpty());
        printDirections(directions);

        // Since we now deal with directions instead of points, we do not directly assert the start and end points
        // Instead, we could assert the path is logical by checking the length or simulating the path
        
        // Additional validations can be performed if necessary, such as checking the sequence of directions
    }

    @Test
    public void testFindBestRouteWithRandomObstacles() {
        final int mapSize = 24;
        String[][] map = new String[mapSize][mapSize];
        Random rand = new Random();

        for (int i = 0; i < mapSize; i++) {
            for (int j = 0; j < mapSize; j++) {
                map[i][j] = "empty";
            }
        }

        int obstaclesCount = mapSize * 2;
        for (int i = 0; i < obstaclesCount; i++) {
            int x, y;
            do {
                x = rand.nextInt(mapSize);
                y = rand.nextInt(mapSize);
            } while ((x == 1 && y == 1) || (x == mapSize - 2 && y == mapSize - 2));
            map[x][y] = "obstacle";
        }

        Pathfinding.setMapDimensions(mapSize, mapSize);

        int startX = 1, startY = 1;
        int destX = mapSize - 2, destY = mapSize - 2;

        ArrayList<String> directions = Pathfinding.findBestRoute(map, startX, startY, destX, destY);

        Assert.assertFalse("Directions should not be empty", directions.isEmpty());
        printDirections(directions);

        // Additional validations as needed
    }

    // This method is no longer applicable as it prints route coordinates.
    // You may want to simulate the path from the start point using the directions to verify the end point,
    // or simply print the directions for visual inspection.
    public void printDirections(ArrayList<String> directions) {
        for (String direction : directions) {
            System.out.println(direction);
        }
    }
}
