// Convex Hull for Simple Polygons
// ===============================
//
// The _Convex Hull Problem_ for arbitrary point set is known not to be solvalbe
// under O(_n_ log_n_) time. Nevertheless, if we know that the points make up
// non intersecting polygonal path, linear time online solutions exist, as
// reported by [**Melkman '87**](http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.512.9681).

// SimplePathHull Class
// --------------------
//
// Performs online computation of convex hull for non intersecting polygonal
// paths. The provided result is in a form of doubly linked list of points
// arranged in CCW order. Uses Melkman algorithm with minor tweaks.
public static class SimplePathHull {
  // Node of the doubly linked list that describes the convex hull polygon.
  // Holds the hull point position and provides acces to the next and previous
  // nodes in CCW order.
  public static class Node {
    // Position of the point
    private PVector pos;

    // Gets the position of the point
    public PVector pos() {
      return pos;
    }

    // Previous node in CCW order
    private Node prev;

    // Gets the previous node in CCW order, or `null` if this node no longer
    // belongs to hull
    public Node prev() {
      return prev;
    }

    // Next hull node in CCW order
    private Node next;

    // Gets the next hull node in CCW order, or `null` if this node no longer
    // belongs to hull
    public Node next() {
      return next;
    }

    // Creates a hull node with given position and neighbours. Automatically
    // alters the pointers of adjecent nodes.
    private Node(PVector pos, Node prev, Node next) {
      this.pos = pos;
      this.prev = prev;
      this.next = next;
      prev.next = next.prev = this;
    }

    // Creates a hull node with given position, connected to itself
    private Node(PVector pos) {
      this.pos = pos;
      this.prev = this.next = this;
    }

    // True if the node is part of a convex hull. A node that belongs to a hull,
    // may get removed from it when a more exterior point is added.
    public boolean isValid() {
      return next != null;
    }

    // Sets the adjecent node poinerts to null and returns the next node (as it
    // was before discarding). Does not modify the adjecent nodes.
    private Node detach() {
      Node oldNext = next;
      prev = next = null;
      return oldNext;
    }
  }

  // First node of the convex hull
  private Node first;

  // Gets the first node of the convex hull, or `null` if the hull is empty
  public Node first () {
    return first;
  }

  // Number of points making up the hull
  private int size;

  // Gets the number of points making up the hull
  public int size() {
    return size;
  }

  // Returns true if the hull contains no points
  public boolean isEmpty() {
    return size == 0;
  }

  // Tries to extend the convex hull by given point. If the point lies outside
  // or on the current hull, it is accepted, becomes the new starting point and
  // the hull is adjusted to fit the extended point set. Otherwise the point is
  // ignored.
  // Returns the newly created node if the point was accepted, and `null`
  // otherwise.
  public Node offer(PVector p) {
    if (size >= 3) {
      // In typical case with at least 3 hull points we seek tangents by skipping
      // all edges that become interior after adding `p` to the hull. Because
      // the offered points make up a non intersecting line, it suffices to
      // consider the viccinity of `first`.
      Node n0 = first;
      while (n0.prev != first && Geometry.side(n0.pos, n0.prev.pos, p) >= 0)
        n0 = n0.prev;
      Node n1 = first;
      while (n1.next != first && Geometry.side(n1.pos, n1.next.pos, p) <= 0)
        n1 = n1.next;
      // If `n0` and `n1` diverged, i.e., any one left `first`, there were some
      // skipped edges, meaning the new point indeed is exterior to the current
      // hull. In that case, `n0p` and `n1p` form tangents and anything between
      // `n0` and `n1` must be removed from the hull.
      if (n0 != n1) {
        Node n = n0.next;
        while (n != n1) {
          n = n.detach();
          --size;
        }
        first = new Node(p, n0, n1);
      }
    } else if (size == 0) {
      first = new Node(p);
    } else if (size == 1) {
      first = new Node(p, first, first);
    } else {
      // We have two points and are about to create a triangle. Make sure it
      // is counter clockwise. If the triangle would become degenerated, we stick
      // to a 2-gon and simply detach `first`.
      float s = Geometry.side(first.pos, first.next.pos, p);
      if (s < 0) {
        first = new Node(p, first, first.next);
      } else if (s > 0) {
        first = new Node(p, first.prev, first);
      } else {
        first = new Node(p, first.prev, first.detach());
        --size;
      }
    }

    if (first.pos == p) {
      ++size;
      return first;
    } else {
      return null;
    }
  }
}
