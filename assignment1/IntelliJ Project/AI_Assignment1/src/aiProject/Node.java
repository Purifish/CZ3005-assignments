package aiProject;

import java.util.Objects;

public class Node implements Comparable<Node>{
    int ID, eCost;
    double g, h;
    Node parent;

    public Node (int i, double g, double h, int eCost, Node parent) {
        this.ID = i;
        this.g = g;
        this.h = h;
        this.eCost = eCost;
        this.parent = parent;
    }

    public Node (int i) {
        this.ID = i;
        this.g = 0.0;
        this.h = 0.0;
        this.eCost = 0;
        this.parent = null;
    }

    public double getF() {
        return g + h;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Node node = (Node) o;
        return ID == node.ID && eCost == node.eCost; // Same Node if same ID and energy cost
    }

    @Override
    public int hashCode() {
        return Objects.hash(ID);
    }

    @Override
    public int compareTo(Node other) {
        double f1 = g + h, f2 = other.g + other.h;
        return (int)Math.ceil(f1 - f2);
    }
}
