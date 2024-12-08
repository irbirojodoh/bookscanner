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

bool isPause;

bool flip(){
  int attempt = 1;
  bool finishRaise = false;
  bool raiseSuccess = false;
  isPause = false;
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
      if(isPause){
        return false;
      }
      
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
    swipeServo.write(180);
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