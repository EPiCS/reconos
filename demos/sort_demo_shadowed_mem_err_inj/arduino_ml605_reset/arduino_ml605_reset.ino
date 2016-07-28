int incoming = 0;
int PINOFFSET = 2;
int PINCOUNT = 12;

void setup() {
  // put your setup code here, to run once:
  for(int i=PINOFFSET; i<PINOFFSET+PINCOUNT; i++){
    pinMode(i, OUTPUT);
    digitalWrite(i, HIGH);
  }
  
  Serial.begin(9600);
}

void loop() {

  
  if (Serial.available() > 0) {
    incoming = Serial.read();

    // 'A' to 'L' and 'a' to 'l' are valid characters
    // 12 Valid input pins are 2 to 13
    
    // 'A' is at position  65 in the ascii table
    // 'a' is at position  97 in the ascii table
    
    // 'L' is at position  76 in the ascii table
    // 'l' is at position 108 in the ascii table
    
    // check ranges
    if ( (incoming >= 'A') && (incoming <= 'L') ){
      digitalWrite(incoming - 'A' + PINOFFSET, HIGH);
    }
    if ( (incoming >= 'a') && (incoming <= 'l') ){
      digitalWrite(incoming - 'a' + PINOFFSET, LOW);
    }
  }
}
