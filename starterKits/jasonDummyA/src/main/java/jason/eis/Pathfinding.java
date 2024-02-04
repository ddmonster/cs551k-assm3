package jason.eis;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.PriorityQueue;

public class Pathfinding {
    private static int MAP_WIDTH = 128; 
    private static int MAP_HEIGHT = 128;

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
        PriorityQueue<Node> openList = new PriorityQueue<>(Comparator.comparingDouble(n -> n.f));
        boolean[][] closedList = new boolean[MAP_WIDTH][MAP_HEIGHT];
        openList.add(new Node(startX, startY, null, 0, heuristic(startX, startY, destX, destY)));

        while (!openList.isEmpty()) {
            Node currentNode = openList.poll();
            closedList[currentNode.x][currentNode.y] = true;

            if (currentNode.x == destX && currentNode.y == destY) {
                return reconstructPath(currentNode);
            }

            int[][] directions = {{0, -1}, {1, 0}, {0, 1}, {-1, 0}}; // Representing N, E, S, W
            for (int[] direction : directions) {
                int neighborX = currentNode.x + direction[0];
                int neighborY = currentNode.y + direction[1];

                if (neighborX >= 0 && neighborX < MAP_WIDTH && neighborY >= 0 && neighborY < MAP_HEIGHT) {
                    if (!map[neighborX][neighborY].equals("obstacle") && !closedList[neighborX][neighborY]) {
                        double gScore = currentNode.g + 1;
                        double hScore = heuristic(neighborX, neighborY, destX, destY);
                        Node neighborNode = new Node(neighborX, neighborY, currentNode, gScore, hScore);
                        openList.add(neighborNode);
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
