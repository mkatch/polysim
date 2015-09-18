import java.util.*;

// I don't care. Cheers!

public static class Control
{
  public static final color LIGHT = #EDEDED;
  public static final color MIDDLE = #A89C83;
  public static final color DARK = #4A4335;
  
  private static List<Control> controls = new ArrayList<Control>();
  private static Control dragged = null;
  
  public static void drawAll() {
    for (Control control : controls)
      control.draw();
  }
  
  public static boolean mousePressedAll(int mouseX, int mouseY) {
    for (Control control : controls) {
      if (control.contains(mouseX, mouseY) && control.mousePressed()) {
        dragged = control;
        return true;
      }
    }
    return false;
  }
  
  public static void mouseReleasedAll() {
    if (dragged != null) {
      dragged.mouseReleased();
      dragged = null;
    }
  }
  
  public static void mouseDraggedAll() {
    if (dragged != null)
      dragged.mouseDragged();
  }
  
  public float x, y, width, height;

  public Control(float x, float y, float width, float height) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    controls.add(this);
  }
  
  public boolean contains(PVector p) {
    return x <= p.x && p.x <= x + width
        && y <= p.y && p.y <= y + height;
  }
  
  public boolean contains(float x, float y) {
    return contains(new PVector(x, y));
  }
  
  protected void draw() { }
  
  protected boolean mousePressed() { return false; }
  
  protected void mouseReleased() { }
  
  protected void mouseDragged() { }
}

class Label extends Control
{
  public String value;
  public PFont font;
  
  public Label(
    float x, float y, float width, float height,
    String value, PFont font
  ) {
    super(x, y, width, height);
    this.value = value;
    this.font = font;
  }
  
  @Override
  protected void draw() {
    if (value == null || font == null)
      return;
    noStroke();
    fill(DARK);
    textFont(font);
    text(value, x, y + (height - textAscent() - textDescent()) / 2 + textAscent());
  }
}

class Button extends Control
{
  public String value;
  public PFont font;
  List<IButtonListener> listeners = new ArrayList<IButtonListener>();
  
  public Button(
    float x, float y, float width, float height,
    String value, PFont font
  ) {
    super(x, y, width, height);
    this.value = value;
    this.font = font;
  }
  
  @Override
  protected void draw() {
    noStroke();
    fill(MIDDLE);
    rectMode(CORNER);
    rect(x, y, width, height);
    if (value == null || font == null)
      return;
    textFont(font);
    float tw = textWidth(value);
    float ta = textAscent();
    float th = ta + textDescent();
    fill(DARK);
    text(value, x + (width - tw) / 2, y + (height - th) / 2 + ta + 1);
  }
  
  @Override
  protected boolean mousePressed() {
    for (IButtonListener listener : listeners)
      listener.onClick(this);
    return true;
  }
  
  void addListener(IButtonListener listener) {
    listeners.add(listener);
  }
}

interface IButtonListener
{
  void onClick(Button sender);
}

class CheckBox extends Control
{
  public boolean checked = false;
  
  public CheckBox(float x, float y, float width, float height) {
    super(x, y, width, height);
  }
  
  @Override
  protected void draw() {
    rectMode(CORNER);
    noStroke();
    fill(MIDDLE);
    rect(x, y, width, height);
    if (checked) {
      fill(DARK);
      float margin = max(1, min(width, height) / 5);
      rect(x + margin, y + margin, width - 2 * margin, height - 2 * margin);
    }
  }
  
  @Override
  protected boolean mousePressed() {
    checked = !checked;
    return true;
  }
}

class Slider extends Control
{
  final int SLIDER_SIZE = 15;
  final int SLIDE_WEIGHT = 2;
  
  private float value = 0.0f;
  
  public float value() {
    return value;
  }
  
  public void setValue(float value) {
    this.value = clamp(value, 0, 1);
  }
  
  private boolean dragging = false;
  
  Slider(float x, float y, float width, float height) {
    super(x, y, width, height);
  }
  
  PVector sliderPosition(float value) {
    return new PVector(
      x + SLIDER_SIZE / 2 + value * (width - SLIDER_SIZE),
      y + height / 2
    );
  }
  
  @Override
  protected void draw() {
    PVector p0 = sliderPosition(0);
    PVector pValue = sliderPosition(value);
    PVector p1 = sliderPosition(1);
    
    strokeWeight(SLIDE_WEIGHT);
    stroke(DARK);
    line(p0.x, p0.y, p1.x, p1.y);
    
    ellipseMode(CENTER);
    noStroke();
    fill(MIDDLE);
    ellipse(pValue.x, pValue.y, SLIDER_SIZE, SLIDER_SIZE);
  }
  
  @Override
  protected boolean mousePressed() {
    PVector m = new PVector(mouseX, mouseY);
    dragging = PVector.dist(m, sliderPosition(value)) < SLIDER_SIZE / 2;
    return dragging;
  }
  
  @Override
  protected void mouseDragged() {
    float newValue = (mouseX - sliderPosition(0).x) / (width - SLIDER_SIZE);
    value = clamp(newValue, 0, 1);
  }
}