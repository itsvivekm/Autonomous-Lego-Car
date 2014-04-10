# Include nios_macros.s to workaround a bug in the movia pseudo-instruction.
.include "C:/Users/Vivek/Desktop/Auto-lego-assembly-2/nios_macros.s"

.equ JP1, 0x10000060
.equ DIR, 0x07f557ff
.equ LEDG, 0x10000010
.equ LEDR, 0x10000000
.equ TIMER, 0x10002000
.equ KEYBOARD, 0x10000100
.equ PERIOD, 100000000
.equ ADDR_7SEG1, 0x10000020
.equ ADDR_7SEG2, 0x10000030

.global main

main:
	movia sp, 0x7ffffc
	movia r8, JP1			# Copy address of JP1 into r8
	movia r9, DIR			# Store direction register values
	stwio r9, 4(r8)			# Initialise direction register
	
	movia r15, 0xffffffff			# Stop motor 
	stwio r15, 0(r8)

	call slider				#Starts the program only if switch 1 is turned on

	
Keyboard_initialization:
	
	mov r21, r0									#Key press ID
	
	movia r23, KEYBOARD
	movi r9, 0x01								#Enable read interrupts
	stwio r9, 4 (r23)

	movi r9, 0x080                              #Storing 0b10000000
	wrctl ctl3, r9                              #ctl3 - enable IRQ7
	
	movi r9, 0b1
	wrctl ctl0, r9                              #Enabling PIE bit to 1

Wait_for_keypress:
	beq r21, r0, Wait_for_keypress

	movi r9, 0x00                              #Restoring 0b00000000
	wrctl ctl3, r9                              #ctl3 - disable IRQ7
	
	movi r9, 0b0
	wrctl ctl0, r9                              #Disabling PIE bit to 0
	
	movui r4, %lo(125000)
	movui r5, %hi(125000)
	
	movi r23, 1									#Check Key ID
	beq r21, r23, Key_A_is_pressed
	movi r23, 2
	beq r21, r23, Key_S_is_pressed
	movi r23, 3
	beq r21, r23, Key_W_is_pressed
	
	br Keyboard_initialization

Key_S_is_pressed:	

	movi r23, 30
	
time_right_0:
	movi r19, 3 
	br turn_right
right_0_for_sec:
	subi r23, r23, 1
	call timer
	call timer
	bne r23, r0, time_right_0

	br Key_W_is_pressed
	
Key_A_is_pressed:	
	movi r23, 30
	
time_left_0:
	movi r19, 3
	movi r19, 3
	br turn_left
left_0_for_sec:
	subi r23, r23, 1
	call timer
	call timer
	bne r23, r0, time_left_0

	

Key_W_is_pressed:	

	call stop_sometime

Timer_initialization:
	 
	 movi r21, 0
	 
	 movia r23, TIMER
	 movui r9, %lo(PERIOD)								#Configure timer
	 stwio r9, 8 (r23)
	 movui r9, %hi (PERIOD)
	 stwio r9, 12 (r23)
	 stwio r0, 0 (r23)								#Starts the timer
	 
	 movi r9, 0b101								#Start, continue, enable interrupt
	 stwio r9, 4 (r23)

	 movi r9, 0x01                                             #Storing 0b00001
	 wrctl ctl3, r9                                             #ctl3 - enable IRQ0

	 movi r9, 0b1
	 wrctl ctl0, r9                                             #Enabling PIE bit to 1

Wait_for_timer:
		beq r21, r0, Wait_for_timer
		
	movi r9, 0x00                              #Restoring 0b00000000
	wrctl ctl3, r9                              #ctl3 - disable IRQ0
	
	movi r9, 0b0
	wrctl ctl0, r9                              #Disabling PIE bit to 0
	
	
	movia r15, 0xfffffbff	# Activate only sensor0 
	stwio r15, 0(r8)
	
	mov r23, r0				#Initialize Turn time
	mov r21, r0				#Initialize Junk value counter
	movui r4, %lo(125000)
	movui r5, %hi(125000)
	
	
	

check_sensor_0:
	movia r7, 0x0FFC00
	ldwio r18, 0(r8)
	or r18, r18, r7
	movia r7, 0xfffffbff
	ldwio r18, 0(r8)
	and r18, r18, r7
	stwio r18, 0(r8) 

	ldwio r10, 0(r8)
	srli r10, r10, 11				# get the ready bit to the right
	andi r10, r10, 0x1				# extract the ready bit

	bne r10, r0, check_sensor_0		# if sensor is not ready yet, then repeat the above 2 steps

	ldwio r11, 0(r8)
	srli r11, r11, 27				# move 27 bits to the right
	andi r11, r11, 0x0F				# extract sensor values (bits 27..30)

	call check_sensor_1
	
	
sensor_comparison:

	movi r20, 2						#Threshold for direction
	movi r19, 1						#Forward id
	
	movi r9, 5						#Threshold for down light
	blt r2, r9, stop_motor
	
	movi r9, 11						#Threshold for front light
	bge r11, r9, reset_counter_to_move_forward
	
change_direction:
	addi r21, r21, 1
	blt r21, r20, move_motor12_forward
	
	mov r21, r0

	call stop_sometime
	

	movi r23, 20
time_backward:
	call check_sensor_1
	movi r9, 5						#Threshold for down light
	blt r2, r9, stop_motor
	
	br move_motor12_backward
backward_for_sec:
	subi r23, r23, 1
	call timer
	call timer
	bne r23, r0, time_backward

	call stop_sometime


	movi r23, 45
time_right_1:
	movi r9, 5						#Threshold for down light
	blt r2, r9, stop_motor
	
	call check_sensor_1
	movi r19, 1
	br turn_right
right_1_for_sec:
	subi r23, r23, 1
	call timer
	call timer
	bne r23, r0, time_right_1

	call stop_sometime

	
	movi r23, 20
time_forward_1:
	movi r9, 5						#Threshold for down light
	blt r2, r9, stop_motor
	
	call check_sensor_1
	movi r19, 2
	br move_motor12_forward
forward_1_for_sec:
	subi r23, r23, 1
	call timer
	call timer
	bne r23, r0, time_forward_1

	call stop_sometime

		
	movi r23, 42
time_left:
	movi r9, 5						#Threshold for down light
	blt r2, r9, stop_motor
	
	call check_sensor_1
	movi r19, 1
	br turn_left
left_for_sec:
	subi r23, r23, 1
	call timer
	call timer
	bne r23, r0, time_left

	call stop_sometime

		
	movi r23, 40
time_forward_2:
	movi r9, 5						#Threshold for down light
	blt r2, r9, stop_motor
	
	call check_sensor_1
	movi r19, 3
	br move_motor12_forward
forward_2_for_sec:
	subi r23, r23, 1
	call timer
	call timer
	bne r23, r0, time_forward_2

	call stop_sometime

	
	movi r23, 50
time_left_2:
	movi r9, 5						#Threshold for down light
	blt r2, r9, stop_motor
	
	call check_sensor_1
	movi r19, 2
	br turn_left
left_2_for_sec:
	subi r23, r23, 1
	call timer
	call timer
	bne r23, r0, time_left_2
	
	call stop_sometime

	
	movi r23, 15
time_forward_4:
	movi r9, 5						#Threshold for down light
	blt r2, r9, stop_motor
	
	call check_sensor_1
	movi r19, 4
	br move_motor12_forward
forward_4_for_sec:
	subi r23, r23, 1
	call timer
	call timer
	bne r23, r0, time_forward_4
	
	call stop_sometime
	
	
	movi r23, 42
time_right_2:
	movi r9, 5						#Threshold for down light
	blt r2, r9, stop_motor
	
	call check_sensor_1
	movi r19, 2
	br turn_right
right_2_for_sec:
	subi r23, r23, 1
	call timer
	call timer
	bne r23, r0, time_right_2
	
	movi r23, 4
	
	
	call stop_sometime
	
	#br stop_motor
	br check_sensor_0	
	
	#br move_motor12_backward
	#br move_motor12_forward

	
stop_sometime:
	subi sp, sp, 4
	stw ra, 0(sp)
	
	movi r23, 4
	movia r15, 0xffffffff			# Activate only sensor0 
	stwio r15, 0(r8)
stop_for_sec_9:
	subi r23, r23, 1
	call timer
	call timer
	bne r23, r0, stop_for_sec_9
	
	ldw ra, 0(sp)
	addi sp, sp, 4
ret	
	
reset_counter_to_move_forward:
	mov r21, r0
	br move_motor12_forward
	
turn_left:
	movia r14, 0xffffffff
	stwio r14, 0(r8)
	call timer
	movia r14, 0xfffffff8
	stwio r14, 0(r8)
	
	movia r22, LEDG
	movi r14, 0xffffff08
	stwio r14, 0(r22)
	
	movia r22, ADDR_7SEG1
	movia r14, 0x38797107
	stwio r14, 0(r22)
	
	movia r22, ADDR_7SEG2
	movia r14, 0x00000000
	stwio r14, 0(r22)
	
	call timer
	movi r17, 1
	beq r19, r17, left_for_sec
	movi r17, 2
	beq r19, r17, left_2_for_sec
	movi r17, 3
	beq r19, r17, left_0_for_sec

	br check_sensor_0
	
turn_right:
	movia r14, 0xffffffff
	stwio r14, 0(r8)
	call timer
	movia r14, 0xfffffff2
	stwio r14, 0(r8)
	
	movia r22, LEDG
	movi r14, 0xffffff01
	stwio r14, 0(r22)
	
	movia r22, ADDR_7SEG1
	movia r14, 0x07000000
	stwio r14, 0(r22)
	
	movia r22, ADDR_7SEG2
	movia r14, 0x61067B76
	stwio r14, 0(r22)
	
	call timer
	movi r17, 1
	beq r19, r17, right_1_for_sec
	movi r17, 2
	beq r19, r17, right_2_for_sec
	movi r17, 3
	beq r19, r17, right_0_for_sec
	
	br check_sensor_0

move_motor1_forward:	
	movia r14, 0xffffffff
	stwio r14, 0(r8)
	call timer
	movia r14, 0xfffffffe
	stwio r14, 0(r8)
	call timer
	br check_sensor_0


move_motor2_forward:	
	movia r14, 0xffffffff
	stwio r14, 0(r8)
	call timer
	movia r14, 0xfffffffb
	stwio r14, 0(r8)
	call timer
	br check_sensor_0

	
	
check_sensor_1:
	subi sp, sp, 4
	stw ra, 0(sp)

loop_in_sensor_1:
	movia r7, 0x0FFC00
	ldwio r18, 0(r8)
	or r18, r18, r7
	movia r7, 0xffffefff
	and r18, r18, r7
	stwio r18, 0(r8) 

	ldwio r10, 0(r8)
	srli r10, r10, 13				# get the ready bit to the right
	andi r10, r10, 0x1				# extract the ready bit

	bne r10, r0, loop_in_sensor_1		# if sensor is not ready yet, then repeat the above 2 steps

	ldwio r2, 0(r8)
	srli r2, r2, 27					# move 27 bits to the right
	andi r2, r2, 0x0F				# extract sensor values (bits 27..30)
		
	ldw ra, 0(sp)
	addi sp, sp, 4
ret
	
move_motor12_forward:	
	movia r14, 0xffffffff
	stwio r14, 0(r8)
	call timer
	call timer
	movia r14, 0xfffffffa
	stwio r14, 0(r8)
	
	movia r22, LEDG
	movi r14, 0xffffff02
	stwio r14, 0(r22)
	
	movia r22, ADDR_7SEG1
	movia r14, 0x07000000
	stwio r14, 0(r22)
	
	movia r22, ADDR_7SEG2
	movia r14, 0x71613F37
	stwio r14, 0(r22)
	
	call timer
	movi r17, 1
	beq r19, r17, check_sensor_0
	movi r17, 2
	beq r19, r17, forward_1_for_sec
	movi r17, 3
	beq r19, r17, forward_2_for_sec
	movi r17, 4
	beq r19, r17, forward_4_for_sec

	br check_sensor_0

move_motor1_backward:
	movia r14, 0xffffffff
	stwio r14, 0(r8)
	call timer
	movia r14, 0xfffffffc
	stwio r14, 0(r8)
	call timer
	br check_sensor_0


move_motor2_backward:
	movia r14, 0xffffffff
	stwio r14, 0(r8)
	call timer
	movia r14, 0xfffffff3
	stwio r14, 0(r8)
	call timer
	br check_sensor_0


move_motor12_backward:
	movia r14, 0xffffffff
	stwio r14, 0(r8)
	
	movia r22, LEDG
	movi r14, 0xffffff04
	stwio r14, 0(r22)
	
	movia r22, ADDR_7SEG1
	movia r14, 0x7F773970
	stwio r14, 0(r22)
	
	movia r22, ADDR_7SEG2
	movia r14, 0x00000000
	stwio r14, 0(r22)
	
	call timer
	call timer
	movia r14, 0xfffffff0
	stwio r14, 0(r8)
	call timer
	
	br backward_for_sec
	


stop_motor:
	movia r15, 0xfffffbff			# Activate only sensor0 
	stwio r15, 0(r8)
	
	movia r22, LEDG
	movi r14, 0xffffff00
	stwio r14, 0(r22)
	
	movia r22, LEDR
	movi r14, 0xffffffff
	stwio r14, 0(r22)
	
	movia r22, ADDR_7SEG1
	movia r14, 0x6D073F73
	stwio r14, 0(r22)
	
	movia r22, ADDR_7SEG2
	movia r14, 0x00000000
	stwio r14, 0(r22)
	
	br stop_motor
	#br check_sensor_0

timer:
	subi sp, sp, 8
	stw ra, 0(sp)
	stw r2, 4(sp)
	
	movia r6, 0x10002000                   	 /* r7 contains the base address for the timer */
   	mov r2, r4
   	stwio r2, 8(r6)                          /* Set the period to be 50000 clock cycles */
   	mov r2, r5
   	stwio r2, 12(r6)

   	movui r2, 4
   	stwio r2, 4(r6)                          /* Start the timer without continuing or interrupts */


timer_read:

  	stwio r0,16(r6)             	/* Tell Timer to take a snapshot of the timer */
   	ldwio r3,16(r6)             	/* Read snapshot bits 0..15 */
   	ldwio r13,20(r6)             	/* Read snapshot bits 16...31 */
   	slli  r13,r13,16			/* Shift left logically */
   	or    r13,r13,r3               	/* Combine bits 0..15 and 16...31 into one register */

	ldwio r16, 0(r6)
	srli r16, r16, 1
	andi r16, r16, 0x1

	bne r16, r0, timer_read 

	ldw ra, 0(sp)
	ldw r2, 4(sp)
	addi sp, sp, 8
ret


.section .exceptions, "ax"
MyISR:
	
 subi sp, sp, 16                                           #Save ea, et, ctl1
 stw et, 0 (sp)
 rdctl et, ctl1
 stw et, 4 (sp)
 stw ea, 8 (sp)
 stw r23, 12 (sp)



 rdctl et, ctl4
 
 andi et, et, 0x080
 bne et, r0, HANDLE_KEYBOARD_INTERRUPT
 
 rdctl et, ctl4
 andi et, et, 0x1
 bne et, r0, HANDLE_TIMER_INTERRUPT
 
 br EXIT_HANDLER
 
HANDLE_TIMER_INTERRUPT:
    movia r23, TIMER
    #ldwio et, 0 (r23 )
    #andi et, et, 0xFFFE
    stwio r0, 0 (r23)                                        #Timer Acknowledged
	movi r21, 1

	br EXIT_HANDLER
	

HANDLE_KEYBOARD_INTERRUPT:
	movia r23, KEYBOARD
	ldb et, 0 (r23)											#Read the Key pressed and acknowledge keyboard
	andi et, et, 0x0ff										#Mask 7-0 bits
	
HANDLE_KEYS:
	movi r23, 0x1c											#Key 'a' is pressed
	bne et, r23, NOT_A
	movi r21, 1
	br RESET_KEYBOARD

NOT_A:
	movi r23, 0x1b											#Key 's' is pressed
#	bne r22, r23, NOT_FOUND
	bne et, r23, NOT_S
	movi r21, 2
	br RESET_KEYBOARD

NOT_S:
	movi r23, 0x1d											#Key 'w' is pressed
	bne et, r23, NOT_FOUND
 	movi r21, 3
	br RESET_KEYBOARD
	
NOT_FOUND:
	movi r21, 0
	
RESET_KEYBOARD:
	srli et, et, 16										#Shift right to get next key press
	bne et, r0, HANDLE_KEYBOARD_INTERRUPT
	
EXIT_HANDLER:
 
	ldw et, 4 (sp)
	wrctl ctl1, et
	ldw et, 0 (sp)
	ldw ea, 8 (sp)
	ldw r23, 12 (sp)
	 
	addi sp, sp, 16
	subi ea, ea, 4
eret

