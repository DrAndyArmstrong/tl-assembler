// TLvma (c) Archonix 2011
//	Command List
//
//	Convention is RegX = Register ValX = Value (e.g. 0xFF)
// 	User registers are 	m1-m4(IO address) ms,ls(WORD results)
//				ax,ay to gx,gy (general purpose registers)
//
//	:XXXXX	 		Label = All "jumps" are to a label
//	move	Reg,Val		Move = Moves the Value into the Register
//	copy 	RegA,RegB	Copy = Copies RegB value into RegA
//	inc* 	Reg		Increment = Register Value + 1 
//	dec* 	Reg		Decrement = Register Value - 1 
//	add 	RegA,RegB,RegC	Add = RegA = RegB + RegC
//	sub 	RegA,RegB,RegC	Subtract = RegA = RegB - RegC
//	==  	RegA,[RegB|Val]	Comparison (if equal) = proceeds to next line if true or skips it if false (Alt Mnemonic: jne)
//	<  	RegA,[RegB|Val]	Comparison (if less) = proceeds to next line if true or skips it if false (Alt Mnemonic: jge)
//	>  	RegA,[RegB|Val]	Comparison (if greater) = proceeds to next line if true or skips it if false (Alt Mnemonic: jle)
//	<= 	RegA,[RegB|Val]	Comparison (if less or equal) = proceeds to next line if true or skips it if false (Alt Mnemonic: jg)
//	>= 	RegA,[RegB|Val]	Comparison (if greater or equal) = proceeds to next line if true or skips it if false (Alt Mnemonic: jl)
//	!= 	RegA,[RegB|Val]	Comparison (if not equal) = proceeds to next line if true or skips it if false (Alt Mnemonic: je)
//	get* 	Reg		Get memory = Gets System VM into Reg, m1,m2,m3,m4 must contain boardID, DeviceID, regHI, regLO prior
//	set* 	Reg		Set memory = Sets System VM from Reg, m1,m2,m3,m4 must contain boardID, DeviceID, regHI, regLO prior
//	sleep 	Val		Sleep = lets system thread have control for Val cycles - use periodically or program will hang system
//	usleep 	Val		Microsleep = causes program execution to sleep for Val microseconds
//	jump	XXXXX		Jump = Jumps to a label - Often required immediately after a comparison
//	call	XXXXX		Call = Jumps to a label containing a subroutine and ends with a return
//	return			Return = returns to the next instruction after the last call
//	nop			No Operation = cpu skips over this
//	push* 	Reg		Push = pushes a register value onto the stack 
//	pop* 	Reg		Pop = pops a value from the stack into a register
//	mult	RegA,RegB	Multiply = Multiplies RegA with RegB and stores result in registers ms (MSB) and ls (LSB)
//	mod	RegA,RegB	Modulo = Divide RegA with RegB and stores remainder in registers ms (MSB) and ls (LSB)
//	div	RegA,RegB	Divide = Divide RegA with RegB and stores integer in registers ms (MSB) and ls (LSB)
//	load*	Value		Loads Value to destination (as with SET) but increments M4 afterwards. Does not require a register
//	tohex	Reg		bcd 2 hex = Converts Value in Reg to Hex Representation
//	tobcd	Reg		hex 2 bcs = Converts Value in Reg to BCD Representation
//	and	RegA,RegB	Bitwise AND = Performs a bitwise AND of RegA and RegB, result in RegA
//	or	RegA,RegB	Bitwise	OR = Performs a bitwise OR of RegA and RegB, result in RegA
//	xor	RegA,RegB	Bitwise XOR = Performs a bitwise XOR of RegA and RegB, result in RegA
//	bls	Reg,Val		Bitwise Left Shift = Performs a bitwise Left Shift of Reg to Val shifts, result in Reg
//	brs	Reg,Val		Bitwise Right Shift = Performs a bitwise Right Shiftof Reg to Val shifts, result in Reg
//	dbg* 	Reg		Debug = prints contents of register to console for debugging
//	#inc	"FILENAME.TL"	Include = Includes another file into the listing. 
//	end			End = end program - usually placed at end of file before subroutines
//
//
//	* Note - these commands have a expansion macro which automatically creates additional lines or a subroutine and places a call to it, potentially
//			adding unintentional program size. For more control an resuse you are advised to build your own subroutines
//			if placing similar calls throughout your program
//
//
//
// 	TL Virtual Machine Specification
//
//	Callstack Depth 	: 16 Calls
//	Stack 			: 16 Bytes
//	Local RAM Virtdevice	: 0xAA		(undocumented - not for general use)

