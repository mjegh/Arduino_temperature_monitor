// $Id$
// script for arduino to read voltage on A0 from a TMP36
int sensorPin = A0;    // select the input pin for the potentiometer
int ledPin = 13;      // select the pin for the LED
int sensorValue = 0;  // variable to store the value coming from the sensor
float temp; //temperature
float millivolts; // voltage conversion from ADC
// we are using 3.3V and the 10bit ADC gives us 1024 values
float conversion_factor = 3300.00 / 1024.00;
char read_buffer[100]; // whatever was sent from Perl

void setup() {
  // declare the ledPin as an OUTPUT:
  pinMode(ledPin, OUTPUT);
  Serial.begin(115200);
  analogReference(EXTERNAL);
}

void loop() {
  // wait to read something on the serial port
  if (Serial.available() > 0) {
      // turn the ledPin on
      digitalWrite(ledPin, HIGH);

      // just read whatever it is - we do not really care what it is right now
     // but we would if we had multiple TMP36 sensors
      Serial.readBytes(read_buffer, sizeof(read_buffer));

      // read the value from the sensor:
      sensorValue = analogRead(sensorPin);

     millivolts = sensorValue * conversion_factor;
     // we subtract 500 (100 for the .1V the TMP36 starts at and 400 for the -40 degrees C at 10mV per degree C and divide by 10 as the TMP36 does 10mV per degree C
     temp = (millivolts - 500) / 10;
     Serial.println(temp);
     // stop the program for <sensorValue> milliseconds:
     delay(500);
     // turn the ledPin off:
     digitalWrite(ledPin, LOW);
  }
}
