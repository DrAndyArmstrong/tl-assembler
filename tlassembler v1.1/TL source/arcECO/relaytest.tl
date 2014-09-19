// arcECO Relay Test 21 March 2011 Andrew Armstrong
move	cx, 0x55
move	cy, 0x24
:test		
move 	m1, 0x00	//Board
move 	m2, 0x06	//Device
move	m3, 0x00	//Register High
move	m4, 0x02	//Register Low	(BANK)
set	cy		//Value to Write to register

sleep	20

move 	m1, 0x00	
move 	m2, 0x06	
move	m3, 0x00
move	m4, 0x02
set	cx

sleep 	20

jump 	test		//Lets do the whole thing again
