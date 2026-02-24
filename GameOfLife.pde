/**
 * CONWAY'S GAME OF LIFE
 * -----------------------------------------------------------------------------
 * Autore:      Fraternali Lorenzo
 *
 * Descrizione: Simulazione dell'automa cellulare di Conway.
 * -----------------------------------------------------------------------------
 */
 
// =============================================================================
// PARAMETRI DI CONFIGURAZIONE E VARIABILI GLOBALI
// =============================================================================

// Dimensioni della griglia (celle)
int   rows = 40; 
int   cols = 40;
int   probability = 15;

// Dimensioni calcolate dinamicamente nel setup
int   gridHeight; // Altezza disponibile per la griglia
float cellWidth;  // Larghezza singola cella
float cellHeight; // Altezza singola cella

// Gestione del Tempo e Velocità
int   nFrame = 60; // FrameRate dell'applicazione (UI)
int   speed  = 5; // Ogni quanti frame aggiornare

// Parametri Interfaccia Utente (UI)
int    menuHeight = 75;
float  buttonWidth;
float  buttonHeight;

// Strutture Dati 
int[][] currentPhase  = new int[rows][cols]; 
int[][] nextPhase     = new int[rows][cols];

// Stato del sistema
boolean toggle    = true;  // Determina quale array leggere/scrivere
boolean isPlaying = false; // Flag per Avvio/Pausa
boolean pacMan    = true;  // Attiva/Disattiva effetto Pac-Man 

// Gestione colori
int color1 = 180;
int color2 = 300;

// =============================================================================
// SETUP INIZIALE
// =============================================================================
void setup (){
   size(1000,1000); 
   colorMode(HSB, 360, 100, 100);
   
   gridHeight = height - menuHeight; // Calcolo area di gioco escludendo il menu
     
   frameRate(nFrame); // Imposto gli FPS per fluidità del mouse
 
   // Calcolo dimensioni celle in base alla finestra
   cellWidth    = (float)width/cols;
   cellHeight   = (float)gridHeight/rows;
   
   // Calcolo dimensioni pulsanti
   buttonWidth  = (float)width/4;
   buttonHeight = (float)(menuHeight)/2.0;
   
   // Pulizia e inizializzazione random
   resetPhases();
   randomizeGrid();
   
   // Inizializzo la griglia con 1 linea di 5 celle 
   //setManyGriders(1,5);
   
   
}

// =============================================================================
// MAIN LOOP (DRAW)
// =============================================================================
void draw(){
  background(240, 20, 10); 
  
  // Disegno le celle (Leggo dall'array attivo)
  if (toggle) {
    drawPhase(currentPhase);
  } else {
    drawPhase(nextPhase);
  }
  
  // Disegno la griglia e l'interfaccia sopra le celle
  drawGrid(); 
  drawUI();  
  
  // Logica di aggiornamento temporale
  // Eseguo il calcolo solo se in PLAY e solo ogni 'speed' frames  
  if (isPlaying && frameCount % speed == 0) {
    if (toggle) {
      calcPhase(currentPhase, nextPhase);
    } else {
      calcPhase(nextPhase, currentPhase);
    }
  toggle = !toggle; // Scambio gli array solo se ho calcolato una nuova fase
  }
}

// =============================================================================
// FUNZIONI DI RENDERING (GRAFICA)
// =============================================================================

// Disegna la griglia grigia sopra le celle
void drawGrid(){
  stroke(0, 0, 40); // Grigio chiaro
  
  // Linee verticali
  for (int x=0; x<=cols; x+=1){
    line(x * cellWidth, 0, x * cellWidth, height - menuHeight);
  }
  
  // Linee orizzontali
  for (int y=0; y<=rows; y+=1){
    line(0, y * cellHeight, width, y * cellHeight);
  }
}

// Disegna le celle vive (rettangoli neri)
void drawPhase(int phase[][]){
  noStroke();
  
  for (int r = 0; r<rows; r++){
    for (int c = 0; c<cols; c++){
      int age = phase[r][c];
      
      if (age > 0){
        // Mappiamo l'età (da 1 a 100) 
        float hue    = map(min(age, 100), 1, 100, color1, color2); 
        float bright = map(min(age, 100), 1, 100, 100,  70);
        fill(hue, 90, bright);
        
        rect(c * cellWidth, r * cellHeight, cellWidth, cellHeight);
      }
    }
  }
}

// Disegna il menu inferiore con i pulsanti
void drawUI(){
  fill(0, 0, 80); // Sfondo base grigio molto chiaro
  rect(0, gridHeight, width, menuHeight);
  stroke(0, 0, 0);
  
  // --- Pulsante AVVIA/PAUSA ---
  if (isPlaying) {
    fill(0, 80, 90); // Rosso PAUSA
  }else{
    fill(120, 80, 90); // Verde AVVIA
  }
  rect(width/8, gridHeight + (menuHeight/4) , buttonWidth, buttonHeight, 10);
  fill(0, 0, 0);
  textSize(20);
  textAlign(CENTER,CENTER);
  text(isPlaying ? "PAUSA" : "AVVIA", width*1/4, gridHeight + (menuHeight/2.0));

  // --- Pulsante RESET ---  
  fill(0, 0, 70);
  rect(width*5/8, gridHeight + (menuHeight/4.0), buttonWidth, buttonHeight, 10);
  fill(0, 0, 0);
  text("RESET", width*3/4, gridHeight + (menuHeight/2.0));

  // --- Pulsante "PAC-MAN" ---
  if (pacMan) {
    fill(120, 80, 90); // Verde PACMAN attivo 
  }else{
    fill(0, 80, 90); // Rosso PACMAN disattivo
  }
  rect(width*7/16.0,gridHeight + (menuHeight/4),buttonWidth/2, buttonHeight, 10);
  fill(50, 90, 100);
  noStroke();
  arc(width/2, gridHeight + (menuHeight/2), 
      buttonHeight-gridHeight*0.01, buttonHeight-gridHeight*0.01, 
      PI / 4, 7 * PI / 4);  
}

// =============================================================================
// LOGICA DEL GIOCO
// =============================================================================

// Applica le regole del Gioco della Vita
void calcPhase(int currentPhase[][], int nextPhase[][])
{
  for (int r = 0; r < rows; r++){
    for (int c = 0; c < cols; c++){
      int neighbors;
      
      if (pacMan){
        neighbors = countNeighborsPacMan(currentPhase, r, c);
      }else{
        neighbors = countNeighbors(currentPhase, r, c);
      }
      
      int cellAge = currentPhase[r][c];
      
      if (cellAge > 0) { // CELLA VIVA
        // Meno di 2 o più di tre viini --> Muore
        if ((neighbors < 2) || (neighbors > 3)){
          nextPhase[r][c] = 0; 
        }else {
          // Sopravvivenza (2 o 3 vicini) e invecchiamento
          nextPhase[r][c] = min(cellAge + 1, 255);
        }
      } else { // CELLA MORTA            
        // Riproduzione (esattamente 3 vicini) -> Nasce
        if (neighbors == 3){
          nextPhase[r][c] = 1;
        // Resta morta 
        } else {
          nextPhase[r][c] = 0;
        }
      }
    }
  }
}

// Conta i vicini (celle adiacenti vive) considerando effetto "Pac-Man"
int countNeighborsPacMan (int phase[][], int row, int col){
  int neighbors = 0;
  // Controllo matrice 3x3 attorno alla cella
  for (int r = -1; r<2; r++){
    int checkRow = (row + r + rows) % rows;
    for (int c = -1; c<2; c++){
      int checkCol = (col + c + cols)% cols;
      // Escludo la cella centrale (se stessa)
      if ((r != 0) || (c != 0)) {
        if (phase[checkRow][checkCol] > 0) {
          neighbors ++;
        }
      }
    }
  }
  return neighbors;
}

// Conta i vicini (celle adiacenti vive) considerando i bordi come limite
int countNeighbors (int phase[][], int row, int col){
  int neighbors = 0;
  // Controllo matrice 3x3 attorno alla cella
  for (int r = -1; r<2; r++){
    int checkRow = row + r;
    for (int c = -1; c<2; c++){
      int checkCol = col + c;
      // Escludo la cella centrale (se stessa)
      if ((r != 0) || (c != 0)) { //<>//
        if (checkRow >= 0 && checkRow < rows && 
            checkCol >= 0 && checkCol < cols){
          if (phase[checkRow][checkCol] > 0) {
            neighbors ++;
          }
        }
      }
    }
  }
  return neighbors;
}
// =============================================================================
// FUNZIONI DI UTILITÀ E INPUT
// =============================================================================

// Azzera completamente la griglia
void resetPhases() {
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      currentPhase[r][c] = 0;
      nextPhase[r][c] = 0;
    }
  }
}

// Riempie la griglia casualmente in base alla probabilità
void randomizeGrid() {
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      if (random(1) < (probability/100.0)) { 
        currentPhase[r][c] = 1;
      } else {
        currentPhase[r][c] = 0;
      }
    }
  }
}

// Funzione per creare linee casuali
void setManyGriders(int count, int len) {
  resetPhases();
  for (int i = 0; i < count; i++) {
    int r = (int)random(rows);
    int c = (int)random(cols);
    setLine(r, c, len); 
  }
}

// Crea una linea orizzontale di celle vive
void setLine(int r, int c, int len) {
  for (int i = 0; i < len; i++) {
    currentPhase[r][(c + i) % cols] = 1;
  }
}

// Gestione Input Mouse
void mousePressed() {
  // Click nella griglia 
  if (mouseY < gridHeight) {
    int c = (int)(mouseX / cellWidth);
    int r = (int)(mouseY / cellHeight);
    
    // Controllo per sicurezza di non uscire dall'array
    if (r >= 0 && r < rows && c >= 0 && c < cols) {
      // Inverte lo stato della cella cliccata (0->1 o 1->0)
      if (toggle) {
        currentPhase[r][c] = (currentPhase[r][c] > 0) ? 0 : 1; 
      } else {
        nextPhase[r][c] = (nextPhase[r][c] > 0) ? 0 : 1;
      }
    }
  // Click nell'area del MENU/PULSANTI  
  }else{
    // Coordinate verticali comuni dei pulsanti
    float btnTop = gridHeight + menuHeight/4.0;
    float btnBot = gridHeight + menuHeight*3/4.0;
    
    // Pulsante SX: AVVIA/PAUSA
    if ((mouseX > width/8 &&  mouseX < width*3/8 && 
         mouseY > btnTop  &&  mouseY < btnBot)) {
      isPlaying = !isPlaying; // Inverte true/false
    }
    // Pulsante DX: RESET
    // Click Sinistro -> Pulisce tutto
    // Click Destro   -> Randomizza
    if ((mouseX > width*5/8 && mouseX < width*7/8 && 
         mouseY > btnTop    && mouseY < btnBot)) {
      if (mouseButton == RIGHT) {
        randomizeGrid();
      }else{
        resetPhases();
      }
      isPlaying = false; // Ferma il gioco quando resetti
      toggle = true;     // Resetta il ciclo
    }
    if ((mouseX > width*7/16.0 &&  mouseX < width*9/16.0 && 
       mouseY > btnTop         &&  mouseY < btnBot)) {
      pacMan = !pacMan;     
    }  
  }
}
