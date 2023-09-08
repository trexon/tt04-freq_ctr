//////////////////////////////////////////////////////////////////////////////////
// Company: spehro
// Engineer: 
// 
// Create Date:    16:03:22 09/05/2023 
// Design Name: 
// Module Name:    bcd_digit 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: pretty much my first Verilog project.. caveat emptor
//
//////////////////////////////////////////////////////////////////////////////////
module bcd_digit(
    input clk_in,
    input clk_enable ,
    input nreset,
    output wire [3:0] ctr,
    output wire carry_out,
	 output wire zero
    );
reg [3:0] ctra; 


always @ (posedge clk_in or negedge nreset)
   begin
	  if (nreset == 0) 
	     ctra  <= 0; 
     else 
	     begin 
		    if (clk_enable == 1) 
			    if (ctra < 4'h9) ctra <= ((ctra + 4'h1) & 4'hF); 
				   else 
					  begin 
					     ctra <= 0; 
                 end 
		  end 
	end 
assign ctr = ctra; 
assign carry_out = clk_enable && (ctra == 9); 
assign zero = (ctra == 0); 
endmodule
