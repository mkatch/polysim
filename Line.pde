// Line and its Coordinate System
// ==============================
//
// Line in 2D cartesian spacecan be defined implicitly by equation
//
//                         ax + by + c = 0.
//
// Such implicit definition is associated with a _line coordinate system_. Every
// plane point (_x_, _y_) be uniquely represented in the line's (_s_, _t_)
// coordinates as follows:
//
//                       (x, y) = O + sT + tN,
//
// where _O_ is the origin of the coordinate system and is defined as the
// projection of cartesian origin (0, 0) onto the line, whereas,
// _T_ = (-_b_, _a_) and _N_ = (_a_, _b_) are the tangent and normal vectors of
// the line.
//
// **Note:** Different implicit definitions of the same line may yield different
// coordinate systems.

// Line Class
// ----------
//
// Represents an implicit line definition and provides routines to work with
// its coordinate system
public static class Line
{
  public float a;
  public float b;
  public float c;

  // Creates line with given coefficients
  public Line(float a, float b, float c) {
    this.a = a;
    this.b = b;
    this.c = c;
  }

  // Gets the line origin defined as the projection of the (0, 0) cartesian
  // point onto the line. This is the origin of this line's coordinate system.
  public PVector origin() {
    float c1 = -c / (a * a + b * b);
    return new PVector(a * c1, b * c1);
  }

  // Gets the (`-b`, `a`) vector. This is the base vector for the _s_ line
  // coordinate.
  public PVector tangent() {
    return new PVector(-b, a);
  }

  // Gets the (`a`, `b`) vector. This is the base vector for the _t_ line
  // coordinate.
  public PVector normal() {
    return new PVector(a, b);
  }

  // Converts point from (_x_, _y_) cartesian coordinates to (s, t) line
  // coordinates
  public LVector map(PVector p) {
    float c1 = a * a + b * b;
    float t = (a * p.x + b * p.y + c) / c1;
    float c2 = c / c1 - t;
    float s = abs(a) > abs(b) ? (p.y + b * c2) / a : -(p.x + a * c2) / b;
    return new LVector(s, t);
  }

  // Converts point from (_s_, _t_) line coordinates to cartesian (_x_, _y_)
  // coordinates
  public PVector unmap(LVector l) {
    return unmap(l.s, l.t);
  }

  // Converts point from (_s_, _t_) line coordinates to cartesian (_x_, _y_)
  // coordinates
  public PVector unmap(float s, float t) {
    final float c1 = t - c / (a * a + b * b);
    return new PVector(c1 * a - s * b, c1 * b + s * a);
  }

  // Converts point given in this line's coordinates to the coordinate
  // system of another line
  public LVector remap(Line other, LVector l) {
    return remap(other, l.s, l.t);
  }

  // Converts point given in this line's coordinates to the coordinate
  // system of another line
  public LVector remap(Line other, float s, float t) {
    return map(other.unmap(s, t));
  }
}

// LVector Class
// -------------
//
// Represents a point in line (_s_, _t_) coordinates
public static class LVector
{
  public float s;
  public float t;

  // Creates new point with given coordinates
  public LVector(float s, float t) {
    this.s = s;
    this.t = t;
  }
}
