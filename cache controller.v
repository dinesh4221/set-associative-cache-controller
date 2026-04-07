module cache_controller #(
parameter ADDR_WIDTH=32,
parameter DATA_WIDTH=32,
parameter BLOCK_WORDS=4,
parameter NUM_SETS=8
)(input  clk,
input  reset,
// CPU interface
input cpu_read,
input cpu_write,
input [ADDR_WIDTH-1:0]cpu_addr,
input [DATA_WIDTH-1:0]cpu_wdata,
output reg [DATA_WIDTH-1:0]cpu_rdata,
output reg cpu_ready,

// Memory interface
output reg mem_read,
output reg mem_write,
output reg [ADDR_WIDTH-1:0]mem_addr,
output reg [DATA_WIDTH*BLOCK_WORDS-1:0]mem_wdata,
input [DATA_WIDTH*BLOCK_WORDS-1:0]mem_rdata,
input mem_ready
);

localparam OFFSET_BITS=$clog2(BLOCK_WORDS*(DATA_WIDTH/8));
localparam INDEX_BITS=$clog2(NUM_SETS);
localparam TAG_BITS=ADDR_WIDTH-INDEX_BITS-OFFSET_BITS;

reg [INDEX_BITS-1:0] index_reg;
reg [TAG_BITS-1:0]   tag_reg;
reg [1:0] word_offset_reg;

reg [ADDR_WIDTH-1:0]addr_reg;
reg [DATA_WIDTH-1:0]wdata_reg;
reg read_reg,write_reg;

    
//Cache storage
reg [DATA_WIDTH*BLOCK_WORDS-1:0]data_array[0:NUM_SETS-1][0:1];
reg [TAG_BITS-1:0]tag_array[0:NUM_SETS-1][0:1];
reg valid_array[0:NUM_SETS-1][0:1];
reg dirty_array[0:NUM_SETS-1][0:1];
reg lru[0:NUM_SETS-1];

// FSM states
localparam IDLE=2'd0, LOOKUP=2'd1, WRITEBACK=2'd2, ALLOCATE=2'd3;

reg [1:0] state;
reg replace_way;
integer i, j;

// HIT logic
wire hit0=valid_array[index_reg][0] && (tag_array[index_reg][0] == tag_reg);
wire hit1=valid_array[index_reg][1] && (tag_array[index_reg][1] == tag_reg);
wire hit=hit0||hit1;

wire hit_way=hit1;
reg alloc_issued;

always @(posedge clk or posedge reset) begin
if(reset)begin
for(i=0;i<NUM_SETS;i=i+1) begin
for(j=0;j<2;j=j+1) begin
valid_array[i][j]<=0;
dirty_array[i][j]<=0;
tag_array[i][j]<=0;
data_array[i][j]<=0;
end
lru[i]<=0;
end
state<=IDLE;
cpu_ready<=0;
mem_read<=0;
mem_write<=0;
mem_addr<=0;
mem_wdata<=0;
alloc_issued<=0;
end
else begin
cpu_ready<=0;
mem_read<=0;
mem_write<=0;

case(state)
IDLE:begin
if(cpu_read||cpu_write)begin
addr_reg<=cpu_addr;
wdata_reg<=cpu_wdata;
read_reg<=cpu_read;
write_reg<=cpu_write;
index_reg<=cpu_addr[OFFSET_BITS +:INDEX_BITS];
tag_reg<=cpu_addr[ADDR_WIDTH-1 -:TAG_BITS];
word_offset_reg<=cpu_addr[3:2];//the 2 msb in the offset gives the word no.
state<= LOOKUP;
end
end
//------------------------------------
LOOKUP:begin
if (hit) begin
//READ HIT
if(read_reg)begin
cpu_rdata<=data_array[index_reg][hit_way]
[word_offset_reg*DATA_WIDTH +:DATA_WIDTH];
end
//WRITE HIT
if(write_reg)begin
data_array[index_reg][hit_way][word_offset_reg*DATA_WIDTH +: DATA_WIDTH]<=wdata_reg;
dirty_array[index_reg][hit_way]<=1;
end

lru[index_reg]<=~hit_way;//lru update
cpu_ready<=1;
state<=IDLE;
end
else begin
//MISS
replace_way<=lru[index_reg];
if (valid_array[index_reg][lru[index_reg]] && dirty_array[index_reg][lru[index_reg]])begin
state<=WRITEBACK;
end
else begin
state<=ALLOCATE;
end
end
end
//----------------------------------
WRITEBACK:begin
if(!mem_write)begin
mem_write <= 1;
mem_addr  <= {tag_array[index_reg][replace_way],
index_reg,
{OFFSET_BITS{1'b0}}};
mem_wdata <= data_array[index_reg][replace_way];
end
if(mem_ready)begin
mem_write<=0;
state<=ALLOCATE;
end
end
//------------------------------------
ALLOCATE:begin
if(!alloc_issued)begin
mem_read<=1;
mem_addr<={tag_reg,index_reg,{OFFSET_BITS{1'b0}}};
alloc_issued<=1;
end
else begin
mem_read<=0;
end
if(mem_ready && alloc_issued)begin
data_array[index_reg][replace_way]<=mem_rdata;
tag_array[index_reg][replace_way]<=tag_reg;
valid_array[index_reg][replace_way]<=1;
dirty_array[index_reg][replace_way]<=0;
alloc_issued<=0;
state<=LOOKUP;
end
end
endcase
end
end
endmodule
