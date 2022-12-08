.data
	coffee:		.word	2
	milk:		.word 	2
	chocolate:	.word	1
	sugar: 		.word	2
	actionOptions:	.asciiz	"\n[1]: Get a coffee \n[2]: Refuel storage \n[3]: Display amount by type \nSelect an option: "
	
	drinkOptions:	.asciiz	"\n[1]: Pure coffee \n[2]: Coffee with milk \n[3]: Mochaccino \nSelect the drink: "
	drinkSizes:	.asciiz "\n[1]: Small \n[2]: Big \nSelect size: "
	isThereSugar: 	.asciiz "\n[1] Yes \n[2] No \nDo you want sugar? "
	refuelOptions: 	.asciiz "\nRefuel"
	
	errorMessage:		.asciiz "\nAn invalid type was selected, the system is restarting\n"
	err_ThereIsntSugar: 	.asciiz "\nInsufficient sugar, please refill \n"
	err_ThereIsntCoffee:	.asciiz "\nInsufficient coffee, please refill \n"
	err_ThereIsntMilk:	.asciiz "\nInsufficient milk, please refill \n"
	err_ThereIsntChocolate: .asciiz "\nInsufficient chocolate, please refill \n"
	
	sugar_word:	.asciiz "\nStorage: \nSugar: "
	coffee_word:	.asciiz "\nCoffee: "
	milk_word:	.asciiz "\nMilk: "
	chocolate_word: .asciiz "\nChocolate: "
	breakline_word: .asciiz "\n"
.text
main:
	jal	GET_ACTION
	ble	$v0, 0, HANDLE_ERROR
	bge	$v0, 4, HANDLE_ERROR
	# $v0 ACTION TYPE ID
	beq 	$v0, 1, GET_COFFEE
	beq	$v0, 2, REFUEL
	beq	$v0, 3, DISPLAY_AMOUNT
	
	BACK_GET_COFFEE_OR_REFUEL:
	j main

GET_ACTION:
	li	$v0, 4	
	la 	$a0, actionOptions
	syscall
	
	# Select an option input
	li	$v0, 5
	syscall
	jr	$ra

GET_COFFEE:
	# $t0 drink_type
	# $t1 drink_size
	# $t2 sugar

	# Select drink_type input
	li	$v0, 4
	la	$a0, drinkOptions
	syscall

	li	$v0, 5
	syscall	
	ble	$v0, 0, HANDLE_ERROR
	bge	$v0, 4, HANDLE_ERROR
	move	$t0, $v0

	# select drink_size input
	li	$v0, 4
	la 	$a0, drinkSizes
	syscall
	
	li	$v0, 5
	syscall
	ble	$v0, 0, HANDLE_ERROR
	bge	$v0, 3, HANDLE_ERROR
	move	$t1, $v0
	
	# select sugar input
	li	$v0, 4
	la	$a0, isThereSugar
	syscall
	
	li	$v0, 5
	syscall
	ble	$v0, 0, HANDLE_ERROR
	bge	$v0, 3, HANDLE_ERROR
	move 	$t2, $v0
	
	move	$a0, $t0 # $t0 drink_type
	move	$a1, $t1 # $t1 drink_size
	move	$a2, $t2 # $t2 sugar
	
	CHECK_SUGAR_AVAILABILITY:
	beq	$a2, 2, CHECK_DRINK_TYPE_AVAILABILITY # if don't want sugar
	
	la	$t0, sugar
	lw	$t0, ($t0) 	# $t0 storage - sugar amount
	
	mul	$s3, $a2, $a1  # $t1 - needed sugar amount

	blt	$t0, $s3, HANDLE_THERE_ISNT_SUGAR_ERROR

	CHECK_DRINK_TYPE_AVAILABILITY:
	la	$s0, coffee
	la	$s1, milk
	la	$s2, chocolate
	lw	$s0, ($s0)	# coffee
	lw	$s1, ($s1)	# milk
	lw	$s2, ($s2)	# chocolate
				# sugar $s3
	CHECK_PURE_COFFEE_AVAIBILITY:
	blt	$s0, $a1, HANDLE_THERE_ISNT_COFFEE_ERROR
	beq	$a0, 1, PREPARE

	CHECK_MILK_AVAIBILITY:
	blt	$s1, $a1, HANDLE_THERE_ISNT_MILK_ERROR
	beq	$a0, 2, PREPARE
	
	CHECK_CHOCOLATE_AVAIBILITY:
	blt	$s2, $a1, HANDLE_THERE_ISNT_CHOCOLATE_ERROR
	beq	$a0, 3, PREPARE

	PREPARE:
	beq	$a2, 2, PREPARECOFFEE # if don't want sugar
	# sugar === $s3
	la	$t0, sugar
	sub 	$s3, $s3, $a1
	sw	$s3, ($t0)

	PREPARECOFFEE:
	la	$t0, coffee
	sub	$s0, $s0, $a1
	sw	$s0, ($t0)
	beq	$a0, 1, PREPARE_OUT
	PREPAREMILK:
	la	$t0, milk
	sub	$s1, $s1, $a1
	sw	$s1, ($t0)
	beq	$a0, 2, PREPARE_OUT
	PREPARECHOCOLATE:
	la	$t0, chocolate
	sub	$s2, $s2, $a1
	sw	$s2, ($t0)
	beq	$a0, 3, PREPARE_OUT 
	
	PREPARE_OUT:
	
	j BACK_GET_COFFEE_OR_REFUEL
REFUEL:
	li	$v0, 4	
	la 	$a0, refuelOptions
	syscall
	j BACK_GET_COFFEE_OR_REFUEL

HANDLE_ERROR:
	li	$v0, 4
	la	$a0, errorMessage
	syscall
	j 	main

HANDLE_THERE_ISNT_SUGAR_ERROR:
	li	$v0, 4
	la 	$a0, err_ThereIsntSugar
	syscall
	j BACK_GET_COFFEE_OR_REFUEL

HANDLE_THERE_ISNT_COFFEE_ERROR:
	li	$v0, 4
	la	$a0, err_ThereIsntCoffee
	syscall
	j BACK_GET_COFFEE_OR_REFUEL

HANDLE_THERE_ISNT_MILK_ERROR:
	li	$v0, 4
	la 	$a0, err_ThereIsntMilk
	syscall
	j BACK_GET_COFFEE_OR_REFUEL
HANDLE_THERE_ISNT_CHOCOLATE_ERROR:
	li	$v0, 4
	la	$a0, err_ThereIsntChocolate
	syscall
	j BACK_GET_COFFEE_OR_REFUEL
DISPLAY_AMOUNT:
	la	$s0, sugar
	la	$s1, coffee
	la	$s2, milk
	la	$s3, chocolate
	lw	$s0, ($s0)	# sugar
	lw	$s1, ($s1)	# coffee
	lw	$s2, ($s2)	# milk
	lw	$s3, ($s3)	# chocolate
	
	li	$v0, 4
	la 	$a0, sugar_word
	syscall
	li	$v0, 1
	move	$a0, $s0
	syscall
	
	li	$v0, 4
	la 	$a0, coffee_word
	syscall
	li	$v0, 1
	move	$a0, $s1
	syscall
	
	li	$v0, 4
	la	$a0, milk_word
	syscall
	li	$v0, 1
	move	$a0, $s2
	syscall
	
	li	$v0, 4
	la	$a0, chocolate_word
	syscall
	li	$v0, 1
	move	$a0, $s3
	syscall
	
	li	$v0, 4
	la	$a0, breakline_word
	syscall
	
	j BACK_GET_COFFEE_OR_REFUEL
