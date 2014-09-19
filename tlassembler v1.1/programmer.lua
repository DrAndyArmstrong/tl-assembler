#!/usr/bin/lua

--AA2011 Programmer for web-programming a Thinloom device over the internet.

local clock = os.clock
function sleep(n)  -- seconds
  local t0 = clock()
  while clock() - t0 <= n do end
end

socket = require("socket")

local tloutfile 	= arg[1] 
local tlIPaddress 	= arg[2]
local tlPort		= arg[3]
local tloptions		= arg[4]
local filelength	= 0

function readprogram(sourcefile)
	local file = io.open(sourcefile,"rb")   
	
	local line = file:read("*a")

	file:close()

	local data={}
	local i=2

    	for b in string.gfind(line, ".") do
		i = i + 1
        	data[i]=string.format("%02X", string.byte(b))
      	end


	local size = string.format("%04x",i-2)
	data[0] = tloptions		--Program options (bit 0=autostart)
	data[1] = string.sub(size,1,2)	--Size HiByte	
	data[2] = string.sub(size,3,4)	--Size LowByte

	filelength = i

	return data
end


function programunit()
	--MAIN CODE

	local dataarray = {}
	dataarray = readprogram(tloutfile)
	client = socket.connect(tlIPaddress, tlPort)

	if client ~= nil then
		client:settimeout(10)
		local line, err
		local buffer=""
		local ready=0


		--login Sequence
		while err == nil and ready == 0 do
			line, err = client:receive(1)
			if line ~= nil then
				buffer=buffer .. line
			end

			if string.find(buffer,"Login:") ~= nil then
				print(buffer)
				print("SEND")
				client:send("admin\r\n")
				client:send("XXX") --send padding
				buffer = ""
			end

			if string.find(buffer,"Password:") ~= nil then
				print(buffer)
				print("SEND")
				client:send("admin\r\n")
				buffer = ""
			end

			if string.find(buffer,">") ~= nil then
				print(buffer)
				ready=1
				client:send("z\n")
				client:settimeout(1)
				buffer = ""
			end
		end

		print "Login Completed"

		--main Sequence
		ready = 0
		local decreg = 0

		while err == nil and ready == 0 do
			line, err = client:receive(1)

			if line ~= nil then
				buffer=buffer .. line
			end

			if string.find(buffer,">") ~= nil then
				if decreg <= filelength then
					print(buffer)
					register = string.format("%04x",decreg)
					datastring = dataarray[decreg]
					local outstring = "w0000" .. register .. datastring .. "\r\n"
					print(outstring)
					--sleep(1)
					client:send(outstring)
				
					buffer = ""
				else
					buffer = ""
					client:send("?\n")
					ready = 1
				end
				decreg = decreg + 1
			end
		end

	err="Not Verifying"
		ready = 0
		local decreg = 0

		while err == nil and ready == 0 do
			line, err = client:receive(1)

			if line ~= nil then
				buffer=buffer .. line
			end

			if string.find(buffer,">") ~= nil then
				if decreg <= filelength then
					print(buffer)
					register = string.format("%04x",decreg)
					local outstring = "r0000" .. register ..  "\r\n"
					print(outstring)
					--sleep(1)
					client:send(outstring)
				
					buffer = ""
				else
					buffer = ""
					client:send("q\n")
					ready = 1
				end
				decreg = decreg + 1
			end
		end

		print(buffer)
		if err then 
			print(err)
		end

		client:close()
	else
		print("Timeout waiting for client")
	end

end

if tloutfile ~= nil then

	if tlIPaddress == nil then
		tlIPaddress = "192.168.0.104"
	end

	if tlPort == nil then
		tlPort = 23
	end

	if tloptions == nil then
		tloptions = "00"
	end

	print("Connecting to Thinloom on " .. tlIPaddress .. " port " .. tlPort)

	programunit()
else
	print("No compiled filename passed")
end
