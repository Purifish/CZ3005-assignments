package aiProject;

import java.util.List;

public class Main {

    private static Graph graph;
    public static final int START = 1, END = 50;
    public static void main(String[] args) {
        System.out.println("Reading Files...");
        graph = new Graph();
        System.out.println("Graph constructed!");
        task1(graph);
        task2(graph);
        task3(graph);
    }

    private static void task1(Graph graph) {
        System.out.println("\nRunning Task 1");
        for(int i = 1; i <= 100; i++)
            System.out.print("=");
        System.out.println();
        List<Node> solPath = graph.basicUCS(START, END);
        outputPath(solPath, false, END);
    }

    private static void task2(Graph graph) {
        System.out.println("\nRunning Task 2");
        for(int i = 1; i <= 100; i++)
            System.out.print("=");
        System.out.println();
        List<Node> solPath = graph.UCS(START, END);
        outputPath(solPath, true, END);
    }

    private static void task3(Graph graph) {
        System.out.println("\nRunning Task 3");
        for(int i = 1; i <= 100; i++)
            System.out.print("=");
        System.out.println();
        List<Node> solPath = graph.aStar(START, END);
        outputPath(solPath, true, END);
    }

    private static void outputPath(List<Node> solPath, boolean constrained, int endNode) {
        if (solPath == null || solPath.size() == 0)
        {
            System.out.println("No path found!");
            return;
        }
        int totalCost = 0;
        double totalDist = 0;

        System.out.println("Shortest path:");
        for (int i = 0; i < solPath.size(); i++)
        {
            Node node = solPath.get(i);
            if (node.ID == endNode)
            {
                if (constrained)
                    totalCost = node.eCost;
                totalDist = node.g;
                System.out.printf("%6d", node.ID);
            }
            else
            {
                System.out.printf("%6d -> ", node.ID);
            }
            if (!constrained && i > 0)
            {
                Node prevNode = solPath.get(i - 1);
                totalCost += graph.retrieveCost(prevNode.ID, node.ID);
            }
            if ((i + 1) % 10 == 0)
                System.out.println();
        }

        System.out.printf("\nShortest distance: %f\n", totalDist);
        System.out.printf("Total energy cost: %d\n", totalCost);
        System.out.println("\n[Additional info]\nTotal nodes processed: " + Graph.ctr);
        System.out.println("Max number of nodes in priority queue: " + Graph.maxNodes);
    }
}
