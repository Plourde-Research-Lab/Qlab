int count = 0;
int incomingByte = 0;

void setup() {
  // open serial interface to host computer
  Serial.begin(256000);

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
    if (Serial.available() > 0) {
          // read the incoming byte:
          incomingByte = Serial.read();
          switch (incomingByte) {
           case 113: //recieved 'q'
              printCount();  //Query Count
              break;
           case 116: //recieved 't'
              resetCounter();
              break;
          }
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
  TCNT2 = 0;
}

void resetCounter(){
  // Serial.println("Resetting Counter");
  TCNT1 = 0;
}

int getCount(){
  count = TCNT1;
  TCNT1=0;
  if (count > 0) {
    return 1;
  }
  return 0;
}

void printCount(){
  // getCount();
  Serial.println(float(getCount()), DEC);
}
