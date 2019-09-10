org 0000H



;defining inputs

hbut equ p1.0;

mbut equ p1.1;

abut equ p1.2;

sbut equ p1.3;


;setting up clock registers
;starting from the first GPR
sec equ 30H
minL equ 32H
minH equ 33H

hrs12L equ 34H
hrs12H equ 35H
hrs24L equ 36H
hrs24H equ 37H
;setting up alarm registers
;will work for both 12hrs and 24hrs systems

amin1L equ 38H
amin1H equ 39H
ahrs1L equ 3AH
ahrs1H equ 3BH

amin2L equ 3CH
amin2H equ 3DH
ahrs2L equ 3EH
ahrs2H equ 3FH

alm1 equ 1AH;
alm2 equ 1BH;


;initial conditions
setb hbut; setting input to active low mode
setb mbut; setting input to active low mode
setb abut; setting input to active low mode
setb sbut; setting input to active low mode


clr alm1;
clr alm2;


mov hrs24H,#00H;
mov hrs24L,#00H;
mov hrs12H,#1H; initiate clock at 12:00
mov hrs12L,#2H;
mov minh,#00H;
mov minL,#00H;

mov amin1L, #11D; initialize alarm registers with impossible values : disable alarm
mov amin1H, #11D;
mov ahrs1L, #11D;
mov ahrs1H, #11D;

mov amin2L, #11D; initialize alarm registers with impossible values : disable alarm
mov amin2H, #11D;
mov ahrs2L, #11D;
mov ahrs2H, #11D;



mov p3,#00H;

mov R2,#00H;


clksetmod:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Josh's part

mov p1,#11111111B; initialize port0 waiting for input.


jnb sbut,clksetmod;

; give enough time to release set button , otherwise the clocksetmode will jump back to 24 hrs loop when brancehd into from mod12/24.
; give neough time for sbut to be released ad mbut to be pressed

jb mbut,addntn1; if not pressed to ground .. add ntn to mins , if bit is pressed "not set prceed to add 1 to mins

w8releasembut:
mov p1,#11111111B; initialize port0 waiting for input. 
;noo need for a delay , wont commence unless unpressed
jnb mbut,w8releasembut;

inc minL; 1 min has passed
mov r3,minL;
cjne r3,#10D,display_clksetmod; w8 for 10 mins
mov minL,#00H;

;tenmin:

inc minH; 10 mins have passed
mov r3,minH;
cjne r3,#6D,display_clksetmod; w8 for 60 mins.
mov minH,#00H;


jmp display_clksetmod;

addntn1:

mov p1,#11111111B
;maybe need a delay here
jb hbut,addntn2;  inc 24hrsL by 1

w8releasehbut:
mov p1,#11111111B; initialize port0 waiting for input. 
;noo need for a delay , wont commence unless unpressed
jnb hbut,w8releasehbut;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;before you add a new hour , check this first
mov r3,hrs12H;
cjne r3,#1D,w8tenhrs_clksetmod; jump if it's not 1x:xx , if it is , check second digit.
mov r3,hrs12L
cjne r3,#2D, w8tenhrs_clksetmod; contiune to clear if its 12:xx other wise , add up to 2 hrs

mov hrs12L,#00H; if its the first hour to be added after 12:00 clear the hour digits first.
mov hrs12H,#00H;

w8tenhrs_clksetmod:
inc hrs12L; 1 hr has passed


;before you add a new hour to 24 registers
mov r3,hrs24H;
cjne r3,#2D,w8twentyhrs_clksetmod; if its 2x:xx check for second hours digit, otherwise , jump to normal
mov r3,hrs24L;
cjne r3,#3D,w8twentyhrs_clksetmod; if its 23:xx commence to clear 24 hrs bytes, otherwise, you can still add up to 3 hours.
mov hrs24L,#00H;
mov hrs24H,#00H;
jmp commence_clksetmod; after 23:59 should turn into 00:00 not 01:00


w8twentyhrs_clksetmod:
inc hrs24L; sync it with the 24h reg

mov r3,hrs24L;
cjne r3, #10D,commence_clksetmod;
mov hrs24L,#00H;

;ten hrs has passed in 24 mode
inc hrs24H; sync it with 24h (10:00) or (20:00)


commence_clksetmod:

mov R3,hrs12L;
CJNE R3,#10D,display_clksetmod;
mov hrs12L,#00H;
inc hrs12H; increase 12hrs high only when 10 hrs has passed (now the time is 10:00)

;jmp display12; finished 10 hrs w8ting for more


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


addntn2:


;dsiplay current 24 registers
display_clksetmod:

MOV DPTR, #seg7values ; load address of lookup table into DPTR
;MOV R0, #0 ; initialize R0 to 1st element in lookup table

MOV R1,#00000001B; set the display to first 7seg
MOV A, hrs24H ; point to appropriate binary code
MOVC A, @A+DPTR ; load current byte pointed by (A+DPTR) to Acc
MOV p0, A ; display value of hrs24H
MOV p2, R1 ; choose appropriate display for that register (first one)
LCALL dispdelay;


MOV R1,#00000010B; set the display to second 7seg
MOV A, hrs24L ; load hrs24L to accumulator
MOVC A, @A+DPTR ; load current byte pointed by (A+DPTR) to Acc
MOV p0, A ; display value of hrs24L
MOV p2, R1 ; choose appropriate display for that register (second one)
LCALL dispdelay;



MOV R1,#00000100B; set the display to Third 7seg
MOV A, minh ; load minh to accumulator
MOVC A, @A+DPTR ; load current byte pointed by (A+DPTR) to Acc
MOV p0, A ; display value minH
MOV p2, R1 ; choose appropriate display for that register (third one)
LCALL dispdelay;



MOV R1,#00001000B; set the display to Fourth 7seg
MOV A, minL ; load minL to accumulator
MOVC A, @A+DPTR ; load current byte pointed by (A+DPTR) to Acc
MOV p0, A ; display value minL
MOV p2, R1 ; choose appropriate display for that register (fourth one)
LCALL dispdelay;
mov p2,#00H; unselect fourth 7seg


mov p1,#11111111B; initialize port0 waiting for input. 
;maybe need a delay here
jnb abut,mod24 ; jump to main again if alarm button is pressed


jmp clksetmod; repeat clksetmod until all set

;other than the initial values , user can choose to set the starting time when he turns the clock on.
;uses same dsiplay function of the registers.
;registers are being jumped back to after each display cycle
;a check will be run on hbut and mbut , if any pressed , icreament relevant register by 1;
;jump back to display and check

;when all values are set , commence to main function : mod24:
;check what to do next



;finish clock edit mode by ret to main function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mod24:

;make sure all buttons are unpressed

mov p1,#11111111B; initialize port0 waiting for input. 

jnb hbut,mod24 ; jump back until button is released 
jnb sbut,mod24;
jnb abut,mod24;
jnb mbut,mod24;

mov p3,#00000000B;

jnb alm1,troll1;
mov p3,#11111111B;

troll1:
jnb alm2,troll2;
mov p3,#11111111B;
troll2:


;set p3 if alarm sounding register 1 is set : sound alarm 1
;set p3 if alarm sounding register 2 is set : sound alarm 2


lcall delay;

mov p1,#11111111B; check if user wants to stop alarm for toaday
JB mbut,nodisable;


mov amin1L, #11D; initialize alarm registers with impossible values : disable alarm
mov amin1H, #11D;
mov ahrs1L, #11D;
mov ahrs1H, #11D;

mov amin2L, #11D; initialize alarm registers with impossible values : disable alarm
mov amin2H, #11D;
mov ahrs2L, #11D;
mov ahrs2H, #11D;
mov p3,#00000000B; mute the buzzer

nodisable:
clr alm1;
clr alm2;


;set p1
;jnb sbut,mode12;

cjne r2,#60D,disp_jmp1;
sjmp jumpover;

disp_jmp1:
jmp display24;

jumpover:

mov R2,#00H;

;clock: ; another code to set the value of the clock registers

;onesec:


setb P2.1 ; choose the second 7seg
;clr P0.7; blink the decimal point
MOV p0,#01111111B; decimal point blinking cure
lcall dispdelay;

inc sec;
clr p2.1; un-choose second 7seg 
;setb  P0.7; clear decimal point

mov r3,sec;
cjne r3, #60D,disp_jmp2; ; w8 for 60 secs 
sjmp jumpover1;
disp_jmp2:
jmp display24 
Jumpover1:
mov sec,#00H ;

;onemin:

inc minL; 1 min has passed
mov r3,minL;
cjne r3,#10D,display24; w8 for 10 mins
mov minL,#00H;

;tenmin:

inc minH; 10 mins have passed
mov r3,minH;
cjne r3,#6D,display24; w8 for 60 mins.
mov minH,#00H;

;hourly chime

mov p3,#11111111B;
;setb P3.1; turn buzzer on
lcall rmvfing; sound the buzz for 2 ms
;CLR P3.1; stop the hourly based buzz 
mov P3,#00000000B


;before you add a new hour , check this first
mov r3,hrs12H;
cjne r3,#1D,w8tenhrs24; jump if it's not 1x:xx , if it is , check second digit.
mov r3,hrs12L
cjne r3,#2D, w8tenhrs24; contiune to clear if its 12:xx other wise , add up to 2 hrs

mov hrs12L,#00H; if its the first hour to be added after 12:00 clear the hour digits first.
mov hrs12H,#00H;

w8tenhrs24:
inc hrs12L; 1 hr has passed


;before you add a new hour to 24 registers
mov r3,hrs24H;
cjne r3,#2D,w8twentyhrs24; if its 2x:xx check for second hours digit, otherwise , jump to normal
mov r3,hrs24L;
cjne r3,#3D,w8twentyhrs24; if its 23:xx commence to clear 24 hrs bytes, otherwise, you can still add up to 3 hours.
mov hrs24L,#00H;
mov hrs24H,#00H;
jmp commence24; after 23:59 should turn into 00:00 not 01:00


w8twentyhrs24:
inc hrs24L; sync it with the 24h reg

mov r3,hrs24L;
cjne r3, #10D,commence24;
mov hrs24L,#00H;

;ten hrs has passed in 24 mode
inc hrs24H; sync it with 24h (10:00) or (20:00)


commence24:

mov R3,hrs12L;
CJNE R3,#10D,display24;
mov hrs12L,#00H;
inc hrs12H; increase 12hrs high only when 10 hrs has passed (now the time is 10:00)

jmp display24; finished 10 hrs w8ting for more



display24:
;compare alarm registers with clock registers :		

Checkalm:

clr alm1; turn alarm off after 1 min
clr alm2;

MOV A ,amin1L
CJNE A,minL,NOALM1

MOV A ,amin1H
CJNE A,minH,NOALM1

MOV A, ahrs1L
CJNE A,hrs24L ,NOALM1

MOV A,ahrs1H
CJNE A,hrs24H,NOALM1

setb alm1; turn alarm 1 on if current time registers are equal to set alarm registers 

;;;;;
NOALM1:	
MOV A ,amin2L
CJNE A,minL,NOALM2

MOV A ,amin2H
CJNE A,minH,NOALM2

MOV A,ahrs2L
CJNE A,hrs24L ,NOALM2

MOV A,ahrs2H
CJNE A,hrs24H,NOALM2

setb alm2;

NOALM2: 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



MOV DPTR, #seg7values ; load address of lookup table into DPTR
;MOV R0, #0 ; initialize R0 to 1st element in lookup table

MOV R1,#00000001B; set the display to first 7seg
MOV A, hrs24H ; point to appropriate binary code
MOVC A, @A+DPTR ; load current byte pointed by (A+DPTR) to Acc
MOV p0, A ; display value of hrs24H
MOV p2, R1 ; choose appropriate display for that register (first one)
LCALL dispdelay;


MOV R1,#00000010B; set the display to second 7seg
MOV A, hrs24L ; load hrs24L to accumulator
MOVC A, @A+DPTR ; load current byte pointed by (A+DPTR) to Acc
MOV p0, A ; display value of hrs24L
MOV p2, R1 ; choose appropriate display for that register (second one)
LCALL dispdelay;



MOV R1,#00000100B; set the display to Third 7seg
MOV A, minh ; load minh to accumulator
MOVC A, @A+DPTR ; load current byte pointed by (A+DPTR) to Acc
MOV p0, A ; display value minH
MOV p2, R1 ; choose appropriate display for that register (third one)
LCALL dispdelay;



MOV R1,#00001000B; set the display to Fourth 7seg
MOV A, minL ; load minL to accumulator
MOVC A, @A+DPTR ; load current byte pointed by (A+DPTR) to Acc
MOV p0, A ; display value minL
MOV p2, R1 ; choose appropriate display for that register (fourth one)
LCALL dispdelay;
mov p2,#00H; unselect fourth 7seg

mov p1,#11111111B; initialize port0 waiting for input. 

jnb hbut,mod12_jmp ; jump to 12hrs mode if hrs push button is pressed (if p1.0 is not set anymore)
jnb sbut,clksetmod_jmp24; jnb only got relative addressing, therfore we jump for another close instruciton that can perform absoulute jump
jnb abut,alrsetmod_jmp24;

jmp mod24 ; repeat mod24 loop

mod12_jmp:
jmp mod12;

clksetmod_jmp24:
jmp clksetmod;

alrsetmod_jmp24:

mov amin1L, #00H; load possible initial values for alarm registers first :enable alarm
mov amin1H, #00H;
mov ahrs1L, #00H;
mov ahrs1H, #00H;

mov amin2L, #00H; 
mov amin2H, #00H;
mov ahrs2L, #00H;
mov ahrs2H, #00H;

jmp alrsetmod;

mod12:

;make sure all buttons are unpressed

mov p1,#11111111B; initialize port0 waiting for input. 

jnb hbut,mod12 ; jump back until button is released 
jnb sbut,mod12;
jnb abut,mod12;
jnb mbut,mod12;

lcall delay;


cjne r2,#100D,display12;

mov R2,#00H;

;clock ; another code to set the value of the clock registers

;onesec:


setb P2.1 ; choose the second 7seg
;clr P0.7; blink the decimal point
MOV p0,#01111111B; decimal point blinking cure
lcall dispdelay;

inc sec;
clr p2.1; un-choose second 7seg 
;setb  P0.7; clear decimal point

mov r3,sec;
cjne r3, #60D, display12 ; w8 for 60 secs
mov sec,#00H ;

;onemin:

inc minL; 1 min has passed
mov r3,minL;
cjne r3,#10D,display12; w8 for 10 mins
mov minL,#00H;

;tenmin:

inc minH; 10 mins have passed
mov r3,minH;
cjne r3,#6D,display12; w8 for 60 mins.
mov minH,#00H;

;hourly chime

mov p3,#11111111B;
;setb P3.1; turn buzzer on
lcall rmvfing; sound the buzz for 2 ms
;CLR P3.1; stop the hourly based buzz 
mov p3,#00000000B;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;before you add a new hour , check this first
mov r3,hrs12H;
cjne r3,#1D,w8tenhrs12; jump if it's not 1x:xx , if it is , check second digit.
mov r3,hrs12L
cjne r3,#2D, w8tenhrs12; contiune to clear if its 12:xx other wise , add up to 2 hrs

mov hrs12L,#00H; if its the first hour to be added after 12:00 clear the hour digits first.
mov hrs12H,#00H;

w8tenhrs12:
inc hrs12L; 1 hr has passed


;before you add a new hour to 24 registers
mov r3,hrs24H;
cjne r3,#2D,w8twentyhrs12; if its 2x:xx check for second hours digit, otherwise , jump to normal
mov r3,hrs24L;
cjne r3,#3D,w8twentyhrs12; if its 23:xx commence to clear 24 hrs bytes, otherwise, you can still add up to 3 hours.
mov hrs24L,#00H;
mov hrs24H,#00H;
jmp commence12; after 23:59 should turn into 00:00 not 01:00


w8twentyhrs12:
inc hrs24L; sync it with the 24h reg

mov r3,hrs24L;
cjne r3, #10D,commence12;
mov hrs24L,#00H;

;ten hrs has passed in 24 mode
inc hrs24H; sync it with 24h (10:00) or (20:00)


commence12:

mov R3,hrs12L;
CJNE R3,#10D,display12;
mov hrs12L,#00H;
inc hrs12H; increase 12hrs high only when 10 hrs has passed (now the time is 10:00)

;jmp display12; finished 10 hrs w8ting for more


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




display12:

MOV DPTR, #seg7values ; load address of lookup table into DPTR
;MOV R0, #0 ; initialize R0 to 1st element in lookup table

MOV R1,#00000001B; set the display to first 7seg
MOV A, hrs12h ; point to appropriate binary code
MOVC A, @A+DPTR ; load current byte pointed by (A+DPTR) to Acc
MOV p0, A ; display value of hrs24H
MOV p2, R1 ; choose appropriate display for that register (first one)
LCALL dispdelay;


MOV R1,#00000010B; set the display to second 7seg
MOV A, hrs12L ; load hrs12L to accumulator
MOVC A, @A+DPTR ; load current byte pointed by (A+DPTR) to Acc
MOV p0, A ; display value of hrs24L
MOV p2, R1 ; choose appropriate display for that register (second one)
LCALL dispdelay;



MOV R1,#00000100B; set the display to Third 7seg
MOV A, minh ; load minh to accumulator
MOVC A, @A+DPTR ; load current byte pointed by (A+DPTR) to Acc
MOV p0, A ; display value minH
MOV p2, R1 ; choose appropriate display for that register (third one)
LCALL dispdelay;



MOV R1,#00001000B; set the display to Fourth 7seg
MOV A, minL ; load minL to accumulator
MOVC A, @A+DPTR ; load current byte pointed by (A+DPTR) to Acc
MOV p0, A ; display value minL
MOV p2, R1 ; choose appropriate display for that register (fourth one)
LCALL dispdelay;
mov p2,#00H; unselect fourth 7seg


mov p1,#11111111B; initialize port0 waiting for input. 

jnb hbut,mod24_jmp; jump to 24hrs mode if hrs push button is pressed (if p1.0 is not set anymore)
jnb sbut,clksetmod_jmp12; nb only got relative addressing, therfore we jump for another close instruciton that can perform absoulute jump
jnb abut,alrsetmod_jmp12;

jmp mod12 ; repeat mod12 loop

mod24_jmp:
jmp mod24;

clksetmod_jmp12:
jmp clksetmod;

alrsetmod_jmp12:
jmp alrsetmod;



; forget about 12 hours mode , we will develope the alarm with 24 mode only ;; once 24 loop is ready .. we copy it to 12 hrs.

;focus on interacting ONLY WITH 24MOD.

alrsetmod:


mov p1,#11111111B; initialize port0 waiting for input.


jnb abut,alrsetmod;

; give enough time to release set button , otherwise the clocksetmode will jump back to 24 hrs loop when brancehd into from mod12/24.
; give neough time for sbut to be released ad mbut to be pressed

jb mbut,addntn1_alr1set; if not pressed to ground .. add ntn to mins , if bit is pressed "not set prceed to add 1 to mins

w8releasembut_alr1set:
mov p1,#11111111B; initialize port0 waiting for input. 
;noo need for a delay , wont commence unless unpressed
jnb mbut,w8releasembut_alr1set;

inc amin1L; 1 min has passed
mov r3,amin1L;
cjne r3,#10D,display_alr1set; w8 for 10 mins
mov amin1L,#00H;

;tenmin:

inc amin1H; 10 mins have passed
mov r3,amin1H;
cjne r3,#6D,display_alr1set; w8 for 60 mins.
mov amin1H,#00H;


jmp display_alr1set;

addntn1_alr1set:

mov p1,#11111111B
;maybe need a delay here
jb hbut,addntn2_alr1set;  inc 24hrsL by 1

w8releasehbut_alr1set:
mov p1,#11111111B; initialize port0 waiting for input. 
;noo need for a delay , wont commence unless unpressed
jnb hbut,w8releasehbut_alr1set;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;before you add a new hour to 24 registers
mov r3,ahrs1H;
cjne r3,#2D,w8twentyhrs_alr1set; if its 2x:xx check for second hours digit, otherwise , jump to normal
mov r3,ahrs1L;
cjne r3,#3D,w8twentyhrs_alr1set; if its 23:xx commence to clear 24 hrs bytes, otherwise, you can still add up to 3 hours.
mov ahrs1L,#00H;
mov ahrs1H,#00H;
jmp commence_alr1set; after 23:59 should turn into 00:00 not 01:00


w8twentyhrs_alr1set:
inc ahrs1L; sync it with the 24h reg

mov r3,ahrs1L;
cjne r3, #10D,commence_alr1set;
mov ahrs1L,#00H;

;ten hrs has passed in 24 mode
inc ahrs1H; sync it with 24h (10:00) or (20:00)


commence_alr1set:


;jmp display12; finished 10 hrs w8ting for more


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


addntn2_alr1set:


;dsiplay current 24 registers
display_alr1set:

MOV DPTR, #seg7values ; load address of lookup table into DPTR
;MOV R0, #0 ; initialize R0 to 1st element in lookup table

MOV R1,#00000001B; set the display to first 7seg
MOV A, ahrs1H ; point to appropriate binary code
MOVC A, @A+DPTR ; load current byte pointed by (A+DPTR) to Acc
MOV p0, A ; display value of hrs24H
MOV p2, R1 ; choose appropriate display for that register (first one)
LCALL dispdelay;


MOV R1,#00000010B; set the display to second 7seg
MOV A, ahrs1L ; load hrs24L to accumulator
MOVC A, @A+DPTR ; load current byte pointed by (A+DPTR) to Acc
MOV p0, A ; display value of hrs24L
MOV p2, R1 ; choose appropriate display for that register (second one)
LCALL dispdelay;



MOV R1,#00000100B; set the display to Third 7seg
MOV A, amin1h ; load minh to accumulator
MOVC A, @A+DPTR ; load current byte pointed by (A+DPTR) to Acc
MOV p0, A ; display value minH
MOV p2, R1 ; choose appropriate display for that register (third one)
LCALL dispdelay;



MOV R1,#00001000B; set the display to Fourth 7seg
MOV A, amin1L ; load minL to accumulator
MOVC A, @A+DPTR ; load current byte pointed by (A+DPTR) to Acc
MOV p0, A ; display value minL
MOV p2, R1 ; choose appropriate display for that register (fourth one)
LCALL dispdelay;
mov p2,#00H; unselect fourth 7seg


mov p1,#11111111B; initialize port0 waiting for input. 
;maybe need a delay here
jnb sbut,alrsetmod2 ; jump to main again if alarm button is pressed


jmp alrsetmod; repeat clksetmod until all set

;finish clock edit mode by ret to main function

alrsetmod2:

mov p1,#11111111B; initialize port0 waiting for input.


jnb sbut,alrsetmod2; w8 for set button to be released

; give enough time to release set button , otherwise the clocksetmode will jump back to 24 hrs loop when brancehd into from mod12/24.
; give neough time for sbut to be released ad mbut to be pressed

jb mbut,addntn1_alr2set; if not pressed to ground .. add ntn to mins , if bit is pressed "not set prceed to add 1 to mins

w8releasembut_alr2set:
mov p1,#11111111B; initialize port0 waiting for input. 
;noo need for a delay , wont commence unless unpressed
jnb mbut,w8releasembut_alr2set;

inc amin2L; 1 min has passed
mov r3,amin2L;
cjne r3,#10D,display_alr2set; w8 for 10 mins
mov amin2L,#00H;

;tenmin:

inc amin2H; 10 mins have passed
mov r3,amin2H;
cjne r3,#6D,display_alr2set; w8 for 60 mins.
mov amin2H,#00H;


jmp display_alr2set;

addntn1_alr2set:

mov p1,#11111111B
;maybe need a delay here
jb hbut,addntn2_alr2set;  inc 24hrsL by 1

w8releasehbut_alr2set:
mov p1,#11111111B; initialize port0 waiting for input. 
;noo need for a delay , wont commence unless unpressed
jnb hbut,w8releasehbut_alr2set;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;before you add a new hour to 24 registers
mov r3,ahrs2H;
cjne r3,#2D,w8twentyhrs_alr2set; if its 2x:xx check for second hours digit, otherwise , jump to normal
mov r3,ahrs2L;
cjne r3,#3D,w8twentyhrs_alr2set; if its 23:xx commence to clear 24 hrs bytes, otherwise, you can still add up to 3 hours.
mov ahrs2L,#00H;
mov ahrs2H,#00H;
jmp commence_alr2set; after 23:59 should turn into 00:00 not 01:00


w8twentyhrs_alr2set:
inc ahrs2L; sync it with the 24h reg

mov r3,ahrs2L;
cjne r3, #10D,commence_alr2set;
mov ahrs2L,#00H;

;ten hrs has passed in 24 mode
inc ahrs2H; sync it with 24h (10:00) or (20:00)


commence_alr2set:


;jmp display12; finished 10 hrs w8ting for more


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


addntn2_alr2set:


;dsiplay current 24 registers
display_alr2set:

MOV DPTR, #seg7values ; load address of lookup table into DPTR
;MOV R0, #0 ; initialize R0 to 1st element in lookup table

MOV R1,#00000001B; set the display to first 7seg
MOV A, ahrs2H ; point to appropriate binary code
MOVC A, @A+DPTR ; load current byte pointed by (A+DPTR) to Acc
MOV p0, A ; display value of hrs24H
MOV p2, R1 ; choose appropriate display for that register (first one)
LCALL dispdelay;


MOV R1,#00000010B; set the display to second 7seg
MOV A, ahrs2L ; load hrs24L to accumulator
MOVC A, @A+DPTR ; load current byte pointed by (A+DPTR) to Acc
MOV p0, A ; display value of hrs24L
MOV p2, R1 ; choose appropriate display for that register (second one)
LCALL dispdelay;



MOV R1,#00000100B; set the display to Third 7seg
MOV A, amin2h ; load minh to accumulator
MOVC A, @A+DPTR ; load current byte pointed by (A+DPTR) to Acc
MOV p0, A ; display value minH
MOV p2, R1 ; choose appropriate display for that register (third one)
LCALL dispdelay;



MOV R1,#00001000B; set the display to Fourth 7seg
MOV A, amin2L ; load minL to accumulator
MOVC A, @A+DPTR ; load current byte pointed by (A+DPTR) to Acc
MOV p0, A ; display value minL
MOV p2, R1 ; choose appropriate display for that register (fourth one)
LCALL dispdelay;
mov p2,#00H; unselect fourth 7seg


mov p1,#11111111B; initialize port0 waiting for input. 
;maybe need a delay here
jnb abut,mod24_AJMP ; jump to main again if alarm button is pressed


jmp alrsetmod2; repeat clksetmod until all set
mod24_AJMP:

JMP mod24; finish alarm registers settings

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  em+ain+faiz 

;all buttons should be released;
;mov p1,#11111111B; initialize port0 waiting for input. 

;jnb hbut,alrsetmod ; jump back until button is released 
;jnb sbut,alrsetmod;
;jnb abut,alrsetmod;
;jnb mbut,alrsetmod;


;initial alarm registers will be set to IMPOSSIBLE values; means that the alarm will be disabled by default.

;will include same clock loop , 
;but display current alarm registers which can be manipulated using hbut, mbut.

;once all set, jump back to main function (ret)

;if "abut" is pressed again any time before setting all of the values for alarm , LOAD IMPOSSIBLE VALUE , to disable alarm and exit function.

;once this function is done , clock and alarm registers comparison should be implemented within main clock loops
;when values are met in main loop , alrtrigmod will be jumped into.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; alrtrigmod: em+ain+faiz



;turn beep on , turn vibrate on  , return.
  
  
;auto stop after 1 min, manual stop, snooze will be implemented within the main function.



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;Delays


delay:
MOV TMOD, #01H ; timer 0, mode 1
MOV TL0, #44H ; TL0 = #ffH , to make timer flow each 1 us
MOV TH0, #0f8H ; TH0 = #ffH  to make timer flow each 1 us
SETB TR0 ; start timer 0
JNB TF0, $ ; stay until timer rolls over
CLR TR0 ; stop timer 0
CLR TF0 ; clear timer flag 0
inc r2;
ret

dispdelay: ;6050 us

		mov r4,#5
		Repeat:	
		mov r5,#200
	Again:
		nop
		nop
		djnz r5,Again
		djnz r4,Repeat
		ret

rmvfing: ;521224 us 
	mov R0,#1
L1:
	mov R1,#255
L2:	
	mov R2,#255
Here:
	nop
	nop
	djnz R2,Here
	djnz R1,L2
	Djnz R0,L1
	ret


;Lookup tables


seg7values:
DB 11000000B, 11111001B,10100100B,10110000B,10011001B,10010010B,10000010B,11111000B,10000000B,10011000B ;


END


