`timescale 1ns/1ps

module tb_cache_controller;
parameter ADDR_WIDTH=32;
parameter DATA_WIDTH=32;
parameter BLOCK_WORDS=4;
parameter NUM_SETS=8;

reg clk;
reg reset;
reg cpu_read;
reg cpu_write;
reg [ADDR_WIDTH-1:0]cpu_addr;
reg [DATA_WIDTH-1:0]cpu_wdata;
wire [DATA_WIDTH-1:0]cpu_rdata;
wire cpu_ready;
 
reg mem_ready;
wire mem_read;
wire mem_write;
wire [ADDR_WIDTH-1:0]mem_addr;
wire [DATA_WIDTH*BLOCK_WORDS-1:0]mem_wdata;
reg  [DATA_WIDTH*BLOCK_WORDS-1:0]mem_rdata;

//DUT Instantiation

cache_controller#(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.BLOCK_WORDS(BLOCK_WORDS),.NUM_SETS(NUM_SETS))
dut(.clk(clk),.reset(reset),
.cpu_read(cpu_read),.cpu_write(cpu_write),.cpu_addr(cpu_addr),.cpu_wdata(cpu_wdata),.cpu_rdata(cpu_rdata),.cpu_ready(cpu_ready),
.mem_read(mem_read),.mem_write(mem_write),.mem_addr(mem_addr),.mem_wdata(mem_wdata),.mem_rdata(mem_rdata),.mem_ready(mem_ready));

reg [DATA_WIDTH*BLOCK_WORDS-1:0]memory[0:255];
integer i;
always #5 clk=~clk;//DEFINING CLOCK

always@(posedge clk)begin
mem_ready=0;
//MEMORY READ
if(mem_read)begin
mem_rdata=memory[mem_addr>>4];
mem_ready=1;
$display("MEM READ  : addr=%h data=%h", mem_addr,mem_rdata );
end

//MEMORY WRITE
if (mem_write) begin
memory[mem_addr >> 4] = mem_wdata;
mem_ready = 1;
$display("MEM WRITE : addr=%h data=%h  <<< WRITEBACK!",mem_addr,mem_wdata);
end
end

//CPU WRITE
task cpu_write_task(input [31:0]addr,input [31:0]data);
begin
@(posedge clk);
cpu_addr<=addr;
cpu_wdata<=data;
cpu_write<=1;
cpu_read<=0;
@(posedge clk);
cpu_write<=0;
wait(cpu_ready);
$display("CPU WRITE DONE: addr=%h data=%h", addr, data);
end
endtask

// CPU READ
task cpu_read_task(input [31:0]addr);
begin
@(posedge clk);
cpu_addr<=addr;
cpu_read<=1;
cpu_write<=0;
@(posedge clk);  // wait for 2 clock cycles
cpu_read<=0;
wait(cpu_ready);
$display("CPU READ DONE: addr=%h data=%h", addr, cpu_rdata);
end
endtask

//TEST SEQUENCE
initial begin
clk=0;
reset=1;
cpu_read=0;
cpu_write=0;
mem_ready=0;

// Initializing memory
for(i=0;i<256;i=i+1) begin
memory[i]={4{i}};
end
#20 reset=0;
cpu_read_task(32'h0000_0000);  // set 0-miss
cpu_write_task(32'h0000_0000,32'hABCEDEFA);
cpu_read_task(32'h0000_0080);  // set 0 (different tag)-miss
cpu_read_task(32'h0000_0100);  // set 0 writeback
#100;
$finish;
end
endmodule
