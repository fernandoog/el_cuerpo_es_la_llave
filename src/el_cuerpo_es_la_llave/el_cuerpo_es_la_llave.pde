/* --------------------------------------------------------------------------
 * Based on Max Rheiner + Rodrigo Godo + Interactivas17 + MediaLab Prado
 * This version came from 
 * 2020/12/16
 */

import SimpleOpenNI.*;
import processing.serial.*;
import java.util.Iterator;

// MultiScreen
int screenNumber = 1;

////Mindwave
String portName ="COM10";
eegPort eeg;
Serial serialPort;
boolean sensor = false;
boolean camera = false;

/// SimpleOpenNI
SimpleOpenNI context;
float        zoomF =0.25f;

// Colores cuerpo
color[]       userClr = new color[] { 
  color(255, 0, 0), 
  color(0, 125, 125), 
  color(0, 0, 255), 
  color(255, 255, 0), 
  color(255, 0, 255), 
  color(0, 255, 255)
};

//Letters
String letterOrder = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
char[] letters;
float[] bright;
char[] chars;
PFont font; 

//Matrix
ArrayList<PVector> stars = new ArrayList<PVector>();
float h2;
float w2;
float d2;
int columns;
int rows;
int[] place;
int charsize = 15;
int   steps = 10;  // to speed up the drawing, draw every third point

//Body
boolean bodyColor = true;
PVector jointPosLeft = new PVector(0, 0, 0);
PVector jointPosRight = new PVector(0, 0, 0);  


void setup()
{
  fullScreen(screenNumber);
  background(0);

  //Mindwave
  try {
    serialPort = new Serial(this, portName, 115200);
    eeg = new eegPort(this, serialPort);
    delay(500);
    eeg.refresh();
    sensor = true;
  }
  catch(RuntimeException e) {
    println("Error conectando a midwave en puerto serie:" +portName );
  }

  //Kinect
  context = new SimpleOpenNI(this);
  // disable mirror
  context.setMirror(true);
  // enable depthMap generation 
  context.enableDepth();
  // enable skeleton generation for all joints
  context.enableUser();

  //Matrix
  font = loadFont("MatrixCode.vlw");
  letters = new char[256];
  for (int i = 0; i < 256; i++) {
    int index = int(map(i, 0, 256, 0, letterOrder.length()));
    letters[i] = letterOrder.charAt(index);
  }
  w2=width/2;
  h2= height/2;
  d2 = dist(0, 0, w2, h2);
  noStroke();
  columns = int(width/charsize);
  rows = int(height/charsize);
  place = new int[columns];
  fill(0);
  rect(0, 0, width, height);

  // current characters for each position in the video
  int count = 0;
  chars = new char[count];
  count++;

  // current brightness for each point
  bright = new float[count];
  for (int i = 0; i < count; i++) {
    // set each brightness at the midpoint to start
    bright[i] = 128;
  }
}


void draw()
{
  drawMatrix();
  drawBody();
  drawHands();
  drawSensor();
}

// Draw Matrix
void drawMatrix() {
  fill(0, 50);
  rect(0, 0, width, height);
  context.update();
  stroke(0, 255, 0);
  fill(0, 255, 0);
  for (int i = 0; i<20; i += 1) {   // star init
    stars.add(new PVector(random(width), random(height), random(1, 3)));
  }

  for (int i = 0; i<stars.size (); i+=2) {
    float x =stars.get(i).x;//local vars
    float y =stars.get(i).y;
    float d =stars.get(i).z;
    stars.set(i, new PVector(x-map(jointPosRight.x, 0, width, -0.05, 0.05)*(w2-x), y-map(jointPosRight.y, 0, height, -0.05, 0.05)*(h2-y), d + 0.2 - 0.6 * noise(x, y, frameCount)));
    if (d>3||d< -3) stars.set(i, new PVector(x, y, 1));
    if (x<0||x>width||y<0||y>height) stars.remove(i);
    if (stars.size()>9999) stars.remove(1);
    text(letters[int(random(letters.length-1))], x, y, z);
  }
}

// Draw Body
void drawBody() {
  int[]   depthMap = context.depthMap();
  int[]   userMap = context.userMap();
  int     index;
  PVector realWorldPoint;
  // set the rotation center of the scene 1000 infront of the camera

  // draw the pointcloud
   if (bodyColor) {
    stroke(userClr[ int(random(userClr.length - 1))]);
    fill(userClr[ int(random(userClr.length - 1))]);
  }
  

  for (int y=0; y < context.depthHeight (); y+=steps)
  {
    for (int x=0; x < context.depthWidth (); x+=steps)
    {
      index = x + y * context.depthWidth();
      // draw the projected point
      realWorldPoint = context.depthMapRealWorld()[index];
      if (userMap[index] == 0) {
        stroke(100);
      } else {
        text(letters[int(random(letters.length-1))], realWorldPoint.x, realWorldPoint.y, realWorldPoint.z);
      }
    }
  }
}

// Draw Hands
void drawHands() {
  int[] userList = context.getUsers();
  for (int i=0; i<userList.length; i++)
  {
    if (context.isTrackingSkeleton(userList[i])) {
      context.getJointPositionSkeleton(userList[i], SimpleOpenNI.SKEL_LEFT_HAND, jointPosLeft);
      context.getJointPositionSkeleton(userList[i], SimpleOpenNI.SKEL_RIGHT_HAND, jointPosRight);       
      ellipse(jointPosLeft.x, jointPosLeft.y, 30, 30);
      ellipse(jointPosRight.x, jointPosRight.y, 30, 30);
    }
  }
}

//Draw Sensor
void drawSensor() {
  if (sensor) {
    // Draw signal
    int lastEventInterval = millis() - eeg.lastEvent;
    if (eeg.poorSignal < 50 && lastEventInterval < 500) {
      // good signal
      ellipse(10, 10, 10, 10);
    } else {
      // bad signal
      ellipse(10, 10, 10, 10);
    }

    // Draw attention
    ellipse(400, 90, eeg.attention, eeg.attention);

    // Draw meditation
    ellipse(600, 90, eeg.meditation, eeg.meditation);

    // Chart vector values
    // first get maximum value
    int maxValue = 0;
    Iterator<eegPort.vectorObs> iterator;
    iterator = eeg.vectorBuffer.iterator();
    int vectorCount = eeg.vectorBuffer.size();

    int skip = 0;
    if (vectorCount > 200) {
      skip = vectorCount - 200;
    }

    int i = -1;

    while (iterator.hasNext()) {
      eegPort.vectorObs vobs = iterator.next();
      if (++i < skip) {
        continue;
      }

      if (vobs.vectorValue > maxValue) {
        maxValue = vobs.vectorValue;
      }
    }

    iterator = eeg.vectorBuffer.iterator();

    // we are interested in the last 400 observations

    i = -1;
    int j = 0;
    int prevValue = 0;
    int x = 0, y = 0;
    int prevX = 0, prevY = 0;

    stroke(0);

    // we are drawing between 0 and 800 in width, and between 400 and 600 in height
    while (iterator.hasNext()) {
      eegPort.vectorObs vobs = iterator.next();
      if (++i < skip) {
        continue;
      }

      x = j*4;
      y = (int)(580 - 200.0*vobs.vectorValue/maxValue);
      if (j > 0) {
        line(prevX, prevY, x, y);
      }

      prevValue = vobs.vectorValue;
      prevX = x;
      prevY = y;
      j++;
    }

    // chart attention
    int attentionCount = eeg.attentionBuffer.size();

    skip = 0;
    if (attentionCount > 200) {
      skip = attentionCount - 200;
    }

    Iterator<Integer> attentionIterator = eeg.attentionBuffer.iterator();

    // we are interested in the last 200 observations

    i = -1;
    j = 0;
    prevValue = 0;
    x = 0; 
    y = 0;
    prevX = 0; 
    prevY = 0;

    stroke(204, 102, 0);

    // we are drawing between 0 and 800 in width, and between 400 and 600 in height
    while (attentionIterator.hasNext()) {
      int attention = attentionIterator.next();
      if (++i < skip) {
        continue;
      }

      x = j*4;
      y = (int)(580 - 200.0*attention/255);
      if (j > 0) {
        line(prevX, prevY, x, y);
      }

      prevValue = attention;
      prevX = x;
      prevY = y;
      j++;
    }

    // chart meditation
    int meditationCount = eeg.meditationBuffer.size();

    skip = 0;
    if (meditationCount > 200) {
      skip = meditationCount - 200;
    }

    Iterator<Integer> meditationIterator = eeg.meditationBuffer.iterator();

    // we are interested in the last 200 observations

    i = -1;
    j = 0;
    prevValue = 0;
    x = 0; 
    y = 0;
    prevX = 0; 
    prevY = 0;

    stroke(108, 102, 240);

    // we are drawing between 0 and 800 in width, and between 400 and 600 in height
    while (meditationIterator.hasNext()) {
      int meditation = meditationIterator.next();
      if (++i < skip) {
        continue;
      }

      x = j*4;
      y = (int)(580 - 200.0*meditation/255);
      if (j > 0) {
        line(prevX, prevY, x, y);
      }

      prevValue = meditation;
      prevX = x;
      prevY = y;
      j++;
    }
  }
}

// Serial event
void serialEvent(Serial p) {
  while (p.available() > 0) {
    int inByte = p.read();
    eeg.serialByte(inByte);
  }
}
