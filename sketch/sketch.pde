/**
* Persistence algorithm by Daniel Shifmann:
* http://shiffman.net/2011/04/26/opencv-matching-faces-over-time/
*
* Based on openCV Image filtering by Jordi Tost
* https://github.com/jorditost/ImageFiltering/tree/master/ImageFilteringWithBlobPersistence
*/

import controlP5.*;
import gab.opencv.*;
import java.awt.Rectangle;
import javax.swing.JOptionPane;
import org.openkinect.freenect.*;
import org.openkinect.processing.*;
import processing.video.*;
import signal.library.*;



public Input INPUT;
public BlobDetector BLOB_DETECTOR;
public BlobAnalysis BLOB_ANALYSIS;

public float
  contrast = 1.35,
  filter_cutoff = 3.0,
  filter_beta = 0.007,
  filter_threshold = 10;
public int
  visibleSnapshot = 0,
  blob_size_min = 5,
  blob_size_max = 50,
  threshold = 75,
  thresholdBlockSize = 489,
  thresholdConstant = 45,
  blobSizeThreshold = 20,
  blurSize = 4,
  minDepth = 0,
  maxDepth = 2047;
public boolean
  invert = false,
  show_blobs = false,
  KINECT_RGB = false,
  useAdaptiveThreshold = false;
public color
  WHITE = color(255),
  BLUE = color(14, 0, 132),
  RED = color(250, 0, 100);



void setup() {
  size(1090, 500);

  initControls(0, 0);

  INPUT = new Input(this);
  BLOB_DETECTOR = new BlobDetector(this, 640, 480);
  BLOB_ANALYSIS = new BlobAnalysis(this, BLOB_DETECTOR, graph);

  setLock(depth_range, (!INPUT.isKinect));
  setLock(kinect_up_button, (!INPUT.isKinect));
  setLock(kinect_down_button, (!INPUT.isKinect));

  load();
}

// -------------------------------------------------------------------------

void draw() {
  background(255);

  BLOB_DETECTOR.detect(INPUT.getClippedDepthImage(), INPUT.getAbsoluteClip());
  BLOB_ANALYSIS.update();

  pushMatrix();
  translate(40, 10);
  String frame_name = "";
  switch (visibleSnapshot) {
    case 0 :
    frame_name = " — [input]";
    image(INPUT.getClippedDepthImage(), INPUT.getAbsoluteClip().x, INPUT.getAbsoluteClip().y);
    INPUT.drawClip();
    break;
    case 1 :
    frame_name = " — [pre-processed]";
    image(BLOB_DETECTOR.preProcessedImage, 0, 0);
    INPUT.drawClip();
    break;
    case 2 :
    frame_name = " — [processed]";
    image(BLOB_DETECTOR.processedImage, 0, 0);
    INPUT.drawClip();
    break;
    case 3 :
    frame_name = " — [contours]";
    image(BLOB_DETECTOR.contoursImage, 0, 0);
    INPUT.drawClip();
    break;
  }

  if (show_blobs) BLOB_DETECTOR.displayBlobs();
  popMatrix();

  surface.setTitle("osc-kinect-broadcaster — " +int(frameRate)+"fps" + frame_name);
}

// -------------------------------------------------------------------------

boolean dragging = false;

void mouseDragged() {
  int x = mouseX - 40,
  y = mouseY - 10;

  if (x > 0 && x < INPUT.getWidth() && y > 0 && y < INPUT.getHeight()) {
    Rectangle c = INPUT.getClip();
    if (!dragging) {
      dragging = true;
      c.x = x;
      c.y = y;
    }
    c.width = x - c.x;
    c.height = y - c.y;
  }
}

void mouseReleased() {
  dragging = false;
  INPUT.update(true);
}


void keyPressed() {
  if (keyCode == LEFT) {
    visibleSnapshot = (visibleSnapshot > 0) ? visibleSnapshot - 1 : 3;
    visibleSnapshot_toggle.activate(visibleSnapshot);
  }
  else if (keyCode == RIGHT) visibleSnapshot_toggle.activate(visibleSnapshot=++visibleSnapshot%4);
  else if (keyCode == UP) kinect_up();
  else if (keyCode == DOWN) kinect_down();
  else if (key == 's') save();
  else if (key == 'r') reset();
  else if (key == 'l') load();
  else if (key == 'f') INPUT.SMOOTH_FRAME = !INPUT.SMOOTH_FRAME;
}

void reset() {
  setup();
}

void save() {
  cp5.saveProperties(("cp5.properties"));
  println("properties saved.");
}

void load() {
  if (cp5!=null) {
    try {
      cp5.loadProperties(sketchPath("cp5.properties"));
    } catch(NullPointerException e) {
      println(e);
    }
  }
}

void kinect_up() {
  if (INPUT != null) {
    if (INPUT.isKinect) {
      INPUT.kinect_angle = constrain(++INPUT.kinect_angle, 0, 30);
      INPUT.kinect.setTilt(INPUT.kinect_angle);
      println("kinect up");
    }
  }
}


void kinect_down() {
  if (INPUT!=null) {
    if (INPUT.isKinect) {
      INPUT.kinect_angle = constrain(--INPUT.kinect_angle, 0, 30);
      INPUT.kinect.setTilt(INPUT.kinect_angle);
      println("kinect down");
    }
  }
}