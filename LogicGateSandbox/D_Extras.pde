import javax.swing.JOptionPane;
import javax.swing.JDialog;



//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Extra Circuits ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

//================================================== Lamp ==================================================

class Lamp extends LogicGate {
  color currentLampColor = color(0);

  Lamp(int x, int y) {
    super("LAMP", 3, 1, x, y);
    disableOutput();

    addInput();
  }



  void calculateOutput() {
    currentLampColor = color(0);

    //---------- 1 INPUT GATE LOGIC ----------
    //THE COLOR IS ENTIER ON/OFF (WHITE/BLACK)
    if (inputs.size() == 1) {

      if (inputs.get(0).inputValue) {  //LAMP ON
        currentLampColor = color(255);
        textColor = color(0);
      } else {  //LAMP OFF
        currentLampColor = color(0);
        textColor = color(255);
      }

      return;
    }

    //---------- 3 INPUT GATE LOGIC ----------
    if (inputs.size() == 3) {

      int[] rgbValues = new int[3];
      for (int i = 0; i < inputs.size(); i++) {
        if (inputs.get(i).inputValue) rgbValues[i] = 255;  // Set rbgValue high if the input is true
        else rgbValues[i] = 0;
      }

      currentLampColor = color(rgbValues[0], rgbValues[1], rgbValues[2]);
      return;
    }
  }

  void changeType() {
  }


  private void disableOutput() {
    outputs.clear();
    outputDot = null;
  }

  @Override
    void addInput() {
    super.addInput();
    //ADD AN ADDITIONAL INPUT IF THERE IS ONLY 2
    if (inputs.size() == 2) {
      super.addInput();

      //RELABEL ALL INPUTS WITH THEIR COLOR CHANNEL
      for (int i = 0; i < inputs.size(); i++) {
        if (i == 0) inputs.get(0).dotText = "R";
        else if (i == 1) inputs.get(1).dotText = "G";
        else if (i == 2) inputs.get(2).dotText = "B";
      }
    }
  }

  @Override
    void removeInput() {
    super.removeInput();

    if (inputs.size() == 2) {
      super.removeInput();

      //RELABEL INPUT AS JUST A NORMAL ON/OFF INPUT
      inputs.get(0).dotText = "I";
    }
  }


  @Override
    void onLeftClick() {
    if (isAltDown) enterNewName(this);
  }


  @Override
    void draw() {
    drawPreliminary();


    //---------- DRAW BODY ----------
    rectMode(CENTER);

    //DRAW GREY BORDER
    fill(150);
    rect(x, y, boxWidth, boxHeight);

    //DRAW DISPLAY COLOR
    noStroke();
    fill(currentLampColor);
    rect(x, y, boxWidth - boxWidth/4, boxHeight - boxWidth/4);


    super.draw();
  }

  @Override
    void updateMenuStats() {
    super.updateMenuStats();

    modeCountStat = "1 / 1";
  }
}



//================================================== Button ==================================================

class Button extends LogicGate {
  final color unpressedColor = color(255, 0, 0);
  final color pressedColor = color(125, 0, 0);
  color currentColor = unpressedColor;
  boolean toggledOn = false;

  Button(int x, int y) {
    super("BUTTON", 0, 0, x, y);
  }


  void calculateOutput() {
    if (changeType) {  //TOGGLE MODE:
      //OUTPUT IS JUST WHATEVER THE TOGGLE STATE IS
      outputResult = toggledOn;
    } else {  //BUTTON MODE:
      //DETECT IF THE LEFT MOUSE BUTTON IS BEING PRESSED AND HELD DOWN, AND, MAKE SURE THE MOUSE IS OVER THIS BUTTON
      if (mousePressed && mouseButton == LEFT && checkIfMouseIsInBounds()) outputResult = true;
      else outputResult = false;
    }

    //PICK COLOR
    if (outputResult) currentColor = pressedColor;
    else currentColor = unpressedColor;
  }

  @Override
    void onLeftClick() {
    //CHANGE NAME IF HOLDING ALT ON CLICK
    if (isAltDown) enterNewName(this);

    //ONLY TOGGLE WHEN IN TOGGLE MODE
    if (!changeType) return;

    toggledOn = !toggledOn;

    calculateOutput();  //Update instantly
  }

  void changeType() {
    changeType = !changeType;
    toggledOn = false;  //Start off whenever the mode changes

    if (changeType) gateType = "TOGGLE\nBUTTON";
    else gateType = "BUTTON";

    calculateOutput();
  }

  @Override
    void draw() {
    drawPreliminary();


    //---------- DRAW BODY ----------
    rectMode(CENTER);

    //DRAW GREY BORDER
    fill(150);
    rect(x, y, boxWidth, boxHeight);

    //DRAW DISPLAY COLOR
    noStroke();
    fill(currentColor);
    rect(x, y, boxWidth - boxWidth/4, boxHeight - boxWidth/4);


    super.draw();
  }
}



//================================================== Clock ==================================================

class Clock extends LogicGate {
  final float maxHZNormalRange = 10, minHZNormalRange = 1;  //1 to 10 ticks per second
  final float maxHZSlowRange = 1.0f, minHZSlowRange = 0.1f;  //1 to 5 seconds per tick (0.1Hz = 5 on, 5 off)
  float currentTicksPerSec = 1; //HZ (full on/off cycles per second)

  float timeSinceToggleMs = 0;  //How much simulation time has passed since the output last flipped

  Clock(int x, int y) {
    super("CLOCK", 0, 0, x, y);
    bodyColor = color(120, 0, 180);  //Purple
  }


  void calculateOutput() {
    //HALF A CYCLE IS HOW LONG THE OUTPUT STAYS ON, THEN HOW LONG IT STAYS OFF
    float halfCycleMs = 1000 / currentTicksPerSec / 2;

    //THIS RUNS ONCE PER TICK, SO ONE TICK'S WORTH OF TIME HAS PASSED
    timeSinceToggleMs += tickDelayMs;

    //IF A HALF CYCLE HAS PASSED, FLIP THE OUTPUT
    if (timeSinceToggleMs >= halfCycleMs) {
      outputResult = !outputResult;
      timeSinceToggleMs -= halfCycleMs;  //Keep the leftover time so the speed doesn't drift
    }
  }


  void changeSpeed(int direction) {  //Direction: 1 = faster, -1 = slower

    if (changeType) {  //SLOW MODE:
      //STEP BY 0.1
      currentTicksPerSec += 0.1f * direction;
      currentTicksPerSec = round(currentTicksPerSec * 10) / 10.0f;  //Rounds off float drift, so it stays at exactly 0.3 and not 0.30000001

      //KEEP IT WITHIN BOUNDS
      if (currentTicksPerSec > maxHZSlowRange) currentTicksPerSec = maxHZSlowRange;
      if (currentTicksPerSec < minHZSlowRange) currentTicksPerSec = minHZSlowRange;
    } else {  //NORMAL MODE:
      //STEP BY 1
      currentTicksPerSec += 1 * direction;

      //KEEP IT WITHIN BOUNDS
      if (currentTicksPerSec > maxHZNormalRange) currentTicksPerSec = maxHZNormalRange;
      if (currentTicksPerSec < minHZNormalRange) currentTicksPerSec = minHZNormalRange;
    }

    //RESTART THE TIMER, SO TIME BUILT UP AT THE OLD SPEED CAN'T CAUSE A BURST OF FLIPS
    timeSinceToggleMs = 0;
  }



  void changeType() {
    changeType = !changeType;

    //1 HZ IS INSIDE BOTH RANGES, SO IT'S A SAFE SPEED TO RESET TO WHEN SWITCHING MODES
    currentTicksPerSec = 1;
    timeSinceToggleMs = 0;

    if (changeType) gateType = "SLOW\nCLOCK";
    else gateType = "CLOCK";

    //NO calculateOutput() CALL HERE, AS THAT WOULD ADD AN EXTRA TICK OF TIME TO THE CLOCK
  }



  @Override
    void draw() {
    drawPreliminary();


    //---------- DRAW BODY ----------
    rectMode(CENTER);
    fill(bodyColor);
    rect(x, y, boxWidth, boxHeight);


    super.draw();


    //---------- DRAW THE CURRENT SPEED UNDER THE NAME ----------
    textAlign(CENTER, CENTER);
    textSize(9);
    fill(0);
    if (changeType) text(nf(currentTicksPerSec, 0, 1) + " Hz", x, y + 19);  //Slow mode shows one decimal, like 0.3
    else text(round(currentTicksPerSec) + " Hz", x, y + 19);
  }
}






//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Sequential Logic ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

interface SequentialLogic {
}
//Level-triggered: The output flips every tick while the clock is on - so it could flicker, as it updates over and over for as long as the clock is powered. (If there's no clock, then it's this type.)
//Edge-triggered: The output flips once per clock pulse (off and on). Note: If both inputs are false when the clock becomes true, and then soon after an input becomes true, then nothing happens.
//Illegal State: A situation where if all inputs are true, it causes problems or unpredictability. In these situations, in this sandbox, the solution is to just do absolutely no change to any values.
//Rising Edge: The single moment - for Edge-triggered things - that tell it when the clock becomes true away from false. Since Edge-triggered updates only happen immediately after that transition.



//================================================== SR Latch ==================================================

class SRCircuit extends LogicGate implements SequentialLogic {
  boolean persistantOutput = outputResult;
  IOButton setInput = null, resetInput = null, clockInput = null;

  static final int LATCH = 0, GATED_LATCH = 1, FLIP_FLOP = 2;  //LATCH = Level-triggered,  GATED_LATCH = Level-triggered,  FLIP_FLOP = Edge-triggered
  int mode = LATCH;
  boolean lastClock = false;  //What the clock was on the previous tick (only used by the flip-flop)


  SRCircuit(int x, int y) {
    super("SR LATCH", 2, 2, x, y);
    bodyColor = color(150, 100, 0);  //Brown

    addInput();  //Set
    setInput = inputs.get(0);
    setInput.dotText = "S";

    addInput();  //Reset
    resetInput = inputs.get(1);
    resetInput.dotText = "R";

    outputDot.dotText = "Q";  //Output
  }


  void calculateOutput() {
    //IF EITHER INPUT DOES NOT EXIST, THEN THIS CIRCUIT IS NOT FINSIHED BEING MADE
    if (setInput == null || resetInput == null) return;

    //---------- CLOCK INPUT LOGIC (FOR GATED LATCH & FLIP-FLOP) ----------
    if (mode != LATCH) {
      //IF THE CLOCK DOT IS STILL BEING MADE, DO NOTHING
      if (clockInput == null) return;

      //FOR GATED LATCH (LEVEL), DO ABSOLUTELY NOTHING WHILE THE CLOCK IS OFF
      if (mode == GATED_LATCH) {
        if (!clockInput.inputValue) return;
      }

      //FOR FLIP-FLOP (EDGE), ONLY ACT ON THE TICK THE CLOCK GOES FROM OFF TO ON
      else {
        boolean risingEdge = (clockInput.inputValue && !lastClock);  //True = this clock input (clockInput.inputValue) is true, and, last clock input (lastClock) is false
        lastClock = clockInput.inputValue;
        if (!risingEdge) return;  //If the clock is not coming from false to true, and it in flip-flip mode, then do nothing
      }
    }

    //DO ABSOLUTELY NOTHING IF BOTH INPUTS ARE ON
    if (setInput.inputValue && resetInput.inputValue) return;

    //SET THE OUTPUT TO WHATEVER THE INPUTS SAY
    if (setInput.inputValue) persistantOutput = true;
    if (resetInput.inputValue) persistantOutput = false;
    outputResult = persistantOutput;
  }


  void changeType() {
    //CYCLE = LATCH > GATED LATCH > FLIP-FLOP > LATCH
    if      (mode == LATCH)       mode = GATED_LATCH;
    else if (mode == GATED_LATCH) mode = FLIP_FLOP;
    else                          mode = LATCH;

    //IF SET AS A GATED_LATCH OR A FLIP_FLOP, THEN SAY changeType IS TRUE
    changeType = (mode != LATCH);

    //---------- SET UP THE NEW MODE ----------
    if (mode == GATED_LATCH) {  //SET AS GATED LATCH
      gateType = "GATED\nSR LATCH";
      addClockInput();  //Add clock input when transitioning from a normal latch to a gated latch
    } else if (mode == FLIP_FLOP) {  //SET AS FLIP-FLOP
      gateType = "SR\nFLIP-FLOP";
      lastClock = clockInput.inputValue;  //So a clock that's already on doesn't count as a new edge
    } else {  //RETURN BACK TO LATCH
      gateType = "SR\nLATCH";
      removeClockInput();
    }

    calculateOutput();
  }


  private void addClockInput() {
    //SET BOTH MIN AND MAX TO 3, SO BUTTONS ARN'T EFFECTIVE
    maxInputCount = 3;
    minInputCount = 3;

    //ADD CLOCK INPUT
    addInput();
    clockInput = inputs.get(2);
    clockInput.dotText = "C";
    lastClock = false;
  }


  private void removeClockInput() {
    //DISCONNECT ANY WIRE TO THE CLOCK INPUT
    if (clockInput.hasConnectionFromOutput) clockInput.inputReceivingConnection.removeConnectionTo(clockInput);
    clockInput = null;

    //SET BOTH MIN AND MAX TO 2, SO BUTTONS ARN'T EFFECTIVE
    maxInputCount = 2;
    minInputCount = 2;

    removeInput();
  }


  @Override
    void draw() {
    drawPreliminary();


    //---------- DRAW BODY ----------
    rectMode(CENTER);
    fill(bodyColor);
    rect(x, y, boxWidth, boxHeight);


    super.draw();
  }

  @Override
    void updateMenuStats() {
    super.updateMenuStats();

    if (mode == LATCH) modeCountStat = "1 / 3";
    else if (mode == GATED_LATCH) modeCountStat = "2 / 3";
    else modeCountStat = "3 / 3";
  }
}



//================================================== T & D Flip-Flop ==================================================

class TDFlipFlop extends LogicGate implements SequentialLogic {
  boolean persistantOutput = outputResult;
  IOButton dataInput = null, clockInput = null;  //dataInput is the T input in T mode, and the D input in D mode
  boolean lastClock = false;  //What the clock was on the previous tick

  //changeType = false is T, changeType = true is D
  TDFlipFlop(int x, int y) {
    super("T\nFLIP-FLOP", 2, 2, x, y);
    bodyColor = color(0, 130, 120);  //Cyan

    addInput();  //Data (T or D)
    dataInput = inputs.get(0);
    dataInput.dotText = "T";

    addInput();  //Clock
    clockInput = inputs.get(1);
    clockInput.dotText = "C";

    outputDot.dotText = "Q";  //Output
  }


  void calculateOutput() {
    //IF EITHER INPUT DOES NOT EXIST, THEN THIS CIRCUIT IS NOT FINISHED BEING MADE
    if (dataInput == null || clockInput == null) return;

    //ONLY ACT ON THE TICK THE CLOCK GOES FROM OFF TO ON
    boolean risingEdge = (clockInput.inputValue && !lastClock);
    lastClock = clockInput.inputValue;
    if (!risingEdge) return;

    //---------- D MODE: COPY WHATEVER D IS ----------
    if (changeType) {
      persistantOutput = dataInput.inputValue;
    }

    //---------- T MODE: FLIP THE OUTPUT IF T IS ON, OTHERWISE HOLD ----------
    else {
      if (dataInput.inputValue) persistantOutput = !persistantOutput;
    }

    outputResult = persistantOutput;
  }


  void changeType() {
    changeType = !changeType;

    if (changeType) {
      gateType = "D\nFLIP-FLOP";
      dataInput.dotText = "D";
    } else {
      gateType = "T\nFLIP-FLOP";
      dataInput.dotText = "T";
    }

    //SO A CLOCK THAT'S ALREADY ON DOESN'T COUNT AS A NEW EDGE
    lastClock = clockInput.inputValue;

    //NOT CALLING calculateOutput() HERE, BECAUSE SWITCHING MODES CAN'T CHANGE THE OUTPUT UNTIL THE NEXT CLOCK EDGE
  }


  @Override
    void draw() {
    drawPreliminary();


    //---------- DRAW BODY ----------
    rectMode(CENTER);
    fill(bodyColor);
    rect(x, y, boxWidth, boxHeight);


    super.draw();
  }
}



//================================================== JK Flip-Flop ==================================================

class JKFlipFlop extends LogicGate implements SequentialLogic {
  boolean persistantOutput = outputResult;
  IOButton jInput = null, kInput = null, clockInput = null;
  boolean lastClock = false;  //What the clock was on the previous tick

  JKFlipFlop(int x, int y) {
    super("JK\nFLIP-FLOP", 3, 3, x, y);
    bodyColor = color(150, 0, 80);  //Maroon

    addInput();  //J (set)
    jInput = inputs.get(0);
    jInput.dotText = "J";

    addInput();  //K (reset)
    kInput = inputs.get(1);
    kInput.dotText = "K";

    addInput();  //Clock
    clockInput = inputs.get(2);
    clockInput.dotText = "C";

    outputDot.dotText = "Q";  //Output
  }


  void calculateOutput() {
    //IF ANY INPUT DOES NOT EXIST, THEN THIS CIRCUIT IS NOT FINISHED BEING MADE
    if (jInput == null || kInput == null || clockInput == null) return;

    //ONLY ACT ON THE TICK THE CLOCK GOES FROM OFF TO ON
    boolean risingEdge = (clockInput.inputValue && !lastClock);
    lastClock = clockInput.inputValue;
    if (!risingEdge) return;

    //IF BOTH ON, THEN FLIP THE OUTPUT (THIS IS THE ONLY DIFFERENCE FROM THE SR)
    if (jInput.inputValue && kInput.inputValue) persistantOutput = !persistantOutput;
    //IF ONLY J ON, THEN SET
    else if (jInput.inputValue) persistantOutput = true;
    //IF ONLY K ON, THEN RESET
    else if (kInput.inputValue) persistantOutput = false;
    //IF BOTH OFF, THEN DO NOTHING/HOLD

    outputResult = persistantOutput;
  }


  void changeType() {
    //NOTHING TO CHANGE TO
  }


  @Override
    void draw() {
    drawPreliminary();


    //---------- DRAW BODY ----------
    rectMode(CENTER);
    fill(bodyColor);
    rect(x, y, boxWidth, boxHeight);


    super.draw();
  }
}
