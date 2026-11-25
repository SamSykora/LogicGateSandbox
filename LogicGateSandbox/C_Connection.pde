





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


      //---------- DRAW STRIGHT LINE ----------
      if (!useWireRightAngleDrawing) {
        line(outX, outY, inX, inY);
        continue;
      }



      //---------- GET THE STATE THINGS ARE IN FOR SQUARE LINE ----------
      //GET AND DETERMINE INPUT DOTS GATES ROTATION
      final LogicGate inGate = connectedInput.getLogicGateObject();  //Needed for its rotation, and for its position in the checks below
      final int inRot = inGate.rotation;

      //TRUE IF THE INPUT DOT IS ON THE TOP OR BOTTOM OF ITS GATE, JUST LIKE leaveDotVertically IS FOR THE OUTPUT DOT
      final boolean enterDotVertically = (inRot == LogicGate.ROT_UP || inRot == LogicGate.ROT_DOWN);

      //TRUE IF BOTH DOTS (INPUT AND OUTPUT DOTS) ARE ON THE TOP/BOTTOM OF THEIR GATES, OR BOTH ARE ON THE LEFT/RIGHT
      //DECIDES IF THE WIRE NEEDS THREE LINES TO GET BETWEEN THEM, OR ONLY ONE CORNER
      final boolean isSameAxis = (leaveDotVertically == enterDotVertically);


      //---------- SPECIAL DRAWING CHECKS FOR SQUARE LINE ----------
      //THE ROTATION OF A GATE IS THE SIDE ITS OUTPUT DOT IS ON, SO ITS INPUT DOTS ARE ALWAYS ON THE OPPOSITE SIDE
      //THIS SAYS THE SIDE THE INPUT DOT IS ON, ON THE INPUT GATE
      final int inSide = (inRot + 2) % 4;  //Adding 2 turns it around to the opposite side

      //THESE WILL LATER BE USED TO PICK HOW THE WIRE IS DRAWN
      boolean isInputDotFacingSameWay = false;      //Same axis only. Output dot and input dot are on the same side of their own gates
      boolean isInputGateBehindOutputGate = false;  //Same axis only. Input gate is on the opposite side of the output gate from where the output dot points
      boolean isInputDotFacingOutputGate = false;   //Different axis only. Input dot is on the side of its gate that points at the output gate

      //ONLY THE SAME AXIS CHECKS MAKE SENSE IF THE GATES ARE THE SAME AXIS
      if (isSameAxis) {
        //TRUE IF THE INPUT DOT IS ON THE SAME SIDE OF ITS GATE AS THE OUTPUT DOT IS ON ITS GATE (e.g. BOTH INPUT/OUTPUT DOTS ARE ON THE RIGHT)
        isInputDotFacingSameWay = !(inSide == outRot);
        //TRUE IF THE INPUT GATE IS BEHIND THE OUTPUT GATE
        //isInputGateBehindOutputGate = isGateOnSide(connectedLogicGate, inGate, (outRot + 2) % 4);
        isInputGateBehindOutputGate = isGateOnSide(outX, outY, inX, inY, (outRot + 2) % 4);
      } else {
        //TRUE IF THE INPUT DOT ON THE INPUT GATE POINTS AT THE OUTPUT GATE
        isInputDotFacingOutputGate = isGateOnSide(inX, inY, outX, outY, inSide);
      }


      //---------- DRAW SQUARE LINE ----------
      //GET THE SPOT WHERE THE WIRE TURNS - HALFWAY BETWEEN THEM
      float midX = (outX + inX) / 2.0f;
      float midY = (outY + inY) / 2.0f;

      if (isSameAxis) {
        //THE OUTPUT & INPUT GATE *ARE* THE SAME AXIS
        if (leaveDotVertically) drawLine_IsSameAxis_WhenOutputUpDown(outX, outY, inX, inY, midX, midY, isInputDotFacingSameWay, isInputGateBehindOutputGate);
        else drawLine_IsSameAxis_WhenOutputLeftRight(outX, outY, inX, inY, midX, midY, isInputDotFacingSameWay, isInputGateBehindOutputGate);
      } else {
        //THE OUTPUT & INPUT GATE ARE *NOT* THE SAME AXIS
        if (leaveDotVertically) drawLine_NotSameAxis_WhenOutputUpDown(outX, outY, inX, inY, inRot, isInputDotFacingSameWay, isInputDotFacingOutputGate);
        else drawLine_NotSameAxis_WhenOutputLeftRight(outX, outY, inX, inY, inRot, isInputDotFacingSameWay, isInputDotFacingOutputGate);
      }


      //
    }
  }


  //CHECKS IF otherGate IS ON THE GIVEN SIDE OF fromGate
  private boolean isGateOnSide(final float outX, final float outY, final float inX, final float inY, final int side) {
    if (side == LogicGate.ROT_RIGHT) return inX > outX;  //RIGHT SIDE: otherGate IS FURTHER RIGHT
    if (side == LogicGate.ROT_LEFT) return inX < outX;  //LEFT SIDE: otherGate IS FURTHER LEFT
    if (side == LogicGate.ROT_DOWN) return inY > outY;  //BOTTOM SIDE: otherGate IS LOWER ON THE SCREEN
    return inY < outY;  //OTHERWISE IT IS THE TOP SIDE: otherGate IS HIGHER ON THE SCREEN
  }


  private void drawLine_IsSameAxis_WhenOutputUpDown(final float outX, final float outY, final float inX, final float inY,
    final float midX, final float midY, final boolean isInputDotFacingSameWay, final boolean isInputGateBehindOutputGate) {
    //HERE WHEN OUTPUT & INPUT GATE IS UP/DOWN...

    if (isInputDotFacingSameWay && !isInputGateBehindOutputGate) {
      //...AND FACING THE SAME DIRECTION, BUT THE INPUT GATE IS IN FRONT OF THE OUTPUT GATE
      line(outX, outY, outX, midY);  //FROM OUTPUT TO MID
      line(outX, midY, inX, midY);   //FROM MID TO MID
      line(inX, midY, inX, inY);     //FROM MID TO INPUT
    } else if (isInputDotFacingSameWay) {
      //...AND FACING THE SAME DIRECTION, BUT THE INPUT GATE IS BEHIND THE OUTPUT GATE
      line(outX, outY, midX, outY);  //FROM OUTPUT TO MID
      line(midX, outY, midX, inY);   //FROM MID TO MID
      line(midX, inY, inX, inY);     //FROM MID TO INPUT
    } else {
      if (!isInputGateBehindOutputGate) {
        //...AND FACING THE OPPOSITE DIRECTION, BUT THE INPUT GATE IS IN FRONT OF THE OUTPUT GATE
        line(outX, outY, outX, inY);  //FROM OUTPUT TO MID
        line(outX, inY, inX, inY);    //FROM MID TO INPUT
      } else {
        //...AND FACING THE OPPOSITE DIRECTION, BUT THE INPUT GATE IS BEHIND THE OUTPUT GATE
        line(outX, outY, inX, outY);  //FROM OUTPUT TO MID
        line(inX, outY, inX, inY);    //FROM MID TO INPUT
      }
    }
  }


  private void drawLine_NotSameAxis_WhenOutputUpDown(final float outX, final float outY, final float inX, final float inY,
    final int inRot, final boolean isInputDotFacingSameWay, final boolean isInputDotFacingOutputGate) {
    //HERE WHEN OUTPUT IS UP/DOWN...

    if (!isInputDotFacingSameWay && isInputDotFacingOutputGate) {
      if (inRot == LogicGate.ROT_RIGHT) {
        //...BUT INPUT GATE IS LEFT/RIGHT, AND INPUT IS FURTHER RIGHT THAN OUTPUT AND FACING RIGHT
        line(outX, outY, inX, outY);   //FROM OUTPUT TO CORNER
        line(inX, outY, inX, inY);     //FROM CORNER TO INPUT
      } else {
        //...BUT INPUT GATE IS LEFT/RIGHT, AND INPUT IS FURTHER LEFT THAN OUTPUT AND FACING LEFT
        line(outX, outY, inX, outY);   //FROM OUTPUT TO CORNER
        line(inX, outY, inX, inY);     //FROM CORNER TO INPUT
      }
    } else {
      //...BUT INPUT GATE IS LEFT/RIGHT, AND INPUT IS: FURTHER RIGHT AND FACING LEFT, OR, FURTHER LEFT AND FACING RIGHT
      line(outX, outY, inX, outY);   //FROM OUTPUT TO CORNER
      line(inX, outY, inX, inY);     //FROM CORNER TO INPUT
    }
  }


  private void drawLine_IsSameAxis_WhenOutputLeftRight(final float outX, final float outY, final float inX, final float inY,
    final float midX, final float midY, final boolean isInputDotFacingSameWay, final boolean isInputGateBehindOutputGate) {
    //HERE WHEN OUTPUT & INPUT GATE IS LEFT/RIGHT...

    if (isInputDotFacingSameWay && !isInputGateBehindOutputGate) {
      //...AND FACING THE SAME DIRECTION, BUT THE INPUT GATE IS IN FRONT OF THE OUTPUT GATE
      line(outX, outY, midX, outY);  //FROM OUTPUT TO MID
      line(midX, outY, midX, inY);   //FROM MID TO MID
      line(midX, inY, inX, inY);     //FROM MID TO INPUT
    } else if (isInputDotFacingSameWay) {
      //...AND FACING THE SAME DIRECTION, BUT THE INPUT GATE IS BEHIND THE OUTPUT GATE
      line(outX, outY, outX, midY);  //FROM OUTPUT TO MID
      line(outX, midY, inX, midY);   //FROM MID TO MID
      line(inX, midY, inX, inY);     //FROM MID TO INPUT
    } else {
      if (!isInputGateBehindOutputGate) {
        //...AND FACING THE OPPOSITE DIRECTION, BUT THE INPUT GATE IS IN FRONT OF THE OUTPUT GATE
        line(outX, outY, inX, outY);  //FROM OUTPUT TO MID
        line(inX, outY, inX, inY);     //FROM MID TO INPUT
      } else {
        //...AND FACING THE OPPOSITE DIRECTION, BUT THE INPUT GATE IS BEHIND THE OUTPUT GATE
        line(outX, outY, outX, inY);  //FROM OUTPUT TO MID
        line(outX, inY, inX, inY);     //FROM MID TO INPUT
      }
    }
  }


  private void drawLine_NotSameAxis_WhenOutputLeftRight(final float outX, final float outY, final float inX, final float inY,
    final int inRot, final boolean isInputDotFacingSameWay, final boolean isInputDotFacingOutputGate) {
    //HERE WHEN OUTPUT IS LEFT/RIGHT...

    if (!isInputDotFacingSameWay && isInputDotFacingOutputGate) {
      if (inRot == LogicGate.ROT_DOWN) {
        //...BUT INPUT GATE IS UP/DOWN, AND INPUT IS LOWER THAN OUTPUT AND FACING DOWN
        line(outX, outY, outX, inY);   //FROM OUTPUT TO CORNER
        line(outX, inY, inX, inY);     //FROM CORNER TO INPUT
      } else {
        //...BUT INPUT GATE IS UP/DOWN, AND INPUT IS HIGHER THAN OUTPUT AND FACING UP
        line(outX, outY, outX, inY);   //FROM OUTPUT TO CORNER
        line(outX, inY, inX, inY);     //FROM CORNER TO INPUT
      }
    } else {
      //...BUT INPUT GATE IS UP/DOWN, AND INPUT IS: LOWER AND FACING UP, OR, HIGHER AND FACING DOWN
      line(outX, outY, outX, inY);   //FROM OUTPUT TO CORNER
      line(outX, inY, inX, inY);     //FROM CORNER TO INPUT
    }
  }



  void transferValue() {
    //SET INPUT TO THE OUTPUT
    for (LogicGate.IOButton connectedInput : allConnectedToInputs) connectedInput.inputValue = connectedOutputDot.currentOutputValue();
  }



  //CLASS END
}
