// // Motor A
// int motor1Pin1 = 33; 
// int motor1Pin2 = 27; 
// int enable1Pin = 26; 

// // Setting PWM properties
// const int freq = 30000;
// const int pwmChannel = 0;
// const int resolution = 8;
// int dutyCycle = 200;

// void setup() {
//   // sets the pins as outputs:
//   pinMode(motor1Pin1, OUTPUT);
//   pinMode(motor1Pin2, OUTPUT);
//   pinMode(enable1Pin, OUTPUT);
  
//   // configure LEDC PWM
//   //ledcAttachChannel(enable1Pin, freq, resolution, pwmChannel);

//   Serial.begin(115200);

//   // testing
//   Serial.print("Testing DC Motor...");
// }

// void loop() {
//   // Move the DC motor forward at maximum speed
//   Serial.println("Moving Forward");
//   digitalWrite(motor1Pin1, LOW);
//   digitalWrite(motor1Pin2, HIGH); 
//   delay(2000);

//   // Stop the DC motor
//   Serial.println("Motor stopped");
//   digitalWrite(motor1Pin1, LOW);
//   digitalWrite(motor1Pin2, LOW);
//   delay(1000);

//   // Move DC motor backwards at maximum speed
//   Serial.println("Moving Backwards");
//   digitalWrite(motor1Pin1, HIGH);
//   digitalWrite(motor1Pin2, LOW); 
//   delay(2000);

//   // Stop the DC motor
//   Serial.println("Motor stopped");
//   digitalWrite(motor1Pin1, LOW);
//   digitalWrite(motor1Pin2, LOW);
//   delay(1000);

//   // // Move DC motor forward with increasing speed
//   // digitalWrite(motor1Pin1, HIGH);
//   // digitalWrite(motor1Pin2, LOW);
//   // while (dutyCycle <= 255){
//   //   ledcWrite(enable1Pin, dutyCycle);   
//   //   Serial.print("Forward with duty cycle: ");
//   //   Serial.println(dutyCycle);
//   //   dutyCycle = dutyCycle + 5;
//   //   delay(500);
//   // }
//   // dutyCycle = 200;
// }


//Begin
//Homing
//BC BL (wait until BL pair)
//BL paired (wait until button 1 to proceed, or butt 3 (or phone unpaired) to unpair)
//Start scanning sequence (wait until sequence trigger, or any button to pause (or device unpaired))
  //Servo moves to low, motor spins, servo moves lower slowly
  //Wait until proxi detects, then servo flip page, wheel servo moves high
  //Send signal to phone to capture photo
  //Repeat
//Pause: (Button 1 to resume, Button 3 to terminate)

#include<ESP32Servo.h>

int motorPin1 = 33; 
int motorPin2 = 27; 
int motorEnPin = 26;

int wheelServoPin = 18; //Also labeled as Servo1
Servo wheelServo;
int swipeServoPin = 19; //Also labeled as Servo2
Servo swipeServo;
int pressureServoPin = 4;
Servo pressureServo;

int proxiPin = 13; 
int buzzPin = 32;

#define MOVESERVOLOWER_INITMS 2000 //Originally 2000

void homing(){
  // Reset servo to default position
  wheelServo.write(5);
  swipeServo.write(0);
  pressureServo.write(0);

  digitalWrite(buzzPin, HIGH);
  delay(5000);
  digitalWrite(buzzPin, LOW);
  delay(1000);

  while(!digitalRead(proxiPin)){
    digitalWrite(buzzPin, HIGH);
    delay(1000);
    digitalWrite(buzzPin, LOW);
    delay(1000);
  }

  // wheelServo.write(140);
  // swipeServo.write(100);
  // delay(5000);
  // swipeServo.write(180);
}

bool flip(){
  int attempt = 1;
  bool finishRaise = false;
  bool raiseSuccess = false;
  int moveServoLower_curAngle;
  //Move wheel servo to lower position
  while (attempt <= 3 && !raiseSuccess){
    wheelServo.write(135);
    delay(1000);

    //Move wheel
    digitalWrite(motorPin1, HIGH);
    digitalWrite(motorPin2, LOW); 
    analogWrite(motorEnPin, 255);
    delay(300);
    analogWrite(motorEnPin, 90);
    
    int moveServoLower_timeoutMs = MOVESERVOLOWER_INITMS;
    moveServoLower_curAngle = 135;
    bool overdrive = false;
    
    finishRaise = false;
    while(!finishRaise){
      if(moveServoLower_timeoutMs == 0){
        if(overdrive){
          moveServoLower_curAngle += 1;
          wheelServo.write(moveServoLower_curAngle);
          analogWrite(motorEnPin, 90);
        } else{
          analogWrite(motorEnPin, 255);
        }
        moveServoLower_timeoutMs = MOVESERVOLOWER_INITMS;
        overdrive = !overdrive;
      }
      moveServoLower_timeoutMs -= 1;

      finishRaise = (moveServoLower_curAngle >= 143) || !digitalRead(proxiPin);
      
      // wheelServo.write(moveServoLower_curAngle - 2);
      // delay(250);
      // wheelServo.write(moveServoLower_curAngle);
      // delay(250);
      delay(1);
      
    }
    raiseSuccess = (moveServoLower_curAngle < 143);
    attempt++;

    if(!raiseSuccess){
      //Move wheel servo to higher position
      wheelServo.write(5);
      delay(1000);
    }
  }

  if (attempt > 3){
      digitalWrite(motorPin1, LOW);
      digitalWrite(motorPin2, LOW);
      digitalWrite(buzzPin, HIGH);
      delay(1000);
      digitalWrite(buzzPin, LOW);
      delay(1000);
      digitalWrite(buzzPin, HIGH);
      delay(1000);
      digitalWrite(buzzPin, LOW); 
      return false;
    }

    //Swiper servo would move, then turn wheel off
    swipeServo.write(100);
    delay(500);
    digitalWrite(motorPin1, LOW);
    digitalWrite(motorPin2, LOW); 
    
    //Move wheel servo to higher position
    wheelServo.write(5);
    delay(1000);
    
    //Swiper servo would move more, and point pressure servo would move
    swipeServo.write(230);
    delay(750);
    pressureServo.write(140);
    delay(1000);

    //Roll page backward to remove excess shift
    wheelServo.write(moveServoLower_curAngle);
    analogWrite(motorEnPin, 255);
    digitalWrite(motorPin1, LOW);
    digitalWrite(motorPin2, HIGH); 
    delay(2000);
    
    //Reset to orig pos
    wheelServo.write(5);
    digitalWrite(motorPin1, LOW);
    digitalWrite(motorPin2, LOW); 
    swipeServo.write(0);
    pressureServo.write(0);
    delay(1000);

    return true;
}

void setup(){
  pinMode(motorPin1, OUTPUT);
  pinMode(motorPin2, OUTPUT);
  pinMode(motorEnPin, OUTPUT);
  pinMode(wheelServoPin, OUTPUT);
  pinMode(swipeServoPin, OUTPUT);
  pinMode(pressureServoPin, OUTPUT);
  pinMode(proxiPin, INPUT);
  pinMode(buzzPin, OUTPUT);

  wheelServo.attach(wheelServoPin);
  swipeServo.attach(swipeServoPin);
  pressureServo.attach(pressureServoPin);
  homing();
}

void loop(){
  flip();
}