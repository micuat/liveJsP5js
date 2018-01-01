import javax.script.ScriptEngineManager;
import javax.script.ScriptEngine;
import javax.script.ScriptContext;
import javax.script.ScriptException;
import javax.script.Invocable;

import java.lang.NoSuchMethodException;
import java.lang.reflect.*;

import java.util.ArrayList;
import java.util.List;

import java.io.IOException;
import java.io.File;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.charset.StandardCharsets;
import java.util.Scanner;
import processing.awt.PSurfaceAWT;

import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;

private static ScriptEngineManager engineManager;
private static ScriptEngine nashorn;

public static String VERSION = "0.1";

private static ArrayList<String> scriptPaths = new ArrayList<String>();
private static ArrayList<Long> prevModified = new ArrayList<Long>();

private static boolean first = true;

PSurfaceAWT.SmoothCanvas smoothCanvas;

float frameRate() {
  return frameRate;
}

void setup() {
  boolean projector = false;
  //size(1920, 1080, P3D);
  //size(2736, 1824, P3D);
  size(800, 800, P3D);
  if (!projector) {
  } else {
    PSurfaceAWT awtSurface = (PSurfaceAWT)surface;
    smoothCanvas = (PSurfaceAWT.SmoothCanvas)awtSurface.getNative();
    smoothCanvas.getFrame().setSize((int)(1280*1.75), (int)(1024*1.75));
    awtSurface.setSize((int)(1280*1.75), (int)(1024*1.75));
    smoothCanvas.getFrame().setAlwaysOnTop(true);
    smoothCanvas.getFrame().removeNotify();
    smoothCanvas.getFrame().setUndecorated(true);
    smoothCanvas.getFrame().setLocation(+(int)(2736*1.75), 0);
    smoothCanvas.getFrame().addNotify();
  }
  frameRate(60);
  smooth();
  noStroke();

  String path = dataPath("");

  println("Listing all filenames in a directory: ");
  String[] filenames = listFileNames(path);
  printArray(filenames);

  println("\nListing info about all files in a directory: ");
  File[] files = listFiles(path);
  for (File f : files) {
    String extension = "";

    int i = f.getName().lastIndexOf('.');
    if (i > 0) {
      extension = f.getName().substring(i+1);

      if (extension.equals("js")) {
        scriptPaths.add(dataPath(f.getName()));
      }
    }
  }

  scriptPaths.clear();
  scriptPaths.add(dataPath("script.js"));
  for (int i = 0; i < scriptPaths.size(); i++) {
    prevModified.add(0l);
    encoded.add(null);
  }

  initNashorn();

  oscP5 = new OscP5(this, 7000);
}

void initNashorn() {
  engineManager = new ScriptEngineManager();
  nashorn = engineManager.getEngineByName("nashorn");

  try {
    // init placehoders
    nashorn.eval("var pApplet = {}; var globalSketch = {};");
    Object global = nashorn.eval("this.pApplet");
    Object jsObject = nashorn.eval("Object");
    // calling Object.bindProperties(global, this);
    // which will "bind" properties of the PApplet object
    ((Invocable)nashorn).invokeMethod(jsObject, "bindProperties", global, (PApplet)this);

    // define "define"
    nashorn.eval("function define(varname, val){if(typeof this[varname] == 'undefined')this[varname] = val;}");

    //nashorn.eval("load(dataPath('jvm-npm.js'))");

    // console.log is print
    nashorn.eval("var console = {}; console.log = print;");

    nashorn.eval("var alternateSketch = new function(){};");

    // PConstants
    nashorn.eval("var PConstantsFields = Packages.processing.core.PConstants.class.getFields();");
    nashorn.eval("for(var i = 0; i < PConstantsFields.length; i++) {alternateSketch[PConstantsFields[i].getName()] = PConstantsFields[i].get({})}");

    // static methods
    nashorn.eval("var PAppletFields = pApplet.class.getMethods();");
    nashorn.eval(
      "for(var i = 0; i < PAppletFields.length; i++) {" +
      "var found = false;" +
      "  for(var prop in pApplet) {" +
      "    if(prop == PAppletFields[i].getName() ) found = true;" +
      "  }" +
      "  if(!found){"+
      "    alternateSketch[PAppletFields[i].getName()] = PAppletFields[i];" +
      "    eval('alternateSketch[PAppletFields[i].getName()] = function() {" +
      "      if(arguments.length == 0) return Packages.processing.core.PApplet.'+PAppletFields[i].getName()+'();" +
      "      if(arguments.length == 1) return Packages.processing.core.PApplet.'+PAppletFields[i].getName()+'(arguments[0]);" +
      "      if(arguments.length == 2) return Packages.processing.core.PApplet.'+PAppletFields[i].getName()+'(arguments[0], arguments[1]);" +
      "      if(arguments.length == 3) return Packages.processing.core.PApplet.'+PAppletFields[i].getName()+'(arguments[0], arguments[1], arguments[2]);" +
      "      if(arguments.length == 4) return Packages.processing.core.PApplet.'+PAppletFields[i].getName()+'(arguments[0], arguments[1], arguments[2], arguments[3]);" +
      "      if(arguments.length == 5) return Packages.processing.core.PApplet.'+PAppletFields[i].getName()+'(arguments[0], arguments[1], arguments[2], arguments[3], arguments[4]);" +
      "    }')" +
      "  }" +
      "}");

    // overwrite random
    nashorn.eval("alternateSketch.random = function() {" +
      "  if(arguments.length == 1) return Math.random() * arguments[0];" +
      "  if(arguments.length == 2) return sketch.map(Math.random(), 0, 1, arguments[0], arguments[1]);" +
      "}");

    // dummy createCanvas - should set size?
    nashorn.eval("alternateSketch.createCanvas = function(w, h, mode) {}");
    
    // utility
    nashorn.eval("this.isReservedFunction = function (str) {" +
      "  var isArgument_ = function (element) { return str === element; };" +
      "  return ['setup', 'draw', 'keyPressed', 'keyReleased', 'keyTyped', 'mouseClicked', 'mouseDragged', 'mouseMoved', 'mousePressed', 'mouseReleased', 'mouseWheel'].some(isArgument_);" +
      "}");

    // p5js entry point
    nashorn.eval("var p5 = function(sketch) {sketch(alternateSketch); globalSketch = alternateSketch;}");
  }
  catch (Exception e) {
    e.printStackTrace();
  }
}

void draw() {
  ArrayList<String> jsCodes = new ArrayList<String>();
  try {
    for (int i = 0; i < scriptPaths.size(); i++) {
      jsCodes.add(readFile(scriptPaths.get(i), i));
    }
  }
  catch (IOException e) {
    e.printStackTrace();
  }
  stroke(255);
  background(0);

  try {
    nashorn.eval("for(var prop in pApplet) {if(!this.isReservedFunction(prop)) {alternateSketch[prop] = pApplet[prop]}}");
    nashorn.eval("alternateSketch.draw();");
  }
  catch (ScriptException e) {
    e.printStackTrace();
  }
}

private static ArrayList<byte[]> encoded = new ArrayList<byte[]>();
public static String readFile(String path, int count) throws IOException {
  long lastModified = Files.getLastModifiedTime(Paths.get(path)).toMillis();
  if (prevModified.get(count) < lastModified || encoded.get(count) == null) {
    encoded.set(count, Files.readAllBytes(Paths.get(path)));
    println("updated at " + lastModified);
    prevModified.set(count, lastModified);
    first = true;

    try {
      nashorn.eval("for(var prop in pApplet) {if(!this.isReservedFunction(prop)) {alternateSketch[prop] = pApplet[prop]}}");
      nashorn.eval(new String(encoded.get(count), StandardCharsets.UTF_8));
      nashorn.eval("alternateSketch.setup();");
      print("script loaded in java");
    }
    catch (ScriptException e) {
      e.printStackTrace();
    }
  }
  return new String(encoded.get(count), StandardCharsets.UTF_8);
}