/* --------------------------------------------------------------------------
 * Based on Max Rheiner + Rodrigo Godo + 
 * This version came from Interactivas17 + MediaLab Prado
 * 2017/10/12
 * Non colonial action
 */

import SimpleOpenNI.*;
//import com.hamoid.*;
//VideoExport videoExport;

boolean recording = true;  //si quieres que grabe desde el principio en true, si vas a adjudicarle una tecla para que empiece a grabar, false


//////////////////////////////// SimpleOpenNI Users
SimpleOpenNI context;
float        zoomF =0.25f;
float        rotX = radians(180);  // by default rotate the hole scene 180deg around the x-axis, 
// the data from openni comes upside down
float        rotY = radians(180);
boolean      autoCalib=true;

PVector      bodyCenter = new PVector();
PVector      bodyDir = new PVector();
PVector      com = new PVector();                                   
PVector      com2d = new PVector();                                   
color[]       userClr = new color[] { 
  color(255, 0, 0), 
  color(0, 125, 125), 
  color(0, 0, 255), 
  color(255, 255, 0), 
  color(255, 0, 255), 
  color(0, 255, 255)
};



//////////////////////////////////// Letters in the body
char[] letters;
float[] bright;
char[] chars;
String letterOrder = "probando mensajes";
PFont font; 

/////////////////////////////////////Matrix FX

ArrayList<PVector> stars = new ArrayList<PVector>();
float h2;//=height/2
float w2;//=width/2
float d2;//=diagonal/2
int lowchar = 33;
int highchar = 126;
int columns;
int rows;
int[] place;
int charsize = 15;


int n;
float w; 
float h; 
int num_lines;



///////////////
PVector jointPosLeft = new PVector(0, 0, 0);
PVector jointPosRight = new PVector(0, 0, 0);  


void setup()
{
  size(displayWidth, displayHeight, P3D);
  // strange, get drawing error in the cameraFrustum if i use P3D, in opengl there is no problem

  ////////////////////////Kinect


  context = new SimpleOpenNI(this);
  if (context.isInit() == false)
  {
    println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
    exit();
    return;
  }

  // disable mirror
  context.setMirror(false);

  // enable depthMap generation 
  context.enableDepth();

  // enable skeleton generation for all joints
  context.enableUser();

  stroke(255, 255, 255);
  smooth();  
  perspective(radians(45), float(width)/float(height), 10, 150000);

  //////////////////////////////Letters in the body
  // for the 256 levels of brightness, distribute the letters across
  // the an array of 256 elements to use for the lookup

  font = loadFont("MatrixCode.vlw");
  letters = new char[256];
  for (int i = 0; i < 256; i++) {
    int index = int(map(i, 0, 256, 0, letterOrder.length()));
    letters[i] = letterOrder.charAt(index);
  }
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

  /*videoExport = new VideoExport(this, "matrixEffect.mp4");
   videoExport.setQuality(100, 128); //esto es la calidad de la imagen y del sonido
   videoExport.setFrameRate(24);
   videoExport.startMovie();*/

  ////////////////////////Matrix FX

  //  stroke(0,255,0);
  fill(0, 255, 0);
  strokeWeight(2);
  textSize(20);

  w2=width/2;
  h2= height/2;
  d2 = dist(0, 0, w2, h2);
  noStroke();
  columns = int(width/charsize);
  rows = int(height/charsize);
  place = new int[columns];

  fill(0);
  rect(0, 0, width, height);
}


void draw()
{
  fill(0, 50);
  rect(0, 0, width, height);
  // update the cam
  context.update();

  //background(0);

  lights();




  stroke(0, 255, 0);
  matrix(jointPosRight.x, jointPosRight.y);



  // set the scene pos
  translate(width/2, height/2, 0);
  rotateX(rotX);
  rotateY(rotY);
  scale(zoomF);


  int[]   depthMap = context.depthMap();
  int[]   userMap = context.userMap();
  int     steps = 8;  // to speed up the drawing, draw every third point
  int     index;
  PVector realWorldPoint;

  translate(0, 0, -1000);  // set the rotation center of the scene 1000 infront of the camera

  //get the position of the joints



  // draw the pointcloud
  beginShape(LINES);
  for (int y=0; y < context.depthHeight (); y+=steps)
  {
    for (int x=0; x < context.depthWidth (); x+=steps)
    {
      index = x + y * context.depthWidth();
      if (depthMap[index] > 0)
      { 
        // draw the projected point
        realWorldPoint = context.depthMapRealWorld()[index];
        if (userMap[index] == 0) {


          stroke(100);
        } else {


          //el que
          pintaLetr(userMap, index, 32, realWorldPoint);
        }
      }
    }
  } 
  endShape();


  int[] userList = context.getUsers();

  for (int i=0; i<userList.length; i++)
  {
    if (context.isTrackingSkeleton(userList[i])) {

      stroke(255, 255, 255);
      strokeWeight(1);

      //background(250);

      // esta funcion da la posicion de la articulacion x, del usuario x en la variable final "jointPosLeft"
      context.getJointPositionSkeleton(userList[i], SimpleOpenNI.SKEL_LEFT_HAND, jointPosLeft);
      context.getJointPositionSkeleton(userList[i], SimpleOpenNI.SKEL_RIGHT_HAND, jointPosRight);       

      pushMatrix();
      translate(jointPosLeft.x, jointPosLeft.y, jointPosLeft.z);
      sphere(50);
      popMatrix();
      pushMatrix();
      translate(jointPosRight.x, jointPosRight.y, jointPosRight.z);
      sphere(50);
      popMatrix();



      ellipse(jointPosLeft.x, jointPosLeft.y, 30, 30);
      ellipse(jointPosRight.x, jointPosRight.y, 30, 30);
    }
  }


  /*if (recording) {
   videoExport.saveFrame();
   }*/
}

/////////////////// uncoment for the final

//boolean sketchFullScreen() {
//  return true;
//}



///////////////////user functions
void onNewUser(SimpleOpenNI curContext, int userId)
{
  println("onNewUser - userId: " + userId);
  println("\tstart tracking skeleton");

  curContext.startTrackingSkeleton(userId);
}

void onLostUser(SimpleOpenNI curContext, int userId)
{
  println("onLostUser - userId: " + userId);
}

void onVisibleUser(SimpleOpenNI curContext, int userId)
{
  //println("onVisibleUser - userId: " + userId);
}

///////////////////letras

void pintaLetr(int[] _userMap, int _index, int letraS, PVector _realWorldPoint) {
  //
  //  stroke(userClr[ (_userMap[_index] - 1) % userClr.length ]);
  //  fill(userClr[ (_userMap[_index] - 1) % userClr.length ]);
  stroke(userClr[ int(random(userClr.length - 1))]);
  fill(userClr[ int(random(userClr.length - 1))]);

  textSize(letraS);
  text(letters[int(random(letters.length-1))], _realWorldPoint.x, _realWorldPoint.y, _realWorldPoint.z);
}

void pintaLetr(int letraS, PVector _realWorldPoint) {

  textSize(letraS);
  text(letters[int(random(letters.length-1))], _realWorldPoint.x, _realWorldPoint.y, _realWorldPoint.z);
}


///////////////////Matrix Function

void matrix(float xHnd, float yHnd) {

  if (true) {

    //fill(0, map(dist(xHnd, yHnd, w2, h2), 0, d2, 255, 5));
    //rect(0, 0, width, height);
    fill(0, 255, 0);

    for (int i = 0; i<20; i += 1) {   // star init
      stars.add(new PVector(random(width), random(height), random(1, 3)));
    }

    for (int i = 0; i<stars.size (); i+=2) {
      float x =stars.get(i).x;//local vars
      float y =stars.get(i).y;
      float d =stars.get(i).z;

      /* movement+"glitter"*/
      stars.set(i, new PVector(x-map(xHnd, 0, width, -0.05, 0.05)*(w2-x), y-map(yHnd, 0, height, -0.05, 0.05)*(h2-y), d + 0.2 - 0.6 * noise(x, y, frameCount)));

      if (d>3||d< -3) stars.set(i, new PVector(x, y, 1));
      if (x<0||x>width||y<0||y>height) stars.remove(i);
      if (stars.size()>9999) stars.remove(1);

      pintaLetr(int(d)*10, new PVector(x, y, d));

      //ellipse(x, y, d, d);//draw stars
    }

    //    int thechar;
    //    char c;
    //    fill(0, 0, 0, 11);
    //    rect(0, 0, width, height);
    //    fill(0, 255, 0);
    //    for (int i = 0; i < columns; i++) {
    //      thechar = int(random(lowchar, highchar))+1;
    //      if (random(1000)>900)
    //      {
    //        thechar = 32;
    //        c = char(thechar);
    //        fill(0, 255, 0);
    //        text(c, charsize*i, place[i]*charsize);
    //      } else {
    //        c = char(thechar);
    //        fill(0, 255, 0);
    //        text(c, charsize*i, place[i]*charsize);
    //        place[i]++;
    //        if (place[i]>rows) {
    //          place[i] = 0;
    //        }
    //      }
    //    }
  }
}



// -----------------------------------------------------------------
// Keyboard events

void keyPressed()
{
  switch(key)
  {
  case ' ':
    context.setMirror(!context.mirror());
    break;
  }

  switch(keyCode)
  {
  case LEFT:
    rotY += 0.1f;
    break;
  case RIGHT:
    // zoom out
    rotY -= 0.1f;
    break;
  case UP:
    if (keyEvent.isShiftDown())
      zoomF += 0.01f;
    else
      rotX += 0.1f;
    break;
  case DOWN:
    if (keyEvent.isShiftDown())
    {
      zoomF -= 0.01f;
      if (zoomF < 0.01)
        zoomF = 0.01;
    } else
      rotX -= 0.1f;
    break;
  }
}

/*void keyTyped() {
 if (key== 'r' || key == 'R') {
 recording = !recording;
 println("Recording is" + (recording ? "ON" : "OFF"));
 }
 if (key == 'q') {
 videoExport.endMovie();
 exit();
 }
 }*/





//void getBodyDirection(int userId, PVector centerPoint, PVector dir)
//{
//  PVector jointL = new PVector();
//  PVector jointH = new PVector();
//  PVector jointR = new PVector();
//  float  confidence;
//
//  // draw the joint position
//  confidence = context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, jointL);
//  confidence = context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_HEAD, jointH);
//  confidence = context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, jointR);
//
//  // take the neck as the center point
//  confidence = context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_NECK, centerPoint);
//
//  /*  // manually calc the centerPoint
//   PVector shoulderDist = PVector.sub(jointL,jointR);
//   centerPoint.set(PVector.mult(shoulderDist,.5));
//   centerPoint.add(jointR);
//   */
//
//  PVector up = PVector.sub(jointH, centerPoint);
//  PVector left = PVector.sub(jointR, centerPoint);
//
//  dir.set(up.cross(left));
//  dir.normalize();
//}

//void drawLimb(int userId, int jointType1, int jointType2)
//{
//  PVector jointPos1 = new PVector();
//  PVector jointPos2 = new PVector();
//  float  confidence;
//
//  // draw the joint position
//  confidence = context.getJointPositionSkeleton(userId, jointType1, jointPos1);
//  confidence = context.getJointPositionSkeleton(userId, jointType2, jointPos2);
//
//  stroke(255, 0, 0, confidence * 200 + 55);
//  line(jointPos1.x, jointPos1.y, jointPos1.z, 
//  jointPos2.x, jointPos2.y, jointPos2.z);
//
//  drawJointOrientation(userId, jointType1, jointPos1, 50);
//}
//
//void drawJointOrientation(int userId, int jointType, PVector pos, float length)
//{
//  // draw the joint orientation  
//  PMatrix3D  orientation = new PMatrix3D();
//  float confidence = context.getJointOrientationSkeleton(userId, jointType, orientation);
//  if (confidence < 0.001f) 
//    // nothing to draw, orientation data is useless
//    return;
//
//  pushMatrix();
//  translate(pos.x, pos.y, pos.z);
//
//  // set the local coordsys
//  applyMatrix(orientation);
//
//  // coordsys lines are 100mm long
//  // x - r
//  stroke(255, 0, 0, confidence * 200 + 55);
//  line(0, 0, 0, 
//  length, 0, 0);
//  // y - g
//  stroke(0, 255, 0, confidence * 200 + 55);
//  line(0, 0, 0, 
//  0, length, 0);
//  // z - b    
//  stroke(0, 0, 255, confidence * 200 + 55);
//  line(0, 0, 0, 
//  0, 0, length);
//  popMatrix();
//}
