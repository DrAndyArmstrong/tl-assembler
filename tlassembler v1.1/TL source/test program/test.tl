// Thinloom Sample Source File
// Arcsembler (c) Archonix 2010
//	Command List
//
//	Convention is RegX = Register ValX = Value (e.g. 0xFF)
// 	User registers are 	m1-m4(IO address) ms,ls(WORD results)
//				ax,ay to gx,gy (general purpose registers)
//
//	:XXXXX	 		Label = All "jmps" are to a label
//	move	Reg,Val		Move = Moves the Value into the Register
//	copy 	RegA,RegB	Copy = Copies RegB value into RegA
//	inc* 	Reg		Increment = Register Value + 1 
//	dec* 	Reg		Decrement = Register Value - 1 
//	add 	RegA,RegB,RegC	Add = RegA = RegB + RegC
//	sub 	RegA,RegB,RegC	Subtract = RegA = RegB - RegC
//	je  	RegA,RegB	Short Jump (if equal) = proceeds to next line if true (must be jump or call) or skips it if false
//	jl  	RegA,RegB	Short Jump (if less) = proceeds to next line if true (must be jump or call) or skips it if false
//	jg  	RegA,RegB	Short Jump (if greater) = proceeds to next line if true (must be jump or call) or skips it if false
//	jle 	RegA,RegB	Short Jump (if less or equal) = proceeds to next line if true (must be jump or call) or skips it if false
//	jge 	RegA,RegB	Short Jump (if greater or equal) = proceeds to next line if true (must be jump or call) or skips it if false
//	get* 	Reg		Get memory = Gets System VM into Reg, m1,m2,m3,m4 must contain boardID, DeviceID, regHI, regLO prior
//	set* 	Reg		Set memory = Sets System VM from Reg, m1,m2,m3,m4 must contain boardID, DeviceID, regHI, regLO prior
//	sleep 	Val		Sleep = lets system thread have control for Val cycles - use periodically or program will hang system
//	usleep 	Val		Microsloop = causes program execution to sleep for Val microseconds
//	jump	XXXXX		Jump = Jumps to a label - Always required immediately after a comparison
//	call	XXXXX		Call = Jumps to a label containing a subroutine and ends with a ret
//	return			Return = returns to the last instruction after the last cal -- Callstack is 16 calls Deep
//	nop			No Operation = cpu skips over this
//	push* 	Reg		Push = pushes a register value onto the stack - Stack is 16 Bytes deep
//	pop* 	Reg		Pop = pops a value from the stack into a register
//	mult	RegA,RegB	Multiply = Multiplies RegA with RegB and stores result in registers ms (MSB) and ls (LSB)
//	load*	Value		Loads Value to destination (as with SET) but increments M4 afterwards. Does not require a register
//	tohex	Reg		bcd 2 hex = Converts Value in Reg to Hex Representation
//	tobcd	Reg		hex 2 bcs = Converts Value in Reg to BCD Representation
//	and	RegA,RegB	Bitwise AND = Performs a bitwise AND of RegA and RegB, result in RegA
//	or	RegA,RegB	Bitwise	OR = Performs a bitwise OR of RegA and RegB, result in RegA
//	xor	RegA,RegB	Bitwise XOR = Performs a bitwise XOR of RegA and RegB, result in RegA
//	bls	RegA,Val	Bitwise Left Shift = Performs a bitwise Left Shift of RegA to Val shifts, result in RegA
//	brs	RegA,Val	Bitwise Right Shift = Performs a bitwise Right Shiftof RegA to Val shifts, result in RegA
//	dbg* 	Reg		Debug = prints contents of register to console for debugging
//	#inc	"FILENAME.TL"	Include = Includes another file into the listing. 
//	end			End = end program - usually placed at end of file before subroutines
//	* Note - these commands have a CSV shorthand e.g pop ax,bx,cx is expanded to pop ax; pop bx; pop cx;


jump	start	//Jump to start label so we do no execute what is in the #included files
#inc	"7seg.tl"

:start
call	initglyphs
move	cx,0x0F
move	dx,0x14

:loop
call	readseconds
call	displayseconds
sleep	0x01
jump	loop

:displayseconds
and	bx,cx		//Strip the MSN
add 	bx,bx,dx
move	m1,0x00	
move	m2,0x01
move	m3,0x00
copy	m4,bx
get	ax
dbg 	ax
call	writeled	//Expects value to write in AX
return

:readseconds
push	m1,m2,m3,m4
move	m1,0x00	
move	m2,0x02
move	m3,0x00
move	m4,0x04
get	bx
dbg 	bx
//tohex	bx
//dbg 	bx
pop	m4,m3,m2,m1
return




