// Path Simplifier
// ===============
//
// The main idea of the simplification algorithm is to find the shortest route
// (we use _route_ instead of _path_ to avoid ambiguity with the polyline) in
// the (unweighted) _admissible segment graph_. The vertices of this graph are
// the path points themselves. Two points, with indices _i_ and _j_, _i_ < _j_,
// are connected if they fulfill the following conditions:
//
//   1. The subpath _S_ spanning between _i_ and _j_, inclusive, is _simple_,
//      i.e., has no self intersections.
//
//   2. The maximal distance between any point of the subpath _S_, and the
//      optimal linear approximation _L_ of path _S_, does not exceed the
//      threshold.
//
//   3. Point _i_ is a pioneer with respect to line _L_ among _S_.
//
//   4. Point _j_ is a pioneer with respect to line _L_ among _S_.
//
// After the shortest route is found, the simplified path is made up of the
// linear approximations of subpaths that correspond to the route's edges.
// For details, see: `PathSimplifier.getSimplified()`.
//
// But still some definitions remain unclear. By _optimal linear approximation_
// of a point set we would normally understand a line which has the smallest
// maximal distance to the points. But since finding such line is
// computationally hard, we use a line that is optimal in the _least squares_
// sense as a fair approximation. After linear preprocessing of a point
// sequence, such lines can be found in constant time for any subsequence. This
// is implemented by [`LineFitter`](LineFitter.html).
//
// For a set of points _S_, and a line _L_, point _p_ is a _pioneer_, if it
// belongs to _S_ and it's projection on _L_ is the most external among
// projection of all other points. In other words, the projections of other
// elements of _S_ reside on one side of the _p_'s projection. Typically, there
// are two pioneers for given _S_ and _L_.
//
// A pioneer always belongs to the _convex hull_ of it's set. Moreover, if
// we have such hull for our disposition, we can verify in constant time whether
// a given point belonging to that hull is a pioneer. For details, refer to
// `PathSimplifier.isPioneer()`. Moreover, convex hull for simple polygonal
// lines can be computed online in linear time, as is done by
// [`SimplePathHull`](SimplePathHull.html).
//
// To maintain a simplified path online, as the points arrive, the strategy is
// to take the newest point, say _j_, and for, _i_ = _j_ - 1, _j_ - 2, ...,
// 0, check if _i_ and _j_ can be connected. Along the way, seek the shothest
// route using a dynamic programming approach.
//
// From what was already said, it follows that conditions 1, 3, and 4, can be
// resolved in constant time for each _i_. The only problem remains for the
// 2nd condition. But the approximation of the maximal distance can still be
// effectively computed, using the fact, that all points lie in small radius
// from the last optimal line. This task is handled by `ErrorBox`, later in this
// file.
//
// Also note, that if any of the conditions: 1, 2, 4, fails, no further iteration
// is necessary, because we will never recover. That said, the resulting online
// step is pessimistically linear in time, but the practical complexity is much
// better.

// PathSimplifier Class
// ----------------------
//
// Maintains a simplified version of path. Can be attached to a `Path` object
// as a listener and then adjusts the simplified path online on any
// modification.
static class PathSimplifier implements IPathListener
{
  // Additional information stored for each point of the original path
  public static final class PointTag
  {
    // Distance to the starting point in the admissible segment graph
    public final int dist;

    // Index of the next vertex along the shortest path in the admissible
    // segment graph
    public final int next;

    // Determines whether the segment starting in this point takes part in an
    // intersection with another non-adjecent segment later in the path.
    public boolean cut;

    public PointTag(int dist, int next) {
      this.dist = dist;
      this.next = next;
      this.cut = false;
    }
  }

  // The original path
  private final Path path;

  // Length of the path being simplified. Normally this should be equivalent to
  // `path.length()` but in the initial steps, when starting with a non empty
  // path, it may be smaller, in order to artificially simulate the construction
  // process.
  private int pathLength;

  // `LineFitter` to retrieve information about optimal linear approximation of
  // selected path segments. It is registered as listener to `path` before this
  // `PathSimplifier`, so when we receive a path change callback, the fitter can
  // be assumed to already be in the newest state.
  public final LineFitter fitter;

  // Additional information stored for the points of simplified path. The
  // indexing of `tags` is identical to that of `path`'s.
  private final List<PointTag> tags = new ArrayList<PointTag>();

  // The maximal allowed squared distance between original path points and the
  // simplified path.
  private final float thresholdSq;

  // Possible events that may occur during addmisibility checking of segment
  // `ij` during `onAddPoint()`. Used for visualization purposes and
  // debugging.
  public enum Event
  {
    // The segment obeys all rules from 1 to 4
    ACCEPT,
    // Point `i` takes part in an intesection (rule 1 violated)
    CUT,
    // The distance to optimal line exceeds threshold (rule 2 violated)
    THRESHOLD,
    // Point `i` is not a pioneer (rule 3 violated)
    PIONEER_WEAK,
    // Point `j` is not a pioneer (rule 4 violated)
    PIONEER_STRONG
  }

  // List of events that occured for each considered `i` during last
  // `onAddPoint()`. Used for visualization purposes and debugging.
  public final List<Event> trace = new ArrayList<Event>();

  // Creates a simplifier attached to given path and using given threshold as
  // the maximal distance between the path points and the simplified path.
  public PathSimplifier(Path path, float threshold) {
    this.path = path;
    this.fitter = new LineFitter(path);
    this.thresholdSq = threshold * threshold;
    path.addListener(this);

    // We artificially invoke the modification callbacks to simulate the
    // construction steps that have taken place before this simplifier was
    // created
    onClear(path);
    for (PVector p : path)
      onAddPoint(path, p);
  }

  @Override
  public void onClear(Path sender) {
    pathLength = 0;
    tags.clear();
  }

  @Override
  public void onAddPoint(Path sender, PVector p) {
    trace.clear();
    trace.add(Event.ACCEPT);
    int j = pathLength++;
    PVector pj = p; // equivalent to path.point(j)
    ErrorBox errorBox = new ErrorBox(fitter.fitLine(j, j), pj);
    SimplePathHull hull = new SimplePathHull();
    SimplePathHull.Node nj = hull.offer(pj);

    if (j == 0) {
      tags.add(new PointTag(0, -1));
      return;
    }

    int next = j - 1;
    int dist = tags.get(next).dist;

    for (int i = j - 1; i >= 0; --i) {
      PVector pi = path.point(i);
      PointTag ti = tags.get(i);

      // Stop if the segment starting at `i` intersects with any other segment along
      // the path to `j`, because `hull` only handles simple polylines.
      if (
        ti.cut ||
        i < j - 2 &&
        Geometry.intersect(pi, path.point(i + 1), path.point(j - 1), pj)
      ) {
        ti.cut = true;
        trace.add(Event.CUT);
        break;
      }

      // Compute the optimal line approximation along with the maximal error
      // approximation and stop if the threshold is violated
      Line line = fitter.fitLine(i, j);
      errorBox.extend(line, pi);
      if (errorBox.error() > thresholdSq) {
        trace.add(Event.THRESHOLD);
        break;
      }

      // Consider the edge between `i` and `j` as admissible, if both points are
      // pioneers with respect to the optimal line. If the `j`th point is not
      // a pioneer, then it will never get back to being one, so we can break
      // right here.
      SimplePathHull.Node ni = hull.offer(pi);
      if (ni == null || !isPioneer(line, ni)) {
        trace.add(Event.PIONEER_WEAK);
        continue;
      }
      if (!isPioneer(line, nj)) {
        trace.add(Event.PIONEER_STRONG);
        break;
      }

      trace.add(Event.ACCEPT);
      if (ti.dist < dist) {
        next = i;
        dist = ti.dist;
      }
    }

    tags.add(new PointTag(dist + 1, next));
  }

  // For a given line an a convex hull point, determines whether that point is
  // a pioneer with respect to that line
  private static boolean isPioneer(Line line, SimplePathHull.Node n) {
    if (!n.isValid())
      return false;
    // For a hull point, it suffices to check whether the projections of its
    // adjecent hull points lie on the same side of its projection
    PVector t = line.tangent();
    float dp = PVector.dot(t, Geometry.span(n.pos(), n.prev().pos()));
    float dn = PVector.dot(t, Geometry.span(n.pos(), n.next().pos()));
    return dp * dn >= 0;
  }

  // Retrieves the simplified path
  public Path getSimplified() {
    if (pathLength <= 1)
      return path;

    Path result = new Path();

    // We go along the shortest route and take the line approximations of the
    // subpaths corresponding to passed edges. We add intersectionf of
    // subsequent lines as points of the simplified path. The first and the last
    // point are projections of the first and last point of the original path
    // onto the corresponding lines.
    int j = pathLength - 1;
    int i = tags.get(j).next;
    Line line = fitter.fitLine(i, j);
    result.addPoint(Geometry.project(path.point(j), line));
    while (i != 0) {
      j = i;
      i = tags.get(j).next;
      PVector pj = path.point(j);
      Line prevLine = line;
      line = fitter.fitLine(i, j);
      PVector p = Geometry.intersection(line, prevLine);
      // **TODO:** If the lines are parallel or some other crazy stuff, I can't
      // seem to find any good solution without violating the threshold
      // condition. Honestly, just adding `p`, only guarantees that we are within two
      // threshold of the original path.
      if (isSingular(p) || Geometry.distSq(p, pj) > 4 * thresholdSq)
        result.addPoint(pj);
      else
        result.addPoint(p);
    }

    result.addPoint(Geometry.project(path.point(0), line));
    return result;
  }
}

// ErrorBox Class
// --------------
//
// Manages a rectangle defined in line coordinates. It is used as a bound for
// positions of points of a given set. For detailed explanation of line
// coordinates, see: [`Line`](Line.html).
public static final class ErrorBox
{
  // Line in which cooordinate system this rectangle is defined
  private Line line;

  // Minimum and maximum _s_ coordinate
  private float s0, s1;

  // Minimum and maximum _t_ coordinate
  private float t0, t1;

  // Creates a new error box in given line coordinate system, containing
  // a single point
  public ErrorBox(Line line, PVector p) {
    this.line = line;
    LVector l = line.map(p);
    this.s0 = this.s1 = l.s;
    this.t0 = this.t1 = l.t;
  }

  // Adds new point to the bounded set, possibly enlarging the box, and
  // converts the representation to coordinate system of a new line.
  public void extend(Line line, PVector p) {
    LVector l = line.map(p);
    LVector l00 = line.remap(this.line, s0, t0);
    LVector l01 = line.remap(this.line, s0, t1);
    LVector l10 = line.remap(this.line, s1, t0);
    LVector l11 = line.remap(this.line, s1, t1);

    this.line = line;
    s0 = min(l.s, l00.s, l01.s, l10.s, l11.s);
    s1 = max(l.s, l00.s, l01.s, l10.s, l11.s);
    t0 = min(l.t, l00.t, l01.t, l10.t, l11.t);
    t1 = max(l.t, l00.t, l01.t, l10.t, l11.t);
  }

  // Computes the largest possible value of the squared distance between a point
  // inside the rectangle, and the line defining its coordinate system
  public float error() {
    return max(t0 * t0, t1 * t1) * (line.a * line.a + line.b * line.b);
  }

  // Gets the four rectangle vertices in cartesian coordinate system
  public PVector[] getCartesianCorners() {
    return new PVector[] {
      line.unmap(s0, t0),
      line.unmap(s0, t1),
      line.unmap(s1, t1),
      line.unmap(s1, t0)
    };
  }
}
