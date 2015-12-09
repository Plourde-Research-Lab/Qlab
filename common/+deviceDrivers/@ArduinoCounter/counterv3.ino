template<class T> inline Print &operator <<(Print &obj, T arg) { 
  obj.print(arg); 
  return obj;
}

#include <EEPROM.h>

// processInput states
const byte COMMAND = 0;
const byte NUMBER = 1;
const byte DONE = 10;

const int NO_MESSAGE = -1;

// command modes
const byte IDN = 0;
const byte GET = 1;
const byte SET = 2;
const byte SEG = 3;
const byte REP = 4;
const byte VAL = 5;
const byte PARAM = 6;
const byte RESET = 7;
const byte UNKNOWN = -1;


int count = 0;
int segments = 1;
int reps = 1;
int segmentMode = false;

const boolean VERBOSE = false;

void setup() {
  // open serial interface to host computer
  Serial.begin(115200);

  initCounter();
  initTriggerCounter();
  // pinMode(pin, OUTPUT);
  attachInterrupt(0, printCount, RISING);

  sei();

//  while (Serial.available() <= 0) {
//    delay(100);
//  }
}

void loop() {
  char input[255];
  char buffer[33];
  int output = 1;
  
  if (Serial.available() > 0) {
    readString(input);
    if (VERBOSE) {
      Serial.println(strcat("Command: ", input));
    }
    output = processInput(input);
    Serial.flush();
  }
}

void readString(char* s) {
//  Serial.println("readString");
  int readCount = 0;
  unsigned long startTime = millis();
  char val;
  // terminate at 255 chars, a semicolon, or 100 ms timeout
  while (readCount < 255 && (millis() - startTime) < 100) {
    if (Serial.available() == 0) {
      continue;
    }
    val = Serial.read();
    if (val != '\n' && val != '\r' && val != ';') { // also ignore linefeeds and carriage returns
      s[readCount++] = val;
    }
    else {
      break;
    }
  }
  s[readCount] = 0;
}

int processInput(char* input) {
//  Serial.println("process");
  byte command = UNKNOWN;
  byte param = UNKNOWN;
  byte mode = COMMAND;
  int value = 0;
  
  char* token = strtok(input, " ");
//  Serial.println(input);
  while (token) {
//    Serial.println(token);
    switch(mode){
      case COMMAND:
        if (!strcasecmp(token, "IDN")) {
          command = IDN;
          mode = DONE;
        }
        if (!strcasecmp(token, "SET")) {
          command = SET;
          mode = PARAM;
        }
        if(!strcasecmp(token, "RESET")){
          command = RESET;
          mode = DONE;
        }
        if (!strcasecmp(token, "GET")) {
          command = GET;
          mode = PARAM;
        }
        break;
      case PARAM:
        if (!strcasecmp(token, "SEG")) {
          param = SEG;
          if (command == SET) mode = VAL;
          else mode=DONE;
        }
        if (!strcasecmp(token, "REP")) {
          param = REP;
          if (command == SET) mode = VAL;
          else mode=DONE;
        }
        break;
      case VAL:
        value = atoi(token);
        mode = DONE;
        break;
    }
   token = strtok(NULL, " "); 
  }

  if (mode != DONE) {
    return NO_MESSAGE;
  } 
  if (command == IDN) {
    Serial.println("ARDUINO COUNTER");
    return 1;
  } else if (command == GET) {
    if (param == SEG) {
      getSegments();
    } else getReps();
    return 1;
  } else if (command == SET) {
    if (param == SEG) {
      setSegments(value);
    }
    else setReps(value);
  } else if(command == RESET){
      resetCounter();
      return 1;
  }
}

void initCounter() {
 //Count rising edges on pin D5
 TCCR1A = 0;
 TCCR1B = 0; 
 TIMSK1 = bit (TOIE1);   // interrupt on Timer 1 overflow
 GTCCR = bit (PSRASY);        // reset prescaler now
 // OCR1A = 10;
 TCCR1B =  bit (CS10) | bit (CS11) | bit (CS12);
 TCNT1 = 0;      // Both counters to zero
}

ISR(TIMER1_COMPB_vect) {
  printOverflow();
  TCNT1 = 0;
}

void initTriggerCounter() {
  //Count rising edges on pin 
  TCCR2A = 0;
  TCCR2B = 0;
  TIMSK2 = bit (TOIE2);
  GTCCR = bit (PSRASY);        // reset prescaler now
  // OCR2A = 2;
  TCCR1B =  bit (CS10) | bit (CS11) | bit (CS12);
  TCNT2 = 0;
}

ISR(TIMER2_COMPA_vect) {
  printOverflow();
  TCNT2 = 0;
}

void resetCounter(){
  // Serial.println("Resetting Counter");
  TCNT1 = 0;
}

int getCount(){
  count = TCNT1;
  TCNT1=0;
  return count;
}

void printCount(){
  Serial.println(getCount(), DEC);
}

void printOverflow() {
  // Serial.println("Timer2 overflow");  
}

void setSegments(int value) {
  segments = value;
  Serial.println(value);
  Serial << "Setting segments to " << value << "\n";
}

void getSegments() {
  Serial.println(segments);
}

void setReps(int value) {
  reps = value;
  Serial << "Setting reps to " << value << "\n";
}

void getReps() {
  Serial.println(reps);
}

