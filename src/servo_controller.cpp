#include "servo_controller.h"

// Define pins
int motorPin1 = 33;
int motorPin2 = 27;
int motorEnPin = 26;

int buttonStartPin = 17;
int buttonStopPin = 16;

int wheelServoPin = 18;
Servo wheelServo;
int swipeServoPin = 19;
Servo swipeServo;
int pressureServoPin = 4;
Servo pressureServo;

int proxiPin = 13;
int buzzPin = 32;

bool overdrive = false;

void homing() {
    wheelServo.write(5);
    swipeServo.write(0);
    pressureServo.write(0);

    digitalWrite(buzzPin, HIGH);
    delay(5000);
    digitalWrite(buzzPin, LOW);
}

void flip() {
    analogWrite(motorEnPin, 180);
    wheelServo.write(135);
    overdrive = false;

    delay(1000);

    digitalWrite(motorPin1, HIGH);
    digitalWrite(motorPin2, LOW);

    int moveServoLower_timeoutMs = MOVESERVOLOWER_INITMS;
    int moveServoLower_curAngle = 135;
    while (digitalRead(proxiPin)) {
        if (moveServoLower_curAngle == 143) {
            if (overdrive) {
                digitalWrite(buzzPin, HIGH);
                delay(1000);
                digitalWrite(buzzPin, LOW);
                delay(1000);
                digitalWrite(buzzPin, HIGH);
                delay(1000);
                digitalWrite(buzzPin, LOW);
                break;
            } else {
                digitalWrite(buzzPin, HIGH);
                delay(1000);
                digitalWrite(buzzPin, LOW);
                moveServoLower_curAngle = 135;
                wheelServo.write(moveServoLower_curAngle);
                analogWrite(motorEnPin, 255);
                overdrive = true;
            }
        }

        if (moveServoLower_timeoutMs == 0) {
            moveServoLower_timeoutMs = MOVESERVOLOWER_INITMS;
            moveServoLower_curAngle += 1;
            wheelServo.write(moveServoLower_curAngle);
        }
        moveServoLower_timeoutMs -= 1;
        delay(1);
    }

    swipeServo.write(33);
    delay(100);
    swipeServo.write(67);
    delay(100);
    swipeServo.write(100);
    delay(500);
    digitalWrite(motorPin1, LOW);
    digitalWrite(motorPin2, LOW);

    wheelServo.write(5);
    delay(1000);

    swipeServo.write(230);
    delay(750);
    pressureServo.write(170);
    delay(2000);

    swipeServo.write(0);
    pressureServo.write(0);
    delay(1000);
}

void servoInit(){
    pinMode(motorPin1, OUTPUT);
    pinMode(motorPin2, OUTPUT);
    pinMode(motorEnPin, OUTPUT);
    pinMode(wheelServoPin, OUTPUT);
    pinMode(swipeServoPin, OUTPUT);
    pinMode(pressureServoPin, OUTPUT);
    pinMode(proxiPin, INPUT);
    pinMode(buzzPin, OUTPUT);
    pinMode(buttonStartPin, INPUT_PULLUP);
    pinMode(buttonStopPin, INPUT_PULLUP);
    wheelServo.attach(wheelServoPin);
    swipeServo.attach(swipeServoPin);
    pressureServo.attach(pressureServoPin);
}
