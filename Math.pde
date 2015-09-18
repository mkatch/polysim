// Math Utilities
// ======================

// Geometry Class
// --------------
//
// Provides elementary geometrical operations
public static final class Geometry
{
  // Computes the _per product_ (aka. _cross product_) of two vectors
  public static float per(PVector u, PVector v) {
    return u.x * v.y - v.x * u.y;
  }

  // Produces a vector spanned between two points
  public static PVector span(PVector a, PVector b) {
    return PVector.sub(b, a);
  }

  // Tests which side of line a given point lies at.
  //
  //   * Returns positive value if `p` is on the left side of line through
  //     `a` and `b`.
  //
  //   * Returns negative value if `p` is on the right side of line through
  //     `a` and `b`.
  //
  //   * Returns 0 if `a`, `b` and `p` are colinear.
  public static float side(PVector a, PVector b, PVector p) {
    return per(span(a, b), span(a, p));
  }

  // Computes the squared distance between two points
  public static float distSq(PVector a, PVector b) {
    float dx = a.x - b.x;
    float dy = a.y - b.y;
    return dx * dx + dy * dy;
  }

  // Tests whether segments `ab` and `cd` intersect
  public static boolean intersect(PVector a, PVector b, PVector c, PVector d) {
    // The segments intersect only if the endpoints of one are on opposite sides
    // of the other (both ways)
    PVector ab = span(a, b), ac = span(a, c), ad = span(a, d);
    float sab = per(ab, ac) * per(ab, ad);
    if (sab > 0)
      return false;
    PVector cd = span(c, d), cb = span(c, b);
    float scd = per(cd, ac) * per(cd, cb);
    // Note that `ac` is used instead of `ca` in the above line, thus reversing
    // the following condition
    if (scd < 0)
      return false;
    // When the points are colinear, we have to check if the segments overlap
    if (sab == 0 && scd == 0) {
      float abSq = ab.magSq();
      return ac.magSq() <= abSq || ad.magSq() < abSq;
    }
    return true;
  }

  // Returns a projection of point onto a line
  public static PVector project(PVector p, Line l) {
    float t = -(l.a * p.x + l.b * p.y + l.c) / (l.a * l.a + l.b * l.b);
    return new PVector(p.x + t * l.a, p.y + t * l.b);
  }

  // Returns the intersection point of two lines. The result may contain ifinities
  // if the lines are parallel, or NaNs if they are identical.
  public static PVector intersection(Line l1, Line l2) {
    float a11 = l1.a, a12 = l1.b, b1 = -l1.c;
    float a21 = l2.a, a22 = l2.b, b2 = -l2.c;

    // We now solve a linear equation `Ax = b`, where `A = [a11 a12; a21 a22]`,
    // `x = [x1; x2]` `b = [b1; b2]`. We use Gaussian elimination method with
    // full pivot selection.

    // We rearrange the equation so that the pivot is `a11`
    boolean swapResult = false;
    if (max(abs(a11), abs(a12)) < max(abs(a21), abs(a22))) {
      float tmp;
      tmp = a11; a11 = a21; a21 = tmp;
      tmp = a12; a12 = a22; a22 = tmp;
      tmp = b1; b1 = b2; b2 = tmp;
    }
    if (abs(a11) < abs(a12)) {
      float tmp;
      tmp = a11; a11 = a12; a12 = tmp;
      tmp = a21; a21 = a22; a22 = tmp;
      swapResult = true;
    }

    a22 -= a12 * a21 / a11;
    b2 -= b1 * a21 / a11;
    float x2 = b2 / a22;
    float x1 = (b1 - a12 * x2) / a11;

    return swapResult ? new PVector(x2, x1) : new PVector(x1, x2);
  }
}

// Gets the smallest of five values
public static float min(float x1, float x2, float x3, float x4, float x5) {
  return min(min(x1, x2, x3), min(x4, x5));
}

// Gets the biggest of five values
public static float max(float x1, float x2, float x3, float x4, float x5) {
  return max(max(x1, x2, x3), max(x4, x5));
}

// Truncates value to given range
public static float clamp (float x, float a, float b) {
  if (x < a)
    return a;
  else if (b < x)
    return b;
  else return x;
}

// Truncates value to given range
public static final int clamp (int x, int a, int b) {
  if (x < a)
    return a;
  else if (b < x)
    return b;
  else return x;
}

// Determines whether a `PVector` contains infinities or NaNs
public static final boolean isSingular(PVector v) {
  return Float.isInfinite(v.x) || Float.isNaN(v.x)
      || Float.isInfinite(v.y) || Float.isNaN(v.y);
}
