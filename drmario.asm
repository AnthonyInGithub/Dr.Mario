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
# x, y are all inclusive
starting_x: .word 1
starting_y: .word 6
ending_x: .word 22
ending_y: .word 30
initial_x: .word 12
initial_y: .word 3
number_or_virus: .word 8
stack_top: .word 0 

current_color_1: .word 0x000000
current_color_2: .word 0x000000

shape_matrix: .word current_color_1, current_color_2, BASE_COLOR, BASE_COLOR,        BASE_COLOR, current_color_1, BASE_COLOR, current_color_2,         BASE_COLOR, BASE_COLOR, current_color_2, current_color_1,           current_color_2, BASE_COLOR, current_color_1, BASE_COLOR  #Row4
shape_matrix_row: .word 4
shape_matrix_color: .word 4

# width: 22, height 26. total: 22*26*4 = 2288
current_map: .space 2288
#
#0: No direction (independent block).
#1: Connected to the left.
#2: Connected to the right.
#3: Connected above.
#4: Connected below.
direction_map: .space 2288  # Holds the direction metadata
stack_base: .space 400
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

clear_the_virus:
    # Step 1: Scan and mark blocks to clear
    jal initialize_stack
    jal scan_for_lines_horizontal
    jal scan_for_lines_vertical

    # Step 2: Clear the marked blocks
    jal clear_marked_blocks

    # Step 3: Apply gravity
    jal apply_gravity

    jr $ra
    
    
    # initialize the stack 
initialize_stack:
    la $t8, stack_base   # the base address of stack 
    li $t9, 0            
    sw $t9, stack_top
    jr $ra

# push to stack
push_to_stack:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $a0, 4($sp)

    la $t8, stack_base
    lw $t9, stack_top
    sll $t9, $t9, 2        # calculate the offset
    add $t8, $t8, $t9      # calculate the address 
    sw $a0, 0($t8)         # push into the stack 
    lw $t9, stack_top                               
    addi $t9, $t9, 1       # stack plus 1
    sw $t9, stack_top

    lw $ra, 0($sp)
    lw $a0, 4($sp)
    addi $sp, $sp, 16
    jr $ra

# pop the stack 
pop_from_stack:
    addi $sp, $sp, -16
    sw $ra, 0($sp)

    lw $t8, stack_top
    blez $t9, stack_empty      # if stack  <= 0 back
    addi $t9, $t9, -1          # stack -1
    sw $t9, stack_top
    la $t8, stack_base
    sll $t9, $t9, 2           
    add $t8, $t8, $t9        
    lw $v0, 0($t8)          

stack_empty:
    lw $ra, 0($sp)
    addi $sp, $sp, 16
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
    beqz $t4, next_horizontal_col

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
    add $t2, $s2, $zero
    bge $s2, 4, push_all_to_mark

push_all_to_mark:
    blez $t2, next_horizontal_col
    move $a0, $t1
    jal push_to_stack
    sll $t1, $t1, 2
    sub $t2, $t2, 1
    add $s1, $s1, 1
    jal push_all_to_mark
    
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
    li $t1, 22           # Number of columns
    li $t2, 25           # Number of rows

vertical_scan_loop:
    bge $s0, 22, end_vertical_scan  # If column exceeds max, stop
    li $s1, 0                       # Reset row index for each column

vertical_check_loop:
    bge $s1, 25, next_vertical_column  # If row exceeds max, go to next column

    # Load current block color
    mul $t3, $s1, 22                  # t3 = row * num_columns
    add $t3, $t3, $s0                 # t3 = (row * num_columns) + column
    sll $t3, $t3, 2                   # t3 = t3 * 4 (byte offset)
    add $t3, $t0, $t3                 # t3 = map_base + offset
    lw $t4, 0($t3)                    # Load color

    # Skip if the block is empty
    beqz $t4, next_vertical_row

    # Match consecutive blocks
    li $s2, 1                         # Match counter = 1
    move $t5, $s1                     # Start matching from current row

match_vertical_blocks:
    addi $t5, $t5, 1                  # Next row
    bge $t5, 25, vertical_match_done  # If out of bounds, stop matching

    # Load next block color
    mul $t6, $t5, 22                  # t6 = row * num_columns
    add $t6, $t6, $s0                 # t6 = (row * num_columns) + column
    sll $t6, $t6, 2                   # t6 = t6 * 4 (byte offset)
    add $t6, $t0, $t6                 # t6 = map_base + offset
    lw $t7, 0($t6)                    # Load next color

    # Check if the colors are in the same group
    move $a0, $t4
    move $a1, $t7
    jal same_group
    beqz $v0, vertical_match_done     # If not in the same group, stop

    addi $s2, $s2, 1                  # Increment match counter
    j match_vertical_blocks

vertical_match_done:
    blt $s2, 4, next_vertical_row     # If less than 4 matches, skip
    add $t2, $s2, $zero
    bge $s2, 4, push_all_to_mark_vertical

push_all_to_mark_vertical:
    blez $t2, next_vertical_row
    move $a0, $t1
    jal push_to_stack
    sll $t1, $t1, 2
    sub $t2, $t2, 1
    add $s1, $s1, 1
    jal push_all_to_mark_vertical

next_vertical_row:
    addi $s1, $s1, 1                  # Next row
    j vertical_check_loop

next_vertical_column:
    addi $s0, $s0, 1                  # Next column
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
    addi $sp, $sp, -16
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
    addi $sp, $sp, 16
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
    la $s4, direction_map   # load direction map

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

    # Clear corresponding pixel in the display
    # Convert index to row and column
    divu $t2, $t0, 22       # Perform division (row = index / num_columns)
    mflo $t2                # Move quotient (row) to $t2
    mfhi $t3                # Move remainder (column) to $t3

    mul $t4, $t2, 128       # $t4 = row_offset = row * 128 (Y-axis offset)
    mul $t5, $t3, 4         # $t5 = col_offset = col * 4 (X-axis offset)
 
    # Compute display address and clear pixel
    add $t6, $s2, $t4       # $t6 = base_display + row_offset
    add $t6, $t6, $t5       # $t6 = display_address
    sw $s3, 0($t6)          # Set pixel to background color (cleared)
    
    #clear the direction map
    
    sll $t1, $t0, 2
    add $t1, $s4, $t1
    lw $t9, 0($t1)
    beq $t9, 1, left_clear
    beq $t9, 2, right_clear
    beq $t9, 3, top_clear
    beq $t9, 4, bottom_clear
    sw $zero, 0($t1)
    
    j clear_stack_loop      # Continue clearing the next marked block

left_clear:
    sub $t8, $t1, 4
    sw $zero, 0($t8)
    jr $ra
    
right_clear:
    addi $t8, $t1, 4
    sw $zero, 0($t8)
    jr $ra
    
top_clear:
    sub $t8, $t1, 128
    sw $zero, 0($t8)
    jr $ra
    
bottom_clear:
    addi $t8, $t1, 128
    sw $zero, 0($t8)
    jr $ra
    
virus_clear:


    

clear_done:
    # Restore $s registers from the stack
    lw $s4, 20($sp)
    lw $s3, 16($sp)         # Restore $s3 (background color)
    lw $s2, 12($sp)         # Restore $s2 (display address)
    lw $s1, 8($sp)          # Restore $s1 (stack index)
    lw $s0, 4($sp)          # Restore $s0 (current_map base address)
    lw $ra, 0($sp)          # Restore return address
    addi $sp, $sp, 20       # Restore stack pointer

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
    sw $s5, 24($sp) 
    sw $s6, 28($sp)  
    sw $s7, 32($sp)  

    la $t0, current_map      # load current_map base 
    la $t1, direction_map    # load direction_map base
    la $t2, ADDR_DSPL        # load display address
    li $s0, 0                # start from column 0


gravity_column_loop:
    bge $s0, 22, gravity_done  # if column excessed, end it
    li $s1, 23                  # start from the last row 

gravity_row_loop:
    bgt $s1, 25, next_column   # if row excessed, end it 
    mul $s6, $s1, 22            
    add $s6, $s6, $s0          
    sll $s6, $s6, 2            
    add $s6, $t0, $s6           # calculate current_map current block 
    lw $s3, 0($s6)              

    add $s7, $t1, $s6           # $s7 = direction_map 
    lw $s4, 0($s7)              

    # if it is empty ,move to next row 
    beq $s3, $zero, move_to_next_row

    beq $s4, $zero, handle_independent_block   
    beq $s4, 1, handle_right_connected_block   
    beq $s4, 4, handle_bottom_connected_block  

    j move_to_next_row

handle_independent_block:

    addi $s2, $s1, 1                # next row 
    bgt $s2, $t4, move_to_next_row  

    mul $s5, $s2, 22
    add $s5, $s5, $s0
    sll $s5, $s5, 2
    add $s5, $t0, $s5              # （current_map）
    lw $t5, 0($s5)                 # load the color 
    bne $t5, $zero, move_to_next_row # if it is not empty, skip it

    # update current_map
    sw $s3, 0($s5)             
    sw $zero, 0($s6)           

    # update direction_map
    add $t6, $t1, $s5              
    sw $s4, 0($t6)                
    add $t7, $t1, $s6              
    sw $zero, 0($t7)              
    
    #update the display address
    addi $t6, $s1, 6  #calculate the row 
    mult $t6, $t6, 128 #calculate the offst
    addi $t7, $s0, 1   # add column 
    mult $t7, $t7, 4
    add $t6, $t6, $t7
    add $t6, $t0, $t6
    sw $zero, 0($t6)
    sw $s3, 128($t6)
    

    handle_right_connected_block  :

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
    sw $s4, 0($t9)                  # Copy direction for left part
    add $t9, $t1, $t6               # Target address in direction_map for right part
    sw $s4, 0($t9)                  # Copy direction for right part
    add $t9, $t1, $t7               # Original address in direction_map for left part
    sw $zero, 0($t9)                # Clear original left direction
    add $t9, $t1, $t8               # Original address in direction_map for right part
    sw $zero, 0($t9)                # Clear original right direction

    # Update display
    # Compute left target display address
    add $t4, $s2, $s6              # Adjust for starting_y
    mul $t4, $t4, 128              # Row offset in display
    add $t5, $s0, $s5              # Adjust for starting_x
    mul $t5, $t5, 4                # Column offset in display
    add $t4, $t2, $t4              # Base + row offset
    add $t4, $t4, $t5              # Full target display address for left part
    sw $s3, 0($t4)                 # Update target display for left part

    # Clear original left display
    add $t4, $s1, $s6              # Adjust for starting_y
    mul $t4, $t4, 128              # Row offset in display
    add $t5, $s0, $s5              # Adjust for starting_x
    mul $t5, $t5, 4                # Column offset in display
    add $t4, $t2, $t4              # Base + row offset
    add $t4, $t4, $t5              # Full original display address for left part
    sw $zero, 0($t4)               # Clear original display for left part

    # Compute right target display address
    add $t6, $s2, $s6              # Adjust for starting_y
    mul $t6, $t6, 128              # Row offset in display
    add $t7, $t3, $s5              # Adjust for starting_x
    mul $t7, $t7, 4                # Column offset in display
    add $t6, $t2, $t6              # Base + row offset
    add $t6, $t6, $t7              # Full target display address for right part
    sw $s3, 0($t6)                 # Update target display for right part

    # Clear original right display
    add $t6, $s1, $s6              # Adjust for starting_y
    mul $t6, $t6, 128              # Row offset in display
    add $t7, $t3, $s5              # Adjust for starting_x
    mul $t7, $t7, 4                # Column offset in display
    add $t6, $t2, $t6              # Base + row offset
    add $t6, $t6, $t7              # Full original display address for right part
    sw $zero, 0($t6)               # Clear original display for right part

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
    sw $s4, 0($t7)                  # Copy direction
    add $t7, $t1, $t6               # Original address in direction_map
    sw $zero, 0($t7)                # Clear original direction

    # Update display
    # Compute target display address
    add $t8, $s2, $s6              # Adjust for starting_y
    mul $t8, $t8, 128              # Row offset in display
    add $t9, $s0, $s5              # Adjust for starting_x
    mul $t9, $t9, 4                # Column offset in display
    add $t8, $t2, $t8              # Base + row offset
    add $t8, $t8, $t9              # Full target display address
    sw $s3, 0($t8)                 # Update target display

    # Clear original display
    add $t8, $s1, $s6              # Adjust for starting_y
    mul $t8, $t8, 128              # Row offset in display
    add $t9, $s0, $s5              # Adjust for starting_x
    mul $t9, $t9, 4                # Column offset in display
    add $t8, $t2, $t8              # Base + row offset
    add $t8, $t8, $t9              # Full original display address
    sw $zero, 0($t8)               # Clear original display

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
    