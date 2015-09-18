// Polyline Simplification
// =======================
//
// This project demostrates an original algorithm for polygonal line
// simplification. Given a polygonal line, referred to as _path_, we produce
// a visually similar path, but with less vertices. The restruction criterion is
// _threshold_, which specifies the maximal distance between a point from
// original path to the simplified path.
//
// The algorithm is, implemented by
// [`PathSimplifier`](docs/PathSimplifier.html). It receives an instance of
// [`Path`](docs/Path.html) as input and provides a simplified path as result.
// The simplest use case may be as follows:
//
//     Path path = new Path();
//     float threshold = 0.3f;
//     PathSimplifier simplifier = new PathSimplifier(path, threshold);
//     path.addPoint(3, 0);
//     path.addPoint(1, 2);
//     . . .
//     path.addPoint(-4, 1);
//     Path simple = simplifier.getSimplified();
//
// The simplifier may be attached to the path at any moment and the simplified
// path may be retrievied at any time. For details, refer to the implementation.
//
// _This file contains the implementation of the demo app. No documentation
// provided, sorry._
//
// ![Demo app screenshot](screenshot.png)

final int MAX_SPARSE_POINT_RATE = 13;
final int POINT_SIZE = 7;
final int POINT_STROKE_WEIGHT = 1;
final int PATH_WEIGHT = 2;
final int SIMPLE_WEIGHT = 4;
final int ERROR_BOX_WEIGHT = 2;
final int CONVEX_HULL_WEIGHT = 2;
final int UI_AREA_SIZE = 350;
final int DETAIL_POINT_COUNT = 200;
final float MIN_THRESHOLD = 1;
final float MAX_THRESHOLD = 20;
final float INITIAL_THRESHOLD = 2;
final color BACKGROUND_COLOR = #E8DFCC;
final color UI_AREA_COLOR = #FFFEED;
final color POINT_COLOR = #665D49;
final color PATH_COLOR = #998B6D;
final color SIMPLE_COLOR = #3B2969;
final color ERROR_BOX_COLOR = #36CF72;
final color ERROR_BOX_BAD_COLOR = #FF5D76;
final color CONVEX_HULL_COLOR = #FFF533;
final color CONVEX_HULL_BAD_COLOR = #FF5D76;
final float DETAIL_FOCUS_AREA = 0.9f;

PVector detailOffset = new PVector(0, 0);
float detailScale = 4.0;

boolean drawing = false;
int lastPointMillis = 0;

Path path = new Path();
Path simple = null;
PathSimplifier simplifier;

Label generalLabel;
CheckBox showOriginal; Label showOriginalLabel;
CheckBox showSimple; Label showSimpleLabel;
Label thresholdLabel; Label thresholdValueLabel;
Slider thresholdSlider;

Label detailViewLabel;
CheckBox showErrorBox; Label showErrorBoxLabel;
CheckBox showConvexHull; Label showConvexHullLabel;
Label traceLabel;
Slider traceSlider;

Label inputMethodLabel; Button inputMethod; Button clear;
String inputMethodFreehand = "Freehand (F)";
String inputMethodSparse = "Sparse (S)";
String inputMethodPrecise = "Precise (P)";

Label originalLengthLabel;
Label simpleLengthLabel;
Label ratioLabel;

float threshold = 0;

void setup() {
  size(900, 650);
  PFont regularFont = loadFont("SourceCodePro-Regular-13.vlw");
  PFont captionFont = loadFont("SourceCodePro-Bold-16.vlw");

  path.addListener(new IPathListener () {
    public void onClear(Path sender) {
      simple = null;
    }
    public void onAddPoint(Path sender, PVector p) {
      lastPointMillis = millis();
      simple = null;
      if (sender.length() < 2)
        return;
      PVector q = sender.point(sender.length() - 2);
      detailOffset.add(Geometry.span(q, p).normalize().mult(0.05f)).div(1.05f);
    }
  });

  generalLabel = new Label(
    width - UI_AREA_SIZE + 15, 15,
    15, 20,
    "General", captionFont
  );
  showOriginal = new CheckBox(
    width - UI_AREA_SIZE + 15, 45,
    15, 15
  );
  showOriginal.checked = true;
  showOriginalLabel = new Label(
    width - UI_AREA_SIZE + 40, 45,
    15, 15,
    "Show original path", regularFont
  );
  showSimple = new CheckBox(
    width - UI_AREA_SIZE + 15, 70,
    15, 15
  );
  showSimple.checked = true;
  showSimpleLabel = new Label(
    width - UI_AREA_SIZE + 40, 70,
    15, 15,
    "Show simplified path", regularFont
  );
  thresholdLabel = new Label(
    width - UI_AREA_SIZE + 15, 100,
    15, 15,
    "Threshold:", regularFont
  );
  textFont(regularFont);
  thresholdValueLabel = new Label(
    width - 15 - textWidth("00.0px"), 100,
    15, 15,
    null, regularFont
  );
  thresholdSlider = new Slider(
    width - UI_AREA_SIZE + 15, 125,
    UI_AREA_SIZE - 30, 15
  );
  thresholdSlider.setValue(
    (INITIAL_THRESHOLD - MIN_THRESHOLD) /
    (MAX_THRESHOLD - MIN_THRESHOLD)
  );

  detailViewLabel = new Label(
    width - UI_AREA_SIZE + 15, 160,
    15, 20,
    "Detail view", captionFont
  );
  showErrorBox = new CheckBox(
    width - UI_AREA_SIZE + 15, 190,
    15, 15
  );
  showErrorBox.checked = true;
  showErrorBoxLabel = new Label(
    width - UI_AREA_SIZE + 40, 190,
    15, 15,
    "Show error box", regularFont
  );
  showConvexHull = new CheckBox(
    width - UI_AREA_SIZE + 15, 215,
    15, 15
  );
  showConvexHull.checked = true;
  showConvexHullLabel = new Label(
    width - UI_AREA_SIZE + 40, 215,
    15, 15,
    "Show convex hull", regularFont
  );
  traceLabel = new Label(
    width - UI_AREA_SIZE + 15, 245,
    15, 15,
    "Trace depth:", regularFont
  );
  traceSlider = new Slider(
    width - UI_AREA_SIZE + 15, 270,
    UI_AREA_SIZE - 30, 15
  );
  traceSlider.setValue(1);

  inputMethodLabel = new Label(
    15, 17,
    15, 15,
    "Input method:", regularFont
  );
  textFont(regularFont);
  inputMethod = new Button(
    25 + textWidth(inputMethodLabel.value), 12,
    150, 23,
    inputMethodFreehand, regularFont
  );
  clear = new Button(
    width - UI_AREA_SIZE - 115, 12,
    100, 23,
    "Clear (C)", regularFont
  );

  originalLengthLabel = new Label(
    15, height - 75,
    15, 15,
    null, regularFont
  );
  simpleLengthLabel = new Label(
    15, height - 50,
    15, 15,
    null, regularFont
  );
  ratioLabel = new Label(
    15, height - 25,
    15, 15,
    null, regularFont
  );

  IButtonListener buttonListener = new IButtonListener() {
    public void onClick(Button sender) {
      if (sender == clear)
        path.clear();
      else if (sender == inputMethod) {
        if (inputMethod.value == inputMethodFreehand)
          inputMethod.value = inputMethodSparse;
        else if (inputMethod.value == inputMethodSparse)
          inputMethod.value = inputMethodPrecise;
        else
          inputMethod.value = inputMethodFreehand;
        path.clear();
      }
    }
  };
  inputMethod.addListener(buttonListener);
  clear.addListener(buttonListener);
}

void updateUIDataBindings() {
  float newThreshold = lerp(MIN_THRESHOLD, MAX_THRESHOLD, thresholdSlider.value());
  if (newThreshold != threshold) {
    threshold = newThreshold;
    int intPart = (int)Math.floor(threshold);
    int fracPart = (int)((threshold - intPart) * 10);
    String intPartString = Integer.toString(intPart);
    if (intPartString.length() < 2)
      intPartString = " " + intPartString;
    String fracPartString = Integer.toString(fracPart);
    thresholdValueLabel.value = intPartString + "." + fracPartString + "px";
    simplifier = new PathSimplifier(path, threshold);
    simple = null;
  }

  if (simple == null);
    simple = simplifier.getSimplified();

  float ratio = (float)max(1, simple.length()) / max(1, path.length());
  int intRatio = (int)Math.round(ratio * 100);
  originalLengthLabel.value = "Original length:   " + Integer.toString(path.length());
  simpleLengthLabel.value   = "Simplified length: " + Integer.toString(simple.length());
  ratioLabel.value          = "Ratio:             " + Integer.toString(intRatio) + "%";
}

void draw() {
  updateUIDataBindings();

  background(BACKGROUND_COLOR);

  drawDetail();

  rectMode(CORNER);
  noStroke();
  fill(UI_AREA_COLOR);
  rect(width - UI_AREA_SIZE, 0, UI_AREA_SIZE, height - UI_AREA_SIZE);
  fill(BACKGROUND_COLOR);
  rect(0, 0, width - UI_AREA_SIZE, height);
  stroke(UI_AREA_COLOR);
  strokeWeight(1);
  line(width - UI_AREA_SIZE, 0, width - UI_AREA_SIZE, height);

  drawNormal();

  Control.drawAll();
}

void drawNormal() {
  if (path.isEmpty())
    return;

  stroke(PATH_COLOR);
  strokeWeight(PATH_WEIGHT);
  if (showOriginal.checked)
    drawPath(path, 1);

  stroke(SIMPLE_COLOR);
  strokeWeight(SIMPLE_WEIGHT);
  if (showSimple.checked)
    drawPath(simple, 1);
}

void drawDetail() {
  if (path.isEmpty())
    return;

  pushMatrix();
  PVector offset = PVector.mult(detailOffset, DETAIL_FOCUS_AREA * UI_AREA_SIZE / 2);
  translate(
    width - UI_AREA_SIZE / 2 + offset.x - detailScale * path.lastPoint().x,
    height - UI_AREA_SIZE / 2 + offset.y - detailScale * path.lastPoint().y
  );

  stroke(PATH_COLOR);
  strokeWeight(PATH_WEIGHT);
  if (showOriginal.checked)
    drawPath(path, detailScale);

  stroke(SIMPLE_COLOR);
  strokeWeight(SIMPLE_WEIGHT);
  if (showSimple.checked)
    drawPath(simple, detailScale);

  if (!showErrorBox.checked && !showConvexHull.checked) {
    popMatrix();
    return;
  }

  List<PathSimplifier.Event> trace = simplifier.trace;
  int j = path.length() - 1;
  PVector pj = path.point(j);
  ErrorBox errorBox = new ErrorBox(simplifier.fitter.fitLine(j, j), pj);
  SimplePathHull hull = new SimplePathHull();
  hull.offer(pj);

  final int k = (int)(traceSlider.value() * (trace.size() - 1));
  final PathSimplifier.Event e = trace.get(k);
  final int iMin = e == PathSimplifier.Event.CUT ? j - k + 1 : j - k;
  for (int i = j - 1; i >= iMin; --i) {
    PVector pi = path.point(i);
    if (showErrorBox.checked) {
      Line line = simplifier.fitter.fitLine(i, j);
      errorBox.extend(line, pi);
    }
    if (showConvexHull.checked)
      hull.offer(pi);
  }

  if (showErrorBox.checked) {
    PVector[] corners = errorBox.getCartesianCorners();
    stroke(e != PathSimplifier.Event.THRESHOLD ? ERROR_BOX_COLOR : ERROR_BOX_BAD_COLOR);
    strokeWeight(ERROR_BOX_WEIGHT);
    for (int i = 0; i < corners.length; ++i) {
      PVector p0 = PVector.mult(corners[i], detailScale);
      PVector p1 = PVector.mult(corners[(i + 1) % corners.length], detailScale);
      line(p0.x, p0.y, p1.x, p1.y);
    }
  }

  if (showConvexHull.checked) {
    stroke(
      e != PathSimplifier.Event.PIONEER_WEAK && e != PathSimplifier.Event.PIONEER_STRONG
        ? CONVEX_HULL_COLOR : CONVEX_HULL_BAD_COLOR
    );
    strokeWeight(CONVEX_HULL_WEIGHT);
    SimplePathHull.Node n = hull.first();
    do {
      PVector p0 = PVector.mult(n.pos(), detailScale);
      PVector p1 = PVector.mult(n.next().pos(), detailScale);
      line(p0.x, p0.y, p1.x, p1.y);
      n = n.next();
    } while (n != hull.first());
  }

  popMatrix();
}

void drawPath(Path path, float scale) {
  for (int i = 1; i < path.length(); ++i) {
    PVector p0 = PVector.mult(path.point(i - 1), scale);
    PVector p1 = PVector.mult(path.point(i), scale);
    line(p0.x, p0.y, p1.x, p1.y);
  }
}

void mousePressed() {
  if (Control.mousePressedAll(mouseX, mouseY))
    return;

  if (mouseX > width - UI_AREA_SIZE) {
    drawing = false;
    return;
  }

  if (inputMethod.value != inputMethodPrecise)
    path.clear();
  path.addPoint(mouseX, mouseY);
  drawing = true;
}

void mouseDragged() {
  Control.mouseDraggedAll();

  if (!drawing)
    return;

  if (
    inputMethod.value == inputMethodPrecise ||
    inputMethod.value == inputMethodSparse &&
    MAX_SPARSE_POINT_RATE * (millis() - lastPointMillis) < 1000
  ) {
    return;
  }

  path.addPoint(min(mouseX, width - UI_AREA_SIZE - PATH_WEIGHT), mouseY);
}

void mouseReleased() {
  Control.mouseReleasedAll();
  drawing = false;
}

void keyPressed() {
  String newInputMethod = null;
  switch (key) {
    case 'c':
    case 'C':
      path.clear();
      break;

    case 'f':
    case 'F':
      newInputMethod = inputMethodFreehand;
      break;

    case 'p':
    case 'P':
      newInputMethod = inputMethodPrecise;
      break;

    case 's':
    case 'S':
      newInputMethod = inputMethodSparse;
      break;
   }

   if (newInputMethod != null && inputMethod.value != newInputMethod) {
     inputMethod.value = newInputMethod;
     path.clear();
   }
}
