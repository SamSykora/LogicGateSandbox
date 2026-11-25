


void uiSequencer() {
  if (isAGateSelected && !neverShowSelectedMenuUI) {
    actionMenu();
    drawMenuStats();
  }

  //TOP MENU LAST, SO IT DRAWS ON TOP OF EVERYTHING
  topMenuSequencer();
}


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ UI MENU ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//q = add +1 input
//e = remove -1 input
//r = rotate
//t = toggle NOT mode
//z = delete all wires to this gates input
//x = delete all wires from this gates output

boolean neverShowSelectedMenuUI = false;

//================================================== DRAW LOOP ==================================================
float menuHeight;
final color menuColor = color(0, 180, 255, 150);
boolean isMouseInMenu = false;

void actionMenu() {
  //DRAW BACKGROUND
  noStroke();
  fill(menuColor);
  quad(0, menuHeight, width, menuHeight, width, height, 0, height);  //top-left, top-right, bottom-right, bottom-left

  //DRAW BUTTONS
  for (MenuUIButton button : allMenuButtons) button.draw();

  //FLAG IF MOUSE IS IN MENU
  if (mouseY > menuHeight) isMouseInMenu = true;
  else isMouseInMenu = false;
}


//================================================== MAKE AND INITIALIZE MENU ==================================================

int lastWindowWidth = 0, lastWindowHeight = 0;

void checkWindowResize() {
  // CHECK TO SEE IF THE WINDOW SIZE HAS NO CHANGE, IF NOT, DO NOTHING
  if (width == lastWindowWidth && height == lastWindowHeight) return;
  lastWindowWidth = width;
  lastWindowHeight = height;

  // ELSE REDETERMINE THE HEIGHT ABOVE THE BOTTOM
  menuHeight = height - 85;

  // THEN FULLY DELETE AND REMAKE THE MENU BUTTONS
  allMenuButtons.clear();
  initializeGateMenu();
}

//================================================== MAKE AND INITIALIZE MENU ==================================================


void initializeGateMenu() {
  float buttonSize = 40;
  float columnWidth = 110;  // The room for each text header, since the header text is wider than the button
  float headerSpace = 34;   // The amount room above each button for the header text
  float lineShift = 15;     // The height of about one line of text in the header

  float baseY = menuHeight + 5 + headerSpace + buttonSize/2;

  String[] labels = {"Add Input (q)", "Remove Input (e)", "Rotate (r)", "Change Type (t)", "Del All\nInput Wires (z)", "Del All\nOutput Wires (x)", "Delete\nGate (~)"};
  char[] keyActions = {'q', 'e', 'r', 't', 'z', 'x', '~'};
  int[] icons = {ICON_ADD, ICON_REMOVE, ICON_ROTATE, ICON_TYPE, ICON_DELETE, ICON_DELETE, ICON_DELETE};

  for (int i = 0; i < 7; i++) {
    float x = i * columnWidth + 100;
    float y = baseY;

    // A SINGLE LINE HEADER MOVES UP BY ONE LINE, SO ITS TEXT STARTS AT THE SAME HEIGHT AS THE FIRST LINE OF THE TWO LINE HEADERS
    if (labels[i].indexOf('\n') < 0) y -= lineShift;

    MenuUIButton mb = new MenuUIButton(x, y, buttonSize, buttonSize, labels[i], keyActions[i], icons[i]);
    allMenuButtons.add(mb);
  }

  // ---------- CLOCK SPEED BUTTONS (ONLY SHOWN WHEN A CLOCK IS SELECTED) ----------
  float speedX = 7 * columnWidth + 100;  //The most far right column
  float speedHeight = 18;
  float speedGap = 4;
  float speedOffset = (speedHeight + speedGap) / 2;  // How far each button sits above/below the center of the column

  // SINCE THE HEADER IS ONLY ON THE TOP BUTTON, THE BOTTOM ONE HAS NO HEADER. THEY ALSO DON'T HAVE A KEY SINCE ARROWS ARN'T A KEY
  allMenuButtons.add(new MenuUIButton(speedX, baseY - speedOffset, buttonSize, speedHeight, "Speed\n(^/v arrows)", ' ', ICON_SPEED_UP));
  allMenuButtons.add(new MenuUIButton(speedX, baseY + speedOffset, buttonSize, speedHeight, "", ' ', ICON_SPEED_DOWN));
  
  // ---------- CUSTOM CIRCUIT EXPORT BUTTON (ONLY SHOWN WHEN A CUSTOM CIRCUIT IS SELECTED) ----------
  // IT SHARES THE CLOCK SPEED COLUMN, SINCE A GATE CAN'T BE BOTH
  allMenuButtons.add(new MenuUIButton(speedX, baseY - lineShift, buttonSize, buttonSize, "Export", ' ', ICON_EXPORT));
}




//================================================== CLICK INTERACTION ==================================================
void checkAllMenuButtons() {
  //DO NOTHING IF THERE IS NO MENU
  if (!isAGateSelected) return;

  //FOR ALL MENU BUTTONS, DO runClick();
  for (MenuUIButton mb : allMenuButtons) mb.runClick();
}



//================================================== MENU BUTTON CLASS ==================================================


ArrayList<MenuUIButton> allMenuButtons = new ArrayList<MenuUIButton>();

// WHICH DESIGN EACH BUTTON DRAWS
final int ICON_ADD = 0, ICON_REMOVE = 1, ICON_ROTATE = 2, ICON_TYPE = 3, ICON_DELETE = 4, ICON_SPEED_UP = 5, ICON_SPEED_DOWN = 6, ICON_EXPORT = 7;

class MenuUIButton {
  float x, y;
  final float boxWidth, boxHeight;
  final String labelHeader;  //The name of this button/what it does, above the button
  final char keyAction;  //What key is this button supposed to replicate
  final int icon;  // Which design to draw on this button

  MenuUIButton(float x, float y, float boxWidth, float boxHeight, String labelHeader, char keyAction, int icon) {
    this.x = x;
    this.y = y;
    this.boxWidth = boxWidth;
    this.boxHeight = boxHeight;
    this.labelHeader = labelHeader;
    this.keyAction = keyAction;
    this.icon = icon;
  }


  void draw() {
    //THE SPEED BUTTONS ARE HIDDEN UNLESS A CLOCK IS SELECTED, AND THE EXPORT BUTTON UNLESS A CUSTOM CIRCUIT IS
    if (!isVisible()) return;

    rectMode(CENTER);
    strokeCap(SQUARE);
    strokeWeight(3);

    //---------- DRAW THE BUTTON ----------
    if (icon == ICON_ADD || icon == ICON_REMOVE) drawDotIcon();
    else if (icon == ICON_ROTATE) drawRotateIcon();
    else if (icon == ICON_TYPE) drawTypeIcon();
    else if (icon == ICON_SPEED_UP || icon == ICON_SPEED_DOWN) drawSpeedIcon();
    else if (icon == ICON_EXPORT) drawExportIcon();
    else drawDeleteIcon();

    //---------- DRAW THE HEADER ABOVE THE BUTTON ----------
    fill(255);
    textSize(12);
    textAlign(CENTER, BOTTOM);  //Bottom so one line and two line headers both sit above the button correctly
    text(labelHeader, x, y - boxHeight/2 - 4);
    textAlign(CENTER, CENTER);
  }


  // THE SPEED BUTTONS ONLY SHOW WHEN A CLOCK IS SELECTED, AND THE EXPORT BUTTON ONLY WHEN A CUSTOM CIRCUIT IS
  boolean isVisible() {
    if (icon == ICON_SPEED_UP || icon == ICON_SPEED_DOWN) return getSelectedClock() != null;
    if (icon == ICON_EXPORT) return getSelectedCircuit() != null;
    return true;
  }


  //================================================== DRAW DESIGNS ==================================================
  // ---------- SMALL BLUE RECTANGLE WITH AN UP OR DOWN ARROW ----------
  void drawSpeedIcon() {
    // DRAW THE BACKGROUND
    stroke(0, 60, 150);
    fill(0, 120, 255);
    rect(x, y, boxWidth, boxHeight);

    // WHITE ARROW HEAD
    noStroke();
    fill(255);
    float halfWidth = boxWidth * 0.2;
    float halfHeight = boxHeight * 0.25;
    // Note: Corners: bottom-left, top-middle, bottom-right
    if (icon == ICON_SPEED_UP) triangle(x - halfWidth, y + halfHeight, x + halfWidth, y + halfHeight, x, y - halfHeight);  // UP
    else triangle(x - halfWidth, y - halfHeight, x + halfWidth, y - halfHeight, x, y + halfHeight);  // DOWN
  }

  // ---------- GREY BOX WITH A GREEN UP ARROW ----------
  void drawExportIcon() {
    // DRAW THE BACKGROUND - A GREY BOX
    stroke(60);
    fill(130);
    rect(x, y, boxWidth, boxHeight);

    float headHalf = boxWidth * 0.3;      // How wide the arrows head is
    float tip = boxWidth * 0.34;          // How tall/pointy the arrows head is
    float shaftHalf = boxWidth * 0.1;     // How wide the arrows stick is
    float shaftLength = boxWidth * 0.34;  // How tall/long the arrows stick is

    // DRAW THE GREEN ARROW POINTING UP
    noStroke();
    fill(0, 220, 60);
    triangle(x - headHalf, y - 1, x + headHalf, y - 1, x, y - 1 - tip);
    rect(x, y - 1 + shaftLength/2, shaftHalf * 2, shaftLength);
  }



  // ---------- BLUE DOT WITH A PLUS OR MINUS ----------
  private void drawDotIcon() {
    // DRAW THE BACKGROUND
    stroke(0, 60, 150);
    fill(0, 120, 255);
    circle(x, y, boxWidth);

    // DRAW THE PLUS OR MINUS
    stroke(255);
    strokeWeight(4);
    float arm = boxWidth * 0.25;
    line(x - arm, y, x + arm, y);                        // Draw the minus. Which is also used for the plus
    if (icon == ICON_ADD) line(x, y - arm, x, y + arm);  // Draw the plus - the rest of it
  }


  // ---------- DARK GREEN SQUARE WITH A BRIGHT GREEN ARROW POINTING EVERY DIRECTION ----------
  private void drawRotateIcon() {
    // DRAW THE BACKGROUND
    stroke(0, 50, 20);
    fill(0, 90, 35);
    rect(x, y, boxWidth, boxHeight);

    float shaft = boxWidth * 0.22;     // Where the arrow heads start
    float tip = boxWidth * 0.38;       // Where the arrow tips end
    float headHalf = boxWidth * 0.14;  // Half of the width an arrows head

    // DRAW THE THE PLUS/CROSS
    stroke(0, 255, 90);
    strokeWeight(3);
    line(x - shaft, y, x + shaft, y);  // Left-right
    line(x, y - shaft, x, y + shaft);  // Up-down

    // DRAW ONE ARROW HEAD PER DIRECTION, TURNING 90 DEGREES EACH TIME
    noStroke();
    fill(0, 255, 90);

    pushMatrix();  // Save stuff
    translate(x, y);  //Center at the button
    for (int i = 0; i < 4; i++) {
      triangle(-headHalf, -shaft, headHalf, -shaft, 0, -tip);
      rotate(HALF_PI);
    }
    popMatrix();  // Reload that stuuf
  }


  // ---------- DARK YELLOW SQUARE WITH A BLACK QUESTION MARK ----------
  private void drawTypeIcon() {
    // DRAW THE BACKGROUND
    stroke(110, 85, 0);
    fill(170, 135, 0);
    rect(x, y, boxWidth, boxHeight);

    // DRAW THE TEXT
    fill(0);
    textAlign(CENTER, CENTER);
    textSize(boxHeight * 0.75);
    text("?", x, y - 2);
  }


  // ---------- VERY DARK RED SQUARE WITH A BRIGHT RED X ----------
  private void drawDeleteIcon() {
    // DRAW THE BACKGROUND
    stroke(35, 0, 0);
    fill(70, 0, 0);
    rect(x, y, boxWidth, boxHeight);

    // DRAW THE X
    stroke(255, 30, 30);
    strokeWeight(4);
    float arm = boxWidth * 0.25;
    line(x - arm, y - arm, x + arm, y + arm);  // Top-left to bottm-right
    line(x - arm, y + arm, x + arm, y - arm);  // Bottom-left to top-right
  }




  //================================================== ON CLICK ==================================================
  void runClick() {
    // CLOCK EXCLUSIVITY CHECK
    if (!isVisible()) return;  //A hidden button can't be clicked

    //MAKE SURE MOUSE IS IN BOUNDS OF THIS BUTTON
    if (!checkIfMouseIsInBounds()) return;

    // SPEED BUTTONS CHANGE THE SELECTED CLOCK DIRECTLY
    if (icon == ICON_SPEED_UP || icon == ICON_SPEED_DOWN) {
      Clock clock = getSelectedClock();
      if (icon == ICON_SPEED_UP) clock.changeSpeed(1);  //Increase speed
      else clock.changeSpeed(-1);  //Decrease speed
      return;
    }

    // THE EXPORT BUTTON SAVES THE SELECTED CUSTOM CIRCUIT BY ITSELF
    if (icon == ICON_EXPORT) {
      requestExport(getSelectedCircuit());
      return;
    }

    //MAKE THE BUTTON DO SOMETHING
    doControls(keyAction);
  }



  boolean checkIfMouseIsInBounds() {
    if (mouseX >= x - boxWidth/2  &&  mouseX <= x + boxWidth/2  &&  mouseY >= y - boxHeight/2  &&  mouseY <= y + boxHeight/2) {
      return true; // mouse IS inside bounds
    } else return false; // mouse is NOT inside bounds
  }
}



// RETURNS THE SELECTED GATE IF IT'S A CLOCK, OTHERWISE null
Clock getSelectedClock() {
  // FOR ALL GATES
  for (LogicGate logicGate : allLogicGates) {
    // IF A CLOCK, RETURN CLOCK
    if (logicGate.isClicked && logicGate instanceof Clock) return (Clock) logicGate;
  }
  return null;
}





// RETURNS THE SELECTED GATE IF IT'S A CUSTOM CIRCUIT, OTHERWISE null
CustomCircuit getSelectedCircuit() {
  // FOR ALL GATES
  for (LogicGate logicGate : allLogicGates) {
    // IF A CUSTOM CIRCUIT, RETURN IT
    if (logicGate.isClicked && logicGate instanceof CustomCircuit) return (CustomCircuit) logicGate;
  }
  return null;
}




// ================================================== DRAW MENU STATS ==================================================
String menuRotationStat = "";
String inputCurMaxStat = "";
String inputMinStat = "";
String modeCountStat = "";


void drawMenuStats() {
  // ---------- PICK TEXT STYLE ----------
  fill(255);
  textSize(11);

  // ---------- DRAW EACH STAT UNDER ITS BUTTON ----------
  drawStatUnderButton('q', inputCurMaxStat);        // Under "Add Input"
  drawStatUnderButton('e', "Min:" + inputMinStat);  // Under "Remove Input"
  drawStatUnderButton('r', menuRotationStat);       // Under "Rotate"
  drawStatUnderButton('t', modeCountStat);          // Under "Change Type"
}


void drawStatUnderButton(char keyAction, String statText) {
  // FOR ALL BUTTONS
  for (MenuUIButton button : allMenuButtons) {
    // IF THE KEY DOES NOT MATCH< SKIP
    if (button.keyAction != keyAction) continue;  // If not the button we're looking for, skip

    // DRAW STAT BELOW BUTTON
    textAlign(CENTER, TOP);
    text(statText, button.x, button.y + button.boxHeight/2 + 4);
    return;
  }
}






































// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ TOP MENU ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//b = toggle tick loop
//n = do next tick step (only while the tick loop is paused)
//m = do next half tick step (only while the tick loop is paused)
//f = change wire style
//k = save the circuit
//l = load a circuit


// ================================================== VARIABLES ==================================================
boolean isTopMenuOpen = false;           // Says if the menu is dropped down
boolean isAddBarOpen = false;            // Says if the gates spawning bar is showing
boolean topMenuClickInProgress = false;  // Is true the entire time holding a click in the top menu, false once released

final float tabWidth = 44, tabHeight = 24;             // The always-visible button in the top left
final float topBarTop = tabHeight, topBarHeight = 56;  // The bar that drops down right underneath the tab

ArrayList<TopMenuButton> allTopMenuButtons = new ArrayList<TopMenuButton>();
ArrayList<SpawnGateButton> allSpawnButtons = new ArrayList<SpawnGateButton>();

// WHICH DESIGN EACH TOP MENU BUTTON DRAWS
final int TOP_ICON_TAB = 0, TOP_ICON_TICK_LOOP = 1, TOP_ICON_STEP = 2, TOP_ICON_WIRE = 3, TOP_ICON_PLUS = 4, TOP_ICON_SAVE = 5, TOP_ICON_LOAD = 6, TOP_ICON_IMPORT = 7;



// ================================================== MAKE AND INITIALIZE THE TOP MENU ==================================================
void initializeTopMenu() {
  float buttonHeight = 28;
  float rowY = topBarTop + 36;  // The middle point of the menu bar, to use as the middle for the buttons

  // ---------- THE TINY TAB THAT OPENS AND CLOSES THE MENU ----------
  allTopMenuButtons.add(new TopMenuButton(tabWidth/2, tabHeight/2, tabWidth, tabHeight, "", ' ', TOP_ICON_TAB));

  // ---------- TICK LOOP BUTTONS ----------
  float tickX = 75;
  float stepSpacing = 34;  // Add a 6 pixel gap to the button height
  allTopMenuButtons.add(new TopMenuButton(tickX, rowY, 110, buttonHeight, "Tick Loop (b)", 'b', TOP_ICON_TICK_LOOP));
  allTopMenuButtons.add(new TopMenuButton(tickX, rowY + stepSpacing, 110, buttonHeight, "Next Tick (n)", 'n', TOP_ICON_STEP));
  allTopMenuButtons.add(new TopMenuButton(tickX, rowY + stepSpacing * 2, 110, buttonHeight, "Half Tick (m)", 'm', TOP_ICON_STEP));

  // ---------- WIRE STYLE ----------
  allTopMenuButtons.add(new TopMenuButton(195, rowY, buttonHeight, buttonHeight, "Wire Style (f)", 'f', TOP_ICON_WIRE));

  // ---------- PLUS (OPENS THE BAR OF GATES) ----------
  allTopMenuButtons.add(new TopMenuButton(300, rowY, buttonHeight, buttonHeight, "Add Gate", ' ', TOP_ICON_PLUS));

  // ---------- SAVE AND LOAD ----------
  allTopMenuButtons.add(new TopMenuButton(width - 100, rowY, buttonHeight, buttonHeight, "Save (k)", 'k', TOP_ICON_SAVE));
  allTopMenuButtons.add(new TopMenuButton(width - 40, rowY, buttonHeight, buttonHeight, "Load (l)", 'l', TOP_ICON_LOAD));
  allTopMenuButtons.add(new TopMenuButton(width - 170, rowY, buttonHeight, buttonHeight, "Import (i)", 'i', TOP_ICON_IMPORT));


  // ---------- THE BAR OF GATES THE PLUS OPENS ----------
  // EACH GATE HAS A NAME AND A TYPE NUMBER, WHICH spawnGate() USES (1-7 ARE THE KEYBOARD NUMBERS, 11 AND UP ARE MENU ONLY)
  String[] gateNames = {"NOT (1)", "AND (2)", "OR (3)", "XOR (4)", "BUFFER (5)", "LAMP (6)", "BUTTON (7)", "CLOCK", "SR\nLATCH", "T & D\nFLIP-FLOP", "JK\nFLIP-FLOP"};
  int[] gateTypes = {1, 2, 3, 4, 5, 6, 7, 11, 12, 13, 14};

  float gateBoxWidth = 90, gateBoxHeight = 34;
  float gateBarLeft = 140;  // Start extra right away from the tick column, that way the tick step buttons don't get in the way
  float gateBarY = topBarTop + topBarHeight + gateBoxHeight/2;  // Set it to be right under the top bar

  // MAKE ALL THE SPAWN BUTTONS
  for (int i = 0; i < gateNames.length; i++) {
    float x = gateBarLeft + gateBoxWidth/2 + i * gateBoxWidth;  // Touching/side by side
    allSpawnButtons.add(new SpawnGateButton(x, gateBarY, gateBoxWidth, gateBoxHeight, gateNames[i], gateTypes[i]));
  }
}



// ================================================== DRAW LOOP ==================================================
void topMenuSequencer() {
  // ---------- WHEN DROPPED DOWN, DRAW THE BACKGROUND BEHIND THE BUTTONS ----------
  if (isTopMenuOpen) {
    noStroke();
    fill(menuColor);
    quad(0, topBarTop, width, topBarTop, width, topBarTop + topBarHeight, 0, topBarTop + topBarHeight);
  }

  // ---------- DRAW THE BUTTONS ----------
  for (TopMenuButton button : allTopMenuButtons) button.draw(); // Each hides itself whe it shouldn't show

  // ---------- DRAW THE BAR OF GATE SPAWN BUTTONS ----------
  if (isAddBarOpen) for (SpawnGateButton button : allSpawnButtons) button.draw();
}



// ================================================== CLICK INTERACTION ==================================================

// RETURNS TRUE IF THE CLICK WAS ON THE TOP MENU, SO THE REST OF mousePressed() KNOWS TO IGNORE IT
boolean checkTopMenuClick() {
  // THE FIRST BUTTON THAT USES THE CLICK STOPS THE REST FROM CHECKING
  for (TopMenuButton button : allTopMenuButtons) if (button.runClick()) return true;
  if (isAddBarOpen) for (SpawnGateButton button : allSpawnButtons) if (button.runClick()) return true;

  // A CLICK ON EMPTY SPACE IN THE BAR IS STILL A CLICK ON THE MENU, SO NOTHING UNDER IT GETS CLICKED
  return checkMouseInTopMenu();
}


boolean checkMouseInTopMenu() {
  // THE TAB IS ALWAYS PART OF THE MENU
  if (mouseX <= tabWidth && mouseY <= tabHeight) return true;

  // THE BAR IS PART OF IT ONLY WHILE DROPPED DOWN
  if (isTopMenuOpen && mouseY <= topBarTop + topBarHeight) return true;

  // THE STEP BUTTONS HANG BELOW THE BAR, AND THE BAR OF GATES SIT UNDER IT
  for (TopMenuButton button : allTopMenuButtons) if (button.isVisible() && button.checkIfMouseIsInBounds()) return true;
  if (isAddBarOpen) for (SpawnGateButton button : allSpawnButtons) if (button.checkIfMouseIsInBounds()) return true;

  return false;
}






// ================================================== TOP MENU BUTTON CLASS ==================================================

class TopMenuButton {
  final float x, y, boxWidth, boxHeight;
  final String labelHeader;  // The name above the button (the step buttons draw it inside instead, since there's no room above them)
  final char keyAction;      // What key this button replicates
  final int icon;            // Which picture to draw on this button

  TopMenuButton(float x, float y, float boxWidth, float boxHeight, String labelHeader, char keyAction, int icon) {
    this.x = x;
    this.y = y;
    this.boxWidth = boxWidth;
    this.boxHeight = boxHeight;
    this.labelHeader = labelHeader;
    this.keyAction = keyAction;
    this.icon = icon;
  }


  void draw() {
    if (!isVisible()) return;

    rectMode(CENTER);
    strokeCap(SQUARE);
    strokeWeight(3);

    // ---------- DRAW THE BUTTON ----------
    if (icon == TOP_ICON_TAB) drawTabIcon();
    else if (icon == TOP_ICON_TICK_LOOP || icon == TOP_ICON_STEP) drawBlueRectangle();
    else if (icon == TOP_ICON_WIRE) drawWireIcon();
    else if (icon == TOP_ICON_PLUS) drawPlusIcon();
    else drawFileIcon();

    // ---------- DRAW THE HEADER ABOVE THE BUTTON ----------
    // NOTE: THE TINY TAB HAS NO HEADER, AND THE TICK STEP BUTTONS DRAW THEIRS INSIDE
    if (icon != TOP_ICON_TAB && icon != TOP_ICON_STEP) {
      fill(255);
      textSize(12);
      textAlign(CENTER, BOTTOM);
      text(labelHeader, x, y - boxHeight/2 - 4);
    }
    textAlign(CENTER, CENTER);
  }


  // ---------- BLUE BUTTON WITH A DOWN/UP ARROW ----------
  void drawTabIcon() {
    // DRAW THE BACKGROUND
    stroke(0, 60, 150);
    fill(0, 120, 255);
    rect(x, y, boxWidth, boxHeight);

    // DRAW THE ARROW POINTS INSIDE
    noStroke();
    fill(255);
    if (isTopMenuOpen) triangle(x - 8, y + 4, x + 8, y + 4, x, y - 4);  // DRAW POINTED UP WHEN OPENED
    else triangle(x - 8, y - 4, x + 8, y - 4, x, y + 4); // DRAW POINTED DOWN WHEN CLOSED
  }


  // ---------- BLUE RECTANGLE (TICK LOOP TOGGLE AND THE STEP BUTTONS) ----------
  void drawBlueRectangle() {
    stroke(0, 60, 150);
    fill(0, 120, 255);

    // SET TEXT FOR WHAT TICK BUTTONS ARE DOING
    String insideText = labelHeader;
    if (icon == TOP_ICON_TICK_LOOP) {
      if (pauseTickLoop) {
        insideText = "PAUSED";
        stroke(35, 0, 0);
        fill(70, 0, 0);
      } else {
        insideText = "RUNNING";
        stroke(0, 80, 30);
        fill(0, 150, 60);
      }
    }

    // DRAW THE BACKGROUND
    rect(x, y, boxWidth, boxHeight);

    // DRAW THE TEXT
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(12);
    text(insideText, x, y - 1);
  }


  // ---------- GREEN SQUARE WITH A ~ ----------
  void drawWireIcon() {
    // DRAW THE BACKGROUND
    stroke(0, 80, 30);
    fill(0, 150, 60);
    rect(x, y, boxWidth, boxHeight);

    // DRAW THE TEXT
    fill(0);
    textAlign(CENTER, CENTER);
    textSize(boxHeight * 0.8);
    text("~", x, y);
  }


  // ---------- BLUE BUTTON SHAPED LIKE A PLUS ----------
  void drawPlusIcon() {
    //DRAW OUTLINE
    stroke(0, 60, 150);
    strokeWeight(14);
    float arm1 = boxWidth * 0.56;
    line(x - arm1, y, x + arm1, y);
    line(x, y - arm1, x, y + arm1);

    //DRAW PLUS
    stroke(0, 120, 255);
    strokeWeight(10);
    float arm2 = getPlusArm();
    line(x - arm2, y, x + arm2, y);  // Left-right
    line(x, y - arm2, x, y + arm2);  // Up-down
  }

  float getPlusArm() {
    return boxWidth * 0.5;
  }



  // ---------- GREY BOX WITH A GREEN UP ARROW (SAVE), A RED DOWN ARROW (LOAD), OR A YELLOW DOWN ARROW (IMPORT) ----------
  void drawFileIcon() {
    // DRAW THE BACKGROUND - A GREY BOX
    stroke(60);
    fill(130);
    rect(x, y, boxWidth, boxHeight);

    float headHalf = boxWidth * 0.3;     // How wide the arrows head is
    float tip = boxWidth * 0.34;         // How tall/pointy the arrows head is
    float shaftHalf = boxWidth * 0.1;    // How wide the arrows stick is
    float shaftLength = boxWidth * 0.34; // How tall/long the arrows stick is

    noStroke();
    if (icon == TOP_ICON_SAVE) {  // SAVE
      fill(0, 220, 60);  // Green
      triangle(x - headHalf, y - 1, x + headHalf, y - 1, x, y - 1 - tip);  //Pointing up
      rect(x, y - 1 + shaftLength/2, shaftHalf * 2, shaftLength);
    } else {  // LOAD OR IMPORT
      if (icon == TOP_ICON_LOAD) fill(255, 40, 40);  // Red
      else fill(255, 220, 0);  // Yellow
      triangle(x - headHalf, y + 1, x + headHalf, y + 1, x, y + 1 + tip);  //Pointing down
      rect(x, y + 1 - shaftLength/2, shaftHalf * 2, shaftLength);
    }
  }



  // IF THE CLICK WAS USED BY/INSIDE THIS BUTTON, RETURN TRUE
  boolean runClick() {
    // IF THIS BUTTON IS NOT VISABLE OR THE MOUSE IS NOT INSIDE BOUNDS, STOP
    if (!isVisible() || !checkIfMouseIsInBounds()) return false;

    // THE TINY TAB OPENS AND CLOSES THE MENU
    if (icon == TOP_ICON_TAB) {
      isTopMenuOpen = !isTopMenuOpen;
      if (!isTopMenuOpen) isAddBarOpen = false;  // Closing the menu closes the bar of gates too
    }

    // THE PLUS OPENS AND CLOSES THE BAR OF GATE SPAWN BUTTONS
    else if (icon == TOP_ICON_PLUS) isAddBarOpen = !isAddBarOpen;

    // EVERYTHING ELSE DOES WHAT ITS KEY DOES
    else doControls(keyAction);

    return true;  // Say that this button in fact, did it's things
  }

  boolean isVisible() {
    // RETURN THE VISIBILITY STATUS OF BUTTONS
    if (icon == TOP_ICON_TAB) return true;            // The tiny tab is always there
    if (!isTopMenuOpen) return false;                 // Everything else needs the menu dropped down
    if (icon == TOP_ICON_STEP) return pauseTickLoop;  // The tick step buttons only show while paused
    return true;
  }

  boolean checkIfMouseIsInBounds() {
    if (mouseX >= x - boxWidth/2  &&  mouseX <= x + boxWidth/2  &&  mouseY >= y - boxHeight/2  &&  mouseY <= y + boxHeight/2) {
      return true; // mouse IS inside bounds
    } else return false; // mouse is NOT inside bounds
  }


  // END CLASS
}



// ================================================== SPAWN GATE BUTTON CLASS ==================================================

class SpawnGateButton {
  final float x, y, boxWidth, boxHeight;
  final String name;    // The gate's name, drawn in the center
  final int gateType;   // The number passed to spawnGate()

  SpawnGateButton(float x, float y, float boxWidth, float boxHeight, String name, int gateType) {
    this.x = x;
    this.y = y;
    this.boxWidth = boxWidth;
    this.boxHeight = boxHeight;
    this.name = name;
    this.gateType = gateType;
  }


  void draw() {
    // ---------- DRAW BACKGROUND/BODY ----------
    rectMode(CENTER);
    strokeWeight(1);
    stroke(0);
    fill(0, 180, 255);
    rect(x, y, boxWidth, boxHeight);

    // ---------- DRAW THE NAME ----------
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(13);
    text(name, x, y - 1);
  }


  // RETURNS TRUE IF THE CLICK WAS USED BY THIS BUTTON
  boolean runClick() {
    if (!checkIfMouseIsInBounds()) return false;

    spawnGate(gateType);
    return true;
  }


  boolean checkIfMouseIsInBounds() {
    if (mouseX >= x - boxWidth/2  &&  mouseX <= x + boxWidth/2  &&  mouseY >= y - boxHeight/2  &&  mouseY <= y + boxHeight/2) {
      return true; // mouse IS inside bounds
    } else return false; // mouse is NOT inside bounds
  }
  // END CLASS
}
