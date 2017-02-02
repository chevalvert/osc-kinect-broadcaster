import oscP5.*;
import netP5.*;

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

    message.add(blob.id);
    message.add(int(blob.position.x));
    message.add(int(blob.position.y));
    message.add(blob.position.z);
    message.add(int(blob.size.x));
    message.add(int(blob.size.y));

    bundle.add(message);
    bundle.setTimetag(bundle.now() + 10000);
    this.oscP5.send(bundle, this.address);
  }

}