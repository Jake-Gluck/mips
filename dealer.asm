##############################################################################
# Dealer                                                              dealer.s
#
# This project is all about manipulating arrays and using subroutines.  I've
# preloaded a set of strings naming the cards in a deck and set up an array
# of pointers to the card names. I suggest you don't alter these, but you
# can copy the array and manipulate it in various ways.
#
# Specifically, you should have a deck array and a discard array. Initially,
# both arrays should be filled with null pointers.  For I/O, the main program
# accepts (S)huffle and only accepts (D)raw if the deck array is not empty.
# When these commands are selected, a subroutine is called to handle them. In
# the case of the (D)raw command, when the subroutine returns, the main
# program should display the returned card name.
#
# For the (S)huffle command, a subroutine is called with the addresses of the
# deck and discard arrays. It should clear the discard array if it is not
# already empty and copy the array of pointers to card to the deck array. It
# should then shuffle the deck array.
#
# For the (D)raw command, a subroutine is called with the addresses of the
# deck and discard arrays, as well as the index of the last card in the deck.
# it will then move that card pointer to the discard array, clear it from the
# deck array, and return the pointer to the caller.
#
# For your shuffle subroutine, you will need to modify and use the random
# code you built for the first project.  You don't need it to loop and you
# always need a number between 0 and 51 for indexing into the card array. For
# this project, I allow the use of system service #30, so you can use the time
# value returned in $a0 as your seed.
#
# Author: Patrick Kelley (skeleton file)			11.5.2023
# Author:
##############################################################################
	.data
# constants
Multiplier:	.word	1073807359	# a sufficiently large prime
Seed:		.word	0		# delcared seed for linear congruence algorithm
Range:		.word	51		# Your shuffling subroutine needs to get a random number between 0 and 51
TempBuffer:  	.space 	2        	# Space for temporary input storage, 2 bytes
Cards:  	.space 208              # Space for 52 cards, 4 bytes each
Deck:   	.space 208              # Space for 52 cards, 4 bytes each
Discard: 	.space 208            	# Space for 52 cards, 4 bytes each
UserPrompt:	.asciiz "Enter s to shuffle, d to draw, or q to quit.\n"
ErrorMessage:	.asciiz "Invalid input.\n"
Newline:	.asciiz "\n"
ShufflePrompt:	.asciiz	"Shuffle selected\n"
DrawCardPrompt:	.asciiz "Draw card selected\n"

#----- Your data definitions go here -----#

	.text
	.globl main
main:
	jal 	initCards		# initialize the Cards array
	j ValidateUserInput		# validate user input

	# just some code to test print the unshuffled Cards array
	# delete it when you like
	#li	$t0, 52
	#la	$t1, Cards
	#li	$v0, 4 
	
ValidateUserInput:
	# prompt user
	li $v0, 4			# syscall to to print a string
	la $a0, UserPrompt	        # load the address of label Prompt into $a0
	syscall				# perform the syscall
	
	# read user input
        li $v0, 12               	# syscall to read character
        syscall                  	# perform the syscall
        move $t0, $v0           	# store the character in $t0
        
        # discard newline character from input        
        li $v0, 8                	# syscall to read a string
        la $a0, TempBuffer       	# load address of TempBuffer
        li $a1, 2                	# read up to 1 character + null terminator
        syscall                  	# perform the syscall, discard the newline (if there is one)
    
        # check if user input is valid (s, S, d, D, q, or Q)
        li $t1, 115			# load ascii value for s
        beq $t0, $t1, Shuffle		# if user input is s, branch to Shuffle
        
        li $t1, 83			# load ascii value for S
        beq $t0, $t1, Shuffle		# if user input is S, branch to Shuffle
        
        li $t1, 100			# load ascii value for d
        beq $t0, $t1, DrawCard		# if user input is d, branch to DrawCard
        
        li $t1, 68			# load ascii value for D
        beq $t0, $t1, DrawCard		# if user input is D, branch to DrawCard         
	
        li $t1, 113			# load ascii value for q
        beq $t0, $t1, Quit		# if user input is q, branch to Quit
        
        li $t1, 81			# load ascii value for Q
        beq $t0, $t1, Quit		# if user input is Q, branch to Quit
        
        # if user input isn't valid
        li $v0, 4			# syscall to print a string
	la $a0, ErrorMessage	        # load the address of label ErrorMessage into $a0
	syscall				# perform the syscall
	
	j ValidateUserInput		# jump to ValidateUserInput to re-prompt user to enter valid input
        
        	
PrintLoop:
	blez	$t0, Quit
	addiu	$t0, $t0, -1
	lw	$a0, 0($t1)	# get address of next string
	syscall			# and print it
	la	$a0, Newline	# and then print a new line
	syscall
	addiu	$t1, $t1, 4	# get next string pointer address
	j	PrintLoop

Quit:	
	li	$v0, 10		# syscall for exit	
	syscall			# exit

##############################################################################
# Your shuffling subroutine needs to get a random number between 0 and 51.
# Call this random subroutine anytime you need a new random number
##############################################################################
GetRandom52:

	# This is how you get the seed from the system time		
	li	$v0, 30		# syscall for retrieve system time ($a0 = seconds since epoch)
	syscall			# retrieve system time 	
	sw	$a0, Seed 	# stores seconds since epoch into Seed label
	
	#----- Your main code can go here -----#
	
	lw $t0, Seed		# loads Seed into $t0
	lw $t1, Multiplier	# loads Multiplier into $t1
	lw $t3, Range		# loads Range into $t3
	
	# 1) multiply Seed by Multiplier
	mul $t5, $t0, $t1	# multiply Seed by Multiplier and save the product in $t5
	
	# 2) lo replaces the old seed
	mflo $t0		# moves value from $lo to $t0, replacing seed with lo
	sw $t0, Seed  		# store the lower 32 bits into Seed
	
	# 3) hi is the raw random number
	mfhi $t2		# moves value from $hi to $t2
	
	# next range fit the raw random for output

	# 1) divide the raw random by the precalculated range (unsigned division)
	divu $t2, $t3		# unsigned divide $t2 by $t3, lo = quotient, hi = remainder
			
	# 2) hi holds the ranged random after division
	mfhi $t4		# sets $t4 = remainder of $t2 / $t3
	
	# 3) add minimum to the ranged random 
	# the range is 0 - 51 so the minimum is 0, so no need to add 0 to $t4
	
	#4) copy $t4 to $s0 so it can be used in other functions
	move $s0, $t4		# $s0 = $t4
	
	jr $ra			# return to the function that called GetRandom52

##############################################################################
# The shuffle routine should copy the Cards array to your deck array and clear
# the discard array.  You can then shuffle the deck array by looping through
# every item in the deck array and swapping it with another random item. You
# only need to do that once to sufficiently shuffle the deck.  Doing it more
# than three times is a waste of time as you will spend most of your time
# reshuffling what has already been shuffled.
##############################################################################
Shuffle:

	# clear Discard array
	
        li $t0, 52              	# load 52(# of cards) into $t0
        la $t1, Discard         	# load base address of Discard array into $t1
        
        # sub routine loop to clear Discard array
        ClearDiscardLoop:
        sw $zero, 0($t1)        	# Discard[i] = 0, clears card in Discard[i]
        addi $t1, $t1, 4        	# iterate to next card in Discard array
        addi $t0, $t0, -1       	# decrement counter that controls number of loop iterations
        bgtz $t0, ClearDiscardLoop 	# if counter is > 0, repeat ClearDiscardLoop


	# copy Cards to Deck
	li $t0, 52                	# load 52(# of cards) into $t0
	la $t1, Cards             	# load base address of Cards array into $t1
	la $t2, Deck              	# load base address of Deck array into $t2

        # sub routine loop to copy Cards to Deck
	CopyCardsLoop:
   	lw $t3, 0($t1)        		# load Cards[i] into $t3
    	sw $t3, 0($t2)        		# store Cards[i] in Deck[i]
    	addi $t1, $t1, 4     		# increment Cards pointer
    	addi $t2, $t2, 4     		# increment Deck pointer
    	addi $t0, $t0, -1    		# decrement counter that controls number of loop iterations
    	bgtz $t0, CopyCardsLoop		# if counter is > 0, repeat CopyCardsLoop

	# shuffle deck
   	li $t0, 52                	# load 52(# of cards) into $t0
    	la $t1, Deck              	# load address of Deck array into $t1
    	
    	#sub routine loop to shuffle the loop
    	
	ShuffleLoop:
    	jal GetRandom52       		# generate a random index by calling GetRandom52 sub routine
    	move $t2, $s0         		# save random index in $t2

    	# calculate addresses of Deck[i] and Deck[random]
    	mul $t3, $t0, 4       		# $t3 = i * 4 (byte offset for Deck[i])
    	add $t4, $t1, $t3     		# $t4 = address of Dick[i] = byte offset for Deck[i] + base address of Deck 
    	mul $t5, $t2, 4       		# $t5 = random num($t2) * byte offset(4) = byte offset for random num)
    	add $t6, $t1, $t5     		# $t6 = address of Deck[random](random num byte offset + base address of deck)

    	# swap Deck[i] and Deck[random]
    	lw $t7, 0($t4)        		# load Deck[i] into $t7
    	lw $t8, 0($t6)        		# load Deck[random] into $t8
    	sw $t8, 0($t4)        		# store Deck[random] at Deck[i]
    	sw $t7, 0($t6)        		# store Deck[i] at Deck[random]

    	addiu $t0, $t0, -1    		# decrement counter that controls shuffle loop by 1
    	bgtz $t0, ShuffleLoop		# if counter is still > 0, repeat shuffle loop

	#li $v0, 4			# tells the system its going to want to print a string
	#la $a0, ShufflePrompt	        # load the address of label Prompt into $a0
	#syscall				# do the thing, print the 
	#j Quit

##############################################################################
# Let the main program keep track of the index of the current draw card.  When
# you reshuffle, the index is 51. Once you draw index 0, the deck is empty and
# you can't draw again until it is re-shuffled.
# 
# When this routine is given the index, it gets the pointer value from the
# deck array and puts it in the discard array at (51 - index).  This takes the
# cards from the bottom of the deck array and fills the discard array from the
# top.  It then returns the pointer value to the caller so the caller can
# print the card string.  Don't forget that the main program, not the sub-
# routine, must update the index when a card is drawn.
##############################################################################
DrawCard:
	# inputs: $a0 = DeckIndex
	# outputs: $v0 = Pointer to drawn card

	# calculate addresses
	la $t0, Deck             # load base address of Deck array into $t0
	mul $t1, $a0, 4          # $t1 = DeckIndex($a0) * 4(byte offset)
	add $t2, $t0, $t1        # $t2 = address of Deck[DeckIndex](Deck base address + DeckIndex offset)

	# load card from Deck
	lw $v0, 0($t2)           # load Deck[DeckIndex] into $v0
	sw $zero, 0($t2)         # clear Deck[DeckIndex], zeroes $t2, removes card

	# move card to Discard
	la $t3, Discard          # load address of Discard array to $t3
	li $t4, 51               # load 51(max index for Discard array) to $t4
	sub $t5, $t4, $a0        # $t5(DiscardIndex) = 51 - DeckIndex
	mul $t6, $t5, 4          # $t6 = DiscardIndex * 4(byte offset)
	add $t7, $t3, $t6        # $t7 = Address of Discard[DiscardIndex]
	sw $v0, 0($t7)           # store card pointer in Discard

	jr $ra                   # return to function that called DrawCard

	#li $v0, 4			# tells the system its going to want to print a string
	#la $a0, DrawCardPrompt	        # load the address of label Prompt into $a0
	#syscall				# do the thing, print the 
	#j Quit

##############################################################################
# THIS IS THE CODE TO INITIALIZE THE CARDS AND THE CARD ARRAY.
# IT WORKS, DON'T TOUCH IT.
##############################################################################
	.data 
# First define all the card name strings:
# (byte data should be done last but we'll only lose 3 bytes at worst, so...)
AceOfDiamonds:		.asciiz	"Ace of Diamonds"
TwoOfDiamonds:		.asciiz	"Two of Diamonds"
ThreeOfDiamonds:	.asciiz	"Three of Diamonds"
FourOfDiamonds:		.asciiz	"Four of Diamonds"
FiveOfDiamonds:		.asciiz	"Five of Diamonds"
SixOfDiamonds:		.asciiz	"Six of Diamonds"
SevenOfDiamonds:	.asciiz	"Seven of Diamonds"
EightOfDiamonds:	.asciiz	"Eight of Diamonds"
NineOfDiamonds:		.asciiz	"Nine of Diamonds"
TenOfDiamonds:		.asciiz	"Ten of Diamonds"
JackOfDiamonds:		.asciiz	"Jack of Diamonds"
QueenOfDiamonds:	.asciiz	"Queen of Diamonds"
KingOfDiamonds:		.asciiz	"King of Diamonds"
AceOfClubs:		.asciiz	"Ace of Clubs"
TwoOfClubs:		.asciiz	"Two of Clubs"
ThreeOfClubs:		.asciiz	"Three of Clubs"
FourOfClubs:		.asciiz	"Four of Clubs"
FiveOfClubs:		.asciiz	"Five of Clubs"
SixOfClubs:		.asciiz	"Six of Clubs"
SevenOfClubs:		.asciiz	"Seven of Clubs"
EightOfClubs:		.asciiz	"Eight of Clubs"
NineOfClubs:		.asciiz	"Nine of Clubs"
TenOfClubs:		.asciiz	"Ten of Clubs"
JackOfClubs:		.asciiz	"Jack of Clubs"
QueenOfClubs:		.asciiz	"Queen of Clubs"
KingOfClubs:		.asciiz	"King of Clubs"
AceOfHearts:		.asciiz	"Ace of Hearts"
TwoOfHearts:		.asciiz	"Two of Hearts"
ThreeOfHearts:		.asciiz	"Three of Hearts"
FourOfHearts:		.asciiz	"Four of Hearts"
FiveOfHearts:		.asciiz	"Five of Hearts"
SixOfHearts:		.asciiz	"Six of Hearts"
SevenOfHearts:		.asciiz	"Seven of Hearts"
EightOfHearts:		.asciiz	"Eight of Hearts"
NineOfHearts:		.asciiz	"Nine of Hearts"
TenOfHearts:		.asciiz	"Ten of Hearts"
JackOfHearts:		.asciiz	"Jack of Hearts"
QueenOfHearts:		.asciiz	"Queen of Hearts"
KingOfHearts:		.asciiz	"King of Hearts"
AceOfSpades:		.asciiz	"Ace of Spades"
TwoOfSpades:		.asciiz	"Two of Spades"
ThreeOfSpades:		.asciiz	"Three of Spades"
FourOfSpades:		.asciiz	"Four of Spades"
FiveOfSpades:		.asciiz	"Five of Spades"
SixOfSpades:		.asciiz	"Six of Spades"
SevenOfSpades:		.asciiz	"Seven of Spades"
EightOfSpades:		.asciiz	"Eight of Spades"
NineOfSpades:		.asciiz	"Nine of Spades"
TenOfSpades:		.asciiz	"Ten of Spades"
JackOfSpades:		.asciiz	"Jack of Spades"
QueenOfSpades:		.asciiz	"Queen of Spades"
KingOfSpades:		.asciiz	"King of Spades"
Cards:			.word	0:52			# space for 52 pointers

	.text
# This subroutine should be called by your main routine to initialize the Cards
# array.  It's not pretty but after it runs, it should let you simply do a copy
# of the pointers into your Deck array whenever you need to reinitialize it.
# Call it with jal initCards.  No parameters and no returns
initCards:
	addiu	$sp, $sp, -8	# room to save $t0 and $t1
	sw	$t0, 0($sp)
	sw	$t1, 4($sp)
	la 	$t0, Cards
	la 	$t1, AceOfDiamonds
	sw 	$t1, 0($t0)
	la 	$t1, TwoOfDiamonds
	sw 	$t1, 4($t0)
	la 	$t1, ThreeOfDiamonds
	sw 	$t1, 8($t0)
	la 	$t1, FourOfDiamonds
	sw 	$t1, 12($t0)
	la 	$t1, FiveOfDiamonds
	sw 	$t1, 16($t0)
	la 	$t1, SixOfDiamonds
	sw 	$t1, 20($t0)
	la 	$t1, SevenOfDiamonds
	sw 	$t1, 24($t0)
	la 	$t1, EightOfDiamonds
	sw 	$t1, 28($t0)
	la 	$t1, NineOfDiamonds
	sw 	$t1, 32($t0)
	la 	$t1, TenOfDiamonds
	sw 	$t1, 36($t0)
	la 	$t1, JackOfDiamonds
	sw 	$t1, 40($t0)
	la 	$t1, QueenOfDiamonds
	sw 	$t1, 44($t0)
	la 	$t1, KingOfDiamonds
	sw 	$t1, 48($t0)
	la 	$t1, AceOfClubs
	sw 	$t1, 52($t0)
	la 	$t1, TwoOfClubs
	sw 	$t1, 56($t0)
	la 	$t1, ThreeOfClubs
	sw 	$t1, 60($t0)
	la 	$t1, FourOfClubs
	sw 	$t1, 64($t0)
	la 	$t1, FiveOfClubs
	sw 	$t1, 68($t0)
	la 	$t1, SixOfClubs
	sw 	$t1, 72($t0)
	la 	$t1, SevenOfClubs
	sw 	$t1, 76($t0)
	la 	$t1, EightOfClubs
	sw 	$t1, 80($t0)
	la 	$t1, NineOfClubs
	sw 	$t1, 84($t0)
	la 	$t1, TenOfClubs
	sw 	$t1, 88($t0)
	la 	$t1, JackOfClubs
	sw 	$t1, 92($t0)
	la 	$t1, QueenOfClubs
	sw 	$t1, 96($t0)
	la 	$t1, KingOfClubs
	sw 	$t1, 100($t0)
	la 	$t1, AceOfHearts
	sw 	$t1, 104($t0)
	la 	$t1, TwoOfHearts
	sw 	$t1, 108($t0)
	la 	$t1, ThreeOfHearts
	sw 	$t1, 112($t0)
	la 	$t1, FourOfHearts
	sw 	$t1, 116($t0)
	la 	$t1, FiveOfHearts
	sw 	$t1, 120($t0)
	la 	$t1, SixOfHearts
	sw 	$t1, 124($t0)
	la 	$t1, SevenOfHearts
	sw 	$t1, 128($t0)
	la 	$t1, EightOfHearts
	sw 	$t1, 132($t0)
	la 	$t1, NineOfHearts
	sw 	$t1, 136($t0)
	la 	$t1, TenOfHearts
	sw 	$t1, 140($t0)
	la 	$t1, JackOfHearts
	sw 	$t1, 144($t0)
	la 	$t1, QueenOfHearts
	sw 	$t1, 148($t0)
	la 	$t1, KingOfHearts
	sw 	$t1, 152($t0)
	la 	$t1, AceOfSpades
	sw 	$t1, 156($t0)
	la 	$t1, TwoOfSpades
	sw 	$t1, 160($t0)
	la 	$t1, ThreeOfSpades
	sw 	$t1, 164($t0)
	la 	$t1, FourOfSpades
	sw 	$t1, 168($t0)
	la 	$t1, FiveOfSpades
	sw 	$t1, 172($t0)
	la 	$t1, SixOfSpades
	sw 	$t1, 176($t0)
	la 	$t1, SevenOfSpades
	sw 	$t1, 180($t0)
	la 	$t1, EightOfSpades
	sw 	$t1, 184($t0)
	la 	$t1, NineOfSpades
	sw 	$t1, 188($t0)
	la 	$t1, TenOfSpades
	sw 	$t1, 192($t0)
	la 	$t1, JackOfSpades
	sw 	$t1, 196($t0)
	la 	$t1, QueenOfSpades
	sw 	$t1, 200($t0)
	la 	$t1, KingOfSpades
	sw	$t1, 204($t0)
	lw	$t0, 0($sp)		# get the originals back
	lw	$t1, 4($sp)
	addiu	$sp, $sp, 8
	jr	$ra
