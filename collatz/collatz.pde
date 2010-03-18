import traer.physics.*;
import java.util.*;

//Constant
final float NODE_SIZE = 20;         //diameter of a node
final float EDGE_LENGTH = 10;       //string length
final float EDGE_STRENGTH = 0.05;   //string force
final float SPACER_STRENGTH = 1000; //repulsion force between node
final float SYSTEM_DAMP = 0.1;      //global physical damping

final int REST_STEP = 10;    //how many physical step (frame) between computation ?

final int MIN_COLLATZ = 1;   //computation starting point
final int MAX_COLLATZ = 1000; //compute collatz up to ... ?

final int PRECOMPUTE_COLLATZ = 0;

HashMap hm = new HashMap();  //store node number -> particle
HashMap mh = new HashMap();  //store particle object -> node number

//misc global stuff, do not touch.
ParticleSystem physics;
float scale = 1;
float centroidX = 0;
float centroidY = 0;
int restStep;

int collatz = 1;

//[5,1,9,7,0,3,4,9,7,2]

void setup() {
  size( 600, 600);   //feel free to change screen size
  frameRate(240);     //max framerate
  //smooth();        //antialiasing (useless at this scale)
  strokeWeight( 2 );
  ellipseMode( CENTER );       
  
  physics = new ParticleSystem( 1, SYSTEM_DAMP );
  physics.setIntegrator( ParticleSystem.MODIFIED_EULER );
  physics.setDrag( 0.2 );
  
  textFont( loadFont( "LucidaSans-14.vlw" ) );
  initialize();
}


void draw() {
  
  if(PRECOMPUTE_COLLATZ == 0) { 
    physics.tick(); 
    if ( physics.numberOfParticles() > 1 ) updateCentroid();
  }

  fill(0,50); 
  noStroke(); 
  rect(0,0,width,height); 
  fill(128);
  text( "" + physics.numberOfParticles() + " PARTICLES\n" + (int)frameRate + " FPS", 10, 20 );
  

  if(restStep % REST_STEP == 0) {
    if(collatz < MAX_COLLATZ) { 
      calcCollatz(collatz); 
      collatz++; 
    } else {
      if(PRECOMPUTE_COLLATZ == 1) {
        physics.tick(); 
        if ( physics.numberOfParticles() > 1 ) updateCentroid();
        translate( width/2 , height/2 );
        scale( scale );
        translate( -centroidX, -centroidY );  
        drawNetwork();
      }  
    }
  }
  
  restStep++;
  
  if(PRECOMPUTE_COLLATZ == 0) {
    translate( width/2 , height/2 );
    scale( scale );
    translate( -centroidX, -centroidY );  
    drawNetwork();
  }  
}

void calcCollatz(int c) {
  Particle cPar, nextPar;
  int nextVal;
  if(c==1) return;
    
  if (c%2 == 0) {
    nextVal = c/2;
  } else {
    nextVal = 3*c +1;    
  }
  cPar = (Particle)hm.get(c);
  nextPar = (Particle)hm.get(nextVal);
  
  if(nextPar == null) {
    nextPar = createNode(nextVal);
  } else {
    if(cPar == null) {
      cPar = createNode(c);
      linkNodeTo(c,(Particle)hm.get(nextVal) );
    } else {
      linkNodeTo(c,(Particle)hm.get(nextVal));
    }
    return;
  }
    
  
  if(cPar == null) {
    cPar = createNode(c);
    linkNodeTo(c,(Particle)hm.get(nextVal) );
  } else {
    linkNodeTo(c,(Particle)hm.get(nextVal));
  }

  if (c%2 == 0) {
    calcCollatz(c/2);
  } else {
    calcCollatz(3*c +1);    
  }
  

} 
  

void drawNetwork()
{      

  // draw edges 
  stroke( 0 );
  beginShape( LINES );
  for ( int i = 0; i < physics.numberOfSprings(); ++i )
  {
    Spring e = physics.getSpring( i );
    stroke(100);
    strokeWeight(2);
    Particle a = e.getOneEnd();
    Particle b = e.getTheOtherEnd();
    vertex( a.position().x(), a.position().y() );
    vertex( b.position().x(), b.position().y() );
  }
  endShape();
  // draw vertices
  fill( 160 );
  noStroke();
  for ( int i = 0; i < physics.numberOfParticles(); ++i )
  {
    Particle v = physics.getParticle( i );
    int a = (Integer)mh.get(v);
    if(i == 0) { 
      fill(255,255,255);
      //v.makeFixed();
    } else if(a % 2 == 0) {
      fill( 255, i%255, 0 );
    } else {
      fill( 0, i%255, 255 );
    }
    ellipse( v.position().x(), v.position().y(), NODE_SIZE , NODE_SIZE  );
    if(PRECOMPUTE_COLLATZ == 0) text( mh.get(v).toString(), v.position().x() + NODE_SIZE/2, v.position().y() + NODE_SIZE/2);
  }

}


void updateCentroid()
{
  float 
    xMax = Float.NEGATIVE_INFINITY, 
    xMin = Float.POSITIVE_INFINITY, 
    yMin = Float.POSITIVE_INFINITY, 
    yMax = Float.NEGATIVE_INFINITY;

  for ( int i = 0; i < physics.numberOfParticles(); ++i )
  {
    Particle p = physics.getParticle( i );
    xMax = max( xMax, p.position().x() );
    xMin = min( xMin, p.position().x() );
    yMin = min( yMin, p.position().y() );
    yMax = max( yMax, p.position().y() );
  }
  float deltaX = xMax-xMin;
  float deltaY = yMax-yMin;
  
  centroidX = xMin + 0.5*deltaX;
  centroidY = yMin +0.5*deltaY;
  
  if ( deltaY > deltaX )
    scale = height/(deltaY+50);
  else
    scale = width/(deltaX+50);
}

void addSpacersToNode( Particle p, Particle r )
{
  for ( int i = 0; i < physics.numberOfParticles(); ++i )
  {
    Particle q = physics.getParticle( i );
    if ( p != q && p != r )
      physics.makeAttraction( p, q, -SPACER_STRENGTH, 20 );
  }
}

void makeEdgeBetween( Particle a, Particle b )
{
  physics.makeSpring( a, b, EDGE_STRENGTH, EDGE_STRENGTH, EDGE_LENGTH );
}

void initialize()
{
  physics.clear();
  //physics.makeParticle();
}

Particle createNode(int c) {
  Particle p = physics.makeParticle();
  hm.put(c, p );
  mh.put(p,c);
  p.position().set(centroidX+ random( -100, 100 ), centroidY + random( -100, 100 ), 0 );
  return p;
}

void linkNodeTo(int c, Particle p) {
  Particle q = (Particle)hm.get(c);
  addSpacersToNode( p, q );
  makeEdgeBetween( p, q );
  q.position().set( p.position().x() + random( -1, 1 ), p.position().y() + random( -1, 1 ), 0 );
}

