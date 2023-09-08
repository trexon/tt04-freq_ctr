//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:  Spehro 
// 
// Create Date:    22:34:28 09/05/2023 
// Design Name: 
// Module Name:    bcd_counter 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description:  An 8-digit BCD counter + level-sensitive latch with a multiplexed BCD output from the latch
//
// Dependencies: 
// 
// Revision: 
// Revision 0.01 - File Created
// Additional Comments:  pretty much my first Verilog project.. caveat emptor 
//
//////////////////////////////////////////////////////////////////////////////////
module bcd_counter( 
    input clk_in,
    input clk_enable,
	 input latchit, 
    input nreset,
	 input reset_ctr, 
	 input [2:0] digit_select,  
    output wire [3:0] digit_muxed,
    output wire carry_out
    );
wire  carry_outs[7:0]; 
wire [3:0] digits[7:0];
reg [3:0] latch[7:0];
integer j; 
reg nreset_it; 

reg latched = 0; 


bcd_digit ctr0 
      (
		.clk_in(clk_in), 
		.clk_enable(clk_enable), 
		.nreset (nreset_it), 
		.ctr (digits[0]), 
		.carry_out (carry_outs [0]),
		.zero (zero0)
      );
bcd_digit ctr1
      (
		.clk_in(clk_in), 
		.clk_enable(carry_outs[0]), 
		.nreset (nreset_it), 
		.ctr (digits[1]), 
		.carry_out (carry_outs [1]),
		.zero (zero1)
		);
bcd_digit ctr2
      (
		.clk_in(clk_in), 
		.clk_enable(carry_outs[1]), 
		.nreset (nreset_it), 
		.ctr (digits[2]), 
		.carry_out (carry_outs [2]),
		.zero (zero2)
		);
bcd_digit ctr3
      (
		.clk_in(clk_in), 
		.clk_enable(carry_outs[2]), 
		.nreset (nreset_it), 
		.ctr (digits[3]), 
		.carry_out (carry_outs [3]),
		.zero (zero3)
		);
bcd_digit ctr4
      (
		.clk_in(clk_in), 
		.clk_enable(carry_outs[3]), 
		.nreset (nreset_it), 
		.ctr (digits[4]), 
		.carry_out (carry_outs [4]),
		.zero (zero4)
		);
bcd_digit ctr5
      (
		.clk_in(clk_in), 
		.clk_enable(carry_outs[4]), 
		.nreset (nreset_it), 
		.ctr (digits[5]), 
		.carry_out (carry_outs [5]),
		.zero (zero5)
		);
bcd_digit ctr6
      (
		.clk_in(clk_in), 
		.clk_enable(carry_outs[5]), 
		.nreset (nreset_it), 
		.ctr (digits[6]), 
		.carry_out (carry_outs [6]),
		.zero (zero6)
		);
bcd_digit ctr7
      (
		.clk_in(clk_in), 
		.clk_enable(carry_outs[6]), 
		.nreset (nreset_it), 
		.ctr (digits[7]), 
		.carry_out (carry_outs [7]),
		.zero (zero7)
		);

// next steps - implement latch and multiplexer 
always @ (posedge clk_in or negedge nreset)
    if (nreset == 0) 
	 begin 
	    nreset_it <= 0; 
	 end 
    else 
    begin 
	    if (reset_ctr) 
		     nreset_it <= 0;
       else 
           nreset_it <= 1; 		 
		 if ((latchit == 1) && (latched ==0)) 
		    begin 
//			    for (j = 7; j >= 0; j= j - 1) 
//				    begin 
//					    latch[j] <= digits[j]; 
//                end 	
             // stupid but it works 
				 latch[7] <= (zero7)  ? 4'hF : digits[7];
				 latch[6] <= ((zero6) && (zero7)) ? 4'hF : digits[6];
				 latch[5] <= ((zero5) && (zero6) && (zero7)) ? 4'hF : digits[5];				 
				 latch[4] <= ((zero4) && (zero5) && (zero6) && (zero7)) ? 4'hF : digits[4];				 
				 latch[3] <= ((zero3) && (zero4) && (zero5) && (zero6) && (zero7)) ? 4'hF : digits[3];				 
				 latch[2] <= ((zero2) && (zero3) && (zero4) && (zero5) && (zero6) && (zero7)) ? 4'hF : digits[2];				 
				 latch[1] <= ((zero1) && (zero2) && (zero3) && (zero4) && (zero5) && (zero6) && (zero7)) ? 4'hF : digits[1];				 
	          latch[0] <= digits[0]; // never blank LSD 			 
				 
					 
					 
					 
             latched <= 1; 						
		 		 end 
		 if (latchit ==0) 
		    begin 
			 
			   latched <= 0; 
			 end 
		 
	  end 
assign digit_muxed = latch[digit_select]; // multiplex data from latch 



endmodule
