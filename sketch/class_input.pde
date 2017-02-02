public class Input {

	public boolean SMOOTH_FRAME = false;

	private PApplet parent;

	private Kinect kinect;
  private int[] rawDepth;

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

		this.rawDepth = this.kinect.getRawDepth();
		Rectangle clip = this.getAbsoluteClip();

		for (int x = constrain(clip.x, 0, this.kinect.width); x < constrain(clip.width, x, this.kinect.width); x++) {
			for (int y = constrain(clip.y, 0, this.kinect.height); y < constrain(clip.height, y, this.kinect.height); y++) {
				int index = x + y*this.kinect.width;

				if (this.rawDepth[index] >= this.depthThreshold[0] && this.rawDepth[index] <= this.depthThreshold[1]) {
					if (this.SMOOTH_FRAME) {
						this.img.pixels[index] = lerpColor(this.pimg.pixels[index], this.kinect.getDepthImage().pixels[index], .5);
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

   public float getAvgZ(Rectangle r) {
    if (this.isKinect && this.rawDepth != null && this.rawDepth.length > 0) {
      int count = 0;
      float sum = 0;
      for (int x = r.x; x < r.x + r.width; x++) {
        for (int y = r.y; y < r.y + r.height; y++) {
          int index = x + y * this.kinect.width;
          sum += this.rawDepth[index];
          count++;
        }
      }
      return sum / count;
    } else return -1;
  }

  public float getMinZ(Rectangle r) {
    if (this.isKinect && this.rawDepth != null && this.rawDepth.length > 0) {
      float record = this.depthThreshold[1];
      for (int x = r.x; x < r.x + r.width; x++) {
        for (int y = r.y; y < r.y + r.height; y++) {
          int index = x + y * this.kinect.width;
          float z = this.rawDepth[index];
          if (z >= this.depthThreshold[0] && z <= this.depthThreshold[1]) {
            if (z < record) record = z;
          }
        }
      }
      return norm(record, this.depthThreshold[0], this.depthThreshold[1]);
    } else return -1;
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