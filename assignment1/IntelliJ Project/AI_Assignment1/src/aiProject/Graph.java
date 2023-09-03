package aiProject;

import java.io.*;
import java.util.*;
import org.json.simple.*;
import org.json.simple.parser.*;

public class Graph {

    public static final int N = 264346; // num of nodes
    //public static final int ENERGY_BUDGET = Integer.MAX_VALUE;
    public static final int ENERGY_BUDGET = 287932; // energy budget
    //public static final int ENERGY_BUDGET = 850000; // energy budget
    private JSONObject dist, cost, coord, g;
    public static int ctr = 0, maxNodes = 0;

    public Graph () {
        JSONParser parser = new JSONParser();
        try {
            g = (JSONObject)parser.parse(new FileReader("G.json"));
            cost = (JSONObject)parser.parse(new FileReader("Cost.json"));
            dist = (JSONObject)parser.parse(new FileReader("Dist.json"));
            coord = (JSONObject)parser.parse(new FileReader("Coord.json"));
        } catch(Exception e) {
            e.printStackTrace();
        }
    }

    /**
     * Gets the neighbours of a node.
     * @param u The ID of the node.
     * @return A list of IDs of the neighbours of the node.
     */
    public List<Integer> retrieveNeighbours(int u) {
        List<Integer> neighbourList = new ArrayList<>();
        JSONArray neighbours = (JSONArray) g.get(String.format("%d", u));
        for (Object neighbourObj : neighbours)
        {
            neighbourList.add(Integer.parseInt((String) neighbourObj));
        }
        return neighbourList;
    }

    public double retrieveDist(String edge) {
        Object o = dist.get(edge);
        if (o instanceof Long)
        {
            return (double)(long)o; // Long cannot be cast to double, but long can
        }
        return (double)o;
    }

    public double retrieveDist(int u, int v) {
        return retrieveDist(String.format("%d,%d", u, v));
    }

    public int retrieveCost(String edge) {
        Object o = cost.get(edge);
        if (o instanceof Double)
        {
            System.out.println("Floating point cost detected!");
            return (int)(double)o;
        }
        return (int)(long)o;
    }

    public int retrieveCost(int u, int v) {
        return retrieveCost(String.format("%d,%d", u, v));
    }

    public long[] retrieveCoordinates(String node) {
        long[] xy = new long[2];
        boolean first = true;
        for (Object o : (JSONArray)coord.get(node))
        {
            if (first)
            {
                xy[0] = (long)o;
                first = false;
            }
            else
                xy[1] = (long)o;
        }
        return xy;
    }

    public long[] retrieveCoordinates(int u) {
        return retrieveCoordinates(String.format("%d", u));
    }

    public double heuristic(long x1, long y1, long x2, long y2) {
        return Math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
    }

    public double heuristic(long[] u, long[] v) {
        return heuristic(u[0], u[1], v[0], v[1]);
    }

    public double heuristic(int u, int v) {
        return heuristic(retrieveCoordinates(u), retrieveCoordinates(v));
    }

    public List<Node> basicUCS(int start, int end) {
        List<Node> path = new ArrayList<>();
        boolean[] visited = new boolean[N];
        PriorityQueue<Node> pq = new PriorityQueue<>();
        Map<Integer, Double> gScores = new HashMap<>();

        Node startNode = new Node(start, 0.0, 0.0, 0, null);
        pq.add(startNode);
        gScores.put(start, 0.0);
        // Time Complexity: O(E + V * Log(V))
        // Space Complexity: O(V) : visited, pq/path.
        maxNodes = 1;
        ctr = 1;
        while(!pq.isEmpty()){

            Node curNode = pq.poll(); // dequeue
            visited[curNode.ID - 1] = true; // mark as visited
            gScores.remove(curNode.ID);
            ctr++;
            if (curNode.ID == end) // Reached end point -> Shortest path.
            {
                while (curNode != null) // backtrack to obtain optimal path
                {
                    path.add(0, curNode);
                    curNode = curNode.parent;
                }
                return path;
            }

            for(Integer neighbour : retrieveNeighbours(curNode.ID))
            {
                double distCost = retrieveDist(curNode.ID, neighbour);
                Node neighbourNode = new Node(neighbour, curNode.g + distCost, 0.0, 0, curNode);
                if (!visited[neighbour - 1]) // ignore visited nodes - their shortest paths were found previously
                {
                    if (pq.contains(neighbourNode)) // update pq if shorter path to neighbour found
                    {
                        double oldCost = gScores.get(neighbour);
                        if (neighbourNode.g < oldCost)
                        {
                            pq.remove(neighbourNode);
                            gScores.put(neighbour, neighbourNode.g);
                            pq.add(neighbourNode);
                            maxNodes = Math.max(maxNodes, pq.size());
                        }
                    }
                    else
                    {
                        gScores.put(neighbour, neighbourNode.g);
                        pq.add(neighbourNode);
                        maxNodes = Math.max(maxNodes, pq.size());
                    }
                }
            }
        }
        // If there's no single path between two nodes.
        return path;
    }

    public List<Node> aStar(int start, int end) {
        PriorityQueue<Node> q = new PriorityQueue<>(); // Open (prio queue)
        Map<Integer, List<Node>> processed = new HashMap<>(); // holds both open AND closed nodes
        List<Node> solutionPath = new ArrayList<>();
        List<Node> tempList = new ArrayList<>();

        Node startNode = new Node(start, 0.0, heuristic(start, end), 0, null);
        q.add(startNode); // enqueue start node
        tempList.add(startNode);
        processed.put(start, tempList); // add it to processed as well
        maxNodes = 1;
        ctr = 1;

        while (!q.isEmpty())
        {
            ctr++;
            Node curr = q.poll(); // dequeue
            if (curr.ID == end) // found feasible solution
            {
                while (curr != null) // backtrack to obtain optimal path
                {
                    solutionPath.add(0, curr);
                    curr = curr.parent;
                }
                return solutionPath;
            }

            for (Integer w : retrieveNeighbours(curr.ID)) // loop through neighbours
            {
                double newG = curr.g + retrieveDist(curr.ID, w);
                int newCost = curr.eCost + retrieveCost(curr.ID, w);
                Node neighbourNode = new Node(w, newG, heuristic(w, end), newCost, curr);

                if (newCost <= ENERGY_BUDGET) // consider feasible paths only
                {
                    if (processed.containsKey(w)) // if neighbour is in open or closed sets
                    {
                        tempList = processed.get(w); // get all nodes identical to this neighbour (peers)
                        boolean updated = false;
                        for (Node node : tempList)
                        {
                            if (newG <= node.g && newCost <= node.eCost) // if absolutely better than any peer
                            {
                                q.remove(node);
                                q.add(neighbourNode);
                                node.g = newG;
                                node.eCost = newCost;
                                node.parent = curr; // then we replace the peer
                                updated = true;
                                break;
                            }

                            if (newG >= node.g && newCost >= node.eCost) // if absolutely worse than any peer
                            {
                                updated = true; // then don't consider at all, move on to next neighbour
                                break;
                            }
                        }
                        if (!updated) // not absolutely better or worse than any previous identical nodes
                        {
                            tempList.add(neighbourNode); // update processed
                            q.add(neighbourNode); // enqueue to priority queue
                            maxNodes = Math.max(maxNodes, q.size());
                        }
                    }
                    else // no checking needed
                    {
                        tempList = new ArrayList<>();
                        tempList.add(neighbourNode);
                        processed.put(w, tempList);
                        q.add(neighbourNode);
                        maxNodes = Math.max(maxNodes, q.size());
                    }
                }
            }
        }
        return solutionPath;
    }

    public List<Node> UCS(int start, int end) {
        PriorityQueue<Node> q = new PriorityQueue<>(); // Open (prio queue)
        Map<Integer, List<Node>> processed = new HashMap<>(); // holds both open AND closed nodes
        List<Node> solutionPath = new ArrayList<>();
        List<Node> tempList = new ArrayList<>();

        Node startNode = new Node(start, 0.0, 0.0, 0, null);
        q.add(startNode); // enqueue start node
        tempList.add(startNode);
        processed.put(start, tempList); // add it to processed as well
        maxNodes = 1;
        ctr = 1;

        while (!q.isEmpty())
        {
            ctr++;
            Node curr = q.poll(); // dequeue
            if (curr.ID == end) // found feasible solution
            {
                while (curr != null) // backtrack to obtain optimal path
                {
                    solutionPath.add(0, curr);
                    curr = curr.parent;
                }
                return solutionPath;
            }

            for (Integer w : retrieveNeighbours(curr.ID)) // loop through neighbours
            {
                double newG = curr.g + retrieveDist(curr.ID, w);
                int newCost = curr.eCost + retrieveCost(curr.ID, w);
                Node neighbourNode = new Node(w, newG, 0.0, newCost, curr);

                if (newCost <= ENERGY_BUDGET) // consider feasible paths only
                {
                    if (processed.containsKey(w)) // if neighbour is in open or closed sets
                    {
                        tempList = processed.get(w); // get all nodes identical to this neighbour
                        boolean updated = false;
                        for (Node node : tempList)
                        {
                            if (newG <= node.g && newCost <= node.eCost) // if absolutely better than any peer
                            {
                                q.remove(node);
                                q.add(neighbourNode);
                                node.g = newG;
                                node.eCost = newCost;
                                node.parent = curr; // then we replace the peer
                                updated = true;
                                break;
                            }

                            if (newG >= node.g && newCost >= node.eCost) // if absolutely worse than any peer
                            {
                                updated = true; // then don't consider at all, move on to next neighbour
                                break;
                            }
                        }
                        if (!updated) // not absolutely better or worse than any previous identical nodes
                        {
                            tempList.add(neighbourNode); // update processed
                            q.add(neighbourNode); // enqueue to priority queue
                            maxNodes = Math.max(maxNodes, q.size());
                        }
                    }
                    else // no checking needed
                    {
                        tempList = new ArrayList<>();
                        tempList.add(neighbourNode);
                        processed.put(w, tempList);
                        q.add(neighbourNode);
                        maxNodes = Math.max(maxNodes, q.size());
                    }
                }
            }
        }
        return solutionPath;
    }
}
