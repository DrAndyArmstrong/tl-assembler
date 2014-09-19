//ArcECO
:readsafety
	push 	ex
	push 	fx
	push 	dx

	move	m1, 0x00			//Read Keypress modifies m1-m4, ex returns ax
	move	m2, 0x04
	move	m3, 0x00
	move	m4, 0x00
	get	ex

	move	ey, 0x00
	move	dx, 0x40
	copy	fx, ex
	and	fx, dx
	==	fx, dx; move	ey, 0x01	//Safety Limit (EMERGENCY OPEN) Inverse

	sleep	0x01		//Restore resources to system

	pop 	dx
	pop 	fx
	pop 	ex

return

:readkeys
	push 	ex
	push 	fx
	push 	dx

	move	m1, 0x00			//Read Keypress modifies m1-m4, ex returns ax
	move	m2, 0x04
	move	m3, 0x00
	move	m4, 0x00
	get	ex

	move	ax, 0xFF
	dbg	ex
	sub	ex, ax, ex			//Invert ex
	move	ax, 0x00

	move	dx, 0x20			//Order is important here because its bitwise
	copy	fx, ex				//Therefore STOP outranks open outranks close
	and	fx, dx				//Safety is paramount in this layout
	==	fx, dx; move	ax, 0x03	//Close

	move	dx, 0x04
	copy	fx, ex
	and	fx, dx
	==	fx, dx; move	ax, 0x01	//Open Button

	move	dx, 0x02
	copy	fx, ex
	and	fx, dx
	==	fx, dx; move	ax, 0x02	//STOP

	sleep	0x01		//Restore resources to system

	move	dx, 0x80
	copy	fx, ex
	and	fx, dx
	==	fx, dx; move	ax, 0x05	//Open Limit (STOP)

	move	dx, 0x10
	copy	fx, ex
	and	fx, dx
	==	fx, dx; move	ax, 0x06	//Close Limit (STOP)

	sleep	0x01		//Restore resources to system

	pop 	dx
	pop 	fx
	pop 	ex
return

:clearleds
	move 	gx, 0x00
	move 	gy, 0x00
	call setleds
	move 	gx, 0x01
	move 	gy, 0x00
	call setleds
	move 	gx, 0x03
	move 	gy, 0x00
	call setleds
return

:setleds
	move 	m1, 0x00	
	move 	m2, 0x06	
	move	m3, 0x00
	copy	m4, gx
	set	gy
return

:setrelay		
	move 	m1, 0x00	
	move 	m2, 0x06	
	move	m3, 0x00
	move	m4, 0x02
	set	cy
return

:poweron
	push	ax
	move	ax, 0xF0
	and	cy, ax
	move	ax, 0x05
	or	cy, ax
	pop	ax
	call 	setrelay
return

:poweroff
	push	ax
	move	ax, 0xF0
	and	cy, ax
	move	ax, 0x04
	or	cy, ax
	pop	ax
	call 	setrelay
return

:relayup
	push	ax
	move	ax, 0x0F
	and	cy, ax
	move	ax, 0x20
	or	cy, ax
	pop	ax
	call 	setrelay
return

:relaydown
	push	ax
	move	ax, 0x0F
	and	cy, ax
	move	ax, 0x50
	or	cy, ax
	pop	ax
	call 	setrelay
return

:opendoor
	call	poweroff
	sleep	25
	call	relayup
	sleep	25
	call	poweron
	sleep	25
	call 	clearleds	//Update LEDS
	move	gx,0x00		//Update LEDS
	move	gy,0x01
	call 	setleds
	sleep	1
return

:stopdoor
	call	poweroff
	call 	clearleds	//Update LEDS
	move 	gx, 0x03
	move 	gy, 0x50
	call 	setleds
	sleep	1
return

:closedoor
	call	poweroff
	sleep	25
	call	relaydown
	sleep	25
	call	poweron
	sleep	25
	call 	clearleds	//Update LEDS
	move	gx,0x01		//Update LEDS
	move	gy,0x40
	call 	setleds
	sleep	1
return

:writestatus
	move	m1, 0x00	//Writes to BYTE 1 of SRAM the status 
	move	m2, 0x01
	move	m3, 0x00
	move	m4, 0x16
	set	ay
return

:readcommand
	move	m1, 0x00	//Reads to BYTE 0 of SRAM the command
	move	m2, 0x01
	move	m3, 0x00
	move	m4, 0x15
	get	bx
	call	clearcommand
return

:clearcommand
	push	ax
	move	ax, 0x00
	move	m1, 0x00	//Clears BYTE 0 of SRAM to 0x00
	move	m2, 0x01
	move	m3, 0x00
	move	m4, 0x15
	set	ax
	pop 	ax
return








