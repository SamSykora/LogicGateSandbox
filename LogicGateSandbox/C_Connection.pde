





//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Controls ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
boolean useWireRightAngleDrawing = false;


//================================================== REMOVE ALL INPUT CONNECTIONS ==================================================
void removeAllInputConnections(LogicGate logicGate) {
  for (LogicGate.IOButton inputDot : logicGate.inputs) {
    if (inputDot.inputReceivingConnection != null) inputDot.inputReceivingConnection.removeConnectionTo(inputDot);
  }
}

//================================================== REMOVE ALL OUTPUT CONNECTION ==================================================
void removeAllOutputConnections(LogicGate logicGate) {
  //FOR ALL OUTPUT DOTS
  for (LogicGate.IOButton outputDot : logicGate.outputs) {
    if (outputDot.outputConnection == null) continue;
    outputDot.outputConnection.removeAllConnections();
    outputDot.outputConnection = null;
  }
}


//================================================== ADD CONNECTION ==================================================
boolean isCreatingNewConnection = false;

void startConnection() {
  if (!isShiftDown) return;

  //---------- START/FIND CONNECTION AT OUTPUT ----------
  //IF YOU ARE NOT MAKING A CONNECTION AlREADY, THEN FOR ALL GATES
  if (!isCreatingNewConnection) for (LogicGate logicGate : allLogicGates) {
    //IF THE GATE DOESN'T EVEN HAVE AN OUTPUT, THEN SKIP
    if (logicGate.outputDot == null) continue;

    //FOR ALL OUTPUT DOTS
    for (LogicGate.IOButton outputDot : logicGate.outputs) {
      //FOR THE OUTPUT MAKE SURE MOUSE IS THERE - TO DETERMINE IF YOU SHOULD START
      if (outputDot.checkIfMouseIsInBounds()) {
        //CREATE NEW CONNECTION IF THERE IS NOT ONE
        logicGate.addConnection(outputDot);
        //TELL THAT CONNECTION IT IS BEING SET
        outputDot.outputConnection.settingOutput = true;
        isCreatingNewConnection = true;
        break;  //Stop since you found what the mouse was in
      }
    }

    //IF A CONNECTION WAS STARTED, STOP LOOKING AT GATES
    if (isCreatingNewConnection) break;
  }


  //DON'T NEED TO TRY TO CONNECT TO AN INPUT IF NO OUTPUT WAS SELECTED
  if (!isCreatingNewConnection) return;


  //---------- END CONNECTION AT INPUT ----------
  //FOR ALL GATES
  for (LogicGate logicGate : allLogicGates) {

    //FOR ALL INPUTS
    for (LogicGate.IOButton inputDot : logicGate.inputs) {
      //MAKE SURE THE INPUT DOT DOESN'T ALREADY HAVE A CONNECTION
      if (inputDot.hasConnectionFromOutput) continue;
      //SEE IF THE MOUSE IS IN THE INPUT DOT, IF NOT SKIP - TO DETERMINE IF YOU SHOULD END/CONNECT
      if (!inputDot.checkIfMouseIsInBounds()) continue;

      //NOW THAT YOU FOUND WHAT INPUT THE MOUSE IS IN, FIND THE OUTPUT WANTING TO BE CONNECTED TO
      for (LogicGate logicGate2 : allLogicGates) {
        //FOR ALL CONNECTIONS THIS LOGIC GATE HAS
        for (Connection con : logicGate2.getOutputConnections()) {
          //IF THIS CONNECTION IS NOT WANTING TO BE CONNECTED TO, SKIP
          if (!con.settingOutput) continue;

          //NOW THAT YOU FOUND THE OUTPUT, CONNECT THE OUTPUT TO THE INPUT
          con.addConnectionTo(inputDot);
        }
      }
    }
  }
  //
}




//================================================== REMOVE CONNECTION ==================================================

void removeConnectionUsingInput() {
  if (!isShiftDown || isCreatingNewConnection) return;

  //CAN'T REMOVE ANYTHING IF NO GATE IS SELECTED
  if (!isAGateSelected) return;

  //---------- REMOVE CONNECTION WHEN INPUT CLICKED ----------
  for (LogicGate logicGate : allLogicGates) if (logicGate.isClicked) {
    for (LogicGate.IOButton inputDot : logicGate.inputs) {
      //IF MOUSE NOT IN INPUT DOT, SKIP
      if (!inputDot.checkIfMouseIsInBounds()) continue;

      //IF INPUT DOT HAS NO CONNECTION, DO NOTHING
      if (!inputDot.hasConnectionFromOutput || inputDot.inputReceivingConnection == null) continue;

      //GET THIS INPUTS RECEIVING CONNECTION AND THEN CALL REMOVE IN IT
      inputDot.inputReceivingConnection.removeConnectionTo(inputDot);
    }
  }
}



//================================================== MAKING CONNECTION ==================================================

void endConnectionSetting() {
  for (LogicGate logicGate : allLogicGates) for (Connection con : logicGate.getOutputConnections()) con.settingOutput = false;
  isCreatingNewConnection = false;
}








//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Connection Class ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

class Connection {
  //TAKE SIGNAL FROM THIS LOGICGATE...
  final LogicGate connectedLogicGate;
  final LogicGate.IOButton connectedOutputDot;

  //...AND BRING IT TO THESE INPUTS:
  ArrayList<LogicGate.IOButton> allConnectedToInputs = new ArrayList<LogicGate.IOButton>();

  final color offLineColor = color(150, 150, 150), onLineColor = color(50, 150, 0);
  boolean settingOutput = false;

  Connection(LogicGate connectedLogicGate, LogicGate.IOButton connectedOutputDot) {
    this.connectedLogicGate = connectedLogicGate;
    this.connectedOutputDot = connectedOutputDot;
  }

  void addConnectionTo(LogicGate.IOButton newInputDot) {
    //CHECK TO SEE IF IT ALREADY IS CONNECTED
    if (newInputDot.hasConnectionFromOutput) return;

    //IF NOT, CONNECT TO IT
    allConnectedToInputs.add(newInputDot);

    newInputDot.inputReceivingConnection = this;  //Tell the inputDot to remember that this connection is the one it's connected too
    newInputDot.hasConnectionFromOutput = true;
  }

  void removeConnectionTo(LogicGate.IOButton inputDotToRemove) {
    //CHECK TO SEE IF IT ALREADY IS DISCONNECTED
    if (!inputDotToRemove.hasConnectionFromOutput) return;

    //IF NOT, DISCONNECT IT
    allConnectedToInputs.remove(inputDotToRemove);

    inputDotToRemove.inputReceivingConnection = null;
    inputDotToRemove.hasConnectionFromOutput = false;
    inputDotToRemove.inputValue = false;
  }

  void removeAllConnections() {
    for (int i = allConnectedToInputs.size() - 1; i >= 0; i--) removeConnectionTo(allConnectedToInputs.get(i));
  }




  void draw() {
    //PICK STYLE
    strokeCap(SQUARE);
    strokeWeight(2);

    //PICK COLOR
    if (connectedOutputDot.currentOutputValue()) stroke(onLineColor);
    else stroke(offLineColor);

    //DRAW LINE TO MOUSE WHEN CONNECTING
    if (settingOutput) line(connectedOutputDot.dotX, connectedOutputDot.dotY, mouseX, mouseY);

    //DRAW CONNECTION LINE
    drawLine();
  }




  private void drawLine() {
    //GET AND DETERMINE THE OUTPUT DOTS GATES ROTATION
    final int outRot = connectedLogicGate.rotation;
    boolean leaveDotVertically = (outRot == LogicGate.ROT_UP || outRot == LogicGate.ROT_DOWN);


    for (LogicGate.IOButton connectedInput : allConnectedToInputs) {
      final float outX = connectedOutputDot.dotX;
      final float outY = connectedOutputDot.dotY;
      final float inX = connectedInput.dotX;
      final float inY = connectedInput.dotY;

      //GET AND DETERMINE INPUT DOTS GATES ROTATION
      final int inRot = connectedInput.getLogicGateObject().rotation;
      final boolean enterDotVertically = (inRot == outRot || inRot == (outRot + 2) % 4);

      if (useWireRightAngleDrawing) {  //DRAW LINE THAT HAS CORNERS, NOT STRIGHT LINES
        //GET THE SPOT WHERE THE WIRE TURNS - HALFWAY BETWEEN THEM
        float midX = (outX + inX) / 2.0f;
        float midY = (outY + inY) / 2.0f;


        if (enterDotVertically) {  //INPUT GATE *IS* THE SAME AXIS AS THE OUTPUT GATE
          if (leaveDotVertically) {  //OUTPUT VERTICAL
            line(outX, outY, outX, midY);  //FROM OUTPUT TO MID
            line(outX, midY, inX, midY);   //FROM MID TO MID
            line(inX, midY, inX, inY);     //FROM MID TO INPUT
          } else {  //OUTPUT HORIZONTAL
            line(outX, outY, midX, outY);  //FROM OUTPUT TO MID
            line(midX, outY, midX, inY);   //FROM MID TO MID
            line(midX, inY, inX, inY);     //FROM MID TO INPUT
          }
        } else {  //INPUT GATE IS *NOT* THE SAME AXIS AS THE OUTPUT GATE
          if (leaveDotVertically) {  //OUTPUT VERTICAL
            line(outX, outY, outX, inY);   //FROM OUTPUT TO CORNER
            line(outX, inY, inX, inY);     //FROM CORNER TO INPUT
          } else {  //OUTPUT HORIZONTAL
            line(outX, outY, inX, outY);   //FROM OUTPUT TO CORNER
            line(inX, outY, inX, inY);     //FROM CORNER TO INPUT
          }
        }
      } else {  //DO STRIGHT LINE SINCE RIGHT ANGLE LINES ARE OFF
        //DRAW STRIGHT LINE
        line(outX, outY, inX, inY);
      }
    }
  }




  void transferValue() {
    //SET INPUT TO THE OUTPUT
    for (LogicGate.IOButton connectedInput : allConnectedToInputs) connectedInput.inputValue = connectedOutputDot.currentOutputValue();
  }



  //CLASS END
}
