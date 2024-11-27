################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Dr Mario.
#
# Student 1: Tianxiang Zhu, 1009802536
# Student 2: Bo Xu, 1009839196
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
BASE_COLOR:
    .word 0x000000

TESTING_COLOR:
    .word 0xffffff
##############################################################################
# Mutable Data
##############################################################################
.data
colors: .word 0xffff00, 0xff0000, 0x0000ff
virus_colors: .word 0xCCCC00, 0xCC0000, 0x0000CC
# ending x and y are not inclusive
starting_x: .word 1
starting_y: .word 6
ending_x: .word 23
ending_y: .word 31
initial_x: .word 12
initial_y: .word 4
initial_x_logical: .word 10
initial_y_logical: .word -2
number_or_virus: .word 5
stack_top: .word 0 
blocks_cleared: .word 0
blocks_moved: .word 0

# Define templates for each digit (5x7 pixel matrix, row-major order)
digit_0: .word 0b01110, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110
digit_1: .word 0b00100, 0b01100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110
digit_2: .word 0b01110, 0b10001, 0b00001, 0b00010, 0b00100, 0b01000, 0b11111
digit_3: .word 0b01110, 0b10001, 0b00001, 0b00110, 0b00001, 0b10001, 0b01110
digit_4: .word 0b00010, 0b00110, 0b01010, 0b10010, 0b11111, 0b00010, 0b00010
digit_5: .word 0b11111, 0b10000, 0b11110, 0b00001, 0b00001, 0b10001, 0b01110
digit_6: .word 0b00110, 0b01000, 0b10000, 0b11110, 0b10001, 0b10001, 0b01110
digit_7: .word 0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b10000, 0b10000
digit_8: .word 0b01110, 0b10001, 0b10001, 0b01110, 0b10001, 0b10001, 0b01110
digit_9: .word 0b01110, 0b10001, 0b10001, 0b01111, 0b00001, 0b00010, 0b01100
digit_templates: .word digit_0, digit_1, digit_2, digit_3, digit_4, digit_5, digit_6, digit_7, digit_8, digit_9

pixel_color: .word 0xFFFFFF  # White color for pixels

# Temporary storage for decomposed digits
digit_array: .space 16  # Maximum of 4 digits for the score


game_time: .word 0
time_interval: .word 600
gravity_decrement: .word 5
minimum_gravity_threshold: .word 20

current_score: .word 0 
score_x_pos: .word 2                
score_y_pos: .word 1                

gravity_timer: .word 0  
gravity_threshold: .word 60  

next_color_1: .word 0x000000
next_color_2: .word 0x000000
current_color_1: .word 0x000000
current_color_2: .word 0x000000

sound_effect_notes: .word 72, 69, 64, 72, 48  # MIDI numbers for C5, A4, E4, C5, C3
sound_effect_notes_duration: .word 100, 150, 200, 300, 500

song_notes: .word 70, 71, 70, 71, 69, 67, 67, 69, 70, 71, 69, 67, 67, 60,     70, 71, 70, 71, 69, 67, 67, 69, 59, 59, 59, 60, 60, 60, 60, 61, 61, 61, 60, 62, 62, 62, 60,    70, 71, 70, 71, 69, 67, 67, 69, 70, 71, 69, 67, 67, 60,   70, 71, 70, 71, 69, 67, 67, 69, 70,    ,80, 74, 71, 60, 69, 86, 81, 76, 57, 74, 60, 75, 73, 59, 58,     60
song_durations: .word 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 400, 400,   200, 200, 200, 200, 200, 200, 200, 200, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100,    200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 400, 400,   200, 200, 200, 200, 200, 200, 200, 200,    100, 100, 100, 100, 200, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100,    100
song_volumes: .word 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 0,     100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 0, 100, 100, 100, 100, 100, 100, 0, 100, 100, 100, 0,    100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 0,   100, 100, 100, 100, 100, 100, 100, 100,    ,100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 0, 100, 100, 100, 100,   0
song_intervals: .word 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 12, 12,   6, 6, 6, 6, 6, 6, 6, 6, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 12, 12,    6, 6, 6, 6, 6, 6, 6, 6,       3, 3, 3, 3, 6, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,   3
current_note_waiting_interval: .word 0
current_note_number: .word 0
total_number_notes: .word 75

shape_matrix: .word current_color_1, current_color_2, BASE_COLOR, BASE_COLOR,         current_color_1,BASE_COLOR, current_color_2, BASE_COLOR,          current_color_2, current_color_1, BASE_COLOR, BASE_COLOR,             current_color_2,BASE_COLOR, current_color_1, BASE_COLOR,  #Row4
shape_matrix_row: .word 4
shape_matrix_color: .word 4

can_move_left: .word 0      #0 can not move left, 1 can move left
can_move_right: .word 0
can_rotate: .word 0
can_fall: .word 0

# width: 22, height 25. total: 22*25*4 = 2200
current_map: .space 2200

overflow_detector: .word 0x0000ff

#0: No direction (independent block).
#1: Connected to the left.
#2: Connected to the right.
#3: Connected above.
#4: Connected below.

stack_base: .space 400

connection_direction_map: .space 2200

#IMPORTANT: the value in shape matrix are address of a color, whereas value in current map are value of a color


##############################################################################
# Permanent Register
##############################################################################
# s0: X of current capsule in logical map
# s1: Y of current capsule in logical map
# s2: rotating status of current capsule
# s3: color


##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    # Initialize the game
    jal initialize_current_map
    jal initialize_direction_map
    jal initialize_score     
    jal draw_background
    
    jal initialize_new_capsule
    jal draw_capsule
    jal draw_next_capsule_preview
    jal generate_virus
    
    #jal Testing_Logical_Map
    
    
    jal draw_current_map
    

game_loop:
    # 1. Check if key has been pressed, and then handle the logic on input
    lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
    lw $t8, 0($t0)                  # Load first word from keyboard
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    # 1b. Check which key has been pressed(logic is sepated into handle inputLogic)
    input_ends:
	# 2. Draw the screen
	jal clean_up_screen
    jal draw_background
	jal draw_current_map
	jal draw_score
	jal draw_capsule
	jal draw_next_capsule_preview
	
	#jal Testing_Logical_Map
	jal play_theme_song
	
	
	# methods to implement: canMove, lockCapsuleInPlace, clearLines(lines of 4 in vertical/horizontal direction), check_survival(whether capsule reach top)
	#feature: easy: 1, 2, 4, 5. Hard: 1, 5
	
	#grouping(Wiliam): easy: 1, 2, clearLines, Hard:1, easy:4
	#grouping(Anthony): easy5, Hard: 5, canMove, lockCapsuleInPlace, check_survival, generate_virus

	#concatenate: easy:4, check_survival
	#ending:  easy: 5
	
	jal update_game_time
    # update the timer
    jal timer_update
    

	# 3. Sleep
    li $v0, 32
    li $a0, 16        #60 frames per second, so 1000/60 = 16.6
    syscall
    # 4. Go back to Step 1
    j game_loop

######################################################################
# Handle drawing logic
#####################################################################
#parameter: t1: color, t2: X value, t3: Y value, t4: length
draw_horizontal_line:
    lw $t0, ADDR_DSPL      # $t0 = base address for display
    sll $t3, $t3, 7             # Calculate the Y offset to add to $t0 (multiply by 128)
    sll $t2, $t2, 2             # Calculate the X offset to add to $t0 (multiply by 4)
    add $t5, $t0, $t3           # Add the Y offset to $t0, store the result in $t5
    add $t5, $t5, $t2           # Add the X offset to $t2 ($t2 now has the starting location of the line in bitmap memory)
    # Calculate the final point in the line (start point + length x 4)
    sll $t4, $t4, 2             # Multiply the length by 4
    add $t6, $t4, $t5           # Calculate the address of the final point in the line, store result in $t6..
    # Start the loop
    line_start_horizontal:
        sw $t1, 0($t5)              # Draw a pixel at the current location in the bitmap
        # Loop until the current pixel has reached the final point in the line.
        addi $t5, $t5, 4            # Move the current location to the next pixel
        beq $t5, $t6, line_end_horizontal      # Break out of the loop when $t2 == $t3
        j line_start_horizontal
    # End the loop
    line_end_horizontal:
    # Return to calling program
        jr $ra

#parameter: t1: color, t2: X value, t3: Y value, t4: length
draw_vertical_line:
    lw $t0, ADDR_DSPL      # $t0 = base address for display
    sll $t3, $t3, 7             # Calculate the Y offset to add to $t0 (multiply $a1 by 128)
    sll $t2, $t2, 2             # Calculate the X offset to add to $t0 (multiply $a0 by 4)
    add $t5, $t0, $t3           # Add the Y offset to $t0, store the result in $t5
    add $t5, $t5, $t2           # Add the X offset to $t2 ($t2 now has the starting location of the line in bitmap memory)
    # Calculate the final point in the line (start point + length x 4)
    sll $t4, $t4, 7             # Multiply the length by 4
    add $t6, $t4, $t5           # Calculate the address of the final point in the line, store result in $t6.
    # Start the loop
    line_start_vertical:
        sw $t1, 0($t5)              # Draw a pixel at the current location in the bitmap
        # Loop until the current pixel has reached the final point in the line.
        addi $t5, $t5, 128            # Move the current location to the next pixel
        beq $t5, $t6, line_end_vertical      # Break out of the loop when $t2 == $t3
        j line_start_vertical
    # End the loop
    line_end_vertical:
    # Return to calling program
        jr $ra
        
draw_background:
    # load color
    li $t1, 0x808080
    
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # drawing the bottle
    addi $t2, $zero, 0 #left top row
    addi $t3, $zero, 5
    addi $t4, $zero, 8
    jal draw_horizontal_line
    
    addi $t2, $zero, 16 #right top row
    addi $t3, $zero, 5
    addi $t4, $zero, 8
    jal draw_horizontal_line
    
    addi $t2, $zero, 0 #bottom row
    addi $t3, $zero, 31
    addi $t4, $zero, 24
    jal draw_horizontal_line
    
    addi $t2, $zero, 0 #left colomn
    addi $t3, $zero, 5
    addi $t4, $zero, 26
    jal draw_vertical_line
    
    addi $t2, $zero, 23 #right colomn
    addi $t3, $zero, 5
    addi $t4, $zero, 26
    jal draw_vertical_line
    
    addi $t2, $zero, 7 #left container neck
    addi $t3, $zero, 2
    addi $t4, $zero, 3
    jal draw_vertical_line
    
    addi $t2, $zero, 16 #right container neck
    addi $t3, $zero, 2
    addi $t4, $zero, 3
    jal draw_vertical_line
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

#parameter: s0: X location of capsule, s1: Y location of capsule, s2: rotation state
draw_capsule:
    lw $t0, ADDR_DSPL       # t0 stands for starting location in logical map
    sll $t1, $s0, 2
    sll $t2, $s1, 7         # Calculate the Y offset to add to $t1 (multiply $a1 by 128)
    lw $t3, starting_x
    lw $t4, starting_y
    sll $t3, $t3, 2
    sll $t4, $t4, 7         # Calculate the Y offset to add to $t4 (multiply $a1 by 128)
    
    add $t0, $t3, $t0       # update the X position on t0
    add $t0, $t4, $t0       # update the Y position on t0 so that now t0 is the starting location in logical map
    
    add $t1, $t0, $t1
    add $t1, $t2, $t1

    sll $t3, $s2, 4         # correspondence of rotation state and matrix. *4 to offset address first, then *4 to correspond to row
    la $t4, shape_matrix    
    add $t3, $t3, $t4       # calculate the correct starting position in shape_matrix
    
    lw $t5, BASE_COLOR   # load t5 with base color to determine whether or not to draw this pixel
    lw $s3, 0($t3)          # load the current color address in shape_matrix
    lw $s3, 0($s3)          # load from current color address to color data
    beq $s3, $t5, not_draw_capsule_first_pixel
    sw $s3, 0($t1)
    draw_capsule_first_pixel_end:
    
    
    addi $t1, $t1, 4        # update the new position next capsule piece in screen
     lw $t5, BASE_COLOR     # load t5 with base color to determine whether or not to draw this pixel
    lw $s3, 4($t3)          # load next color in shape_matrix
    lw $s3, 0($s3)          # load from current color address to color data
    beq $s3, $t5, not_draw_capsule_second_pixel
    sw $s3, 0($t1)
    draw_capsule_second_pixel_end:
    
    addi $t1, $t1, 124      # update the new position next capsule piece in screen
    lw $t5, BASE_COLOR          # load the current color in t1
    lw $s3, 8($t3)          # load next color in shape_matrix
    lw $s3, 0($s3)          # load from current color address to color data       
    beq $s3, $t5, not_draw_capsule_third_pixel
    sw $s3, 0($t1)
    draw_capsule_third_pixel_end:
    
    addi $t1, $t1, 4        # update the new position next capsule piece in screen
    lw $t5, BASE_COLOR          # load the current color in t1
    lw $s3, 12($t3)         # load next color in shape_matrix
    lw $s3, 0($s3)          # load from current color address to color data
    beq $s3, $t5, not_draw_capsule_fourth_pixel
    sw $s3, 0($t1)
    draw_capsule_fourth_pixel_end:
    
    jr $ra
    not_draw_capsule_first_pixel:
        j draw_capsule_first_pixel_end
    not_draw_capsule_second_pixel:
        j draw_capsule_second_pixel_end
    not_draw_capsule_third_pixel:
        j draw_capsule_third_pixel_end
    not_draw_capsule_fourth_pixel:
        j draw_capsule_fourth_pixel_end
    
# randomly choose one color from colors and store in s3. 
choose_color:
    li $v0, 42                  # generate random numbers                                
    li $a0, 0
                   # lower bound is 0
    li $a1, 3
                   # upper bound is 3 (number generated will be in [0,2]
    syscall                     # the return value will be stored in a0
    
    la $t3, colors              # load the colors array into t3
    sll $a0, $a0, 2             # calculate the memory offset of a0
    add $t3, $t3, $a0           # update the offset a0 to t3
    lw $s3, 0($t3)              # load randomly a value of color into t4
    
    jr $ra
    
# randomly choose one virus color from virus_colors and store in s3. 
choose_virus_color:
    li $v0, 42                  # generate random numbers                                
    li $a0, 0
                   # lower bound is 0
    li $a1, 3
                   # upper bound is 3 (number generated will be in [0,2]
    syscall                     # the return value will be stored in a0
    
    la $t3, virus_colors          # load the colors array into t3
    sll $a0, $a0, 2             # calculate the memory offset of a0
    add $t3, $t3, $a0           # update the offset a0 to t3
    lw $s3, 0($t3)              # load randomly a value of color into t4
    
    jr $ra

# This is to update the ra to current address when using beq
update_ra_to_current_address:
    jr $ra

clean_up_screen:
    lw $s3, BASE_COLOR  #load s3 with color black
    lw $t0, ADDR_DSPL #load base address
    li $t1, 128       #set t1 to 128*128
    multu $t1, $t1
    mflo $t1
    add $t1, $t1, $t0 #add t1 from t0 to get to offset
    
    start_clean_up_screen:
    sw $s3, 0($t0)
    addi $t0, $t0, 4
    beq $t0, $t1, end_clean_up_screen
    j start_clean_up_screen
    end_clean_up_screen:
    
    jr $ra



draw_current_map:
    lw $t0, ADDR_DSPL
    lw $t1, starting_x
    lw $t3, starting_y
    
    la $t6, current_map
    li $t7, 0 #t7 is the counter for locating current x in map
    li $t8, 0 #t8 is the counter for locating current y in map
    
    lw $t2, ending_x
    sub $t2, $t2, $t1 # calcuate the ending x in current map
    lw $t4, ending_y
    sub $t4, $t4, $t3 # calcuate the ending y in current map
    
    sll $t1, $t1, 2 # calculating correct x, y offset
    sll $t3, $t3, 7
    
    lw $t5, ADDR_DSPL # t5 stands for starting location in map
    add $t5, $t1, $t5
    add $t5, $t3, $t5
    
    li $t9, 0 #t9 standing for current location in bit map relative to current map
    add $t9, $t9, $t5
    
    draw_current_map_loop:
        lw $s3, 0($t6) # load the current color in current map into s3
        sw $s3, 0($t9)
        addi $t6, $t6, 4 #update current map 
        addi $t9, $t9, 4 #update bitmap location
        addi $t7, $t7, 1
        beq $t7, $t2, update_y_when_drawing_current_map
        j draw_current_map_loop
        
    update_y_when_drawing_current_map:
        addi $t8, $t8, 1
        li $t7, 0           # reset logical x position
        addi $t9, $t5, 0    # reset then calculte current bit map position
        sll $t1, $t7, 2     #reuse t1, t3, now t1, t3 is the current x, y offset from the t5
        sll $t3, $t8, 7
        add $t9, $t9, $t1
        add $t9, $t9, $t3
        beq $t8, $t4, end_drawing_current_map
        
        j draw_current_map_loop
    
    end_drawing_current_map:
    
    jr $ra

#a0: action type: 0: rotate, 1: dropping(press s), 2: lock_capsule_in_place 3: remove row or column, 4: game_over
play_effect_sound:
    la $t1, sound_effect_notes
    la $t2, sound_effect_notes_duration
    
    sll $t3, $a0, 2      # calculate the offset
    add $t1, $t1, $t3
    add $t2, $t2, $t3
    
    lw $a0, 0($t1)      # retrieve the current note and duration
    lw $a1, 0($t2)      
    li $a2, 123         # instrument type
    li $a3, 100         # volume
    
    li $v0, 31           # Syscall to play sound effect
    syscall
    
    
    jr $ra

play_theme_song:
    
    lw $t3, current_note_number
    lw $t4, current_note_waiting_interval
    
    beq $t4, 0, play_song_note
    
    addi $t4, $t4, -1
    sw $t4, current_note_waiting_interval
    
    j end_play_song
    
    play_song_note:
        la $t0, song_notes
        la $t1, song_durations
        la $t2, song_volumes
        
        sll $t7, $t3, 2
        
        add $a0, $t0, $t7       # load parameter for calling song
        add $a1, $t1, $t7
        add $a3, $t2, $t7
        
        lw $a0, 0($a0)
        lw $a1, 0($a1)
        li $a2, 0
        lw $a3, 0($a3)
        
        li $v0, 31           # Syscall to play sound effect
        syscall
        
        
        la $t6, song_intervals
        add $t6, $t6, $t7
        lw $t4, 0($t6)
        sw $t4, current_note_waiting_interval
        
        addi $t3, $t3, 1
        
        lw $t5, total_number_notes
        beq $t3, $t5, back_to_song_origin
        sw $t3, current_note_number
        j end_play_song
        
    back_to_song_origin:
        sw $zero, current_note_number
        
    end_play_song:
    jr $ra
    

        
###############################################################
# Handle Key Board Input Logic
###############################################################
keyboard_input:                     # A key is pressed
    lw $a0, 4($t0)                  # Load second word from keyboard  
    
    beq $a0, 0x77, pressW
    beq $a0, 0x61, pressA   
    beq $a0, 0x73, pressS
    beq $a0, 0x64, pressD
    
    b input_ends

pressW:
    jal determine_can_rotate
    lw $t1, can_rotate
    beq $t1, $zero, input_ends                   #t1 == 0 mean can not rotate
    
    addi $s2, $s2, 1      # s2 = s2 + 1
    li $t1, 4             # Load the divisor (4) into $t1
    divu $s2, $t1         # Unsigned division: LO = quotient, HI = remainder
    mfhi $s2              # Move the remainder (y % 4) from HI to $t0
    
    
    li $a0, 0             #parameter for play effect sound
    jal play_effect_sound
    
    b input_ends
pressA:
    
    jal determine_can_move_left
    lw $t1, can_move_left
    beq $t1, $zero, input_ends                   #t1 == 0 mean can not move left
    addi $s0, $s0, -1
    b input_ends
pressS:
    li $a0, 1             #parameter for play effect sound
    jal play_effect_sound
    
    jal fall

    b input_ends
    
    falling_ends:
        jal lock_capsule_in_place
        jal update_direction_map
        jal clear_the_virus
        jal initialize_new_capsule
        jal check_survival
        
        li $a0, 2             #parameter for play effect sound
        jal play_effect_sound
    
    b input_ends
pressD:
    jal determine_can_move_right
    lw $t1, can_move_right
    beq $t1, $zero, input_ends                   #t1 == 0 mean can not move right
    addi $s0, $s0, 1
    b input_ends
    
###############################################################
# Handle Game Rule Logic
#############################################################

clear_the_virus:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

clear_virus_loop:
    # initialize blocks_cleared and blocks_moved to 0
    li $t0, 0
    sw $t0, blocks_cleared
    sw $t0, blocks_moved

    # initiaze the stack
    jal initialize_stack
    
    # scan and mark the blocks
    jal scan_for_lines_horizontal
    jal scan_for_lines_vertical

    # check if there some blocks need to clear
    lw $t0, stack_top
    blez $t0, clear_virus_done    # if stack is 0, skip

    # set blocks_cleared to  1
    li $t0, 1
    sw $t0, blocks_cleared
    lw $t1, stack_top
    lw $t4, current_score         # 加载当前分数
    add $t4, $t4, $t1             # 累加分数增量
    sw $t4, current_score         # 存储回当前分数
    # clear the marked block
    jal clear_marked_blocks

    # apply the gravity
    jal apply_gravity

    #  apply_gravity set blocks_moved 

    # check blocks_cleared and blocks_moved 
    lw $t0, blocks_cleared
    lw $t1, blocks_moved
    or $t2, $t0, $t1           #if any mark is 1, loop
    bne $t2, $zero, clear_virus_loop

clear_virus_done:

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
    # initialize the stack 
initialize_stack:

    li $t9, 0            
    sw $t9, stack_top
    jr $ra

push_to_stack:
    addi $sp, $sp, -4
    
    sw $ra, 0($sp)

    la $t0, stack_base
    lw $t1, stack_top
    sll $t2, $t1, 2          # $t2 = stack_top * 4 (offset)
    add $t0, $t0, $t2        # Address to store the new element
    sw $a0, 0($t0)           # Store the value in $a0 onto the stack
    addi $t1, $t1, 1         # stack_top += 1
    sw $t1, stack_top

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

pop_from_stack:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    lw $t0, stack_top
    blez $t0, stack_empty     # If stack_top <= 0, stack is empty
    addi $t0, $t0, -1         # stack_top -= 1
    sw $t0, stack_top
    la $t1, stack_base
    sll $t2, $t0, 2           # $t2 = stack_top * 4 (offset)
    add $t1, $t1, $t2         # Address of the top element
    lw $v0, 0($t1)            # Load the value from the stack into $v0
    j pop_done

stack_empty:
    li $v0, -1                # Return -1 or any invalid value to indicate empty stack

pop_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
scan_for_lines_horizontal:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)    # Row index
    sw $s1, 8($sp)    # Column index
    sw $s2, 12($sp)   # Match counter

    la $t0, current_map  # Load the base address of the map
    li $s0, 0            # Start at row 0
    li $t1, 22           # Number of columns
    li $t2, 25           # Number of rows

    horizontal_scan_loop:
        bge $s0, 25, end_horizontal_scan  # If row exceeds max, stop
        li $s1, 0                          # Reset column index for each row
    
    horizontal_check_loop:
        bge $s1, 22, next_horizontal_row  # If column exceeds max, go to next row
    
        # Load current block color
        mul $t3, $s0, 22                  # t3 = row * num_columns
        add $t3, $t3, $s1                  # t3 = (row * num_columns) + column
        sll $t3, $t3, 2                    # t3 = t3 * 4 (byte offset)
        
        
        add $t3, $t0, $t3                  # t3 = map_base + offset
        lw $t4, 0($t3)                     # Load color
    
        # Skip if the block is empty
        beq $t4, $zero, next_horizontal_col
    
        # Match consecutive blocks
        li $s2, 1                          # Match counter = 1
        move $t5, $s1                      # Start matching from current column
    
    match_horizontal_blocks:
        addi $t5, $t5, 1                   # Next column
        bge $t5, 22, horizontal_match_done # If out of bounds, stop matching
    
        # Load next block color
        mul $t6, $s0, 22                 # t6 = row * num_columns
        add $t6, $t6, $t5                  # t6 = (row * num_columns) + temp_col
        sll $t6, $t6, 2                    # t6 = t6 * 4 (byte offset)
        add $t6, $t0, $t6                  # t6 = map_base + offset
        lw $t7, 0($t6)                     # Load next color
    
        # Check if the colors are in the same group
        move $a0, $t4
        move $a1, $t7
        jal same_group
        beqz $v0, horizontal_match_done    # If not in the same group, stop
    
        addi $s2, $s2, 1                   # Increment match counter
        j match_horizontal_blocks
    
    horizontal_match_done:
    blt $s2, 4, next_horizontal_col    # If less than 4 matches, skip

    # Start from the current column ($s1) and mark all matching blocks
    move $t5, $s1                      # $t5 = starting column
    add $t6, $s1, $s2                  # $t6 = ending column (exclusive)

    mark_horizontal_blocks:
    bge $t5, $t6, next_horizontal_col  # If we've marked all blocks, move to next column

    # Calculate the index of the block to mark
    mul $t7, $s0, 22                   # t7 = row * num_columns
    add $t7, $t7, $t5                  # t7 = (row * num_columns) + column
    # Push index onto the stack
    move $a0, $t7
    jal push_to_stack

    addi $t5, $t5, 1                   # Move to the next column
    j mark_horizontal_blocks
        
    next_horizontal_col:
        addi $s1, $s1, 1                   # Next column
        j horizontal_check_loop
    
    next_horizontal_row:
        addi $s0, $s0, 1                   # Next row
        j horizontal_scan_loop
    
    end_horizontal_scan:
        lw $ra, 0($sp)
        lw $s0, 4($sp)
        lw $s1, 8($sp)
        lw $s2, 12($sp)
        addi $sp, $sp, 16
        jr $ra
 
scan_for_lines_vertical:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)    # Column index
    sw $s1, 8($sp)    # Row index
    sw $s2, 12($sp)   # Match counter

    la $t0, current_map  # Load the base address of the map
    li $s0, 0            # Start at column 0

vertical_scan_loop:
    bge $s0, 22, end_vertical_scan  # If column exceeds max, stop
    li $s1, 0                       # Reset row index for each column

vertical_check_loop:
    bge $s1, 25, next_vertical_column  # If row exceeds max, go to next column

    # Load current block color
    mul $t3, $s1, 22                  # t3 = row * num_columns
    add $t3, $t3, $s0                 # t3 = (row * num_columns) + column
    sll $t3, $t3, 2                   # t3 = t3 * 4 (byte offset)
    add $t4, $t0, $t3                 # t4 = map_base + offset
    lw $t5, 0($t4)                    # Load color

    # Skip if the block is empty
    beq $t5,$zero, increment_row

    # Match consecutive blocks
    li $s2, 1                         # Match counter = 1
    move $t6, $s1                     # Start matching from current row

match_vertical_blocks:
    addi $t6, $t6, 1                  # Next row
    bge $t6, 25, vertical_match_done  # If out of bounds, stop matching

    # Load next block color
    mul $t7, $t6, 22                  # t7 = row * num_columns
    add $t7, $t7, $s0                 # t7 = (row * num_columns) + column
    sll $t7, $t7, 2                   # t7 = t7 * 4 (byte offset)
    add $t8, $t0, $t7                 # t8 = map_base + offset
    lw $t9, 0($t8)                    # Load next color

    # Check if the colors are in the same group
    move $a0, $t5
    move $a1, $t9
    jal same_group
    beq $v0, $zero, vertical_match_done     # If not in the same group, stop

    addi $s2, $s2, 1                  # Increment match counter
    j match_vertical_blocks

vertical_match_done:
    blt $s2, 4, increment_row     # If less than 4 matches, skip

    # Mark all matching blocks
    move $t6, $s1                      # $t6 = starting row
    add $t7, $s1, $s2                  # $t7 = ending row (exclusive)

mark_vertical_blocks:
    bge $t6, $t7, increment_row        # If we've marked all blocks, move to next row

    # Calculate the index of the block to mark
    mul $t8, $t6, 22                   # t8 = row * num_columns
    add $t8, $t8, $s0                  # t8 = (row * num_columns) + column

    # Push index onto the stack
    move $a0, $t8
    jal push_to_stack

    addi $t6, $t6, 1                   # Move to the next row
    j mark_vertical_blocks

increment_row:
    addi $s1, $s1, 1                   # Next row
    j vertical_check_loop

next_vertical_column:
    addi $s0, $s0, 1                   # Next column
    j vertical_scan_loop

end_vertical_scan:
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    jr $ra

    
#check if have the similar color if so return 1.
same_group:
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)

    beq $a0, 0xffff00, check_yellow
    beq $a0, 0xCCCC00, check_yellow
    
    beq $a0, 0xff0000, check_red
    beq $a0, 0xcc0000, check_red
    
    beq $a0, 0x0000ff, check_blue
    beq $a0, 0x0000cc, check_blue
    
    check_yellow:
    
    beq $a1, 0xffff00,same
    beq $a1, 0xCCCC00,same
    li $v0, 0
    j end_same_group
    
    check_red:
    
    beq $a1, 0xff0000,same
    beq $a1, 0xcc0000,same
    li $v0, 0
    j end_same_group
    
    check_blue:
    
    beq $a1, 0x0000ff,same
    beq $a1, 0x0000cc,same
    li $v0, 0
    j end_same_group
    
    same:
        
    li $v0, 1
    
    end_same_group:
    lw $ra, 0($sp)
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    addi $sp, $sp, 12
    jr $ra
    

clear_marked_blocks:
    # Save $s registers on the stack
    addi $sp, $sp, -24
    sw $ra, 0($sp)          # Save return address
    sw $s0, 4($sp)          # Save $s0 (base address of current_map)
    sw $s1, 8($sp)          # Save $s1 (stack index)
    sw $s2, 12($sp)         # Save $s2 (calculated display address)
    sw $s3, 16($sp)         # Save $s3 (background color)
    sw $s4, 20($sp)

    la $s0, current_map     # Load base address of current_map into $s0
    lw $s3, BASE_COLOR      # Load background color into $s3
    la $s2, ADDR_DSPL       # Load base address of display into $s2
    la $s4, connection_direction_map   # load direction map
    
    li $t2, 0
    sw $t2, blocks_cleared

clear_stack_loop:
    lw $s1, stack_top       # Load stack top index into $s1
    blez $s1, clear_done    # If stack is empty (stack_top <= 0), finish clearing

    # Pop the top index from the stack
    jal pop_from_stack
    move $t0, $v0           # Store popped index in $t0

    # Clear corresponding block in current_map
    sll $t1, $t0, 2         # $t1 = index * 4 (word offset in current_map)
    add $t1, $s0, $t1       # $t1 = base_address + offset
    sw $zero, 0($t1)        # Set current_map[index] to 0 (cleared)
    
    li $t2, 1
    sw $t2, blocks_cleared
    
    #clear the direction map
    
    sll $t1, $t0, 2
    add $t1, $s4, $t1
    lw $t9, 0($t1)
    beq $t9, 0, ind
    beq $t9, 5, ind
    beq $t9, 1, left_clear
    beq $t9, 2, right_clear
    beq $t9, 3, top_clear
    beq $t9, 4, bottom_clear

    
    j clear_stack_loop      # Continue clearing the next marked block
ind:
    sw $zero, 0($t1)
    j clear_stack_loop
    
left_clear:
    sw $zero, 0($t1)
    sub $t8, $t1, 4
    sw $zero, 0($t8)
    j clear_stack_loop
    
right_clear:
    sw $zero, 0($t1)
    addi $t8, $t1, 4
    sw $zero, 0($t8)
    j clear_stack_loop
    
top_clear:
    sw $zero, 0($t1)
    sub $t8, $t1, 88
    sw $zero, 0($t8)
    j clear_stack_loop
    
bottom_clear:
    sw $zero, 0($t1)
    addi $t8, $t1, 88
    sw $zero, 0($t8)
    j clear_stack_loop
    

clear_done:
    # Restore $s registers from the stack
    lw $s4, 20($sp)
    lw $s3, 16($sp)         # Restore $s3 (background color)
    lw $s2, 12($sp)         # Restore $s2 (display address)
    lw $s1, 8($sp)          # Restore $s1 (stack index)
    lw $s0, 4($sp)          # Restore $s0 (current_map base address)
    lw $ra, 0($sp)          # Restore return address
    addi $sp, $sp, 24      # Restore stack pointer

    jr $ra                  # Return to caller
    
apply_gravity:
    # save register
    addi $sp, $sp, -36
    sw $ra, 0($sp)
    sw $s0, 4($sp)   # cloumn index
    sw $s1, 8($sp)   # row index
    sw $s2, 12($sp)  # target row 
    sw $s3, 16($sp)  # current block color
    sw $s4, 20($sp)  # direction 
    sw $s5, 24($sp)  # 
    sw $s6, 28($sp)  
    sw $s7, 32($sp)  # direction 

    la $t0, current_map      # load current_map base 
    la $t1, connection_direction_map    # load direction_map base
    la $t2, ADDR_DSPL        # load display address
    
    li $s0, 0                # start from column 0
    # Initialize blocks_moved to 0
    li $t3, 0
    sw $t3, blocks_moved


gravity_column_loop:
    bge $s0, 22, gravity_done  # if column excessed, end it
    li $s1, 24                  # start from the last row 

gravity_row_loop:
    blt $s1, 0, next_column
    bgt $s1, 25, move_to_next_row   # if row excessed, end it 
    mul $s6, $s1, 22            
    add $s6, $s6, $s0          
    sll $s6, $s6, 2            
    add $s6, $t0, $s6           # calculate current_map current block 
    lw $s3, 0($s6)              


    # if it is empty ,move to next row 
    beq $s3, $zero, move_to_next_row
    mul $s6, $s1, 22            
    add $s6, $s6, $s0          
    sll $s6, $s6, 2  
    add $s4, $t1, $s6
    lw  $s7, 0($s4)
    beq $s7, $zero, handle_independent_block   
    beq $s7, 2, handle_right_connected_block   
    beq $s7, 3, handle_bottom_connected_block  

    j move_to_next_row

handle_independent_block:

    addi $s2, $s1, 1                # next row 
    bgt $s2, 24, move_to_next_row  

    mul $s5, $s2, 22
    add $s5, $s5, $s0
    sll $s5, $s5, 2
    add $s5, $t0, $s5              # （current_map）
    lw $t5, 0($s5)                 # load the color 
    bne $t5, $zero, move_to_next_row # if it is not empty, skip it

    # update current_map
    sw $s3, 0($s5) 
    add $s6, $s6, $t0
    sw $zero, 0($s6)           

    # update direction_map
    add $t6, $t1, $s5              
    sw $s7, 0($t6)                
    add $t7, $t1, $s6              
    sw $zero, 0($t7)             
    
    li $t3, 1
    sw $t3, blocks_moved
    
    li $s1, 23                   # Reset $s1 to bottom row
    j gravity_row_loop
    
    
    #update the display address
    #addi $t6, $s1, 6  #calculate the row 
    #mult $t6, $t6, 128 #calculate the offst
    #addi $t7, $s0, 1   # add column 
    #mult $t7, $t7, 4
    #add $t6, $t6, $t7
    #add $t6, $t0, $t6
    #sw $zero, 0($t6)
    #sw $s3, 128($t6)
    

    handle_right_connected_block:

    # Calculate target row (row below current block)
    addi $s2, $s1, 1                # Target row = current row + 1
    bge $s2, 24, move_to_next_row   # If target row exceeds boundary, skip

    # Check if space below both parts is empty
    mul $t4, $s2, 22
    add $t4, $t4, $s0
    sll $t4, $t4, 2
    add $t4, $t0, $t4               # Target address in current_map for left part
    lw $t5, 0($t4)                  # Check left part below
    bne $t5, $zero, move_to_next_row

    mul $t6, $s2, 22
    add $t6, $t6, $t3
    sll $t6, $t6, 2
    add $t6, $t0, $t6               # Target address in current_map for right part
    lw $t5, 0($t6)                  # Check right part below
    bne $t5, $zero, move_to_next_row

    # Update current_map
    sw $s3, 0($t4)                  # Move left part down
    sw $s3, 0($t6)                  # Move right part down
    mul $t7, $s1, 22
    add $t7, $t7, $s0
    sll $t7, $t7, 2
    add $t7, $t0, $t7
    sw $zero, 0($t7)                # Clear original left position
    mul $t8, $s1, 22
    add $t8, $t8, $t3
    sll $t8, $t8, 2
    add $t8, $t0, $t8
    sw $zero, 0($t8)                # Clear original right position

    # Update direction_map
    add $t9, $t1, $t4               # Target address in direction_map for left part
    sw $s7, 0($t9)                  # Copy direction for left part
    add $t9, $t1, $t6               # Target address in direction_map for right part
    sw $s7, 0($t9)                  # Copy direction for right part
    add $t9, $t1, $t7               # Original address in direction_map for left part
    sw $zero, 0($t9)                # Clear original left direction
    add $t9, $t1, $t8               # Original address in direction_map for right part
    sw $zero, 0($t9)                # Clear original right direction
    
    li $t3, 1
    lw $t3, blocks_moved

    # Update display
    # Compute left target display address
    #add $t4, $s2, $s6              # Adjust for starting_y
    #mul $t4, $t4, 128              # Row offset in display
    #add $t5, $s0, $s5              # Adjust for starting_x
    #mul $t5, $t5, 4                # Column offset in display
    #add $t4, $t2, $t4              # Base + row offset
    #add $t4, $t4, $t5              # Full target display address for left part
    #sw $s3, 0($t4)                 # Update target display for left part

    # Clear original left display
    #add $t4, $s1, $s6              # Adjust for starting_y
    #mul $t4, $t4, 128              # Row offset in display
    #add $t5, $s0, $s5              # Adjust for starting_x
    #mul $t5, $t5, 4                # Column offset in display
   # add $t4, $t2, $t4              # Base + row offset
   # add $t4, $t4, $t5              # Full original display address for left part
    #sw $zero, 0($t4)               # Clear original display for left part

    # Compute right target display address
    #add $t6, $s2, $s6              # Adjust for starting_y
    #mul $t6, $t6, 128              # Row offset in display
    #add $t7, $t3, $s5              # Adjust for starting_x
    #mul $t7, $t7, 4                # Column offset in display
    #add $t6, $t2, $t6              # Base + row offset
    #add $t6, $t6, $t7              # Full target display address for right part
    #sw $s3, 0($t6)                 # Update target display for right part

    # Clear original right display
    #add $t6, $s1, $s6              # Adjust for starting_y
    #mul $t6, $t6, 128              # Row offset in display
    #add $t7, $t3, $s5              # Adjust for starting_x
    #mul $t7, $t7, 4                # Column offset in display
    #add $t6, $t2, $t6              # Base + row offset
    #add $t6, $t6, $t7              # Full original display address for right part
    #sw $zero, 0($t6)               # Clear original display for right part

    li $s1, 23                   # Reset $s1 to bottom row
    j gravity_row_loop
    
    handle_bottom_connected_block:

    # Calculate target row (row below current block)
    addi $s2, $s1, 1                # Target row = current row + 1
    bge $s2, 24, move_to_next_row   # If target row exceeds boundary, skip

    # Check if space below is empty
    mul $t4, $s2, 22
    add $t4, $t4, $s0
    sll $t4, $t4, 2
    add $t4, $t0, $t4               # Target address in current_map
    lw $t5, 0($t4)                  # Check below block
    bne $t5, $zero, move_to_next_row # If target position is not empty, skip

    # Update current_map
    sw $s3, 0($t4)                  # Move current block down
    mul $t6, $s1, 22
    add $t6, $t6, $s0
    sll $t6, $t6, 2
    add $t6, $t0, $t6               # Original address in current_map
    sw $zero, 0($t6)                # Clear original position

    # Update direction_map
    add $t7, $t1, $t4               # Target address in direction_map
    sw $s7, 0($t7)                  # Copy direction
    add $t7, $t1, $t6               # Original address in direction_map
    sw $zero, 0($t7)                # Clear original direction
    
    li $t3, 1
    lw $t3, blocks_moved

    # Update display
    # Compute target display address
    #add $t8, $s2, $s6              # Adjust for starting_y
    #mul $t8, $t8, 128              # Row offset in display
    #add $t9, $s0, $s5              # Adjust for starting_x
    #mul $t9, $t9, 4                # Column offset in display
    #add $t8, $t2, $t8              # Base + row offset
    #add $t8, $t8, $t9              # Full target display address
    #sw $s3, 0($t8)                 # Update target display

    # Clear original display
    #add $t8, $s1, $s6              # Adjust for starting_y
    #mul $t8, $t8, 128              # Row offset in display
    #add $t9, $s0, $s5              # Adjust for starting_x
    #mul $t9, $t9, 4                # Column offset in display
    #add $t8, $t2, $t8              # Base + row offset
    #add $t8, $t8, $t9              # Full original display address
    #sw $zero, 0($t8)               # Clear original display

    li $s1, 23                   # Reset $s1 to bottom row
    j gravity_row_loop
    
    
move_to_next_row:
    addi $s1, $s1, -1                   # Move to the next row
    j gravity_row_loop

next_column:
    addi $s0, $s0, 1                    # Move to the next column
    j gravity_column_loop

gravity_done:
    # Restore registers
    lw $s7, 32($sp)
    lw $s6, 28($sp)
    lw $s5, 24($sp)
    lw $s4, 20($sp)
    lw $s3, 16($sp)
    lw $s2, 12($sp)
    lw $s1, 8($sp)
    lw $s0, 4($sp)
    lw $ra, 0($sp)
    addi $sp, $sp, 36
    jr $ra
    
timer_update:
    
    lw $t0, gravity_timer
    addi $t0, $t0, 1              # gravity_timer += 1
    sw $t0, gravity_timer

    lw $t1, gravity_threshold
    blt $t0, $t1, end_timer_update  
    
    addi $sp, $sp, -4           # typical way of calling a function, choose a random color and store in s3
    sw $ra, 0($sp)              # choose a new color and store it in current color1
    jal fall
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    sw $zero, gravity_timer

    end_timer_update:
    jr $ra  

initialize_new_capsule:
    # If this is the first initialization and "next capsule" colors are not set, generate them
    lw $t0, next_color_1
    lw $t1, next_color_2
    bne $t0, $zero, skip_first_capsule_initialization  # If next_color_1 is already set, skip initialization

    # Generate the "next capsule" colors
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal choose_color  # Generate next_color_1
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    sw $s3, next_color_1

    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal choose_color  # Generate next_color_2
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    sw $s3, next_color_2

skip_first_capsule_initialization:

    # Transfer the "next capsule" colors to the "current capsule"
    lw $s3, next_color_1
    sw $s3, current_color_1
    lw $s3, next_color_2
    sw $s3, current_color_2

    # Initialize the position and rotation state of the current capsule
    lw $s0, initial_x_logical       # Initialize x-coordinate
    lw $s1, initial_y_logical       # Initialize y-coordinate
    li $s2, 1                       # Initialize rotation state

    # Generate new colors for the next capsule
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal choose_color                # Generate new next_color_1
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    sw $s3, next_color_1

    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal choose_color                # Generate new next_color_2
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    sw $s3, next_color_2

    jr $ra                          # Return to the calling function                       
    
draw_next_capsule_preview:
    lw $t0, ADDR_DSPL           # load the base address
    lw $t1, next_color_1        # load the first color
    lw $t2, next_color_2        # load the next color

    # draw the first  (x=26, y=5)
    li $t3, 26                  # x 
    li $t4, 5                   # y 
    sll $t3, $t3, 2             # x  * 4
    sll $t4, $t4, 7             # y  * 128
    add $t5, $t0, $t3          
    add $t5, $t5, $t4          
    sw $t1, 0($t5)              

    # draw the second (x=26, y=6)
    li $t4, 6                   # y to be 6
    sll $t4, $t4, 7             # y 
    add $t5, $t0, $t3          
    add $t5, $t5, $t4          
    sw $t2, 0($t5)             

    jr $ra
    
initialize_current_map:
    la $t0, current_map          # Load base address of the array
    lw $t1, BASE_COLOR        # Load the address of base color into $t1
    li $t2, 550            # Number of elements

    fill_current_map:
    beq $t2, 0, finish_filling_current_map       # Exit loop when all elements are filled
    sw $t1, 0($t0)         # Store the address of A in the current array element
    addi $t0, $t0, 4       # Move to the next element
    subi $t2, $t2, 1       # Decrement the counter
    j fill_current_map            # Repeat

    finish_filling_current_map:
    jr $ra


determine_can_move_left:
    move $t1, $s0
    addi $t1, $t1, -1                           # manually check the left position
    move $t2, $s1
    bltz $t1, can_not_move_left                 # determine whether t1 is less than 0
    bltz $t2, able_to_move_left                 # edge case at initial position
    
    la $t3, current_map
    mul $t2, $t2, 88                            #calculate the correct address in current map by x, y. Calculate by width * memory offset = 22 * 4
    sll $t1, $t1, 2                             # calculate the correct offset for $t1
    
    add $t3, $t3, $t2
    add $t3, $t3, $t1
    
    la $t6, shape_matrix
    sll $t7, $s2, 4                             # calcualte the current rotation state
    add $t6, $t6, $t7                           
    
    check_left_top_move_left:                               # check whether the left top corner of color in shape matrix and corresponding position's color in map are both not BASE_COLOR
        lw $t5, BASE_COLOR
        lw $t4, 0($t3)                                       # load the current logical map value in the left top position
        
        beq $t4, $t5, check_left_bottom_move_left           
        lw $t7, 0($t6)                                       # load the current color's address in shape matrix
        lw $t4, 0($t7)                                       # load the current value in that color address
        beq $t4, $t5, check_left_bottom_move_left
        j can_not_move_left
    check_left_bottom_move_left:
        lw $t5, BASE_COLOR
        addi $t3, $t3, 88                                   # move to next row(y+=1, x remains the same)(22*4)
        lw $t4, 0($t3)
        beq $t4, $t5, able_to_move_left
        addi $t6, $t6, 8
        lw $t7, 0($t6)                                       # load the current color's address in shape matrix
        lw $t4, 0($t7)                                       # load the current value in that color address
        beq $t4, $t5, able_to_move_left
        j can_not_move_left
        
    can_not_move_left:
        li $t5, 0
        sw $t5, can_move_left
        j end_can_move_left
    
    
    able_to_move_left:
        li $t5, 1
        sw $t5, can_move_left
        j end_can_move_left
    
    end_can_move_left:
    jr $ra


determine_can_move_right:
    move $t1, $s0
    addi $t1, $t1, 2
    
    li $t9, 2                                   # Load the divisor (2) into $t9(determine the current rotating status to determine whether should detect the +1 position or +2 position of current location))
    divu $s2, $t9                               # Unsigned division: LO = quotient, HI = remainder
    mfhi $t9                                    # Move the remainder (y % 4) from HI to $t0
    beq $t9, $zero, determine_can_move_right_rotation_status_checked
    
    subi $t1, $t1, 1                           # manually check the right position(since in the shape matrix, horizontal are all in top row, vertical are all in left column)
        
    
    determine_can_move_right_rotation_status_checked:
    
    move $t2, $s1
    bltz $t2, able_to_move_right                #edge case at initial position
    
    addi $t8, $t1, -21                          # determine for right edge
    bgtz $t8, can_not_move_right                 # determine whether t1 is greater than or equal to 22 
    
    la $t3, current_map
    mul $t2, $t2, 88                            #calculate the correct address in current map by x, y. Calculate by width * memory offset = 22 * 4
    sll $t1, $t1, 2                             # calculate the correct offset for $t1
    
    add $t3, $t3, $t2
    add $t3, $t3, $t1
    
    check_right_top_move_right:                               # check whether the left top corner of color in shape matrix and corresponding position's color in map are both not BASE_COLOR
        lw $t5, BASE_COLOR
        lw $t4, 0($t3)                                       # load the current logical map value in the right top position
        
        beq $t4, $t5, check_right_bottom_move_right                  
        j can_not_move_right
    check_right_bottom_move_right:
        lw $t5, BASE_COLOR
        addi $t3, $t3, 88                                   # move to next row(y+=1, x remains the same)(22*4)
        lw $t4, 0($t3)
        beq $t4, $t5, able_to_move_right
        j can_not_move_right
        
    can_not_move_right:
        li $t5, 0
        sw $t5, can_move_right
        j end_can_move_right
    
    able_to_move_right:
        li $t5, 1
        sw $t5, can_move_right
        j end_can_move_right
    
    end_can_move_right:
    jr $ra

determine_can_fall:
    move $t1, $s0
    move $t2, $s1
    addi $t2, $t2, 2
    
    li $t9, 2                                   # Load the divisor (2) into $t9(determine the current rotating status to determine whether should detect the +1 position or +2 position of current location))
    divu $s2, $t9                               # Unsigned division: LO = quotient, HI = remainder
    mfhi $t9                                    # Move the remainder (y % 4) from HI to $t0
    li $a0, 1
    beq $t9, $a0, determine_can_fall_rotation_status_checked
    
    subi $t2, $t2, 1                           # manually check the right position(since in the shape matrix, horizontal are all in top row, vertical are all in left column)
    
    determine_can_fall_rotation_status_checked:
    
    addi $t8, $t2, -24                          # determine for the bottom
    bgtz $t8, can_not_fall                 # determine whether y position is larger than heigh(25)
    
    la $t3, current_map
    mul $t2, $t2, 88                            #calculate the correct address in current map by x, y. Calculate by width * memory offset = 22 * 4
    sll $t1, $t1, 2                             # calculate the correct offset for $t1
    
    add $t3, $t3, $t2
    add $t3, $t3, $t1
    
    li $t1, 1
    beq $t9, $t1, check_left_bottom_can_fall    # only in horizontal rotation status that we need to check both side
    
    check_right_bottom_can_fall:
        lw $t5, BASE_COLOR
        addi $t3, $t3, 4                       # finding the right bottom
        lw $t4, 0($t3)
        addi $t3, $t3, -4                       # finding the left bottom 
        beq $t4, $t5, check_left_bottom_can_fall
        j can_not_fall
    check_left_bottom_can_fall:                              # check whether the left top corner of color in shape matrix and corresponding position's color in map are both not BASE_COLOR
        lw $t5, BASE_COLOR
        lw $t4, 0($t3)                                       # load the current logical map value in the right top position
        beq $t4, $t5, able_to_fall
        
        j can_not_fall
        
    can_not_fall:
        li $t5, 0
        sw $t5, can_fall
        j end_can_fall
    
    able_to_fall:
        li $t5, 1
        sw $t5, can_fall
        j end_can_fall
    end_can_fall:
    jr $ra

determine_can_rotate:
    move $t1, $s0
    move $t2, $s1
    
    
    li $t9, 2                                   # Load the divisor (2) into $t9(determine the current rotating status to determine whether should detect the +1 position or +2 position of current location))
    divu $s2, $t9                               # Unsigned division: LO = quotient, HI = remainder
    mfhi $t9                                    # Move the remainder (y % 4) from HI to $t0
    
    beq $t9, $zero, can_rotate_when_horizontal
    
    can_rotate_when_vertical:
        addi $t1, $t1, 1
        
        addi $t8, $t1, -21                          # determine for right edge
        bgtz $t8, can_not_rotate                 # determine whether t1 is greater than or equal to 22 

        j can_rotate_location_check
    
    can_rotate_when_horizontal:
        addi $t2, $t2, 1
        
        addi $t8, $t2, -24                          # determine for the bottom
        bgtz $t8, can_not_rotate                 # determine whether y position is larger than heigh(25)
    
    can_rotate_location_check:
        la $t3, current_map
        mul $t2, $t2, 88                            #calculate the correct address in current map by x, y. Calculate by width * memory offset = 22 * 4
        sll $t1, $t1, 2                             # calculate the correct offset for $t1
        add $t3, $t3, $t2
        add $t3, $t3, $t1
        
        lw $t5, BASE_COLOR
        lw $t4, 0($t3) 
        beq $t4, $t5, able_to_rotate
        j can_not_rotate
    
    can_not_rotate:
        li $t5, 0
        sw $t5, can_rotate
        j end_can_rotate
    
    able_to_rotate:
        li $t5, 1
        sw $t5, can_rotate
        j end_can_rotate
    end_can_rotate:
    jr $ra
    
    

generate_virus:
    li $t2, 0
    generate_virus_loop:
    li $v0, 42                  # generate random numbers of x position value of virus
    li $a0, 0                   # the starting x is not 0 in actual map, but is 0 in logic
    lw $a1, ending_x            # load ending x
    addi $a1, $a1, 1            # random number is not inclusive, so need to add 1 for ending_x
    lw $t3, starting_x          # load starting x to correctly finding the right x position
    sub $a1, $a1, $t3
    syscall                     # the return value will be stored in a0
    
    la $t0, current_map         # loading the current map address
    sll $t1, $a0, 2             # calculate the x offset of current virus
    
    li $v0, 42                  # generate random numbers of y position value of virus
    li $a0, 0                   # the starting y is not 0, but MIPS only support generate starting from 0, which means we need to manually calculate the random number.
    lw $a1, ending_y                   # load ending y
    addi $a1, $a1, 1
    lw $t3, starting_y
    sub $a1, $a1, $t3
    syscall                     # the return value will be stored in a0       
    
    mul $a0, $a0, 88           # calculate y offset in current map and add to t1, correct offset: 4 * 22(width)
    
    add $t1, $a0, $t1           # t1 is now the offset from current map starting address
    
    addi $sp, $sp, -4           # typical way of calling a function, choose a random virus color and store in s3
    sw $ra, 0($sp)              
    jal choose_virus_color
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    add $t0, $t0, $t1                           #save the virus color into current map
    sw $s3, 0($t0)
    
    la $t6, connection_direction_map            #save the 5 to connection_direction map (5 stands for virus)
    add $t6, $t6, $t1
    li $t5, 5
    sw $t5, 0($t6)
    
    addi $t2, $t2, 1
    
    lw $t3, number_or_virus
    beq $t2, $t3 end_generate_virus
    j generate_virus_loop
    
    end_generate_virus:
    jr $ra

lock_capsule_in_place:
    move $t1, $s0
    move $t2, $s1
    
    li $t9, 2                                   # Load the divisor (2) into $t9(determine the current rotating status is in horizontal or vertical)
    divu $s2, $t9                               # Unsigned division: LO = quotient, HI = remainder
    mfhi $t9                                    # Move the remainder (y % 4) from HI to $t0
    
    la $t3, current_map
    mul $t2, $t2, 88                            #calculate the correct address in current map by x, y. Calculate by width * memory offset = 22 * 4
    sll $t1, $t1, 2                             # calculate the correct offset for $t1
    add $t3, $t3, $t2
    add $t3, $t3, $t1
    
    la $t4, shape_matrix
    sll $t5, $s2, 4                             # calcualte the current shape matrix top left corner color
    add $t4, $t4, $t5                           
    
    lw $t6, 0($t4)                              # return an address to the color
    lw $t6, 0($t6)
    
    sw $t6, 0($t3)                              # save the top left corner
    
    beq $t9, 1, lock_vertical_capsule
    
    j lock_horizontal_capsule
    
    lock_vertical_capsule:
        addi $t4, $t4, 8                            # update to the next colored square in shape matrix
        lw $t6, 0($t4)                              # return an address to the color
        lw $t6, 0($t6)
        
        addi $t3, $t3, 88                           # y+= 1
        
        sw $t6, 0($t3)
        j end_lock_capsule
        
    lock_horizontal_capsule:
        addi $t4, $t4, 4                            # update to the next colored square in shape matrix
        lw $t6, 0($t4)                              # return an address to the color
        lw $t6, 0($t6)
        
        addi $t3, $t3, 4                           # x+= 1
        
        sw $t6, 0($t3)
        j end_lock_capsule
        
    
    end_lock_capsule:
    jr $ra

initialize_direction_map:
    la $t0, connection_direction_map          # Load base address of the array
    li $t1, 0               # Load immediate value 0
    li $t2, 550            # Number of elements

    fill_direction_map:
    beq $t2, 0, finish_filling_direction_map       # Exit loop when all elements are filled
    sw $t1, 0($t0)         # Store the address of A in the current array element
    addi $t0, $t0, 4       # Move to the next element
    subi $t2, $t2, 1       # Decrement the counter
    j fill_direction_map            # Repeat

    finish_filling_direction_map:
    jr $ra
    

update_direction_map:
    move $t1, $s0
    move $t2, $s1
    
    li $t9, 2                                   # Load the divisor (2) into $t9(determine the current rotating status is in horizontal or vertical)
    divu $s2, $t9                               # Unsigned division: LO = quotient, HI = remainder
    mfhi $t9                                    # Move the remainder (y % 4) from HI to $t0
    
    la $t3, connection_direction_map
    mul $t2, $t2, 88                            #calculate the correct address in current map by x, y. Calculate by width * memory offset = 22 * 4
    sll $t1, $t1, 2                             # calculate the correct offset for $t1
    add $t3, $t3, $t2
    add $t3, $t3, $t1

    beq $t9, 1, lock_vertical_capsule_direction
    
    j lock_horizontal_capsule_direction
    
    lock_vertical_capsule_direction:
        li $t4, 4
        sw $t4, 0($t3)
        
        addi $t3, $t3, 88                           # y+= 1
        
        li $t4, 3
        sw $t4, 0($t3)
        
        j end_lock_capsule_direction
        
    lock_horizontal_capsule_direction:
        li $t4, 2
        sw $t4, 0($t3)
        
        addi $t3, $t3, 4                           # x+= 1
        
        li $t4, 1
        sw $t4, 0($t3)
        j end_lock_capsule_direction
        
    
    end_lock_capsule_direction:
    jr $ra

check_survival:
    li $t1, 9
    li $t2, 0
    
    la $t3, current_map
    mul $t2, $t2, 88                            #calculate the correct address in current map by x, y. Calculate by width * memory offset = 22 * 4
    sll $t1, $t1, 2                             # calculate the correct offset for $t1
    add $t3, $t3, $t2
    add $t3, $t3, $t1
    
    li $t4, 6                                   # counter for bottle neck space
    
    check_survival_loop:
        lw $t5, BASE_COLOR
        lw $t6, 0($t3)
        bne $t5, $t6, end_game
        
        addi $t3, $t3, 4
        addi $t4, $t4, -1
        beq $t4, $zero, end_check_survival
        j check_survival_loop
    
    end_check_survival:
    jr $ra

fall:
    addi $sp, $sp, -4           # typical way of calling a function, choose a random color and store in s3
    sw $ra, 0($sp)              # choose a new color and store it in current color1
    jal determine_can_fall
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    lw $t1, can_fall
    beq $t1, $zero, falling_ends                   #t1 == 0 mean can not fall
    addi $s1, $s1, 1
    jr $ra
    

end_game:
    li $a0, 4             #parameter for play effect sound
    jal play_effect_sound
    
    li $v0, 10
    syscall

update_game_time:

    # load current time
    lw $t0, game_time               
    addi $t0, $t0, 1                 # game_time += 1
    sw $t0, game_time                # save current time

    # check if reach the interval 
    lw $t1, time_interval            # load the time interval 
    divu $t0, $t1                    # $LO = game_time / time_interval, $HI = game_time % time_interval
    mfhi $t2                         # $t2 = game_time % time_interval
    bne $t2, $zero, end_update_game_time  # if reminder is not 0, skip

    # decrease gravity_threshold
    lw $t3, gravity_threshold         # load gravity_threshold
    lw $t4, gravity_decrement         # load gravity_decrement
    subu $t3, $t3, $t4                # gravity_threshold -= gravity_decrement

    # reach gravity_threshold lowest
    lw $t5, minimum_gravity_threshold # load the lowest
    bgeu $t3, $t5, update_gravity_threshold  # if gravity_threshold >= minimum_gravity_threshold，update gravity_threshold
    move $t3, $t5                     # let gravity_threshold = minimum_gravity_threshold

update_gravity_threshold:
    sw $t3, gravity_threshold         


end_update_game_time:
    jr $ra                            #back
    


initialize_score:
    li $t0, 0                       # set the score to be zero
    sw $t0, current_score
    li $t1, 2                       # set the display x
    sw $t1, score_x_pos
    li $t1, 1                       # set the display y
    sw $t1, score_y_pos
    jr $ra                          # back 

#base on the current socore, first cut it into two numbers, and draw it separtely
draw_score:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)

    # divide current_score to two parts
    lw $t0, current_score
    div $t0, $t0, 10
    mfhi $s2             # low 
    mflo $s1             # high
    
    # draw high
    li $a0, 25           # X start
    li $a1, 10           # Y start
    move $a2, $s1        # low number
    jal draw_digit       # draw it 

    # draw low
    li $a0, 25           # X start
    li $a1, 20           # Y start
    move $a2, $s2        # high number
    jal draw_digit       # draw it 

    # return 
    lw $s3, 12($sp)
    lw $s2, 8($sp)
    lw $s1, 4($sp)
    lw $ra, 0($sp)
    addi $sp, $sp, 16
    jr $ra
    
    
    #$a0 is the x start, $a1 is the y start
    #$a2 is the number
    draw_digit:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    lw $t0, ADDR_DSPL
    lw $t1, TESTING_COLOR      # load the write 
    lw $t2, BASE_COLOR      # load the black 

    beq $a2, 0, draw_0
    beq $a2, 1, draw_1
    beq $a2, 2, draw_2
    beq $a2, 3, draw_3
    beq $a2, 4, draw_4
    beq $a2, 5, draw_5
    beq $a2, 6, draw_6
    beq $a2, 7, draw_7
    beq $a2, 8, draw_8
    beq $a2, 9, draw_9
    
    finish_drawing:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
    draw_0:
        mult $t3, $a1, 32 
        add $t3, $t3, $a0  
        sll $t3, $t3, 2
        add $t4, $t3, $t0
        sw $t1, 0($t4)      # Row 1
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 2
        sw $t1, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 3
        sw $t1, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 4
        sw $t1, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 5
        sw $t1, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 6
        sw $t1, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 7
        sw $t1, 0($t4)
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
        j finish_drawing
        
    draw_1:
        mult $t3, $a1, 32
        add $t3, $t3, $a0
        sll $t3, $t3, 2
        add $t4, $t3, $t0
        sw $t0, 0($t4)      # Row 1
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t0, 12($t4)
        sw $t0, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 2
        sw $t0, 0($t4)
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t0, 12($t4)
        sw $t0, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 3
        sw $t0, 0($t4)
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t0, 12($t4)
        sw $t0, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 4
        sw $t0, 0($t4)
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t0, 12($t4)
        sw $t0, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 5
        sw $t0, 0($t4)
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t0, 12($t4)
        sw $t0, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 6
        sw $t0, 0($t4)
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t0, 12($t4)
        sw $t0, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 7
        sw $t0, 0($t4)
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t0, 12($t4)
        sw $t0, 16($t4)
        j finish_drawing
    draw_2:
        mult $t3, $a1, 32
        add $t3, $t3, $a0
        sll $t3, $t3, 2
        add $t4, $t3, $t0
        sw $t1, 0($t4)      # Row 1
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 2
        sw $t0, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 3
        sw $t1, 0($t4)
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 4
        sw $t1, 0($t4)
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t0, 12($t4)
        sw $t0, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 5
        sw $t1, 0($t4)
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 6
        sw $t1, 0($t4)
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 7
        sw $t1, 0($t4)
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
        j finish_drawing
    draw_3:
        mult $t3, $a1, 32
        add $t3, $t3, $a0
        sll $t3, $t3, 2
        add $t4, $t3, $t0
        sw $t1, 0($t4)      # Row 1
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 2
        sw $t0, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 3
        sw $t0, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 4
        sw $t1, 0($t4)
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 5
        sw $t0, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 6
        sw $t0, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 7
        sw $t1, 0($t4)
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
        j finish_drawing
    draw_4:
        mult $t3, $a1, 32
        add $t3, $t3, $a0
        sll $t3, $t3, 2
        add $t4, $t3, $t0
        sw $t1, 0($t4)      # Row 1
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 2
        sw $t1, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 3
        sw $t1, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 4
        sw $t1, 0($t4)
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 5
        sw $t0, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 6
        sw $t0, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 7
        sw $t0, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
        j finish_drawing
    draw_5:
        mult $t3, $a1, 32
        add $t3, $t3, $a0
        sll $t3, $t3, 2
        add $t4, $t3, $t0
        sw $t1, 0($t4)      # Row 1
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 2
        sw $t1, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t0, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 3
        sw $t1, 0($t4)
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 4
        sw $t0, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 5
        sw $t0, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 6
        sw $t0, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 7
        sw $t1, 0($t4)
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
        j finish_drawing
        
    draw_6:
        mult $t3, $a1, 32
        add $t3, $t3, $a0
        sll $t3, $t3, 2
        add $t4, $t3, $t0
        sw $t1, 0($t4)      # Row 1
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 2
        sw $t1, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t0, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 3
        sw $t1, 0($t4)
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 4
        sw $t1, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 5
        sw $t1, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 6
        sw $t1, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 7
        sw $t1, 0($t4)
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
        j finish_drawing
        
    draw_7:
        mult $t3, $a1, 32
        add $t3, $t3, $a0
        sll $t3, $t3, 2
        add $t4, $t3, $t0
        sw $t1, 0($t4)      # Row 1
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 2
        sw $t0, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 3
        sw $t0, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 4
        sw $t0, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t1, 12($t4)
        sw $t0, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 5
        sw $t0, 0($t4)
        sw $t0, 4($t4)
        sw $t1, 8($t4)
        sw $t0, 12($t4)
        sw $t0, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 6
        sw $t0, 0($t4)
        sw $t1, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t0, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 7
        sw $t1, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t0, 16($t4)
        j finish_drawing

    draw_8:
        mult $t3, $a1, 32
        add $t3, $t3, $a0
        sll $t3, $t3, 2
        add $t4, $t3, $t0
        sw $t1, 0($t4)      # Row 1
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 2
        sw $t1, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 3
        sw $t1, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 4
        sw $t1, 0($t4)
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 5
        sw $t1, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 6
        sw $t1, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 7
        sw $t1, 0($t4)
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
        j finish_drawing
        
    draw_9:
        mult $t3, $a1, 32
        add $t3, $t3, $a0
        sll $t3, $t3, 2
        add $t4, $t3, $t0
        sw $t1, 0($t4)      # Row 1
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 2
        sw $t1, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 3
        sw $t1, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 4
        sw $t1, 0($t4)
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 5
        sw $t0, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 6
        sw $t0, 0($t4)
        sw $t0, 4($t4)
        sw $t0, 8($t4)
        sw $t0, 12($t4)
        sw $t1, 16($t4)
    
        addi $t4, $t4, 128  # Move to Row 7
        sw $t1, 0($t4)
        sw $t1, 4($t4)
        sw $t1, 8($t4)
        sw $t1, 12($t4)
        sw $t1, 16($t4)
        j finish_drawing
        
        
#Testing_Logical_Map:
    #la $t0, current_map
    #addi $t0, $t0, 88
    #li $t1, 0x00ff00
    #sw $t1, 0($t0)
    #jr $ra
    
    