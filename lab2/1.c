/*
This code will cause a TekBot connected to the AVR board to
move forward and when it touches an obstacle, it will reverse
and turn away from the obstacle and resume forward motion.

PORT MAP
Port B, Pin 4 -> Output -> Right Motor Enable
Port B, Pin 5 -> Output -> Right Motor Direction
Port B, Pin 7 -> Output -> Left Motor Enable
Port B, Pin 6 -> Output -> Left Motor Direction
Port D, Pin 1 -> Input -> Left Whisker
Port D, Pin 0 -> Input -> Right Whisker
*/

#define F_CPU 16000000
#include <avr/io.h>
#include <util/delay.h>
#include <stdio.h>

int main(void)
{

    DDRB =0b11110000;   //Set up Port B for Input/Output
    PORTB=0b11110000;   //Turn off both motors

    DDRD =0b00000000;   //Set up Port D for Input/Output
    PORTD=0b00000011;   //Set pullup resistors on

    PORTB=0b01100000;   //Move forward
    
    while (1)                           // Loop Forever
        {
            if((PIND | 0b11111100) == 0b11111110){ //Right whisker hit when PIND == 0bxxxxxx10
                PORTB=0b00000000;   //Reverse
                _delay_ms(1000);
                PORTB=0b00100000; //Turn Left
                _delay_ms(1000);
                PORTB=0b01100000;   //Move forward
            }
            else if((PIND | 0b11111100) == 0b11111101 || (PIND | 0b11111100) == 0b11111100){ //Left whisker hit or both whiskers hit at once
                PORTB=0b00000000;   //Reverse
                _delay_ms(1000);
                PORTB=0b01000000; //Turn Right
                _delay_ms(1000);
                PORTB=0b01100000;   //Move forward
            }
        };
    }
