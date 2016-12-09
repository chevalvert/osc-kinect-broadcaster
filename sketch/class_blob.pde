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

		this.size = this.computeSize();
		this.p_size = this.size;
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
		return new PVector( r.x + r.width * 0.5, r.y + r.height * 0.5, 0);
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

