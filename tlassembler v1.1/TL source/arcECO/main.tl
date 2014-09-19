// arcECO 18 March 2011 Andrew Armstrong
// Allows The controller to operate an electric garage door
// Respects safety interlocks and limits
// Allows the web interface to also operate the door and check status

//Initialisation

move	ax, 0x02	//Command Register
move	ay, 0x00	//Status Register
move	by, 0x00	//Processing Register
move	cy, 0x00	//Relay Status Register
call	stopdoor
call 	updatestatus
call	clearcommand

// Main Execution Thread
:start
	call	readkeys	//Check for putton presses	ax
	call	readcommand	//Check for web access		bx

	==	ax, 0x00
	copy	ax, bx		//If no buttons pressed accept web command

	call	updatestatus	//Update the status
	call	relayupdate

	sleep	0x01		//Restore resources to system
jump 	start

#inc	"functions.tl"

:relayupdate			//Relay Update		
	==	dy, by
	return

	sleep	0x01		//Restore resources to system

	==	by, 0x01	//Relays can operate independantly
	call	opendoor	//So Need their own status register
	==	by, 0x02
	call	stopdoor
	==	by, 0x03
	call	closedoor
	==	by, 0x04	//Emergency safety open
	call	opendoor
	==	by, 0x05	//Open Limit (STOP)
	call	stopdoor
	==	by, 0x06	//Close Limit (STOP)
	call	stopdoor
	copy	dy, by

	sleep	0x01		//Restore resources to system
return

:updatestatus

	call	readsafety
	==	ey, 0x01	//Is safety broken?
	call	checkclosing

	==	ax, 0x00
	return

	==	ax, ay		//Check if there is a new command
	return

	copy	ay, ax		//Update the command register
	copy	by, ay

	call	writestatus	//Write Status For Web Page
return

:checkclosing
	==	ay, 0x03	//If we are closing
	move	ax, 0x04	//Apply safety trigger
return













