



//================================================== MERGE CALL ==================================================

void mergeIntoCircuit() {
  ArrayList<LogicGate> gatesGrouped = new ArrayList<LogicGate>();

  //GET ALL GATES PART OF A GROUP
  for (LogicGate logicGate : allLogicGates) if (logicGate.isInGroup) gatesGrouped.add(logicGate);

  //CHECK TO SEE IF GROUP IS VAILD, IF NOT, DO NOTHING
  if (!isGroupedSelectionVaildMerge(gatesGrouped)) return;
  println("is vaild");


  int inputCount = 0, outputCount = 0;
  for (LogicGate logicGate : gatesGrouped) {
    //REMOVE ALL LOGIC GATES
    allLogicGates.remove(logicGate);

    //REMOVE FLAGS
    logicGate.isClicked = false;
    logicGate.isBeingMoved = false;
    logicGate.isInGroup = false;

    //COUNT INPUTS AND OUTPUTS
    if (logicGate instanceof Button) inputCount++;
    else if (logicGate instanceof Lamp) outputCount++;
  }

  //RESET FLAGS
  isAGateSelected = false;
  isBoxSelecting = false;
  isMovingGroup = false;

  //CREATE CUSTOM CIRCUIT
  CustomCircuit cc = new CustomCircuit(gatesGrouped, inputCount, outputCount, width/2, height/2);
  allLogicGates.add(cc);
}




//================================================== MERGE CHECKER ==================================================

//IS VAILD WHEN:
//1) Has more than 3 gates (including button and lamp).
//2) Lamps are only in on/off mode (toggle buttons act as normal buttons).
//3) All inputs and outputs are used/connected to something.
//4) There are no wires that connect to any gates not selected in the group.
//5) You sort by highest up when buttons/lamps are facing left/right, and you sort by left-most when buttons/lamps are facing up/down.
//   Buttons must all face the same axis with each other, Lamps must all face the same axis with each other, Buttons/Lamps axis don't need to match.
//   Example: If one button is facing left, and all the rest is facing up/down, that would make it invaild.
//   This is done this way so you always know what posistion/order the inputs/outputs are supposed to be.




boolean isGroupedSelectionVaildMerge(ArrayList<LogicGate> gatesGrouped) {
  boolean doesContainButton = false, doesContainLamp = false;
  int buttonFacing = -1, lampFacing = -1;  //-1 = none found yet, 0 = facing left/right, 1 = facing up/down

  //IF 3 OR LESS GATES ARE GROUPED, DO NOTHING (since you can't combine anything in any special way with 1 button, 1 gate, 1 lamp)
  if (gatesGrouped.size() <= 3) return false;

  //FOR ALL GATES PART OF THE GROUP:
  for (LogicGate logicGate : gatesGrouped) {
    //DETECT IF A BUTTON AND LAMP IS PRESENT IN THE GROUPED SELECTION
    if (logicGate instanceof Button) doesContainButton = true;
    else if (logicGate instanceof Lamp && logicGate.inputs.size()==1) doesContainLamp = true;

    // GET IF THIS GATE FACES UP/DOWN OR LEFT/RIGHT
    int facing = 0;
    if (logicGate.rotation == LogicGate.ROT_UP || logicGate.rotation == LogicGate.ROT_DOWN) facing = 1;

    // ALL BUTTONS HAVE TO FACE THE SAME WAY
    if (logicGate instanceof Button) {
      if (buttonFacing != -1 && buttonFacing != facing) return false;
      buttonFacing = facing;
    }

    // ALL LAMPS HAVE TO FACE THE SAME WAY
    if (logicGate instanceof Lamp) {
      if (lampFacing != -1 && lampFacing != facing) return false;
      lampFacing = facing;
    }

    //LAMPS HAVE NO OUTPUT DOTS
    if (logicGate instanceof Lamp && logicGate.inputs.size() != 1) return false;  //The lamp doesn't have an output by design, and only vaild if it's in off/on mode

    //FOR ALL OUTPUT DOTS
    for (LogicGate.IOButton outputDot : logicGate.outputs) {
      //CHECK OUTPUT TO SEE IF IT'S EMPTY/UNCONNECTED
      if (outputDot.outputConnection == null  ||  outputDot.outputConnection.allConnectedToInputs.size() == 0) return false;

      //CHECK TO SEE IF THE OUTPUT CONNECTION FROM THIS GATE DOES NOT GO TO AN UNGROUPED GATE
      for (LogicGate.IOButton inputDot : outputDot.outputConnection.allConnectedToInputs) if (!inputDot.getLogicGateObject().isInGroup) return false;
    }

    //FOR ALL INPUTS IN GATE:
    for (LogicGate.IOButton ioButton : logicGate.inputs) {
      //CHECK ALL TO SEE IF ANY ARE EMPTY/UNCONNECTED
      if (!ioButton.hasConnectionFromOutput) return false;
      //CHECK TO SEE IF THE INPUT CONNECTION TO THIS GATE DOES NOT GO TO AN UNGROUP GATE
      if (!ioButton.inputReceivingConnection.connectedLogicGate.isInGroup) return false;
    }
  }

  //IF IT DOES NOT CONTAIN EITHER A LAMP OR BUTTON, DO NOTHING
  if (!doesContainButton || !doesContainLamp) return false;

  //ALL CHECKS PASSED
  return true;
}














//================================================== CustomCircuit Class ==================================================


class CustomCircuit extends LogicGate {
  final ArrayList<LogicGate> gatesGrouped, innerInputs, innerOutputs;
  boolean[] outputValues;  //What each output dot is sending, same order as the outputs list
  //final int lengthAdjust = max(inputs.size(), outputs.size());

  CustomCircuit(ArrayList<LogicGate> gatesGrouped, int inputCount, int outputCount, int x, int y) {
    super("CUSTOM", inputCount, inputCount, x, y);
    this.gatesGrouped = gatesGrouped;
    bodyColor = color(255, 200, 250);  //Pink

    //CREATE LISTS OF ALL THE INPUT BUTTONS AND OUTPUT LAMPS INSIDE THE CIRCUIT
    ArrayList<LogicGate> holder1 = new ArrayList<LogicGate>(), holder2 = new ArrayList<LogicGate>();
    for (LogicGate logicGate : gatesGrouped) {
      if (logicGate instanceof Button) holder1.add(logicGate);
      else if (logicGate instanceof Lamp) holder2.add(logicGate);
    }

    //SORT BY POSITION, SO DOT 1 IS THE TOP OR LEFT BUTTON/LAMP
    sortByPosition(holder1);
    sortByPosition(holder2);
    innerInputs = holder1;
    innerOutputs = holder2;
    outputValues = new boolean[outputCount];

    // MAKE THE DOTS (THE FIRST OUTPUT DOT ALREADY EXISTS, SO ONLY ADD THE REST)
    for (int i = 0; i < inputCount; i++) addInput();
    for (int i = 1; i < outputCount; i++) addOutput();

    // NUMBER THE DOTS
    for (int i = 0; i < inputs.size(); i++) inputs.get(i).dotText = str(i + 1);
    for (int i = 0; i < outputs.size(); i++) outputs.get(i).dotText = str(i + 1);

    // GROW THE BODY SO EVERY DOT FITS ON ITS SIDE
    boxWidth = max(70, 20 * max(inputCount, outputCount) + 10);
    boxHeight = boxWidth;
    moveBy(0, 0);  // Recalculates the sides, since updateDotSides() is private
  }
  
  
  
  
  
  


  void changeType() {
  }
  
  @Override
    void onLeftClick() {
      if (isAltDown) enterNewName(this);
    }

  @Override
    boolean getOutputValueAt(int outputIndex) {
    if (outputIndex < 0 || outputIndex >= outputValues.length) return false;
    return outputValues[outputIndex];
  }

  void calculateOutput() {
    //GIVE EACH INNER BUTTON THE VALUE OF THE MATCHING INPUT DOT
    for (int i = 0; i < inputs.size() && i < innerInputs.size(); i++) innerInputs.get(i).outputResult = inputs.get(i).inputValue;

    //RUN THE INNER GATES FOR ONE TICK
    doTick();

    //READ WHAT EACH INNER LAMP IS RECEIVING, AND PUT IT ON THE MATCHING OUTPUT DOT
    for (int i = 0; i < outputValues.length && i < innerOutputs.size(); i++) outputValues[i] = innerOutputs.get(i).inputs.get(0).inputValue;
  }

  private void doTick() {
    //PHASE 1: EVERY GATE FIGURES OUT ITS OUTPUT. BUTTONS ARE SKIPPED, SINCE THEIR VALUE COMES FROM THIS CIRCUIT'S INPUT DOTS
    for (LogicGate logicGate : gatesGrouped) if (!(logicGate instanceof Button)) logicGate.calculateOutput();
    //PHASE 2: EVERY WIRE CARRIES ITS VALUE
    for (LogicGate logicGate : gatesGrouped) for (Connection con : logicGate.getOutputConnections()) con.transferValue();
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



//================================================== DETERMINE INPUT/OUTPUT ORDERS FROM BUTTONS/LAMPS ==================================================
void sortByPosition(ArrayList<LogicGate> list) {
  if (list.size() == 0) return;

  // UP/DOWN GATES ARE IN A ROW SO SORT BY LEFT/RIGHT, LEFT/RIGHT GATES ARE IN A COLUMN SO SORT BY HEIGHT
  boolean sortByX = (list.get(0).rotation == LogicGate.ROT_UP || list.get(0).rotation == LogicGate.ROT_DOWN);  // Every gate faces the same way, so the first one is enough

  //FOR ALL GATES IN THE LIST
  for (int i = 0; i < list.size(); i++) {
    // FOR ALL GATES AFTER IT
    for (int j = i + 1; j < list.size(); j++) {
      // GET THE POSITION THAT MATTERS FOR BOTH
      float first = list.get(i).y, second = list.get(j).y;
      if (sortByX) {
        first = list.get(i).x;
        second = list.get(j).x;
      }

      // IF THE LATER GATE IS HIGHER/MORE LEFT, SWAP THEM
      if (second < first) {
        LogicGate holder = list.get(i);
        list.set(i, list.get(j));
        list.set(j, holder);
      }
    }
  }
}
