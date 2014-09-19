// Writeled - 	sets the DATAIO output to the value passed in register ax
//		returns nothing	

:writeled
push	m1,m2,m3,m4
move	m1,0x00	
move	m2,0x04
move	m3,0x00
move	m4,0x00
set	ax
pop	m4,m3,m2,m1
return

// initglyphs- 	loads alphanumeric fonts into SRAM
:initglyphs
move	m1,0x00	//Board
move	m2,0x01	//Device SRAM 	--lowest reg is 14h
move	m3,0x00	//RegHi
move	m4,0x14

//Loading SRAM Variable Registers - These are Non Volatile

load	0x3F,0x30,0x9B,0xB9,0xB4,0xAD,0xAF,0x38,0xBF,0xBC,0xBE,0xA7,0x83,0xB3,0x8F,0x8E
return



