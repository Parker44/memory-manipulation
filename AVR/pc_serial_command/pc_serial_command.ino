/*
 * File:        pc_serial_command.ino
 * 
 * Author:      Parker Lloyd
 * 
 * Description: This program consumes a user command via serial and converts
 *              it into a 4-bit code to read/write one of two 8-bit registers
 *              on a CPLD. This 4-bit code is sent to a CPLD via 4 output 
 *              pins and a 5th output pin is used as a read-enable pin to 
 *              signal to the CPLD that the command is ready to be read. 
 *              Valid commands are:
 *                - "reg a"   : points to register A -> WILL NOT BE SENT AS ITS OWN COMMAND
 *                - "reg b"   : points to register B -> WILL NOT BE SENT AS ITS OWN COMMAND
 *                - "clear"   : sets the value of the pointed register to zero
 *                - "inc"     : increments the value of the pointed register
 *                - "dec"     : decrements the value of the pointed register
 *                - "input"   : inputs the next value into the pointer register
 *                - "repeat"  : decrements the value of the pointed register and repeats the previous command
 *                - "output"  : outputs the value of pointed register on the CPLD I/O
 * 
 */

#define MAX_BUFFER_SIZE 200 // bytes
#define PULSE_INTERVAL 100  // millis

// output pin to indicate command ready to be read
const int commandPins_ready = 3;

// output pins for sending 4-bit command to CPLD
const int commandPin_bit0 = 4;
const int commandPin_bit1 = 5;
const int commandPin_bit2 = 6;
const int commandPin_bit3 = 7;

// input pin to indicate CPLD is expecting integer input value 
const int CPLDPin_intwait = 13;

// input pins for reading 4-bit CPLD output after "output" command is run
const int CPLDPin_bit0 = 9;
const int CPLDPin_bit1 = 10;
const int CPLDPin_bit2 = 11;
const int CPLDPin_bit3 = 12;

// initialize command buffer, buffer pointer, converted 4-bit command, and input value (following input command)
char    command[MAX_BUFFER_SIZE] = "";
char    *bufp = command;
uint8_t convertedCommand = 0;       // uint8_t is shortest type for bitwise arithmetic; use 4 LSBs
int     inputVal = 0;               // value to input into reg(X)

// flags
bool commandFlag = false;       // to indicate command received
bool inputValFlag = false;      // to indicate input value is expected next
bool sendData = false;          // to indicate command/input should be sent to CPLD

// timestamp for beginning of pulse; will be set when command received
unsigned long previousMillis;

// private function prototypes
static void translateCommand(char *cmd);
static void validateInputValue(char *val);
static void sendCommand(uint8_t convCmd);
static void commandInfo();


void setup() 
{  
  // configure I/O pins
  pinMode(CPLDPin_intwait, INPUT);
  pinMode(CPLDPin_bit0, INPUT);
  pinMode(CPLDPin_bit1, INPUT);
  pinMode(CPLDPin_bit2, INPUT);
  pinMode(CPLDPin_bit3, INPUT);

  pinMode(commandPins_ready, OUTPUT);
  pinMode(commandPin_bit0, OUTPUT);
  pinMode(commandPin_bit1, OUTPUT);
  pinMode(commandPin_bit2, OUTPUT);
  pinMode(commandPin_bit3, OUTPUT);

  // PRECAUTIONARY: ensure output pins are initialized to LOW
  digitalWrite(commandPins_ready, LOW);
  digitalWrite(commandPin_bit0, LOW);
  digitalWrite(commandPin_bit1, LOW);
  digitalWrite(commandPin_bit2, LOW);
  digitalWrite(commandPin_bit3, LOW);
  
  // start serial communication
  Serial.begin(9600);
}


void loop() 
{
  // convert command once serial has received command/newline
  if ( commandFlag ) 
  {
    inputValFlag = digitalRead(CPLDPin_intwait);
    sendData = true;          // set flag for sending data to CPLD; changed to false if command is invalid

    // if user did not previously perform "input" command, translate command buffer contents
    // otherwise, treat command buffer contents as an integer value and validate
    if ( ! inputValFlag )
    {
      translateCommand(command);
    }
    else
    {
      validateInputValue(command);
    }

    // indicates the command/input has been processed
    // will be false until new command provided via serial
    commandFlag = false;

    // if command is not "reg a" or "reg b" or invalid
    // write the 4-bit command to the output pins and pulse the read-enable pin
    if ( sendData )
    {
      sendCommand(convertedCommand);
      previousMillis = millis();      // start time for pulse
    }

    // prints the current command, value of output pins, and whether the command was sent
    commandInfo();

    // erase buffer and point back to beginning of buffer to rewrite
    memset( command, 0, sizeof(command) );
    bufp = command;
  }

  // end read-enable pulse if read-enable pin is mid-pulse and if desired time has elapsed
  unsigned long currentMillis = millis();
  if ( digitalRead(commandPins_ready) && ( currentMillis - previousMillis >= PULSE_INTERVAL ) )
    digitalWrite(commandPins_ready, LOW);
}


// this function will run after every loop iteration
void serialEvent() 
{  
  while ( Serial.available() ) 
  {
    // get next char and convert to lower case
    char inChar = tolower( (char) Serial.read() );
    // append char to command string buffer
    *bufp++ = inChar;

    // signal the end of command when newline reached
    if ( inChar == '\n' ) 
    {
      *(--bufp) = '\0';   // replace newline char with null terminator in command buffer
      commandFlag = true; // command received
    }
  }
}


// translates valid serial input into a 4-bit code
// accepts a character pointer that points to the beginning of the input string
static void translateCommand(char * cmd){
  // translate command to 4-bit value, if valid
  if ( strcmp(cmd, "reg a") == 0 ) 
  {
    convertedCommand &= ~1;                           // clear bit 0 (xxxxxxx0)
    sendData = false;
  } 
  else if ( strcmp(cmd, "reg b") == 0 ) 
  {
    convertedCommand |= 1;                            // set bit 0 (xxxxxxx1)
    sendData = false;
  } 
  else if ( strcmp(cmd, "clear") == 0 ) 
  {
    convertedCommand &= ~14;                          // clear bits 1, 2, 3 (xxxx000x)
  } 
  else if ( strcmp(cmd, "inc") == 0 ) 
  {
    convertedCommand = (convertedCommand & ~12) | 2;  // clear bits 2, 3 and set bit 1 (xxxx001x)
  } 
  else if ( strcmp(cmd, "dec") == 0 ) 
  {
    convertedCommand = (convertedCommand & ~10) | 4;  // clear bits 1, 3 and set bit 2 (xxxx010x)
  } 
  else if ( strcmp(cmd, "input") == 0 ) 
  {
    convertedCommand = (convertedCommand & ~8) | 6;   // clear bit 3 and set bits 1, 2 (xxxx011x)
    Serial.println("Input an integer between 0 and 15 (inclusive) in decimal format.\n");
  } 
  else if ( strcmp(cmd, "repeat") == 0 ) 
  {
    convertedCommand = (convertedCommand & ~6) | 8;   // clear bits 1, 2 and set bit 3 (xxxx100x)
  } 
  else if ( strcmp(cmd, "output") == 0 ) 
  {
    convertedCommand = (convertedCommand & ~4) | 10;  // clear bit 2 and set bits 1, 3 (xxxx101x)
  } 
  else 
  {
    sendData = false;
    Serial.println("Invalid command.\n");
  }
}


// validates the serial input after the "input" command has been performed
static void validateInputValue(char * val)
{
 /*
  * strtol() is safer than atoi()
  * strtol() returns 0 if command buffer does not contain numbers
  * strtol() also returns 0 if command = "0" (zero input value)
  * (endptr != command) checks if command buffer pointer has moved which distinguishes "0" from zero return value
  */  
  char *endptr;
  if ( long l = strtol(val, &endptr, 10); (l >= 0) && (l < 16) && (endptr != val))
  {
    convertedCommand = l;    
  }
  else
  {
    Serial.println("Invalid input value.\n");    // l = 0 (error) not parsed 0 value
    Serial.println("Input an integer between 0 and 15 (inclusive) in decimal format.\n");
    sendData = false;
  }
}


// write the 4-bit command to the output pins and begin the read-enable pulse
static void sendCommand(uint8_t convCmd)
{
  // set 4-bit command output
  digitalWrite(commandPin_bit0, convCmd & 1);        // set to bit 0 value
  digitalWrite(commandPin_bit1, (convCmd & 2) >> 1); // set to bit 1 value
  digitalWrite(commandPin_bit2, (convCmd & 4) >> 2); // set to bit 2 value
  digitalWrite(commandPin_bit3, (convCmd & 8) >> 3); // set to bit 3 value
  
  // begin output pulse for indicating command ready to be read
  digitalWrite(commandPins_ready, HIGH);
}


static void commandInfo()
{
  Serial.print("Command: ");
  Serial.println(command);
  
  Serial.print("4-bit command: ");
  Serial.print((convertedCommand & 8) >> 3);
  Serial.print((convertedCommand & 4) >> 2);
  Serial.print((convertedCommand & 2) >> 1);
  Serial.println(convertedCommand & 1);
  
  // output pins must not be floating for digitalRead to work
  Serial.print("Command pins: ");
  Serial.print(digitalRead(commandPin_bit3));     
  Serial.print(digitalRead(commandPin_bit2)); 
  Serial.print(digitalRead(commandPin_bit1)); 
  Serial.println(digitalRead(commandPin_bit0));
  
  Serial.print("CPLD output: ");
  Serial.print(digitalRead(CPLDPin_bit0));     
  Serial.print(digitalRead(CPLDPin_bit1)); 
  Serial.print(digitalRead(CPLDPin_bit2)); 
  Serial.println(digitalRead(CPLDPin_bit3));

  Serial.print("Command sent: ");
  Serial.println(sendData ? "yes" : "no");
  Serial.println();
}
