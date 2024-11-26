################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Dr Mario.
#
# Student 1: Tianxiang Zhu, 1009802536
# Student 2: Bo Xu, Student Number (if applicable)
#
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
number_or_virus: .word 8

current_color_1: .word 0x000000
current_color_2: .word 0x000000

sound_effect_notes: .word 72, 69, 64, 72, 48  # MIDI numbers for C5, A4, E4, C5, C3
sound_effect_notes_duration: .word 100, 150, 200, 300, 500

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
    jal draw_background
    
    jal initialize_new_capsule
    jal draw_capsule
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
	jal draw_capsule
	#jal Testing_Logical_Map
	
	
	# methods to implement: canMove, lockCapsuleInPlace, clearLines(lines of 4 in vertical/horizontal direction), check_survival(whether capsule reach top)
	#feature: easy: 1, 2, 4, 5. Hard: 1, 5
	
	#grouping(Wiliam): easy: 1, 2, clearLines, Hard:1, easy:4
	#grouping(Anthony): easy5, Hard: 5, canMove, lockCapsuleInPlace, check_survival, generate_virus

	#concatenate: easy:4, check_survival
	#ending:  easy: 5
	
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
    add $t6, $t4, $t5           # Calculate the address of the final point in the line, store result in $t6.
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
    li $a0, 0                   # lower bound is 0
    li $a1, 3                   # upper bound is 3 (number generated will be in [0,2]
    syscall                     # the return value will be stored in a0
    
    la $t3, colors              # load the colors array into t3
    sll $a0, $a0, 2             # calculate the memory offset of a0
    add $t3, $t3, $a0           # update the offset a0 to t3
    lw $s3, 0($t3)              # load randomly a value of color into t4
    
    jr $ra
    
# randomly choose one virus color from virus_colors and store in s3. 
choose_virus_color:
    li $v0, 42                  # generate random numbers                                
    li $a0, 0                   # lower bound is 0
    li $a1, 3                   # upper bound is 3 (number generated will be in [0,2]
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

#a0: action type: 0: rotate, 1: dropping(press w), 2: lock_capsule_in_place 3: remove row or column, 4: game_over
play_effect_sound:
    la $t1, sound_effect_notes
    la $t2, sound_effect_notes_duration
    
    sll $t3, $a0, 2      # calculate the offset
    add $t1, $t1, $t3
    add $t2, $t2, $t3
    
    lw $a0, 0($t1)      # retrieve the current note and duration
    lw $a1, 0($t2)
    li $a2, 123
    li $a3, 100
    
    li $v0, 31           # Syscall to play sound effect
    syscall
    
    
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
    #jal play_effect_sound
    
    b input_ends
pressA:
    
    jal determine_can_move_left
    lw $t1, can_move_left
    beq $t1, $zero, input_ends                   #t1 == 0 mean can not move left
    addi $s0, $s0, -1
    b input_ends
pressS:
    jal determine_can_fall
    lw $t1, can_fall
    beq $t1, $zero, falling_ends                   #t1 == 0 mean can not fall
    addi $s1, $s1, 1
    b input_ends
    
    falling_ends:
        jal lock_capsule_in_place
        jal update_direction_map
        jal initialize_new_capsule
        jal check_survival
    
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

initialize_new_capsule:
    lw $s0, initial_x_logical #initialize position of capsule
    lw $s1, initial_y_logical
    li $s2, 1           #initialize rotation state
    
    addi $sp, $sp, -4           # typical way of calling a function, choose a random color and store in s3
    sw $ra, 0($sp)              # choose a new color and store it in current color1
    jal choose_color
    lw $ra, 0($sp)
    addi $sp, $sp, 4 
    
    sw $s3, current_color_1
    
    addi $sp, $sp, -4           # typical way of calling a function, choose a random color and store in s3
    sw $ra, 0($sp)              # choose a new color and store it in current color1
    jal choose_color
    lw $ra, 0($sp)
    addi $sp, $sp, 4 
    
    sw $s3, current_color_2
    
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

end_game:
    li $v0, 10
    syscall

        

        
    

#Testing_Logical_Map:
    #la $t0, current_map
    #addi $t0, $t0, 88
    #li $t1, 0x00ff00
    #sw $t1, 0($t0)
    #jr $ra
    
    