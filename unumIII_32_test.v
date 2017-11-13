module unumIII_32_test(
	input clk,
	input rst_n,
	
	output[31:0] unum_o,
	output NaN
);


reg[31:0] unum1;
reg[31:0] unum2;
reg rst_n_add;
wire clk_130m;
reg[3:0] state;

always@(posedge clk_130m or negedge rst_n)begin
	if(!rst_n)begin
		state<=4'd0;
	end
	else case(state)
	4'd0:begin
		unum1<=32'hb5800000;   //-6.5*7.5=-48.75(0xa9e8_0000)
		unum2<=32'h4b800000;
		state<=state+4'd1;
	end
	
	4'd1:begin
		unum1<=32'hb5800000;   //test 0
		unum2<=32'h0000_0000;
		state<=state+4'd1;
	end
	
	4'd2:begin
		unum1<=32'h55e0_0000;   //47*-2.3=-108.1(0xa53e_6666)
		unum2<=32'hbb66_6666;
		state<=state+4'd1;
	end
	4'd3:begin
		unum1<=32'h7fff_ffff;   //test overflow
		unum2<=32'h7fff_ffff;
		state<=state+4'd1;
	end
	
	4'd4:begin
		unum1<=32'h55e0_0000;   //47*0.3=14.1(0x4f0c_cccd)
		unum2<=32'h38cc_cccd;
		state<=state+4'd1;
	end
	
	4'd5:begin
		unum1<=32'h55e0_0000;   //test Inf
		unum2<=32'h8000_0000;
		state<=state+4'd1;
	end
	
	4'd6:begin   ///-0.0756+0.0756=0(0x0000)
		unum1<=32'h305a_1cac;   //0.068*1.333=0.090644(0x31cd1c7e)
		unum2<=32'h4154_fdf4;
		state<=state+4'd1;
	end
	
	4'd7:begin
		unum1<=32'h8000_0000;   //0.068*1.333=0.090644(0x31cd1c7e)
		unum2<=32'h0000_0000;
		state<=state+4'd1;
	end
	

	4'd8:begin
		
	end
	default:;
	
	endcase
	
end

unum_multiplier multiplier1(
	.clk(clk_130m),
	.unum1(unum1),
	.unum2(unum2),
	
	.unum_o(unum_o),
	.NaN(NaN)
					);

pll_1 u2(
	.inclk0(clk),
	.areset(),
	
	.c0(clk_130m),

	.locked()
);
endmodule 