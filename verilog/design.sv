/*
 *  Author:       Parker Lloyd
 *
 *  Description:  This program accepts a 4-bit command from an MCU to read/write
 *                values that are stored in two 8-bit registers.
 *                Possible commands are:
 *              	Valid commands are:
 *                  - "xxx0"	: points to register A	*WILL NOT BE RUN BY ITSELF*
 *                  - "xxx1"	: points to register B	*WILL NOT BE RUN BY ITSELF*
 *                  - "000x"	: sets the value of the pointed register to zero
 *                	- "001x"	: increments the value of the pointed register
 *                	- "010x"	: decrements the value of the pointed register
 *					        - "011x"	: inputs the next value into the pointer register
 *                	- "100x	: decrements the value of the pointed register and repeats the previous command
 *                  - "101x"	: outputs the value of pointed register on the CPLD I/O
 */
module two_byte_memory(clk, en, pc_in, data_out, int_wait, data_a, data_b);
  
  parameter INPUT_WIDTH = 4;	// length of the command 
  parameter MEM_WIDTH = 8;		// length of the data registers
  parameter	ADDR_WIDTH = 1;		// 1-bit: 0 -> A, 1 -> B
  
  input 						clk;		// clock input
  input							en;			// enable pulse triggered by new command/input
  input	 	  [INPUT_WIDTH-1:0]	pc_in; 		// the 4-bit pc command/input value
  output 	  [MEM_WIDTH-1:0]	data_out;	// the data read from a register
  output wire					int_wait;	// indicates if CPLD is waiting for integer input value
  output wire [MEM_WIDTH-1:0]	data_a;		// for viewing contents fo reg(A) w/o output command
  output wire [MEM_WIDTH-1:0]	data_b;		// for viewing contents fo reg(B) w/o output command
  
  reg 	 [MEM_WIDTH-1:0]	data_out;		// too allow data_out to be read by testbench
  
  reg 	 [MEM_WIDTH-1:0]	mem[2**ADDR_WIDTH - 1:0]; // 2-element array of 8-bit wide reg (A and B)
  	
  reg 	 [INPUT_WIDTH-1:0] 	input_val;				// input value provided after input command
  reg 	 [INPUT_WIDTH-1:0] 	prev_cmd;				// for saving previous command
  reg 	 [INPUT_WIDTH-1:0] 	curr_cmd;				// for saving current command
  reg 						curr_addr = 1'b0;		// initialize current address to reg(A)
  reg 						read_input_val = 1'b0;	// input command not yet provided
  reg 						repeating = 1'b0;		// repeat/dec command not yet provided
  
  assign int_wait = read_input_val; // let MCU know whether CPLD is waiting for integer input
  assign data_a = mem[0];			// continously assign current value of reg(A)
  assign data_b = mem[1];			// continously assign current value of reg(B)
  
  /* Increments value at given address */
  task inc;
    input addr;
    begin
      if (mem[addr] < 8'b11111111)		// prevent overflow
        mem[addr] = mem[addr] + 1;
    end
  endtask
  
  /* Decrements value at given address */
  task dec;
    input addr;
    begin
      if (mem[addr] > 8'b00000000)		// prevent from going negative
        mem[addr] = mem[addr] - 1;
    end
  endtask
  
  /* Write a new value to the given address
   * Will be run twice per write:
   *				- Once to acknowledge input command
   *				- Again to write next input value
   */			 	
  task write_reg;
    input addr;
    begin
      if (read_input_val)
        mem[addr] <= input_val;		// set reg(X) = (input value)
      
      // 0 -> 1 : input command received; now expecting input value
      // 1 -> 0 : input value has been written to register; end input command
      read_input_val = ~read_input_val;
    end
  endtask
  
  /*  */
  task dec_repeat;
    begin
      if (repeating == 1'b0)
        repeating <= 1'b1;
    end
  endtask
  
  /* Executes the command provided */
  task process_cmd;
    input [3:0] cmd;
    begin
      curr_addr = cmd[0];		// point to register A (0) or B (1)
      casez (cmd)
        4'b000?: mem[curr_addr] <= 8'b00000000;			// clear reg(X)
        4'b001?: inc(curr_addr);						// increment reg(X)
        4'b010?: dec(curr_addr);						// decrement reg(X)
        4'b011?: write_reg(curr_addr);					// write input value to reg(X)
        4'b100?: dec_repeat();							// set flag to allow always block to dec/repeat
        4'b101?: data_out <= mem[curr_addr];			// write reg(X) value to CPLD output
        default: $display("Unknown/invalid command provided.");
      endcase
    end
  endtask
  
  /* 
   * This block will run when the MCU pulses the read-enable pin 
   */
  always @ (posedge en) begin
    // if expecting input value, save 4-bit input as input value
    // otherwise save as current command
    if (read_input_val)
      input_val = pc_in;
    else
      curr_cmd = pc_in; 

    // read-enable pulse should occur while dec/repeat command is running only to input next value (prev_cmd = "input")
    if (repeating)
      process_cmd(prev_cmd);
    else
      process_cmd(curr_cmd);
    
    // save previous command if not "dec/repeat"
    if (curr_cmd[3:1] !== 3'b100)
      prev_cmd = curr_cmd;
    
  end
  
  /*
   * This block is for processing the dec/repeat command
   * This block should only execute if:
   * 				- dec/repeat command is currently running
   *				- an input value is not expected from the user
   */
  always @(posedge clk) begin
    if (repeating && ~read_input_val) begin
      
      // decrement the register indicated by the current "dec/repeat" command
      dec(curr_cmd[0]);
      
      // if reg(X) decremented to zero, exit always block
      // otherwise, execute previous command
      if (mem[curr_cmd[0]] == 0)
      	repeating <= 1'b0; 			// clear repeat flag
      else
      	process_cmd(prev_cmd);
     
    end
  end
          
endmodule
