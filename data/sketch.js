var s = function( sketch ) {

  var x = 100; 
  var y = 100;

  sketch.setup = function() {
    sketch.createCanvas(800, 800);
  };

  sketch.draw = function() {
    sketch.colorMode(sketch.HSB, 100);
    sketch.background(sketch.millis() / 100 % 100, 100, 100);
    sketch.noFill();
    sketch.stroke(100, 0, 100);
    sketch.strokeWeight(4);
    sketch.rectMode(sketch.CENTER);
    var w = sketch.map(Math.sin(sketch.millis() * 0.001), -1, 1, 0, 200);
    sketch.rect(sketch.mouseX, sketch.mouseY, w, 100);
    sketch.rectMode(sketch.CORNER);
    var h = sketch.map(x++ % 100, 0, 100, -sketch.height/2, 0);
    sketch.rect(sketch.width/2 - 50, sketch.height, 100, h);
  };

  sketch.keyPressed = function(event) {
    console.log(event);
  };

  sketch.keyReleased = function(event) {
    console.log(event);
  };

  sketch.mousePressed = function(event) {
    console.log(event);
  };
};

var myp5 = new p5(s);
