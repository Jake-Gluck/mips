.data
# constants
TempBuffer:  		.space 	2       # Space for temporary input storage, 2 bytes
Deck: 			.word 0:52 	# space for 52 pointers
Discard: 		.word 0:52 	# space for 52 pointers
CurrentDrawIndex: 	.word 51  	# Initially set to 51 after shuffling
Multiplier: 		.word 1073807359 # a sufficiently large prime
Seed: 			.word 0 	# delcared seed for linear congruence algorithm
Range:			.word 51	# Your shuffling subroutine needs to get a random number between 0 and 51
Newline: 		.asciiz 	"\n"
UserPrompt:		.asciiz 	"Enter s to shuffle, d to draw, or q to quit.\n"
ErrorMessage:		.asciiz 	"Invalid input.\n"
DrawEmptyMessage:	.asciiz		"Error, there are no more cards left to draw.\nEnter s to shuffle or q to quit.\n"
DrawCardMessage:	.asciiz 	"\n\nThe card you drew was the "
ShufflePrompt:		.asciiz		"\nShuffling cards...\nOne moment please.\n\n"
QuitPrompt:		.asciiz 	"\nGoodbye\n"
WelcomePrompt:		.asciiz		"Welcome to the card shuffling program!\n"
.text
.globl main

main:
li $v0, 4			# syscall to to print a string
la $a0, WelcomePrompt	        # load the address of label Prompt into $a0
syscall				# perform the syscall

jal initCards 			# initialize the Cards array
jal Shuffle			# shuffle the deck
j ValidateUserInput		# validate user input

ValidateUserInput:
# prompt user
li $v0, 4			# syscall to to print a string
la $a0, UserPrompt	        # load the address of label Prompt into $a0
syscall				# perform the syscall
                
# remove newline character from input        
li $v0, 8                	# syscall to read a string
la $a0, TempBuffer       	# load address of TempBuffer
li $a1, 2                	# read up to 1 character + null terminator
syscall                  	# perform the syscall, discard the newline (if there is one)

# save the first character from user input into $t0
la $a0, TempBuffer   		# load the address of TempBuffer into $a0
lb $t0, 0($a0)      		# load the first character from TempBuffer into $t0
    
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
beq $t0, $t1, Endit		# if user input is q, branch to Quit
        
li $t1, 81			# load ascii value for Q
beq $t0, $t1, Endit		# if user input is Q, branch to Quit
        
# if user input isn't valid
li $v0, 4			# syscall to print a string
la $a0, ErrorMessage	        # load the address of label ErrorMessage into $a0
syscall				# perform the syscall
	
j ValidateUserInput		# jump to ValidateUserInput to re-prompt user to enter valid input

Endit:
li $v0, 4			# syscall to to print a string
la $a0, QuitPrompt	        # load the address of label ShufflePrompt into $a0
syscall				# perform the syscall

li $v0, 10			# syscall for exit
syscall				# exit the program

GetRandom52:
# modified random number generator from project 1, only this time the seed is set by the system time instead of user input
li $v0, 30			# syscall for retrieve system time ($a0 = seconds since epoch)
syscall				# retrieve system time 	
sw $a0, Seed 			# stores seconds since epoch into Seed label
	
lw $t0, Seed			# loads Seed into $t0
lw $t1, Multiplier		# loads Multiplier into $t1
lw $t3, Range			# loads Range into $t3
	
# 1) multiply Seed by Multiplier
mul $t5, $t0, $t1		# multiply Seed by Multiplier and save the product in $t5
	
# 2) lo replaces the old seed
mflo $t0			# moves value from $lo to $t0, replacing seed with lo
sw $t0, Seed  			# store the lower 32 bits into Seed
	
# 3) hi is the raw random number
mfhi $t2			# moves value from $hi to $t2
	
# next range fit the raw random for output

# 1) divide the raw random by the precalculated range (unsigned division)
divu $t2, $t3			# unsigned divide $t2 by $t3, lo = quotient, hi = remainder
			
# 2) hi holds the ranged random after division
mfhi $t4			# sets $t4 = remainder of $t2 / $t3
	
# 3) add minimum to the ranged random 
# the range is 0 - 51 so the minimum is 0, so no need to add 0 to $t4
	
#4) copy $t4 to $s0 so it can be used in other functions
move $s0, $t4			# $s0 = $t4
	
jr $ra				# return to the function that called GetRandom52

# delay loop, ShuffleLoop calls GetRandom52 fifty-two times in a loop. This loop happens very quickly and since GetRandom52 uses the $a0
# return from syscall 30  which returns the time in seconds since epoch as the seed to the random number generator, the result is that 
# the same number gets repeated instead of 52 random numbers. To fix this I added a delay, so now GetRandom52 is able to produce a series 
# of random numbers even in a loop
Delay:
li $t0, 85068     		# set the delay count to 85068
    
DelayLoop:
sub $t0, $t0, 1    		# decrement the counter by 1
bnez $t0, DelayLoop 		# if $t0 is still greater than 0, continue looping
jr $ra              		# return to the function that called DelayLoop

Shuffle:
li $v0, 4			# syscall to to print a string
la $a0, ShufflePrompt	        # load the address of label ShufflePrompt into $a0
syscall				# perform the syscall

# load the base addresses of Cards array and Deck array into $t0 and $t1
la $t0, Cards			# load the base address of Cards array to $t0
la $t1, Deck			# load the base address of Deck array to $t1
li $t2, 0			# reset $t2 to 0, the counter that controls the loop, it will increment at the end of each loop

# copy words from Cards array to Deck array
CopyLoop:
beq $t2, 52, ClearDiscard	# branch to ClearDiscard when counter($t2) = 52
lw $t3, 0($t0)			# load word from $t0(Cards) to $t3
sw $t3, 0($t1)			# copy data from $t3 to $t1(Deck)
addi $t0, $t0, 4		# increment to next card in Cards array
addi $t1, $t1, 4		# increment to next card in Deck array
addi $t2, $t2, 1		# increment the counter that controls the loop ($t2) by 1
j CopyLoop			# repeat this loop for all 52 cards

ClearDiscard:
# clear the discard array 
la $t0, Discard			# load address of Discard array to $t0
li $t2, 0			# reset $t2 to 0, the counter that controls the loop, it will increment at the end of each loop

ClearLoop:
beq $t2, 52, ShuffleDeck	# branch to ShuffleDeck when the counter($t2) = 52
sw $zero, 0($t0)		# copies 0 into offset(Discard), removing the card that was in that index of Discard array
addi $t0, $t0, 4		# increment to the next card in the Discard array
addi $t2, $t2, 1		# increment the counter that controls the loop ($t2) by 1
j ClearLoop			# repeat this loop for all 52 cards

# traverse Deck array in order, swap Deck[i] which is ($t2) with Deck[randomly generated number] which is ($t1)
ShuffleDeck:
li $t2, 0			# reset $t2 to 0, the counter that controls the loop, it will increment at the end of each loop

ShuffleLoop:
beq $t2, 52, ShuffleComplete	# branch to ShuffleComplete when the counter($t2) = 52

# save $t2 to stack to preserve it across function call GetRandom52, otherwise $t2 in ShuffleLoop gets overwritten by a value in GetRandom52
addiu $sp, $sp, -4         	# make space on stack
sw $t2, 0($sp)             	# save $t2 to stack

# generate random number and return it
jal GetRandom52			# jump and link to GetRandom52 to generate a random number between 0 and 51
jal Delay			# jump to Delay to add a delay between each loop so GetRandom52 will be able to generate random numbers
move $t1, $s0			# copy randomly generated number from $s0 to $t1

# restore $t2 from stack after GetRandom52
lw $t2, 0($sp)             # load $t2 back from stack
addiu $sp, $sp, 4          # restore stack pointer    
    
# calculate the offset for Deck[i] which is Deck[base address of Deck array + (i * 4)]
la $t0, Deck			# load base address of Deck array to $t0

# calculate byte offset and add it to Deck array base address
mul $t3, $t2, 4			# multiply $t2(counter aka [i]) by 4 bytes to get the byte offset, save to $t3
add $t4, $t0, $t3		# add byte offset($t3) to Deck array base address($t0) to get Deck[in-order index]
lw $t5 0($t4)			# copy Deck[i] from $t4 to $t5, 

# calculate the offset for Deck[randomly generated num] which is Deck[base addresss of Deck array + (randomly generated number * 4)]
mul $t3, $t1, 4			# multiply random num ($t1) by 4 bytes to get the byte offset, save to $t3
add $t6, $t0, $t3		# add byte offset ($t3) to Deck array base address ($t0) to get Deck[randomly generated number]
lw $t7, 0($t6)			# copy Deck[randomly generated number] from $t6 to $t7

# swap Deck[i] and Deck[random num]
sw $t7, 0($t4)         		# store Deck[random num] at Deck[i]
sw $t5, 0($t6)         		# store Deck[i] at Deck[random num]
addi $t2, $t2, 1		# increnent counter $t2
j ShuffleLoop			# jump to beginning of ShuffleLoop function to repeat this swap for every index in Deck array	

ShuffleComplete:
# reset CurrentDrawIndex to 51 and then jump to ValidateUserInput
li $t0, 51                     # load the value 51 into $t0
sw $t0, CurrentDrawIndex       # store the value 51 into CurrentDrawIndex
j ValidateUserInput            # jump to ValidateUserInput

DrawCard:
# load CurrentDrawIndex
lw $t0, CurrentDrawIndex  	# $t0 = CurrentDrawIndex

# check if Deck is empty(CurrentDrawIndex = 0)
beqz $t0, DrawEmpty		# if CurrentDrawIndex is 0, branch to DrawEmpty

# load the base addresses of the Deck and Discard arrays
la $t1, Deck			# load base address of Deck array into $t1
la $t2, Discard			# load base address of Discard array into $t2

# calculate the address of Deck[DrawIndex]
mul $t3, $t0, 4			# calculate byte offset for Deck[CurrentDrawIndex] = CurrentDrawIndex($t0) * 4, save in $t3
add $t3, $t1, $t3		# address of Deck[CurrentDrawIndex] = Deck array base address + byte offset, save to $t3

# calculate the address of Discard[51 - CurrentDrawIndex]
li $t4, 51			# load value 51 into $t4
sub $t4, $t4, $t0		# subtract CurrentDrawIndex($t0) from 51($t4) and save to $t4
mul $t4, $t4, 4 		# multiply $t4 by 4 bytes to get byte offset, save to $t4
add $t4, $t2, $t4		# add byte offset and base address of Discard array to get address of Discard[51-CurrentDrawIndex], save to $t4

# Load the drawn card from Deck into $v0
lw $v0, 0($t3)         # $t3 contains address of Deck[CurrentDrawIndex]

# Store the drawn card into the Discard array
sw $v0, 0($t4)         # Store the card (in $v0) at Discard[51 - CurrentDrawIndex


addi $t0, $t0, -1         	# decrement CurrentDrawIndex by 1
sw $t0, CurrentDrawIndex  	# store word back in CurrentDrawIndex

# print the DrawCardMessage
li $v0, 4			# syscall to to print a string
la $a0, DrawCardMessage	        # load the address of label DrawCardMessage into $a0
syscall				# perform the syscall

# print the card that was drawn from the deck
lw $a0, 0($t3)   		# load the address of the string($t3) into $a0
li $v0, 4			# syscall to to print a string
syscall             		# syscall to print the string in $a0

# print a Newline
li $v0, 4			# syscall to to print a string
la $a0, Newline	        	# load the address of label Newline into $a0
syscall				# perform the syscall

# return to ValidateUserInput
j ValidateUserInput		# jump to ValidateUserInput function

DrawEmpty:
# print message informing the user that the Deck to draw from is empty
li $v0, 4			# syscall to print a string
la $a0, DrawEmptyMessage	# load the address of label DrawEmptyMessage into $a0
syscall				# perform the syscall

# remove newline character from input        
li $v0, 8                	# syscall to read a string
la $a0, TempBuffer       	# load address of TempBuffer
li $a1, 2                	# read up to 1 character + null terminator
syscall                  	# perform the syscall, discard the newline (if there is one)

# save the first character from user input into $t0
la $a0, TempBuffer   		# load the address of TempBuffer into $a0
lb $t0, 0($a0)      		# load the first character from TempBuffer into $
    
# check if user input is valid (s, S, q, or Q)
li $t1, 115			# load ascii value for s
beq $t0, $t1, Shuffle		# if user input is s, branch to Shuffle
        
li $t1, 83			# load ascii value for S
beq $t0, $t1, Shuffle		# if user input is S, branch to Shuffle       
	
li $t1, 113			# load ascii value for q
beq $t0, $t1, Endit		# if user input is q, branch to Quit
        
li $t1, 81			# load ascii value for Q
beq $t0, $t1, Endit		# if user input is Q, branch to Quit
        
# if user input isn't valid
li $v0, 4			# syscall to print a string
la $a0, ErrorMessage	        # load the address of label ErrorMessage into $a0
syscall				# perform the syscall

j DrawEmpty			# loop back to DrawEmpty function to repeat user prompt

##############################################################################
# THIS IS THE CODE TO INITIALIZE THE CARDS AND THE CARD ARRAY.
# IT WORKS, DON'T TOUCH IT.
##############################################################################
.data
# First define all the card name strings:
# (byte data should be done last but we'll only lose 3 bytes at worst, so...)
AceOfDiamonds: .asciiz "Ace of Diamonds"
TwoOfDiamonds: .asciiz "Two of Diamonds"
ThreeOfDiamonds: .asciiz "Three of Diamonds"
FourOfDiamonds: .asciiz "Four of Diamonds"
FiveOfDiamonds: .asciiz "Five of Diamonds"
SixOfDiamonds: .asciiz "Six of Diamonds"
SevenOfDiamonds: .asciiz "Seven of Diamonds"
EightOfDiamonds: .asciiz "Eight of Diamonds"
NineOfDiamonds: .asciiz "Nine of Diamonds"
TenOfDiamonds: .asciiz "Ten of Diamonds"
JackOfDiamonds: .asciiz "Jack of Diamonds"
QueenOfDiamonds: .asciiz "Queen of Diamonds"
KingOfDiamonds: .asciiz "King of Diamonds"
AceOfClubs: .asciiz "Ace of Clubs"
TwoOfClubs: .asciiz "Two of Clubs"
ThreeOfClubs: .asciiz "Three of Clubs"
FourOfClubs: .asciiz "Four of Clubs"
FiveOfClubs: .asciiz "Five of Clubs"
SixOfClubs: .asciiz "Six of Clubs"
SevenOfClubs: .asciiz "Seven of Clubs"
EightOfClubs: .asciiz "Eight of Clubs"
NineOfClubs: .asciiz "Nine of Clubs"
TenOfClubs: .asciiz "Ten of Clubs"
JackOfClubs: .asciiz "Jack of Clubs"
QueenOfClubs: .asciiz "Queen of Clubs"
KingOfClubs: .asciiz "King of Clubs"
AceOfHearts: .asciiz "Ace of Hearts"
TwoOfHearts: .asciiz "Two of Hearts"
ThreeOfHearts: .asciiz "Three of Hearts"
FourOfHearts: .asciiz "Four of Hearts"
FiveOfHearts: .asciiz "Five of Hearts"
SixOfHearts: .asciiz "Six of Hearts"
SevenOfHearts: .asciiz "Seven of Hearts"
EightOfHearts: .asciiz "Eight of Hearts"
NineOfHearts: .asciiz "Nine of Hearts"
TenOfHearts: .asciiz "Ten of Hearts"
JackOfHearts: .asciiz "Jack of Hearts"
QueenOfHearts: .asciiz "Queen of Hearts"
KingOfHearts: .asciiz "King of Hearts"
AceOfSpades: .asciiz "Ace of Spades"
TwoOfSpades: .asciiz "Two of Spades"
ThreeOfSpades: .asciiz "Three of Spades"
FourOfSpades: .asciiz "Four of Spades"
FiveOfSpades: .asciiz "Five of Spades"
SixOfSpades: .asciiz "Six of Spades"
SevenOfSpades: .asciiz "Seven of Spades"
EightOfSpades: .asciiz "Eight of Spades"
NineOfSpades: .asciiz "Nine of Spades"
TenOfSpades: .asciiz "Ten of Spades"
JackOfSpades: .asciiz "Jack of Spades"
QueenOfSpades: .asciiz "Queen of Spades"
KingOfSpades: .asciiz "King of Spades"
Cards: .word 0:52 # space for 52 pointers
.text
# This subroutine should be called by your main routine to initialize the Cards
# array. It's not pretty but after it runs, it should let you simply do a copy
# of the pointers into your Deck array whenever you need to reinitialize it.
# Call it with jal initCards. No parameters and no returns
initCards:
addiu $sp, $sp, -8 # room to save $t0 and $t1
sw $t0, 0($sp)
sw $t1, 4($sp)
la $t0, Cards
la $t1, AceOfDiamonds
sw $t1, 0($t0)
la $t1, TwoOfDiamonds
sw $t1, 4($t0)
la $t1, ThreeOfDiamonds
sw $t1, 8($t0)
la $t1, FourOfDiamonds
sw $t1, 12($t0)
la $t1, FiveOfDiamonds
sw $t1, 16($t0)
la $t1, SixOfDiamonds
sw $t1, 20($t0)
la $t1, SevenOfDiamonds
sw $t1, 24($t0)
la $t1, EightOfDiamonds
sw $t1, 28($t0)
la $t1, NineOfDiamonds
sw $t1, 32($t0)
la $t1, TenOfDiamonds
sw $t1, 36($t0)
la $t1, JackOfDiamonds
sw $t1, 40($t0)
la $t1, QueenOfDiamonds
sw $t1, 44($t0)
la $t1, KingOfDiamonds
sw $t1, 48($t0)
la $t1, AceOfClubs
sw $t1, 52($t0)
la $t1, TwoOfClubs
sw $t1, 56($t0)
la $t1, ThreeOfClubs
sw $t1, 60($t0)
la $t1, FourOfClubs
sw $t1, 64($t0)
la $t1, FiveOfClubs
sw $t1, 68($t0)
la $t1, SixOfClubs
sw $t1, 72($t0)
la $t1, SevenOfClubs
sw $t1, 76($t0)
la $t1, EightOfClubs
sw $t1, 80($t0)
la $t1, NineOfClubs
sw $t1, 84($t0)
la $t1, TenOfClubs
sw $t1, 88($t0)
la $t1, JackOfClubs
sw $t1, 92($t0)
la $t1, QueenOfClubs
sw $t1, 96($t0)
la $t1, KingOfClubs
sw $t1, 100($t0)
la $t1, AceOfHearts
sw $t1, 104($t0)
la $t1, TwoOfHearts
sw $t1, 108($t0)
la $t1, ThreeOfHearts
sw $t1, 112($t0)
la $t1, FourOfHearts
sw $t1, 116($t0)
la $t1, FiveOfHearts
sw $t1, 120($t0)
la $t1, SixOfHearts
sw $t1, 124($t0)
la $t1, SevenOfHearts
sw $t1, 128($t0)
la $t1, EightOfHearts
sw $t1, 132($t0)
la $t1, NineOfHearts
sw $t1, 136($t0)
la $t1, TenOfHearts
sw $t1, 140($t0)
la $t1, JackOfHearts
sw $t1, 144($t0)
la $t1, QueenOfHearts
sw $t1, 148($t0)
la $t1, KingOfHearts
sw $t1, 152($t0)
la $t1, AceOfSpades
sw $t1, 156($t0)
la $t1, TwoOfSpades
sw $t1, 160($t0)
la $t1, ThreeOfSpades
sw $t1, 164($t0)
la $t1, FourOfSpades
sw $t1, 168($t0)
la $t1, FiveOfSpades
sw $t1, 172($t0)
la $t1, SixOfSpades
sw $t1, 176($t0)
la $t1, SevenOfSpades
sw $t1, 180($t0)
la $t1, EightOfSpades
sw $t1, 184($t0)
la $t1, NineOfSpades
sw $t1, 188($t0)
la $t1, TenOfSpades
sw $t1, 192($t0)
la $t1, JackOfSpades
sw $t1, 196($t0)
la $t1, QueenOfSpades
sw $t1, 200($t0)
la $t1, KingOfSpades
sw $t1, 204($t0)
lw $t0, 0($sp) # get the originals back
lw $t1, 4($sp)
addiu $sp, $sp, 8
jr $ra