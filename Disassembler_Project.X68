*****************************************************************
* Program	: Disasembler
* Description (A general discription about the dissasembler as a whole) :
* This is one of three parts of a Dissasembler weritten in 68K Assembly
* Language. As a whole this program is meant to be colpletly benine. 
* It does read only operations to deccode a memory
* image and prints the instructions that have been decoded to the screen.
*
******************************************************************

******************************************************************
*
* EQUates and REG
*
******************************************************************
run		EQU	$400			* The memory location to run the program from
load		EQU	$400			* The memory location that the program is loaded into
sim_end		EQU	$2700			* Return control to the simulator
data		EQU	$3500			* The data section will be located here	

task0		EQU	00			* TRAP#15 task 0
task1		EQU	01			* TRAP#15 task 1
task2		EQU	02			* TRAP#15 task 2

stack		EQU	$000A0000		* Locate the stack here
min_address	EQU	$00000400		* The smalles address that can be used in the test
max_address	EQU	$0000FFFF		* The largest address that can be used in the test

decode_count	SET	$00			* Initial value for decodein loop count
in_count	SET	$00			* Initialize the input count value
ascii_num_0	EQU	$30			* ASCII number 0
ascii_num_9	EQU	$39			* ASCII number 9
ascii_num_A	EQU	$41			* ASCII number A
ascii_num_F	EQU	$46			* ASCII number F
ascii_num_al	EQU	$61			* ASCII number a
ascii_num_fl	EQU	$66			* ASCII number f
space_char	EQU	$00			* NULL
line_count	EQU	$10			* Maximum number of lines

reg_fl		EQU	%01000000			* needs to get next word and figure out the reg set being moved
reg_set_1	REG	A3-A4			* The registers used to sotre the starting and ending address of the test reigon
reg_set_head	REG	A0-A6/D0-D6		* The registers used for memory check
reg_set_2	REG	A0-A1/D0-D4/D7		* The registers to save before going to decode helper routine
prompt_reg	REG	D0-D1/A1/A5		* The registers used for I/O prompting
add_val_reg	REG	A3-A4			* Holds pointers to the valid address range
reg_set_4	REG	A5-A6/D5		* The registers used to sotre the starting and ending address of the test reigon
reg_set_5	REG	A0-A4/D0-D6		* Another register set
reg_set_6	REG	A0-A4/D1-D2,D4		* Another register set
reg_set_7	REG	A0-A6/D0-D6		* The registers used to sotre the starting and ending address of the test reigon
reg_set_8	REG	A0-A2/A5-A6/D0-D3/D5-D6	* Another reg set

good_flag	EQU	$0000			* Successfully decoded instruction
bad_flag	EQU	$0001			* Bad instructoin
end_flag	EQU	$0011			* End of memory image

long_ea_fl	EQU	$0100			* Indicats that the opcode is size long
word_ea_fl	EQU	$0110			* Indicates the the opcode is size word

data_flag	EQU	$0101			* Flag to indicati I need to put Dn into buffer
addr_flag	EQU	$0111			* Flag to indicate I need to put An into buffer

no_more_wk	EQU	$FFFF			* Flag to indicate there is no more work to do after EA work
lea_rt_fl	EQU	$1000			* Flag to indicate that I need to return to LEA after EA work
ori_rt_fl	EQU	$1111			* Flag to indicate that I need to return to ORI after EA work
andirt_fl	EQU	$1001			* Flag to indicate that I need to return to ANDI after EA work
subirt_fl	EQU	$1010			* Flag to indicate that I need to return to SUBI after EA work
addirt_fl	EQU	$1011			* Flag to indicate that I need to return to ADDI after EA work
eorirt_fl	EQU	$1100			* Flag to indicate that I need to return to EORI after EA work
cmpirt_fl	EQU	$1101			* Flag to indicate that I need to return to CMPI after EA work
movert_fl	EQU	$1110			* Flag to indicate that I need to return to MOOVE after EA work
or_ea_dn_fl	EQU	$A000			* Flag to indicate that I need to return to OR_EA_DN
or_dn_ea_fl	EQU	$A00A			* Flag to indicate that I need to return to OR_DN_EA
add_ea_dn_fl	EQU	$A0A0			* Flag to indicate that I need to return to ADD_EA_DN
add_dn_ea_fl	EQU	$A0AA			* Flag to indicate that I need to return to ADD_DN_EA
adda_ea_dn_fl	EQU	$AA00			* Flag to indicate that I need to return to ADDA_EA_AN
and_ea_dn_fl	EQU	$AA0A			* Flag to indicate that I need to return to AND_EA_DN
and_dn_ea_fl	EQU	$AAA0			* Flag to indicate that I need to return to AND_DN_EA
sub_ea_dn_fl	EQU	$B000			* Flag to indicate that I need to return to SUB_EA_DN
sub_dn_ea_fl	EQU	$B00B			* Flag to indicate that I need to return to SUB_DN_EA
suba_ea_an_fl	EQU	$B0B0			* Flag to indicate that I need to return to SUB_EA_AN
cmpa_ea_an_fl	EQU	$C000			* Flag to indicate that I need to return to CMPA_EA_AN
eor_dn_ea_fl	EQU	$C00C			* Flag to indicate that I need to return to EOR_DN_EA
cmp_ea_dn_fl	EQU	$C0C0			* Flag to indicate that I need to return to CMP_EA_DN
move_b_fl	EQU	$D000			* Flag to indicate that I need to return to RT_MOVE_B
move_w_fl	EQU	$D00D			* Flag to indicate that I need to return to RT_MOVE_W
move_l_fl	EQU	$D0D0			* Flag to indicate that I need to return to RT_MOVE_L
movea_w_fl	EQU	$D0DD			* Flag to indicate that I need to return to RT_MOVEA_W
movea_l_fl	EQU	$DD00			* Flag to indicate that I need to return to RT_MOVEA_L
mm_ea_reg_fl	EQU	$E000			* Flag to indicate that I need to return to MM_EA_REG
mm_reg_ea_fl	EQU 	$E00E			* Flag to indicate that I need to return to MM_REG_EA

imed_byte	EQU	%00111000		* Fake imediate byte code to pass EA
imed_word	EQU	%00111000		* Fake imediate word code to pass EA
imed_long	EQU	%00111001		* Fake imediate long code to pass EA

mask1		EQU	$0001			* Mask off 1
mask2		EQU	$0004			* Mask off 2
mask0_2		EQU	$0007			* Mask off 0-2
mask0_3		EQU	$000F			* Mask off 0-3 
mask0_5		EQU	$003F			* Mask off 0-5
mask0_7		EQU	$00FF			* Mask off 0-7
mask3_4		EQU	$0018			* Mask off 3-4
mask3_5		EQU	$0038			* Mask off 3-5
mask3_7		EQU	$00F8			* Mask off 3-7
mask6		EQU	$0040			* Mask off 6
mask6_7		EQU	$00C0			* Mask off 6-7
mask6_8		EQU	$01C0			* Mask off 6-8
mask6_11	EQU	$0FC0			* Mask off 6-11
mask7		EQU	$0080			* Mask off 7
mask8		EQU	$0100			* Mask off 8
mask7_8		EQU	$0180			* Mask off 7-8
mask8_11	EQU	$0F00			* Mask off 8-11
mask9_11	EQU	$0E00			* Mask off 9-11
mask10		EQU	$0400			* Mask off 10
mask12_13	EQU	$3000			* Mask off 12-13
mask12_15	EQU	$F000			* Mask off 12-15
ANOTH_START
shift2		EQU	2			* Shift 2 bits
shift3		EQU	3			* Shift 3 bits
shift4		EQU	4			* Shift 4 bits
shift6		EQU	6			* Shitf 6 bits
shift7		EQU	7			* Shift 7 bits
shift8		EQU	8			* Shift 8 bits
shift9		EQU	9			* Shift 9 bits
shift10		EQU	10			* Shift 10 bits
shift12		EQU	12			* Shift 12 bits

jmp_offset	EQU	6			* Each jump table entry is 6 bytes of memory apart

******************************************************************
* PROGRAM CODE IS BELOW!
******************************************************************
*
* Sub-routine: MAIN_IO
* Description: This is the I/O portion to print out the first instruction
* 	       for clinet and get the information from them and it goes
*	       through error checking process to make sure the information
*	       from client is correct. The information would be passed to 
*	       Op_Code for decoding.
*API:
* A3 Points to the minimum starting address
* A4 Points to the max ending address
* D5 Holds the test word
******************************************************************

		OPT	CRE			* Cross-refrencd directive, show the symbol table
		ORG	run			* Run the program at this location

PROGRAM_PREP	LEA	stack,SP		* Initialize the Stack Pointer
		LEA	valid_start,A3		* Load the lowest allowed starting address into A3
		BSR	BANNER			* Printing banner		

ANOTH_START_	CLR.L	D0			* Clear D0
		CLR.L	D1			* Clear D1
		CLR.L	D2			* Clear D2
		CLR.L	D3			* Clear D3
		CLR.L	D4			* Clear D4
		CLR.L	D5			* Clear D5
		CLR.L	D6			* Clear D6
		CLR.L	D7			* Clear D7
		LEA	stack,SP		* Initialize the Stack Pointer
		LEA	valid_start,A3		* Load the lowest allowed starting address into A3
		LEA	line_counter,A5		* Load the loacation that the number of lines printed to the screen is stored
		CLR.W	(A5)			* Reset the counter to zero
		
		BSR	PROMPT_START		* Branch to prompt input message
		BSR	PROMPT_END		* Branch to promt end address
		MOVEA.L	A5,A3			* A3 will be used from here on to point to the word in memory to decode

		CLR.L	D0			* Clear Do before use
		LEA	end_address,A5		* Load the address to save the ending address
		MOVE.L	A6,D0			* Move the ending address into a data register
		MOVE.L	D0,(A5)			* Save the ending address

		LEA	line_counter,A5		* Load the loacation that the number of lines printed to the screen is stored
		ADDI.W	#0,(A5)			* Initialize the line count to zero

PROGRAM_START	LEA	end_address,A5		* Load the address where the address of the end of the memory image is stored
		MOVE.L	(A5),A0			* Put the saved address into A0
		CMPA.L	A3,A0			* Check to see if the end of the memory image has been reached
		BLE	ANOTH_MEM		* If disassembling done, client can continue with another location
		BRA	NEXT_OP			* decide if the program should end
		

NEXT_OP		LEA	line_counter,A5		* Load the loacation that the number of lines printed to the screen is stored
		CMPI.W	#26,(A5)		* Check to see if we have reached the max amount of lines to be printed to the screen
		BEQ	STOP_DISPLAY		* Stop decodeing and call method PRINT_LINE
DISP_MORE	BSR	SET_BUFFERS		* Call the buffer setting method	
		JMP	MAIN_OP			* Call opcode
				
FLAG_CHECK	CMPI.W	#end_flag,D4		* check for end flag
		BEQ	QUIT			* All done!
		CMPI.W	#good_flag,D4		* check for good flag
		BNE	DO_PRINT_BAD		* Deal with bad flag
		BSR	PRINT_GOOD_DATA		* Deal with good data
		BRA	RESET_BUFFERS		* Get ready to reset the buffers	

DO_PRINT_BAD	BSR	PRINT_BAD_DATA		* print bad flag
RESET_BUFFERS	BSR	SET_BUFFERS		* Call the buffer setting method
		ADDQ.W	#1,(A5)			* Incriment counter
		BRA	PROGRAM_START		* Loop again

STOP_DISPLAY	BSR	PRINT_LINE		* Display a message asking if they would like to see the next set of decoded ops
		BRA	DISP_MORE		* If this line of code is reached, display the next 20 lines
		
ANOTH_MEM	BSR	ANOTHER_MEM_		* Ask client to continue with another memory location
		BRA	ANOTH_START_		* Start over		
		
QUIT		JMP	ARE_U_SURE
QUIT_DONE	STOP	#sim_end		* Return controle to simulator

		
*****************************************************************
* Sub-routine: CLEAR_BUFF_GD
* Description: This method will clear the good buffer which would be used in SET_BUFFERS.
*              
* API: 
* A4 points to the start of the good buffer
*****************************************************************
CLEAR_BUFF_GD	LEA 	good_buf,A0		* Load good buffer into A0
		LEA	bad_buf,A1		* Load the address of the last byte of good_buf
CLR_GD_LOOP	MOVE.B	#$20,(A0)+		* Update the Buffer and advance pointer
		CMPA.L	A0,A1			* Check for the end of the string
		BNE	CLR_GD_LOOP		* Get next ASCII (for safty)
		RTS				* Return to calling method


*****************************************************************
* Sub-routine: CLEAR_BUFF_BD
* Description: This method will clear the bad buffer which would be used in SET_BUFFERS.
*              
* API: 
* A4 points to the start of the good buffer
*****************************************************************		
CLEAR_BUFF_BD	LEA 	bad_buf,A0		* Load bad buffer into A0
		LEA	user_input_len,A1	* Load the address of the last byte of good_buf
CLR_BD_LOOP	MOVE.B	#$20,(A0)+		* Update the Buffer and advance pointer
		CMPA.L	A0,A1			* Check for the end of the string
		BNE	CLR_BD_LOOP		* Get next ASCII (for safty)
		RTS


*****************************************************************
* Sub-routine: SET_BUFFERS
* Description: This method will clear the buffers and set A4 pointing back at the
*               beginning of the buffer to decode the next opcode and EA.
*
* API: 
* A4 points to the start of the good buffer
*****************************************************************
SET_BUFFERS	BSR	CLEAR_BUFF_GD		* Branch to clear buffers
		BSR	CLEAR_BUFF_BD		* Branch to clear buffers

		LEA	long_flag,A0		* Load the address where the EA lenght flag is stored
		MOVE.W	#word_ea_fl,(A0)	* Reset EA length flag

		LEA	good_buf,A4		* Load good buffer into A4
		MOVE.L	A3,D0			* Copy current pointer
		MOVEA	A4,A0			* Set up pass to MEM_TO_ASCII
		MOVE.L	#8,D3			* Convert to 8 ASCII chars
		BSR	MEM_TO_ASCII		* Convert address to ASCII
		ADDA	#8,A4			* Move 8 bytes forword
		MOVE.B	#$20,(A4)+		* Put a space after the address
		MOVE.B	#$20,(A4)+		* Put a space after the address
		MOVE.B	#$20,(A4)+		* Put a space after the address

		LEA	bad_buf,A6		* Load address of bad_buf
		MOVE.L	A3,D0			* Copy current pointer
		MOVEA	A6,A0			* Set up pass to MEM_TO_ASCII
		MOVE.L	#8,D3			* Convert to 8 ASCII chars
		BSR	MEM_TO_ASCII		* Convert address to ASCII
		ADDA	#8,A6			* Move 8 bytes forword
		MOVE.B	#$20,(A6)+		* Put a space after the address
		MOVE.B	#$20,(A6)+		* Put a space after the address
		MOVE.B	#$20,(A6)+		* Put a space after the address

		LEA 	bad_ad_msg_2,A0		* Load the addres of '<DATA!>' into A0
		LEA	bad_ad_m_2_len,A1	* Load the address of the end of string
_DATA_LOOP	MOVE.B	(A0)+,(A6)+		* Update the Buffer and advance pointer
		CMPA.L	A0,A1			* Check for the end of the string
		BNE	_DATA_LOOP		* Get next ASCII (for safty)
		RTS				* Return to calling method
	
**************************************************************
* Sub-routine: BANNER
* Description: Displays a banner for the start program
* API:
* D0 holds the TRAP #15 mode
* D1 holds the TRAP #15 string lenght
* A1 holds the TRAP #15 string starting address
**************************************************************
BANNER		MOVE.B	#task0,D0		* Load the type of TRAP #15 task
		LEA	instr_prompt,A1		* Load the starting address of the string
		MOVE.W	instr_len,D1		* Get the length of the string
		TRAP	#15			* Print to screen

		MOVE.B	#task0,D0		* Load the type of TRAP #15 task
		LEA	instr_p1,A1		* Load the starting address of the string
		MOVE.W	instr_p1_len,D1		* Get the length of the string
		TRAP	#15			* Print to screen
		
		MOVE.B	#task0,D0		* Load the type of TRAP #15 task
		LEA	instr_p2,A1		* Load the starting address of the string
		MOVE.W	instr_p2_len,D1		* Get the length of the string
		TRAP	#15			* Print to screen
		
		MOVE.B	#task0,D0		* Load the type of TRAP #15 task
		LEA	instr_p3,A1		* Load the starting address of the string
		MOVE.W	instr_p3_len,D1		* Get the length of the string
		TRAP	#15			* Print to screen

		MOVE.B	#task0,D0		* Load the type of TRAP #15 task
		LEA	instr_p4,A1		* Load the starting address of the string
		MOVE.W	instr_p4_len,D1		* Get the length of the string
		TRAP	#15			* Print to screen	

		MOVE.B	#task0,D0		* Load the type of TRAP #15 task
		LEA	instr_p5,A1		* Load the starting address of the string
		MOVE.W	instr_p5_len,D1		* Get the length of the string
		TRAP	#15			* Print to screen

		MOVE.B	#task0,D0		* Load the type of TRAP #15 task
		LEA	instr_p6,A1		* Load the starting address of the string
		MOVE.W	instr_p6_len,D1		* Get the length of the string
		TRAP	#15			* Print to screen
				
		MOVE.B	#task0,D0		* Load the type of TRAP #15 task
		LEA	instr_p1,A1		* Load the starting address of the string
		MOVE.W	instr_p1_len,D1		* Get the length of the string
		TRAP	#15			* Print to screen
		
		MOVE.B	#task0,D0		* Load the type of TRAP #15 task
		LEA	instr_p7,A1		* Load the starting address of the string
		MOVE.W	instr_p7_len,D1		* Get the length of the string
		TRAP	#15			* Print to screen
		
		RTS

**************************************************************
* Sub-routine: PROMPT_START
* Description: Displays a message propting the user to enter a starting address for the test and returns a valid address.
* API:
* D0 holds the TRAP #15 mode
* D1 holds the TRAP #15 string lenght
* A1 holds the TRAP #15 string starting address
* A3 Points to the memory location where a valid user imput starting address is stored
* A4 Points to the valid data that has been entered
* D6 Holds a local copy of decoded memory word, isolate bit 1 to check for odd address
* D7 is the flag passing register
**************************************************************
PROMPT_START	MOVEM.L	reg_set_1,-(SP)		* Save main registers on stack so they can be reused

DO_AGAIN	MOVE.B	#task0,D0		* load the task
		LEA	blank_line,A1		* load string
		MOVE.W	blank_line_len,D1	* get length
		TRAP	#15			* Print screen		

		MOVE.B	#task0,D0		* Load the type of TRAP #15 task
		LEA	prompt_1,A1		* Load the starting address of the string
		MOVE.W	prompt_1_len,D1		* Get the length of the string
		TRAP	#15			* Print to screen	

		MOVE.B	#task2,D0		* Load input TRAP #15 task into D0
		LEA	user_input,A1		* Load starting address of memory for input
		MOVE.W	user_input_len,D1	* Get allowed length for user input
		TRAP	#15			* Get user input
	
		BSR	ASCII_TO_MEM		* Branch to ASCII to HEX conversion 
		
		CMPI.B	#$1,D7			* is it an address at all?
		BEQ	INVL_E_ASCII		* print out invalid ascii error
		
		LEA	valid_start,A3		* load valid start into A5		
		CMP.L	(A3),D3			* Compair the minimum address < 00002000 print error
		BLT	PRINT_E_1		* Print error
		
		LEA	valid_end,A6		* load vlaid end into A5
		CMP.L	(A6),D3			* Check that it's not out of range
		BGE	PRINT_E_7		* Print error
		
		LEA	valid_end,A6		* load vlaid end into A5
		CMP.L	(A6),D3			* make sure not > max address
		BGT	PRINT_E_2		* Print error
		MOVE.L	D3,D6			* Make local copy
		ANDI.L	#$00000001,D6		* Mask
		CMPI.B	#$1,D6			* Check for odd address	
		BEQ	PRINT_E_3		* Print error
		
		JSR	TO_OPCODE_STRT		* Sending user input starting address to Op-Code
		
		BRA	QUIT_PROMPT		* OK

INVL_E_ASCII	BSR	INVAL_ASCII_ERR		* Jump to print error
		CLR.L	D7			* Clear the bad data for the next try
		BRA	DO_AGAIN		* Start over

PRINT_E_1	BSR	PRINT_ERROR_1		* Jump to print error
		BRA	DO_AGAIN		* Start over
		
PRINT_E_2	BSR	PRINT_ERROR_2		* Jump to print error			
		BRA	DO_AGAIN		* Start Over

PRINT_E_3	BSR	PRINT_ERROR_3		* Jump to print error
		BRA	DO_AGAIN		* Start over
		
PRINT_E_7	BSR	PRINT_ERROR_7		* Jump to print error
		BRA	DO_AGAIN		* Start over
		
QUIT_PROMPT	LEA	user_start_addr,A3	* Load address of location to store valid address
		MOVE.L	D3,(A3)			* Save the valid user input
		MOVEM.L (SP)+,reg_set_1		* Restore registers	
		RTS				* Return to calling method

**************************************************************
* Sub-routine: TO_OPCODE_STRT
* Description: Sends the starting address to Op-Code
*
**************************************************************
TO_OPCODE_STRT	MOVE.L	D3,A5			* Send starting address to Op-Code
		
		RTS
		
**************************************************************
* Sub-routine: PROMPT_END
* Description: Displays a message propting the user to enter an ending address for the test and returns a valid address.
* API:
* D0 holds the TRAP #15 mode
* D1 holds the TRAP #15 string lenght
* A1 holds the TRAP #15 string starting address
* A3 Points to the memory location where a valid user imput starting address is stored
* A4 Points to the valid data that has been entered
* A5 Points to the users starting address
* D6 Holds a local copy of decoded memory word, isolate bit 1 to check for odd address
* D7 is the flag passing register
**************************************************************
PROMPT_END	MOVEM.L	reg_set_1,-(SP)		* Save main registers on stack so they can be reused

AGAIN		MOVE.B	#task0,D0		* Load the type of TRAP #15 task
		LEA	prompt_2,A1		* Load the starting address of the string
		MOVE.W	prompt_2_len,D1		* Get the length of the string
		TRAP	#15			* Print to screen

		MOVE.B	#task2,D0		* Load input TRAP #15 task into D0
		LEA	user_input,A1		* Load starting address of memory for input
		MOVE.W	user_input_len,D1	* Get allowed length for user input
		TRAP	#15			* Get user input

		BSR	ASCII_TO_MEM		* Branch to ASCII to MEM 
		
		CMPI.B	#$1,D7			* is it an address at all?
		BEQ	INVL_Er_ASCII		* Print out invalid ASCII error
		
		LEA	valid_end,A6		* load vlaid end into A5
		CMP.L	(A6),D3			* Check that it's not out of range
		BGE	PRINT_Er_7		* Print error
		
		LEA	user_start_addr,A2	* Load address where the users starting address is stored
		CMP.L	(A2),D3			* Make sure end is > start
		BLE	PRINT_Er_6		* Print error
		
		LEA	valid_end,A6		* load vlaid end into A5
		CMP.L	(A6),D3			* make sure not > max address
		BGT	PRINT_Er_2		* Print error
		MOVE.L	D3,D6			* Make local copy
		ANDI.L	#$00000001,D6		* Mask
		CMPI.B	#$1,D6			* Check for odd address	
		BEQ	PRINT_Er_3		* Print error
		
		JSR	TO_OPCODE_END		* Sending user input end address to Op-Code
		
		BRA	QUIT_END		* OK
		
INVL_Er_ASCII	BSR	INVAL_ASCII_ERR		* Jump to print error
		CLR.L	D7			* Clear the bad data for the next try
		BRA	AGAIN			* Start over

PRINT_Er_6	BSR	PRINT_ERROR_6		* Jump to print error
		BRA	AGAIN			* Start over
		
PRINT_Er_2	BSR	PRINT_ERROR_2		* Jump to print error			
		BRA	AGAIN			* Start Over

PRINT_Er_3	BSR	PRINT_ERROR_3		* Jump to print error
		BRA	AGAIN			* Start over
		
PRINT_Er_7	BSR	PRINT_ERROR_7		* Jump to print error
		BRA	AGAIN			* Start over		
		
QUIT_END	LEA	user_end_addr,A3	* Load address of location to store valid address
		MOVE.L	D3,(A3)			* Save the valid user input	
		MOVEM.L (SP)+,reg_set_1		* Restore registers
		RTS

**************************************************************
* Sub-routine: TO_OPCODE_END
* Description: Sends the ending address to Op-Code
*
**************************************************************
TO_OPCODE_END	MOVE.L	D3,A6			* Send ending address to Op-Code

		RTS

**************************************************************
* Sub-routine: PRINT_HEADER
* Description: This method will display the header in the following format:
*		ADDRESS			DATA WRITTEN		DATA READ
*
*API:
* D0 holds the TRAP #15 mode
* D1 holds the TRAP #15 string lenght
* A1 holds the TRAP #15 string starting address
* A5 holds the address that the bad data is located
* A5 points to the bad data found
* D5 holds the data that should have been found
**************************************************************
PRINT_HEADER	MOVE.B	#task1,D0		* load the task
		LEA	blank_line,A1		* load blank string
		MOVE.W	blank_line_len,D1	* get length
		TRAP	#15			* Print screen
	
		RTS				* Return to calling method
	
**************************************************************
* Sub-routine: PRINT_GOOD_DATA
* Description: This method will display the decoded instructions
*
*API:
* D0 holds the TRAP #15 mode
* D1 holds the TRAP #15 string lenght
* A1 holds the TRAP #15 string starting address
* A5 holds the address that the bad data is located
* A5 points to the bad data found
* D5 holds the data that should have been found
**************************************************************
PRINT_GOOD_DATA	MOVEM.L	reg_set_1,-(SP)		* save main registers on stack so they can be reused
		
		CLR.L	D0			* Clear D0
		CLR.L	D1			* Clear D1
		CLR.L	D3			* Clear D3
		
		LEA	crg_return,A0		* Load the address of the $0D (carriage return) into A0
		MOVE.B	(A0),(A4)+		* Update the buffer and advance pointer
		LEA	line_feed,A0		* Load the address of the $0A (line feed) into A0
		MOVE.B	(A0),(A4)+		* Update the buffer and advance pointer	
		
		MOVE.B	#task1,D0		* load the task
		LEA	good_buf,A1		* load good buf
		MOVE.L	A4,D3			* Copy ending address
		SUB.L	A1,D3			* Get length
		MOVE.L	D3,D1			* Put lenght in D1
		TRAP	#15			* print to screen
		
QUIT_GD		MOVEM.L (SP)+,reg_set_1		* restore registers
GD_RTS		RTS				* return, we're done



**************************************************************
* Sub-routine: PRINT_BAD_DATA
* Description: This method will display the bad data found in the following format:
*		ADDRESS	    DATA	Hexadecinal not decoded
*
*API:
* D0 holds the TRAP #15 mode
* D1 holds the TRAP #15 string lenght
* A1 holds the TRAP #15 string starting address
* A5 holds the address that the bad data is located
* A5 points to the bad data found
* D5 holds the data that should have been found
**************************************************************
PRINT_BAD_DATA	MOVEM.L	reg_set_1,-(SP)		* save main registers on stack so they can be reused
		
		CLR.L	D0			* Clear D0
		CLR.L	D1			* Clear D1
		CLR.L	D3			* Clear D3
	
		LEA	crg_return,A0		* Load the address of the $0D (carriage return) into A0
		MOVE.B	(A0),(A6)+		* Update the buffer and advance pointer
		LEA	line_feed,A0		* Load the address of the $0A (line feed) into A0
		MOVE.B	(A0),(A6)+		* Update the buffer and advance pointer	
			
		MOVE.B	#task1,D0		* load the type of TRAP #15 task
		LEA	bad_buf,A1		* load the starting address of the string
		MOVE.L	A6,D3			* Put address of the end of the string into D2
		SUB.L	A1,D3			* Get string length
		MOVE.L	D3,D1			* Set up trap
		TRAP	#15			* print to screen
				
QUIT_PBD	MOVEM.L (SP)+,reg_set_1		* restore registers
		RTS				* return, we're done

**************************************************************
* Sub-routine: PRINT_LINE
* Description: When decoded instructions filled one page, user would be prompt
*		to either continue with decoding to quite completely
*
*API:
* D0 holds the TRAP #15 mode
* D1 holds the TRAP #15 string lenght
* A1 holds the TRAP #15 string starting address
* A5 holds the address that the bad data is located
* A5 points to the bad data found
* D5 holds the data that should have been found
**************************************************************
PRINT_LINE	MOVE.B	#task0,D0		* Load task into D0
		LEA	prnt_ln_lmt,A1		* load line limit to A1
		MOVE.W	prnt_ln_lmt_len,D1	* Get lenghth of the string
		TRAP	#15			* Print to screen
		
PR_LINE_LOOP	MOVE.B	#task2,D0		* Load input TRAP #15 task into D0
		LEA	user_input,A1		* Load starting address of memory for input
		MOVE.W	user_input_len,D1	* Get allowed length for user input
		TRAP	#15			* Get user input
				
		CMPI.B	#$51,(A1)		* User entered Q
		BEQ	QUIT			* If Q then QUIT
		CMPI.B	#$71,(A1)		* User entered q	
		BEQ	QUIT			* If q then QUIT
		CMPI.B	#$59,(A1)		* User entered Y
		BEQ	CONTINUE		* If Y then CONTINUE
		CMPI.B	#$79,(A1)		* User entered y
		BEQ	CONTINUE		* If y then CONTINUE
		BSR	PRINT_ERROR_8		* If this line is reached print an error
		BRA	PR_LINE_LOOP		* Get user input again			
				
CONTINUE	LEA	line_counter,A5		* Load the loacation that the number of lines printed to the screen is stored
		CLR.W	(A5)			* Reset the counter to zero
		RTS

**************************************************************
* Sub-routine: ANOTHER_MEM_
* Description: Prompt a client to ask if the would like to disassemble 
*		another memory location or not.
*
*API:
* D0 holds the TRAP #15 mode
* D1 holds the TRAP #15 string lenght
* A1 holds the TRAP #15 string starting address
* A5 holds the address that the bad data is located
* A5 points to the bad data found
* D5 holds the data that should have been found
**************************************************************
ANOTHER_MEM_	MOVEM.L	reg_set_2,-(SP)		* Save main registers on stack so they can be reused

		MOVE.B	#task0,D0		* load the task
		LEA	blank_line,A1		* load blank string
		MOVE.W	blank_line_len,D1	* get length
		TRAP	#15			* Print screen
		
		MOVE.B	#task0,D0		* Load task into D0
		LEA	another_mem,A1		* load line limit to A1
		MOVE.W	another_mem_len,D1	* Get lenghth of the string
		TRAP	#15			* Print to screen
		
PR_MEM_LOOP	MOVE.B	#task2,D0		* Load input TRAP #15 task into D0
		LEA	user_input,A1		* Load starting address of memory for input
		MOVE.W	user_input_len,D1	* Get allowed length for user input
		TRAP	#15			* Get user input
				
		CMPI.B	#$4E,(A1)		* User entered N
		BEQ	QUIT			* If N then QUIT
		CMPI.B	#$6E,(A1)		* User entered n	
		BEQ	QUIT			* If n then QUIT
		CMPI.B	#$59,(A1)		* User entered Y
		BEQ	CONTINUE_MEM		* If Y then CONTINUE
		CMPI.B	#$79,(A1)		* User entered y
		BEQ	CONTINUE_MEM		* If y then CONTINUE
		BSR	PRINT_ERROR_8		* If this line is reached print an error
		BRA	PR_MEM_LOOP		* Get user input again			
				
CONTINUE_MEM	LEA	line_counter,A5		* Load the loacation that the number of lines printed to the screen is stored
		CLR.W	(A5)			* Reset the counter to zero
		MOVEM.L (SP)+,reg_set_2		* restore registers

		RTS

**************************************************************
* Sub-routine: ARE_U_SURE
* Description: Prompt a client to ask if they are sure to compeletly
*		exit the program or try another memory location
*
*API:
* D0 holds the TRAP #15 mode
* D1 holds the TRAP #15 string lenght
* A1 holds the TRAP #15 string starting address
* A5 holds the address that the bad data is located
* A5 points to the bad data found
* D5 holds the data that should have been found
**************************************************************
ARE_U_SURE	MOVE.B	#task0,D0		* load the task
		LEA	blank_line,A1		* load blank string
		MOVE.W	blank_line_len,D1	* get length
		TRAP	#15			* Print screen
		
		MOVE.B	#task0,D0		* Load task into D0
		LEA	are_sure,A1		* load line limit to A1
		MOVE.W	are_sure_len,D1	* Get lenghth of the string
		TRAP	#15			* Print to screen
		
PR_MEM_LOOP_	MOVE.B	#task2,D0		* Load input TRAP #15 task into D0
		LEA	user_input,A1		* Load starting address of memory for input
		MOVE.W	user_input_len,D1	* Get allowed length for user input
		TRAP	#15			* Get user input
				
		CMPI.B	#$4E,(A1)		* User entered N
		BEQ	ANOTH_START_		* If N then QUIT
		CMPI.B	#$6E,(A1)		* User entered n	
		BEQ	ANOTH_START_		* If n then QUIT
		CMPI.B	#$59,(A1)		* User entered Y
		BEQ	QUIT_DONE		* If Y then CONTINUE
		CMPI.B	#$79,(A1)		* User entered y
		BEQ	QUIT_DONE		* If y then CONTINUE
		BSR	PRINT_ERROR_5		* If this line is reached print an error
		BRA	PR_MEM_LOOP_		* Get user input again			

		
**************************************************************
* Sub-routine: MEM_TO_ASCII 
* Description: 
* Registers	:	A0 stores the address of the bad address buffer
*			D0 stores address data to be converted to ascii
*			D1 stores a copy of D0 to be masked
*			D2 stores the dynamic mask 
*			D3 stores the number of asciis to convert
*			D4 stores the counter
**************************************************************
MEM_TO_ASCII	MOVEM.L	reg_set_head,-(SP)	* save main registers on stack so they can be reused
		CLR.L	D4			* clear the counter, reach 8 and we're done
		MOVE.L	#$0000000F,D2		* use a mask to isolate one hex value at a time
		CMPI.B	#$4,D3			* are we converting a word of data?
		BGT	MTA_LOOP		* no? start looping then
		ROL.L	#8,D0			* rotate first byte to account for word values
		ROL.L	#8,D0			* rotate second byte to account for word values
MTA_LOOP	ROL.L	#4,D0			* rotate to the next hex value
		MOVE.L	D0,D1			* create a copy to manipulate
		AND.L	D2,D1			* clear the nibbles we don't care about stuff
		BSR	HEX_TO_ASCII		* convert the nibble to ascii
		MOVE.B	D1,(A0)+		* store the char  
		ADD.B	#1,D4			* increment the counter
		CMP.B	D3,D4			* have we reached the end?
		BLT	MTA_LOOP		* no? then loop
		BRA	MTA_DONE		* yes? then we're done
MTA_DONE	MOVEM.L (SP)+,reg_set_head	* restore registers
		RTS		

**************************************************************
* Sub-routine: ASCII_TO_MEM
* Description: This sub-routine will read in a word of memory at a time
*		that has been filled with ASCII char input. Then it will
*		convert the ASCII into Hex that is viewable in memory 
*		(although it is actually encoded in binary). It will save the
*		converted user input in memory.
*
*API:
* A1 Points to the start of the user input
* D0 (RETURN) holds flag for bad address
* D1 holds ascii char to be converted to hex
* D2 holds position multiplier
* D3 (RETURN) holds final address
* D4 counter, reach 8 and we're done
**************************************************************
ASCII_TO_MEM	MOVEM.L	reg_set_6,-(SP)		* Save main registers on stack so they can be reused by sub
		CLR.L	D0
		CLR.L	D1
		CLR.L	D2			* setup position multiplier
		CLR.L	D3			* clear D3
		CLR.L	D4			* clear the counter,reach 8 and we're done
		MOVE.B	#$4,D2			* statrt position multiplier
		LEA	user_input,A1		* point A1 at the user input
ASCII_LOOP	MOVE.B	(A1)+,D1		* move first byte of string into working register
		BSR	ASCII_TO_HEX		* pass D1 to convert the ascii value to hex
		CMPI.B	#$0,D4			* are we trying to shift by zero?
		BEQ	SKIP_SHIFT		* yes? skip shifting the digit
		ASL.L	D2,D3			* shift digit into position
SKIP_SHIFT	ADD.L	D1,D3			* add next digit to address
		CLR	D1			* Clear the ascii buffer
		ADD.L	#$1,D4			* increment counter
		CMP.B	#space_char,(A1) 	* have we hit a space char?	  
		BEQ	ATM_DONE		* kill the loop , we're done
		CMPI.B	#8,D4 			* have we loaded 8 characters?
		BLT	ASCII_LOOP		* No?  Then keep reading
		BRA	ATM_DONE		* Yes?  then we're done
ATM_DONE	MOVEM.L	(SP)+,reg_set_6		* Restore registers before leaving sub

		RTS

**************************************************************
* Sub-routine: ASCII_TO_HEX
* Description: 
* Parameters : D1 - stores ascii (byte)char to convert to hex
* API:
* **************************************************************
ASCII_TO_HEX	CMPI.B	#ascii_num_0,D1		* less than ascii 0?
		BLT	ERROR			* out of boundry character used
		CMPI.B	#ascii_num_9,D1		* less than ascii 0?
		BLE	CVT_NUM			* yes? then its in range so convert
		CMPI.B	#ascii_num_A,D1		* less than ascii A?
		BLT	ERROR			* yes? out of boundry character used
		CMPI.B	#ascii_num_F,D1		* less than ascii F?
		BLE	CVT_U_ALPHA		* yes? then its in range so convert
		CMPI.B	#ascii_num_al,D1	* Less than ascii a?
		BLT	ERROR			* yes? out of boundry character used
		CMPI.B	#ascii_num_fl,D1	* Less than ascii F?
		BLE	CVT_L_ALPHA		* yes? then its in range so convert
		BRA	ERROR 			* no?, out of boundry character used
CVT_NUM		SUBI.B	#ascii_num_0,D1		* convert ascii num to hex num
		BRA	DONE			* done
CVT_U_ALPHA	SUBI.B	#55,D1			* convert ascii upper alpha to hex num
		BRA	DONE			* done
CVT_L_ALPHA	SUBI.B	#87,D1			* convert ascii lower alpha
		BRA	DONE			* done
DONE		RTS				* return
ERROR		MOVE.B	#$1,D7			*set fail bit (bad address)
		BRA	DONE

**************************************************************
* Sub-routine: HEX_TO_ASCII
* Description: 
* Parameters : D1 - stores ascii (byte)char to convert to hex
* API:
* **************************************************************
HEX_TO_ASCII	CMPI.B	#9,D1			* Less than ascii 0?
		BLE	CVT_NUM_A		* convert to a ascii number
		BRA	CVT_ALPHA_A  		* convert to an ascii hex A-F
CVT_NUM_A	ADDI.B	#48,D1			* convert to ascii
		BRA	HTA_DONE		* done
CVT_ALPHA_A	ADDI.B	#55,D1			* convert to ascii
		BRA	HTA_DONE		* done
HTA_DONE		RTS			* return

		

********************************************************************************************************************************
********************************************************* ERRORS ***************************************************************
********************************************************************************************************************************

**************************************************************
* Sub-routine: INVAL_ASCII_ERR
* Description: This method will display and error message indicateing an invalid
*	       starting address has been entered in the following format:
*	       "Error: Use only characters (0-9), (A-F) or (a-f)"
*
*API:
* D0 holds the TRAP #15 mode
* D1 holds the TRAP #15 string lenght
* A1 holds the TRAP #15 string starting address
**************************************************************
INVAL_ASCII_ERR	MOVEM.L	reg_set_1,-(SP)		* Save main registers on stack so they can be reused

		MOVE.B	#task0,D0		* Load the type of TRAP #15 task
		LEA	inval_ascii,A1		* Load the starting address of the string
		MOVE.W	inval_ascii_len,D1	* Get the length of the string
		TRAP	#15			* Print to screen

		MOVEM.L (SP)+,reg_set_1		* Restore registers
		RTS

**************************************************************
* Sub-routine: PRINT_ERROR_1
* Description: This method will display and error message indicateing an invalid
*	       starting address has been entered in the following format:
*	       "Must enter a starting address >= 00000400 and less than 000FFFFF"
*
*API:
* D0 holds the TRAP #15 mode
* D1 holds the TRAP #15 string lenght
* A1 holds the TRAP #15 string starting address
* A3 Points to the minimum starting address
* A4 Points to the maximim ending address
**************************************************************
PRINT_ERROR_1	MOVEM.L	reg_set_1,-(SP)		* Save main registers on stack so they can be reused

		MOVE.B	#task0,D0		* Load the type of TRAP #15 task
		LEA	error_1,A1		* Load the starting address of the string
		MOVE.W	error_1_len,D1		* Get the length of the string
		TRAP	#15			* Print to screen

QUIT_ERROR_1	MOVEM.L (SP)+,reg_set_1		* Restore registers
		RTS

**************************************************************
* Sub-routine: PRINT_ERROR_2
* Description: This method will display and error message indicateing an invalid
*	       ending address has been entered in the following format:
*	       "Must enter a starting address >= greater (their entered startign address) and less than 000FFFFF"
*
*API:
* D0 holds the TRAP #15 mode
* D1 holds the TRAP #15 string lenght
* A1 holds the TRAP #15 string starting address
* A3 Points to the minimum starting address
* A4 Points to the maximim ending address
**************************************************************
PRINT_ERROR_2	MOVEM.L	reg_set_1,-(SP)		* Save main registers on stack so they can be reused

		MOVE.B	#task0,D0		* Load the type of TRAP #15 task
		LEA	error_2,A1		* Load the starting address of the string
		MOVE.W	error_2_len,D1		* Get the length of the string
		TRAP	#15			* Print to screen

QUIT_ERROR_2	MOVEM.L (SP)+,reg_set_1		* Restore registers
		RTS

**************************************************************
* Sub-routine: PRINT_ERROR_3
* Description: This method will display and error message indicateing an invalid
*	       test word has been entered in the following format:
*	       "The test word must be exactly 4 characters and must be made up from 0-9, A-f, a-f"
*
*API:
* D0 holds the TRAP #15 mode
* D1 holds the TRAP #15 string lenght
* A1 holds the TRAP #15 string starting address
*
**************************************************************
PRINT_ERROR_3	MOVEM.L	reg_set_1,-(SP)		* Save main registers on stack so they can be reused

		MOVE.B	#task0,D0		* Load the type of TRAP #15 task
		LEA	error_3,A1		* Load the starting address of the string
		MOVE.W	error_3_len,D1		* Get the length of the string
		TRAP	#15			* Print to screen

QUIT_ERROR_3	MOVEM.L (SP)+,reg_set_1		* Restore registers
		RTS

**************************************************************
* Sub-routine: PRINT_ERROR_4
* Description: This method will display and error message indicateing an invalid
*	       test word has been entered in the following format:
*	       "The test word must be exactly 4 characters and must be made up from 0-9, A-f, a-f"
*
*API:
* D0 holds the TRAP #15 mode
* D1 holds the TRAP #15 string lenght
* A1 holds the TRAP #15 string starting address
*
**************************************************************
PRINT_ERROR_4	MOVEM.L	reg_set_1,-(SP)		* Save main registers on stack so they can be reused

		MOVE.B	#task0,D0		* Load the type of TRAP #15 task
		LEA	error_4,A1		* Load the starting address of the string
		MOVE.W	error_4_len,D1		* Get the length of the string
		TRAP	#15			* Print to screen

QUIT_ERROR_4	MOVEM.L (SP)+,reg_set_1		* Restore registers
		RTS
		
**************************************************************
* Sub-routine: PRINT_ERROR_5
* Description: This method will display and error message indicateing a
*	       bad user entry:
*	       "Error 8: Please enter either Y or N"
*
*API:
* D0 holds the TRAP #15 mode
* D1 holds the TRAP #15 string lenght
* A1 holds the TRAP #15 string starting address
*
**************************************************************
PRINT_ERROR_5	MOVEM.L	reg_set_1,-(SP)		* Save main registers on stack so they can be reused

		MOVE.B	#task0,D0		* Load the type of TRAP #15 task
		LEA	error_5,A1		* Load the starting address of the string
		MOVE.W	error_5_len,D1		* Get the length of the string
		TRAP	#15			* Print to screen

QUIT_ERROR_5	MOVEM.L (SP)+,reg_set_1		* Restore registers
		RTS
		
**************************************************************
* Sub-routine: PRINT_ERROR_6
* Description: This method will display and error message indicateing a
*	       bad ending address has been entered in the following format:
*	       "Error 6: The ending address must come after the starting address "
*
*API:
* D0 holds the TRAP #15 mode
* D1 holds the TRAP #15 string lenght
* A1 holds the TRAP #15 string starting address
*
**************************************************************		
PRINT_ERROR_6	MOVEM.L	reg_set_1,-(SP)		* Save main registers on stack so they can be reused

		MOVE.B	#task0,D0		* Load the type of TRAP #15 task
		LEA	error_6,A1		* Load the starting address of the string
		MOVE.W	error_6_len,D1		* Get the length of the string
		TRAP	#15			* Print to screen

		MOVEM.L (SP)+,reg_set_1		* Restore registers
		RTS				* Return
	
**************************************************************
* Sub-routine: PRINT_ERROR_7
* Description: This method will display and error message indicateing a
*	       bad ending address has been entered in the following format:
*	       "Error 7: the address is out of specified range "
*
*API:
* D0 holds the TRAP #15 mode
* D1 holds the TRAP #15 string lenght
* A1 holds the TRAP #15 string starting address
*
**************************************************************		
PRINT_ERROR_7	MOVEM.L	reg_set_1,-(SP)		* Save main registers on stack so they can be reused

		MOVE.B	#task0,D0		* Load the type of TRAP #15 task
		LEA	error_7,A1		* Load the starting address of the string
		MOVE.W	error_7_len,D1		* Get the length of the string
		TRAP	#15			* Print to screen

		MOVEM.L (SP)+,reg_set_1		* Restore registers
		RTS				* Return
		
**************************************************************
* Sub-routine: PRINT_ERROR_8
* Description: This method will display and error message indicateing a
*	       bad prompt:
*	       "Error 8: Please enter either Y or Q"
*
*API:
* D0 holds the TRAP #15 mode
* D1 holds the TRAP #15 string lenght
* A1 holds the TRAP #15 string starting address
*
**************************************************************				
		MOVE.W	#lea_rt_fl,(A1)	* Save the flag for where to return to	
PRINT_ERROR_8	MOVEM.L	reg_set_1,-(SP)		* Save main registers on stack so they can be reused

		MOVE.B	#task0,D0		* Load the type of TRAP #15 task
		LEA	error_8,A1		* Load the starting address of the string
		MOVE.W	error_8_len,D1		* Get the length of the string
		TRAP	#15			* Print to screen

		MOVEM.L (SP)+,reg_set_1		* Restore registers
		RTS				* Return



*******************************************************************
*
* Sub-routine	: MAIN_OP
* Description	: The Opcode portion of the dissasembler handles the decoding of the
*		actual opcode word. It has no knowlage of the functionality of the I/O portion 
* 		of the program or the EA prtion of the program. The opcode section only decodes
* 		the opcode and passes a good, bad, or end flag back to the I/O person along
* 		with a pointer to the input buffer that has been filled by the opcode and EA
* 		person.
*
* Note: The jump table code was borrorwed from the assignment specs, written by Arnie Berger
*
* API:
* D4 is the flag passing register between the I/O, Opcode and EA
* A0 is used to help store ending address, and holds the address of the jump table
* A3 Points to the next word in memory to be decoded
* A4 Points to the possition that can be written to in the output buffer
* A5 (used only first time through algorithm) to initialize A3 points to the starting address of the memory image 
* A6 (used onlu first time through algorithm) Points to the last word in the memory image 
*
*******************************************************************
MAIN_OP		MOVE.W	(A3)+,D0		* Make first local copy of word to decode and advance the pointer
		MOVE.W	D0,D1			* Make a second local copy of the word to decode
		ANDI.L	#mask12_15,D1		* Mask off bits 12-15				
		MOVE.B	#shift12,D2		* Put the shift value into D2
		LSR.W	D2,D1			* Move D1 bits 12-15 into 0-3
		
		LEA	JUMP_TABLE,A0		* Load the address of the jump table into A0
		MULU	#jmp_offset,D1		* Multiply by jump table offset of 6 bytes
		JSR	00(A0,D1)		* jump indirect with index


****************************************************************************
* Sub-routine	: JUMP_TABLE
* Description	:
* This code controls the branching to various algorithms that are necessairy to decode 
* the opcode.
*****************************************************************************
JUMP_TABLE	JMP	CODE0000
		JMP	CODE0001
		JMP	CODE0010
		JMP	CODE0011
		JMP	CODE0100
		JMP	CODE0101
		JMP	CODE0110
		JMP	CODE0111
		JMP	CODE1000
		JMP	CODE1001
		JMP	CODE1010
		JMP	CODE1011
		JMP	CODE1100
		JMP	CODE1101
		JMP	CODE1110
		JMP	CODE1111


****************************************************************************
* Sub-routine	: CODE0000
* Description	:This the section of the jump table that deals with  the immediate opcodes. They have
*			the pattern %0000 in bits 12-15
*****************************************************************************
CODE0000	CLR.L	D1		* Make sure the working register is clear to start
		CLR.L	D2		* Make sure D2 is clear
		MOVE.W	D0,D1		* Put a copy of the word into D1
		ANDI.L	#mask8_11,D1	* Mask off bits 8-11
		MOVE.B	#shift8,D2	* Put the shift value into D2
		LSR.W	D2,D1		* Shift bits 8-11 into 0-3
		CLR.L	D2		* Clear D2
		ADDI.B	#%0000,D2	* Put test pattern %0000 into D2
		CMP.B	D2,D1		* Is this ORI?
		BEQ	OP_ORI		* Deal with ORI
		ADDI.B	#%0010,D2	* Put test pattern %0010 into D2
		CMP.B	D2,D1		* Is this ANDI?
		BEQ	OP_ANDI		* Deal with ANDI
		CLR.L	D2		* Clear D2
		ADDI.B	#%0100,D2	* Put test pattern %0100 into D2
		CMP.B	D2,D1		* Is this SUBI?
		BEQ	OP_SUBI		* Deal with SUBI
		CLR.L	D2		* Clear D2
		ADDI.B	#%0110,D2	* Put test pattern %0110 into D2
		CMP.B	D2,D1		* Is this ADDI?
		BEQ	OP_ADDI		* Deal with ADDI
		CLR.L	D2		* Clear D2
		ADDI.B	#%1010,D2	* Put test pattern %1010 into D2
		CMP.B	D2,D1		* Is this EORI?
		BEQ	OP_EORI		* Deal with EORI
		CLR.L	D2		* Clear D2
		ADDI.B	#%1100,D2	* Put test pattern %1100 into D2
		CMP.B	D2,D1		* Is this CMPI?
		BEQ	OP_CMPI		* Deal with CMPI
		BRA	CHECK_MOVEP	* If not one of the above choices, check for MOVEP or DATA

CHECK_MOVEP	BRA	SET_BAD_FLAG	*  *** NOT IMPLEMENTED! NOT RQUIRED! ***


*****************************************************************************************
* ORI	: ORI is added to the buffer below
*****************************************************************************************
OP_ORI		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#ori_rt_fl,(A1)	* Save the flag for where to return to		
		LEA	ori,A0		* Load the address of the 'A0' string into A0
		LEA	ori_len,A1	* Load the address of the end of the string
LOOP_ORI	MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LOOP_ORI	* Get next ASCII	
		JSR	PRINT_SIZE	* Print the size field if the size != 11
		CMPI.W	#bad_flag,D1	* Check for bad flag
		BEQ	SET_BAD_FLAG	* If size is invalid the opcode is invalid
		JSR	N_PRINT_SPACE	* Call ' ' printing method
		JSR	PRINT_POUND	* Call '#' printing method
		JSR	LOAD_IMMED_CODE	* Load the fake immediate code into D4
		CMPI.W	#bad_flag,D1	* Check for bad flag
		BEQ	SET_BAD_FLAG	* If size is invalid the opcode is invalid
		JMP	TO_BRYAN	* Pass control to EA
RT_ORI		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#no_more_wk,(A1) * Save the flag for where to return to
		JSR	PRINT_COMMA	* Call ',' printing method
		CLR.L	D4		* Make sure the flag passing register is clear
		MOVE.W	D0,D4		* Put the bits to be passed to EA into D4
		ANDI.L	#mask0_5,D4	* Mask off bits 0-5
		JMP	TO_BRYAN	* Pass control to EA

*****************************************************************************************
* ANDI	: ANDI is added to the buffer below
*****************************************************************************************
OP_ANDI		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#andirt_fl,(A1)	* Save the flag for where to return to		
		LEA	andi,A0		* Load the address of the 'A0' string into A0
		LEA	andi_len-1,A1	* Load the address of the end of the string
LOOP_ANDI	MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LOOP_ANDI	* Get next ASCII	
		JSR	PRINT_SIZE	* Print the size field if the size != 11
		CMPI.W	#bad_flag,D1	* Check for bad flag
		BEQ	SET_BAD_FLAG	* If size is invalid the opcode is invalid
		JSR	N_PRINT_SPACE	* Call ' ' printing method
		JSR	PRINT_POUND	* Call '#' printing method
		JSR	LOAD_IMMED_CODE	* Load the fake immediate code into D4
		CMPI.W	#bad_flag,D1	* Check for bad flag
		BEQ	SET_BAD_FLAG	* If size is invalid the opcode is invalid
		JMP	TO_BRYAN	* Pass control to EA
RT_ANDI		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#no_more_wk,(A1) * Save the flag for where to return to
		JSR	PRINT_COMMA	* Call ',' printing method
		CLR.L	D4		* Make sure the flag passing register is clear
		MOVE.W	D0,D4		* Put the bits to be passed to EA into D4
		ANDI.L	#mask0_5,D4	* Mask off bits 0-5
		JMP	TO_BRYAN	* Pass control to EA


*****************************************************************************************
* SUBI	: SUBI is added to the buffer below
*****************************************************************************************
OP_SUBI		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#subirt_fl,(A1)	* Save the flag for where to return to		
		LEA	subi,A0		* Load the address of the 'A0' string into A0
		LEA	subi_len-1,A1	* Load the address of the end of the string
LOOP_SUBI	MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LOOP_SUBI	* Get next ASCII	
		JSR	PRINT_SIZE	* Print the size field if the size != 11
		CMPI.W	#bad_flag,D1	* Check for bad flag
		BEQ	SET_BAD_FLAG	* If size is invalid the opcode is invalid
		JSR	N_PRINT_SPACE	* Call ' ' printing method
		JSR	PRINT_POUND	* Call '#' printing method
		JSR	LOAD_IMMED_CODE	* Load the fake immediate code into D4
		CMPI.W	#bad_flag,D1	* Check for bad flag
		BEQ	SET_BAD_FLAG	* If size is invalid the opcode is invalid
		JMP	TO_BRYAN	* Pass control to EA
RT_SUBI		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#no_more_wk,(A1) * Save the flag for where to return to
		JSR	PRINT_COMMA	* Call ',' printing method
		CLR.L	D4		* Make sure the flag passing register is clear
		MOVE.W	D0,D4		* Put the bits to be passed to EA into D4
		ANDI.L	#mask0_5,D4	* Mask off bits 0-5
		JMP	TO_BRYAN	* Pass control to EA


*****************************************************************************************
* ADDI	: ADDI is added to the buffer below
*****************************************************************************************
OP_ADDI		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#addirt_fl,(A1)	* Save the flag for where to return to		
		LEA	addi,A0		* Load the address of the 'A0' string into A0
		LEA	addi_len-1,A1	* Load the address of the end of the string
LOOP_ADDI	MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LOOP_ADDI	* Get next ASCII	
		JSR	PRINT_SIZE	* Print the size field if the size != 11
		CMPI.W	#bad_flag,D1	* Check for bad flag
		BEQ	SET_BAD_FLAG	* If size is invalid the opcode is invalid
		JSR	N_PRINT_SPACE	* Call ' ' printing method
		JSR	PRINT_POUND	* Call '#' printing method
		JSR	LOAD_IMMED_CODE	* Load the fake immediate code into D4
		CMPI.W	#bad_flag,D1	* Check for bad flag
		BEQ	SET_BAD_FLAG	* If size is invalid the opcode is invalid
		JMP	TO_BRYAN	* Pass control to EA
RT_ADDI		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#no_more_wk,(A1) * Save the flag for where to return to
		JSR	PRINT_COMMA	* Call ',' printing method
		CLR.L	D4		* Make sure the flag passing register is clear
		MOVE.W	D0,D4		* Put the bits to be passed to EA into D4
		ANDI.L	#mask0_5,D4	* Mask off bits 0-5
		JMP	TO_BRYAN	* Pass control to EA


*****************************************************************************************
* EORI	: EORI is added to the buffer below
*****************************************************************************************
OP_EORI		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#eorirt_fl,(A1)	* Save the flag for where to return to		
		LEA	eori,A0		* Load the address of the 'A0' string into A0
		LEA	eori_len-1,A1	* Load the address of the end of the string
LOOP_EORI	MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LOOP_EORI	* Get next ASCII	
		JSR	PRINT_SIZE	* Print the size field if the size != 11
		CMPI.W	#bad_flag,D1	* Check for bad flag
		BEQ	SET_BAD_FLAG	* If size is invalid the opcode is invalid
		JSR	N_PRINT_SPACE	* Call ' ' printing method
		JSR	PRINT_POUND	* Call '#' printing method
		JSR	LOAD_IMMED_CODE	* Load the fake immediate code into D4
		CMPI.W	#bad_flag,D1	* Check for bad flag
		BEQ	SET_BAD_FLAG	* If size is invalid the opcode is invalid
		JMP	TO_BRYAN	* Pass control to EA
RT_EORI		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#no_more_wk,(A1) * Save the flag for where to return to
		JSR	PRINT_COMMA	* Call ',' printing method
		CLR.L	D4		* Make sure the flag passing register is clear
		MOVE.W	D0,D4		* Put the bits to be passed to EA into D4
		ANDI.L	#mask0_5,D4	* Mask off bits 0-5
		JMP	TO_BRYAN	* Pass control to EA


*****************************************************************************************
* CMPI	: CMPI is added to the buffer below
*****************************************************************************************
OP_CMPI		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#cmpirt_fl,(A1)	* Save the flag for where to return to		
		LEA	cmpi,A0		* Load the address of the 'A0' string into A0
		LEA	cmpi_len-1,A1	* Load the address of the end of the string
LOOP_CMPI	MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LOOP_CMPI	* Get next ASCII	
		JSR	PRINT_SIZE	* Print the size field if the size != 11
		CMPI.W	#bad_flag,D1	* Check for bad flag
		BEQ	SET_BAD_FLAG	* If size is invalid the opcode is invalid
		JSR	N_PRINT_SPACE	* Call ' ' printing method
		JSR	PRINT_POUND	* Call '#' printing method
		JSR	LOAD_IMMED_CODE	* Load the fake immediate code into D4
		CMPI.W	#bad_flag,D1	* Check for bad flag
		BEQ	SET_BAD_FLAG	* If size is invalid the opcode is invalid
		JMP	TO_BRYAN	* Pass control to EA
RT_CMPI		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#no_more_wk,(A1) * Save the flag for where to return to
		JSR	PRINT_COMMA	* Call ',' printing method
		CLR.L	D4		* Make sure the flag passing register is clear
		MOVE.W	D0,D4		* Put the bits to be passed to EA into D4
		ANDI.L	#mask0_5,D4	* Mask off bits 0-5
		JMP	TO_BRYAN	* Pass control to EA


*****************************************************************************************
* MOVEP	: MOVEP is added to the buffer below
*****************************************************************************************	
OP_MOVEP	BRA	SET_BAD_FLAG	* *** NOT IMPLEMENTED! NOT RQUIRED! ***


****************************************************************************
* Sub-routine	: CODE0001
* Description	:
* This is the algorithm for decoding MOVE.B
*****************************************************************************
CODE0001	LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#move_b_fl,(A1)	* Save the flag for where to return to
		BSR	MOVE_HELPER	* Add 'MOVE.' to the string
		BSR	PRINT_B		* ADD 'B' to the string	
		MOVE.B	#$20,(A4)+	* ADD ' ' to string
		BSR	MASK_0_5	* Mask off 0-5 and put in D4
		JMP	TO_BRYAN	* Pass control to EA

RT_MOVE_B	LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#no_more_wk,(A1) * Save the flag for where to return to	
		BSR	PRINT_COMMA	* Add the camma to the buffer
		CLR.L	D1		* Make sure the working register is clear to start
		CLR.L	D2		* Make sure D2 is clear
		MOVE.W	D0,D1		* Put a copy of the word into D1
		ANDI.L	#mask9_11,D1	* Mask off bits 9-11
		MOVE.B	#shift9,D2	* Put the shift value into D2
		LSR.W	D2,D1		* Shift bits 9-11 into 0-2
		CLR.L	D2		* Clear D2
		CLR.L	D3		* Clear D3
		MOVE.W	D1,D3		* Move the register number to bits 0-2 of D3
		CLR.L	D1		* Clear D1
		MOVE.W	D0,D1		* Reload the test word
		ANDI.L	#mask6_8,D1	* Mask off 6-8
		MOVE.B	#shift3,D2	* Load the shift value
		LSR.W	D2,D1		* Shift bits 6-8 into 3-5
		ADD.L	D3,D1		* Combine regiters to put EA in proper format
		MOVE.L	D1,D4		* Load the EA bits into D4
		JMP	TO_BRYAN	* Pass control to EA


*****************************************************************************
* Sub-routine	: MOVE_HELPER
* Description	:
*	Add 'MOVE.' character to the buffer
*
* API:
* A0 holds the address of the 'MOVE.' string
* A1 holds the address of the end of the 'MOVE.' string
* A4 holds the address to be written to in the buffer
*****************************************************************************
MOVE_HELPER	LEA 	move,A0		* Load the addres of 'B' into A0
		LEA	move_len-1,A1	* Load the address of the end of string
M_LOOP		MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	M_LOOP		* Get next ASCII (for safty)
		RTS


*****************************************************************************
* Sub-routine	: MOVEA_HELPER
* Description	:
*	Add 'MOVE.' character to the buffer
*
* API:
* A0 holds the address of the 'MOVE.' string
* A1 holds the address of the end of the 'MOVE.' string
* A4 holds the address to be written to in the buffer
*****************************************************************************
MOVEA_HELPER	LEA 	movea,A0		* Load the addres of 'B' into A0
		LEA	movea_len,A1	* Load the address of the end of string
MA_LOOP		MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	MA_LOOP		* Get next ASCII (for safty)
		RTS			

****************************************************************************
* Sub-routine	: CODE0010
* Description	:
* This is the algorithm deals with MOVE.L and MOVEA.L
*****************************************************************************
CODE0010	CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload test word into D1
		ANDI.L	#mask6_8,D1	* Mask off bits 6-8
		MOVE.B	#shift6,D2	* Put the shift value into D2
		LSR.W	D2,D1		* Shift bits 6-8 into 0-2
		CLR.L	D2		* Clear D2
		CMPI.B	#%0001,D1	* Is this MOVEA?
		BEQ	OP_MOVEA_L	* Deal with MOVEA.L
		BRA	OP_MOVE_L	* Deal with MOVE.L

OP_MOVEA_L	LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#movea_l_fl,(A1) * Save the flag for where to return to
		BSR	MOVEA_HELPER	* Add 'MOVEA.' to the string
		BSR	PRINT_L		* ADD 'L' to the string	
		MOVE.B	#$20,(A4)+	* ADD ' ' to string
		BSR	MASK_0_5	* Mask off 0-5 and put in D4
		JMP	TO_BRYAN	* Pass control to EA

RT_MOVEA_L	BSR	PRINT_COMMA	* Add the camma to the buffer
		CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.L	#mask9_11,D1	* Mask off 9-11
		MOVE.B	#shift9,D2	* Load shift value
		LSR.W	D2,D1		* Shift
		CLR.L	D2		* Clear D2
		LEA	buff_reg_nm,A1	* Load location to save Address register
		MOVE.W	D1,(A1)		* Ssave the Address register
		BSR 	PRINT_AN	* Print Address register
		JMP	SET_GOOD_FLAG	* Set the good flag
		

OP_MOVE_L	LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#move_l_fl,(A1)	* Save the flag for where to return to
		BSR	MOVE_HELPER	* Add 'MOVE.' to the string
		BSR	PRINT_L		* ADD 'B' to the string	
		MOVE.B	#$20,(A4)+	* ADD ' ' to string
		BSR	MASK_0_5	* Mask off 0-5 and put in D4
		JMP	TO_BRYAN	* Pass control to EA

RT_MOVE_L	LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#no_more_wk,(A1) * Save the flag for where to return to	
		BSR	PRINT_COMMA	* Add the camma to the buffer
		CLR.L	D1		* Make sure the working register is clear to start
		CLR.L	D2		* Make sure D2 is clear
		MOVE.W	D0,D1		* Put a copy of the word into D1
		ANDI.L	#mask9_11,D1	* Mask off bits 9-11
		MOVE.B	#shift9,D2	* Put the shift value into D2
		LSR.W	D2,D1		* Shift bits 9-11 into 0-2
		CLR.L	D2		* Clear D2
		CLR.L	D3		* Clear D3
		MOVE.W	D1,D3		* Move the register number to bits 0-2 of D3
		CLR.L	D1		* Clear D1
		MOVE.W	D0,D1		* Reload the test word
		ANDI.L	#mask6_8,D1	* Mask off 6-8
		MOVE.B	#shift3,D2	* Load the shift value
		LSR.W	D2,D1		* Shift bits 6-8 into 3-5
		ADD.L	D3,D1		* Combine regiters to put EA in proper format
		MOVE.L	D1,D4		* Load the EA bits into D4
		JMP	TO_BRYAN	* Pass control to EA
		

****************************************************************************
* Sub-routine	: CODE0011
* Description	:
* This is the algorithm deals with MOVE.W and MOVEA.W
*****************************************************************************
CODE0011	CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload test word into D1
		ANDI.L	#mask6_8,D1	* Mask off bits 6-8
		MOVE.B	#shift6,D2	* Put the shift value into D2
		LSR.W	D2,D1		* Shift bits 6-8 into 0-2
		CLR.L	D2		* Clear D2
		CMPI.B	#%0001,D1	* Is this MOVEA?
		BEQ	OP_MOVEA_W	* Deal with MOVEA.W
		BRA	OP_MOVE_W	* Deal with MOVE.W

OP_MOVEA_W	LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#movea_w_fl,(A1) * Save the flag for where to return to
		BSR	MOVEA_HELPER	* Add 'MOVEA.' to the string
		BSR	PRINT_W		* ADD 'W' to the string	
		MOVE.B	#$20,(A4)+	* ADD ' ' to string
		BSR	MASK_0_5	* Mask off 0-5 and put in D4
		JMP	TO_BRYAN	* Pass control to EA

RT_MOVEA_W	BSR	PRINT_COMMA	* Add the camma to the buffer
		CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.L	#mask9_11,D1	* Mask off 9-11
		MOVE.B	#shift9,D2	* Load shift value
		LSR.W	D2,D1		* Shift
		CLR.L	D2		* Clear D2
		LEA	buff_reg_nm,A1	* Load location to save Address register
		MOVE.W	D1,(A1)		* Ssave the Address register
		BSR 	PRINT_AN	* Print Address register
		JMP	SET_GOOD_FLAG	* Set the good flag
		

OP_MOVE_W	LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#move_w_fl,(A1)	* Save the flag for where to return to
		BSR	MOVE_HELPER	* Add 'MOVE.' to the string
		BSR	PRINT_W		* ADD 'B' to the string	
		MOVE.B	#$20,(A4)+	* ADD ' ' to string
		BSR	MASK_0_5	* Mask off 0-5 and put in D4
		JMP	TO_BRYAN	* Pass control to EA

RT_MOVE_W	LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#no_more_wk,(A1) * Save the flag for where to return to	
		BSR	PRINT_COMMA	* Add the camma to the buffer
		CLR.L	D1		* Make sure the working register is clear to start
		CLR.L	D2		* Make sure D2 is clear
		MOVE.W	D0,D1		* Put a copy of the word into D1
		ANDI.L	#mask9_11,D1	* Mask off bits 9-11
		MOVE.B	#shift9,D2	* Put the shift value into D2
		LSR.W	D2,D1		* Shift bits 9-11 into 0-2
		CLR.L	D2		* Clear D2
		CLR.L	D3		* Clear D3
		MOVE.W	D1,D3		* Move the register number to bits 0-2 of D3
		CLR.L	D1		* Clear D1
		MOVE.W	D0,D1		* Reload the test word
		ANDI.L	#mask6_8,D1	* Mask off 6-8
		MOVE.B	#shift3,D2	* Load the shift value
		LSR.W	D2,D1		* Shift bits 6-8 into 3-5
		ADD.L	D3,D1		* Combine regiters to put EA in proper format
		MOVE.L	D1,D4		* Load the EA bits into D4
		JMP	TO_BRYAN	* Pass control to EA


****************************************************************************
* Sub-routine	: CODE0100
* Description	: This the section of the jump table that deals with opcodes that have
*			the pattern %0100 in bits 12-15
*
* AIP:
* D0 holds the original copy of the word in memory
* D1 holds teh local copy to be masked
* D2 holds the shift patterns and the test condition bits
* D4 is the flag passing buffer
* A0 Holds the address  of the start of the string to be added to the buffer
* A1 holds the address of the end of the string to be added to the buffer, and the address of a save 
*  location to store register type and number information for when I need to add more info to the
*  buffer after the EA work is done
* A2 holds the address where the address register number is stored
* A4 points to the spot in the buffer to write
*****************************************************************************
CODE0100	CLR.L	D1		* Make sure the working register is clear to start
		CLR.L	D2		* Make sure D2 is clear
		MOVE.W	D0,D1		* Put a copy of the word into D1
		ANDI.L	#mask8_11,D1	* Mask off bits 8-11
		MOVE.B	#shift8,D2	* Put the shift value into D2
		LSR.W	D2,D1		* Shift bits 8-11 into 0-3
		CLR.L	D2		* Clear D2
		ADDI.B	#%1110,D2	* Put test pattern 1110 into D2
		CMP.B	D2,D1		* Check to see if D2 == D1
		BNE	NO_1110		* keep decoding

YES_1110	CLR.L 	D1		* Make sure D1 is clear again
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Put a copy of the word into D1
		ANDI.L	#mask7,D1	* Mask off bit 7
		MOVE.B	#shift7,D2	* Put the shift value in D2
		LSR.W	D2,D1		* shift bit 7 into 0
		CLR.L	D2		* Clear D2
		ADDI.B	#%0000,D2	* put test word in D2
		CMP.B	D2,D1		* Check to see if it equals zero
		BNE	_7_NOT_0	* Branch if not equal

_7_IS_0		CLR.L 	D1		* Make sure D1 is clear again
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Put a copy of the word into D1	
		ANDI.L	#mask0_2,D1	* Mask off bit 2
		MOVE.B	#%0001,D2	* This is the pattern for NOP in bits 0-2
		CMP.B	D2,D1		* Check to see if D2 == D1
		BEQ	OP_NOP		* If equal the opcode is NOP
		CLR.L	D2		* Clear D2
		MOVE.B	#%0010,D2	* This is the pattern for STOP in bits 0-2
		CMP.B	D2,D1		* Is it STOP?
		BEQ	OP_STOP		* Print out STOP
		BRA	CHECK_RTS	* If not NOP varify that it is RTS

_7_NOT_0	CLR.L 	D1		* Make sure D1 is clear again
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Put a copy of the word into D1
		ANDI.L	#mask6,D1	* Mask off bit 6
		MOVE.B	#shift6,D2	* Load the shift value
		LSR.W	D2,D1		* Shift bit 6 into bit 1
		CLR.L	D2		* Clear D2 Also doubles as loading %0000 test patten into D2
		CMP.B	D2,D1		* Check to see if bit 6 == 0
		BNE	OP_JMP		* Check to see if op code is JMP
		BRA	OP_JSR		* The op code is JSR

NO_1110		ANDI.L	#mask1,D1	* Isolate bit 8, D1 should still be holding bit 8 in bit possition 1
		CLR.L	D2		* Clear D2 Also doubles as loading %0000 test patten into D2
		CMP.B	D2,D1		* Check to see if bit 8 == 0
		BNE	CHECK_LEA	* If not equal the op code might be LEA
_8_NOT_1	CLR.L	D1		* Clear D1 
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Put a copy of the word into D1
		ANDI.L	#mask8_11,D1	* Mask off 8-11
		MOVE.B	#shift8,D2	* Load shift value in D2
		LSR.W	D2,D1		* Shift 8-11 to 0-3
		CLR.L	D2		* Clear D2
		CMPI.B	#%0010,D1	* Is this CLR?
		BEQ	OP_CLR		* If == opcode is CLR
		CMPI.B	#%0100,D1	* Is this NEG?
		BEQ	OP_NEG		* If == opcode is NEG
		CMPI.B	#%0110,D1	* Is this NOT?
		BEQ	OP_NOT		* If == this is NOT
		CMPI.B	#%1000,D1 	* Is this SWAP?
		BEQ	CHECK_SWAP	* If == this could be SWAP still need to check bit 7
		CMPI.B	#%1100,D1	* Is this MOVEM?
		BEQ	OP_MOVEM	* If == this is MOVEM 
		BRA	SET_BAD_FLAG	* If this line is reached set bad flag


*****************************************************************************************
* CHECK	: Below are three check points to check for bad data when determining
* 		that an opcode is what it seems to be. The checks are for
*		SWAP, LEA and RTS
*****************************************************************************************
CHECK_SWAP	CLR.L 	D1		* Make sure D1 is clear, D2 should be clear from previous checks
		MOVE.W	D0,D1		* Reload the test word
		ANDI.L	#mask7,D1	* Mask off bit 7
		MOVE.B	#shift7,D2	* Load the shift pattern into D2
		LSR.L	D2,D1		* Shift bits 6-8 into 0-2
		CLR.L	D2		* Clear D2. Also doubles as putting %0000 test pattern in D2
		CMP.B	D2,D1		* Does D1 == %0000?
		BEQ	OP_SWAP		* If D1 == %0000 then the opcode is SWAP
		BRA	OP_MOVEM	* If D1 == %0001 then the opcode is MOVEM	
			
CHECK_LEA	CLR.L 	D1		* Make sure D1 is clear, D2 should be clear from previous checks
		MOVE.W	D0,D1		* Reload the test word
		ANDI.L	#mask6_8,D1	* Mask off bits 6-8
		MOVE.B	#shift6,D2	* Load the shift pattern into D2
		LSR.L	D2,D1		* Shift bits 6-8 into 0-2
		CLR.L	D2		* Clear D2
		ADDI.B	#%0111,D2	* Load test pattern into D2
		CMP.B	D2,D1		* Does D1 == %0111?
		BEQ	OP_LEA		* If == the opcoed is LEA
		JMP	SET_BAD_FLAG	* If != set the bad flag
		
CHECK_RTS	CLR.L	D1		* Make sure D1 is clear
		CLR.L	D2		* Make sure D2 is clear
		MOVE.W	D0,D1		* Reload the test word
		ANDI.L	#mask0_3,D1	* Mask off bits 0-3
		ADDI.B	#%0101,D2	* Load test bit pattern
		CMP.B	D2,D1		* Check for equality
		BEQ	OP_RTS		* If equal, the opcode is RTS
		JMP	SET_BAD_FLAG	* Go set the bad flag if not equal


*****************************************************************************************
* _PRINT_ATTR	: PRINT ATTRibutes adds 'B', 'W' or 'L' as size of operation below
*****************************************************************************************
_PRINT_ATTR	CMPI.B	#%0000,D1	* Is this size byte?
		BEQ	_PRINT_B	* Get ready to add 'B' to the buffer
		CMPI.B	#%0001,D1	* Is this size word?
		BEQ	_PRINT_W	* Get ready to add 'W' to the buffer
		CMPI.B	#%0010,D1	* Is this size long?
		BEQ	_PRINT_L	* Get ready to add 'L' to the buffer
_PRINT_B	JSR	PRINT_B		* Call PRINT_B
		BRA	_PRINT_SP	* Now add the space
_PRINT_W	JSR	PRINT_W		* Call PRINT_W
		BRA	_PRINT_SP	* Now add the space
_PRINT_L	JSR	PRINT_L		* Call PRINT_L
_PRINT_SP	JSR	N_PRINT_SPACE	* Call ' ' printing method
		CLR.L	D4		* Make sure the flag passing register is clear
		MOVE.W	D0,D4		* Put the bits to be passed to EA into D4
		ANDI.L	#mask0_5,D4	* Mask off bits 0-5
		JMP	TO_BRYAN	* Pass control to EA


*****************************************************************************************
* STOP	: STOP is added to the buffer below
*****************************************************************************************
OP_STOP		LEA	more_work,A1	* Load flag address to check after return from EA
		MOVE.W	#no_more_wk,(A1) * Set flag as all done when retun from EA	
		LEA 	stop_st,A0	* Load the address of the JSR string into A0
		LEA	stop_st_len,A1	* Load the address of the end of the string
LOOP_OP_STOP	MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LOOP_OP_STOP	* Get next ASCII	
		JSR	N_PRINT_SPACE	* Call ' ' printing method
		JSR	PRINT_POUND	* Add a # to buffer
		ADDI.L	#imed_word,D4	* Load the fake immediate code of size byte
		JMP	TO_BRYAN	* Pass control to EA


*****************************************************************************************
* CLR	: CLR is added to the buffer below
*****************************************************************************************
OP_CLR		CLR.L	D1		* Make sure D1 is clear
		CLR.L	D2		* Make sure D2 is clear
		MOVE.W	D0,D1		* Reload the test word
		ANDI.L	#mask6_7,D1	* Mask off bits 6-7 to get size
		MOVE.B	#shift6,D2	* Load shift value into D2
		LSR.L	D2,D1		* Shift 6-7 into 0-1
		CLR.L	D2		* Clear D2
		LEA	more_work,A1	* Load flag address to check after return from EA
		MOVE.W	#no_more_wk,(A1) * Set flag as all done when retun from EA	
		ADDI.B	#%0011,D2	* Load the bad value that needs to be checked into D2
		CMP.B	D2,D1		* If == this op code is not valid!
		BEQ	SET_BAD_FLAG	* Set the bad flag
		LEA 	clr,A0		* Load the address of the CLR string into A0
		LEA	clr_len,A1	* Load the address of the end of the string
LOOP_OP_CLR	MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LOOP_OP_CLR	* Get next ASCII
		BRA	_PRINT_ATTR	* Now print the size

		
*****************************************************************************************
* NEG	: NEG is added to the buffer below
*****************************************************************************************		
OP_NEG		CLR.L	D1		* Make sure D1 is clear
		CLR.L	D2		* Make sure D2 is clear
		MOVE.W	D0,D1		* Reload the test word
		ANDI.L	#mask6_7,D1	* Mask off bits 6-7 to get size
		MOVE.B	#shift6,D2	* Load shift value into D2
		LSR.L	D2,D1		* Shift 6-7 into 0-1
		CLR.L	D2		* Clear D2
		LEA	more_work,A1	* Load flag address to check after return from EA
		MOVE.W	#no_more_wk,(A1) * Set flag as all done when retun from EA	
		ADDI.B	#%0011,D2	* Load the bad value that needs to be checked into D2
		CMP.B	D2,D1		* If == this op code is not valid!
		BEQ	SET_BAD_FLAG	* Set the bad flag
		LEA 	neg,A0		* Load the address of the NEG string into A0
		LEA	neg_len,A1	* Load the address of the end of the string
LOOP_OP_NEG	MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LOOP_OP_NEG	* Get next ASCII
		BRA	_PRINT_ATTR	* Now print the size		


*****************************************************************************************
* NOT	: NOT is added to the buffer below
*****************************************************************************************
OP_NOT		CLR.L	D1		* Make sure D1 is clear
		CLR.L	D2		* Make sure D2 is clear
		MOVE.W	D0,D1		* Reload the test word
		ANDI.L	#mask6_7,D1	* Mask off bits 6-7 to get size
		MOVE.B	#shift6,D2	* Load shift value into D2
		LSR.L	D2,D1		* Shift 6-7 into 0-1
		CLR.L	D2		* Clear D2
		LEA	more_work,A1	* Load flag address to check after return from EA
		MOVE.W	#no_more_wk,(A1) * Set flag as all done when retun from EA	
		ADDI.B	#%0011,D2	* Load the bad value that needs to be checked into D2
		CMP.B	D2,D1		* If == this op code is not valid!
		BEQ	SET_BAD_FLAG	* Set the bad flag
		LEA 	not,A0		* Load the address of the NOT string into A0
		LEA	not_len,A1	* Load the address of the end of the string
LOOP_OP_NOT	MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LOOP_OP_NOT	* Get next ASCII
		BRA	_PRINT_ATTR	* Now print the size
	

*****************************************************************************************
* SWAP	: SWAP is added to the buffer below
*****************************************************************************************
OP_SWAP		CLR.L	D1		* Make sure D1 is clear
		CLR.L	D2		* Make sure D2 is clear
		MOVE.W	D0,D1		* Reload the test word
		ANDI.L	#mask6_7,D1	* Mask off bits 6-7 to get size
		MOVE.B	#shift6,D2	* Load shift value into D2
		LSR.L	D2,D1		* Shift 6-7 into 0-1
		CLR.L	D2		* Clear D2	
		ADDI.B	#%0001,D2	* Load the only valid size (word) into D2
		CMP.B	D2,D1		* If != this op code is not valid!
		BNE	SET_BAD_FLAG	* Set the bad flag
		CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload test word
		ANDI.L	#mask3_5,D1	* Mask off bits 3-5
		MOVE.B	#shift3,D2	* Load shift value into D2
		LSR.L	D2,D1		* Shift bits 3-5 into 0-2
		CLR.L	D2		* Clear D2, Also doubles as putting test value %0000 into D2
		CMP.B	D2,D1		* D1 == %0000?
		BNE	SET_BAD_FLAG	* If D1 != %0000 set the bad flag
		CLR.L	D1		* Clear D1
		CLR.L 	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.L	#mask0_2,D1	* Mask off bits 0-2. This gets Dn
		
		LEA 	swap,A0		* Load the address of the SWAP string into A0
		LEA	swap_len,A1	* Load the address of the end of the string
LOOP_OP_SWAP	MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LOOP_OP_SWAP	* Get next ASCII
		JSR	N_PRINT_SPACE	* Call ' ' printing method
		BSR	PRINT_DN	* Jump to the data register printing method
		BSR	N_PRINT_SPACE	* Add a ' '
		JMP	SET_GOOD_FLAG	* Set the good flag


*****************************************************************************************
* MOVEM	: MOVEM is added to the buffer below
*****************************************************************************************
OP_MOVEM	CLR.L 	D1		* Make sure D1 is clear, D2 should be clear from previous checks
		MOVE.W	D0,D1		* Reload the test word
		ANDI.L	#mask7,D1	* Mask off bit 7
		MOVE.B	#shift7,D2	* Load the shift pattern into D2
		LSR.L	D2,D1		* Shift bits 6-8 into 0-2
		CMPI.B	#%0001,D1	* Make sure bit 7 is a 1
		BNE	SET_BAD_FLAG	* If bit 7 is not 1 then bad op

		LEA 	movem,A0	* Load the addres of 'MOVEM' into A0
		LEA	movem_len,A1	* Load the address of the end of string
MM_LOOP		MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	MM_LOOP		* Get next ASCII
			
		CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload test word
		ANDI.L	#mask6,D1	* Mask of bit 6 to get the size
		MOVE.B	#shift6,D2	* Load shift value
		LSR.L	D2,D1		* Shift
		CMPI.B	#%0001,D1	* Is it size a long?
		BEQ 	P_MOVEM_L	* Add the .L
		BSR	PRINT_W		* Add the .W
		BRA	MM_CNT		* Continue		

P_MOVEM_L	BSR	PRINT_L		* Add the .L
MM_CNT		BSR	N_PRINT_SPACE	* Add the space

		CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.L	#mask10,D1	* Mask off bit 10
		MOVE.B	#shift10,D2	* Load the shift pattern
		LSR.L	D2,D1		* Shift
		CMPI.B	#%0001,D1	* Check the format
		BEQ	MM_REG_EA_S	* Format 1
		BRA	MM_EA_REG_S	* Format 2

MM_REG_EA_S	LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#mm_reg_ea_fl,(A1) * Save the flag for where to return to
		CLR.L	D4		* Clear D4
		MOVE.W	#reg_fl,D4	* send REG flag
		JMP	TO_BRYAN	* Pass control to EA
		
MM_REG_EA	LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#no_more_wk,(A1) * Set flag as all done when retun from EA
		BSR	PRINT_COMMA	* Add ',' to buffer
		BSR	MASK_0_5	* Put EA in D4
		JMP	TO_BRYAN	* Pass control to E


MM_EA_REG_S	LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#mm_ea_reg_fl,(A1) * Save the flag for where to return to
		BSR	MASK_0_5	* Put EA in D4
		JMP	TO_BRYAN	* Pass control to EA

MM_EA_REG	LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#no_more_wk,(A1) * Set flag as all done when retun from EA
		BSR	PRINT_COMMA	* Add ',' to buffer
		CLR.L	D4		* Clear D4
		MOVE.W	#reg_fl,D4	* send REG flag
		JMP	TO_BRYAN	* Pass control to EA					


*****************************************************************************************
* LEA	: LEA is added to the buffer below
*****************************************************************************************
OP_LEA		CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask9_11,D1	* Get An from bits 9-11
		MOVE.B	#shift9,D2	* Load shift value into D2
		LSR.L	D2,D1		* Move 9-11 into 0-3
		CLR.L	D2		* Clear D2
		LEA	buff_reg_fl,A1	* Load the address to save register info
		MOVE.W	#addr_flag,(A1)	* Save register flag type
		LEA	buff_reg_nm,A1	* Load the addres to save reg number
		MOVE.W	D1,(A1)		* Save the register number
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#lea_rt_fl,(A1)	* Save the flag for where to return to	
		LEA 	lea,A0		* Load the address of the lea string into A0
		LEA	lea_len-1,A1	* Load the address of the end of the string
LOOP_OP_LEA	MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LOOP_OP_LEA	* Get next ASCII	
		LEA 	spa,A0		* Load the addres of spa into A0
		LEA	spa_len-1,A1	* Load the address of the end of string
LOOP_SP_LEA	MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LOOP_SP_LEA	* Get next ASCII
		CLR.L	D4		* Make sure the flag passing register is clear
		MOVE.W	D0,D4		* Put the bits to be passed to EA into D4
		ANDI.L	#mask0_5,D4	* Mask off bits 0-5
		LEA	long_flag,A0	* Load the address where the EA lenght flag is stored
		MOVE.W	#long_ea_fl,(A0) * EA length is long
		JMP	TO_BRYAN	* Pass control to EA	
_RT_LEA		BSR	PRINT_COMMA	* Add ',' to buffer
		BSR	PRINT_AN	* Add the address register to the buffer
		BSR	N_PRINT_SPACE	* Call ' ' printing method
		JMP	SET_GOOD_FLAG	* Set the good flag
		

*****************************************************************************************
* JSR	: JSR is added to the buffer below
*****************************************************************************************
OP_JSR		LEA	more_work,A1	* Load flag address to check after return from EA
		MOVE.W	#no_more_wk,(A1) * Set flag as all done when retun from EA	
		LEA 	jsr,A0		* Load the address of the JSR string into A0
		LEA	jsr_len-1,A1	* Load the address of the end of the string
LOOP_OP_JSR	MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LOOP_OP_JSR	* Get next ASCII	
		JSR	N_PRINT_SPACE	* Call ' ' printing method
		CLR.L	D4		* Make sure the flag passing register is clear
		MOVE.W	D0,D4		* Put the bits to be passed to EA into D4
		ANDI.L	#mask0_5,D4	* Mask off bits 0-5
		JMP	TO_BRYAN	* Pass control to EA


*****************************************************************************************
* JMP	: JMP is added to the buffer below
*****************************************************************************************
OP_JMP		LEA	more_work,A1	* Load flag address to check after return from EA
		MOVE.W	#no_more_wk,(A1) * Set flag as all done when retun from EA
		LEA 	jmp,A0		* Load the address of the JMP string into A0
		LEA	jmp_len-1,A1	* Load the address of the end of the string
LOOP_OP_JMP	MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LOOP_OP_JMP	* Get next ASCII	
		JSR	N_PRINT_SPACE	* Call ' ' printing method
		CLR.L	D4		* Make sure the flag passing register is clear
		MOVE.W	D0,D4		* Put the bits to be passed to EA into D4
		ANDI.L	#mask0_5,D4	* Mask off bits 0-5
		JMP	TO_BRYAN	* Pass control to EA


*****************************************************************************************
* RTS	: RTS is added to the buffer below
*****************************************************************************************
OP_RTS		LEA 	rts,A0		* Load the address of the RTS string into A0
		LEA	rts_len-1,A1	* Load the address of the end of the string
LOOP_OP_RTS	MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LOOP_OP_RTS	* Get next ASCII	
		JSR	N_PRINT_SPACE	* Call ' ' printing method
		JMP	SET_GOOD_FLAG	* Set the good flag


*****************************************************************************************
* NOP	: NOP is added to the buffer below
*****************************************************************************************
OP_NOP		LEA 	nop,A0		* Load the address of the NOP string into A0
		LEA	nop_len-1,A1	* Load the address of the end of the string
LOOP_OP_NOP	MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LOOP_OP_NOP	* Get next ASCII	
		JSR	N_PRINT_SPACE	* Call ' ' printing method
		JMP	SET_GOOD_FLAG	* Set the good flag
		
				
****************************************************************************
* Sub-routine	: CODE0101
* Description	:
* This is the algorithm for dealing with imediates
*****************************************************************************
CODE0101	BRA	SET_BAD_FLAG	* *** NOT IMPLEMENTED! NOT RQUIRED! ****


****************************************************************************
* Sub-routine	: CODE0110
* Description	:
* This is the algorithm decodes BSR
*****************************************************************************
CODE0110	CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.L	#mask8_11,D1	* Mask off bits 8-11 to get size
		MOVE.B	#shift8,D2	* Load shift value into D2
		LSR.L	D2,D1		* Shift 8-11 into 0-3
		CLR.L	D2		* Clear D2
		CMPI.B	#%0001,D1	* Is if BSR?
		BNE	SET_BAD_FLAG	* Set bad flag

		CLR.L	D1		* Clear D1
		MOVE.W	D0,D1		* Reload the test word
		ANDI.L	#mask0_7,D1	* Get 8, 16, or 32 bit displacement
		CMPI.B	#$00,D1		* 16-bit?
		BEQ	BSR_16		* Take care of 16-bit displacement
		CMPI.B	#$FF,D1		* 32-bit?
		BEQ	BSR_32		* Take care of 32-bit displacement
		BRA	BSR_8		* Take care of 8-bit displacement

BSR_8		BSR	BSR_HELPER	* Call helper
		BSR	PRINT_B		* Add 'B'
		JSR	N_PRINT_SPACE	* Call ' ' printing method
		MOVE.B	#$24,(A4)+	* Put a $ after the address

BSR_DSP		CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.L	#mask7,D1	* Mask off bit 7 to get +/- displacement
		MOVE.B	#shift7,D2	* Load shift value into D2
		LSR.L	D2,D1		* Shift 7 into 0
		CLR.L	D2		* Clear D2
		CMPI.B	#%0001,D1	* Bit 7 == 1?
		BEQ	BSR_NEG

		CLR.L	D1		* Clear D1
		MOVE.W	D0,D1		* Reload the test word
		ANDI.L	#mask0_7,D1	* Get  positive 8-bit displacement
		MOVE.L	A3,D2		* Get address of the line after the BSR
		ADD.L	D2,D1		* Add together to get new address

		MOVEM.L	D0,-(SP)	* save test word
		MOVE.L	D1,D0		* load what to convert
		MOVEA	A4,A0		* Set up pass to MEM_TO_ASCII
		MOVE.L	#8,D3		* Convert to 8 ASCII chars (Print full address)
		BSR	MEM_TO_ASCII	* Convert address to ASCII
		MOVEM.L	(SP)+,D0	* restore test word
		ADDA	#8,A4		* Move 8 bytes forword
		JMP	SET_GOOD_FLAG	* Set good flag	

BSR_NEG		CLR.L	D1		* Clear D1
		MOVE.W	D0,D1		* Reload the test word
		ANDI.L	#mask0_7,D1	* Get  positive 8-bit displacement
		NOT.B	D1		* Not bits 0-7
		ADDI.B	#1,D1		* Take twos complement of D1
		MOVE.L	A3,D2		* Get address of the line after the BSR
		SUB.L	D2,D1		* Add together to get new address
		NOT.L	D1		* Not bits 0-32
		ADDI.L	#1,D1		* Take twos complement of D1
		

		MOVEM.L	D0,-(SP)	* save test word
		MOVE.L	D1,D0		* load what to convert
		MOVEA	A4,A0		* Set up pass to MEM_TO_ASCII
		MOVE.L	#8,D3		* Convert to 8 ASCII chars (Print full address)
		BSR	MEM_TO_ASCII	* Convert address to ASCII
		MOVEM.L	(SP)+,D0	* restore test word
		ADDA	#8,A4		* Move 8 bytes forword
		JMP	SET_GOOD_FLAG	* Set good flag	
	
BSR_16		ADDA	#$2,A3		* Move 1 word forword
		BSR	BSR_HELPER	* Call helper
		BSR	PRINT_W		* Add 'W'
		JSR	N_PRINT_SPACE	* Call ' ' printing method
		MOVE.B	#$24,(A4)+	* Put a $ after the address
		BRA	BSR_DSP		* Branch!
		
		
		
BSR_32		ADDA	#$4,A3		* move 2 words forword
		BSR	BSR_HELPER	* Call helper
		BSR	PRINT_L		* Add 'L'
		JSR	N_PRINT_SPACE	* Call ' ' printing method
		MOVE.B	#$24,(A4)+	* Put a $ after the address
		BRA	BSR_DSP		* Branch!
		

****************************************************************************
* Sub-routine	: BSR_HELPER
* Description	:
* This is the algorithm adds 'BSR.' to the buffer
*****************************************************************************
BSR_HELPER	LEA 	bsr,A0		* Load the addres of 'OR' into A0
		LEA	bsr_len,A1	* Load the address of the end of string
BSR_LOOP		MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	BSR_LOOP		* Get next ASCII (for safty)
		RTS			* Return to calling method
			
****************************************************************************
* Sub-routine	: CODE0111
* Description	:
* This is the algorithm for dealing with imediates
*****************************************************************************
CODE0111	BRA	SET_BAD_FLAG	* *** NOT IMPLEMENTED! NOT RQUIRED! ***


****************************************************************************
* Sub-routine	: CODE1000
* Description	:
* This section of code decodes the OR opcode as it is the only opcode that starts with 1000 
*****************************************************************************
CODE1000	CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask6_7,D1	* Get An from bits 6-7
		MOVE.B	#shift6,D2	* Load shift value into D2
		LSR.L	D2,D1		* Move 6-7 into 0-1
		CLR.L	D2		* Clear D2
		CMPI.B	#%0011,D1	* Load bad test pattern
		BEQ	SET_BAD_FLAG	* Set the bad flag

******************************************************************************
* OR	: OR is decoded below
******************************************************************************
		LEA 	buff_reg_fl,A0	* Load the address to save the register type
		MOVE.L	#data_flag,(A0)	* Save Dn type register
		CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask9_11,D1	* Mask off 9-11
		MOVE.B	#shift9,D2	* Load shift pattern into D2
		LSR.L	D2,D1		* Move 6-8 into 0-3
 		CLR.L	D2		* Clear D2
		LEA	buff_reg_nm,A0	* Load the addres to save reg number
		MOVE.W	D1,(A0)		* Save the register number

		CLR.L	D1		* Make sure D1 is clear
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask6_8,D1	* Mask off 6-8
		MOVE.B	#shift6,D2	* Load shift pattern into D2
		LSR.L	D2,D1		* Move 6-8 into 0-3
 		CLR.L	D2		* Clear D2	
		CMPI.B	#%0000,D1	* Is it .B <ea>,Dn ?
		BEQ	_B_EA_DN	* Deal with it
		CMPI.B	#%0001,D1	* Is it .W <ea>,Dn ?
		BEQ	_W_EA_DN	* Deal with it	
		CMPI.B	#%0010,D1	* Is it .L <ea>,Dn ?
		BEQ	_L_EA_DN	* Deal with it
		CMPI.B	#%0100,D1	* Is it .B Dn,<ea> ?
		BEQ	_B_DN_EA	* Deal with it	
		CMPI.B	#%0101,D1	* Is it .W Dn,<ea> ?
		BEQ	_W_DN_EA	* Deal with it	
		CMPI.B	#%0110,D1	* Is it .L Dn,<ea> ?
		BEQ	_L_DN_EA	* Deal with it
		BRA	SET_BAD_FLAG	* Set the bad flag if this line of code is reached			

_B_EA_DN	BSR	OR_HELPER	* Update the buffer
		BSR	PRINT_B		* Add 'B'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#or_ea_dn_fl,(A1) * Save the flag for where to return to
		BRA	OR_PREP_BR	* Call to mask off EA bits 0-5

_W_EA_DN	BSR	OR_HELPER	* Update the buffer
		BSR	PRINT_W		* Add 'W'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#or_ea_dn_fl,(A1) * Save the flag for where to return to
		BRA	OR_PREP_BR	* Call to mask off EA bits 0-5

_L_EA_DN	BSR	OR_HELPER	* Update the buffer
		BSR	PRINT_L		* Add 'L'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#or_ea_dn_fl,(A1) * Save the flag for where to return to
		BRA	OR_PREP_BR	* Call to mask off EA bits 0-5

_B_DN_EA	BSR	OR_HELPER	* Update the buffer
		BSR	PRINT_B		* Add 'B'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	buff_reg_nm,A0	* Get the saved register number
		MOVE.W	(A0),D1		* load the saved value into D1
		BSR	PRINT_DN	* Add the Data register
		BSR	PRINT_COMMA	* Add a comma
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#or_dn_ea_fl,(A1) * Save the flag for where to return to
		BRA	OR_PREP_BR	* Call to mask off EA bits 0-5

_W_DN_EA	BSR	OR_HELPER	* Update the buffer
		BSR	PRINT_W		* Add 'W'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	buff_reg_nm,A0	* Get the saved register number
		MOVE.W	(A0),D1		* load the saved value into D1
		BSR	PRINT_DN	* Add the Data register
		BSR	PRINT_COMMA	* Add a comma
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#or_dn_ea_fl,(A1) * Save the flag for where to return to
		BRA	OR_PREP_BR	* Call to mask off EA bits 0-5

_L_DN_EA	BSR	OR_HELPER	* Update the buffer
		BSR	PRINT_L		* Add 'L'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	buff_reg_nm,A0	* Get the saved register number
		MOVE.W	(A0),D1		* load the saved value into D1
		BSR	PRINT_DN	* Add the Data register
		BSR	PRINT_COMMA	* Add a comma
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#or_dn_ea_fl,(A1) * Save the flag for where to return to
		BRA	OR_PREP_BR	* Call to mask off EA bits 0-5
		
OR_PREP_BR	CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask0_5,D1	* Get An from bits 6-7
		MOVE.B	D1,D4		* Read to pass to Bryan
		JMP	TO_BRYAN	* Pass control to EA
	
OR_EA_DN	BSR	PRINT_COMMA	* Add a comma
		LEA	buff_reg_nm,A0	* Get the saved register number
		MOVE.W	(A0),D1		* load the saved value into D1
		BSR	PRINT_DN	* Add the Data register
		JSR	N_PRINT_SPACE	* Call ' ' printing method
		JMP	SET_GOOD_FLAG	* Set good flag	
		
OR_DN_EA	JSR	N_PRINT_SPACE	* Call ' ' printing method
		JMP	SET_GOOD_FLAG	* Set good flag	


****************************************************************************
* Sub-routine	: OR_HELPER
* Description	:
* This method puts 'OR.' into the buffer A4
*****************************************************************************
OR_HELPER	LEA 	_or,A0		* Load the addres of 'OR' into A0
		LEA	_or_len-1,A1	* Load the address of the end of string
OR_LOOP		MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	OR_LOOP		* Get next ASCII (for safty)
		RTS			* Return to calling method	


****************************************************************************
* Sub-routine	: CODE1001
* Description	:
* This section decodes SUB and SUBA
*****************************************************************************
CODE1001	CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask6_7,D1	* Get An from bits 6-7
		MOVE.B	#shift6,D2	* Load shift value into D2
		LSR.L	D2,D1		* Move 6-7 into 0-1
		CLR.L	D2		* Clear D2
		CMPI.B	#%0011,D1	* Load bad test pattern
		BEQ	OP_SUBA		* Make sure the op code is ADDA


*****************************************************************************
* SUB	: SUB is decoded below
*****************************************************************************
		LEA 	buff_reg_fl,A0	* Load the address to save the register type
		MOVE.L	#data_flag,(A0)	* Save Dn type register
		CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask9_11,D1	* Mask off 9-11
		MOVE.B	#shift9,D2	* Load shift pattern into D2
		LSR.L	D2,D1		* Move 9-11 into 0-3
 		CLR.L	D2		* Clear D2
		LEA	buff_reg_nm,A0	* Load the addres to save reg number
		MOVE.W	D1,(A0)		* Save the register number

		CLR.L	D1		* Make sure D1 is clear
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask6_8,D1	* Mask off 6-8
		MOVE.B	#shift6,D2	* Load shift pattern into D2
		LSR.L	D2,D1		* Move 6-8 into 0-3
 		CLR.L	D2		* Clear D2	
		CMPI.B	#%0000,D1	* Is it .B <ea>,Dn ?
		BEQ	S_B_EA_DN	* Deal with it
		CMPI.B	#%0001,D1	* Is it .W <ea>,Dn ?
		BEQ	S_W_EA_DN	* Deal with it	
		CMPI.B	#%0010,D1	* Is it .L <ea>,Dn ?
		BEQ	S_L_EA_DN	* Deal with it
		CMPI.B	#%0100,D1	* Is it .B Dn,<ea> ?
		BEQ	S_B_DN_EA	* Deal with it	
		CMPI.B	#%0101,D1	* Is it .W Dn,<ea> ?
		BEQ	S_W_DN_EA	* Deal with it	
		CMPI.B	#%0110,D1	* Is it .L Dn,<ea> ?
		BEQ	S_L_DN_EA	* Deal with it
		BRA	SET_BAD_FLAG	* Set the bad flag if this line of code is reached			

S_B_EA_DN	BSR	SUB_HELPER	* Update the buffer
		BSR	PRINT_B		* Add 'B'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#sub_ea_dn_fl,(A1) * Save the flag for where to return to
		BRA	SUB_PREP_BR	* Call to mask off EA bits 0-5

S_W_EA_DN	BSR	SUB_HELPER	* Update the buffer
		BSR	PRINT_W		* Add 'W'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#sub_ea_dn_fl,(A1) * Save the flag for where to return to
		BRA	SUB_PREP_BR	* Call to mask off EA bits 0-5

S_L_EA_DN	BSR	SUB_HELPER	* Update the buffer
		BSR	PRINT_L		* Add 'L'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#sub_ea_dn_fl,(A1) * Save the flag for where to return to
		BRA	SUB_PREP_BR	* Call to mask off EA bits 0-5

S_B_DN_EA	BSR	SUB_HELPER	* Update the buffer
		BSR	PRINT_B		* Add 'B'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	buff_reg_nm,A0	* Get the saved register number
		MOVE.W	(A0),D1		* load the saved value into D1
		BSR	PRINT_DN	* Add the Data register
		BSR	PRINT_COMMA	* Add a comma
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#sub_dn_ea_fl,(A1) * Save the flag for where to return to
		BRA	SUB_PREP_BR	* Call to mask off EA bits 0-5

S_W_DN_EA	BSR	SUB_HELPER	* Update the buffer
		BSR	PRINT_W		* Add 'W'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	buff_reg_nm,A0	* Get the saved register number
		MOVE.W	(A0),D1		* load the saved value into D1
		BSR	PRINT_DN	* Add the Data register
		BSR	PRINT_COMMA	* Add a comma
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#sub_dn_ea_fl,(A1) * Save the flag for where to return to
		BRA	SUB_PREP_BR	* Call to mask off EA bits 0-5

S_L_DN_EA	BSR	SUB_HELPER	* Update the buffer
		BSR	PRINT_L		* Add 'L'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	buff_reg_nm,A0	* Get the saved register number
		MOVE.W	(A0),D1		* load the saved value into D1
		BSR	PRINT_DN	* Add the Data register
		BSR	PRINT_COMMA	* Add a comma
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#sub_dn_ea_fl,(A1) * Save the flag for where to return to
		BRA	SUB_PREP_BR	* Call to mask off EA bits 0-5
		
SUB_PREP_BR	CLR.L	D4		* Clear D4
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D4		* Reload the test word
		ANDI.W	#mask0_5,D4	* Get An from bits 6-7
		JMP	TO_BRYAN	* Pass control to EA
	
SUB_EA_DN	BSR	PRINT_COMMA	* Add a comma
		LEA	buff_reg_nm,A0	* Get the saved register number
		MOVE.W	(A0),D1		* load the saved value into D1
		BSR	PRINT_DN	* Add the Data register
		JSR	N_PRINT_SPACE	* Call ' ' printing method
		JMP	SET_GOOD_FLAG	* Set good flag	
		
SUB_DN_EA	JSR	N_PRINT_SPACE	* Call ' ' printing method
		JMP	SET_GOOD_FLAG	* Set good flag


****************************************************************************
* Sub-routine	: SUB_HELPER
* Description	:
* This method puts 'SUB.' into the buffer A4
*****************************************************************************
SUB_HELPER	LEA 	sub,A0		* Load the addres of 'SUB' into A0
		LEA	sub_len,A1	* Load the address of the end of string
SUB_LOOP	MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	SUB_LOOP	* Get next ASCII (for safty)
		RTS			* Return to calling method	


****************************************************************************
* SUBA	: SUBA is decoded below
****************************************************************************
OP_SUBA		LEA 	buff_reg_fl,A0	* Load the address to save the register type
		MOVE.L	#addr_flag,(A0)	* Save Address type register
		CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask9_11,D1	* Mask off 9-11
		MOVE.B	#shift9,D2	* Load shift pattern into D2
		LSR.L	D2,D1		* Move 9-11 into 0-3
 		CLR.L	D2		* Clear D2
		LEA	buff_reg_nm,A0	* Load the addres to save reg number
		MOVE.W	D1,(A0)		* Save the register number	

		CLR.L	D1		* Make sure D1 is clear
		CLR.L	D1		* Make sure D2 is clear
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask6_8,D1	* Get An from bits 6-7
		MOVE.B	#shift6,D2	* Load shift value into D2
		LSR.L	D2,D1		* Move 6-7 into 0-1
		CLR.L	D2		* Clear D2
		CMPI.B	#%0011,D1	* Is it size .W ?
		BEQ	SUBA_W		* Deal with size .W
		CMPI.B	#%0111,D1	* Is it size .L ?
		BEQ	SUBA_L		* Deal with size .L
		BRA	SET_BAD_FLAG	* Set the bad flag if this line of code is reached

SUBA_W		BSR	SUBA_HELPER	* Update the buffer
		BSR	PRINT_W		* Add 'W'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#suba_ea_an_fl,(A1) * Save the flag for where to return to
		BRA	SUBA_PREP_BR	* Call to mask off EA bits 0-5	

	
SUBA_L		BSR	SUBA_HELPER	* Update the buffer
		BSR	PRINT_L		* Add 'L'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#suba_ea_an_fl,(A1) * Save the flag for where to return to
		BRA	SUBA_PREP_BR	* Call to mask off EA bits 0-5

SUBA_PREP_BR	CLR.L	D1		* Clear D1
		CLR.L	D4		* Clear D4
		MOVE.W	D0,D4		* Reload the test word
		ANDI.W	#mask0_5,D4	* Mask off bits 0-5
		JMP	TO_BRYAN	* Pass control to EA

SUBA_EA_AN	BSR	PRINT_COMMA	* Add a comma
		BSR	PRINT_AN	* Add the Data register
		JSR	N_PRINT_SPACE	* Call ' ' printing method
		JMP	SET_GOOD_FLAG	* Set good flag	


****************************************************************************
* Sub-routine	: SUBA_HELPER
* Description	:
* This method puts 'SUBA.' into the buffer A4
*****************************************************************************
SUBA_HELPER	LEA 	suba,A0		* Load the addres of 'SUBA' into A0
		LEA	suba_len,A1	* Load the address of the end of string
SUBA_LOOP	MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	SUBA_LOOP	* Get next ASCII (for safty)
		RTS			* Return to calling method

****************************************************************************
* Sub-routine	: CODE1010
* Description	:
* This is the algorithm for dealing with imediates
*****************************************************************************
CODE1010	BRA	SET_BAD_FLAG	* *** NOT IMPLEMENTED! NOT RQUIRED! ***


****************************************************************************
* Sub-routine	: CODE1011
* Description	:
* This is section decodes CMP, CMPA and EOR
*****************************************************************************
CODE1011	CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask6_7,D1	* Get An from bits 6-7
		MOVE.B	#shift6,D2	* Load shift value into D2
		LSR.L	D2,D1		* Move 6-7 into 0-1
		CLR.L	D2		* Clear D2
		CMPI.B	#%0011,D1	* Load bad test pattern
		BEQ	OP_CMPA		* Make sure the op code is CMPA

*****************************************************************************
* Is if CMP or EOR ?
*****************************************************************************
		LEA 	buff_reg_fl,A0	* Load the address to save the register type
		MOVE.L	#data_flag,(A0)	* Save Dn type register
		CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask9_11,D1	* Mask off 9-11
		MOVE.B	#shift9,D2	* Load shift pattern into D2
		LSR.L	D2,D1		* Move 9-11 into 0-3
 		CLR.L	D2		* Clear D2
		LEA	buff_reg_nm,A0	* Load the addres to save reg number
		MOVE.W	D1,(A0)		* Save the register number

		CLR.L	D1		* Make sure D1 is clear
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask6_8,D1	* Mask off 6-8
		MOVE.B	#shift6,D2	* Load shift pattern into D2
		LSR.L	D2,D1		* Move 6-8 into 0-3
 		CLR.L	D2		* Clear D2	
		CMPI.B	#%0000,D1	* Is it .B <ea>,Dn ?
		BEQ	CMP_B_EA_DN	* Deal with it
		CMPI.B	#%0001,D1	* Is it .W <ea>,Dn ?
		BEQ	CMP_W_EA_DN	* Deal with it	
		CMPI.B	#%0010,D1	* Is it .L <ea>,Dn ?
		BEQ	CMP_L_EA_DN	* Deal with it
		CMPI.B	#%0100,D1	* Is it .B Dn,<ea> ?
		BEQ	EOR_B_DN_EA	* Deal with it	
		CMPI.B	#%0101,D1	* Is it .W Dn,<ea> ?
		BEQ	EOR_W_DN_EA	* Deal with it	
		CMPI.B	#%0110,D1	* Is it .L Dn,<ea> ?
		BEQ	EOR_L_DN_EA	* Deal with it
		BRA	SET_BAD_FLAG	* Set the bad flag if this line of code is reached			

*****************************************************************************
* CMP	: CMP is added to buffer below
*****************************************************************************
CMP_B_EA_DN	BSR	CMP_HELPER	* Update the buffer
		BSR	PRINT_B		* Add 'B'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#cmp_ea_dn_fl,(A1) * Save the flag for where to return to
		BRA	EC_PREP_BR	* Call to mask off EA bits 0-5

CMP_W_EA_DN	BSR	CMP_HELPER	* Update the buffer
		BSR	PRINT_W		* Add 'W'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#cmp_ea_dn_fl,(A1) * Save the flag for where to return to
		BRA	EC_PREP_BR	* Call to mask off EA bits 0-5

CMP_L_EA_DN	BSR	CMP_HELPER	* Update the buffer
		BSR	PRINT_L		* Add 'L'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#cmp_ea_dn_fl,(A1) * Save the flag for where to return to
		BRA	EC_PREP_BR	* Call to mask off EA bits 0-5

CMP_EA_DN	BSR	PRINT_COMMA	* Add a comma
		LEA	buff_reg_nm,A0	* Get the saved register number
		MOVE.W	(A0),D1		* load the saved value into D1
		BSR	PRINT_DN	* Add the Data register
		JSR	N_PRINT_SPACE	* Call ' ' printing method
		JMP	SET_GOOD_FLAG	* Set good flag	

*****************************************************************************
* EOR	: EOR is added to buffer below
*****************************************************************************
EOR_B_DN_EA	BSR	EOR_HELPER	* Update the buffer
		BSR	PRINT_B		* Add 'B'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	buff_reg_nm,A0	* Get the saved register number
		MOVE.W	(A0),D1		* load the saved value into D1
		BSR	PRINT_DN	* Add the Data register
		BSR	PRINT_COMMA	* Add a comma
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#eor_dn_ea_fl,(A1) * Save the flag for where to return to
		BRA	EC_PREP_BR	* Call to mask off EA bits 0-5

EOR_W_DN_EA	BSR	EOR_HELPER	* Update the buffer
		BSR	PRINT_W		* Add 'W'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	buff_reg_nm,A0	* Get the saved register number
		MOVE.W	(A0),D1		* load the saved value into D1
		BSR	PRINT_DN	* Add the Data register
		BSR	PRINT_COMMA	* Add a comma
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#eor_dn_ea_fl,(A1) * Save the flag for where to return to
		BRA	EC_PREP_BR	* Call to mask off EA bits 0-5

EOR_L_DN_EA	BSR	EOR_HELPER	* Update the buffer
		BSR	PRINT_L		* Add 'L'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	buff_reg_nm,A0	* Get the saved register number
		MOVE.W	(A0),D1		* load the saved value into D1
		BSR	PRINT_DN	* Add the Data register
		BSR	PRINT_COMMA	* Add a comma
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#eor_dn_ea_fl,(A1) * Save the flag for where to return to
		BRA	EC_PREP_BR	* Call to mask off EA bits 0-5

EOR_DN_EA	JSR	N_PRINT_SPACE	* Call ' ' printing method
		JMP	SET_GOOD_FLAG	* Set good flag

*****************************************************************************
* EC_PREP_BR	: EC_PREP_BR is used by both CMP and EOR
*****************************************************************************		
EC_PREP_BR	CLR.L	D4		* Clear D4
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D4		* Reload the test word
		ANDI.W	#mask0_5,D4	* Get An from bits 6-7
		JMP	TO_BRYAN	* Pass control to EA
	

****************************************************************************
* Sub-routine	: CMP_HELPER
* Description	:
* This method puts 'CMP.' into the buffer A4
*****************************************************************************
CMP_HELPER	LEA 	cmp,A0		* Load the addres of 'cmp' into A0
		LEA	cmp_len,A1	* Load the address of the end of string
CMP_LOOP	MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	CMP_LOOP	* Get next ASCII (for safty)
		RTS			* Return to calling method	


****************************************************************************
* Sub-routine	: EOR_HELPER
* Description	:
* This method puts 'EOR.' into the buffer A4
*****************************************************************************
EOR_HELPER	LEA 	eor,A0		* Load the addres of 'EOR' into A0
		LEA	eor_len,A1	* Load the address of the end of string
EOR_LOOP	MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	EOR_LOOP	* Get next ASCII (for safty)
		RTS			* Return to calling method


****************************************************************************
* CMPA	: CMPA is decoded below
****************************************************************************
OP_CMPA		LEA 	buff_reg_fl,A0	* Load the address to save the register type
		MOVE.L	#addr_flag,(A0)	* Save Address type register
		CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask9_11,D1	* Mask off 9-11
		MOVE.B	#shift9,D2	* Load shift pattern into D2
		LSR.L	D2,D1		* Move 9-11 into 0-3
 		CLR.L	D2		* Clear D2
		LEA	buff_reg_nm,A0	* Load the addres to save reg number
		MOVE.W	D1,(A0)		* Save the register number	

		CLR.L	D1		* Make sure D1 is clear
		CLR.L	D1		* Make sure D2 is clear
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask6_8,D1	* Get An from bits 6-7
		MOVE.B	#shift6,D2	* Load shift value into D2
		LSR.L	D2,D1		* Move 6-7 into 0-1
		CLR.L	D2		* Clear D2
		CMPI.B	#%0011,D1	* Is it size .W ?
		BEQ	CMPA_W		* Deal with size .W
		CMPI.B	#%0111,D1	* Is it size .L ?
		BEQ	CMPA_L		* Deal with size .L
		BRA	SET_BAD_FLAG	* Set the bad flag if this line of code is reached

CMPA_W		BSR	CMPA_HELPER	* Update the buffer
		BSR	PRINT_W		* Add 'W'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#cmpa_ea_an_fl,(A1) * Save the flag for where to return to
		BRA	CMPA_PREP_BR	* Call to mask off EA bits 0-5	

	
CMPA_L		BSR	CMPA_HELPER	* Update the buffer
		BSR	PRINT_L		* Add 'L'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#cmpa_ea_an_fl,(A1) * Save the flag for where to return to
		BRA	CMPA_PREP_BR	* Call to mask off EA bits 0-5

CMPA_PREP_BR	CLR.L	D1		* Clear D1
		CLR.L	D4		* Clear D4
		MOVE.W	D0,D4		* Reload the test word
		ANDI.W	#mask0_5,D4	* Mask off bits 0-5
		JMP	TO_BRYAN	* Pass control to EA

CMPA_EA_AN	BSR	PRINT_COMMA	* Add a comma
		BSR	PRINT_AN	* Add the Data register
		JSR	N_PRINT_SPACE	* Call ' ' printing method
		JMP	SET_GOOD_FLAG	* Set good flag	


****************************************************************************
* Sub-routine	: CMPA_HELPER
* Description	:
* This method puts 'CMPA.' into the buffer A4
*****************************************************************************
CMPA_HELPER	LEA 	cmpa,A0		* Load the addres of 'CMPA' into A0
		LEA	cmpa_len,A1	* Load the address of the end of string
CMPA_LOOP	MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	CMPA_LOOP	* Get next ASCII (for safty)
		RTS			* Return to calling method		
	

****************************************************************************
* Sub-routine	: CODE1100
* Description	:
* This is the algorithm for dealing with AND as well as EXG
*****************************************************************************
CODE1100	CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask6_7,D1	* Get An from bits 6-7
		MOVE.B	#shift6,D2	* Load shift value into D2
		LSR.L	D2,D1		* Move 6-7 into 0-1
		CLR.L	D2		* Clear D2
		CMPI.B	#%0011,D1	* Load bad test pattern
		BEQ	SET_BAD_FLAG	* Set the bad flag

		CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask8,D1	* Mask off bits 8
		MOVE.B	#shift8,D2	* Load shift value into D2
		LSR.L	D2,D1		* Move bit 8 into bit 0
		CLR.L	D2		* Clear D2
		CMPI.B	#%0001,D1	* Does bit 8 == 1?
		BNE	OP_AND		* If not equal opcode is AND
	
		CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask6_8,D1	* Mask off 6-8
		MOVE.B	#shift6,D2	* Load the shift value into D2
		LSR.L	D2,D1		* Move 6-8 into 0-2
		CLR.L	D2		* Clear D2
		CMPI.B	#%0100,D1	* D1 == %0100?
		BEQ	OP_AND		* If == opcode is AND

		CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask3_5,D1	* Mask off bits 3-5
		MOVE.B	#shift3,D2	* Load shift value into D2
		LSR.L	D2,D1		* Move bit 3-5 into bit 0-2
		CLR.L	D2		* Clear D2
		CMPI.B	#%0000,D1	* == 0?
		BEQ	OP_EXG		* If == opcode is EXG
		CMPI.B	#%0001,D1	* == 1?
		BEQ	OP_EXG		* If == opcode is AND
		BRA	OP_AND		* If not %0000 or %0001 then opcode is AND


******************************************************************************
* EXG	: EXG is decoded below
******************************************************************************
OP_EXG		LEA	long_flag,A0	* Load the address where the EA lenght flag is stored
		MOVE.W	#long_ea_fl,(A0) * EA length is long
		CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask3_7,D1	* Mask off bits 3-7
		MOVE.B	#shift3,D2	* Load shift value into D2
		LSR.L	D2,D1		* Move bit bits 3-7 into 0-5
		CLR.L	D2		* Clear D2
		CMPI.W	#%00001000,D1	* Is it %00001000?
		BEQ	DATA_REG_TWO	* If == there are two data registers
		CMPI.W	#%00001001,D1	* Is it %00001001?
		BEQ	ADDR_REG_TWO	* If == there are two address registers
		CMPI.W	#%00010001,D1	* Is it %00010001?
		BEQ	DATAX_ADDRY	* DataX,AddrY
		BRA	SET_BAD_FLAG	* Set the bad flag if not an above case

DATA_REG_TWO	CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask9_11,D1	* Mask off bits 9-11
		MOVE.B	#shift9,D2	* Load the shift value into D2
		LSR.L	D2,D1		* Move 9-11 into 0-2
		LEA	buff_reg_fl,A0	* Load the address to save the register type
		MOVE.W	#data_flag,(A0)	* Save the register type
		LEA	buff_reg_nm,A0	* Load the address to save the register number
		MOVE.W	D1,(A0)		* Save the register number

		CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload teh test word
		ANDI.W	#mask0_2,D1	* Mask off bits 0-2
		LEA	exg_reg_fl_y,A0	* Load the address to save the 2nd register
		MOVE.W	#data_flag,(A0)	* Save the register type of the 2nd register
		LEA	exg_reg_nm_y,A0	* Load the address to save the 2nd register number
		MOVE.W	D1,(A0)		* Save the 2nd register number
		BRA	EXG_UPDATE_BUF	* Call the method to update buffer for all three EXG modes
				
ADDR_REG_TWO	CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask9_11,D1	* Mask off bits 9-11
		MOVE.B	#shift9,D2	* Load the shift value into D2
		LSR.L	D2,D1		* Move 9-11 into 0-2
		LEA	buff_reg_fl,A0	* Load the address to save the register type
		MOVE.W	#addr_flag,(A0)	* Save the register type
		LEA	buff_reg_nm,A0	* Load the address to save the register number
		MOVE.W	D1,(A0)		* Save the register number

		CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload teh test word
		ANDI.W	#mask0_2,D1	* Mask off bits 0-2
		LEA	exg_reg_fl_y,A0	* Load the address to save the 2nd register
		MOVE.W	#addr_flag,(A0)	* Save the register type of the 2nd register
		LEA	exg_reg_nm_y,A0	* Load the address to save the 2nd register number
		MOVE.W	D1,(A0)		* Save the 2nd register number
		BRA	EXG_UPDATE_BUF	* Call the method to update buffer for all three EXG modes
	
DATAX_ADDRY	CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask9_11,D1	* Mask off bits 9-11
		MOVE.B	#shift9,D2	* Load the shift value into D2
		LSR.L	D2,D1		* Move 9-11 into 0-2
		LEA	buff_reg_fl,A0	* Load the address to save the register type
		MOVE.W	#data_flag,(A0)	* Save the register type
		LEA	buff_reg_nm,A0	* Load the address to save the register number
		MOVE.W	D1,(A0)		* Save the register number

		CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload teh test word
		ANDI.W	#mask0_2,D1	* Mask off bits 0-2
		LEA	exg_reg_fl_y,A0	* Load the address to save the 2nd register
		MOVE.W	#addr_flag,(A0)	* Save the register type of the 2nd register
		LEA	exg_reg_nm_y,A0	* Load the address to save the 2nd register number
		MOVE.W	D1,(A0)		* Save the 2nd register number
		BRA	EXG_UPDATE_BUF	* Call the method to update buffer for all three EXG modes

EXG_UPDATE_BUF	LEA 	exg,A0		* Load the addres of 'OR' into A0
		LEA	exg_len-1,A1	* Load the address of the end of string
EXG_LOOP	MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	EXG_LOOP	* Get next ASCII (for safty)
		BSR	N_PRINT_SPACE	* Add the space character

		LEA	buff_reg_fl,A0	* Retrieve the X register type
		CMPI.W	#data_flag,(A0)	* Is register X a data register?
		BEQ	REG_X_DATA	* Prepair to deal with the dat register printmethod
		BRA	REG_X_ADDR	* If not a data register, it is an address register

REG_X_DATA	LEA	buff_reg_nm,A0	* Load the memory location where the X register value is stored
		MOVE.W	(A0),D1		* Load D1 with the address number before calling PRINT_DN		
		BSR	PRINT_DN	* Add the data register to the buffer
		BRA	EXG_CAMMA	* Prepair to insert the camma

REG_X_ADDR	BSR	PRINT_AN	* Add the data register to the buffer
		BRA	EXG_CAMMA	* Prepair to insert the camma

EXG_CAMMA	BSR	PRINT_COMMA	* Add the camma to the string

		LEA	exg_reg_fl_y,A0	* Retrieve the Y register type
		CMPI.W	#data_flag,(A0)	* Is register Y a data register?
		BEQ	REG_Y_DATA	* Prepair to deal with the dat register printmethod
		BRA	REG_Y_ADDR	* If not a data register, it is an address register

REG_Y_DATA	LEA	exg_reg_nm_y,A0	* Load the memory location where the Y register value is stored
		MOVE.W	(A0),D1		* Load D1 with the address number before calling PRINT_DN		
		BSR	PRINT_DN	* Add the data register to the buffer
		BSR	EXG_SPACE	* Skip to the line that adds the space to string
		
REG_Y_ADDR	LEA	exg_reg_nm_y,A0 * Retrieve the Y register type
		LEA	buff_reg_nm,A1	* Load the memory location where the X register value is stored
		MOVE.W	(A0),(A1)	* The Address register print method exspects to find its data in buff_reg_num
		BSR	PRINT_AN	* Add the data register to the buffer

EXG_SPACE	BSR	N_PRINT_SPACE	* Add the space character
		JMP	SET_GOOD_FLAG	* Set good flag	


******************************************************************************
* AND	: AND is decoded below
******************************************************************************
OP_AND		LEA 	buff_reg_fl,A0	* Load the address to save the register type
		MOVE.L	#data_flag,(A0)	* Save Dn type register
		CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask9_11,D1	* Mask off 9-11
		MOVE.B	#shift9,D2	* Load shift pattern into D2
		LSR.L	D2,D1		* Move 6-8 into 0-3
 		CLR.L	D2		* Clear D2
		LEA	buff_reg_nm,A0	* Load the addres to save reg number
		MOVE.W	D1,(A0)		* Save the register number

		CLR.L	D1		* Make sure D1 is clear
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask6_8,D1	* Mask off 6-8
		MOVE.B	#shift6,D2	* Load shift pattern into D2
		LSR.L	D2,D1		* Move 6-8 into 0-3
 		CLR.L	D2		* Clear D2	
		CMPI.B	#%0000,D1	* Is it .B <ea>,Dn ?
		BEQ	AND_B_EA_DN	* Deal with it
		CMPI.B	#%0001,D1	* Is it .W <ea>,Dn ?
		BEQ	AND_W_EA_DN	* Deal with it	
		CMPI.B	#%0010,D1	* Is it .L <ea>,Dn ?
		BEQ	AND_L_EA_DN	* Deal with it
		CMPI.B	#%0100,D1	* Is it .B Dn,<ea> ?
		BEQ	AND_B_DN_EA	* Deal with it	
		CMPI.B	#%0101,D1	* Is it .W Dn,<ea> ?
		BEQ	AND_W_DN_EA	* Deal with it	
		CMPI.B	#%0110,D1	* Is it .L Dn,<ea> ?
		BEQ	AND_L_DN_EA	* Deal with it
		BRA	SET_BAD_FLAG	* Set the bad flag if this line of code is reached			

AND_B_EA_DN	BSR	AND_HELPER	* Update the buffer
		BSR	PRINT_B		* Add 'B'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#and_ea_dn_fl,(A1) * Save the flag for where to return to
		BRA	AND_PREP_BR	* Call to mask off EA bits 0-5

AND_W_EA_DN	BSR	AND_HELPER	* Update the buffer
		BSR	PRINT_W		* Add 'W'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#and_ea_dn_fl,(A1) * Save the flag for where to return to
		BRA	AND_PREP_BR	* Call to mask off EA bits 0-5

AND_L_EA_DN	BSR	AND_HELPER	* Update the buffer
		BSR	PRINT_L		* Add 'L'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#and_ea_dn_fl,(A1) * Save the flag for where to return to
		BRA	AND_PREP_BR	* Call to mask off EA bits 0-5

AND_B_DN_EA	BSR	AND_HELPER	* Update the buffer
		BSR	PRINT_B		* Add 'B'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	buff_reg_nm,A0	* Get the saved register number
		MOVE.W	(A0),D1		* load the saved value into D1
		BSR	PRINT_DN	* Add the Data register
		BSR	PRINT_COMMA	* Add a comma
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#and_dn_ea_fl,(A1) * Save the flag for where to return to
		BRA	AND_PREP_BR	* Call to mask off EA bits 0-5

AND_W_DN_EA	BSR	AND_HELPER	* Update the buffer
		BSR	PRINT_W		* Add 'W'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	buff_reg_nm,A0	* Get the saved register number
		MOVE.W	(A0),D1		* load the saved value into D1
		BSR	PRINT_DN	* Add the Data register
		BSR	PRINT_COMMA	* Add a comma
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#and_dn_ea_fl,(A1) * Save the flag for where to return to
		BRA	AND_PREP_BR	* Call to mask off EA bits 0-5

AND_L_DN_EA	BSR	AND_HELPER	* Update the buffer
		BSR	PRINT_L		* Add 'L'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	buff_reg_nm,A0	* Get the saved register number
		MOVE.W	(A0),D1		* load the saved value into D1
		BSR	PRINT_DN	* Add the Data register
		BSR	PRINT_COMMA	* Add a comma
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#and_dn_ea_fl,(A1) * Save the flag for where to return to
		BRA	AND_PREP_BR	* Call to mask off EA bits 0-5
		
AND_PREP_BR	CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask0_5,D1	* Get An from bits 6-7
		MOVE.B	D1,D4		* Read to pass to Bryan
		JMP	TO_BRYAN	* Pass control to EA
	
AND_EA_DN	BSR	PRINT_COMMA	* Add a comma
		LEA	buff_reg_nm,A0	* Get the saved register number
		MOVE.W	(A0),D1		* load the saved value into D1
		BSR	PRINT_DN	* Add the Data register
		JSR	N_PRINT_SPACE	* Call ' ' printing method
		JMP	SET_GOOD_FLAG	* Set good flag	
		
AND_DN_EA	JSR	N_PRINT_SPACE	* Call ' ' printing method
		JMP	SET_GOOD_FLAG	* Set good flag	


****************************************************************************
* Sub-routine	: AND_HELPER
* Description	:
* This method puts 'AND.' into the buffer A4
*****************************************************************************
AND_HELPER	LEA 	and,A0		* Load the addres of 'OR' into A0
		LEA	and_len,A1	* Load the address of the end of string
AND_LOOP	MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	AND_LOOP		* Get next ASCII (for safty)
		RTS			* Return to calling method

****************************************************************************
* Sub-routine	: CODE1101
* Description	:
* This section of code decodes codes that start with 1101. The two opcodes that are decoded
* are ADD and ADDA
*****************************************************************************
CODE1101	CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask6_7,D1	* Get An from bits 6-7
		MOVE.B	#shift6,D2	* Load shift value into D2
		LSR.L	D2,D1		* Move 6-7 into 0-1
		CLR.L	D2		* Clear D2
		CMPI.B	#%0011,D1	* Load bad test pattern
		BEQ	OP_ADDA		* Make sure the op code is ADDA


*****************************************************************************
* ADD	: ADD is decoded below
*****************************************************************************
		LEA 	buff_reg_fl,A0	* Load the address to save the register type
		MOVE.L	#data_flag,(A0)	* Save Dn type register
		CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask9_11,D1	* Mask off 9-11
		MOVE.B	#shift9,D2	* Load shift pattern into D2
		LSR.L	D2,D1		* Move 9-11 into 0-3
 		CLR.L	D2		* Clear D2
		LEA	buff_reg_nm,A0	* Load the addres to save reg number
		MOVE.W	D1,(A0)		* Save the register number

		CLR.L	D1		* Make sure D1 is clear
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask6_8,D1	* Mask off 6-8
		MOVE.B	#shift6,D2	* Load shift pattern into D2
		LSR.L	D2,D1		* Move 6-8 into 0-3
 		CLR.L	D2		* Clear D2	
		CMPI.B	#%0000,D1	* Is it .B <ea>,Dn ?
		BEQ	A_B_EA_DN	* Deal with it
		CMPI.B	#%0001,D1	* Is it .W <ea>,Dn ?
		BEQ	A_W_EA_DN	* Deal with it	
		CMPI.B	#%0010,D1	* Is it .L <ea>,Dn ?
		BEQ	A_L_EA_DN	* Deal with it
		CMPI.B	#%0100,D1	* Is it .B Dn,<ea> ?
		BEQ	A_B_DN_EA	* Deal with it	
		CMPI.B	#%0101,D1	* Is it .W Dn,<ea> ?
		BEQ	A_W_DN_EA	* Deal with it	
		CMPI.B	#%0110,D1	* Is it .L Dn,<ea> ?
		BEQ	A_L_DN_EA	* Deal with it
		BRA	SET_BAD_FLAG	* Set the bad flag if this line of code is reached			

A_B_EA_DN	BSR	ADD_HELPER	* Update the buffer
		BSR	PRINT_B		* Add 'B'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#add_ea_dn_fl,(A1) * Save the flag for where to return to
		BRA	ADD_PREP_BR	* Call to mask off EA bits 0-5

A_W_EA_DN	BSR	ADD_HELPER	* Update the buffer
		BSR	PRINT_W		* Add 'W'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#add_ea_dn_fl,(A1) * Save the flag for where to return to
		BRA	ADD_PREP_BR	* Call to mask off EA bits 0-5

A_L_EA_DN	BSR	ADD_HELPER	* Update the buffer
		BSR	PRINT_L		* Add 'L'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#add_ea_dn_fl,(A1) * Save the flag for where to return to
		BRA	ADD_PREP_BR	* Call to mask off EA bits 0-5

A_B_DN_EA	BSR	ADD_HELPER	* Update the buffer
		BSR	PRINT_B		* Add 'B'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	buff_reg_nm,A0	* Get the saved register number
		MOVE.W	(A0),D1		* load the saved value into D1
		BSR	PRINT_DN	* Add the Data register
		BSR	PRINT_COMMA	* Add a comma
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#add_dn_ea_fl,(A1) * Save the flag for where to return to
		BRA	ADD_PREP_BR	* Call to mask off EA bits 0-5

A_W_DN_EA	BSR	ADD_HELPER	* Update the buffer
		BSR	PRINT_W		* Add 'W'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	buff_reg_nm,A0	* Get the saved register number
		MOVE.W	(A0),D1		* load the saved value into D1
		BSR	PRINT_DN	* Add the Data register
		BSR	PRINT_COMMA	* Add a comma
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#add_dn_ea_fl,(A1) * Save the flag for where to return to
		BRA	ADD_PREP_BR	* Call to mask off EA bits 0-5

A_L_DN_EA	BSR	ADD_HELPER	* Update the buffer
		BSR	PRINT_L		* Add 'L'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	buff_reg_nm,A0	* Get the saved register number
		MOVE.W	(A0),D1		* load the saved value into D1
		BSR	PRINT_DN	* Add the Data register
		BSR	PRINT_COMMA	* Add a comma
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#add_dn_ea_fl,(A1) * Save the flag for where to return to
		BRA	ADD_PREP_BR	* Call to mask off EA bits 0-5
		
ADD_PREP_BR	CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask0_5,D1	* Get An from bits 6-7
		MOVE.B	D1,D4		* Read to pass to Bryan
		JMP	TO_BRYAN	* Pass control to EA
	
ADD_EA_DN	BSR	PRINT_COMMA	* Add a comma
		LEA	buff_reg_nm,A0	* Get the saved register number
		MOVE.W	(A0),D1		* load the saved value into D1
		BSR	PRINT_DN	* Add the Data register
		JSR	N_PRINT_SPACE	* Call ' ' printing method
		JMP	SET_GOOD_FLAG	* Set good flag	
		
ADD_DN_EA	JSR	N_PRINT_SPACE	* Call ' ' printing method
		JMP	SET_GOOD_FLAG	* Set good flag


****************************************************************************
* Sub-routine	: ADD_HELPER
* Description	:
* This method puts 'ADD.' into the buffer A4
*****************************************************************************
ADD_HELPER	LEA 	add,A0		* Load the addres of 'ADD' into A0
		LEA	add_len,A1	* Load the address of the end of string
ADD_LOOP	MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	ADD_LOOP	* Get next ASCII (for safty)
		RTS			* Return to calling method	


****************************************************************************
* ADDA	: ADDA is decoded below
****************************************************************************
OP_ADDA		LEA 	buff_reg_fl,A0	* Load the address to save the register type
		MOVE.L	#addr_flag,(A0)	* Save Address type register
		CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask9_11,D1	* Mask off 9-11
		MOVE.B	#shift9,D2	* Load shift pattern into D2
		LSR.L	D2,D1		* Move 9-11 into 0-3
 		CLR.L	D2		* Clear D2
		LEA	buff_reg_nm,A0	* Load the addres to save reg number
		MOVE.W	D1,(A0)		* Save the register number	

		CLR.L	D1		* Make sure D1 is clear
		CLR.L	D1		* Make sure D2 is clear
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask6_8,D1	* Get An from bits 6-7
		MOVE.B	#shift6,D2	* Load shift value into D2
		LSR.L	D2,D1		* Move 6-7 into 0-1
		CLR.L	D2		* Clear D2
		CMPI.B	#%0011,D1	* Is it size .W ?
		BEQ	ADDA_W		* Deal with size .W
		CMPI.B	#%0111,D1	* Is it size .L ?
		BEQ	ADDA_L		* Deal with size .L
		BRA	SET_BAD_FLAG	* Set the bad flag if this line of code is reached

ADDA_W		BSR	ADDA_HELPER	* Update the buffer
		BSR	PRINT_W		* Add 'W'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#adda_ea_dn_fl,(A1) * Save the flag for where to return to
		BRA	ADDA_PREP_BR	* Call to mask off EA bits 0-5	

	
ADDA_L		BSR	ADDA_HELPER	* Update the buffer
		BSR	PRINT_L		* Add 'L'
		BSR	N_PRINT_SPACE	* Add ' '
		LEA	more_work,A1	* Load the loaction to save return flag
		MOVE.W	#adda_ea_dn_fl,(A1) * Save the flag for where to return to
		BRA	ADDA_PREP_BR	* Call to mask off EA bits 0-5

ADDA_PREP_BR	CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask0_5,D1	* Get An from bits 6-7
		MOVE.B	D1,D4		* Read to pass to Bryan
		JMP	TO_BRYAN	* Pass control to EA

ADDA_EA_AN	BSR	PRINT_COMMA	* Add a comma
		BSR	PRINT_AN	* Add the Data register
		JSR	N_PRINT_SPACE	* Call ' ' printing method
		JMP	SET_GOOD_FLAG	* Set good flag	


****************************************************************************
* Sub-routine	: ADDA_HELPER
* Description	:
* This method puts 'ADDA.' into the buffer A4
*****************************************************************************
ADDA_HELPER	LEA 	adda,A0		* Load the addres of 'ADDA' into A0
		LEA	adda_len-1,A1	* Load the address of the end of string
ADDA_LOOP	MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	ADDA_LOOP	* Get next ASCII (for safty)
		RTS			* Return to calling method


****************************************************************************
* Sub-routine	: CODE1110
* Description	:
* This is the algorithm decodes ASL, ASR, LSL, LSR, ROL, ROR
*****************************************************************************
CODE1110	CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask6_7,D1	* Mask off bits 6-7
		MOVE.B	#shift6,D2	* Load shift value into D2
		LSR.L	D2,D1		* Move 6-7 into 0-1
		CLR.L	D2		* Clear D2
		CMPI.B	#%0011,D1	* Check to see if bits 6-7 == 11
		BEQ	MEM_SHIFT	* Deal with memory shift
		BRA	REG_SHIFT	* Deal with register shift

****************************************************************************
* Memory shift or Register shift?
****************************************************************************
REG_SHIFT	CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask3_4,D1	* Mask off bits 3-4
		MOVE.B	#shift3,D2	* Load shift value into D2
		LSR.L	D2,D1		* Move 3-4 into 0-1
		CLR.L	D2		* Clear D2
		CMPI.B	#%0000,D1	* Is it ASd?
		BEQ	REG_ASD		* Deal with ASd
		CMPI.B	#%0001,D1	* Is is LSd?
		BEQ	REG_LSD		* Deal with LSd
		CMPI.B	#%0011,D1	* Is it ROd?
		BEQ	REG_ROD		* Deal with ROd
		BRA	SET_BAD_FLAG	* If this line is reached set bad flag

MEM_SHIFT	CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask9_11,D1	* Mask off bits 9-11
		MOVE.B	#shift9,D2	* Load shift value into D2
		LSR.L	D2,D1		* Move 6-7 into 0-1
		CLR.L	D2		* Clear D2
		CMPI.B	#%0000,D1	* Is this ASd?
		BEQ	MEM_ASD		* Deal with ASd
		CMPI.B	#%0001,D1	* Is this LSd?
		BEQ	MEM_LSD		* Deal with LSd
		CMPI.B	#%0011,D1	* Is this ROd?
		BEQ	MEM_ROD		* Deal with DOd
		BRA	SET_BAD_FLAG	* If this line is reached set bad flag

****************************************************************************
* ASd (Register Shift)	: ASd is decoded below
****************************************************************************			
REG_ASD		BSR	ASD_HELPER	* Start printing to buffer
		BSR	MASK_BIT_EIGHT	* Get the direction
		CMPI.B	#%0001,D1	* Check direction
		BEQ	RASD_L_H	* If equal direction is L
		BRA	RASD_R_H	* Otherwise directino is R

RASD_L_H	BSR	L_HELPER	* Call L_HELPER
		BRA	RASD_CNT	* Continue
RASD_R_H	BSR	R_HELPER	* Call R_HELPER
RASD_CNT	BSR	MASK_6_7	* Adds size and space to buffer
		BRA	MASK_3_5	* Decide the ASd format	

ASD_POUND	BSR	PRINT_POUND	* Add # to buffer
		BSR	MASK_9_11	* Decide what the #<size> is
		CLR.L	D1		* Clear D1
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask0_2,D1	* Mask off bits 0-2
		BSR	PRINT_DN	* Add the Data register to buffer
		JMP	SET_GOOD_FLAG	* Set good flag	
			
ASDX_DY		CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask9_11,D1	* Mask off bits 9-11
		MOVE.B	#shift9,D2	* Load shift value into D2
		LSR.L	D2,D1		* Move 9-11 into 0-2
		CLR.L	D2		* Clear D2
		BSR	PRINT_DN	* Add the Data register to buffer
		BSR	PRINT_COMMA	* Add a comma to buffer
		CLR.L	D1		* Clear D1
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask0_2,D1	* Mask off bits 0-2
		BSR	PRINT_DN	* Add the Data register to buffer
		JMP	SET_GOOD_FLAG	* Set good flag	
		

****************************************************************************
* ASd (Memory Shift)	: ASd is decoded below
****************************************************************************			
MEM_ASD		BSR	ASD_HELPER	* Start printing to buffer
		BSR	MASK_BIT_EIGHT	* Call helper method to mask off bit 8
		CMPI.B	#%0001,D1	* Check direction
		BEQ	MASD_L_H	* If equal direction is L
		BRA	MASD_R_H	* Otherwise directino is R

MASD_L_H	BSR	L_HELPER	* Call L_HELPER
		BRA	MASD_CNT	* Continue
MASD_R_H	BSR	R_HELPER	* Call R_HELPER
MASD_CNT	BSR	PRINT_W		* add the 'W' 	
		BSR	N_PRINT_SPACE	* Add ' '
		BSR	MASK_0_5	* Put EA bits into D4		
		JMP	TO_BRYAN	* Pass control to EA


****************************************************************************
* LSd (Register Shift)	: LSd is decoded below
****************************************************************************
REG_LSD		BSR	LSD_HELPER	* Start printing to buffer
		BSR	MASK_BIT_EIGHT	* Get the direction
		CMPI.B	#%0001,D1	* Check direction
		BEQ	RLSD_L_H	* If equal direction is L
		BRA	RLSD_R_H	* Otherwise directino is R

RLSD_L_H	BSR	L_HELPER	* Call L_HELPER
		BRA	RLSD_CNT	* Continue
RLSD_R_H	BSR	R_HELPER	* Call R_HELPER
RLSD_CNT	BSR	MASK_6_7	* Adds size and space to buffer
		BRA	MASK_3_5	* Decide the ASd format	

LSD_POUND	BSR	PRINT_POUND	* Add # to buffer
		BSR	MASK_9_11	* Decide what the #<size> is
		CLR.L	D1		* Clear D1
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask0_2,D1	* Mask off bits 0-2
		BSR	PRINT_DN	* Add the Data register to buffer
		JMP	SET_GOOD_FLAG	* Set good flag	
			
LSDX_DY		CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask9_11,D1	* Mask off bits 9-11
		MOVE.B	#shift9,D2	* Load shift value into D2
		LSR.L	D2,D1		* Move 9-11 into 0-2
		CLR.L	D2		* Clear D2
		BSR	PRINT_DN	* Add the Data register to buffer
		BSR	PRINT_COMMA	* Add a comma to buffer
		CLR.L	D1		* Clear D1
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask0_2,D1	* Mask off bits 0-2
		BSR	PRINT_DN	* Add the Data register to buffer
		JMP	SET_GOOD_FLAG	* Set good flag	


****************************************************************************
* LSd (Memory Shift)	: LSd is decoded below
****************************************************************************
MEM_LSD		BSR	LSD_HELPER	* Start printing to buffer
		BSR	MASK_BIT_EIGHT	* Call helper method to mask off bit 8
		CMPI.B	#%0001,D1	* Check direction
		BEQ	MLSD_L_H	* If equal direction is L
		BRA	MLSD_R_H	* Otherwise directino is R

MLSD_L_H	BSR	L_HELPER	* Call L_HELPER
		BRA	MLSD_CNT	* Continue
MLSD_R_H	BSR	R_HELPER	* Call R_HELPER
MLSD_CNT	BSR	PRINT_W		* add the 'W' 	
		BSR	N_PRINT_SPACE	* Add ' '
		BSR	MASK_0_5	* Put EA bits into D4		
		JMP	TO_BRYAN	* Pass control to EA


****************************************************************************
* ROd (Register Shift)	: ROd is decoded below
****************************************************************************
REG_ROD		BSR	ROD_HELPER	* Start printing to buffer
		BSR	MASK_BIT_EIGHT	* Get the direction
		CMPI.B	#%0001,D1	* Check direction
		BEQ	ROD_L_H		* If equal direction is L
		BRA	ROD_R_H		* Otherwise directino is R

ROD_L_H		BSR	L_HELPER	* Call L_HELPER
		BRA	ROD_CNT		* Continue
ROD_R_H		BSR	R_HELPER	* Call R_HELPER
ROD_CNT		BSR	MASK_6_7	* Adds size and space to buffer
		BRA	MASK_3_5	* Decide the ASd format	

ROD_POUND	BSR	PRINT_POUND	* Add # to buffer
		BSR	MASK_9_11	* Decide what the #<size> is
		CLR.L	D1		* Clear D1
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask0_2,D1	* Mask off bits 0-2
		BSR	PRINT_DN	* Add the Data register to buffer
		JMP	SET_GOOD_FLAG	* Set good flag	
			
RODX_DY		CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask9_11,D1	* Mask off bits 9-11
		MOVE.B	#shift9,D2	* Load shift value into D2
		LSR.L	D2,D1		* Move 9-11 into 0-2
		CLR.L	D2		* Clear D2
		BSR	PRINT_DN	* Add the Data register to buffer
		BSR	PRINT_COMMA	* Add a comma to buffer
		CLR.L	D1		* Clear D1
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask0_2,D1	* Mask off bits 0-2
		BSR	PRINT_DN	* Add the Data register to buffer
		JMP	SET_GOOD_FLAG	* Set good flag	


****************************************************************************
* ROd (Memory Shift)	: ROd is decoded below
****************************************************************************
MEM_ROD		BSR	ROD_HELPER	* Start printing to buffer
		BSR	MASK_BIT_EIGHT	* Call helper method to mask off bit 8
		CMPI.B	#%0001,D1	* Check direction
		BEQ	MROD_L_H	* If equal direction is L
		BRA	MROD_R_H	* Otherwise directino is R

MROD_L_H	BSR	L_HELPER	* Call L_HELPER
		BRA	MROD_CNT	* Continue
MROD_R_H	BSR	R_HELPER	* Call R_HELPER
MROD_CNT	BSR	PRINT_W		* add the 'W' 	
		BSR	N_PRINT_SPACE	* Add ' '
		BSR	MASK_0_5	* Put EA bits into D4		
		JMP	TO_BRYAN	* Pass control to EA


****************************************************************************
* Sub-routine	: MASK_3_5
* Description	:
* This method masks off bits 3-5 to choose between form #<data>,Dy and Dx,Dy
* Then it jumps to the correct place to finish 
*****************************************************************************
MASK_3_5	CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask3_5,D1	* Mask off bits 3-5
		MOVE.B	#shift3,D2	* Load shift value into D2
		LSR.L	D2,D1		* Move 6-7 into 0-1
		CLR.L	D2		* Clear D2
		CMPI.B	#%0000,D1	* Is it ASd # ?
		BEQ	ASD_POUND	* Prepair to deal with ASD_POUND
		CMPI.B	#%0100,D1	* Is it ASDX_DY ?
		BEQ	ASDX_DY		* Prepair to deal with ASDX_DY
		CMPI.B	#%0001,D1	* Is it LSD_POUND ?
		BEQ	LSD_POUND	* Prepair to deal with LSD_POUND
		CMPI.B	#%0101,D1	* Is it LSDX_DY ?
		BEQ	LSDX_DY		* Deal with LSDX_DY
		CMPI.B	#%0011,D1		* Is it ROD_POUND ?
		BEQ	ROD_POUND	* Deal with ROD_POUND
		CMPI.B	#%0111,D1	* Is it RODX_DY ?
		BEQ	RODX_DY		* Deal with RODX_DY
		BRA	SET_BAD_FLAG	* If this line is reached set bad flag


****************************************************************************
* Sub-routine	: MASK_0_5
* Description	:
* This method masks off bits 0-5. This method can be used every time I need to pass
* bits 0-5 to EA. It also puts the EA bits into D4
*****************************************************************************
MASK_0_5	CLR.L	D4		* Clear D4
		MOVE.W	D0,D4		* Reload the test word
		ANDI.W	#mask0_5,D4	* Mask off bits 0-5	
		RTS			* Return to calling method


****************************************************************************
* Sub-routine	: MASK_6_7
* Description	:
* This method masks off bits 6-7 to get the size to print to buffer. 
*****************************************************************************
MASK_6_7	CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask6_7,D1	* Mask off bits 6-7
		MOVE.B	#shift6,D2	* Load shift value into D2
		LSR.L	D2,D1		* Move 6-7 into 0-1
		CLR.L	D2		* Clear D2
		CMPI.B	#%0000,D1	* Is it size .B?
		BEQ	MASK_B		* Prepair to deal with .B
		CMPI.B	#%0001,D1	* Is it size .W?
		BEQ	MASK_W		* Prepair to deal with .W
		CMPI.B	#%0010,D1	* Is is size .L?
		BEQ	MASK_L		* Prepair to deal with .L
		BRA	SET_BAD_FLAG	* If this line is reached set bad flag

MASK_B		BSR	PRINT_B		* Print .B
		BRA	MASK_CONT	* Continue

MASK_W		BSR	PRINT_W		* Print .W
		BRA	MASK_CONT	* Continue

MASK_L		BSR	PRINT_L		* Print	.L
MASK_CONT	BSR	N_PRINT_SPACE	* Add ' '	
		RTS	


****************************************************************************
* Sub-routine	: MASK_9_11
* Description	:
* This method masks off bits 9-11 to get the size of the immediate to put in the buffer
* This method also adds a ',' to buffer
*****************************************************************************
MASK_9_11	CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask9_11,D1	* Mask off bits 9-11
		MOVE.B	#shift9,D2	* Load shift value into D2
		LSR.L	D2,D1		* Move 9-11 into 0-2
		CLR.L	D2		* Clear D2
		CMPI.B	#%0000,D1	* Is it #8 ?
		BEQ	ADD_8		* Put #8 in the buffer
		CMPI.B	#%0001,D1	* Is it #1 ?
		BEQ	ADD_1		* Put #1 in the buffer
		CMPI.B	#%0010,D1	* #2 ?
		BEQ	ADD_2		* #2 in buffer
		CMPI.B	#%0011,D1	* #3 ?
		BEQ	ADD_3		* #3 in buffer
		CMPI.B	#%0100,D1	* #4 ?
		BEQ	ADD_4		* #4 in buffer
		CMPI.B	#%0101,D1	* #5 ?
		BEQ	ADD_5		* #5 in buffer
		CMPI.B	#%0110,D1	* #6 ?
		BEQ	ADD_6		* #6 in buffer
		CMPI.B	#%0111,D1	* #7 ?
		BEQ	ADD_7		* #7 in buffer
		BRA	SET_BAD_FLAG	* If this line is reached set bad flag

ADD_1		MOVE.B	#$31,(A4)+	* Add #1 to buffer
		BRA	MASK9_11_CNT	* Continue

ADD_2		MOVE.B	#$32,(A4)+	* Add #2 to buffer
		BRA	MASK9_11_CNT	* Continue

ADD_3		MOVE.B	#$33,(A4)+	* Add #3 to buffer
		BRA	MASK9_11_CNT	* Continue

ADD_4		MOVE.B	#$34,(A4)+	* Add #4 to buffer
		BRA	MASK9_11_CNT	* Continue

ADD_5		MOVE.B	#$35,(A4)+	* Add #5 to buffer
		BRA	MASK9_11_CNT	* Continue

ADD_6		MOVE.B	#$36,(A4)+	* Add #6 to buffer
		BRA	MASK9_11_CNT	* Continue

ADD_7		MOVE.B	#$37,(A4)+	* Add #7 to buffer
		BRA	MASK9_11_CNT	* Continue

ADD_8		MOVE.B	#$38,(A4)+	* Add #8 to buffer
MASK9_11_CNT	BSR	PRINT_COMMA	* Add a comma to buffer	
		RTS			* Return


****************************************************************************
* Sub-routine	: MASK_BIT_EIGHT
* Description	:
* This method masks off bit 8. It is used to help decode ASL, ASR, LSL, LSR, ROL, ROR
*****************************************************************************
MASK_BIT_EIGHT	CLR.L	D1		* Clear D1
		CLR.L	D2		* Clear D2
		MOVE.W	D0,D1		* Reload the test word
		ANDI.W	#mask8,D1	* Mask off bit 8
		MOVE.B	#shift8,D2	* Load shift value into D2
		LSR.L	D2,D1		* Move bit 8 into 1
		CLR.L	D2		* Clear D2	
		RTS			* Return to calling method

****************************************************************************
* Sub-routine	: ASD_HELPER
* Description	:
* This method puts 'AS' into the buffer A4
*****************************************************************************
ASD_HELPER	LEA 	asd,A0		* Load the addres of 'AS' into A0
		LEA	asd_len,A1	* Load the address of the end of string
ASD_LOOP	MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	ASD_LOOP	* Get next ASCII (for safty)
		RTS			* Return to calling method


****************************************************************************
* Sub-routine	: LSD_HELPER
* Description	:
* This method puts 'LS' into the buffer A4
*****************************************************************************
LSD_HELPER	LEA 	lsd,A0		* Load the addres of 'LS' into A0
		LEA	lsd_len,A1	* Load the address of the end of string
LSD_LOOP	MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LSD_LOOP	* Get next ASCII (for safty)
		RTS			* Return to calling method


****************************************************************************
* Sub-routine	: ROD_HELPER
* Description	:
* This method puts 'RO' into the buffer A4
*****************************************************************************
ROD_HELPER	LEA 	rod,A0		* Load the addres of 'RO' into A0
		LEA	rod_len,A1	* Load the address of the end of string
ROD_LOOP	MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	ROD_LOOP	* Get next ASCII (for safty)
		RTS			* Return to calling method


****************************************************************************
* Sub-routine	: L_HELPER
* Description	:
* This method puts '.L' into the buffer A4
*****************************************************************************
L_HELPER	LEA 	dir_l,A0	* Load the addres of '.L' into A0
		LEA	dir_l_len,A1	* Load the address of the end of string
_L_LOOP		MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	_L_LOOP		* Get next ASCII (for safty)
		RTS			* Return to calling method


****************************************************************************
* Sub-routine	: R_HELPER
* Description	:
* This method puts '.R' into the buffer A4
*****************************************************************************
R_HELPER	LEA 	dir_r,A0	* Load the addres of '.R' into A0
		LEA	dir_r_len,A1	* Load the address of the end of string
R_LOOP		MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	R_LOOP		* Get next ASCII (for safty)
		RTS			* Return to calling method


****************************************************************************
* Sub-routine	: CODE1111
* Description	:
* This is the algorithm for dealing with imediates
*****************************************************************************
CODE1111	BRA	SET_BAD_FLAG	* *** NOT IMPLEMENTED! NOT RQUIRED! ***


****************************************************************************
* Sub-routine	: PRINT_AN
* Description	:
* This method adds the Address register to the Buffer. You must have saved 
* the register number in the memory location "buff_reg_nm" found in the 
* data area of the program before calling this method
*
* API:
* D1 holds the data register number
* A0 points to the start of the string
* A1 points to the end of the string
* A4 points to the buffer
*****************************************************************************
PRINT_AN	LEA	buff_reg_nm,A2	* Get the An number
		CMPI.W	#$0000,(A2)	* Is it A0?
		BEQ	LEA_ST_A0	* LOAD A0 string
		CMPI.W	#$0001,(A2)	* Is it A1?
		BEQ	LEA_ST_A1	* LOAD A1 string
		CMPI.W	#$0002,(A2)	* Is it A2?
		BEQ	LEA_ST_A2	* LOAD A2 string
		CMPI.W	#$0003,(A2)	* Is it A3?
		BEQ	LEA_ST_A3	* LOAD A3 string
		CMPI.W	#$0004,(A2)	* Is it A4?
		BEQ	LEA_ST_A4	* LOAD A4 string
		CMPI.W	#$0005,(A2)	* Is it A5?
		BEQ	LEA_ST_A5	* LOAD A5 string				
		CMPI.W	#$0006,(A2)	* Is it A6?
		BEQ	LEA_ST_A6	* LOAD A6 string
		CMPI.W	#$0007,(A2)	* Is it A7?
		BEQ	LEA_ST_A7	* LOAD A7 string

LEA_ST_A0	LEA	_a0,A0		* Load the address of the 'A0' string into A0
		LEA	_a0_len,A1	* Load the address of the end of the string
LEA_A0		MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LEA_A0		* Get next ASCII
		BRA	RT_PRINT_AN	* Get ready to return

LEA_ST_A1	LEA	_a1,A0		* Load the address of the 'A1' string into A0
		LEA	_a1_len,A1	* Load the address of the end of the string
LEA_A1		MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LEA_A1		* Get next ASCII
		BRA	RT_PRINT_AN	* Get ready to return

LEA_ST_A2	LEA	_a2,A0		* Load the address of the 'A2' string into A0
		LEA	_a2_len,A1	* Load the address of the end of the string
LEA_A2		MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LEA_A2		* Get next ASCII
		BRA	RT_PRINT_AN	* Get ready to return

LEA_ST_A3	LEA	_a3,A0		* Load the address of the 'A3' string into A0
		LEA	_a3_len,A1	* Load the address of the end of the string
LEA_A3		MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LEA_A3		* Get next ASCII
		BRA	RT_PRINT_AN	* Get ready to return

LEA_ST_A4	LEA	_a4,A0		* Load the address of the 'A4' string into A0
		LEA	_a4_len,A1	* Load the address of the end of the string
LEA_A4		MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LEA_A4		* Get next ASCII
		BRA	RT_PRINT_AN	* Get ready to return

LEA_ST_A5	LEA	_a5,A0		* Load the address of the 'A5' string into A0
		LEA	_a5_len,A1	* Load the address of the end of the string
LEA_A5		MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LEA_A5		* Get next ASCII
		BRA	RT_PRINT_AN	* Get ready to return

LEA_ST_A6	LEA	_a6,A0		* Load the address of the 'A6' string into A0
		LEA	_a6_len,A1	* Load the address of the end of the string
LEA_A6		MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LEA_A6		* Get next ASCII
		BRA	RT_PRINT_AN	* Get ready to return

LEA_ST_A7	LEA	_a7,A0		* Load the address of the 'A0' string into A0
		LEA	_a7_len,A1	* Load the address of the end of the string
LEA_A7		MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LEA_A7		* Get next ASCII
		BRA	RT_PRINT_AN	* Get ready to return

RT_PRINT_AN	RTS			* Return to caller


****************************************************************************
* Sub-routine	: PRINT_DN
* Description	:
* This method adds the Dn to the Buffer. You must load D1 before calling this method
*
* API:
* D1 holds the data register number
* A0 points to the start of the string
* A1 points to the end of the string
* A4 points to the buffer
*****************************************************************************
PRINT_DN	CMPI.W	#$0000,D1	* Is it D0?
		BEQ	LEA_ST_D0	* LOAD D0 string
		CMPI.W	#$0001,D1	* Is it D1?
		BEQ	LEA_ST_D1	* LOAD D1 string
		CMPI.W	#$0002,D1	* Is it D2?
		BEQ	LEA_ST_D2	* LOAD D2 string
		CMPI.W	#$0003,D1	* Is it D3?
		BEQ	LEA_ST_D3	* LOAD D3 string
		CMPI.W	#$0004,D1	* Is it D4?
		BEQ	LEA_ST_D4	* LOAD D4 string
		CMPI.W	#$0005,D1	* Is it D5?
		BEQ	LEA_ST_D5	* LOAD D5 string				
		CMPI.W	#$0006,D1	* Is it D6?
		BEQ	LEA_ST_D6	* LOAD D6 string
		CMPI.W	#$0007,D1	* Is it D7?
		BEQ	LEA_ST_D7	* LOAD D7 string
	
LEA_ST_D0	LEA	_d0,A0		* Load the address of the 'D0' string into A0
		LEA	_d0_len,A1	* Load the address of the end of the string
LEA_D0		MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LEA_D0		* Get next ASCII
		BRA	PRINT_DN_RT	* Get ready to return

LEA_ST_D1	LEA	_d1,A0		* Load the address of the 'D1' string into A0
		LEA	_d1_len,A1	* Load the address of the end of the string
LEA_D1		MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LEA_D1		* Get next ASCII
		BRA	PRINT_DN_RT	* Get ready to return

LEA_ST_D2	LEA	_d2,A0		* Load the address of the 'D2' string into A0
		LEA	_d2_len,A1	* Load the address of the end of the string
LEA_D2		MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LEA_D2		* Get next ASCII
		BRA	PRINT_DN_RT	* Get ready to return

LEA_ST_D3	LEA	_d3,A0		* Load the address of the 'D3' string into A0
		LEA	_d3_len,A1	* Load the address of the end of the string
LEA_D3		MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LEA_D3		* Get next ASCII
		BRA	PRINT_DN_RT	* Get ready to return

LEA_ST_D4	LEA	_d4,A0		* Load the address of the 'D4' string into A0
		LEA	_d4_len,A1	* Load the address of the end of the string
LEA_D4		MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LEA_D4		* Get next ASCII
		BRA	PRINT_DN_RT	* Get ready to return

LEA_ST_D5	LEA	_d5,A0		* Load the address of the 'D5' string into A0
		LEA	_d5_len,A1	* Load the address of the end of the string
LEA_D5		MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LEA_D5		* Get next ASCII
		BRA	PRINT_DN_RT	* Get ready to return

LEA_ST_D6	LEA	_d6,A0		* Load the address of the 'D6' string into A0
		LEA	_d6_len,A1	* Load the address of the end of the string
LEA_D6		MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LEA_D6		* Get next ASCII
		BRA	PRINT_DN_RT	* Get ready to return

LEA_ST_D7	LEA	_d7,A0		* Load the address of the 'D7' string into A0
		LEA	_d7_len,A1	* Load the address of the end of the string
LEA_D7		MOVE.B	(A0)+,(A4)+	* Update the buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LEA_D7		* Get next ASCII
		BRA	PRINT_DN_RT	* Get ready to return

PRINT_DN_RT	RTS			* Return to caller


****************************************************************************
* Sub-routine	: PRINT_SIZE
* Description	: This method masks off bits 6-7, rotates them into bits 0-1 and places
*                  the result into D1. Then it calls the apropriate print method
* API:
* D0 holds the original test word
* D1 holds the binary vlue that indicates the size (.B, .W, .L) if bits 6-7 == 11 return bad flag in D1
* D2 holds the shift pattern
****************************************************************************
PRINT_SIZE	CLR.L	D1		* Make sure D1 is clear
		CLR.L	D2		* Make sure D2 is clear
		MOVE.W	D0,D1		* Make a copy of the test word
		ANDI.W	#mask6_7,D1	* Mask off 6-7
		MOVE.B	#shift6,D2	* Load shift pattern into D2
		LSR.L	D2,D1		* Shift 6-7 into 0-1
		CMPI.B	#%0000,D1	* Is it size byte?
		BEQ	SIZE_BYTE	* Deal with byte
		CMPI.B	#%0001,D1	* Is it size word?
		BEQ	SIZE_WORD	* Deal with word
		CMPI.B	#%0010,D1	* IS it size long?
		BEQ	SIZE_LONG	* Deal with long
		BRA	BAD_SIZE	* Deal with bad size

SIZE_BYTE	BSR	PRINT_B		* Print byte
		CLR.L	D1		* Clearing D1 sets good flag
		BRA	RETURN		* get ready to return	
SIZE_WORD	BSR	PRINT_W		* Print word
		CLR.L	D1		* Clearing D1 sets good flag
		BRA	RETURN		* get ready to return
SIZE_LONG	BSR	PRINT_L		* Print long
		CLR.L	D1		* Clearing D1 sets good flag
		BRA	RETURN		* get ready to return
BAD_SIZE	CLR.L	D1		* Clear D1
		ADDI.W	#bad_flag,D1	* Set the bad flag
RETURN		RTS			* Go back to line after call


*****************************************************************************
* Sub-routine	: LOAD_IMMED_CODE
* Description	:
*		This method loads the fake opcode size code into D4 so that
*		 the EA person can fetch the immediate value to put into the operand field
*
* API:
* D0 holds the original test word
* D1 holds the binary vlue that indicates the size (.B, .W, .L) if bits 6-7 == 11 return bad flag in D1
* D2 holds the shift pattern
* D4 holds the pattern to pass to the EA person
*****************************************************************************
LOAD_IMMED_CODE	CLR.L	D1		* Make sure D1 is clear
		CLR.L	D2		* Make sure D2 is clear
		MOVE.W	D0,D1		* Make a copy of the test word
		ANDI.W	#mask6_7,D1	* Mask off 6-7
		MOVE.B	#shift6,D2	* Load shift pattern into D2
		LSR.L	D2,D1		* Shift 6-7 into 0-1
		CMPI.B	#%0000,D1	* Is it size byte?
		BEQ	_SIZE_BYTE	* Deal with byte
		CMPI.B	#%0001,D1	* Is it size word?
		BEQ	_SIZE_WORD	* Deal with word
		CMPI.B	#%0010,D1	* IS it size long?
		BEQ	_SIZE_LONG	* Deal with long
		BRA	_BAD_SIZE	* Deal with bad size

_SIZE_BYTE	ADDI.L	#imed_byte,D4	* Load the fake immediate code of size byte
		CLR.L	D1		* Clearing D1 sets good flag
		BRA	_RETURN		* get ready to return	
_SIZE_WORD	ADDI.L	#imed_word,D4	* Load the fake immediate code of size byte
		CLR.L	D1		* Clearing D1 sets good flag
		BRA	_RETURN		* get ready to return
_SIZE_LONG	ADDI.L	#imed_long,D4	* Load the fake immediate code of size byte
		CLR.L	D1		* Clearing D1 sets good flag
		BRA	_RETURN		* get ready to return
_BAD_SIZE	CLR.L	D1		* Clear D1
		ADDI.W	#bad_flag,D1	* Set the bad flag
_RETURN		RTS			* Go back to line after call


*****************************************************************************
* Sub-routine	: PRINT_B
* Description	:
*	Add a 'B' character to the buffer
*
* API:
* A0 holds the address of the 'B' string
* A1 holds the address of the end of the 'B' string
* A4 holds the address to be written to in the buffer
*****************************************************************************
PRINT_B		LEA 	__b,A0		* Load the addres of 'B' into A0
		LEA	b_len-1,A1	* Load the address of the end of string
B_LOOP		MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	B_LOOP		* Get next ASCII (for safty)
		RTS			* Return to calling method


*****************************************************************************
* Sub-routine	: PRINT_W
* Description	:
*	Add a 'W' character to the buffer
*
* API:
* A0 holds the address of the 'W' string
* A1 holds the address of the end of the 'W' string
* A4 holds the address to be written to in the buffer
*****************************************************************************
PRINT_W		LEA 	__w,A0		* Load the addres of 'W' into A0
		LEA	w_len-1,A1	* Load the address of the end of string
W_LOOP		MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	W_LOOP		* Get next ASCII (for safty)
		RTS			* Return to calling method


*****************************************************************************
* Sub-routine	: PRINT_L
* Description	:
*	Add a 'L' character to the buffer
*
* API:
* A0 holds the address of the 'L' string
* A1 holds the address of the end of the 'L' string
* A4 holds the address to be written to in the buffer
*****************************************************************************
PRINT_L		LEA	long_flag,A0	* Load the address where the EA lenght flag is stored
		MOVE.W	#long_ea_fl,(A0) * EA length is long

		LEA 	__l,A0		* Load the addres of 'L' into A0
		LEA	l_len-1,A1	* Load the address of the end of string
L_LOOP		MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	L_LOOP		* Get next ASCII (for safty)
		RTS			* Return to calling method


*****************************************************************************
* Sub-routine	: N_PRINT_SPACE
* Description	:
*	Add a space character to the buffer
*
* API:
* A0 holds the address of the ' ' string
* A1 holds the address of the end of the ' ' string
* A4 holds the address to be written to in the buffer
*****************************************************************************
N_PRINT_SPACE	LEA 	spa,A0		* Load the addres of spa into A0
		LEA	spa_len-1,A1	* Load the address of the end of string
N_SP_LOOP	MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	N_SP_LOOP	* Get next ASCII (for safty)
		RTS			* Return to calling method


*****************************************************************************
* Sub-routine	: PRINT_POUND
* Description	:
*	Add a # character to the buffer
*
* API:
* A0 holds the address of the '#' string
* A1 holds the address of the end of the '#' string
* A4 holds the address to be written to in the buffer
*****************************************************************************
PRINT_POUND	LEA 	pound,A0	* Load the addres of pound into A0
		LEA	pound_len-1,A1	* Load the address of the end of string
LOOP_POUND	MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LOOP_POUND	* Get next ASCII (for safty)
		RTS			* Return to calling method


*****************************************************************************
* Sub-routine	: PRINT_COMMA
* Description	:
*	Add a comma character to the buffer
*
* API:
* A0 holds the address of the ',' string
* A1 holds the address of the end of the ',' string
* A4 holds the address to be written to in the buffer
*****************************************************************************
PRINT_COMMA	LEA 	comma,A0	* Load the addres of camma into A0
		LEA	comma_len-1,A1	* Load the address of the end of string
LOOP_CAMMA	MOVE.B	(A0)+,(A4)+	* Update the Buffer and advance pointer
		CMPA.L	A0,A1		* Check for the end of the string
		BNE	LOOP_CAMMA	* Get next ASCII (for safty)
		RTS			* Return to calling method


*****************************************************************************
* Sub-routine	: SET_BAD_FLAG
* Description	:
*	Set the bad flag and return to I/O
*
* API:
* D4 holds the flag to be passed
*****************************************************************************
SET_BAD_FLAG	CLR	D4			* Make sure there are no artifacts in D4
		ADDI.W	#bad_flag,D4		* Set the bad flag
		
		MOVE.B	#$24,(A6)+		* Put a $ after the address
		MOVEA	A6,A0			* Set up pass to MEM_TO_ASCII
		MOVE.W	#4,D3			* Convert to 8 ASCII chars
		BSR	MEM_TO_ASCII		* Convert address to ASCII
		ADDA	#8,A6			* Move 8 bytes forword Do not over write buffer!
		
		JMP	TO_SAHAR		* Return control to I/O


*****************************************************************************
* Sub-routine	: SET_GOOD_FLAG
* Description	:
*	Set the good flag and return to I/O
*
* API:
* D4 holds the flag to be passed
*****************************************************************************
SET_GOOD_FLAG	CLR	D4			* Make sure there are no artifacts in D4
		ADDI.W	#good_flag,D4		* Set the good flag
		JMP	TO_SAHAR		* Return control to I/O


******************************************************************************
* Sub-routine	: TO_SAHAR
* Description	: This is where control is passed back to Sahar, to process the I/O
*****************************************************************************
TO_SAHAR	JMP	FLAG_CHECK		* Retrun to Sahar to process I/O




******************************************************************************
* Sub-routine	: TO_BRYAN
* Description	: This is where control is passed to user, to process the EA
*		    then control is returned to me to check the flag status.
*		    if the good flage is not set it calls the SET_BAD_FLAG method
*		    and returns control to Sahar in I/O. If the good flag is set
*		    it checks to see what is in (A1) and decieds based on the flag
*		    it finds, it will return to the poper location to continue processing
*		    the opcode.
* API:
* A1 holds the address of the flag to check
* D2 holds the value of no_more_wk
* D4 holds the flag value from EA work
*****************************************************************************
TO_BRYAN	LEA	long_flag,A0		* Load the address where the EA lenght flag is stored
		CMPI.W	#long_ea_fl,(A0) 	* Check for EA long flag
		BNE	PASS_EA			* If not equal no need to add 1 in most signigficant digit of byte
		ORI.B	#%10000000,D4		* If equal OR to D4 
PASS_EA		BSR	DECODE_EA		* Call EA to get the Efective Address
		CMPI.W	#good_flag,D4		* Check for good flag
		BNE	NO_GOOD			* If good flag is not set the opcode is not valid
		LEA	more_work,A1		* Load the address of the more work status
		CMPI.W	#no_more_wk,(A1)	* Check to see if we are done	
		BEQ	ALL_DONE		* If (A1) holds value $FFFF, OP and EA are done send to I/O
		CMPI.W	#lea_rt_fl,(A1)		* Need to return to LEA?
		BEQ	_RT_LEA			* If equal go back and finish LEA work
		CMPI.W	#andirt_fl,(A1)		* Need to return to ANDI?		
		BEQ	RT_ANDI			* If equal go back and finish ANDI work 
		CMPI.W	#subirt_fl,(A1)		* Need to return to SUBI?
		BEQ	RT_SUBI			* If equal go back and finish SUBI
		CMPI.W	#addirt_fl,(A1)		* Need to return to ADDI?
		BEQ	RT_ADDI			* If equal go back and finish ADDI
		CMPI.W	#eorirt_fl,(A1)		* Need to return to EORI?
		BEQ	RT_EORI			* If equal go back to EORI
		CMPI.W	#cmpirt_fl,(A1)		* Need to return to CMPI?
		BEQ	RT_CMPI			* If equal return to CMPI
		CMPI.W	#ori_rt_fl,(A1)		* Need to return to ORI?
		BEQ	RT_ORI			* If equal return to ORI
		CMPI.W	#or_ea_dn_fl,(A1)	* Need to return to OR_EA_DN ?
		BEQ	OR_EA_DN		* If equal return to OR_EA_DN
		CMPI.W	#or_dn_ea_fl,(A1)	* Need to return to OR_DN_EA ?
		BEQ	OR_DN_EA		* If equal return to OR_DN_EA
		CMPI.W	#add_ea_dn_fl,(A1)	* Need to return to ADD_EA_DN ?
		BEQ	ADD_EA_DN		* If equal return to ADD_EA_DN
		CMPI.W	#add_dn_ea_fl,(A1)	* Need to return to ADD_DN_EA ?
		BEQ	ADD_DN_EA		* If equal return to ADD_DN_EA
		CMPI.W	#adda_ea_dn_fl,(A1)	* Need to return to ADDA_EA_AN ?
		BEQ	ADDA_EA_AN		* If equal return to ADDA_EA_AN	
		CMPI.W	#and_dn_ea_fl,(A1)	* Need to return to AND_DN_EA ?
		BEQ	AND_DN_EA		* If equl return to AND_DN_EA
		CMPI.W	#and_ea_dn_fl,(A1)	* Need to return to AND_EA_DN ?
		BEQ	AND_EA_DN		* If equal return to AND_EA_DN
		CMPI.W	#sub_ea_dn_fl,(A1)	* Return to SUB_EA_DN?
		BEQ	SUB_EA_DN		* Go to SUB_EA_DN
		CMPI.W	#sub_dn_ea_fl,(A1)	* Return to SUB_DN_EA?
		BEQ	SUB_DN_EA		* Go to SUB_DN_EA
		CMPI.W	#suba_ea_an_fl,(A1)	* Return to SUBA_EA_AN?
		BEQ	SUBA_EA_AN		* Go to SUBA_EA_AN
		CMPI.W	#cmpa_ea_an_fl,(A1)	* Retrun to CMPA_EA_AN?
		BEQ	CMPA_EA_AN		* Go to CMPA_EA_AN
		CMPI.W	#eor_dn_ea_fl,(A1)	* Retrun to EOR_DN_EA?
		BEQ	EOR_DN_EA		* Go to EOR_DN_EA
		CMPI.W	#cmp_ea_dn_fl,(A1)	* Return to CMP_EA_DN?
		BEQ	CMP_EA_DN		* Go to CMP_EA_DN
		CMPI.W	#move_b_fl,(A1)		* Return to RT_MOVE_B?
		BEQ	RT_MOVE_B		* Go to RT_MOVE_B
		CMPI.W	#move_w_fl,(A1)		* Return to RT_MOVE_W?
		BEQ	RT_MOVE_W		* Go to RT_MOVE_W
		CMPI.W	#move_l_fl,(A1)		* Return to RT_MOVE_L?
		BEQ	RT_MOVE_L		* Go to RT_MOVE_L
		CMPI.W	#movea_w_fl,(A1)	* Return to RT_MOVEA_W?
		BEQ	RT_MOVEA_W		* Go to RT_MOVEA_W
		CMPI.W	#movea_l_fl,(A1)	* Retrun to RT_MOVEA_L?
		BEQ	RT_MOVEA_L		* Go to RT_MOVEA_L
		CMPI.W	#mm_ea_reg_fl,(A1)	* Retrun to MM_EA_REG?
		BEQ	MM_EA_REG		* Go to MM_EA_REG
		CMPI.W	#mm_reg_ea_fl,(A1)	* Return to MM_REG_EA?
		BEQ	MM_REG_EA		* Go to MM_REG_EA
		BRA	SET_BAD_FLAG		* If this line is reached set bad flag
	
ALL_DONE	JMP	SET_GOOD_FLAG		* Make sure the good flage is set in a way that I/O exspects to see it

NO_GOOD		JMP	SET_BAD_FLAG		* Make sure the bad flage is set in a way that I/O exspects to see it			

**************************************************************
* Sub-routine: DECODE_EA 
* Description: This is the primary subrutine for decoding the effective address and is 
*		responsible for calling all the other support subrutines
* Registers	:	A3 stores the address of the input buffer
*			A4 stores address of the output buffer
*			D0 stores a copy of D4 for manipulating
*			D1 stores a copy of D4 for manipulating
*			D4 stores the effective address
*			D5 stores a copy of D4 for manipulating
*			D6 stores a copy of D4 for manipulating
**************************************************************
DECODE_EA	MOVEM.L	reg_set_8,-(SP)		* Save main registers on stack so they can be reused by sub
		ANDI.B	#$FF,D4			* clear the bits we don't care about
		CLR	D0			* clean the register
		CLR	D5			* clean the register
		CLR	D6			* clean the register
		MOVE.B 	D4,D0			* make a copy of D4
		MOVE.B	D4,D5			* make a copy of D4
		MOVE.B	D4,D6			* make a copy of D4
		AND.B	#$07,D0			* isolate register/special
		AND.B	#$80,D5			* isolate the long word bit
		AND.B	#$40,D6			* isolate the list ea bit
		CMPI.B	#$40,D6			* is this is a list of eas?
		BEQ	DECODE_LIST		* yes, then decode them
		MOVE.B	D4,D1			* make another copy of D4
		AND.B	#$38,D1			* isolate mode
		ROR.B	#$3,D1			* rotate into position
		BRA	DECODE_MODE		* begin decode the mode
DCD_EA_DONE	CLR.L	D4	
		MOVEM.L	(SP)+,reg_set_8		* Restore registers before leaving sub
		RTS
BAD_EA_DONE	MOVEM.L	(SP)+,reg_set_8		* Restore registers before leaving sub
		RTS
		
**************************************************************
* Sub-routine: DECODE_MODE
* Written by : Bryan Tinsly
* Date       : 5/22/2010 
* Description: decodes the effective address mode
* Registers	:	A1 stores the starting jump location
*			A3 stores the address of the input buffer
*			A4 stores address of the output buffer
*			D4 stores the effective address
**************************************************************
DECODE_MODE	LEA	MODE_OPS,A1
		ASL.B	#$2,D1			* multiply by 4 in to position
		JMP	00(A1,D1)		* jump to the address that correlates with the mode
MODE_OPS	BRA	DECODE_DRD		* Data Register Direct Mode
		BRA	DECODE_ARD		* Address Register Direct Mode
		BRA	DECODE_ARI		* Address Register Indirect Mode
		BRA	DECODE_ARIPI		* Address Register Indirect with Postincrement Mode
		BRA	DECODE_ARIPD		* Address Register Indirect with Predecrement Mode
		BRA	DECODE_ARID		* Address Register Indirect with Displacement Mode
		BRA	DECODE_ARIWI		* Address Register Indirect with Index Mode
		BRA	DECODE_SPCL		* (111)(XXX) modes
DCD_MD_DONE	BRA	DCD_EA_DONE		* we're done here
**************************************************************
* Sub-routine: DCD_MD_ERROR
* Written by : Bryan Tinsly
* Date       : 5/22/2010 
* Description: Sets the bad EA flag for EAs I can't decode
* Registers	:	D4 stores the effective address
**************************************************************
DCD_MD_ERROR	CLR 	D4
		MOVE.B	#$1,D4
		BRA	BAD_EA_DONE

**************************************************************
* Sub-routine: DECODE_SPCL
* Written by : Bryan Tinsly
* Date       : 5/22/2010 
* Description: Handles (111)(XXX) modes
* Registers	:	A3 stores the address of the input buffer
*			A4 stores address of the output buffer
*			D4 stores the effective address
*			
**************************************************************
DECODE_SPCL	LEA	SPCL_OPS,A1
		ASL.B	#$2,D0			* multiply by 4
		JMP	00(A1,D0)		* jump  to mode address
SPCL_OPS	BRA	DECODE_AWA 		* Absolute Short Addressing Mode
		BRA	DECODE_ALA		* Absolute Long Addressing Mode
		BRA	DECODE_PCD 		* Program Counter Indirect with Displacement Mode
		BRA	DCD_MD_ERROR 		* Bad EA
		BRA	DCD_MD_ERROR		* Bad EA
		BRA	DECODE_ID		* Immediate Data
		BRA	DCD_MD_ERROR		* Bad EA
		BRA	DCD_MD_ERROR		* Bad EA
		BRA	DCD_MD_ERROR		* Bad EA
		BRA	DCD_MD_ERROR 		* Bad EA
		BRA	DCD_MD_ERROR		* Bad EA
		BRA	DCD_MD_ERROR		* Bad EA
		BRA	DCD_MD_ERROR		* Bad EA
		BRA	DCD_EA_DONE
**************************************************************
* Sub-routine: DECODE_DRD
* Written by : Bryan Tinsly
* Date       : 5/22/2010 
* Description: mode(000) Data Register Direct Mode
* Registers	:	A0 output source
*			D0 register (n)
**************************************************************
DECODE_DRD	LEA 	mode_drd,A0
		ADDA	#$1,A0		*increment to the byte we're going to modify
		MOVE.B	#$30,(A0)	*reset (n) to 0 for D(n)
		ADD.B	D0,(A0)		*specify which register 0 to 7 
		LEA	mode_drd,A0	*point A0 at the start of the output for the output buffer
		BSR	WRITE_OUTPUT	*write to the output buffer
		BRA	DCD_EA_DONE
**************************************************************
* Sub-routine: DECODE_ARD
* Written by : Bryan Tinsly
* Date       : 5/22/2010 
* Description: mode(001) Address Register Direct Mode
* Registers	:	A0 output source
*			D0 register (n)
**************************************************************
DECODE_ARD	LEA 	mode_ard,A0
		ADDA	#$1,A0		*increment to the byte we're going to modify
		MOVE.B	#$30,(A0)	*reset (n) to 0 for A(n)
		ADD.B	D0,(A0)		*specify which register 0 to 7 
		LEA	mode_ard,A0	*point A0 at the start of the output for the output buffer
		BSR	WRITE_OUTPUT	*write to the output buffer
		BRA	DCD_EA_DONE
**************************************************************
* Sub-routine: DECODE_ARI
* Written by : Bryan Tinsly
* Date       : 5/22/2010 
* Description: mode(010) Address Register Indirect Mode
* Registers	:	A0 output source
*			D0 register (n)
**************************************************************
DECODE_ARI	LEA 	mode_ari,A0
		ADDA	#$2,A0		*increment to the byte we're going to modify
		MOVE.B	#$30,(A0)	*reset (n) to 0 for A(n)
		ADD.B	D0,(A0)		*specify which register 0 to 7 
		LEA	mode_ari,A0	*point A0 at the start of the output for the output buffer
		BSR	WRITE_OUTPUT	*write to the output buffer
		BRA	DCD_EA_DONE

**************************************************************
* Sub-routine: DECODE_ARIPI 
* Written by : Bryan Tinsly
* Date       : 5/22/2010 
* Description: mode(011) Address Register Indirect with Postincrement Mode
* Registers	:	A0 output source
*			D0 register (n)
**************************************************************
DECODE_ARIPI	LEA 	mode_aripi,A0
		ADDA	#$2,A0		*increment to the byte we're going to modify
		MOVE.B	#$30,(A0)	*reset (n) to 0 for A(n)
		ADD.B	D0,(A0)		*specify which register 0 to 7 
		LEA	mode_aripi,A0	*point A0 at the start of the output for the output buffer
		BSR	WRITE_OUTPUT	*write to the output buffer
		BRA	DCD_EA_DONE
**************************************************************
* Sub-routine: DECODE_ARIPD
* Written by : Bryan Tinsly
* Date       : 5/22/2010 
* Description: mode(100) Address Register Indirect with Predecrement Mode
* Registers	:	A0 output source
*			D0 register (n)
**************************************************************
DECODE_ARIPD	LEA 	mode_aripd,A0
		ADDA	#$3,A0		*increment to the byte we're going to modify
		MOVE.B	#$30,(A0)	*reset (n) to 0 for A(n)
		ADD.B	D0,(A0)		*specify which register 0 to 7 
		LEA	mode_aripd,A0	*point A0 at the start of the output for the output buffer
		BSR	WRITE_OUTPUT	*write to the output buffer
		BRA	DCD_EA_DONE

**************************************************************
* Sub-routine: DECODE_ARID
* Written by : Bryan Tinsly
* Date       : 5/22/2010 
* Description: mode(101)EA = (An) + d16 Address Register Indirect with Displacement Mode
* Registers	:	A0 output source
*			A3 input buffer
*			A4 output buffer
*			D0 ea word
*			D3 ascii counter
**************************************************************
DECODE_ARID	MOVEM.L	reg_set_7,-(SP)		* Save main registers on stack
		MOVE.W	(A3),D0		* grab a word from the input buffer
		ADDA	#2,A3		* move the input buffer POINTER forward
		MOVE.B	#$24,(A4)+	* add the dollar sign to the output buffer and increment the pointer forward
		MOVEA	A4,A0		* pass the address of the output buffer to A0
		MOVE.B	#$4,D3		* number of hex values to convert (passed to MEM_TO_ASCII)
		BSR	MEM_TO_ASCII	* convert the long word input to ascii in the output buffer
		MOVEM.L	(SP)+,reg_set_7		* Restore registers before leaving sub
		ADDA	#$2,A3		* increment past the word we grabed
		ADDA	#$5,A4		* move the output buffer pointer forward the ascii length of the long word
		LEA 	mode_ari,A0	* set up the output to be printed
		ADDA	#$2,A0		* increment to the byte we're going to modify
		MOVE.B	#$30,(A0)	* reset (n) to 0 for A(n)
		ADD.B	D0,(A0)		* specify which register 0 to 7 
		LEA	mode_ari,A0	* point A0 at the start of the output for the output buffer
		BSR	WRITE_OUTPUT	* write to the output buffer
		BRA	DCD_EA_DONE


**************************************************************
* Sub-routine: DECODE_ARIWI
* Written by : Bryan Tinsly
* Date       : 5/22/2010 
* Description: mode(110) Address Register Indirect with Index
* Registers	:	A0 output to be sent to output buffer
*			A3 stores the address of the input buffer
*			A4 stores address of the output buffer
*			D0 stores a copy of D4 for manipulating
*			D2 stores the word that follows the op code
**************************************************************
DECODE_ARIWI	MOVEM.L	reg_set_7,-(SP)		* Save main registers on stack
		MOVE.W	(A3),D2		* grab the word that follows and move the pointer forward a word
		MOVE.B	#$24,(A4)+	* add the dollar sign to the output buffer and increment the pointer forward
		MOVEA	A4,A0		* make a copy of output buffer ptr in A0
		CLR	D0		* clear d0 before using
		MOVE.B	D2,D0		* store a copy of D2 in D0
		MOVE.B	#$4,D3		* number of hex values to convert (passed to MEM_TO_ASCII)
		BSR	MEM_TO_ASCII	* convert the word input to ascii in the output buffer
		MOVEM.L	(SP)+,reg_set_7 * load the registers we saved
		ADDA	#$1,A4		* increment past the dollar sign in the output buffer	
		LEA 	mode_ariwi,A0	* set the ouput
		ADDA	#$2,A0		* move to the byte we're going to modify
		MOVE.B	#$30,(A0)	* reset (n) to 0 for A(n)
		ADD.B	D0,(A0)		* specify which register 0 to 7 
		ADDA	#$3,A0		* move to the byte we're going to modify
		MOVE.B	#$30,(A0)	* reset (n) to 0 for A(n)
		MOVE.W	(A3),D2		* grab a word from the input buffer
		ROL	#$4,D2		* rotate into position
		AND.L	#$0000000F,D2	* isolate the register bits
		ADD.B	D2,(A0)		* specify which register 0 to 7
		MOVE.W	(A3),D2		* grab the same word from the input buffer
		ROR	#$8,D2		* rotate into position
		AND.L	#$0000000F,D2	* isolate the register bits
		ADDA	#$2,A0		* move to the byte we're going to modify
		MOVE.B	#$57,(A0)	* change to W
		CMPI.B	#$4,D2		* is it a word?
		BEQ	EA_CONTINUE	* yes? then continue
		MOVE.B	#$4C,(A0)	* otherwise its an L (long word)
EA_CONTINUE	ADDA	#$2,A3		* increment to account for output
		ADDA	#$4,A4		* move the output buffer pointer forward the ascii length of the long word		
		LEA 	mode_ariwi,A0	* set output
		BSR	WRITE_OUTPUT	* write to the output buffer
		BRA	DCD_EA_DONE

**************************************************************
* Sub-routine: DECODE_AWA
* Written by : Bryan Tinsly
* Date       : 5/22/2010 
* Description: mode(111)(000) Absolute Short Addressing Mode
* Registers	:	A0 output to be sent to output buffer
*			A3 stores the address of the input buffer
*			A4 stores address of the output buffer
*			D0 stores a copy of D4 for manipulating
*			D3 stores number of ascii to convert
**************************************************************
DECODE_AWA	MOVE.W	(A3),D0		* grab a word from the input buffer
		ADDA	#2,A3		* move the input buffer POINTER forward
		MOVE.B	#$24,(A4)+	* add the dollar sign to the output buffer and increment the pointer forward
		MOVEA	A4,A0		* pass the address of the output buffer to A0
		MOVE.B	#$4,D3		* number of hex values to convert (passed to MEM_TO_ASCII)
		BSR	MEM_TO_ASCII	* convert the long word input to ascii in the output buffer
		ADDA	#4,A4		* move the output buffer pointer forward the ascii length of the long word
		BRA	DCD_EA_DONE

**************************************************************
* Sub-routine: DECODE_ALA
* Written by : Bryan Tinsly
* Date       : 5/22/2010 
* Description: mode(111)(001) Absolute Long Addressing Mode
* Registers	:	A0 output to be sent to output buffer
*			A3 stores the address of the input buffer
*			A4 stores address of the output buffer
*			D0 stores a copy of D4 for manipulating
*			D3 stores number of ascii to convert
**************************************************************
DECODE_ALA	MOVE.L	(A3),D0		* grab a word from the input buffer
		ADDA	#4,A3		* move the input buffer POINTER forward
		MOVE.B	#$24,(A4)+	* add the dollar sign to the output buffer and increment the pointer forward
		MOVEA	A4,A0		* pass the address of the output buffer to A0
		MOVE.B	#$8,D3		* number of hex values to convert (passed to MEM_TO_ASCII)
		BSR	MEM_TO_ASCII	* convert the long word input to ascii in the output buffer
		ADDA	#8,A4		* move the output buffer pointer forward the ascii length of the long word
		BRA	DCD_EA_DONE

**************************************************************
* Sub-routine: DECODE_PCD
* Written by : Bryan Tinsly
* Date       : 5/22/2010 
* Description: mode(111)(010) Program Counter Indirect with Index (Base Displacement) Mode
* Registers	:	A0 output to be sent to output buffer
*			A3 stores the address of the input buffer
*			A4 stores address of the output buffer
*			D0 stores a copy of D4 for manipulating
*			D1 displacement
*			D2 displacment copy
*			D3 stores number of ascii to convert
**************************************************************
DECODE_PCD	MOVEM.L	reg_set_7,-(SP)		* Save main registers on stack
		CLR	D0		* clear the register of conaminents
		CLR	D1		* clear the register of conaminents
		CLR	D2		* clear the register of conaminents
		MOVE.W	(A3)+,D0	* grab the word that follows and move the pointer forward a word
		NEG	D0		* negate the displacement
		MOVE.B	#$24,(A4)+	* add the dollar sign to the output buffer and increment the pointer forward
		MOVE.B	#$2D,(A4)+	* add the negative sign
		MOVEA	A4,A0		* make a copy of output buffer ptr in A0
		MOVE.B	#$4,D3		* number of hex values to convert (passed to MEM_TO_ASCII)
		BSR	MEM_TO_ASCII	* convert the word input to ascii in the output buffer
		MOVEM.L	(SP)+,reg_set_7	*load the registers	
		ADDA	#7,A4		* move the output buffer pointer forward the ascii length of the long word
		LEA	mode_pcd,A0	* point A0 at the start of the output for the output buffer
		BSR	WRITE_OUTPUT	* write to the output buffer
		BRA	DCD_EA_DONE
**************************************************************
* Sub-routine: DECODE_ID
* Written by : Bryan Tinsly
* Date       : 5/22/2010 
* Description: mode(111)(100) Immediate Data
* Registers	:	D5 stores the bit to determine if address that follows is long or short word 
**************************************************************
DECODE_ID	CMPI.B 	#$80,D5 	* is it a long value?
		BEQ	DECODE_ALA	* yes, process as absolute long
		BRA	DECODE_AWA	* otherwise, it's a word

**************************************************************
* Sub-routine: DECODE_LIST
* Written by : Bryan Tinsly
* Date       : 5/22/2010 
* Description: mode(01)(XXX)(XXX) MOVEM Special Case
* Registers	:	A0 output to be sent to output buffer
*			A3 stores the address of the input buffer
*			A4 stores address of the output buffer
*			D0 stores address word data
*			D1 copy of word data to manipulate
*			D3 stores data register counter
**************************************************************
DECODE_LIST	MOVEM.L	reg_set_8,-(SP)		* Save main registers on stack
		MOVE.W	(A3)+,D0	* grab the word to decode
		CLR	D3		* clear the register
		ADDI.B	#$1,D3		* start at one
DN_LOOP		LEA 	mode_drd,A0	* set output
		ADDA	#$1,A0		* increment to the byte we're going to modify
		MOVE.B	#$30,(A0)	* reset (n) to 0 for D(n)
		MOVE.B	D3,D5		* copy data register (n) to D5
		SUBI.B	#$1,D5		* subtract one 1-8 to 0-7
		ADD.B	D5,(A0)		* specify which register 0 to 7
		MOVE.W	D0,D1		* copy the input word to be manipulated
		ROL	D3,D1		* rotate into position
		AND.L	#$00000001,D1 	* isolate the bit of interest
		CMPI.B	#$1,D1		* if its a one then the register belongs
		BNE	NEXT_DN		* no? then go to the next register
		LEA	mode_drd,A0	* point A0 at the start of the output for the output buffer
		BSR	WRITE_OUTPUT	* write to the output buffer
		MOVE.B	#$2F,(A4)+	* add the /
NEXT_DN		ADDI.B	#$1,D3		* increment D3
		CMPI.B	#$8,D3		* Have we processed 8 data registers?
		BLE	DN_LOOP		* no? then loop
		ROL	#$8,D0		* move on to the address registers
		CLR	D3		* clear D3
		ADDI.B	#$1,D3		* set D3 to one
AN_LOOP		LEA 	mode_ard,A0	* set output
		ADDA	#$1,A0		* increment to the byte we're going to modify
		MOVE.B	#$30,(A0)	* reset (n) to 0 for A(n)
		MOVE.B	D3,D5		* copy data register (n) to D5
		SUBI.B	#$1,D5		* subtract one 1-8 to 0-7
		ADD.B	D5,(A0)		* specify which register 0 to 7
		MOVE.W	D0,D1		* copy the input word to be manipulated
		ROL	D3,D1		* rotate into position
		AND.L	#$00000001,D1	* isolate the bit of interest
		CMPI.B	#$1,D1		* if its a one then the register belongs
		BNE	NEXT_AN		* no? then go to the next register
		LEA	mode_ard,A0	*point A0 at the start of the output for the output buffer
		BSR	WRITE_OUTPUT	*write to the output buffer
		MOVE.B	#$2F,(A4)+	* add the /
NEXT_AN		ADDI.B	#$1,D3		* increment D3
		CMPI.B	#$8,D3		* Have we processed 8 data registers?
		BLE	AN_LOOP		* no? then loop
		MOVEM.L	(SP)+,reg_set_8
		BRA	DCD_EA_DONE
		
**************************************************************
* Sub-routine: WRITE_OUTPUT
* Written by : Bryan Tinsly
* Date       : 5/22/2010 
* Description: 
* Registers	:	
**************************************************************
WRITE_OUTPUT	MOVE.B	(A0)+,(A4)+		* copy from ea output to output buffer and increment
		CMP.B	#$20,(A0)		* have we hit a space char?
		BNE	WRITE_OUTPUT		* yes? its time to quit
		BRA	WR_OUT_DONE
WR_OUT_DONE	RTS

*******************************************************************
*
* Data area
*
*******************************************************************
		ORG 	data			* This is where the dat ais stored
long_flag	DS.W	1			* Hold the EA length
word_copy1	DS.W	1			* A local copy of the current word to be decoded. Get from A3
word_copy2	DS.W	1			* A second copy to allow masking without loosing the original
end_address	DS.L	1			* A copy to the last address. Get from A6
init_a3		DS.W	1			* Store the status of A3 having been initialized
buff_reg_fl	DS.W	1			* Store the type of Register I need to print to screen after EA doese there work
buff_reg_nm	DS.W	1			* Store the An or Dn number to be written to buffer
exg_reg_fl_y	DS.W	1			* Store the An or Dn type for EXG register y
exg_reg_nm_y	DS.W	1			* Store the An or Dn of the second register (bits 0-2) used with EXG opcode
more_work	DS.W	1			* Store the flag for where I need to go back to after EA work
user_start_addr	DS.L	1			* Store the Hex version of the user start address here
user_end_addr	DS.L	1			* Store the hex version of the user end addres here
user_test_word	DS.W	1			* Store the hex version of the user test word here
user_input	DS.B	80			* Allow 80 bytes in memory for input to avoid the possibility of user overwriting memory
good_buf	DS.B	80			* Good buffer
bad_buf		DS.B	80			* Bad buffer
user_input_len	DC.W	user_input_len-user_input * Get string length	
valid_start	DC.L	min_address		* Hold the smallest valid starting address
valid_end	DC.L	max_address		* Hold the largest valid ending address
line_counter	DS.W	1			* Hold the count of lines to be printed to the screen


*******************************************************************
*
* Print table for instructions
* Description: This is where the strings to be added to the buffer are stored
*
*******************************************************************
input_count	DC.B	in_count							* keep track of the input pattern recieved
loop_count	DC.B	decode_count							* Keep track of the number of times through the decode loop
blank_line	DC.B	' '								* space (blank)
blank_line_len	DC.W	blank_line_len-blank_line					* get lenght
inval_ascii	DC.B	'Error: Use only characters (0-9), (A-F) or (a-f) '		* invalid ascii error
inval_ascii_len	DC.W	inval_ascii_len-inval_ascii					* Length of error message
instr_prompt	DC.B	'****************************************************************' * Instruction prompt
instr_len	DC.W	instr_len-instr_prompt						* Length of string
instr_p1	DC.B	'* '								* Instruction prompt
instr_p1_len	DC.W	instr_p1_len-instr_p1						* Length of string
instr_p2	DC.B	'* Welcome to disassembler program '				* Instruction prompt
instr_p2_len	DC.W	instr_p2_len-instr_p2						* Length of string
instr_p3	DC.B	'* For this program use only characters (0-9), (A-F) or (a-f)'	* Instruction prompt
instr_p3_len	DC.W	instr_p3_len-instr_p3						* Length of string
instr_p4	DC.B	'*'								* Instruction prompt
instr_p4_len	DC.W	instr_p4_len-instr_p4						* Length of string
instr_p5	DC.B	'*'								* Instruction prompt
instr_p5_len	DC.W	instr_p5_len-instr_p5						* Length of string
instr_p6	DC.B	'* Please load your code between 400 and 990 or between 4000 and FFFF'
instr_p6_len	DC.W	instr_p6_len-instr_p6
instr_p7	DC.B	'****************************************************************' * Instruction prompt
instr_p7_len	DC.W	instr_p6_len-instr_p6						* Length of string
prompt_1	DC.B	'Enter a starting address >= $00000400 and press [Enter]: '	* Starting prompt message
prompt_1_len	DC.W	prompt_1_len-prompt_1						* Get lenght of string
prompt_2	DC.B	'Enter an ending address <= $000FFFFF and press [Enter]: '	* Ending prompt message
prompt_2_len	DC.W	prompt_2_len-prompt_2						* Get lenght of string
prnt_ln_lmt 	DC.B	'Press " Y " to continue or press " Q " to quite.'		* Prompt message
prnt_ln_lmt_len	DC.W	prnt_ln_lmt_len-prnt_ln_lmt					* Get length of string
another_mem	DC.B	'Do you want to disassemble another memory area? (Y or N)'	* prompt message
another_mem_len	DC.W	another_mem_len-another_mem					* Get lenght of string
are_sure	DC.B	'Do you want to exit compeletly? (Y or N)' 			* prompt message
are_sure_len	DC.W	are_sure_len-are_sure						* Get lenght of string
error_1		DC.B	'Error 1: The starging address is below $00000400'		* Message for error 1
error_1_len	DC.W	error_1_len-error_1						* Length of error message
error_2		DC.B	'Error 2: The ending address is above $000FFFFF'		* Message for error 2
error_2_len	DC.W	error_2_len-error_2						* Length of error message
error_3		DC.B	'Error 3: The address is on an odd boundry'			* Message for error 3
error_3_len	DC.W	error_3_len-error_3						* Length of error message
error_4		DC.B	'Error 4: The string is not of proper length'			* Message for error 4
error_4_len	DC.W	error_4_len-error_4						* Lenght of error message
error_5		DC.B	'Error 5: Please enter either N or Y'				* Message for error 5
error_5_len	DC.W	error_5_len-error_5						* Lenght of error message
error_6		DC.B	'Error 6: Ending address must be > starting address '		* Message for error 6
error_6_len	DC.W	error_6_len-error_6						* Length of error message
error_7		DC.B	'Error 7: the address is out of specified range'		* Message for error 7
error_7_len	DC.W	error_7_len-error_7						* Length of error message
error_8		DC.B	'Error 8: Please enter either Q or Y'				* Message for error 7
error_8_len	DC.W	error_8_len-error_8						* Length of error message
bad_ad_msg_2	DC.B	'<DATA!>   '							* display before data written
bad_ad_m_2_len	DC.W	bad_ad_m_2_len-bad_ad_msg_2

crg_return	DC.B	$0D								* Hex Carriage return
line_feed	DC.B	$0A								* Hex Line Feed
stop_st		DC.B	'STOP'			* STOP
stop_st_len	DC.W	stop_st_len-stop_st	* string length
asd		DC.B	'AS'			* (ASL, ASR)
asd_len		DC.W	asd_len-asd		* string length
dir_r		DC.B	'R.'			* direction R
dir_r_len	DC.W	dir_r_len-dir_r		* string lenght
dir_l		DC.B	'L.'			* direction L
dir_l_len	DC.W	dir_l_len-dir_l		* string length		
add		DC.B	'ADD.'			* add instruction
add_len		DC.W	add_len-add		* string length_adda		
adda		DC.B	'ADDA.'			* adda instruction
adda_len	DC.W	adda_len-adda		* string length
addi		DC.B	'ADDI.'			* addi instruction
addi_len	DC.W	addi_len-addi		* string length
and		DC.B	'AND.'			* and instruction
and_len		DC.W	and_len-and		* string length
andi		DC.B	'ANDI.'			* andi instruction
andi_len	DC.W	andi_len-andi		* string length
bsr		DC.B	'BSR.'			* bsr instruction
bsr_len		DC.W	bsr_len-bsr		* string length	
clr		DC.B	'CLR.'			* clr instruction
clr_len		DC.W	clr_len-clr		* string length
cmp		DC.B	'CMP.'			* cmp instruction
cmp_len		DC.W	cmp_len-cmp		* string length
cmpa		DC.B	'CMPA.'			* cmpa instruction
cmpa_len	DC.W	cmpa_len-cmp		* string length
cmpi		DC.B	'CMPI.'			* cmpi instruction
cmpi_len	DC.W	cmpi_len-cmpi		* string length
eor		DC.B	'EOR.'			* eor instruction
eor_len		DC.W	eor_len-eor		* string length
eori		DC.B	'EORI.'			* eori instruction
eori_len	DC.W	eori_len-eori		* string length
exg		DC.B	'EXG.L'			* exg instruction This opcode is always size .L
exg_len		DC.W	exg_len-exg		* string length
jmp		DC.B	'JMP'			* jmp instruction
jmp_len		DC.W	jmp_len-jmp		* sstring length
jsr		DC.B	'JSR'			* jsr instruction
jsr_len		DC.W	jsr_len-jsr		* string length
lea		DC.B	'LEA'			* lea instruction
lea_len		DC.W	lea_len-lea		* string length
lsd		DC.B	'LS'			* ls instruction (LSL, LSR)
lsd_len		DC.W	lsd_len-lsd		* string length
move		DC.B	'MOVE.'			* move instruction
move_len	DC.W	move_len-move		* string length
movea		DC.B	'MOVEA.'		* movea instruction
movea_len	DC.W	movea_len-movea		* string length
movem		DC.B	'MOVEM.'		* movem instruction
movem_len	DC.W	movem_len-movem		* string length
neg		DC.B	'NEG.'			* neg instruction
neg_len		DC.W	neg_len-neg		* string length
nop		DC.B	'NOP'			* nop instruction
nop_len		DC.W	nop_len-nop		* string lenght
not		DC.B	'NOT.'			* not instruction
not_len		DC.W	not_len-not		* string lenght
_or		DC.B	'OR.'			* or instruction
_or_len		DC.W	_or_len-_or		* string length
ori		DC.B	'ORI.'			* ori instruction
ori_len		DC.W	ori_len-ori		* string length
rod		DC.B	'RO'			* (ROL, ROR)
rod_len		DC.W	rod_len-rod		* string length
rts		DC.B	'RTS'			* rts instruction
rts_len		DC.W	rts_len-rts		* string length
sub		DC.B	'SUB.'			* sub instruction
sub_len		DC.W	sub_len-sub		* string length
suba		DC.B	'SUBA.'			* suba instruction
suba_len	DC.W	suba_len-suba		* string length
subi		DC.B	'SUBI.'			* subi instruction
subi_len	DC.W	subi_len-subi		* string length
swap		DC.B	'SWAP.W'		* SWAP is only in size word, and Dn
swap_len	DC.W	swap_len-swap		* string length
pound		DC.B	'#'			* # sign
pound_len	DC.W	pound_len-pound		* string length
comma		DC.B	','			* comma
comma_len	DC.W	comma_len-comma		* length of string	
__l		DC.B	'L'			* size L
l_len		DC.W	l_len-__l		* string length
__w		DC.B	'W'			* size W
w_len		DC.W	w_len-__w		* string length
__b		DC.B	'B'			* size B
b_len		DC.W	b_len-__b		* string length
spa		DC.B	' '			* space character
spa_len		DC.W	spa_len-spa		* string length
_a0		DC.B	'A0'			* A0
_a0_len		DC.W	_a0_len-_a0		* string length
_a1		DC.B	'A1'			* A1
_a1_len		DC.W	_a1_len-_a1		* string length
_a2		DC.B	'A2'			* A2
_a2_len		DC.W	_a2_len-_a2		* string length
_a3		DC.B	'A3'			* A3
_a3_len		DC.W	_a3_len-_a3		* string length
_a4		DC.B	'A4'			* A4
_a4_len		DC.W	_a4_len-_a4		* string length
_a5		DC.B	'A5'			* A5
_a5_len		DC.W	_a5_len-_a5		* string length
_a6		DC.B	'A6'			* A6
_a6_len		DC.W	_a6_len-_a6		* string length
_a7		DC.B	'A7'			* A7
_a7_len		DC.W	_a7_len-_a7		* string length
_d0		DC.B	'D0'			* D0
_d0_len		DC.W	_d0_len-_d0		* string length
_d1		DC.B	'D1'			* D1
_d1_len		DC.W	_d1_len-_d1		* string length
_d2		DC.B	'D2'			* D2
_d2_len		DC.W	_d2_len-_d2		* string length
_d3		DC.B	'D3'			* D3
_d3_len		DC.W	_d3_len-_d3		* string length
_d4		DC.B	'D4'			* D4
_d4_len		DC.W	_d4_len-_d4		* string length
_d5		DC.B	'D5'			* D5
_d5_len		DC.W	_d5_len-_d5		* string length
_d6		DC.B	'D6'			* D6
_d6_len		DC.W	_d6_len-_d6		* string length
_d7		DC.B	'D7'			* D7
_d7_len		DC.W	_d7_len-_d7		* string length

mode_drd	DC.B	'D0 '
mode_ard	DC.B	'A0 '
mode_ari	DC.B	'(A0) '
mode_id		DC.B	'$00000000 '
mode_ala	DC.B	'$00000000 '
mode_awa	DC.B	'$00000000 '
mode_aripi	DC.B	'(A0)+ '
mode_aripd	DC.B	'-(A0) '
mode_ariwi	DC.B	'(A0,D0.W) '
mode_pcd	DC.B	'(PC) '
mode_hlpr	DC.B	'$00000000 '		
		
		END	load			* nothing more to assemble			






















*~Font name~Courier New~
*~Font size~9~
*~Tab type~1~
*~Tab size~8~
