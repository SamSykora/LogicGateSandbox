// ================================================== SAVE / LOAD ==================================================
File pendingSave = null, pendingExport = null, pendingLoad = null, pendingImport = null;
CustomCircuit circuitToExport = null;  // The circuit that was selected when the export button was clicked


void runSaveAndLoad() {
  if (pendingSave != null) {
    writeBoard(pendingSave);
    pendingSave = null;
  }
  if (pendingExport != null) {
    writeCircuit(pendingExport, circuitToExport);
    pendingExport = null;
    circuitToExport = null;
  }
  if (pendingLoad != null) {
    readFile(pendingLoad, false);
    pendingLoad = null;
  }
  if (pendingImport != null) {
    readFile(pendingImport, true);
    pendingImport = null;
  }
}


void requestSave() {
  // Opens a file dialog so the user can select where the file should go
  selectOutput("Save board as...", "saveChosen");  // Calls saveChosen() and passes the file location into the method after the user selected location
}
void saveChosen(File f) {
  if (f != null) pendingSave = f;  // Save the location to save the file
}


void requestExport(CustomCircuit circuit) {
  // REMEMBER THE CIRCUIT NOW, SINCE THE SELECTION CAN CHANGE WHILE THE DIALOG IS OPEN
  circuitToExport = circuit;
  selectOutput("Export custom circuit as...", "exportChosen");
}
void exportChosen(File f) {
  if (f != null) pendingExport = f;  // Save the location to export the circuit to
}


void requestLoad() {
  // Opens a file dialog so the user can select what file to load into the sketch
  selectInput("Open a board file...", "loadChosen");  // Calls loadChosen() and passes the file location into the method after the user selected location
}
void loadChosen(File f) {
  if (f != null) pendingLoad = f;  // Save the location of the file to load
}


void requestImport() {
  selectInput("Import a board or custom circuit...", "importChosen");
}
void importChosen(File f) {
  if (f != null) pendingImport = f;  // Save the location of the file to import
}



// ================================================== Helpers ==================================================

String typeOf(LogicGate g) {
  if (g instanceof NotGate) return "NOT";
  if (g instanceof AndGate) return "AND";
  if (g instanceof OrGate)  return "OR";
  if (g instanceof XorGate) return "XOR";
  if (g instanceof BufferGate) return "BUFFER";

  if (g instanceof Lamp) return "LAMP";
  if (g instanceof Button) return "BUTTON";
  if (g instanceof Clock)   return "CLOCK";

  if (g instanceof SRCircuit) return "SR";
  if (g instanceof TDFlipFlop) return "DT";
  if (g instanceof JKFlipFlop) return "JK";

  if (g instanceof CustomCircuit) return "CUSTOM";
  return null;
}


LogicGate makeGate(String type, int x, int y) {
  if (type.equals("NOT")) return new NotGate(x, y);
  if (type.equals("AND")) return new AndGate(x, y);
  if (type.equals("OR"))  return new OrGate(x, y);
  if (type.equals("XOR")) return new XorGate(x, y);
  if (type.equals("BUFFER")) return new BufferGate(x, y);

  if (type.equals("LAMP")) return new Lamp(x, y);
  if (type.equals("BUTTON")) return new Button(x, y);
  if (type.equals("CLOCK")) return new Clock(x, y);

  if (type.equals("SR")) return new SRCircuit(x, y);
  if (type.equals("DT")) return new TDFlipFlop(x, y);
  if (type.equals("JK")) return new JKFlipFlop(x, y);
  return null;
}


// MAKES A CUSTOM CIRCUIT FROM ITS SAVED JSON, BY FIRST MAKING THE GATES INSIDE IT
CustomCircuit makeCircuit(JSONObject gj) {
  if (!gj.hasKey("innerGates")) return null;  // Nothing inside it, so it can't be made
  ArrayList<LogicGate> innerGates = buildGates(gj.getJSONArray("innerGates"));

  // COUNT THE BUTTONS AND LAMPS INSIDE, THE SAME WAY MERGING DOES
  int inputCount = 0, outputCount = 0;
  for (LogicGate logicGate : innerGates) {
    if (logicGate instanceof Button) inputCount++;
    else if (logicGate instanceof Lamp) outputCount++;
  }

  return new CustomCircuit(innerGates, inputCount, outputCount, gj.getInt("x"), gj.getInt("y"));
}


// THE SR, D/T, AND JK CIRCUITS REMEMBER A BIT. IT HAS TO BE PUT BACK ON LOAD, OR THEY WOULD ALL COME BACK OFF
void restoreMemory(LogicGate g, boolean storedBit) {
  // SR CIRCUIT
  if (g instanceof SRCircuit) {
    SRCircuit sr = (SRCircuit) g;
    sr.persistantOutput = storedBit;
    if (sr.clockInput != null) sr.lastClock = sr.clockInput.inputValue;  // So a clock that's already on doesn't count as a new rising edge
  }

  // T & D FLIP-FLOP
  else if (g instanceof TDFlipFlop) {
    TDFlipFlop td = (TDFlipFlop) g;
    td.persistantOutput = storedBit;
    td.lastClock = td.clockInput.inputValue;
  }

  // JK FLIP-FLOP
  else if (g instanceof JKFlipFlop) {
    JKFlipFlop jk = (JKFlipFlop) g;
    jk.persistantOutput = storedBit;
    jk.lastClock = jk.clockInput.inputValue;
  }

  // THE OUTPUT ALWAYS MATCHES THE STORED BIT
  g.outputResult = storedBit;
}



// ================================================== Write & Make A File ==================================================

// SAVE THE WHOLE BOARD, CUSTOM CIRCUITS INCLUDED
void writeBoard(File file) {
  // ---------- WRAP EVERYTHING UP INTO ONE OBJECT ----------
  JSONObject root = new JSONObject();     // The json file that holds the list of all gates and extra info
  root.setInt("version", 1);              // So the format can change later without breaking old saves
  root.setString("importType", "board");  // Says whether this saved file is a entire board save or only single a circuit saved
  root.setJSONArray("gates", writeGates(allLogicGates));  // Add the list of gates to the main json file

  writeFile(root, file);
}


// SAVE ONLY ONE CUSTOM CIRCUIT
void writeCircuit(File file, CustomCircuit circuit) {
  // PUT THE CIRCUIT IN A LIST BY ITSELF, SO IT SAVES THE SAME WAY A BOARD DOES
  ArrayList<LogicGate> circuitOnly = new ArrayList<LogicGate>();
  circuitOnly.add(circuit);  // Wires to gates outside the circuit are skipped, since those gates aren't in this list

  JSONObject root = new JSONObject();
  root.setInt("version", 1);
  root.setString("importType", "customcircuit");  // Says this file is a single custom circuit
  root.setJSONArray("gates", writeGates(circuitOnly));

  writeFile(root, file);
}


void writeFile(JSONObject root, File file) {
  // MAKE SURE THE FILE NAME ENDS IN .json, THEN WRITE IT TO DISK
  String path = file.getAbsolutePath();
  if (!path.toLowerCase().endsWith(".json")) path += ".json";
  saveJSONObject(root, path);
}


// TURNS A LIST OF GATES INTO JSON. IT CALLS ITSELF FOR THE GATES INSIDE A CUSTOM CIRCUIT
JSONArray writeGates(ArrayList<LogicGate> gates) {
  ArrayList<LogicGate> savedGates = new ArrayList<LogicGate>();  // The list of all savable gates
  for (LogicGate g : gates) if (typeOf(g) != null) savedGates.add(g);  // As long as an entry in the main list isn't null, save it to this list

  JSONArray gatesJson = new JSONArray();  // This holds all the gates json

  // FOR ALL GATES
  for (LogicGate g : savedGates) {
    // ---------- SAVE THE BASICS OF THIS GATE ----------
    JSONObject gj = new JSONObject();
    gj.setString("type", typeOf(g));  // What kind of gate it was
    gj.setInt("x", (int) g.x);
    gj.setInt("y", (int) g.y);
    gj.setInt("rotation", g.rotation);

    // ---------- SAVE THE GATES INSIDE A CUSTOM CIRCUIT ----------
    // THEIR WIRE NUMBERS COUNT FROM THE START OF THEIR OWN LIST
    if (g instanceof CustomCircuit) gj.setJSONArray("innerGates", writeGates(((CustomCircuit) g).gatesGrouped));

    // ---------- SAVE THE NAME OF THE GATES THAT CAN BE RENAMED ----------
    if (g instanceof Button || g instanceof Lamp || g instanceof CustomCircuit) gj.setString("gateType", g.gateType);

    // ---------- SAVE WHICH TYPE IT IS ----------
    // THIS IS HOW MANY TIMES changeType() HAS TO BE CALLED ON A BRAND NEW GATE TO GET IT BACK TO THIS TYPE
    // MOST GATES HAVE TWO TYPES (0 OR 1 PRESSES), BUT THE SR CIRCUIT HAS THREE (0, 1, OR 2 PRESSES)
    int typePresses = 0;
    if (g instanceof SRCircuit) typePresses = ((SRCircuit) g).mode;
    else if (g.changeType) typePresses = 1;
    gj.setInt("typePresses", typePresses);

    // ---------- SAVE THE REMEMBERED BIT OF THE SR, D/T, AND JK CIRCUITS ----------
    if (g instanceof SequentialLogic) gj.setBoolean("storedBit", g.outputResult);

    // ---------- SAVE EACH INPUT'S TRUE/FALSE VALUE ----------
    // THE LENGTH OF THIS LIST ALSO TELLS THE LOADER HOW MANY INPUTS THE GATE HAD
    JSONArray inputValues = new JSONArray();  // Make array for the inputValues for this gate
    for (LogicGate.IOButton inp : g.inputs) inputValues.append(inp.inputValue);  // Store each inputValue in said array
    gj.setJSONArray("inputs", inputValues);  // Add this array to the main gate json

    // ---------- SAVE EVERY WIRE COMING OUT OF THIS GATE'S OUTPUTS ----------
    // A WIRE IS SAVED AS THREE NUMBERS: WHICH OUTPUT, WHICH GATE, WHICH INPUT. (BECAUSE OBJECT REFERENCES DON'T EXIST ONCE THE PROGRAM CLOSES)
    JSONArray wires = new JSONArray();  // Make an array for all the connections this gates outputs have

    // FOR ALL OUTPUT DOTS
    for (int outIndex = 0; outIndex < g.outputs.size(); outIndex++) {
      Connection con = g.outputs.get(outIndex).outputConnection;
      if (con == null) continue;  // This output has no wires, so skip

      // FOR EVERY INPUT THIS OUTPUT IS CONNECTED TO
      for (LogicGate.IOButton target : con.allConnectedToInputs) {
        // FIND THE GATE THAT INPUT BELONGS TO, THEN LOOK UP ITS POSITION IN THE LIST AND IN ITS OWN INPUTS
        LogicGate targetGate = target.getLogicGateObject();  // Get the gate that input is part of
        int gateIndex  = savedGates.indexOf(targetGate);     // Get the index in the list that gate is at...
        int inputIndex = targetGate.inputs.indexOf(target);  // ...And likewise get the index - in the input list, that's in that gate - for where that input is at
        if (gateIndex < 0 || inputIndex < 0) continue;       // Skips wires to deleted inputs, or to gates that weren't saved

        // STORE THE THREE NUMBERS
        JSONObject w = new JSONObject();
        w.setInt("output", outIndex);
        w.setInt("gate", gateIndex);
        w.setInt("input", inputIndex);
        wires.append(w);  // Save which output, gate, and input the wire went to
      }
    }
    gj.setJSONArray("wires", wires);

    // SAVING THIS GATE IS FINISHED, ADD ITS JSON TO THE LIST
    gatesJson.append(gj);
  }

  return gatesJson;
}



// ================================================== Read & Make From File ==================================================

// isImporting FALSE = LOAD (WIPES THE BOARD), TRUE = IMPORT (ADDS TO THE BOARD)
void readFile(File file, boolean isImporting) {
  // OPEN THE FILE AND GET THE MAIN OBJECT
  JSONObject fileJson = loadJSONObject(file.getAbsolutePath());
  String importType = fileJson.getString("importType", "");

  // IF THE FILE IS NOT A BOARD OR A CUSTOM CIRCUIT FILE, DO NOTHING
  if (!importType.equals("board") && !importType.equals("customcircuit")) {
    System.err.println("[WARNING]: IMPORT FAILED! Invaild saved file! File \"importType\" is incorrect or not present.");
    return;
  }

  // MAKE ALL THE GATES IN THE FILE
  ArrayList<LogicGate> loadedGates = buildGates(fileJson.getJSONArray("gates"));

  // A CUSTOM CIRCUIT FILE HAS TO HAVE A CUSTOM CIRCUIT IN IT
  CustomCircuit circuit = null;
  if (importType.equals("customcircuit")) {
    if (loadedGates.size() == 0 || !(loadedGates.get(0) instanceof CustomCircuit)) {
      System.err.println("[WARNING]: IMPORT FAILED! The custom circuit file has no custom circuit in it.");
      return;
    }
    circuit = (CustomCircuit) loadedGates.get(0);
  }

  // IF LOADING, WIPE THE CURRENT BOARD, AND CANCEL ANY CONNECTION THAT WAS HALF MADE
  if (!isImporting) {
    allLogicGates.clear();
    isCreatingNewConnection = false;
    isAGateSelected = false;
  }

  // ---------- BOARD FILE: ADD EVERY GATE ----------
  if (circuit == null) {
    for (LogicGate logicGate : loadedGates) allLogicGates.add(logicGate);
  }

  // ---------- CIRCUIT FILE, IMPORTING: ADD THE CIRCUIT AS ONE GATE IN THE MIDDLE OF THE SCREEN ----------
  else if (isImporting) {
    circuit.moveBy(width/2 - circuit.x, height/2 - circuit.y);
    allLogicGates.add(circuit);
  }

  // ---------- CIRCUIT FILE, LOADING: ADD EVERY GATE INSIDE IT, SO IT CAN BE EDITED ----------
  else {
    for (LogicGate logicGate : circuit.gatesGrouped) allLogicGates.add(logicGate);
  }
}


// TURNS SAVED JSON INTO GATES. IT CALLS ITSELF FOR THE GATES INSIDE A CUSTOM CIRCUIT
ArrayList<LogicGate> buildGates(JSONArray gatesJson) {
  // EVERY GATE IN THE FILE, IN FILE ORDER. A GATE THAT COULDN'T BE MADE STAYS IN AS null, SO THE WIRE INDEXES STILL LINE UP
  ArrayList<LogicGate> loadedGates = new ArrayList<LogicGate>();

  // ---------- PASS 1: CREATE EVERY GATE ----------
  // WIRES CAN'T BE MADE YET, BECAUSE A WIRE MIGHT POINT AT A GATE THAT HASN'T BEEN CREATED YET
  for (int i = 0; i < gatesJson.size(); i++) {
    JSONObject gj = gatesJson.getJSONObject(i);

    // BUILD THE RIGHT TYPE OF GATE AT THE SAVED SPOT
    String type = gj.getString("type", "");
    LogicGate g;
    if (type.equals("CUSTOM")) g = makeCircuit(gj);
    else g = makeGate(type, gj.getInt("x"), gj.getInt("y"));
    loadedGates.add(g);         // Added even if it's null, so the indexes stay lined up
    if (g == null) continue;    // If the made gate is null - it didn't make a gate - skip setting this gate up
    g.rotation = gj.getInt("rotation");

    // ---------- SET ITS TYPE FIRST (BEFORE THE INPUTS) ----------
    // SOME TYPES ADD OR REMOVE INPUTS, LIKE THE SR CIRCUIT'S CLOCK INPUT, SO IT HAS TO COME BEFORE THE INPUT COUNT IS MATCHED
    int typePresses = 0;
    if (gj.hasKey("typePresses")) typePresses = gj.getInt("typePresses");
    else if (gj.getBoolean("changeType", false)) typePresses = 1;  // Files saved before typePresses existed
    for (int p = 0; p < typePresses; p++) g.changeType();

    // PUT BACK THE SAVED NAME (AFTER THE TYPE, SINCE CHANGING THE TYPE RESETS THE NAME)
    if (gj.hasKey("gateType")) g.gateType = gj.getString("gateType");

    // ADD OR REMOVE INPUTS UNTIL IT HAS THE SAME AMOUNT AS WHEN IT WAS SAVED
    // (FOR LOOPS INSTEAD OF WHILE LOOPS, SO IF A GATE REFUSES TO ADD ONE, IT CAN'T FREEZE THE SKETCH)
    JSONArray inputValues = gj.getJSONArray("inputs");  // Grab the array of inputs from the gate json
    for (int n = g.inputs.size(); n < inputValues.size(); n++) g.addInput();
    for (int n = g.inputs.size(); n > inputValues.size(); n--) g.removeInput();

    // PUT EACH INPUT'S TRUE/FALSE VALUE BACK
    for (int j = 0; j < inputValues.size() && j < g.inputs.size(); j++) g.inputs.get(j).inputValue = inputValues.getBoolean(j);

    // PUT BACK THE REMEMBERED BIT OF THE SR, D/T, AND JK CIRCUITS (AFTER THE INPUTS, SO THE CLOCK'S VALUE IS KNOWN)
    if (g instanceof SequentialLogic) restoreMemory(g, gj.getBoolean("storedBit", false));

    // DETERMINE ITS OUTPUT
    g.calculateOutput();
  }

  // ---------- PASS 2: RECONNECT ALL THE WIRES ----------
  // NOW THAT EVERY GATE EXISTS, ANY SAVED INDEX IS NOW SAFE TO USE
  // SO FOR ALL GATES IN THE SAVED JSON LIST OF GATES
  for (int i = 0; i < gatesJson.size(); i++) {
    LogicGate g = loadedGates.get(i);
    if (g == null) continue;  // This gate couldn't be made, so it has no wires to rebuild

    JSONArray wires = gatesJson.getJSONObject(i).getJSONArray("wires");  // Get the array of wires/connections that gate has

    // FOR EVERY SAVED WIRE, FIND THE OUTPUT, GATE, AND INPUT IT POINTS/CONNECTS TO, THEN CONNECT TO IT
    for (int j = 0; j < wires.size(); j++) {
      JSONObject w = wires.getJSONObject(j);  // Get this specific wire out of the array

      // GET THE OUTPUT DOT THE WIRE LEAVES FROM, AND GIVE IT A CONNECTION
      int outIndex = w.getInt("output", 0);  // Old files have no "output", and those gates only had one
      if (outIndex >= g.outputs.size()) continue;  // That output doesn't exist on the loaded gate
      LogicGate.IOButton outDot = g.outputs.get(outIndex);
      g.addConnection(outDot);

      LogicGate target = loadedGates.get(w.getInt("gate"));  // Get the gate this wire points to
      if (target == null) continue;  // That gate couldn't be made, so there's nothing to connect to

      int inputIndex = w.getInt("input");
      if (inputIndex >= target.inputs.size()) continue;  // That input doesn't exist on the loaded gate
      outDot.outputConnection.addConnectionTo(target.inputs.get(inputIndex));  // Then add a connection to that gate at the right input
    }
  }

  // ---------- REMOVE THE GATES THAT COULDN'T BE MADE ----------
  // THE WIRES ARE DONE, SO THE INDEXES DON'T MATTER ANYMORE
  for (int i = loadedGates.size() - 1; i >= 0; i--) if (loadedGates.get(i) == null) loadedGates.remove(i);

  return loadedGates;
}
