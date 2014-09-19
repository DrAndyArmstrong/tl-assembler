/* 
	Thinloom Assembler Interpreter
   	Arcsembler (c) Archonix 2010

   	Designed to work on PC or TL

	Andrew Armstrong	16 Nov 2010	V1.0
	Andrew Armstrong	17 Mar 2011	V1.1 --Added new instructions
*/


#include <stdio.h>
#include "HardwareProfile.h"

#define MAX_STACK (16u)
#define MAX_CALL_STACK (16u)
#define USER_REGISTERS (21u)

char reglist[USER_REGISTERS][3] = {"m1", "m2", "m3", "m4", "ms", "ls", "ax", "ay", "bx", "by", "cx", "cy", "dx", "dy", "ex", "ey", "fx", "fy", "gx", "gy"};

#define CHECK_BIT(var,pos) ((var) & (1<<(pos)))

#if defined(THINLOOM)

#include "TCPIP Stack/TCPIP.h"
#include <GenericTypeDefs.h>
static WORD fp;
#else

#define BYTE unsigned char
#define WORD long
static FILE *fp;

#endif

static BYTE fast[32];
static BYTE registers[USER_REGISTERS];
static BYTE stack[MAX_STACK];
static BYTE stackpointer=0;
static WORD callstack[MAX_CALL_STACK];
static WORD callstackpointer=0;
static BYTE pause=0;
static BYTE pausewatchdog=0;
static WORD i = 0;
static WORD size = 0;
static BYTE buf[5];
static BYTE initflag=0;
BYTE runprogram = 0x00; //program execution flag
BYTE debugoutput = 0x00; 

#if defined(THINLOOM)

#define printtl(x) if (debugoutput!=0) {sprintf(debugbuffer,x);putsUART(debugbuffer); }
#define get(x,y,z) doread(x,y,z)
#define set(x,y,z,a) dowrite(x,y,z,a)

static WORD inspointer = 0;
extern BYTE dowrite(WORD board,WORD device,WORD tregister, WORD data);
extern BYTE doread(WORD board,WORD device,WORD tregister);


extern APP_CONFIG AppConfig;
#define SEEK_CUR 3
#define SEEK_END 4 
#define SEEK_SET 5

#define SIZEVAR 3 //0=program options (0x01=e.g. autostart) 1=HiSize 2=LowSize
/*
int printtl(const char *format, ...)
{
	va_list ap;
	va_start(ap,format);
	printf(format, ap);
	va_end(ap);
}
*/
int tlseek(FILE *stream, long offset, int whence)
{
	switch ( whence )
	{
	case 3: inspointer = offset + i;
		break;
	case 4: inspointer = offset + size;
		break;
	case 5: inspointer = offset;
		break;
	}
}

WORD tlread(BYTE *buf, WORD pointer, WORD count, BYTE UNUSED)
{
	WORD byteaddress = sizeof(AppConfig) + SIZEVAR + inspointer + 49000; //This is a cheat, needs to fix memory map properly!

	XEEReadArray(byteaddress, buf, count);
	inspointer = inspointer + count;
	pausewatchdog++;
	return inspointer;
}

static WORD initdata()
{
	union 
	{
		WORD tempvar;
		struct 
		{
			BYTE LoByte;
			BYTE HiByte;
		} bytes;
	} TWOBYTES;

	BYTE programflags;

	XEEBeginRead(sizeof(AppConfig)+ 49000); //This is a cheat, needs to fix memory map properly!

	programflags = XEERead();			//ONLY autorun program on first execution
	if (initflag == 0)
	{
		initflag=1;
		runprogram = CHECK_BIT(programflags,0);	
		debugoutput = CHECK_BIT(programflags,1);
	}

	TWOBYTES.bytes.HiByte = XEERead();
	TWOBYTES.bytes.LoByte = XEERead();

	return(TWOBYTES.tempvar);
}

#else

#define printtl printf
#define get(x,y,z) //x y z
#define set(x,y,z,a) //x y z a

int tlseek(FILE *stream, long offset, int whence)
{
	return fseek(stream, offset, whence);
}

long tlread(char *buf, FILE *ofp, WORD count, BYTE step)
{
	if (step > 1)
	{
	    	tlseek(ofp, step-1, SEEK_CUR); 
	}
	fread(buf, 1, count, ofp);	
	return ftell(ofp);
}

long initdata()
{
	long osize;
	if ((fp = fopen("../source/test/test.tl.out", "r")) == NULL)
	{
		printtl("Cannot open source file\r\n\r\n");
	    	return 0;
	}

	tlseek(fp, 0L, SEEK_END);
	osize = ftell(fp);
	tlseek(fp, 0L, SEEK_SET);

	return osize;
}

#endif

BYTE BCD2HEX(BYTE n) 
{
	BYTE ourvalue = ((n>>4)*10+(n&0x0f));
	return ourvalue;
}

BYTE HEX2BCD(BYTE x) 
{
	BYTE ourvalue = ((((x) / 10) << 4) + (x) % 10);
	return ourvalue;
}

#if defined(THINLOOM)
int interpreter_tick(void)
{
WORD tempword;
static BYTE debugbuffer[80];
if (runprogram == 0)
{
	fp=0x00;
}
#else
int main(void)
{
WORD tempword;
printtl("\r\nArcsembler (c) Archonix 2010\r\n\r\n");
runprogram = 0x01;
#endif


#if defined(THINLOOM)
if (runprogram==0x00 && i>0)	//Clear the registers if program has finished execution
{
	for(i=0;i<USER_REGISTERS;i++)
	{
		registers[i]=0x00;	
	}
	i=0x00;
	size=0x00;
	inspointer=0x00;
	stackpointer=0x00;
	callstackpointer=0x00;
	pause=0;
	printtl("Reset Registers\r\n");
}
#endif

if (size == 0x00)
{
	size=initdata();
	if (size != 0)
	{
#if defined(THINLOOM)
	printtl("Program File size is 0x%04x\r\n", size);
#else
	printtl("File size is %ld\r\n", size);
#endif
	}
	else
	{
		runprogram=0;
	}
}

if (pause > 0)	//Pauses let the TL system breathe i.e. do all the other things it needs to do
{
	printtl(".");
	pause--;
	if (pause == 0)
	{
		pausewatchdog=0;
		printtl("\r\n");
	}
}

while (i < size && pause == 0 && runprogram != 0) 
{
	tlread(buf, fp, 1, 1);

	printtl("0x%02x - ", buf[0]);

	switch(buf[0])
	{
		case 0x00: i = tlread(buf, fp, 1, 1); //Nop
			printtl("NOP 0x%04x\r\n", (unsigned int) i);
			break;
		case 0x01: i = tlread(buf, fp, 1, 1); //Read two, thus skip over.
#if defined(THINLOOM)
			printtl("Label 0x%02x\r\n", i);
#endif
			break;//Label
		case 0x02: i = tlread(buf, fp, 2, 1);
			registers[buf[0]] = buf[1];
			printtl("Move 0x%02x to %.2s\r\n", buf[1], reglist[buf[0]]);
			break;//Mov
		case 0x03: i = tlread(buf, fp, 2, 1);
			registers[buf[0]] = registers[buf[1]];
			printtl("Copy 0x%02x to %.2s (from Register %.2s)\r\n", registers[buf[1]], reglist[buf[0]], reglist[buf[1]]);
			break;//Copy
		case 0x04: i = tlread(buf, fp, 1, 1);
			registers[buf[0]]++;
			printtl("Inc to %.2s (now contains 0x%02x)\r\n", reglist[buf[0]], registers[buf[0]]);
			break;//Inc
		case 0x05: i = tlread(buf, fp, 1, 1);
			registers[buf[0]]--;
			printtl("Dec to %.2s (now contains 0x%02x)\r\n", reglist[buf[0]], registers[buf[0]]);
			break;//Dec
		case 0x06: i = tlread(buf, fp, 3, 1);
			registers[buf[0]] = registers[buf[1]] + registers[buf[2]];
			printtl("Add %.2s+%.2s to %.2s (now contains 0x%02x)\r\n", reglist[buf[1]], reglist[buf[2]], reglist[buf[0]], registers[buf[0]]);
			break;//Add
		case 0x07: i = tlread(buf, fp, 3, 1);
			registers[buf[0]] = registers[buf[1]] - registers[buf[2]];
			printtl("Sub %.2s-%.2s to %.2s (now contains 0x%02x)\r\n", reglist[buf[1]], reglist[buf[2]], reglist[buf[0]], registers[buf[0]]);
			break;//Sub
		case 0x08: i = tlread(buf, fp, 3, 1);
			printtl("!= (JE) %d \r\n",(registers[buf[0]] != registers[buf[1]]));
			if (registers[buf[0]] == registers[buf[1]]) {i = tlread(buf, fp, buf[2], 1); } 
			break;//je
		case 0x09: i = tlread(buf, fp, 3, 1);
			printtl(">= (JL) %d \r\n",(registers[buf[0]] >= registers[buf[1]]));
			if (registers[buf[0]] < registers[buf[1]]) {i = tlread(buf, fp, buf[2], 1);} 
			break;//jl
		case 0x0A: i = tlread(buf, fp, 3, 1);
			printtl("<= (JG) %d \r\n",(registers[buf[0]] <= registers[buf[1]]));
			if (registers[buf[0]] > registers[buf[1]]) {i = tlread(buf, fp, buf[2], 1); } 
			break;//jg
		case 0x0B: i = tlread(buf, fp, 3, 1);
			printtl("> (JLE) %d \r\n",(registers[buf[0]] > registers[buf[1]]));
			if (registers[buf[0]] <= registers[buf[1]]) {i = tlread(buf, fp, buf[2], 1); } 
			break;//jle
		case 0x0C: i = tlread(buf, fp, 3, 1);
			printtl("< (JGE) %d \r\n",(registers[buf[0]] < registers[buf[1]]));
			if (registers[buf[0]] >= registers[buf[1]]) {i = tlread(buf, fp, buf[2], 1); } 
			break;//jge
		case 0x0D: i = tlread(buf, fp, 1, 1);
#if defined(THINLOOM)
			tempword = (WORD)registers[2] << 8;
			tempword += (WORD)registers[3];
			printtl("GET Reading to register %.2s 0x%02x/0x%02x/0x%04x\r\n", reglist[buf[0]], registers[0] , registers[1] , tempword);

			if (registers[1]==0xAA)
			{
				registers[buf[0]]=fast[registers[3]];
			}
			else
			{
				registers[buf[0]] = get(registers[0],registers[1], tempword);
			}
#endif
			break;//get
		case 0x0E: i = tlread(buf, fp, 1, 1);
#if defined(THINLOOM)
			tempword = (WORD)registers[2] << 8;
			tempword += (WORD)registers[3];
			printtl("SET Writing to 0x%02x/0x%02x/0x%04x\r\n", registers[0] , registers[1] , tempword);

			if (registers[1]==0xAA)
			{
				fast[registers[3]]=registers[buf[0]];
			}
			else
			{
				set(registers[0],registers[1], tempword, registers[buf[0]]);
			}
#endif
			break;//set
		case 0x0F: i = tlread(buf, fp, 1, 1);
			printtl("Sleep: 0x%02x\r\n", buf[0]);
#if defined(THINLOOM)
			pause=buf[0];
#endif
			break;//slp
		case 0x10: i = tlread(buf, fp, 1, 1);
			printtl("USleep: 0x%02x\r\n", buf[0]);
			break;//uslp
		case 0x11: i = tlread(buf, fp, 2, 1);  //Jumps are WORD
			tempword = (WORD)buf[1] << 8;
			tempword += (WORD)buf[0];
			tlseek(fp, tempword-1, SEEK_SET); //Set Seek to first instruction after label
			i=tempword;
			printtl("Jumping to: 0x%04x\r\n", (unsigned int) i);
			break;//jump
		case 0x12: //i = tlread(buf, fp, 1, 1);
			printtl("NOP\r\n");
			break;
		case 0x13: i = tlread(buf, fp, 1, 1);
			if (stackpointer < MAX_STACK-1)
			{
				stackpointer++;
				printtl("Pushing register %.2s (0x%02x) to stack\r\n", reglist[buf[0]], registers[buf[0]]);
				stack[stackpointer] = registers[buf[0]];
			}
			else
			{
				printtl("!! ERROR STACK FULL\r\n");
				runprogram=0;
			}
			break;
		case 0x14: i = tlread(buf, fp, 1, 1);
			if (stackpointer > 0)
			{
				printtl("Popping stack register value 0x%02x to %.2s\r\n", stack[stackpointer], reglist[buf[0]]);
				registers[buf[0]] = stack[stackpointer];
				stackpointer--;
			}
			else
			{
				printtl("!! ERROR STACK EMPTY\r\n");
				runprogram=0;
			}
			break;
		case 0x15: i = tlread(buf, fp, 2, 1);  //Jumps are WORD
			if (callstackpointer < MAX_CALL_STACK-1)
			{
				tempword = (WORD)buf[1] << 8;
				tempword += (WORD)buf[0];

				tlseek(fp, (tempword)-1, SEEK_SET); //Set Seek to first instruction after label
				callstackpointer++;
				callstack[callstackpointer] = i;
				i=(tempword);
				printtl("Calling subroutine 0x%04x from 0x%04x\r\n", (unsigned int) i, (unsigned int) callstack[callstackpointer]);
			}
			else
			{
				printtl("!! ERROR SUBROUTINE TOO DEEP\r\n");
				runprogram=0;
			}

			break;//jump
		case 0x16: 
			if (callstackpointer > 0)
			{
				printtl("Returning to instruction at 0x%04x\r\n", (unsigned int) callstack[callstackpointer] );
				tlseek(fp, callstack[callstackpointer], SEEK_SET);
				callstackpointer--;
			}
			else
			{
				printtl("!! ERROR RET ENTERED WITHOUT CALL\r\n");
				runprogram=0;
			}

			break;
		case 0x17: i = tlread(buf, fp, 2, 1);
			printtl("Mult 0x%02x with 0x%02x result",registers[buf[0]], registers[buf[1]]);
			tempword = registers[buf[0]];
			tempword = tempword * registers[buf[1]];
			registers[4] = (BYTE) ((tempword >> 8) & 0xFF);
			registers[5] = (BYTE) tempword & 0x00FF;
			printtl(" 0x%02x%02x\r\n",registers[4], registers[5]);
			break;
		case 0x18: i = tlread(buf, fp, 1, 1);
			printtl("Loading 0x%02x to destination\r\n",buf[0]);
			tempword = (WORD)registers[2] << 8;
			tempword += (WORD)registers[3];

			if (registers[1]==0xAA)
			{
				fast[registers[3]]=buf[0];
			}
			else
			{
				set(registers[0],registers[1], tempword, buf[0]);	
			}
			tempword ++;
			registers[2] = (BYTE) ((tempword >> 8) & 0xFF);
			registers[3] = (BYTE) tempword & 0x00FF;

			break;
		case 0x19: i = tlread(buf, fp, 1, 1);
			if ((registers[buf[0]] > 32 && registers[buf[0]] < 127)) 
			{
				printtl("Register %.2s contains 0x%02x (%d %c)\r\n",reglist[buf[0]], registers[buf[0]], registers[buf[0]], registers[buf[0]]);
			}
			else
			{
				printtl("Register %.2s contains 0x%02x (%d)\r\n",reglist[buf[0]], registers[buf[0]], registers[buf[0]]);
			}
			break;
		case 0x1A: i = tlread(buf, fp, 1, 1);
			printtl("BCD2HEX %.2s\r\n",reglist[buf[0]]);
			registers[buf[0]] = BCD2HEX(registers[buf[0]]);
			break;
		case 0x1B: i = tlread(buf, fp, 1, 1);
			printtl("HEX2BCD %.2s\r\n",reglist[buf[0]]);
			registers[buf[0]] = HEX2BCD(registers[buf[0]]);
			break;
		case 0x1C: i = tlread(buf, fp, 2, 1);
			printtl("Bitwise AND %.2s 0x%02x & 0x%02x",reglist[buf[0]],registers[buf[0]],registers[buf[1]]);
			registers[buf[0]] = registers[buf[0]] & registers[buf[1]];
			printtl(" = 0x%02x\r\n",registers[buf[0]]);
			break;
		case 0x1D: i = tlread(buf, fp, 2, 1);
			printtl("Bitwise OR %.2s 0x%02x | 0x%02x",reglist[buf[0]],registers[buf[0]],registers[buf[1]]);
			registers[buf[0]] = registers[buf[0]] | registers[buf[1]];
			printtl(" = 0x%02x\r\n",registers[buf[0]]);
			break;
		case 0x1E: i = tlread(buf, fp, 2, 1);
			printtl("Bitwise XOR %.2s 0x%02x ^ 0x%02x",reglist[buf[0]],registers[buf[0]],registers[buf[1]]);
			registers[buf[0]] = registers[buf[0]] ^ registers[buf[1]];
			printtl(" = 0x%02x\r\n",registers[buf[0]]);
			break;
		case 0x1F: i = tlread(buf, fp, 2, 1);
			printtl("Bitwise Left Shift %.2s\r\n",reglist[buf[0]]);
			registers[buf[0]] = registers[buf[0]] << buf[1];
			break;
		case 0x20: i = tlread(buf, fp, 2, 1);
			printtl("Bitwise Right Shift %.2s\r\n",reglist[buf[0]]);
			registers[buf[0]] = registers[buf[0]] >> buf[1];
			break;
		case 0x21: i = tlread(buf, fp, 3, 1);
			printtl("== (JNE) %d \r\n",(registers[buf[0]] == registers[buf[1]]));
			if (registers[buf[0]] != registers[buf[1]]) {i = tlread(buf, fp, buf[2], 1); } //v1.1 New Instruction
			break;//je
		case 0x22: i = tlread(buf, fp, 3, 1);
			printtl("!= (JE) val %d \r\n",(registers[buf[0]] != buf[1]));
			if (registers[buf[0]] == buf[1]) {i = tlread(buf, fp, buf[2], 1); }  //v1.1 New Instruction
			break;//je with value not register
		case 0x23: i = tlread(buf, fp, 3, 1);
			printtl(">= (JL) val %d \r\n",(registers[buf[0]] >= buf[1]));
			if (registers[buf[0]] < buf[1]) {i = tlread(buf, fp, buf[2], 1);}  //v1.1 New Instruction
			break;//jl with value not register
		case 0x24: i = tlread(buf, fp, 3, 1);
			printtl("<= (JG) val %d \r\n",(registers[buf[0]] <= buf[1]));
			printtl("Buffer2 %d \r\n", buf[2]);
			if (registers[buf[0]] > buf[1]) {i = tlread(buf, fp, buf[2], 1); }  //v1.1 New Instruction
			break;//jg with value not register
		case 0x25: i = tlread(buf, fp, 3, 1);
			printtl("> (JLE) val %d \r\n",(registers[buf[0]] > buf[1]));
			if (registers[buf[0]] <= buf[1]) {i = tlread(buf, fp, buf[2], 1); }  //v1.1 New Instruction
			break;//jle with value not register
		case 0x26: i = tlread(buf, fp, 3, 1);
			printtl("< (JGE) val %d \r\n",(registers[buf[0]] < buf[1]));
			if (registers[buf[0]] >= buf[1]) {i = tlread(buf, fp, buf[2], 1); }  //v1.1 New Instruction
			break;//jge with value not register
		case 0x27: i = tlread(buf, fp, 3, 1);
			printtl("== (JNE) val %d\r\n",(registers[buf[0]] == buf[1]));
			if (registers[buf[0]] != buf[1]) {i = tlread(buf, fp, buf[2], 1); }  //v1.1 New Instruction
			break;//je with value not register
		case 0x28: i = tlread(buf, fp, 2, 1);
			printtl("Mod 0x%02x with 0x%02x result",registers[buf[0]], registers[buf[1]]);
			tempword = registers[buf[0]];
			tempword = tempword % registers[buf[1]];
			registers[4] = (BYTE) ((tempword >> 8) & 0xFF);
			registers[5] = (BYTE) tempword & 0x00FF;
			printtl(" 0x%02x%02x\r\n",registers[4], registers[5]);
			break;
		case 0x29: i = tlread(buf, fp, 2, 1);
			printtl("Div 0x%02x with 0x%02x result",registers[buf[0]], registers[buf[1]]);
			tempword = registers[buf[0]];
			tempword = tempword / registers[buf[1]];
			registers[4] = (BYTE) ((tempword >> 8) & 0xFF);
			registers[5] = (BYTE) tempword & 0x00FF;
			printtl(" 0x%02x%02x\r\n",registers[4], registers[5]);
			break;
		case 0xFF: //END
			printtl("!! PROGRAM END CALLED\r\n");
			runprogram=0;
			break;
		default:
			printtl("!! ERROR INSTRUCTION NOT RECOGNISED 0x%02x, instruction %ld\r\n", buf[0], i);
			runprogram=0;
	}

	if (pausewatchdog > 100)
	{
		printtl("!! SYSTEM PERFORMANCE WATCHDOG PAUSING EXECUTION\r\n");
		pause++;
	}
}
#if defined(THINLOOM)
if (i > size && runprogram==1)
{
	printtl("<PROGRAM END>");
	runprogram=0;
	size=0;
}
#else
printtl("<PROGRAM END>");
printtl("\r\n\r\n");
fclose(fp);
#endif
}
