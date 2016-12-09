public ControlP5 cp5;
public RadioButton visibleSnapshot_toggle;
public Button kinect_up_button, kinect_down_button;
public Range blobsize_slider, depth_range;
public Println console;
public Textarea console_area;
public Chart graph;
public int buttonColor, buttonBgColor;

// -------------------------------------------------------------------------

void initControls(int x, int y) {
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
		.setLabel("") // label "contrast" is on the invert toggle ¯\_(ツ)_/¯
		.setColorLabel(color(0))
		.setColorBackground(BLUE)
		.setColorForeground(RED)
		.setPosition(x, y+=21)
		.setSize(w-21, 20)
		.setRange(0.0, 10.0);

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
		.setRange(-10.0, 100);

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

void toggleAdaptiveThreshold(boolean theFlag) {
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

void setLock(Controller theController, boolean theValue) {
	theController.setLock(theValue);
	if (theValue) {
		theController.setColorBackground(color(150,150));
		theController.setColorForeground(color(100,100));
	} else {
		theController.setColorBackground(color(buttonBgColor));
		theController.setColorForeground(color(buttonColor));
	}
}

void controlEvent(ControlEvent theEvent) {
	if(theEvent.isFrom(visibleSnapshot_toggle)) {
		visibleSnapshot = int(theEvent.getGroup().getValue());
	}
	else if(theEvent.isFrom("blobSizeThreshold")) {
		blob_size_min = int(theEvent.getController().getArrayValue(0));
		blob_size_max = int(theEvent.getController().getArrayValue(1));
	}
	else if(theEvent.isFrom("depth_range") && INPUT != null){
		INPUT.depthThreshold[0] = int(theEvent.getController().getArrayValue(0));
		INPUT.depthThreshold[1] = int(theEvent.getController().getArrayValue(1));
	}
}