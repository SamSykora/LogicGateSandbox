

void deleteGate(LogicGate logicGate) {
  //IF A WIRE WAS BEING DRAGGED OUT OF THIS GATE, CANCEL IT
  for (Connection con : logicGate.getOutputConnections()) if (con.settingOutput) isCreatingNewConnection = false;

  //REMOVE EVERY WIRE TO AND FROM THIS GATE
  removeAllOutputConnections(logicGate);
  removeAllInputConnections(logicGate);

  //REMOVE IT FROM THE BOARD
  allLogicGates.remove(logicGate);

  //THE SELECTED GATE IS NOW GONE
  isAGateSelected = false;
  isMouseInMenu = false;
}


//================================================== SPAWN A GATE ==================================================
void spawnGate(int type) {
  int x = width/2 + int(random(-20, 20));
  int y = height/2 + int(random(-20, 20));
  LogicGate newGate = null;

  if (type == 1) newGate = new NotGate(x, y);
  else if (type == 2) newGate = new AndGate(x, y);
  else if (type == 3) newGate = new OrGate(x, y);
  else if (type == 4) newGate = new XorGate(x, y);
  else if (type == 5) newGate = new BufferGate(x, y);
  else if (type == 6) newGate = new Lamp(x, y);
  else if (type == 7) newGate = new Button(x, y);

  //11 AND UP CAN'T BE MADE WITH THE KEYBOARD NUMBERS
  else if (type == 11) newGate = new Clock(x, y);
  else if (type == 12) newGate = new SRCircuit(x, y);
  else if (type == 13) newGate = new TDFlipFlop(x, y);
  else if (type == 14) newGate = new JKFlipFlop(x, y);

  //IF THAT GATE TYPE DOESN'T EXISTS, DO NOTHING
  if (newGate == null) return;

  //UPDATE AND ADD IT
  newGate.calculateOutput();
  allLogicGates.add(newGate);
}




ArrayList<LogicGate> allLogicGates = new ArrayList<>();

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Logic Gate Super Class ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

abstract class LogicGate {
  //BODY
  String gateType;  //The label in the center of the gate that shows its name/type
  float x, y, boxWidth, boxHeight;
  final float defaultButtonSize = 17;  //The size every IOButton will normally be
  color bodyColor = color(0, 180, 255), textColor = color(0);
  int maxInputCount, minInputCount;

  //OUTPUT
  Connection outputConnection = null;  //The wires/connections the output dot uses to transfer data to inputs
  boolean outputResult = false;  //The output dots value
  IOButton outputDot = new IOButton(false);  //The output dot
  ArrayList<IOButton> outputs = new ArrayList<IOButton>();  //All outputs this gate has

  //INPUT
  boolean changeType = false;  //Whether we make this gate invert its singal (used for NAND, NOR, and XNOR)
  ArrayList<IOButton> inputs = new ArrayList<IOButton>();  //All inputs this gate has

  //ROTATION
  static final int ROT_UP = 0, ROT_RIGHT = 1, ROT_DOWN = 2, ROT_LEFT = 3;  //The constant names for the rotations
  int rotation = ROT_RIGHT;  //What direction/side the output is on/pointing to
  float[] sidesAdjustX;
  float[] sidesAdjustY;

  //MOVING
  boolean isClicked = false;  //If this gate is being clicked (shown with yellow border)
  boolean isBeingMoved = false;  //If this gate is being and should be moved
  boolean isInGroup = false;  //Part of the Ctrl+drag group (only used for moving everything together)


  LogicGate(String gateType, int maxInputCount, int minInputCount, int x, int y) {
    this.gateType = gateType;
    this.maxInputCount = maxInputCount;
    this.minInputCount = minInputCount;

    this.x = x;
    this.y = y;
    boxWidth = 70;
    boxHeight = 70;

    outputs.add(outputDot);

    updateDotSides();
  }


  void drawPreliminary() {
    if (isClicked) {  //MAKE YELLOW OUTLINE WHEN CLICKED
      strokeWeight(2);
      stroke(255, 255, 0);
    } else if (isInGroup) {  //MAKE WHITE OUTLINE WHEN GROUPED
      strokeWeight(4);
      stroke(255);
    } else noStroke();  //Else no border/outline
  }

  void draw() {
    //CENTER TYPE TEXT
    textAlign(CENTER, CENTER);
    textSize(10);

    fill(textColor);
    text(gateType, x, y);

    //DRAW OUTPUT DOT
    for (IOButton outDot : outputs) outDot.draw();

    //DRAW INPUT DOTS
    for (int i = 0; i < inputs.size(); i++) inputs.get(i).draw();

    //ONLY IF THIS IS THE CLICKED GATE
    if (isClicked) updateMenuStats();
  }


  void updateMenuStats() {
    if (rotation == 0) menuRotationStat = "UP";
    else if (rotation == 1) menuRotationStat = "RIGHT";
    else if (rotation == 2) menuRotationStat = "DOWN";
    else if (rotation == 3) menuRotationStat = "LEFT";

    inputCurMaxStat = inputs.size() +" / "+ maxInputCount;
    inputMinStat = str(minInputCount);

    if (changeType) modeCountStat = "2 / 2";
    else modeCountStat = "1 / 2";
  }



  //================================================== Move & Location ==================================================
  void updatePosistions() {
    //UPDATE POSITION: PLACE AT MOUSE LOCATION WHEN BEING MOVED
    if (isBeingMoved) movePosistion();
    for (int i = 0; i < outputs.size(); i++) outputs.get(i).movePosistion(i);
    for (int i = 0; i < inputs.size(); i++) inputs.get(i).movePosistion(i);
  }

  private void movePosistion() {
    x = mouseX;
    y = mouseY;
    updateDotSides();
  }

  void moveBy(float dx, float dy) {
    x += dx;
    y += dy;
    updateDotSides();
  }


  private void updateDotSides() {
    sidesAdjustX = new float[] {x, x + boxWidth/2, x, x - boxWidth/2};   //Row offset for UP, RIGHT, DOWN, LEFT, respectively.
    sidesAdjustY = new float[] {y - boxHeight/2, y, y + boxHeight/2, y}; //Row offset for UP, RIGHT, DOWN, LEFT, respectively.
  }

  boolean isMouseOverGateOrDots() {
    //THE GATE BODY
    if (checkIfMouseIsInBounds()) return true;

    //ANY INPUT DOT
    for (IOButton inputDot : inputs) {
      if (inputDot.checkIfMouseIsInBounds()) return true;
    }

    //ANY OUTPUT DOT
    for (IOButton outDot : outputs) if (outDot.checkIfMouseIsInBounds()) return true;

    //RETURN FALSE IF NOTHING WAS TRUE
    return false;
  }

  boolean checkIfMouseIsInBounds() {
    if (mouseX >= x - boxWidth/2  &&  mouseX <= x + boxWidth/2  &&  mouseY >= y - boxHeight/2  &&  mouseY <= y + boxHeight/2) {
      return true; // mouse IS inside bounds
    } else return false; // mouse is NOT inside bounds
  }




  //================================================== Input Management ==================================================
  void addInput() {
    if (inputs.size() >= maxInputCount) return;
    inputs.add(new IOButton(true));

    updateInputDotSizes();
    calculateOutput();
  }

  void removeInput() {
    if (inputs.size() <= minInputCount) return;
    inputs.remove(inputs.size() - 1);

    updateInputDotSizes();
    calculateOutput();
  }

  void updateInput(int whichInput, boolean inputValue) {
    if (whichInput > inputs.size() || whichInput < 0) return;
    inputs.get(whichInput).inputValue = inputValue;
  }

  void updateInputDotSizes() {
    if (this instanceof CustomCircuit) return;
    
    //BASED ON HOW MANY INPUTS THERE ARE, THEN PICK THE SIZE
    float newSize = defaultButtonSize;  //Same as the default dotSize in IOButton
    if (inputs.size() >= 6) newSize = defaultButtonSize - 4;
    else if (inputs.size() >= 5) newSize = defaultButtonSize - 2;

    //GIVE EVERY INPUT THAT SAME SIZE
    for (IOButton inputDot : inputs) inputDot.dotSize = newSize;
  }



  //================================================== Connection Management ==================================================
  void addConnection(LogicGate.IOButton connectedOutputDot) {
    //GIVE THIS OUTPUT DOT A CONNECTION IF IT DOESN'T HAVE ONE
    if (connectedOutputDot.outputConnection == null) connectedOutputDot.outputConnection = new Connection(this, connectedOutputDot);
  }

  ArrayList<Connection> getOutputConnections() {
    //GET EVERY CONNECTION LEAVING THIS GATE - ONE PER OUTPUT DOT
    ArrayList<Connection> found = new ArrayList<Connection>();
    for (IOButton outDot : outputs) if (outDot.outputConnection != null) found.add(outDot.outputConnection);
    return found;
  }


  //A NORMAL GATE HAS ONE OUTPUT, SO IT'S JUST outputResult. A GATE WITH SEVERAL (CustomCircuit) OVERRIDES THIS
  boolean getOutputValueAt(int outputIndex) {
    return outputResult;
  }

  void addOutput() {
    outputs.add(new IOButton(false));
  }








  //================================================== Gate Requirements ==================================================
  abstract void calculateOutput();
  abstract void changeType();

  //Used for buttons:
  void onLeftClick() {
  }


  //==================================================                       ==================================================
  //================================================== I/O Dot Buttons CLASS ==================================================
  //==================================================                       ==================================================

  //Input/Output Button
  class IOButton {
    final boolean isThisAnInputDot;
    boolean inputValue = false;
    float dotX, dotY, dotSize;
    String dotText = "";  //The text to show in the middle of the dot

    Connection inputReceivingConnection = null;  //If this is an input, then it gets its data from this connection
    boolean hasConnectionFromOutput = false;  //If this is an input, mark if this has a connection to this input
    Connection outputConnection = null;  //The wires/connections the output dot uses to transfer data to inputs




    IOButton(boolean isThisAnInputDot) {
      this.isThisAnInputDot = isThisAnInputDot;

      if (isThisAnInputDot) dotText = "I";
      else dotText = "O";

      dotSize = defaultButtonSize;
    }

    LogicGate getLogicGateObject() {
      return LogicGate.this;
    }
    boolean currentOutputValue() {
      //RETURN THE outputResult THIS outputDot IS SENDING
      return getOutputValueAt(outputs.indexOf(this));
    }


    void draw() {
      //PICK BORDER
      strokeWeight(2);
      stroke(0);

      //PICK COLOR
      if ((!isThisAnInputDot && currentOutputValue()) || (inputValue && isThisAnInputDot)) fill(0, 255, 0);  //Green
      else fill(255, 0, 0);  //Red

      //DRAW DOT
      circle(dotX, dotY, dotSize);

      //DRAW CENTER TEXT/LABEL IN DOT
      textSize(8);
      fill(0);
      text(dotText, dotX, dotY);
    }


    void movePosistion(int posOrder) {
      //PICK ROTATION
      int adjustedRotation = rotation;
      if (isThisAnInputDot) adjustedRotation += 2;
      adjustedRotation = ((adjustedRotation % 4) + 4) % 4;

      final float shiftSize = dotSize + 3;

      //GET COUNT, SO IT STAYS CENTERED
      int dotCount = isThisAnInputDot ? inputs.size() : outputs.size();

      //SLOT 0 SITS HALF A GROUP ABOVE CENTER, THE LAST SLOT HALF A GROUP BELOW
      float offset = shiftSize * (posOrder - (dotCount - 1) / 2.0);

      //PICK LOCATION
      dotX = sidesAdjustX[adjustedRotation];
      if (adjustedRotation == ROT_UP || adjustedRotation == ROT_DOWN) dotX += offset;

      dotY = sidesAdjustY[adjustedRotation];
      if (adjustedRotation == ROT_RIGHT || adjustedRotation == ROT_LEFT) dotY += offset;
    }






    boolean checkIfMouseIsInBounds() {
      if (mouseX >= dotX - dotSize/2  &&  mouseX <= dotX + dotSize/2  &&  mouseY >= dotY - dotSize/2  &&  mouseY <= dotY + dotSize/2) {
        return true; // mouse IS inside bounds
      } else return false; // mouse is NOT inside bounds
    }

    //CLASS END
  }
  //CLASS END
}








//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Individual Logic Gates ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



//================================================== NOT Gate ==================================================

class NotGate extends LogicGate {
  NotGate(int x, int y) {
    super("NOT", 1, 1, x, y);

    addInput();
  }

  void calculateOutput() {
    //---------- GATE LOGIC ----------
    outputResult = !inputs.get(0).inputValue;
  }

  @Override
    void updateInput(int whichInput, boolean inputValue) {
    inputs.get(0).inputValue = inputValue;
  }

  void changeType() {
  }


  @Override
    void draw() {
    drawPreliminary();


    //---------- DRAW BODY ----------
    pushMatrix();  // Save settings

    translate(x, y);  // Origin is now the gate's center
    rotate((rotation - ROT_RIGHT) * HALF_PI);  // 0 when RIGHT, then 90 degrees per step
    fill(bodyColor);

    triangle(
      -boxWidth/2, -boxHeight/2, // Back-top corner
      -boxWidth/2, boxHeight/2, // Back-bottom corner
      boxWidth/2, 0);          // Tip

    popMatrix();  // Load settings


    super.draw();
  }
}

//================================================== AND Gate ==================================================


class AndGate extends LogicGate {
  AndGate(int x, int y) {
    super("AND", 6, 2, x, y);

    addInput();
    addInput();
  }

  void calculateOutput() {
    boolean tempOutput = true;

    //---------- GATE LOGIC ----------
    for (IOButton inputDot : inputs) {
      if (inputDot.inputValue) continue;  //If true, then good, do nothing
      tempOutput = false;  //Else, set false then stops
      break;
    }

    //IF changeType TRUE, INVERT THE RESULT
    if (changeType) outputResult = !tempOutput;
    else outputResult = tempOutput;
  }

  void changeType() {
    changeType = !changeType;

    if (changeType) gateType = "NAND";
    else gateType = "AND";

    calculateOutput();
  }


  @Override
    void draw() {
    drawPreliminary();


    //---------- DRAW BODY ----------
    float w = boxWidth/2, h = boxHeight/2;    // Half sizes, so edges are at +-w and +-h
    float k = 0.5523;                         // Makes a bezier curve match a circle

    pushMatrix();  // Save settings

    translate(x, y);                          // Origin is now the gate's center
    rotate((rotation - ROT_RIGHT) * HALF_PI); // 0 when RIGHT, then 90 degrees per step
    fill(bodyColor);

    beginShape();
    vertex(-w, -h);                           // Top-left
    vertex(0, -h);                            // Top-middle, where the curve starts
    bezierVertex(k*w, -h, w, -k*h, w, 0);     // Curve down to the tip
    bezierVertex(w, k*h, k*w, h, 0, h);       // Curve back to the bottom-middle
    vertex(-w, h);                            // Bottom-left
    endShape(CLOSE);

    popMatrix();  // Load settings


    super.draw();
  }
}





//================================================== OR Gate ==================================================


class OrGate extends LogicGate {
  OrGate(int x, int y) {
    super("OR", 6, 2, x, y);

    addInput();
    addInput();
  }

  void calculateOutput() {
    boolean tempOutput = false;

    for (IOButton inputDot : inputs) {
      if (!inputDot.inputValue) continue;  //If false, then bad, do nothing
      tempOutput = true;  //Else, set true if any is true, then stop
      break;
    }

    //IF changeType TRUE, INVERT THE RESULT
    if (changeType) outputResult = !tempOutput;
    else outputResult = tempOutput;
  }

  void changeType() {
    changeType = !changeType;

    if (changeType) gateType = "NOR";
    else gateType = "OR";

    calculateOutput();
  }


  @Override
    void draw() {
    drawPreliminary();


    //---------- DRAW BODY ----------
    // TWEAKABLE SETTINGS
    float sideStraightLength = 25; // The length of the flat top/bottom edge, measured from the back corner
    float noseTaperLength    = 5;  // How far back from the tip the curve starts easing in. Bigger = longer, gentler point
    float noseRoundness      = 15; // 0 = needle-thin point. Bigger = wider/blunter point
    float backDentDepth      = 8;  // How far the back edge caves inward. 0 = flat back
    float backDentHeight     = 10; // How tall the dent is. Smaller = tight narrow dent, bigger = wide shallow dent

    // CORNERS (measured from the gate's center)
    float leftEdgeX   = -boxWidth/2;
    float rightTipX   =  boxWidth/2;
    float topEdgeY    = -boxHeight/2;
    float bottomEdgeY =  boxHeight/2;

    // WHERE THE FLAT EDGE ENDS AND THE CURVE BEGINS
    float flatEdgeEndX = leftEdgeX + sideStraightLength;
    float halfwayToTipX = (flatEdgeEndX + rightTipX) / 2;

    pushMatrix();  // Save settings

    translate(x, y);  // Origin is now the gate's center
    rotate((rotation - ROT_RIGHT) * HALF_PI);  // 0 when RIGHT, then 90° per step
    fill(bodyColor);

    beginShape();
    // TOP EDGE: flat line first...
    vertex(leftEdgeX, topEdgeY);
    vertex(flatEdgeEndX, topEdgeY);

    // ...then the: curve from the end of the flat line to the tip
    bezierVertex(halfwayToTipX, topEdgeY, rightTipX - noseTaperLength, -noseRoundness, rightTipX, 0);

    // BOTTOM EDGE: curve from the tip back to the end of the bottom flat line...
    bezierVertex(rightTipX - noseTaperLength, noseRoundness, halfwayToTipX, bottomEdgeY, flatEdgeEndX, bottomEdgeY);

    // ...then the: flat line to the bottom-left corner
    vertex(leftEdgeX, bottomEdgeY);

    // BACK DENT: bottom-left corner up to top-left corner, caving inward
    bezierVertex(leftEdgeX + backDentDepth, backDentHeight, leftEdgeX + backDentDepth, -backDentHeight, leftEdgeX, topEdgeY);
    endShape(CLOSE);

    popMatrix();  // Load settings


    super.draw();
  }
}


//================================================== XOR Gate ==================================================


class XorGate extends LogicGate {
  XorGate(int x, int y) {
    super("XOR", 6, 2, x, y);

    addInput();
    addInput();
  }

  void calculateOutput() {
    boolean tempOutput = false;
    int trueCount = 0;

    //COUNT EVERY TRUE INPUT
    for (IOButton inputDot : inputs)  if (inputDot.inputValue) trueCount++;
    //IF THERE IS AN ODD NUMBER OF TRUE INPUTS, THEN OUTPUT IS TRUE
    if (trueCount % 2 == 1) tempOutput = true;

    //IF changeType TRUE, INVERT THE RESULT
    if (changeType) outputResult = !tempOutput;
    else outputResult = tempOutput;
  }

  void changeType() {
    changeType = !changeType;

    if (changeType) gateType = "XNOR";
    else gateType = "XOR";

    calculateOutput();
  }


  @Override
    void draw() {
    drawPreliminary();


    // ---------- DRAW BODY ----------
    // TWEAKABLE SETTINGS
    float sideStraightLength = 25;
    float noseTaperLength    = 5;
    float noseRoundness      = 15;
    float backDentDepth      = 8;
    float backDentHeight     = 10;
    float gapBehindBody      = 6;   // How far behind the body the extra line sits
    float extraLineTrim      = 2;   // How far the extra line's tips are pulled in from the body's top/bottom edges

    // CORNERS (measured from the gate's center)
    float leftEdgeX   = -boxWidth/2;
    float rightTipX   =  boxWidth/2;
    float topEdgeY    = -boxHeight/2;
    float bottomEdgeY =  boxHeight/2;

    float flatEdgeEndX  = leftEdgeX + sideStraightLength;
    float halfwayToTipX = (flatEdgeEndX + rightTipX) / 2;
    float extraLineX    = leftEdgeX - gapBehindBody;  // The extra line's back corners

    // WHERE THE EXTRA LINE STARTS AND ENDS (pulled in so it doesn't poke past the body)
    float extraLineTopY    = topEdgeY + extraLineTrim;
    float extraLineBottomY = bottomEdgeY - extraLineTrim;

    pushMatrix();

    translate(x, y);
    rotate((rotation - ROT_RIGHT) * HALF_PI);

    // BODY (same as the OR gate)
    fill(bodyColor);
    beginShape();
    vertex(leftEdgeX, topEdgeY);
    vertex(flatEdgeEndX, topEdgeY);
    bezierVertex(halfwayToTipX, topEdgeY, rightTipX - noseTaperLength, -noseRoundness, rightTipX, 0);
    bezierVertex(rightTipX - noseTaperLength, noseRoundness, halfwayToTipX, bottomEdgeY, flatEdgeEndX, bottomEdgeY);
    vertex(leftEdgeX, bottomEdgeY);
    bezierVertex(leftEdgeX + backDentDepth, backDentHeight, leftEdgeX + backDentDepth, -backDentHeight, leftEdgeX, topEdgeY);
    endShape(CLOSE);

    //  CURVED LINE
    pushStyle();
    noFill();
    stroke(bodyColor);
    strokeWeight(2);
    strokeCap(SQUARE);
    beginShape();
    vertex(extraLineX, extraLineBottomY);
    bezierVertex(extraLineX + backDentDepth, backDentHeight, extraLineX + backDentDepth, -backDentHeight, extraLineX, extraLineTopY);
    endShape();
    popStyle();

    popMatrix();


    super.draw();
  }
}




//================================================== Buffer Gate ==================================================

class BufferGate extends LogicGate {
  BufferGate(int x, int y) {
    super("BUFFER", 1, 1, x, y);

    addInput();
  }

  void calculateOutput() {
    //---------- GATE LOGIC ----------
    outputResult = inputs.get(0).inputValue;
  }

  @Override
    void updateInput(int whichInput, boolean inputValue) {
    inputs.get(0).inputValue = inputValue;
  }

  void changeType() {
  }


  @Override
    void draw() {
    drawPreliminary();


    //---------- DRAW BODY ----------
    pushMatrix();  // Save settings

    translate(x, y);  // Origin is now the gate's center
    rotate((rotation - ROT_RIGHT) * HALF_PI);  // 0 when RIGHT, then 90 degrees per step
    fill(bodyColor);

    triangle(
      -boxWidth/2, -boxHeight/2, // Back-top corner
      -boxWidth/2, boxHeight/2, // Back-bottom corner
      boxWidth/2, 0);          // Tip

    popMatrix();  // Load settings


    super.draw();
  }

  @Override
    void updateMenuStats() {
    super.updateMenuStats();

    modeCountStat = "1 / 1";
  }
}
