Disassembler
============

68K Assembly Language Disassembler Project

<h2>Description</h2>
 
The program is a disassembler, written in 68K Assembly Language using Easy68K software. It reads operations to decode a memory image of instructions and prints the instruction that have been decoded to the screen along with the information about instructions that were not able to be decoded. For our project, the program is designed into three parts: I/O, Op-Code, and Effective Address (EA).
 
In general, the program is designed to prompt a client to enter a proper starting addresses based on the specification of the program. If a client enters anything other than what was specified to be entered, an error message will be displayed on the screen and give a client another chance to enter correct address. Once the correct starting address detected, I/O would save it in a register and send it to Op-Code.
 
The client would be then prompted to enter a proper ending address based on the specification of the program. If a client enters anything other than what was specified to be entered, an error message will be displayed on the screen and give a client another chance to enter correct address. Once the correct ending address detected, I/O would save it in a register and send it to Op-Code.
 
Once the Op-Code received the information required to read and analyze each operation and will mask off 12-15 bits and then jumps to the table created by Op-Code to decode. If the instruction requires further decoding that cannot be done by Op-Code, it would be sent out to Effective Address to be decoded.
 
We are proud that our program is able to decode Advanced Addressing Mode 5 which was not part of the assignment. We are excited to implement it correctly and are able to see the instruction on the screen. Also, we are proud to be able to implement two operations: AND and EXG. Apparently, these instructions were the most challenging of all. It took the longest time to go through the logic and drew flowcharts for each operation. Last thing to be proud of is that we implemented decoding for “STOP” to be printed out to the screen as it is the same as what we see in the assembler – STOP #$2700.


<h2>Specification</h2>

The first message that will be print out on the screen is the welcome screen with instruction on how this program works, the specifications that was designed for this program, and the name of the creators of this program.
 
First, the client will be prompt to enter a starting address of the memory. The program will go through rigid error checking to make sure a user enters a proper address range that was specified in the program. Once the correct address detected, the user input will be stored. Second, the client will be prompted to enter an ending address of the memory. The same error checking process would be processed for the ending address.
 
The program then reads operations to decode a memory image of instructions and prints the instruction that have been decoded to the screen. If there are instructions that could not be decoded, the memory address of the word would be the first to be printed out on the screen followed by <data!> and at last the hex value of the word that could not be decoded would be printed out on the screen. The program would then continue with other sets of instruction to decode.
           
If the printed instructions go over 28 lines, a message will be displayed to ask a client whether continue decoding or quit the program. The client is restricted to only enter “Y” to “continue” or “Q” to “quit”; if any other characters entered, an error message would be displayed.
           
Also, if a client wishes to try another memory location, a message would be printed on the screen, and the process of entering starting and ending address as explained above will be processed.

<ul>Effective Addressing Modes:
<li>Data Register Direct</li>
<li>Address Register Direct</li>
<li>Address Register Indirect</li>
<li>Immediate Data</li>
<li>Absolute Long Address</li>
<li>Absolute Word Address</li>
<li>Address Register Indirect with Post incrementing</li>
<li>Address Register Indirect with Pre decrementing</li>
<li>Program counter with displacement</li>
<li>Address register indirect with index</li>
</ul>

<ul>
Instructions:
<li>ADD, ADDA, ADDI</li>
<li>AND, ANDI</li>
<li>ASL,ASR</li>
<li>BSR</li>
<li>CLR</li>
<li>CMP, CMPA,CMPI</li>
<li>EOR,EORI</li>
<li>EXG</li>
<li>JMP, JSR</li>
<li>LEA</li>
<li>LSR,LSL</li>
<li>MOVE, MOVEA, MOVEM</li>
<li>NEG</li>
<li>NOP</li>
<li>NOT, OR, ORI</li>
<li>ROL, ROR</li>
<li>RTS</li>
<li>SUB, SUBA, SUBI</li>
<li>SWAP</li>
</ul> 

<ul>
Input
<li>Start address – formatted as follows:</li>
<ul><li>1-8 characters</ul></li>
<ul><li>Only hex values</ul></li>
<ul><li>Greater than $00002000</ul></li>
<ul><li>Less than $000FFFFF</ul></li>
 
<li>End address – formatted as follows:</li>
<ul><li>1-8 characters</ul></li>
<ul><li>Only hex values</ul></li>
<ul><li>Greater than $00002000</ul></li>
<ul><li>Less than $000FFFFF</ul></li>
<ul><li>Greater than Start address</ul></li>
 
<li>Paging (y/q) – formatted as follows:</li>
<ul><li>Only y/Y or q/Q char followed by enter</ul></li>
 
<li>New Region (y/n) – formatted as follows:</li>
<ul><li>Only y/Y or q/Q char followed by enter</ul></li>
</ul>
