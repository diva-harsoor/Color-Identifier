/**
 * ColorIdentifier: This program opens with asking the user for
 * an image, and then allowing the user to select a portion of 
 * the image (under 6400 pixels in area). Then, it uses density
 * based spatial clustering of applications with noise (DBSCAN)
 * to determine what the dominant colors of the image are, which
 * it then displays on the screen. The user may also adjust the
 * sensitivity of the clustering with a slider at the bottom of
 * the screen.
 *
 * Author: Diva Harsoor
 * Date: May 31, 2016
 * Class: COMP 500, Dr. Miles, Period 2
 *
 * Disclaimers: 
 *   Images in exImg are not mine, except for CardweavingPattern and
 *   ColorExperiments
 *   DBSCAN:
 *     https://www-users.cs.umn.edu/~kumar/dmbook/ch8.pdf
 *     http://www.cse.buffalo.edu/~jing/cse601/fa12/materials/clustering_density.pdf
 *     https://en.wikipedia.org/wiki/DBSCAN
 * Acknowledgements: 
 *   Thank you to Dr. Miles for his extra help and guidance
 *
 * Space for improvement (In the future, I'd like to):
 *   Make it so the Display and Slider do not obstruct the image
 *   Use an R*-tree to make the program able to handle images with greater areas
 */

PImage userImg;
PImage userBox;
Slider sensitivity;

//define userBox
private float x1;
private float y1;
private float x2;
private float y2;

/**
 * Does setup, including defining initial environment properties
 * and asking user for image
 */
void setup() {
  size(600, 600);
  colorMode(HSB, 360, 100, 100);
  if (userImg == null) {
    selectInput("Select an image", "imageSelected");
  }

  x1 = -1;
  y1 = -1;
  x2 = -1;
  y2 = -1;

  sensitivity = new Slider(.01, .24);
}

/**
 * Callback function to selectInput
 */
void imageSelected(File selection) {
  if (selection == null) {
    exit();
  } else {
    userImg = loadImage(selection.getAbsolutePath());
  }
}

/** 
 * Draws onto the screen (further commented in code)
 */
void draw() {
  background(0, 0, 0);
  noStroke();

  //Resizes userImg to fit the screen
  if (userImg != null) {
    image(userImg, 0, 0);
    if (userImg.width > userImg.height) {
      userImg.resize(width, 0);
    } else {
      userImg.resize(0, height);
    }
    image(userImg, 0, 0);
  }

  sensitivity.drawSlider();

  // Draws userBox according to user's actions
  stroke(0, 0, 0);
  fill(0, 0, 100, 75);
  if (x1 > -1 && x2 > -1) {
    if (abs((x1 - x2) * (y1 - y2)) <= 6400) {
      rect(min(x1, x2), min(y1, y2), abs(x1 - x2), abs(y1 - y2));
      userBox = userImg.get((int)min(x1, x2), (int)min(y1, y2), (int)abs(x1 - x2), (int)abs(y1 - y2));
    } else {
      rect(min(x1, x2), min(y1, y2), 80, 80);
      userBox = userImg.get((int)x1, (int)y1, 80, 80);
    }
  } else if (x1 > -1 && y1 > -1) {
    userBox = null;
    if (abs((x1 - mouseX) * (y1 - mouseY)) <= 6400) {
      rect(min(x1, mouseX), min(y1, mouseY), abs(x1 - mouseX), abs(y1 - mouseY));
    } else {
      rect(x1, y1, 80, 80);
    }
  }

  // Draws the Display onto the screen
  if (userBox != null) {
    CoordinatesList cL = new CoordinatesList(userBox);
    Clustering c = new Clustering(cL, 100, sensitivity.val); 
    new Display(c).drawDisplay();
  }
}

/**
 * Used to change userBox and sensitivity according to user input
 */
void mousePressed() {
  if (sensitivity.isOnSlider()) {
    sensitivity.changeVal(mouseX);
  } else {
    x2 = -1;
    y2 = -1;

    x1 = mouseX;
    y1 = mouseY;
  }
}

/**
 * Used to change userBox and sensitivity according to user input
 */
void mouseReleased() {
  if (sensitivity.isOnSlider()) {
    sensitivity.changeVal(mouseX);
  } else {
    x2 = mouseX;
    y2 = mouseY;
  }
}

/**
 * Takes Clustering and displays the average color
 * of each of its clusters
 */
public class Display {

  private color[] clusters;

  /**
   * Stores the average colors of a given Clustering's clusters 
   * in an array
   */
  public Display(Clustering c) {
    clusters = new color[c.clusters.size()];
    for (int i = 0; i < clusters.length; i++) {
      clusters[i] = c.clusters.get(i).avgColor;
    }
  }

  /**
   * Draws the colors onto the screen
   */
  public void drawDisplay() {
    stroke(0, 0, 0);  
    fill(0, 0, 100);
    rect(width/3, 7 * height/12, width/3, height/6);
    if (clusters.length >0) {
      float w = (width/3 - 40)/clusters.length;
      for (int i = 0; i < clusters.length; i++) {
        fill(clusters[i]);
        rect((width/3 + 20) + i * w, 7 * height/12 + 20, w, height/6 - 40);
      }
    }
  }
} 

/**
 * Represents color as a coordinate on the
 * HSB color cone
 */
public class HSBCoordinate {

  private float x, y, z;
  private color clr;
  private boolean classified;

  /**
   * Given a color, creates an HSB object
   */
  public HSBCoordinate (color rgb) {
    float h = hue(rgb); //tested
    float s = saturation(rgb);
    float b = brightness(rgb);

    x = (s/100) * (b/100) * cos(2 * PI * (h/360));
    y = (s/100) * (b/100) * sin(2 * PI * (h/360));
    z = b/100;

    clr = rgb;
    classified = false;
  }

  /**
   * Finds the Euclidean distance between this HSB object and
   * another on the HSB color cone
   */
  public float distance (HSBCoordinate other) {
    float dX = abs(this.x - other.x);
    float dY = abs(this.y - other.y);
    float dZ = abs(this.z - other.z);

    return sqrt(dX * dX + dY * dY + dZ * dZ);
  }
}

/**
 * A list of all the pixels in an image as HSBCoordinates
 */
public class CoordinatesList extends ArrayList<HSBCoordinate> {

  /** 
   * Given an image, is an ArrayList of the HSBCoordinate for each pixel
   */
  public CoordinatesList (PImage img) {
    img.loadPixels();
    for (color clr : img.pixels) {
      add(new HSBCoordinate(clr));
    }
  }
}

/**
 * A group of similar pixels turned HSBCoordinates in an image
 */
public class Cluster {
  int count;
  float allH;
  float allS;
  float allB;
  color avgColor;

  /**
   * Adds an HSBCoordinate by updating fields appropriately
   */
  public void add(HSBCoordinate hsb) {
    count++;
    allH += hue(hsb.clr);
    allS += saturation(hsb.clr);
    allB += brightness(hsb.clr);
    avgColor = color(allH/count, allS/count, allB/count);
  }
}

/** 
 * Finds and stores clusters for a given data set
 */
public class Clustering {
  private ArrayList<Cluster> clusters;
  private CoordinatesList dataSet;
  private int minPts;
  private float distance;

  /**
   * Given a CoordinatesList and sensitivity parameters,
   * finds the clusters
   */
  public Clustering (CoordinatesList cL, int mP, float d) {
    clusters = new ArrayList<Cluster>();
    dataSet = cL;
    minPts = mP;
    distance = d;
    DBSCAN();
  }

  /**
   * Creates clusters in a given data set according to sensitivity
   * parameters
   */
  private void DBSCAN() {
    for (HSBCoordinate c : dataSet) {
      if (c.classified == false) {
        c.classified = true;
        if (neighbors(c).size() >= minPts) {
          Cluster newCluster = new Cluster();
          clusters.add(newCluster);
          newCluster.add(c);
          fillClusters(c, clusters.size() - 1);
        }
      }
    }
  }

  /**
   * Fills clusters created in DBSCAN() with the appropriate
   * HSBCoordinates in CoordinatesList 
   */
  private void fillClusters(HSBCoordinate hsb, int j) {
    ArrayList<HSBCoordinate> neighboring = neighbors(hsb);
    for (int i = 0; i < neighboring.size(); i++) {
      if (neighboring.get(i).classified == false) {
        neighboring.get(i).classified = true;
        clusters.get(j).add(neighboring.get(i));
        if (neighbors(neighboring.get(i)).size() >= minPts) {
          neighboring.addAll(neighbors(neighboring.get(i)));
        }
      }
    }
  }

  /**
   * Given an HSBCoordinate, returns all the HSBCoordinates
   * within distance (on the HSB color cone)
   */
  private ArrayList<HSBCoordinate> neighbors(HSBCoordinate hsb) {
    ArrayList<HSBCoordinate> neighboring = new ArrayList<HSBCoordinate>();
    for (HSBCoordinate c : dataSet) {
      if (c.classified == false) {
        if (hsb.distance(c) <= distance) {
          neighboring.add(c);
        }
      }
    }
    return neighboring;
  }
}

/**
 * A Slider whose value corresponds to the stored
 * position of the scroller
 */
public class Slider {
  private float val;
  private float min;
  private float max;
  private float pos; //stored position of the scroller

  /**
   * Given a minimum and maximum value, creates a Slider
   */
  public Slider (float mn, float mx) {
    min = mn;
    max = mx;
    val = (min + max)/2;
    pos = width/2;
  }

  /**
   * Given the new position of the scroller, updates fields
   */
  public void changeVal(float p) {
    pos = width - p;
    val = min + (max - min) * pos/(width - 40);
  }

  /**
   * Draws Slider, changing color and position of scroller 
   * according to user input
   */
  public void drawSlider() {
    textSize(12);
    fill (200, 100, 50);
    text("generally less sensitive", 20, height - 25);
    text("generally more sensitive", width - 150, height - 25);
    fill(200, 50, 50);
    rect (0, height - 20, width, 20);
    fill(200, 100, 50);
    rect(20, height - 15, width - 40, 10);
    if (isOnSlider()) {
      fill(200, 100, 25);
      ellipse(mouseX, height - 10, 7.5, 7.5);
    } else {
      fill(200, 0, 50);
      ellipse(pos, height - 10, 7.5, 7.5);
    }
  }

  /**
   * Returns true if the mouse is onSlider, false if it is not
   */
  public boolean isOnSlider() {
    if (mouseX > 20 && mouseX < width - 20 && mouseY > height - 20 && mouseY < height) {
      return true;
    }
    return false;
  }
}