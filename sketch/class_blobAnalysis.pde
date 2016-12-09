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