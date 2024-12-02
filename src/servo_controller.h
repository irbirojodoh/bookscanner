#ifndef SERVO_CONTROLLER_H
#define SERVO_CONTROLLER_H

#include <ESP32Servo.h>

// Pin definitions
extern int motorPin1;
extern int motorPin2;
extern int motorEnPin;
extern int wheelServoPin;
extern int swipeServoPin;
extern int pressureServoPin;
extern int proxiPin;
extern int buzzPin;
extern int buttonStartPin;
extern int buttonStopPin;

// Servo objects
extern Servo wheelServo;
extern Servo swipeServo;
extern Servo pressureServo;

// Constants
#define MOVESERVOLOWER_INITMS 2000

// Flags
extern bool overdrive;

// Function prototypes
void homing();
void flip();
void servoInit();

#endif // SERVO_CONTROLLER_H
