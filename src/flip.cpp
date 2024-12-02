

// #include <ESP32Servo.h>

// int motorPin1 = 33; 
// int motorPin2 = 27; 
// int motorEnPin = 26;

// int wheelServoPin = 18; //Also labeled as Servo1
// Servo wheelServo;
// int swipeServoPin = 19; //Also labeled as Servo2
// Servo swipeServo;
// int pressureServoPin = 4;
// Servo pressureServo;

// int proxiPin = 13;
// int buzzPin = 32;

// #define MOVESERVOLOWER_INITMS 2000
// bool overdrive = false;

// void homing(){
//   // Reset servo to default position
//   wheelServo.write(5);
//   swipeServo.write(0);
//   pressureServo.write(0);

//   digitalWrite(buzzPin, HIGH);
//   delay(5000);
//   digitalWrite(buzzPin, LOW);

// }

// void flip(){
//   //Move wheel servo to lower position
//   analogWrite(motorEnPin, 180);
//   wheelServo.write(135);
//   overdrive = false;

//   delay(1000);

//   //Move wheel slowly
//   //Until proxi detects
//   digitalWrite(motorPin1, HIGH);
//   digitalWrite(motorPin2, LOW); 
  
//   int moveServoLower_timeoutMs = MOVESERVOLOWER_INITMS;
//   int moveServoLower_curAngle = 135;
//   while(digitalRead(proxiPin)){

//     if(moveServoLower_curAngle == 143){
//       if(overdrive){
//         digitalWrite(buzzPin, HIGH);
//         delay(1000);
//         digitalWrite(buzzPin, LOW);
//         delay(1000);
//         digitalWrite(buzzPin, HIGH);
//         delay(1000);
//         digitalWrite(buzzPin, LOW);
//         break;
//       } 
//       else {
//         digitalWrite(buzzPin, HIGH);
//         delay(1000);
//         digitalWrite(buzzPin, LOW);
//         moveServoLower_curAngle = 135;
//         wheelServo.write(moveServoLower_curAngle);
//         analogWrite(motorEnPin, 255);
//         overdrive = true;
//       }
//     }
    
//     if(moveServoLower_timeoutMs == 0){
//       moveServoLower_timeoutMs = MOVESERVOLOWER_INITMS;
//       moveServoLower_curAngle += 1;
//       wheelServo.write(moveServoLower_curAngle);
//     }
//     moveServoLower_timeoutMs -= 1;
//     // wheelServo.write(moveServoLower_curAngle + 2);
//     // delay(250);
//     // wheelServo.write(moveServoLower_curAngle);
//     // delay(250);
//     delay(1);
//   }

//   //Swiper servo would move, then turn wheel off
//   swipeServo.write(33);
//   delay(100);
//   swipeServo.write(67);
//   delay(100);
//   swipeServo.write(100);
//   delay(500);
//   digitalWrite(motorPin1, LOW);
//   digitalWrite(motorPin2, LOW); 
  
//   //Move wheel servo to higher position
//   wheelServo.write(5);
//   delay(1000);
  
//   //Swiper servo would move more, and point pressure servo would move
//   swipeServo.write(230);
//   delay(750);
//   pressureServo.write(170);
//   delay(2000);

//   //Swiper servo would reset
//   swipeServo.write(0);
//   pressureServo.write(0);
//   delay(1000);

// }

// void setup(){
//   pinMode(motorPin1, OUTPUT);
//   pinMode(motorPin2, OUTPUT);
//   pinMode(motorEnPin, OUTPUT);
//   pinMode(wheelServoPin, OUTPUT);
//   pinMode(swipeServoPin, OUTPUT);
//   pinMode(pressureServoPin, OUTPUT);
//   pinMode(proxiPin, INPUT);
//   pinMode(buzzPin, OUTPUT);

//   wheelServo.attach(wheelServoPin);
//   swipeServo.attach(swipeServoPin);
//   pressureServo.attach(pressureServoPin);
// }

// void loop(){
//   flip()
// }