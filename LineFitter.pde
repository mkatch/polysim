// Linear Approximation
// ====================
//
// Given line _L_: _ax_ + _by_ + _c_ = 0 and point _p_ = (_x_, _y_), we can
// compute the squared distace d(_L_, _p_) between those two, using the
// simple formula
//
//              d(L, p) = (ax + by + c)^2 / (a^2 + b^2).
//
// Given a set of _n_ points, _p1_ = (_x1_, _y1_), _p2_ = (_x2_, _y2_), ...,
// _pn_ = (_xn_, _yn_), We define the _least square error_ f(_a_, _b_, _c_) of
// a linear approximation _L_ by the sum of their squared distances:
//
//        f(a, b, c) = d(L, p1) + d(L, p2) + . . . + d(L, pn).
//
// Minimizing this error yields an _optimal linear approximation in the least
// squares sense_. Solving this problem, by seeking the roots of the derivative
// of f, leads to an algorithm, that after linear preprocessing, determines the
// optimal approximation for any continuous subsequence of points in constant
// time.

// LineFitter Class
// ----------------
//
// Provides means to quickly retrieve optimal linear approximation of
// a subsequence of path points. Can be attached to a `Path` object, thus making
// the linear approximation readily avilable after any modification.
static class LineFitter implements IPathListener
{
  // Length of the path being approximated. Normally this should be equivalent
  // to `path.length()` but in the initial steps, when starting with a non empty
  // path, it may be smaller to artificially simulate the construction process.
  private int pathLength;

  // Partial sums of the point x coordinates
  private FloatList sumsX = new FloatList();

  // Partial sums of the point y coordinates
  private FloatList sumsY = new FloatList();

  // Partial sums of the squares of point x coordinates
  private FloatList sumsXX = new FloatList();

  // Partial sums of the squares of point y coordinates
  private FloatList sumsYY = new FloatList();

  // Partial sums of the products of point coordinates
  private FloatList sumsXY = new FloatList();

  // Creates new fitter attached to given path
  public LineFitter(Path path) {
    path.addListener(this);

    // We artificially invoke the modification callbacks to simulate the
    // construction steps that have taken place before this fitter was created
    onClear(path);
    for (int i = 0; i < path.length(); ++i)
      onAddPoint(path, path.point(i));
  }

  void onClear(Path sender) {
    pathLength = 0;
    sumsX.clear(); sumsX.append(0);
    sumsY.clear(); sumsY.append(0);
    sumsXX.clear(); sumsXX.append(0);
    sumsYY.clear(); sumsYY.append(0);
    sumsXY.clear(); sumsXY.append(0);
  }

  void onAddPoint(Path sender, PVector p) {
    float x = p.x, y = p.y;
    int i = pathLength;
    sumsX.append(sumsX.get(i) + x);
    sumsY.append(sumsY.get(i) + y);
    sumsXX.append(sumsXX.get(i) + x * x);
    sumsYY.append(sumsYY.get(i) + y * y);
    sumsXY.append(sumsXY.get(i) + x * y);
    ++pathLength;
  }

  // Gets the line approximation for the whole path
  public Line fitLine() {
    return fitLine(0, pathLength - 1);
  }

  // Gets the line approximation for the subpath starting at index `i` and
  // ending at index `j`.
  public Line fitLine(int i, int j) {
    return fitLine(
      rangeSum(sumsX, i, j), rangeSum(sumsY, i, j),
      rangeSum(sumsXX, i, j), rangeSum(sumsYY, i, j),
      rangeSum(sumsXY, i, j),
      j - i + 1
    );
  }

  private static Line fitLine(
    float sumX, float sumY,
    float sumXX, float sumYY,
    float sumXY,
    int n
  ) {
    if (n <= 0)
      return new Line(1, -1, 0);

    // Normally the following coefficients should never be negative, as follows
    // from the Cauchy-Schwarz inequality, but we want to play safe in case of
    // floating point errors
    float fa = max(n * sumXX - sumX * sumX, 0);
    float fb = max(n * sumYY - sumY * sumY, 0);

    // This condition detects cases where all points are nearly indistinguishable.
    // The returned line direction is difficult to compute, so we just make sure the
    // line we return passes near the points. Case `n == 1` is also handled here.
    if (fa <= Float.MIN_NORMAL && fb <= Float.MIN_NORMAL)
      return new Line(-1, -1, (sumX + sumY) / n);

    // The following computations should in ideal case give the same result, but we
    // choose the one that is numerically safer.
    if (fa < fb) {
      float a = 1.0f;
      float b = (sumX * sumY - n * sumXY) / fb;
      float c = -(sumY * b + sumX) / n;
      return new Line(a, b, c);
    } else {
      float a = (sumX * sumY - n * sumXY) / fa;
      float b = 1.0f;
      float c = -(sumX * a + sumY) / n;
      return new Line(a, b, c);
    }
  }

  private static float rangeSum(FloatList sums, int i, int j) {
    return sums.get(j + 1) - sums.get(i);
  }
}
