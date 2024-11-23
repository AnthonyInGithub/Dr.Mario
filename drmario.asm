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
# x, y are all inclusive
starting_x: .word 1
starting_y: .word 6
ending_x: .word 22
ending_y: .word 30
initial_x: .word 12
initial_y: .word 3
number_or_virus: .word 8

current_color_1: .word 0x000000
current_color_2: .word 0x000000

shape_matrix: .word current_color_1, current_color_2, BASE_COLOR, BASE_COLOR,        BASE_COLOR, current_color_1, BASE_COLOR, current_color_2,         BASE_COLOR, BASE_COLOR, current_color_2, current_color_1,           current_color_2, BASE_COLOR, current_color_1, BASE_COLOR  #Row4
shape_matrix_row: .word 4
shape_matrix_color: .word 4

# width: 22, height 26. total: 22*26*4 = 2288
current_map: .space 2288

##############################################################################
# Permanent Register
##############################################################################
# s0: X of current capsule
# s1: Y of current capsule
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
    jal draw_background
    
    jal initialize_new_capsule
    jal draw_capsule
    jal generate_virus
    
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
    lw $t0, ADDR_DSPL
    sll $t1, $s0, 2
    sll $t2, $s1, 7         # Calculate the Y offset to add to $t1 (multiply $a1 by 128)
    add $t1, $t1, $t2       # add X offset
    add $t1, $t1, $t0       # add base location
    
    sll $t3, $s2, 4         # correspondence of rotation state and matrix. *4 to offset address first, then *4 to correspond to row
    la $t4, shape_matrix    
    add $t3, $t3, $t4       # calculate the correct starting position in shape_matrix
    lw $s3, 0($t3)          # load the current color address in shape_matrix
    lw $s3, 0($s3)          # load from current color address to color data
    sw $s3, 0($t1)
    
    addi $t1, $t1, 4        # update the new position next capsule piece in screen
    lw $s3, 4($t3)          # load next color in shape_matrix
    lw $s3, 0($s3)          # load from current color address to color data
    sw $s3, 0($t1)
    
    addi $t1, $t1, 124      # update the new position next capsule piece in screen
    lw $s3, 8($t3)          # load next color in shape_matrix
    lw $s3, 0($s3)          # load from current color address to color data
    sw $s3, 0($t1)          
    
    addi $t1, $t1, 4        # update the new position next capsule piece in screen
    lw $s3, 12($t3)         # load next color in shape_matrix
    lw $s3, 0($s3)          # load from current color address to color data
    sw $s3, 0($t1)          
    
    jr $ra
    
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

generate_virus:
    li $t2, 0
    generate_virus_loop:
    li $v0, 42                  # generate random numbers of x position value of virus
    li $a0, 0                   # the starting x is not 0 in actual map, but is 0 in logic
    lw $a1, ending_x            # load ending x
    lw $a3, starting_x          # load starting x to correctly finding the right x position
    sub $a1, $a1, $a3
    syscall                     # the return value will be stored in a0
    
    la $t0, current_map         # loading the current map address
    sll $t1, $a0, 2             # calculate the x offset of current virus
    add $t1, $t0, $t1
    
    li $v0, 42                  # generate random numbers of y position value of virus
    li $a0, 0                   # the starting y is not 0, but MIPS only support generate starting from 0, which means we need to manually calculate the random number.
    lw $a1, ending_y            # load ending y
    lw $a3, starting_y
    sub $a1, $a1, $a3
    syscall                     # the return value will be stored in a0       
    
    li $a3, 100                 #correct offset: 4 * 25(height)
    mul $a0, $a0, $a3           # calculate y offset in current map and add to t1
    add $t1, $a0, $t1           
    
    addi $sp, $sp, -4           # typical way of calling a function, choose a random virus color and store in s3
    sw $ra, 0($sp)              
    jal choose_virus_color
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    sw $s3, 0($t1)
    
    addi $t2, $t2, 1
    
    lw $t3, number_or_virus
    beq $t2, $t3 end_generate_virus
    j generate_virus_loop
    
    end_generate_virus:
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
    addi $t4, $t4, 1
    
    sll $t1, $t1, 2 # calculating correct x, y offset
    sll $t3, $t3, 7
    
    lw $t5, ADDR_DSPL # t5 stands for starting location in map
    add $t5, $t1, $t5
    add $t5, $t3, $t5
    
    li $t9, 0 #t9 standing for current location in bit map relative to current map
    add $t9, $t9, $t5
    
    draw_current_map_loop:
        
        lw $s3, 0($t6) # load the current color into t8
        sw $s3, 0($t9)
        addi $t6, $t6, 4 #update current map 
        addi $t9, $t9, 4 #update bitmap location
        beq $t7, $t2, update_y_when_drawing_current_map
        addi $t7, $t7, 1
        
        j draw_current_map_loop
        
    update_y_when_drawing_current_map:
        li $t7, 0           # reset logical x position
        addi $t9, $t5, 0      # reset then calculte current bit map position
        sll $t1, $t7, 2  #reuse t1, t3, now t1, t3 is the current x, y offset from the t5
        sll $t3, $t8, 7
        add $t9, $t9, $t1
        add $t9, $t9, $t3
        beq $t8, $t4, end_drawing_current_map
        addi $t8, $t8, 1    #update logical y position
        j draw_current_map_loop
    
    end_drawing_current_map:
    
    
    
    jr $ra
    
    

###############################################################
# Handle Key Board Input Logic
###############################################################
keyboard_input:                     # A key is pressed
    lw $a0, 4($t0)                  # Load second word from keyboard  
    
    beq $a0, 0x71, quit     # Check if the key q was pressed
    beq $a0, 0x77, pressW
    beq $a0, 0x61, pressA   
    beq $a0, 0x73, pressS
    beq $a0, 0x64, pressD
    
    b input_ends

pressW:
    addi $s2, $s2, 1      # s2 = s2 + 1
    li $t1, 4             # Load the divisor (4) into $t1
    divu $s2, $t1         # Unsigned division: LO = quotient, HI = remainder
    mfhi $s2              # Move the remainder (y % 4) from HI to $t0
    b input_ends
pressA:
    addi $s0, $s0, -1
    b input_ends
pressS:
    addi $s1, $s1, 1
    b input_ends
pressD:
    addi $s0, $s0, 1
    b input_ends
    
###############################################################
# Handle Game Rule Logic
#############################################################
quit:
	li $v0, 10                      # Quit gracefully
	syscall

initialize_new_capsule:
    lw $s0, initial_x #initialize position of capsule
    lw $s1, initial_y
    li $s2, 0           #initialize rotation state
    
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
    lw $t1, TESTING_COLOR        # Load the address of base color into $t1
    li $t2, 572            # Number of elements

    fill_current_map:
    beq $t2, 0, finish_filling_current_map       # Exit loop when all elements are filled
    sw $t1, 0($t0)         # Store the address of A in the current array element
    addi $t0, $t0, 4       # Move to the next element
    subi $t2, $t2, 1       # Decrement the counter
    j fill_current_map            # Repeat

    finish_filling_current_map:
    jr $ra
    