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


