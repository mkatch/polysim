// Polygonal Line Path
// ===================

// Path Class
// ----------
//
// Represents a polygonal line path. Informs registered listeners about
// any changes.
static class Path implements Iterable<PVector>
{
  // List of path points
  private ArrayList<PVector> points = new ArrayList<PVector>();

  // List of registered listeners
  private ArrayList<IPathListener> listeners = new ArrayList<IPathListener>();

  // Gets the number of points in the path
  public int length() {
    return points.size();
  }

  // True if this path has no points
  public boolean isEmpty() {
    return points.size() == 0;
  }

  // Gets the `i`th point
  public PVector point(int i) {
    return points.get(i);
  }

  // Gets the last point
  public PVector lastPoint() {
    return points.get(points.size() - 1);
  }

  // Adds new point at the end of the path
  public void addPoint(PVector p) {
    points.add(p);
    for (IPathListener listener : listeners)
      listener.onAddPoint(this, p);
  }

  // Adds new point at the end of the path
  public void addPoint(float x, float y) {
    addPoint(new PVector(x, y));
  }

  // Removes all points from the path
  public void clear() {
    points.clear();
    for (IPathListener listener : listeners)
      listener.onClear(this);
  }

  // Registers new listener. It will from now on be informed about any
  // modifications to this path. The listeners will be informed in the same
  // order they were registered.
  public void addListener(IPathListener listener) {
    listeners.add(listener);
  }

  // Gets the iterator over all points
  public Iterator<PVector> iterator() {
    return points.iterator();
  }
}

// IPathListener Interface
// -----------------------
//
// Path modification callbacks. Client must implement this interface to be
// able to be informed about modifications of a `Path`
interface IPathListener
{
  // Invoked when point `p` is added to the end of path `sender`
  void onAddPoint(Path sender, PVector p);

  // Invoked when `sender` is cleared
  void onClear(Path sender);
}
