import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import controlP5.*; 
import gab.opencv.*; 
import java.awt.Rectangle; 
import javax.swing.JOptionPane; 
import org.openkinect.freenect.*; 
import org.openkinect.processing.*; 
import processing.video.*; 
import signal.library.*; 
import oscP5.*; 
import netP5.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class sketch extends PApplet {

/**
* Persistence algorithm by Daniel Shifmann:
* http://shiffman.net/2011/04/26/opencv-matching-faces-over-time/
*
* Based on openCV Image filtering by Jordi Tost
* https://github.com/jorditost/ImageFiltering/tree/master/ImageFilteringWithBlobPersistence
*/












public Input INPUT;
public BlobDetector BLOB_DETECTOR;
public BlobAnalysis BLOB_ANALYSIS;

public float
  contrast = 1.35f,
  filter_cutoff = 3.0f,
  filter_beta = 0.007f,
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
public int
  WHITE = color(255),
  BLUE = color(14, 0, 132),
  RED = color(250, 0, 100);



public void setup() {
  
  frameRate(15);

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

public void draw() {
  background(255);

  BLOB_DETECTOR.detect(INPUT.getClippedDepthImage(), INPUT.getAbsoluteClip());
  BLOB_ANALYSIS.update();

  pushMatrix();
  translate(40, 10);
  String frame_name = "";
  switch (visibleSnapshot) {
    case 0 :
    frame_name = " \u2014 [input]";
    image(INPUT.getRawDepthImage(), 0, 0);
    noStroke();
    fill(0, 255*.3f);
    rect(0, 0, 640, 480);
    image(INPUT.getClippedDepthImage(), INPUT.getAbsoluteClip().x, INPUT.getAbsoluteClip().y);
    INPUT.drawClip();
    break;
    case 1 :
    frame_name = " \u2014 [pre-processed]";
    image(BLOB_DETECTOR.preProcessedImage, 0, 0);
    INPUT.drawClip();
    break;
    case 2 :
    frame_name = " \u2014 [processed]";
    image(BLOB_DETECTOR.processedImage, 0, 0);
    INPUT.drawClip();
    break;
    case 3 :
    frame_name = " \u2014 [contours]";
    image(BLOB_DETECTOR.contoursImage, 0, 0);
    INPUT.drawClip();
    break;
  }

  if (show_blobs) BLOB_DETECTOR.displayBlobs();
  popMatrix();

  surface.setTitle("osc-kinect-broadcaster \u2014 " +PApplet.parseInt(frameRate)+"fps" + frame_name);
}

// -------------------------------------------------------------------------

boolean dragging = false;

public void mouseDragged() {
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

public void mouseReleased() {
  dragging = false;
  INPUT.update(true);
}


public void keyPressed() {
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

public void reset() {
  setup();
}

public void save() {
  cp5.saveProperties(("cp5.properties"));
  println("properties saved.");
}

public void load() {
  if (cp5!=null) {
    try {
      cp5.loadProperties(sketchPath("cp5.properties"));
    } catch(NullPointerException e) {
      println(e);
    }
  }
}

public void kinect_up() {
  if (INPUT != null) {
    if (INPUT.isKinect) {
      INPUT.kinect_angle = constrain(++INPUT.kinect_angle, 0, 30);
      INPUT.kinect.setTilt(INPUT.kinect_angle);
      println("kinect up");
    }
  }
}


public void kinect_down() {
  if (INPUT!=null) {
    if (INPUT.isKinect) {
      INPUT.kinect_angle = constrain(--INPUT.kinect_angle, 0, 30);
      INPUT.kinect.setTilt(INPUT.kinect_angle);
      println("kinect down");
    }
  }
}
public class Blob {
	private PApplet parent;
	public Contour contour;
	public boolean available;
	public boolean delete;

	private int initTimer = 15;
	public int timer;
	public int id;

	private PVector position, p_position, size, p_size;

	public Blob(PApplet parent, int id, Contour c) {
		this.parent = parent;
		this.id = id;
		this.contour = new Contour(parent, c.pointMat);

		this.available = true;
		this.delete = false;
		this.timer = initTimer;

		this.position = this.computePosition();
		this.p_position = this.position;
		// this.p_position = new PVector(0,0);

		this.size = this.computeSize();
		this.p_size = this.size;
		// this.p_size = new PVector(0,0);
	}



	// -------------------------------------------------------------------------
	public void display() { this.display(-1); }
	public void display(int id) {
		Rectangle r = contour.getBoundingBox();

		fill(14, 0, 132, map(this.timer, 0, this.initTimer, 0, 127));
		stroke(255);
		strokeWeight(2);
		rect(r.x, r.y, r.width, r.height);

		stroke(250, 0, 100);
		strokeWeight(10);
		point(this.position.x, this.position.y);

		strokeWeight(4);
		line(this.p_position.x, this.p_position.y, this.position.x, this.position.y);

		if(id>=0){
			fill(255);
			textSize(14);
			text(""+id +" ("+this.id+")", r.x+6, r.y+18);
		}
	}



	// -------------------------------------------------------------------------
	public void update(Contour newC) {
		this.contour = new Contour(parent, newC.pointMat);
		this.p_position = this.position;
		this.position = this.computePosition();

		this.p_size = this.size;
		this.size = this.computeSize();
	}

	public void countDown() { this.timer--; }
	public boolean dead() { return (this.timer < 0); }
	public Rectangle getBoundingBox() { return contour.getBoundingBox(); }

	// -------------------------------------------------------------------------
	public PVector computePosition() {
		Rectangle r = this.getBoundingBox();
		return new PVector( r.x + r.width*.5f, r.y + r.height*.5f );
	}

	public PVector computeSize() {
		Rectangle r = this.getBoundingBox();
		return new PVector(r.width, r.height);
	}

	public PVector getPosition() { return this.position; }
	public PVector getPrevPosition() { return this.p_position; }
	public float getDeltaPosition() { return this.position.dist(this.p_position); }

	public PVector getSize() { return this.size; }
	public PVector getPrevSize() { return this.p_size; }
	public float getDeltaSize() { return this.size.dist(this.p_size); }

	public float getDelta() { return this.getDeltaSize() + this.getDeltaPosition(); }
}

public class BlobAnalysis {
	private PApplet parent;
	public OSCWrapper OSC;
	private BlobDetector detector;
	private Chart chart;
	private SignalFilter filter;

	private int max;
	private float MAX_FILTERED_VALUE;
	private float threshold = 10;

	// -------------------------------------------------------------------------

  public BlobAnalysis(PApplet parent, BlobDetector detector, Chart chart) {
		this.parent = parent;
		this.detector = detector;
		this.chart = chart.setRange(-10, 100)
						.addDataSet("v")
						.setData("v", new float[100])

						.addDataSet("vf")
						.setData("vf", new float[100])
						.setColors("vf", color(255), color(255))

						.addDataSet("threshold")
						.setColors("threshold", color(250, 0, 100), color(250, 0, 100))
						.setData("threshold", new float[2])

						.setStrokeWeight(3);

		for (int i = 0; i < 2; i++) {
      this.chart.push("threshold", this.threshold);
    }

		this.filter = new SignalFilter(parent);
		this.OSC = new OSCWrapper(parent);
		this.MAX_FILTERED_VALUE = 0;
	}

	// -------------------------------------------------------------------------

	public void update() {
		this.filter.setMinCutoff(filter_cutoff);
		this.filter.setBeta(filter_beta);
		if (filter_threshold != this.threshold) {
			this.threshold = filter_threshold;
			for(int i = 0; i < 2; i++) this.chart.push("threshold", this.threshold);
		}

    float avg = 0;
    for (Blob b : this.detector.blobList) {
      float v = b.getDelta();
      avg += v;
      if (v > this.threshold) this.OSC.send(b);
    }

    avg /= this.detector.blobList.size();
    if (avg > 0) {
      float filtered_avg = this.filter.filterUnitFloat(avg);
      if (filtered_avg > this.MAX_FILTERED_VALUE) this.MAX_FILTERED_VALUE = filtered_avg;
      if (this.MAX_FILTERED_VALUE > 0) this.MAX_FILTERED_VALUE = 0;
      this.chart.push("v", avg);
      this.chart.push("vf", filtered_avg);
    }

	}
}
public class BlobDetector {

  private PApplet parent;
  private int width, height;

  private OpenCV opencv;
  private ArrayList<Contour> contours, newBlobContours;
  private ArrayList<Blob> blobList;
  private int blobCount = 0;

  private PImage src, preProcessedImage, processedImage, contoursImage;



  // -------------------------------------------------------------------------
  public BlobDetector(PApplet parent, int width, int height) {
    this.parent = parent;
    this.width = width;
    this.height = height;

    this.opencv = new OpenCV(parent, width, height);
    this.contours = new ArrayList<Contour>();
    this.blobList = new ArrayList<Blob>();
  }



  // -------------------------------------------------------------------------
  public void detect(PImage input) {
    this.detect(input, null);
  }

  public void detect(PImage input, Rectangle clip) {
    // MANUAL ROI
    if (clip != null) {
      // this.opencv.setROI(clip.x, clip.y, clip.width, clip.height);
      PGraphics pg = createGraphics(this.width, this.height);
      pg.beginDraw();
      pg.background(0);
      pg.image(input, clip.x, clip.y);
      pg.endDraw();
      input = pg.get();
    }

    this.opencv.loadImage(input);
    src = opencv.getSnapshot();

    // pre-process
    opencv.gray();
    // opencv.brightness(int(cp5_brightness));
    opencv.contrast(contrast);

    preProcessedImage = opencv.getSnapshot();

    if (useAdaptiveThreshold) {
      // Block size must be odd and greater than 3
      if (thresholdBlockSize%2 == 0) thresholdBlockSize++;
      if (thresholdBlockSize < 3) thresholdBlockSize = 3;

      opencv.adaptiveThreshold(thresholdBlockSize, thresholdConstant);
    } else opencv.threshold(threshold);

    if (invert) opencv.invert();

    // Reduce noise - Dilate and erode to close holes
    opencv.dilate();
    opencv.erode();
    opencv.blur(blurSize);
    processedImage = opencv.getSnapshot();


    this.detectBlobs();
    contoursImage = opencv.getSnapshot();
  }


  private void detectBlobs() {
    // Contours detected in this frame
    // Passing 'true' sorts them by descending area.
    contours = opencv.findContours(true, true);
    newBlobContours = getBlobsFromContours(contours);

    // Check if the detected blobs already exist are new or some has disappeared.

    if (blobList.isEmpty()) {
    // Just make a Blob object for every face Rectangle
    for (int i = 0; i < newBlobContours.size(); i++) {
        // println("new blob detected with ID: " + blobCount);
        blobList.add(new Blob(this.parent, blobCount, newBlobContours.get(i)));
        blobCount++;
      }
    } else if (blobList.size() <= newBlobContours.size()) {

      boolean[] used = new boolean[newBlobContours.size()];
      // Match existing Blob objects with a Rectangle
      for (Blob b : blobList) {
        // Find the new blob newBlobContours.get(index) that is closest to blob b
        // set used[index] to true so that it can't be used twice
        float record = 50000;
        int index = -1;
        for (int i = 0; i < newBlobContours.size(); i++) {
          float d = dist(newBlobContours.get(i).getBoundingBox().x, newBlobContours.get(i).getBoundingBox().y, b.getBoundingBox().x, b.getBoundingBox().y);
          //float d = dist(blobs[i].x, blobs[i].y, b.r.x, b.r.y);
          if (d < record && !used[i]) {
            record = d;
            index = i;
          }
        }
        used[index] = true;
        b.update(newBlobContours.get(index));
      }

      for (int i = 0; i < newBlobContours.size(); i++) {
        if (!used[i]) {
          // println("new blob detected with ID: " + blobCount);
          blobList.add(new Blob(this.parent, blobCount, newBlobContours.get(i)));
          //blobList.add(new Blob(blobCount, blobs[i].x, blobs[i].y, blobs[i].width, blobs[i].height));
          blobCount++;
        }
      }

    } else {

      for (Blob b : blobList) b.available = true;

        // Match Rectangle with a Blob object
      for (int i = 0; i < newBlobContours.size(); i++) {
          // Find blob object closest to the newBlobContours.get(i) Contour
          // set available to false
          float record = 50000;
          int index = -1;
          for (int j = 0; j < blobList.size(); j++) {
            Blob b = blobList.get(j);
            float d = dist(newBlobContours.get(i).getBoundingBox().x, newBlobContours.get(i).getBoundingBox().y, b.getBoundingBox().x, b.getBoundingBox().y);
            //float d = dist(blobs[i].x, blobs[i].y, b.r.x, b.r.y);
            if (d < record && b.available) {
              record = d;
              index = j;
            }
          }

          Blob b = blobList.get(index);
          b.available = false;
          b.update(newBlobContours.get(i));
        }

        for (Blob b : blobList) {
          if (b.available) {
            b.countDown();
            if (b.dead()) {
              b.delete = true;
            }
          }
        }
      }

    // Delete any blob that should be deleted
    for (int i = blobList.size()-1; i >= 0; i--) {
      Blob b = blobList.get(i);
      if (b.delete) {
        blobList.remove(i);
      }
    }
  }



  // -------------------------------------------------------------------------
  public ArrayList<Contour> getBlobsFromContours(ArrayList<Contour> newContours) {
    ArrayList<Contour> newBlobs = new ArrayList<Contour>();

    for (int i = 0; i < newContours.size(); i++) {
      Contour contour = newContours.get(i);
      Rectangle r = contour.getBoundingBox();

      if (r.width*r.height < map(blob_size_min, 0, 100, 0, 640*480)) continue;
      if (r.width*r.height < map(blob_size_max, 0, 100, 0, 640*480)) newBlobs.add(contour);
    }

    return newBlobs;
  }



  // -------------------------------------------------------------------------
  private void displayBlobs() {
    int i = 0;
    for (Blob b : blobList) {
      strokeWeight(1);
      b.display(i++);
    }
  }
}
public class Input {

	public boolean SMOOTH_FRAME = false;

	private PApplet parent;

	private Kinect kinect;
	private boolean isKinect = false;
	private boolean isWebcam = false;
	private float kinect_angle;

	private Capture webcam;
	private int[] depthThreshold = {0, 2047};
	private PImage img, pimg;

	private Rectangle clip;

	// -------------------------------------------------------------------------

	public Input(PApplet parent) {
		this.parent = parent;

		this.kinect = new Kinect(parent);
		if (this.kinect.numDevices() > 0) {
			this.isKinect = true;
			this.kinect.initDepth();
			this.kinect.initVideo();
			this.kinect.enableColorDepth(true);
			this.kinect_angle = this.kinect.getTilt();
			this.img = new PImage(this.kinect.width, this.kinect.height);
			this.pimg = new PImage(this.kinect.width, this.kinect.height);
			this.clip = new Rectangle(0, 0, this.kinect.width, this.kinect.height);
		} else {
			this.isWebcam = true;
			this.webcam = new Capture(parent, 640, 480);
			this.webcam.start();

			this.img = new PImage(this.webcam.width, this.webcam.height);
			this.SMOOTH_FRAME = false;
			this.clip = new Rectangle(0, 0, this.webcam.width, this.webcam.height);
		}
	}



	// -------------------------------------------------------------------------
	private PImage update() { return this.update(false); }
	private PImage update(boolean forceUpdate) {
		if (this.isWebcam) return this.update_webcam();
		else if (KINECT_RGB) return this.kinect.getVideoImage();
		else return this.update_kinect(forceUpdate);
	}

	private PImage update_webcam() {
		if (this.webcam.available()) this.webcam.read();
		this.img = this.webcam;
		return this.img;
	}

	private PImage update_kinect(boolean forceUpdate) {
		if (forceUpdate) this.img.pixels = new int[this.img.pixels.length];

		int[] rawDepth = this.kinect.getRawDepth();

		PImage depth = this.kinect.getDepthImage();
		depth.loadPixels();

		Rectangle clip = this.getAbsoluteClip();

		for (int x = constrain(clip.x, 0, depth.width); x < constrain(clip.width, x, depth.width); x++) {
			for (int y = constrain(clip.y, 0, depth.height); y < constrain(clip.height, y, depth.height); y++) {
				int index = x + y*depth.width;

				if (rawDepth[index] >= this.depthThreshold[0] && rawDepth[index] <= this.depthThreshold[1]) {
					if (this.SMOOTH_FRAME) {
						this.img.pixels[index] = lerpColor(this.pimg.pixels[index], this.kinect.getDepthImage().pixels[index], .5f);
					}else this.img.pixels[index] = this.kinect.getDepthImage().pixels[index];
				}
				else this.img.pixels[index] = color(0);
			}
		}

		this.img.updatePixels();
		if (this.SMOOTH_FRAME) this.pimg = this.img;
		return this.img;
	}




	// -------------------------------------------------------------------------
	public int getHeight() { return this.img.height; }
	public int getWidth() { return this.img.width; }
	public int[] getDepthThreshold() { return this.depthThreshold; }
	public Kinect getKinect() { return this.kinect; }

	public PImage getDepthImage() { return this.update();}
	public PImage getRawDepthImage() {
		if (this.webcam != null) return this.update_webcam();
		else return this.kinect.getDepthImage();
	}
	public PImage getClippedDepthImage() {
		Rectangle c = this.getAbsoluteClip();
		return this.update().get(c.x, c.y, c.width-c.x, c.height-c.y);
	}

	public Rectangle getClip() { return this.clip; }
	public Rectangle getAbsoluteClip() {
		Rectangle c = this.getClip();
		return new Rectangle(
			min(c.x, c.width + c.x),
			min(c.y, c.height + c.y),
			max(c.x, c.x + c.width),
			max(c.y, c.y + c.height)
		);
	}


	// -------------------------------------------------------------------------
	public void drawClip() {
		pushStyle();
		noFill();
		strokeWeight(4);
		stroke(250, 0, 100);

		Rectangle c = this.getClip();
		rect(c.x, c.y, c.width, c.height);

		popStyle();
	}
}



public class OSCWrapper {
  private OscP5 oscP5;
  private NetAddress address;

  // -------------------------------------------------------------------------

  public OSCWrapper(PApplet parent) {
    this.oscP5 = new OscP5(parent, 12000);
    this.address = new NetAddress("127.0.0.1", 32000);
  }

  // -------------------------------------------------------------------------

  public void send(Blob blob) {
    OscBundle bundle = new OscBundle();
    OscMessage message = new OscMessage("/blob");

    println("blob.x: "+ blob.position.x);

    message.add(blob.id);
    message.add(blob.position.x);
    message.add(blob.position.y);
    message.add(blob.size.x);
    message.add(blob.size.y);

    bundle.add(message);
    bundle.setTimetag(bundle.now() + 10000);
    this.oscP5.send(bundle, this.address);
  }

}
public ControlP5 cp5;
public RadioButton visibleSnapshot_toggle;
public Button kinect_up_button, kinect_down_button;
public Range blobsize_slider, depth_range;
public Println console;
public Textarea console_area;
public Chart graph;
public int buttonColor, buttonBgColor;

// -------------------------------------------------------------------------

public void initControls(int x, int y) {
	x += 10; y += 10;
	int w = 125;

	if(cp5!=null) cp5.dispose(); // fix hard reset
	cp5 = new ControlP5(this);
	cp5.getProperties().setFormat(ControlP5.SERIALIZED);

	cp5.addButton("reset")
		.setLabel("R")
		.setColorLabel(WHITE)
		.setColorBackground(BLUE)
		.setColorForeground(RED)
		.setSize(20, 20)
		.setPosition(x, (height-(y+=21)));

	cp5.addButton("load")
		.setLabel("L")
		.setColorLabel(WHITE)
		.setColorBackground(BLUE)
		.setColorForeground(RED)
		.setSize(20, 20)
		.setPosition(x, (height-(y+=30)));

	cp5.addButton("save")
		.setLabel("S")
		.setColorLabel(WHITE)
		.setColorBackground(BLUE)
		.setColorForeground(RED)
		.setSize(20, 20)
		.setPosition(x, (height-(y+=21)));

	kinect_up_button = cp5.addButton("kinect_up")
		.setLabel("^")
		.setColorLabel(WHITE)
		.setColorBackground(BLUE)
		.setColorForeground(RED)
		.setSize(20, 20)
		.setPosition(x, y=10);

	kinect_down_button = cp5.addButton("kinect_down")
		.setLabel("v")
		.setColorLabel(WHITE)
		.setColorBackground(BLUE)
		.setColorForeground(RED)
		.setSize(20, 20)
		.setPosition(x, y+=21);

	cp5.addToggle("KINECT_RGB")
		.setLabel("K")
		.setColorLabel(WHITE)
		.setColorBackground(BLUE)
		.setColorForeground(RED)
		.setSize(20, 20)
		.setPosition(x, y+=21);

	// -------------------------------------------------------------------------

	visibleSnapshot_toggle = cp5.addRadioButton("radioButton")
		.setPosition(x+=(21+10+640+10), y=10)
		.setSize(20,20)
		.setColorLabel(color(0))
		.setColorBackground(BLUE)
		.setColorActive(RED)
		.setItemsPerRow(6)
		.addItem("0",0)
		.addItem("1",1)
		.addItem("2",2)
		.addItem("3",3)
		// .addItem("4",4)
		.hideLabels();
	visibleSnapshot_toggle.activate(visibleSnapshot);

	cp5.addToggle("show_blobs")
		.setLabel("blobs")
		.setColorLabel(color(0))
		.setColorBackground(BLUE)
		.setColorForeground(RED)
		.setSize(20, 20)
		.setPosition(x + 105, 10)
		.getCaptionLabel()
		.getStyle()
		.setMargin(-19,0,0,25);

	cp5.addSlider("contrast")
		.setLabel("") // label "contrast" is on the invert toggle \u00af\_(\u30c4)_/\u00af
		.setColorLabel(color(0))
		.setColorBackground(BLUE)
		.setColorForeground(RED)
		.setPosition(x, y+=21)
		.setSize(w-21, 20)
		.setRange(0.0f, 10.0f);

	cp5.addToggle("invert")
		.setLabel("contrast")
		.setColorLabel(color(0))
		.setColorBackground(BLUE)
		.setColorForeground(RED)
		.setSize(20,20)
		.setPosition(x+w-20, y)
		.getCaptionLabel()
		.getStyle()
		.setMargin(-19,0,0,25);

	// -------------------------------------------------------------------------

	depth_range = cp5.addRange("depth_range")
		.setLabel("depth range")
		.setColorLabel(color(0))
		.setBroadcast(false)
		.setPosition(x, y+=21)
		.setSize(w, 20)
		.setHandleSize(5)
		.setRange(0, 2047)
		.setRangeValues(100, 1027)
		.setBroadcast(true)
		.setColorForeground(RED)
		.setColorBackground(BLUE);

	// -------------------------------------------------------------------------

	cp5.addToggle("toggleAdaptiveThreshold")
		.setLabel("use adaptive threshold")
		.setColorLabel(color(0))
		.setColorBackground(BLUE)
		.setColorForeground(RED)
		.setSize(20,20)
		.setPosition(x, y+=30)
		.getCaptionLabel()
		.getStyle()
		.setMargin(-19,0,0,25);

	cp5.addSlider("threshold")
		.setLabel("threshold")
		.setColorLabel(color(0))
		.setColorBackground(BLUE)
		.setColorForeground(RED)
		.setPosition(x, y+=21)
		.setSize(w, 20)
		.setRange(0,255);

	cp5.addSlider("thresholdBlockSize")
		.setLabel("a.t. block size")
		.setColorLabel(color(0))
		.setColorBackground(BLUE)
		.setColorForeground(RED)
		.setPosition(x, y+=21)
		.setSize(w, 20)
		.setRange(1,700);

	cp5.addSlider("thresholdConstant")
		.setLabel("a.t. constant")
		.setColorLabel(color(0))
		.setColorBackground(BLUE)
		.setColorForeground(RED)
		.setPosition(x, y+=21)
		.setSize(w, 20)
		.setRange(-100,100);


	// -------------------------------------------------------------------------

	cp5.addSlider("blurSize")
		.setLabel("blur size")
		.setColorLabel(color(0))
		.setColorBackground(BLUE)
		.setColorForeground(RED)
		.setPosition(x, y+=30)
		.setSize(w, 20)
		.setRange(1, 100);

	blobsize_slider = cp5.addRange("blobSizeThreshold")
		.setLabel("blob size range")
		.setColorLabel(color(0))
		.setBroadcast(false)
		.setPosition(x, y+=21)
		.setSize(w, 20)
		.setHandleSize(5)
		.setRange(0, 50)
		.setRangeValues(blob_size_min, blob_size_max)
		.setBroadcast(true)
		.setColorForeground(RED)
		.setColorBackground(BLUE);


	// -------------------------------------------------------------------------
	// cp5.addSlider("filter_cutoff")
	// 	.setLabel("filter min cutoff")
	// 	.setColorLabel(color(0))
	// 	.setColorBackground(BLUE)
	// 	.setColorForeground(RED)
	// 	.setPosition(x, y+=30)
	// 	.setSize(w, 20)
	// 	.setRange(0.0, 10.0);

	// cp5.addSlider("filter_beta")
	// 	.setLabel("filter Beta")
	// 	.setColorLabel(color(0))
	// 	.setColorBackground(BLUE)
	// 	.setColorForeground(RED)
	// 	.setPosition(x, y+=21)
	// 	.setSize(w, 20)
	// 	.setRange(0.0, 0.1);

	cp5.addSlider("filter_threshold")
		.setLabel("")
		.setColorLabel(color(0))
		.setColorBackground(BLUE)
		.setColorForeground(RED)
		.setPosition(x, y+=30)
		.setSize(20, (height-y-10))
		.setRange(-10.0f, 100);

	graph = cp5.addChart("dataflow")
		.setPosition(x+=21, y)
		.setSize((width-x-10), (height-y-10))
		.setColorBackground(BLUE)
		.setColorForeground(RED)
		.setView(Chart.LINE);

	// -------------------------------------------------------------------------
	console = cp5.addConsole(
				cp5.addTextarea("txt")
					.setPosition(x+=180, y=10)
					.setSize((width-x-10), (height-y-10-graph.getHeight()-10))
					.setFont(createFont("", 10))
					.setLineHeight(14)
					.setColor(color(0))
					.setColorBackground(WHITE)
					.setColorForeground(RED));



	setLock(cp5.getController("thresholdBlockSize"), true);
	setLock(cp5.getController("thresholdConstant"), true);

	buttonColor = cp5.getController("contrast").getColor().getForeground();
	buttonBgColor = cp5.getController("contrast").getColor().getBackground();

	load();
}

public void toggleAdaptiveThreshold(boolean theFlag) {
	useAdaptiveThreshold = theFlag;
	if (useAdaptiveThreshold) {
		setLock(cp5.getController("threshold"), true);
		setLock(cp5.getController("thresholdBlockSize"), false);
		setLock(cp5.getController("thresholdConstant"), false);
	} else {
		setLock(cp5.getController("threshold"), false);
		setLock(cp5.getController("thresholdBlockSize"), true);
		setLock(cp5.getController("thresholdConstant"), true);
	}
}

public void setLock(Controller theController, boolean theValue) {
	theController.setLock(theValue);
	if (theValue) {
		theController.setColorBackground(color(150,150));
		theController.setColorForeground(color(100,100));
	} else {
		theController.setColorBackground(color(buttonBgColor));
		theController.setColorForeground(color(buttonColor));
	}
}

public void controlEvent(ControlEvent theEvent) {
	if(theEvent.isFrom(visibleSnapshot_toggle)) {
		visibleSnapshot = PApplet.parseInt(theEvent.getGroup().getValue());
	}
	else if(theEvent.isFrom("blobSizeThreshold")) {
		blob_size_min = PApplet.parseInt(theEvent.getController().getArrayValue(0));
		blob_size_max = PApplet.parseInt(theEvent.getController().getArrayValue(1));
	}
	else if(theEvent.isFrom("depth_range") && INPUT != null){
		INPUT.depthThreshold[0] = PApplet.parseInt(theEvent.getController().getArrayValue(0));
		INPUT.depthThreshold[1] = PApplet.parseInt(theEvent.getController().getArrayValue(1));
	}
}
  public void settings() {  size(1090, 500); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "--present", "--window-color=#050505", "--hide-stop", "sketch" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
