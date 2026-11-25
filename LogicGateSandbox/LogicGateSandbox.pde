//CURRENT VERSION v1.2
//Hours Worked On: 5.5 hours, 3.5 hours, 3 hours, 8 hours, 4.5 hours, 5.5 hours, 10 hours, 4 hours, 4.5 hours
//TOTAL: 48.5 hours

PFont font;

void setup() {
  size(1260, 840, P2D);
  windowResizable(true);
  pixelDensity(displayDensity());
  windowMove( (displayWidth - width)/2, (displayHeight - height)/2);
  windowTitle("Logic Gate Sandbox");
  frameRate(60);
  smooth(8);

  font = createFont("SansSerif", 50, true);
  textFont(font);
  menuHeight = height-85;
  
  initializeGateMenu();
  initializeTopMenu();
  maxCameraTravelDistance = width*2;

  optimizer();
  setupAll();

  println("========================= Sketch Started... =========================\n");
}

void optimizer() {
  hint(DISABLE_DEPTH_TEST);
  hint(DISABLE_DEPTH_MASK);
  hint(DISABLE_DEPTH_SORT);
  hint(DISABLE_STROKE_PERSPECTIVE);

  hint(DISABLE_OPENGL_ERRORS);
  hint(DISABLE_TEXTURE_MIPMAPS);
}




void setupAll() {
  //for (int i = 0; i < 3; i++) {
  //  NotGate ng = new NotGate(width/3+i*200, height/3 - 200);
  //  allLogicGates.add(ng);
  //  ng.calculateOutput();
  //}

  //for (int i = 0; i < 3; i++) {
  //  AndGate ag = new AndGate(width/3+i*200, height/3 - 100);
  //  allLogicGates.add(ag);
  //  ag.calculateOutput();
  //}

  //for (int i = 0; i < 3; i++) {
  //  OrGate og = new OrGate(width/3+i*200, height/3);
  //  allLogicGates.add(og);
  //  og.calculateOutput();
  //}

  //for (int i = 0; i < 3; i++) {
  //  XorGate xg = new XorGate(width/3+i*200, height/3 + 100);
  //  allLogicGates.add(xg);
  //  xg.calculateOutput();
  //}

  //for (int i = 0; i < 3; i++) {
  //  BufferGate bg = new BufferGate(width/3+i*200, height/3 + 200);
  //  allLogicGates.add(bg);
  //  bg.calculateOutput();
  //}

  //for (int i = 0; i < 3; i++) {
  //  Lamp l = new Lamp(width/3+i*200, height/3 + 300);
  //  allLogicGates.add(l);
  //  l.calculateOutput();
  //}

  //for (int i = 0; i < 3; i++) {
  //  Button b = new Button(width/3+i*200, height/3 + 400);
  //  allLogicGates.add(b);
  //  b.calculateOutput();
  //}

  //for (int i = 0; i < 3; i++) {
  //  Clock c = new Clock(width/3+i*200+50, height/3 + 500);
  //  allLogicGates.add(c);
  //  c.calculateOutput();
  //}


  //SRCircuit sr = new SRCircuit(width/3, height/3 + 500);
  //allLogicGates.add(sr);
  //sr.calculateOutput();

  //TDFlipFlop dt = new TDFlipFlop(width/3+200, height/3 + 500);
  //allLogicGates.add(dt);
  //dt.calculateOutput();

  //JKFlipFlop jk = new JKFlipFlop(width/3+400, height/3 + 500);
  //allLogicGates.add(jk);
  //jk.calculateOutput();
}





void draw() {
  background(0);

  runSaveAndLoad();
  mainTickLoop();

  //---------- DRAW EVERYTHING CAMERA ----------
  cameraSequencer();

  //---------- DRAW EVERYTHING LOGIC ----------
  //MOVE EVERYTHING INTO PLACE
  for (LogicGate logicGate : allLogicGates) logicGate.updatePosistions();

  //DRAW ALL CONNECTIONS
  for (LogicGate logicGate : allLogicGates) for (Connection con : logicGate.getOutputConnections()) con.draw();

  //DRAW ALL LOGIC GATES & IO DOTS
  for (LogicGate logicGate : allLogicGates) logicGate.draw();

  //---------- DRAW UI ----------
  checkWindowResize();
  moveGroup();  //GROUP SELECETION (WHITE BORDER)
  uiSequencer();
  drawSelectionBox();  //GROUP SELECETION (WHITE BORDER)
}







//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Main Game Loop ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

boolean pauseTickLoop = false, doNextTick = false, doNextHalfTick = false;
int tickDelayMs = 50, lastTickTime = 0;


//================================================== Tick Sequencer ==================================================


boolean doneTickFirstHalf = false;

void mainTickLoop() {
  //IF PAUSED, ONLY STEP WHEN TOLD
  if (pauseTickLoop) {
    //FULL STEP
    if (doNextTick) {
      tick();
      doneTickFirstHalf = false;  //A full tick finishes the cycle, so the next half tick starts fresh
      doNextTick = false;
    }

    //HALF STEP
    if (doNextHalfTick) {
      halfTick();
      doNextHalfTick = false;
    }

    //THEN DO NOT DO AUTOMATIC LOOP
    return;
  }

  if (millis() - lastTickTime >= tickDelayMs) {
    tick();
    lastTickTime = millis();
  }
}


void tick() {
  cleanUpBoard();

  //PHASE 1: EVERY GATE FIGURES OUT ITS OUTPUT
  tickUpdateOutputs();
  //PHASE 2: EVERY WIRE CARRIES OUTPUTS TO INPUTS
  tickUpdateInputs();
}


void halfTick() {
  cleanUpBoard();

  //FIRST HALF IS PHASE 1, SECOND HALF IS PHASE 2
  if (!doneTickFirstHalf) {
    tickUpdateOutputs();
    doneTickFirstHalf = true;
  } else {
    tickUpdateInputs();
    doneTickFirstHalf = false;
  }
}






void cleanUpBoard() {
  //---------- REMOVE THINGS ----------
  for (LogicGate logicGate : allLogicGates) {
    //REMOVE CONNECTION IF THERE'S NO CONNECTIONS TO ANY INPUTS
    for (Connection con : logicGate.getOutputConnections()) {
      if (!con.settingOutput && con.allConnectedToInputs.size() <= 0) con.removeAllConnections();
    }

    //RESET INPUTS TO FALSE IF THERE IS NO CONNECTION TO THEM
    for (LogicGate.IOButton inputDot : logicGate.inputs) if (!inputDot.hasConnectionFromOutput) inputDot.inputValue = false;
  }
}

void tickUpdateOutputs() {
  for (LogicGate logicGate : allLogicGates) logicGate.calculateOutput();
}

void tickUpdateInputs() {
  for (LogicGate logicGate : allLogicGates) for (Connection con : logicGate.getOutputConnections()) con.transferValue();
}
