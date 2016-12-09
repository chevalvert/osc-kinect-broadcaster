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