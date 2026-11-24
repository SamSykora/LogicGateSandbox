import java.awt.event.KeyEvent;

//CONTROLS:
//Shift + left click (on output) = make new connection/wire/line
//Shift + left click (on input) = delete connection/wire/line

//ON A SELECTED GATE, IF YOU PRESS:
//q = add +1 input
//e = remove -1 input
//r = rotate
//t = toggle NOT mode
//z = delete all wires to this gates input
//x = delete all wires from this gates output
//(if clock) up arrow = increase speed
//(if clock) down arrow = decrease speed
//(if button, lamp, or custom circuit) alt + let click = rename
//right click + hold = drag/move gate around
//~ (shift + `) = delete gate

//GLOBAL:
//b = toggle tick loop
//n = do next tick step
//m = do next half tick step
//k = save entire circuit to a file  (NOTE: The file selection menu will likely appear below every signle window or even minimized.)
//l = replace and load entire circuit from a file  (NOTE: The file selection menu will likely appear below every signle window or even minimized.)
//i = import file (won't delete everything)
//f = change wire style (from stright to using corners)
//p = toggle selected gate menu visibility
//1-7 spawn logic gate (1 = NOT, 2 = AND, 3 = OR, 4 = XOR, 5 = Buffer, 6 = Lamp, 7 = Button)
//g = combine all groups gates into a single circuit
//w, a, s, d = camera controls

//GROUP SELECT:
//Ctrl + left click and drag = make box which selects gates to be grouped
//Right click + hold on any gate in the group = move the whole group



//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Mouse Controls ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//void mouseClicked() {}
//void mousePressed() {}
//void mouseMoved() {}
//void mouseDragged() {}
//void mouseWheel(MouseEvent event) {}


void mousePressed() {
  // CLICK THE TOP MENU FIRST, AND IF CLICK, CLICK NOTHING ELSE
  //---------- TOP MENU ----------
  //CLEAR THE FLAG FIRST, SO A NEW PRESS CAN NEVER INHERIT THE LAST ONE'S
  topMenuClickInProgress = false;

  //ANY MOUSE BUTTON PRESSED ON THE TOP MENU OR THE BAR OF GATES BELONGS TO THE MENU, SO NOTHING UNDER IT CAN BE CLICKED
  if (checkMouseInTopMenu()) {
    topMenuClickInProgress = true;
    if (mouseButton == LEFT) checkTopMenuClick();  //Only a left click presses the menu's buttons
    return;
  }



  // ---------- GROUP SELECTION (WHITE BORDER) ----------
  // ON RIGHT CLICK, IF CLICKING ONE OF THE GATES IN THE GROUP, THEN MOVE THE GROUP. OTHERWISE, DO THE NORMAL SINGLE GATE MOVE.
  if (mouseButton == RIGHT) {
    startGroupMove();
    if (!isMovingGroup) setGateToMoveWhenClicked();  // Don't move the yellow border when you are moving the group
  }
  // ON CTRL + LEFT CLICK, START DRAWING THE SELECTION BOX
  if (mouseButton == LEFT && isControlDown) startBoxSelect();
  // PREFORM NO CLICK ACTIONS WHEN GROUP SELECTION IS ACTIVE
  if (isControlDown) return;


  //---------- BUTTONS ----------
  if (mouseButton == LEFT && !isShiftDown) {
    clickBodies();
    checkAllMenuButtons();
  }


  //---------- CONNECTIONS ----------
  if (mouseButton == LEFT && isShiftDown) {
    removeConnectionUsingInput();
    startConnection();
  }
}

void mouseReleased() {
  // IF THE PRESS WAS USED BY THE TOP MENU, THEN THERE'S NO DRAG OR SELECTION TO FINISH
  if (topMenuClickInProgress) {
    topMenuClickInProgress = false;
    return;
  }


  // ---------- GROUP SELECTION (WHITE BORDER) ----------
  // FINISH THE SELECTION BOX
  if (isBoxSelecting && mouseButton == LEFT) {
    finishBoxSelect();
    return;
  }

  // FINISH MOVING THE GROUP
  if (isMovingGroup && mouseButton == RIGHT) {
    isMovingGroup = false;
    return;
  }

  //---------- SELECT GATE (YELLOW BORDER) ----------
  selectGateWhenClickReleased();
}




//================================================== Click Control Action ==================================================

void clickBodies() {
  //FOR ALL GATES
  for (LogicGate logicGate : allLogicGates) {
    //REQUIRE IT TO BE A BUTTON, LAMP, OR A CUSTOM CIRCUIT
    if (!(logicGate instanceof Button) && !(logicGate instanceof Lamp) && !(logicGate instanceof CustomCircuit)) continue;

    //IF THE MOUSE IS ON THIS GATE'S BODY, TELL IT IT GOT CLICKED
    if (logicGate.checkIfMouseIsInBounds()) {
      logicGate.onLeftClick();
      break;  //Stop since you found what the mouse was in
    }
  }
}



//================================================== Select Gate & What To Move ==================================================

void setGateToMoveWhenClicked() {
  //CAN'T MOVE ANYTHING IF THERE IS NOTHING SELECTED
  if (!isAGateSelected) return;

  boolean hasAssignedOne = false;

  //FOR ALL GATES
  for (LogicGate logicGate : allLogicGates) {

    //IF MOUSE NOT IN BOUNDS OR IT'S NOT ALREADY CLICKED, THEN RESET AND SKIP
    if (!logicGate.isClicked || !logicGate.checkIfMouseIsInBounds()) {
      logicGate.isBeingMoved = false;
      continue;
    }

    if (hasAssignedOne) continue;

    //ALREADY CLICKED AND NOW CLICKED AGAIN, SO MOVE IT
    logicGate.isBeingMoved = true;
    hasAssignedOne = true;
  }
}


boolean isAGateSelected = false;

void selectGateWhenClickReleased() {
  //DON'T DO ANYTHING (SELECT/DESELECT) IF THE MOUSE IN THE MENU WHEN IT CLICKED
  if (isMouseInMenu) return;

  //THE GATE THAT WILL END UP SELECTED
  LogicGate selectedGate = null;

  //FOR ALL GATES
  for (LogicGate logicGate : allLogicGates) {

    //IF THIS GATE WAS JUST BEING DRAGGED IT SHOULD ALWAYS WIN, SO ALWAYS MAKE THE ONE THAT WAS BEING DRAGGED THE SELECTED GATE
    if (logicGate.isBeingMoved) selectedGate = logicGate;
    //HOWEVER, PICK THE FIRST GATE IN BOUNDS ONE TIME, JUST IN CASE THE GATE THAT WAS BEING DRAGGED IN NOT FOUND
    else if (selectedGate == null && logicGate.isMouseOverGateOrDots()) selectedGate = logicGate;

    //RESET EVERY GATE (THIS HAPPENS AFTER WE LOOKED AT isBeingMoved ABOVE)
    logicGate.isBeingMoved = false;
    logicGate.isClicked = false;
  }

  //FOR WHATEVER GATE THAT GOT SELECTED, EITHER FIRST IN BOUNDS OR THE ONE JUST DRAGGED, SET AS CLICKED
  if (selectedGate != null) {
    selectedGate.isClicked = true;
    isAGateSelected = true;
  } else isAGateSelected = false;
}



// ================================================== Group Select & Move ==================================================

boolean isBoxSelecting = false, isMovingGroup = false;  // Says if the box is being drawn or a group is being dragged
float boxStartX, boxStartY;                             // Says where the mouse was when the box started (the other corner is where the mouse is)
float lastGroupMouseX, lastGroupMouseY;                 // Says where the mouse was last frame so we can measure how far it moved

// CALLED ON ctrl + left click TO SAVE WHERE THE BOX STARTED
void startBoxSelect() {
  isBoxSelecting = true; // Say that we are now drawing a selection box for drawSelectionBox()
  boxStartX = mouseX; // Remember the starting x of the box
  boxStartY = mouseY; // Remember the starting y of the box
}

// CALLED ON RELEASE OF THE CLICK, AS NOW THE FULL SELECTION BOX HAS BEEN MADE
void finishBoxSelect() {
  isBoxSelecting = false;   // Say that we are no longer drawing the selection box

  // GET THE END X & Y OF THE BOX (using min/max so dragging right-to-left or down-to-up works)
  float boxLeft = min(boxStartX, mouseX), boxRight = max(boxStartX, mouseX);
  float boxTop = min(boxStartY, mouseY), boxBottom = max(boxStartY, mouseY);

  // FOR ALL GATES
  for (LogicGate logicGate : allLogicGates) {
    // CHECK IF ANY PART OF THE BOX INTERSECTS THEM, true = INTERSECTION
    boolean overlapsX = (logicGate.x + logicGate.boxWidth/2 >= boxLeft  &&  logicGate.x - logicGate.boxWidth/2 <= boxRight);    // Left-right span
    boolean overlapsY = (logicGate.y + logicGate.boxHeight/2 >= boxTop  &&  logicGate.y - logicGate.boxHeight/2 <= boxBottom);  // Top-bottom span
    // IF BOTH AXES OVERLAP, MARK IT AS PART OF THE GROUP
    if (overlapsX && overlapsY) logicGate.isInGroup = true;
  }
}

// CALLED ON right click TO MOVE ALL THE GROUPED GATES
void startGroupMove() {
  // FOR ALL GATES
  for (LogicGate logicGate : allLogicGates) {
    // IF ITS IN THE GROUP AND THE MOUSE IS IN BOUNDS
    if (logicGate.isInGroup && logicGate.checkIfMouseIsInBounds()) {
      // THEN SAY YOU ARE MOVING THE WHOLE GROUP
      isMovingGroup = true;
      // AND SAVE THE MOUSE POSITION AS THE STARTING POINT TO MEASURE MOVEMENT FROM
      lastGroupMouseX = mouseX;
      lastGroupMouseY = mouseY;
      return; // Stop looking as one is enough
    }
  }
}

// CALLED ON EVERY FRAME FROM DRAW, THIS SHIFTS THE WHOLE GROUP BY HOWEVER FAR THE MOUSE MOVED SINCE LAST FRAME
void moveGroup() {
  // DO NOTHING IF WE ARE NOT MOVING THE GROUP
  if (!isMovingGroup) return;

  // HOW FAR THE MOUSE MOVED SINCE LAST FRAME
  float dx = mouseX - lastGroupMouseX;  // Horizontally
  float dy = mouseY - lastGroupMouseY;  // Vertically
  // UPDATE THE POSISTION TO MEASURE FROM
  lastGroupMouseX = mouseX;
  lastGroupMouseY = mouseY;

  // SHIFT EVERY GROUPED GATE BY THE SAME AMOUNT
  for (LogicGate logicGate : allLogicGates) if (logicGate.isInGroup) logicGate.moveBy(dx, dy);
}

void drawSelectionBox() {
  // ONLY DRAW THE SELECTION BOX WHEN WE ARE MARKING A SELECTION
  if (!isBoxSelecting) return;

  pushStyle();  // Save the current drawing settings

  rectMode(CORNERS);
  strokeWeight(1);
  stroke(255);
  fill(255, 255, 255, 40);
  rect(boxStartX, boxStartY, mouseX, mouseY);  // Draw from where the drag started to where the mouse is now

  popStyle();  // Restore/load the saved settings
}

void clearGroupSelection() {
  // REMOVE EVERY GATE FROM THE GROUP
  for (LogicGate logicGate : allLogicGates) logicGate.isInGroup = false;

  // STOP ANY DRAG THAT WAS IN PROGRESS
  isMovingGroup = false;
  isBoxSelecting = false;
}




















//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Keyboard Controls ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

boolean isControlDown = false, isAltDown = false, isShiftDown = false;

void keyPressed() {
  //DETECT BUTTONS BEING HELD
  updateIsHeld();

  doControls(key);
}

void keyReleased() {
  updateNotHeld();
  if (keyCode == CONTROL) clearGroupSelection();

  if (keyCode == SHIFT) endConnectionSetting();
}






void updateIsHeld() {
  if (keyCode == CONTROL) isControlDown = true;
  if (keyCode == ALT) isAltDown = true;
  if (keyCode == SHIFT) isShiftDown = true;

  if (key == 'w' || key == 'W') isWPressed = true;
  if (key == 's' || key == 'S') isSPressed = true;
  if (key == 'a' || key == 'A') isAPressed = true;
  if (key == 'd' || key == 'D') isDPressed = true;
}

void updateNotHeld() {
  if (keyCode == CONTROL) isControlDown = false;
  if (keyCode == ALT) isAltDown = false;
  if (keyCode == SHIFT) isShiftDown = false;

  if (key == 'w' || key == 'W') isWPressed = false;
  if (key == 's' || key == 'S') isSPressed = false;
  if (key == 'a' || key == 'A') isAPressed = false;
  if (key == 'd' || key == 'D') isDPressed = false;
}







void doControls(char k) {
  //---------- SPECIFIC GATE CONTROLS ----------
  if (isAGateSelected) for (LogicGate logicGate : allLogicGates) if (logicGate.isClicked) {

    //ADD INPUT
    if (k == 'q' || k == 'Q') {
      logicGate.addInput();
      break;
    }

    //REMOVE INPUT
    if (k == 'e' || k == 'E') {
      logicGate.removeInput();
      break;
    }

    //ROTATE
    if (k == 'r' || k == 'R') {
      logicGate.rotation--;
      if (logicGate.rotation < 0) logicGate.rotation = 3;
      break;
    }

    //TOGGLE TYPE
    if (k == 't' || k == 'T') {
      logicGate.changeType();
      break;
    }

    //REMOVE ALL CONNECTIONS TO INPUTS
    if (k == 'z' || k == 'Z') {
      removeAllInputConnections(logicGate);
      break;
    }

    //REMOVE ALL CONNECTIONS FROM OUTPUT
    if (k == 'x' || k == 'X') {
      removeAllOutputConnections(logicGate);
      break;
    }
    //CHANGE CLOCK SPEED - USING UP/DOWN ARROW KEYS
    if (k == CODED && (keyCode == UP || keyCode == DOWN)) {
      if (logicGate instanceof Clock) {
        Clock clock = (Clock) logicGate;
        if (keyCode == UP) clock.changeSpeed(1);  //Increase speed
        else clock.changeSpeed(-1);  //Decrease speed
      }
      break;
    }
    //DELETE GATE
    if (k == '~') {
      deleteGate(logicGate);
      return;
    }
  }


  //---------- GLOBAL CONTROLS ----------
  //TOGGLE pauseTickLoop
  if (k == 'b' || k == 'B') {
    pauseTickLoop = !pauseTickLoop;
    if (pauseTickLoop == false) doneTickFirstHalf = false;
    return;
  }
  //DO NEXT TICK STEP
  if (k == 'n' || k == 'N') {
    if (pauseTickLoop) doNextTick = true;
    return;
  }
  //DO NEXT TICK STEP
  if (k == 'm' || k == 'M') {
    if (pauseTickLoop) doNextHalfTick = true;
    return;
  }

  //SAVE FILE
  if (k == 'k' || k == 'K') {
    requestSave();
    return;
  }
  //LOAD FILE
  if (k == 'l' || k == 'L') {
    requestLoad();
    return;
  }
  //IMPORT FILE
  if (k == 'i' || k == 'I') {
    requestImport();
    return;
  }
  //COPY GATE
  if (k == 'c' || k == 'C') {
    return;
  }
  //PASTE GATE
  if (k == 'v' || k == 'V') {
    return;
  }
  //CHANGE WIRE STYLE
  if (k == 'f' || k == 'F') {
    useWireRightAngleDrawing = !useWireRightAngleDrawing;
    return;
  }
  //SPAWN GATE
  if (k >= '1' && k <= '7') {
    spawnGate(k - '0');
  }
  //TOGGLE SELECTED GATE MENU VISIBILITY
  if (k == 'p' || k == 'P') {
    neverShowSelectedMenuUI = !neverShowSelectedMenuUI;
    return;
  }
  //MERGE GROUPED GATED INTO CIRCUIT
  if (keyCode == 'g' || keyCode == 'G') {
    mergeIntoCircuit();
    return;
  }
}

//if (key == 'c' || key == 'C')
//if (key == BACKSPACE)
//if (key == 'x' || key == 'X')





//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Change Name ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


  void enterNewName(LogicGate logicGate) {
    String newName = askForName(logicGate.gateType);
    if (newName != null) logicGate.gateType = newName; // null = they hit X/Cancel, so do nothing
    isAltDown = false;
  }

  private String askForName(String currentName) {
    String message = "Enter a new name:";

    while (true) {
      // MAKE WINDOW
      String input = promptOnTop(message, currentName);

      // IF NOTHING, DO NOTHING
      if (input == null) return null;  // X or Cancel

      // REMOVE WHITESPACE
      input = input.trim();

      // BAISC CHECKS
      if (input.length() == 0) {
        message = "Name can't be empty. Try again:";
      } else if (input.length() > 25) {
        message = "Max 25 characters. Try again:";
      } else if (!input.matches("[A-Za-z0-9 _-]+")) {
        message = "Letters, numbers, spaces, - and _ only. Try again:";
      } else {
        return input;
      }
    }
  }

  private String promptOnTop(String message, String initial) {
    // CREATE POP-UP: message / icon / buttons
    JOptionPane pane = new JOptionPane(message,  JOptionPane.QUESTION_MESSAGE,  JOptionPane.OK_CANCEL_OPTION);
    // ADD TEXT FIELD
    pane.setWantsInput(true);
    pane.setInitialSelectionValue(initial);
    // PUT POP-UP IN WINDOW
    JDialog dialog = pane.createDialog("Rename Button");
    // FORCE IT TO THE TOP
    dialog.setAlwaysOnTop(true);
    // SHOW IT SO IT CAN EVEN BE SEEN
    dialog.setVisible(true);
    // MAGIC IDK
    dialog.dispose();

    // GET WHAT BUTTON WAS PRESSED
    Object value = pane.getValue();
    // IF X OR CANCEL REPORT NULL
    if (!(value instanceof Integer) || ((Integer) value).intValue() != JOptionPane.OK_OPTION) return null;  // X or Cancel
    // ELSE PRESSED OKAY SO RETURN INPUTED TEXT
    return (String) pane.getInputValue();
  }



//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Camera Controls ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void cameraSequencer() {
  moveCameraUpdate();
  drawOriginLines();
  drawBoundsWall();
}



//================================================== MOVE CAMERA ==================================================
boolean isWPressed = false, isAPressed = false, isSPressed = false, isDPressed = false;

float cameraOriginX, cameraOriginY;  //The position before any movement at the start of the sketch
float velocityX, velocityY;          //How much to be moving the camera by each frame

final float epsilon = 0.0001f;       //Floating point cutoff
final float acceleration = 1.5f;     //How much to be speeding up the movement of the camera
final float friction = 0.85f;        //Higher = slippery, lower = grippyer. How much to be slowing down the movement of the camera each frame
final int maxCameraSpeed = 40;

int maxCameraTravelDistance;

void moveCameraUpdate() {
  //INCREASE SPEED
  if (isWPressed) velocityY += acceleration;
  if (isAPressed) velocityX += acceleration;
  if (isSPressed) velocityY -= acceleration;
  if (isDPressed) velocityX -= acceleration;

  //APPLY FRICTION
  if (!isAPressed && !isDPressed) velocityX *= friction;
  if (!isWPressed && !isSPressed) velocityY *= friction;

  //RESTRICT TO 0 WITHIN DECIMAL THREADHOLD
  if (abs(velocityX) < epsilon) velocityX = 0;
  if (abs(velocityY) < epsilon) velocityY = 0;

  //APPLY UPPER BOUNDS ON SPEED
  velocityX = constrain(velocityX, -maxCameraSpeed, maxCameraSpeed);
  velocityY = constrain(velocityY, -maxCameraSpeed, maxCameraSpeed);

  forceCamereaIntoBounds();

  //MOVE POSITION
  for (LogicGate logicGate : allLogicGates) logicGate.moveBy(velocityX, velocityY);
  cameraOriginX += velocityX;
  cameraOriginY += velocityY;
}



//================================================== RESTRICT CAMERA INTO BOUNDS ==================================================
void forceCamereaIntoBounds() {
  //LEFT BOUND
  if (cameraOriginX > maxCameraTravelDistance) {
    float discrepancyToMove = cameraOriginX - maxCameraTravelDistance;
    for (LogicGate logicGate : allLogicGates) logicGate.moveBy(-discrepancyToMove, 0);
    cameraOriginX = maxCameraTravelDistance;
    velocityX = 0;
  }

  //RIGHT BOUND
  else if (cameraOriginX < -maxCameraTravelDistance) {
    float discrepancyToMove = cameraOriginX + maxCameraTravelDistance;
    for (LogicGate logicGate : allLogicGates) logicGate.moveBy(-discrepancyToMove, 0);
    cameraOriginX = -maxCameraTravelDistance;
    velocityX = 0;
  }

  //TOP BOUND
  if (cameraOriginY > maxCameraTravelDistance) {
    float discrepancyToMove = cameraOriginY - maxCameraTravelDistance;
    for (LogicGate logicGate : allLogicGates) logicGate.moveBy(0, -discrepancyToMove);
    cameraOriginY = maxCameraTravelDistance;
    velocityY = 0;
  }

  //BOTTOM BOUND
  else if (cameraOriginY < -maxCameraTravelDistance) {
    float discrepancyToMove = cameraOriginY + maxCameraTravelDistance;
    for (LogicGate logicGate : allLogicGates) logicGate.moveBy(0, -discrepancyToMove);
    cameraOriginY = -maxCameraTravelDistance;
    velocityY = 0;
  }
}



//================================================== DRAW BEARING LINES ==================================================
float startWidth = 0, startHeight = 0;  //The window size at the start, which is the size of the box

void drawOriginLines() {
  //REMEMBER THE WINDOW SIZE ON THE VERY FIRST FRAME
  if (startWidth == 0) {
    startWidth = width;
    startHeight = height;
  }

  //WHERE EACH LINE IS (THE EDGES OF THE START SCREEN, SHIFTED BY HOW FAR THE CAMERA HAS TRAVELED)
  //ROUNDED AND +0.5 SO THE 1 PIXEL LINE STAYS SHARP WHILE MOVING
  float leftX = round(cameraOriginX) + 0.5;
  float rightX = round(cameraOriginX + startWidth - 1) + 0.5;
  float topY = round(cameraOriginY) + 0.5;
  float bottomY = round(cameraOriginY + startHeight - 1) + 0.5;

  //DRAW THE LINES ACROSS THE WHOLE WINDOW
  stroke(255);
  strokeWeight(1);
  line(leftX, 0, leftX, height);
  line(rightX, 0, rightX, height);
  line(0, topY, width, topY);
  line(0, bottomY, width, bottomY);
}



//================================================== DRAW RED BOUNDS ==================================================
final color wallColor = color(255, 0, 0);
final float wallThickness = 5;

void drawBoundsWall() {
  //WHERE EACH WALL IS (THE WINDOW EDGE WHEN THE CAMERA IS AT ITS LIMIT, SHIFTED BY HOW FAR THE CAMERA HAS TRAVELED)
  float leftX =   cameraOriginX - maxCameraTravelDistance;
  float rightX =  cameraOriginX + width + maxCameraTravelDistance;
  float topY =    cameraOriginY - maxCameraTravelDistance;
  float bottomY = cameraOriginY + height + maxCameraTravelDistance;

  //DRAW THE BORDER, PULLED IN BY HALF THE THICKNESS SO ALL 5 PIXELS STAY INSIDE THE AREA
  rectMode(CORNERS);
  noFill();
  stroke(wallColor);
  strokeWeight(wallThickness);
  rect(leftX + wallThickness/2, topY + wallThickness/2, rightX - wallThickness/2, bottomY - wallThickness/2);
}
