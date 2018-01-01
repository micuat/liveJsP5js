liveJSP5js
========

Naoto Hieda (2018)

liveJSP5js is a Processing project that is inspired by [ProcessingLiveJS](https://github.com/procsynth/ProcessingLiveJS) to do live coding with JavaScript.

What it does
--------

The program loads `data/sketch.js` which has to be written in [p5.js instance mode](https://github.com/processing/p5.js/wiki/Global-and-instance-mode).
The program does not use p5.js. Instead, it binds Processing methods and variables to `sketch` object in Nashorn JavaScript engine. This is possible because Processing and p5.js shares most of the methods and variable names. Unlike p5.js, every time you edit the sketch, the updated `setup()` will be called once and then the updated `draw()` will be called every frame.

Using Processing Plugins
--------

You can import a library in Processing sketch and call it from JavaScript by adding `Packages` prefix, for example:

    Packages.geomerative.RG.getText("text", "font.ttf", 300, sketch.LEFT);

Limitations
--------

Since the p5.js sketch will be interpreted in Java/Nashorn not a browser, HTML DOM cannot be used. There are many things I haven't tested so please report an issue or submit a pull request if you find any problems.
