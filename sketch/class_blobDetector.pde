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
    contours = opencv.findContours(false, false);
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
  ArrayList<Contour> getBlobsFromContours(ArrayList<Contour> newContours) {
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