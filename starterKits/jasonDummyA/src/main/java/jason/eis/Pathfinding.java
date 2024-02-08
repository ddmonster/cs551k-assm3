package jason.eis;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.PriorityQueue;
import java.util.Random;

public class Pathfinding {
    private static int MAP_WIDTH = 128; 
    private static int MAP_HEIGHT = 128;
    private static final int MAX_OPEN_LIST_SIZE = 1000;

    private static final Random random = new Random();

    public static void setMapDimensions(int width, int height) {
        MAP_WIDTH = width;
        MAP_HEIGHT = height;
    }

    private static class Node {
        int x, y;
        Node parent;
        double g, h, f;

        public Node(int x, int y, Node parent, double g, double h) {
            this.x = x;
            this.y = y;
            this.parent = parent;
            this.g = g;
            this.h = h;
            this.f = g + h;
        }
    }

    private static double heuristic(int x, int y, int destX, int destY) {
        return Math.abs(x - destX) + Math.abs(y - destY);
    }

    public static ArrayList<String> findBestRoute(String[][] map, int startX, int startY, int destX, int destY) {
        // Modify the comparator to introduce randomness in case of equal f values
        PriorityQueue<Node> openList = new PriorityQueue<>((n1, n2) -> {
            if (n1.f < n2.f) return -1;
            if (n1.f > n2.f) return 1;
            // If f values are equal, randomly choose one to precede the other
            return random.nextBoolean() ? -1 : 1;
        });
        boolean[][] closedList = new boolean[MAP_WIDTH][MAP_HEIGHT];
        openList.add(new Node(startX, startY, null, 0, heuristic(startX, startY, destX, destY)));

        while (!openList.isEmpty()) {
            Node currentNode = openList.poll();
            closedList[currentNode.x][currentNode.y] = true;

            if (currentNode.x == destX && currentNode.y == destY) {
                return reconstructPath(currentNode);
            }

            if (openList.size() >= MAX_OPEN_LIST_SIZE) {
                // Prevent further expansion if the openList reaches its maximum size
                break;
            }

            int[][] directions = {{0, -1}, {1, 0}, {0, 1}, {-1, 0}};
            for (int[] direction : directions) {
                int neighborX = currentNode.x + direction[0];
                int neighborY = currentNode.y + direction[1];

                if (neighborX >= 0 && neighborX < MAP_WIDTH && neighborY >= 0 && neighborY < MAP_HEIGHT) {
                    if (!map[neighborX][neighborY].equals("obstacle") && !closedList[neighborX][neighborY]) {
                        double gScore = currentNode.g + 1;
                        double hScore = heuristic(neighborX, neighborY, destX, destY);
                        Node neighborNode = new Node(neighborX, neighborY, currentNode, gScore, hScore);

                        if (openList.size() < MAX_OPEN_LIST_SIZE) {
                            openList.add(neighborNode);
                        }
                    }
                }
            }
        }
        return new ArrayList<>();
    }

    private static ArrayList<String> reconstructPath(Node endNode) {
        ArrayList<String> path = new ArrayList<>();
        Node currentNode = endNode;
        Node previousNode = endNode.parent;

        while (previousNode != null) {
            if (currentNode.x == previousNode.x) {
                if (currentNode.y < previousNode.y) {
                    path.add(0, "n");
                } else {
                    path.add(0, "s");
                }
            } else {
                if (currentNode.x > previousNode.x) {
                    path.add(0, "e");
                } else {
                    path.add(0, "w");
                }
            }
            currentNode = previousNode;
            previousNode = previousNode.parent;
        }
        return path;
    }
}
