//32-bit multiplier Universal number(unum)-Type III with 3-bit exponent bit in pipeline structure
//Dased on the document in http://superfri.org/superfri/article/view/137/232
//LZC(leading zero counter) module is designed based on MODULAR DESIGN OF FAST LEADING ZEROS COUNTING CIRCUIT (http://iris.elf.stuba.sk/JEEEC/data/pdf/6_115-05.pdf)
//Designed by Jianyu CHEN, in Delft, the Netherlands, in 2nd Sept, 2017
//Email of designer: chenjy0046@gmail.com

module unum_multiplier(
	input clk,
	input[31:0] unum1,
	input[31:0] unum2,
	
	output[31:0] unum_o,
	output NaN
					);
					
					
//1st: check whether the input number is special situations: zero and Inf
//If the number is nagative, change it from 2's complement to original  
reg[1:0] isZero_1;   //isZero[1]: unum1   [0]: unum2    =0 if value is zero
reg[1:0] isInf_1;	 //isInf[1]: unum1    [0]: unum2    =1 if value is Inf
reg[31:0] temp1,temp2;  //store changed or unchange input numbers
reg[4:0] unum1_shift,unum2_shift; //result of zero/one counting
wire[4:0] n1,n2;//result of leading zero count
wire[30:0] unum1_2s,unum2_2s;
assign unum1_2s=~unum1[30:0]+31'b1;
assign unum2_2s=~unum2[30:0]+31'b1;
always@(posedge clk)begin  ////////1st
	if(unum1[30:0]==31'b0)begin isZero_1[1]<=unum1[31]; isInf_1[1]<=unum1[31]; end
	else begin isZero_1[1]<=1'b1; isInf_1[1]<=1'b0;end 
	
	if(unum2[30:0]==31'b0)begin isZero_1[0]<=unum2[31]; isInf_1[0]<=unum2[31]; end
	else begin isZero_1[0]<=1'b1; isInf_1[0]<=1'b0; end
	
	if(unum1[31])begin temp1<=unum1_2s; end  /// change unum from 2nd complement to original
	else begin temp1<=unum1[31:0]; end
	if(unum2[31])begin temp2<=unum2_2s; end
	else begin temp2<=unum2[31:0]; end
	
	unum1_shift<=n1;
	unum2_shift<=n2;
	
	temp1[31]<=unum1[31];
	temp2[31]<=unum2[31];
end
LZC lzc1(.x1(unum1_2s),.n(n1));
LZC lzc2(.x1(unum2_2s),.n(n2));


//2nd: Left shift the temp so that the exponent bits, sign bit and fraction bits will in the certain positions.
//change regime bits and exponent bits into exponent value in 2's complement format
reg isInf_2;  //if one of the input numbers is Inf, this bit will be 1
reg[31:0] temp1_2,temp2_2;  //[31]:sign bit   [30]: ==1 if component value is negative, ==0 if zero or positive. Useless here      [29:27]:exponent bits [26:1]:fraction bit [0]:Do not care
reg[8:3] expo_num1, expo_num2; //store exponent values
reg NaN_2;
reg isZero_2;
always@(posedge clk)begin        ///2nd
	temp1_2[30:0]<=temp1[30:0]<<unum1_shift;
	temp2_2[30:0]<=temp2[30:0]<<unum2_shift;
	temp1_2[31]<=temp1[31];
	temp2_2[31]<=temp2[31];	
	
	if(temp1[30]) begin expo_num1[8]<=1'b0; expo_num1[7:3]<=unum1_shift; end
	else begin expo_num1[8]<=1'b1; expo_num1[7:3]<=~unum1_shift; end
	
	if(temp2[30]) begin expo_num2[8]<=1'b0; expo_num2[7:3]<=unum2_shift; end
	else begin expo_num2[8]<=1'b1; expo_num2[7:3]<=~unum2_shift; end

	isInf_2<=isInf_1[1]|isInf_1[0];
	NaN_2<=(isInf_1[1]&~isZero_1[0])|(~isZero_1[1]&isInf_1[0]);
	
	isZero_2<=isZero_1[1]&isZero_1[0]&~(isInf_1[1]|isInf_1[0]);   ////caculation of results of Inf and Zero are very similar, so regard Inf as Zero here 
end

///3rd: multiple two fractions, add two exponent values
reg isZero_3;
reg isInf_3;  //if one of the input numbers is Inf, this bit will be 1
reg frac_numo_3; //[54]:sign bit   [53]:for carry on 			[52]:1.   	[51:0]fraction bits
reg[1:0] expo_sign_3; //[1]: sign value of unum1     [0]: sign value of unum2
reg[8:0] expo_numo_3; //store exponent values
reg NaN_3;
wire[53:25] mult_result;
always@(posedge clk)begin         //3rd
	//frac_numo_3[53:0]<=*;
	frac_numo_3<=(temp1_2[31]^temp2_2[31])&isZero_2|isInf_2;
	NaN_3<=NaN_2;
	expo_sign_3[1]<=expo_num1[8];
	expo_sign_3[0]<=expo_num2[8];
	expo_numo_3<={expo_num1,temp1_2[28:26]}+{expo_num2,temp2_2[28:26]};
	isInf_3<=isInf_2;
	isZero_3<=isZero_2;
end

frac_mult mult1(.clock(clk),.dataa({isZero_2,temp1_2[25:0]}),.datab({isZero_2,temp2_2[25:0]}) ,.result(mult_result[53:25]) );

reg isZero_3_2;
reg isInf_3_2;  //if one of the input numbers is Inf, this bit will be 1
reg frac_numo_3_2; //[54]:sign bit   [53]:for carry on 			[52]:1.   	[51:0]fraction bits
reg[1:0] expo_sign_3_2; //[1]: sign value of unum1     [0]: sign value of unum2
reg[8:0] expo_numo_3_2; //store exponent values
reg NaN_3_2;
always@(posedge clk)begin         //3rd
	isZero_3_2<=isZero_3;
	isInf_3_2<=isInf_3;
	frac_numo_3_2<=frac_numo_3;
	expo_sign_3_2<=expo_sign_3;
	expo_numo_3_2<=expo_numo_3;
	NaN_3_2<=NaN_3;
	
end


//4th: normalize the result of fraction multiplication 
reg isZero_4;
reg NaN_4;
reg[54:26] frac_numo_4; //[54]:sign bit    [53]:1.   [52:0]fraction bits
reg[8:0] expo_numo_4; //store exponent values
reg[1:0] expo_sign_4; //[1]: sign value of unum1     [0]: sign value of unum2
always@(posedge clk)begin         //4th
	frac_numo_4[54]<=frac_numo_3_2;
	if(mult_result[53])begin frac_numo_4[53:26]<=mult_result[53:26];expo_numo_4<=expo_numo_3_2+9'd1;end
	else begin  frac_numo_4[53:26]<=mult_result[52:25]; expo_numo_4<=expo_numo_3_2; end
	NaN_4<=NaN_3_2;
	expo_sign_4<=expo_sign_3_2;
	isZero_4<=isZero_3_2;
end


//5th: Right shift the exponent bits and fraction bits following the regime value (in order to adding regime bits on the left side)
reg overflow,underflow;
reg[31:0] runumo_5;
reg round;
reg NaN_5;
wire signed[31:0] shift;
assign shift={~expo_numo_4[8]&isZero_4,expo_numo_4[8]&isZero_4,{isZero_4,isZero_4,isZero_4}&expo_numo_4[2:0],frac_numo_4[52:26]};
always@(posedge clk)begin         //5th
	{runumo_5[30:0],round}<=shift>>>(expo_numo_4[8]?(~expo_numo_4[7:3]):expo_numo_4[7:3]);
	NaN_5<=NaN_4;
	overflow<=expo_numo_4[8]&(~expo_sign_4[1])&(~expo_sign_4[0]);
	underflow<=~expo_numo_4[8]&(expo_sign_4[1])&(expo_sign_4[0]);
	runumo_5[31]<=frac_numo_4[54];
end

//6th: check overflow, underflow, rounding and negative number
reg NaN_6;
reg[31:0] runumo_6;
always@(posedge clk)begin         //6th
	if(overflow) begin runumo_6<=32'h7fff_ffff;end
	else if(underflow) begin runumo_6<=32'h0000_0000; end
	else if(runumo_5[31]) begin  runumo_6[31]<=runumo_5[31];runumo_6[30:0]<=~runumo_5[30:0]+31'd1+{30'd0,round}; end //if the number is negative, take 2's complement
	else begin runumo_6[31]<=runumo_5[31]; runumo_6[30:0]<=runumo_5[30:0]+{30'd0,round}; end
	NaN_6<=NaN_5;
end

assign unum_o=runumo_6;
assign NaN=NaN_6;
endmodule 

//LZC(leading zero counter) module is designed based on MODULAR DESIGN OF FAST LEADING ZEROS COUNTING CIRCUIT (http://iris.elf.stuba.sk/JEEEC/data/pdf/6_115-05.pdf)
module LZC(
			input[30:0] x1,
			output[4:0] n
			);
wire[7:0] a;
wire[15:0] z;
reg[31:0] x;
reg [1:0] n1;
wire[2:0] y;
assign n[1:0]=n1[1:0];
assign n[4:2]=y;

always@(*)begin

	if(x1[30]) begin x[31:2]=~x1[29:0]; end			//if the number starts with 1, inverse it
	else begin x[31:2]=x1[29:0]; end
	x[1:0]=2'b10;
	case(y)
	3'b000: n1[1:0]=z[1:0];
	3'b001: n1[1:0]=z[3:2];
	3'b010: n1[1:0]=z[5:4];
	3'b011: n1[1:0]=z[7:6];
	3'b100: n1[1:0]=z[9:8];
	3'b101: n1[1:0]=z[11:10];
	3'b110: n1[1:0]=z[13:12];
	3'b111: n1[1:0]=z[15:14];
	endcase
end
BNE BNE1(.a(a), .y(y));			
NLC NLC7(.x(x[3:0]),		.a(a[7]), 	.z(z[15:14]) );
NLC NLC6(.x(x[7:4]),		.a(a[6]), 	.z(z[13:12]) );
NLC NLC5(.x(x[11:8]),	.a(a[5]),	.z(z[11:10]) );
NLC NLC4(.x(x[15:12]),	.a(a[4]), 	.z(z[9:8])  );
NLC NLC3(.x(x[19:16]),	.a(a[3]), 	.z(z[7:6])  );
NLC NLC2(.x(x[23:20]),	.a(a[2]), 	.z(z[5:4])  );
NLC NLC1(.x(x[27:24]),	.a(a[1]), 	.z(z[3:2])  );
NLC NLC0(.x(x[31:28]),	.a(a[0]), 	.z(z[1:0])  );
endmodule


module BNE(
			input[7:0] a,
			output[2:0] y 
			);
assign y[2]=a[1]&a[2]&a[3]&a[4];
assign y[1]=a[0]&a[1]&(~a[2]|~a[3]|(a[4]&a[5]));
assign y[0]=a[0]&(~a[1]|(a[2]&~a[3]))|(a[0]&a[2]&a[4]&(~a[5]|a[6]));
endmodule



module NLC(
			input[3:0] x,
			output a,
			output[1:0] z
			);

assign z[1]=~(x[3]|x[2]);
assign z[0]=~(((~x[2])&x[1])|x[3]);
assign a=~(x[0]|x[1]|x[2]|x[3]);
endmodule 