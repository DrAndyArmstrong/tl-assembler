#!/usr/bin/lua
-- Arcsembler (c) Archonix 2010 Thinloom Assembler v1.0
-- Andrew Armstrong - Initial Revision
-- Arcsembler (c) Archonix 2011 Thinloom Assembler v1.1
-- Andrew Armstrong 	- original jumps replaced with conditional codes == >= etc
--			- macro function to allow certain shorthands implemented


local tlsourcefile 	= arg[1] 
local tloutfile 	= arg[2]
local sourcepath 	= ""  
local rawsource={}						--Cleaned Source Array
local linenumbers={}						--Original Line numbers for error messages

function paramcount(data, ourparams, delimeter)
	local ourdata = data
	local parametercount = 0
	if delimeter == nil then
		delimeter = ","
	end
	if string.sub(data,1,2) ~= "//" then
		while (ourdata) do
			local location = string.find(ourdata, delimeter)
			if location ~= nil then
				parametercount = parametercount + 1
				ourparams[parametercount] = string.sub(ourdata, 1, location -1)
				ourdata = string.sub(ourdata, location + 1)
			else
				if ourdata ~= "" then
					parametercount = parametercount + 1
					ourparams[parametercount] = ourdata
				end
				ourdata = nil
			end
		end
	else
		parametercount=nil
	end
	return parametercount
end

function clean(line)						--Removes whitespaces and Comments
	local commentpos = string.find(line,"//")
	if commentpos == 1 then return nil end
	if commentpos ~= nil then line = string.sub(line,1,commentpos-1) end
	if line == "" then return nil end			--Remove blank line

	local n = 1
	while true do
		while true do -- removes spaces
			local _, ne, np = line:find("^[^%s%%]*()%s*", n)
			n = np
			if np - 1 ~= ne then line = line:sub(1, np - 1) .. line:sub(ne + 1)
			else break end
		end
		local m = line:match("%%(.?)", n) -- skip magic chars
		if m == "b" then n = n + 4
		elseif m then n = n + 2
		else break end
	end
	return line
end

local CSVcommands = {"load","pop","push","dbg","inc","dec","get","set"}
function checkCSV(parameter)
	for i,v in ipairs(CSVcommands) do
		if string.sub(parameter,0,string.len(v))==v then
			return v
		end
	end
	return nil
end

function readprogram(sourcefile, processedsource, linenums)
	local file = nil
	local linecount = 0

	if sourcepath ~= "" then
		file = io.open(sourcepath .. sourcefile,"r")   
	end

	if file == nil then 
		print("File not found, trying " .. sourcefile)
		file = io.open(sourcefile,"r")   
	end

	assert(file, "Filename " .. sourcefile .. " does not exist in current or source folders.", 0)

	if processedsource[0] == nil then
		processedsource[0] = 0 			--Element 0 contains the counter for the array
	end

	local tinputline = file:read("*l")	
	local autosubs = 0				--Macro Automatically Generates Subroutines	
	local autosubstring = {}
	local lastline = ""

	while (tinputline ~= nil) do

		local statements = {}
		local inputstatements = paramcount(tinputline, statements, ";")

		linecount = linecount + 1

		for j,line in ipairs(statements) do
			line=clean(line)
			if line ~= nil then
				local CSVparam = checkCSV(line)
				local loadparamcount = 0
				local loadparams={}
				if CSVparam ~= nil then
					loadparamcount = paramcount(string.sub(line,string.len(CSVparam)+1), loadparams)
				end

				if string.sub(line,0,4)=="#inc" then
					readprogram(string.sub(line,6,-2), processedsource, linenums)
				elseif	loadparamcount > 1 then	--Preprocesses multiparameter loads into several
					if checkcompares(lastline) == true then --If following a jump need to create subroutines
						autosubs = autosubs + 1
						autosubstring[autosubs]={}
						for i,v in ipairs(loadparams) do
							autosubstring[autosubs][i]=CSVparam .. v
							autosubstring[autosubs]["line"]=linecount
						end
						processedsource[0] = processedsource[0] + 1
						processedsource[processedsource[0]] = "callautosub" ..autosubs
						linenums[processedsource[0]] = sourcefile .. " line " .. linecount .. " (" .. line .. ") ->"
					else
						for i,v in ipairs(loadparams) do
							processedsource[0] = processedsource[0] + 1
							processedsource[processedsource[0]] = CSVparam .. v
						end
						linenums[processedsource[0]] = sourcefile .. " line " .. linecount
					end
				else
					processedsource[0] = processedsource[0] + 1
					processedsource[processedsource[0]] = line	--Store the line data
					linenums[processedsource[0]] = sourcefile .. " line " .. linecount
				end

				if line ~= "" and string.sub(line,1,2) ~= "//" then
					lastline = line
				end
			end
		end

		tinputline = file:read("*l")
	end


	if autosubs > 0 then
		local outnames = ""
		-- Sub to add automatic subroutines, a little messy

		processedsource[0] = processedsource[0] + 1
		processedsource[processedsource[0]] = "end"
		linecount = linecount + 1
		linenums[processedsource[0]] = sourcefile .. " line " .. linecount
		for i,v in ipairs(autosubstring) do --Insert Automatic Macro Labels
			processedsource[0] = processedsource[0] + 1
			processedsource[processedsource[0]] = ":autosub" .. i
			if i > 1 then
				outnames = outnames .. " "
			end
			linenums[processedsource[0]] = sourcefile .. " line " .. v["line"]
			outnames = outnames .. "{"
			for j,k in ipairs(v) do
				if j == 1 then
					outnames = outnames .. k
				else
					outnames = outnames .. "," .. k
				end
				processedsource[0] = processedsource[0] + 1
				processedsource[processedsource[0]] = k
				linenums[processedsource[0]] = sourcefile .. " line " .. v["line"]
			end	
			outnames = outnames .. "}"
			processedsource[0] = processedsource[0] + 1
			processedsource[processedsource[0]] = "return"
			linenums[processedsource[0]] = sourcefile .. " line " .. v["line"]
		end

		print(autosubs .. " automatically generated subroutines added (" .. outnames.. ")")	
	end

	file:close()
end

function subregisters(instype, parameter)
	if instype == 0x01 or instype == 0x11 or instype == 0x15 then --label
		return parameter
	end

	if parameter == "m1" then return 0x00 end
	if parameter == "m2" then return 0x01 end
	if parameter == "m3" then return 0x02 end
	if parameter == "m4" then return 0x03 end
	if parameter == "ms" then return 0x04 end
	if parameter == "ls" then return 0x05 end
	if parameter == "ax" then return 0x06 end
	if parameter == "ay" then return 0x07 end
	if parameter == "bx" then return 0x08 end
	if parameter == "by" then return 0x09 end
	if parameter == "cx" then return 0x0A end
	if parameter == "cy" then return 0x0B end
	if parameter == "dx" then return 0x0C end
	if parameter == "dy" then return 0x0D end
	if parameter == "ex" then return 0x0E end
	if parameter == "ey" then return 0x0F end
	if parameter == "fx" then return 0x10 end
	if parameter == "fy" then return 0x11 end
	if parameter == "gx" then return 0x12 end
	if parameter == "gy" then return 0x13 end

	local numpar = tonumber(parameter)
	if numpar == "" or numpar == nil then
		return nil
	else
		return tonumber(parameter)
	end
end

function parseinstruction(instruction, data, ourparams, paramexpected)
	ourparams[0] = instruction

	local parametercount = paramcount(data,ourparams)

	if parametercount ~= paramexpected then
		return(nil)
	else
		return(true)
	end
end

function debug(string)
	--print(string)
end

function checkisval(commandstring, position)
	local parmtable = fromCSV(commandstring)

	if parmtable[position] == nil then
		return false
	end

	if tonumber(parmtable[position]) ~= nil then
		return true
	end

	return false
end

function checkcompares(commandstring)				--checks if comparisons as these have jumps and system added parameters
	if string.find(commandstring, '(==)') or		--this code checks if second parameter is register or value
		string.find(commandstring, '(!=)') or		--we could use a pattern library, but lets keep the code native
		string.find(commandstring, '(<=)') or		
		string.find(commandstring, '(>=)') or		
		string.find(commandstring, '(<)') or		
		string.find(commandstring, '(>)') then
		return true
	end
	return false
end

function checkjumps(commandstring)				
	if string.find(commandstring, '(call)') or		
		string.find(commandstring, '(:)') or
		string.find(commandstring, '(jump)') then
		return true
	end
	return false
end

function macrocheck(commandstring, nextcommand)
	commandstring = string.gsub(commandstring, "jne", "==", 1)
	commandstring = string.gsub(commandstring, "jge", "<", 1)
	commandstring = string.gsub(commandstring, "jle", ">", 1)
	commandstring = string.gsub(commandstring, "jg",  "<=", 1)
	commandstring = string.gsub(commandstring, "jl",  ">=", 1)
	commandstring = string.gsub(commandstring, "je",  "!=", 1)

	if checkjumps(commandstring) == true then	--Jump instructions occupy a WORD and not just a byte, so adding an instruction
		commandstring = commandstring .. ",0x00"
	end

	if checkcompares(commandstring) == true then
		if checkisval(commandstring, 2) == true then	--Check if second parameter is a value (rather than a register)
			commandstring = "v" .. commandstring	--Substitutes a v onto the front of the mnemonic for its Value based equalivent
		end

		if nextcommand ~= nil then
			local nextcodelength = DEC_HEX(getopcodelen(nextcommand))
			if string.len(nextcodelength) == 1 then
				nextcodelength = "0x0" .. nextcodelength
			else
				nextcodelength = "0x" .. nextcodelength
			end
			commandstring = commandstring .. "," .. nextcodelength
		end
	end

	return commandstring
end

local instructions = {	[":"] 		= {0x01, 2},	--Opcode and Number of 1 byte parameters
			["move"] 	= {0x02, 2},
			["copy"] 	= {0x03, 2},
			["inc"] 	= {0x04, 1},
			["dec"] 	= {0x05, 1},
			["add"] 	= {0x06, 3},
			["sub"] 	= {0x07, 3},
			["!="] 		= {0x08, 3},
			[">="] 		= {0x09, 3},
			["<="] 		= {0x0A, 3},
			[">"] 		= {0x0B, 3},
			["<"]	 	= {0x0C, 3},
			["get"] 	= {0x0D, 1},
			["set"] 	= {0x0E, 1},
			["sleep"] 	= {0x0F, 1},
			["usleep"] 	= {0x10, 1},
			["jump"] 	= {0x11, 2},	--SPECIAL WORD LENGTH (these have instruction specific code in this file)
			["nop"] 	= {0x12, 0},
			["push"] 	= {0x13, 1},
			["pop"] 	= {0x14, 1},
			["call"] 	= {0x15, 2},	--SPECIAL WORD LENGTH (these have instruction specific code in this file)
			["return"] 	= {0x16, 0},
			["mult"] 	= {0x17, 2},
			["load"] 	= {0x18, 1},
			["dbg"] 	= {0x19, 1},
			["tohex"] 	= {0x1A, 1},
			["tobcd"] 	= {0x1B, 1},
			["and"] 	= {0x1C, 2},
			["or"] 		= {0x1D, 2},
			["xor"] 	= {0x1E, 2},
			["bls"] 	= {0x1F, 2},
			["brs"] 	= {0x20, 2},
			["=="] 		= {0x21, 3},
			["v!="]	 	= {0x22, 3},
			["v>="] 	= {0x23, 3},
			["v<="] 	= {0x24, 3},
			["v>"] 		= {0x25, 3},
			["v<"]	 	= {0x26, 3},
			["v=="] 	= {0x27, 3},
			["mod"] 	= {0x28, 2},
			["div"] 	= {0x29, 2},
			["end"] 	= {0xFF, 0},
			}

function getopcodelen(cmd)	--given a command will return the total length of the opcodes
	local length = 0

	for i, v in pairs(instructions) do
		local cmdlength = string.len(i)
		if cmdlength ~= nil then
			if string.sub(cmd, 0, cmdlength) == i then
				exists = true
				return 1 + v[2] --one byte for opcode plus one byte per parameter
			end
		end
	end

	return length
end

function checkins(cmd, linenumber, paramlist)	--Checks instruction exists and has correct number of parameters
	local exists = nil
	local valid = nil

	for i, v in pairs(instructions) do
		local cmdlength = string.len(i)
		if cmdlength ~= nil then
			if string.sub(cmd, 0, cmdlength) == i then
				exists = true
				valid = parseinstruction(v[1], string.sub(cmd, string.len(i)+1), paramlist[linenumber], v[2])
			end
		end
	end

	return exists, valid
end

function parse(rawsrc, linenumbers, outfile)
	local error = 0
	local errortype = 0
	local od = {}

	print ("Parsing opcode parameters")

	for i,v in ipairs(rawsrc) do
		error = i	--set error flag
		od[i] = {}		
		--print(linenumbers[i], v)

		local nextcommand = rawsrc[i+1]
		if nextcommand ~= nil then
			v = macrocheck(v,nextcommand) -- performs macro substitution if necessary but passes next command for jump calcs
		else
			v = macrocheck(v) -- performs macro substitution if necessary
		end
	
		local exists, valid = checkins(v, i, od) --Check the instruction for validness

		if exists ~= nil then
			if valid == nil then
				break
			end
		else	
			errortype=1
			break
		end
		error = 0	--reset error flag
	end

	print ("Parsing register substitutions")

	local bytecount = 0
	local jumpaddresses = {}
	if error == 0 then	--correct number of parameters etc, good, now we can continue
		for i,v in ipairs(od) do
			debug(v[0])
			bytecount = bytecount + 1			--Instruction costs 1 byte
			for j,k in ipairs(v) do
				if v[0] == 0x01 then			--Label Data Type 
					if j == 1 then
						jumpaddresses[k] = bytecount
						bytecount = bytecount + 1		--Parameters cost 1 byte each
						v[2] = nil
					end
				else
					local subvalue = subregisters(v[0], k)
					if subvalue == nil then
						error = i
						errortype = 2
					else
						v[j] = subvalue
					end
					bytecount = bytecount + 1		--Parameters cost 1 byte each
				end

				if error ~= 0 then break end	
			end
		debug("")
		if error ~= 0 then break end		
		end
	end

	print ("Updating jump vectors")

	if error == 0 then	--so far so good, lets update the jump vectors
		for i,v in ipairs(od) do
			if v[0] == 0x11 or v[0] == 0x15 then 	--jumps and calls
				local destination = jumpaddresses[v[1]]
				if destination ~= nil then
					local jaddress = string.format("%04X",destination)
					v[2]=tonumber("0x" .. string.sub(jaddress, 1, 2))
					v[1]=tonumber("0x" .. string.sub(jaddress, 3, 4))
				else
					error = i
					errortype = 3
				end
			end
			if error ~= 0 then break end	
		end
	end

	local file = assert(io.open(outfile, "wb"))

	if error == 0 then	--ok now we can output the code
		for i,v in ipairs(od) do
			if v[0] == 0x01 then 
				v[1] = 0xAA		--Not sure what this does
			end
			file:write(string.char(v[0]))
			debug("Instruction " .. v[0])
			for j,k in ipairs(v) do
				file:write(string.char(k))
			end
			debug("")
		end
	end

	file:close()

	if error ~= 0 then
		if errortype == 1 then
			print("!! Unknown operator in " .. linenumbers[error] .. " (" .. rawsrc[error] .. ")")
		elseif errortype == 2 then
			print("!! Parameter error in " .. linenumbers[error] .. " (" .. rawsrc[error] .. ")")
		elseif errortype == 3 then
			print("!! Missing jump label in " .. linenumbers[error] .. " (" .. rawsrc[error] .. ")")
		else
			print("!! Error detected in " .. linenumbers[error] .. " (" .. rawsrc[error] .. ")")
		end
		return nil
	else
		print("Program compiled successfully, using " .. bytecount .. " bytes\n")
	end

end


function escapeCSV (s)
	if string.find(s, '[,"]') then
		s = '"' .. string.gsub(s, '"', '""') .. '"'
	end
	return s
end


function fromCSV (s)
	s = s .. ','        -- ending comma
	local t = {}        -- table to collect fields
	local fieldstart = 1
	repeat
	-- next field is quoted? (start with `"'?)
	if string.find(s, '^"', fieldstart) then
		  local a, c
		  local i  = fieldstart
		  repeat
		    -- find closing quote
		    a, i, c = string.find(s, '"("?)', i+1)
		  until c ~= '"'    -- quote not followed by quote?
		  if not i then error('unmatched "') end
		  local f = string.sub(s, fieldstart+1, i-1)
		  table.insert(t, (string.gsub(f, '""', '"')))
		  fieldstart = string.find(s, ',', i) + 1
	else                -- unquoted; find next comma
		  local nexti = string.find(s, ',', fieldstart)
		  table.insert(t, string.sub(s, fieldstart, nexti-1))
		  fieldstart = nexti + 1
	end
	until fieldstart > string.len(s)
	return t
end

function DEC_HEX(IN)
    local B,K,OUT,I,D=16,"0123456789ABCDEF","",0
    while IN>0 do
        I=I+1
        IN,D=math.floor(IN/B),math.mod(IN,B)+1
        OUT=string.sub(K,D,D)..OUT
    end
    return OUT
end


print ("\nArcsembler (c) 2011 Archonix\n")

if tlsourcefile == nil then
	print("No Thinloom source filename passed")
else
	if tloutfile == nil then
		tloutfile = tlsourcefile .. ".out"
		print("No output file passed, outputting to " .. tloutfile)
	end

	local sourcebreak = string.len(tlsourcefile) - string.find(string.reverse(tlsourcefile), "\/", 1, true) + 1
	if sourcebreak ~= nil then
		sourcepath = string.sub(tlsourcefile, 1, sourcebreak)
		tlsourcefile = string.gsub(tlsourcefile, sourcepath, "")
	end

	-- Call the sourcefile and strip the headers
	readprogram(tlsourcefile, rawsource, linenumbers)

	parse(rawsource,linenumbers, tloutfile)
end






















