//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: spehro
// 
// Create Date:    13:36:27 09/05/2023 
// Design Name: 
// Module Name:    freq_meas 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: a simple frequency meter using a binary timebase counter and a 
//  BCD edge counter (probably not ideal, but passes timing with ease in Spartan 6 FPGA). 
//  an FPGA clock of either 50MHz (preferred) or 10MHz (fallback) is allowed for
//	 
//  8 seven segment digits are multiplexed at 125 usec per digit with 10usec 
//  dead time to prevent ghosting 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: pretty much my first Verilog project.. caveat emptor.. contains dumb errors
//
//////////////////////////////////////////////////////////////////////////////////
	 

`default_nettype none

module tt_um_spehro_freq_meas #( parameter MAX_COUNT = 24'd10_000_000 ) (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    wire nreset = rst_n;
    wire fpga_clk = clk; 
    wire [7:0] digit_drive; 
	wire [7:0] sev_segments; 
    wire carry_out;
	wire sig_out; 	
    // wire [6:0] led_out;
    // assign uo_out[6:0] = led_out;
    // assign uo_out[7] = 1'b0;

    //use bidirectionals as outputs
    assign uio_oe = 8'b11111111;

    //put bottom 8 bits of second counter out on the bidirectional gpio
    assign uio_out = digit_drive;
	assign uo_out = sev_segments; 
	wire signal = ui_in[0];
	wire n10_50 = ui_in[1];
   	wire out_1000kHzt;
       wire latchitt; 
	wire reset_ctrt; 
	wire [19:0] timebase_countert;

// module freq_meas(
    // input fpga_clk,
    // input nreset,
    // input signal,
	 // input n10_50, // low for 10MHz clock, high for 50MHz 
    // output wire [7:0] sev_segments,   // active low for common anode 
    // output wire [7:0] digit_drive,   // active low to drive PNP transistors or P-channel MOSFETs
	 // output wire sig_out, // output timebase for debugging 
	 // output wire out_1000kHzt,
	 // output wire latchitt,
	 // output wire reset_ctrt,
	 // output wire [19:0] timebase_countert
    // );



	
integer j; 

reg flip_test = 0; // just for testing 
reg reset_ctr;
reg [7:0]sev_segment; 
reg latchit = 0;
reg clk_enable; 
reg [19:0] timebase_counter;        // 1 second at 1MHz 
reg [7:0] digit_drives;
wire [3:0] digit_muxed; 
reg [7:0] digit_dwell_counter;      // time in microseconds to dwell each digit and for deadtime 
reg  [1:0] signal_old ;


reg [2:0] mux_counter; 

reg [4:0] prescaler_1000kHz; // counter to give 1MHz output for either 10MHz or 50MHz in, counts to 5 or  25 
reg out_1000kHz;

// Instantiate the 8-digit BCD counter 
  bcd_counter bcd_count (
		.clk_in(fpga_clk), 
		.clk_enable(clk_enable), 
		.latchit(latchit), 
		.nreset(nreset),
		.reset_ctr(reset_ctr), // synchronous reset
		.digit_select(mux_counter), 
		.digit_muxed(digit_muxed), 
		.carry_out(carry_out)
	);


always @ (posedge fpga_clk or negedge nreset)
   begin
	  if (nreset == 0) 
	      begin 
			  prescaler_1000kHz <= 0; 
			  timebase_counter <= 0; 
			  out_1000kHz <= 0; 
// 			   signal_old <= signal << 1 | signal;     // can't mix synchronous and asynchronous
			end 
		else 
		   begin
			signal_old <= (signal_old << 1) | signal; 
	       if (signal_old == 2'b01)
		         begin 
	               clk_enable <= 1; 
	            end 
			  else 
               begin
					   clk_enable <= 0; 
					end
		   prescaler_1000kHz <= prescaler_1000kHz + 1; 
			if (prescaler_1000kHz == (n10_50 ? 24 : 5))        // high for 50MHz (div by 25), low for 10MHz (div by 5) 
			     begin
				     if (out_1000kHz) timebase_counter <= timebase_counter +1;  
				     out_1000kHz <= ~out_1000kHz;;
				     prescaler_1000kHz <= 0; 
				  end 
         if (latchit==1)  
			   begin 
				   reset_ctr <= 1; 
				   latchit <= 0; 
					flip_test <= ~flip_test; 
				end
				else 
            begin 	
	            reset_ctr <= 0; 
				end 
			if (timebase_counter == 1000000)  
			   begin 
               timebase_counter <= 0; 
               latchit <= 1; 
  			   end 
			end		
	end


// multiplex the display  
always @ (posedge out_1000kHz or negedge nreset) 
   begin
	  if (nreset == 0) 
	      begin  
	        mux_counter <= 0;      
			  digit_dwell_counter <= 0; 
			  digit_drives <= 'hFF; 
	      end 
	  else 
	      begin 
			   digit_dwell_counter <= digit_dwell_counter + 1; 
				if ((digit_dwell_counter < 5 )  || (digit_dwell_counter > 119)) 
				     digit_drives <= 'hff;   // 10 us blanking to prevent ghosting 
			   else 
//                 if (mux_counter  < 'h06) 
//					     digit_drives <= ~('h80 >> (mux_counter +2) );  // board test 
//                 else 
//					     digit_drives <= 'hff; 

					  digit_drives <= ~('h01 << mux_counter);   // for ASIC
			   if (digit_dwell_counter == 124)
				   begin
					  digit_dwell_counter <= 0; 
					  mux_counter <= (mux_counter+1 ) & 'h07; 
  				   end 
			
			end 
	
	end

assign digit_drive = digit_drives; 


//assign sig_out = timebase_counter ; // repeat it for testing

//assign sig_out = flip_test; 

assign sig_out = clk_enable; 

//  leading zero blanking uses invalid BCD 
always @ (posedge fpga_clk) 
  begin 
    case (digit_muxed)
      0: sev_segment <= (~'h3f & 8'hff);
		1: sev_segment <= (~'h06 & 8'hff);
      2: sev_segment <= (~'h5b & 8'hff);
		3: sev_segment <= (~'h4f & 8'hff);
      4: sev_segment <= (~'h66 & 8'hff);
		5: sev_segment <= (~'h6d & 8'hff);
      6: sev_segment <= (~'h7d & 8'hff);
		7: sev_segment <= (~'h07 & 8'hff);
      8: sev_segment <= (~'h7f & 8'hff);
		9: sev_segment <= (~'h6f & 8'hff);	
      default: sev_segment <= (~'h00 & 8'hff);
    endcase 
  end 

assign sev_segments = sev_segment; 

assign out_1000kHzt = out_1000kHz; 

assign latchitt = latchit; 
assign reset_ctrt = reset_ctr; 
assign timebase_countert = timebase_counter; 
endmodule
