
module axi_lite_memory #(
	parameter   AXIL_DATA_WIDTH = 32,
			    AXIL_ADDR_WIDTH = 4
)(
	input wire  						clk,
	input wire  						reset,
	
	// AXI4-Lite read signals
	input wire  						arvalid,
	input wire [AXIL_ADDR_WIDTH-1:0]	araddr,
	input wire  						rready,
	
	output reg  						arready,
	output reg  						rvalid,
	output reg [AXIL_DATA_WIDTH-1:0]	rdata,
	output reg [1:0]					rresp,
	
	// AXI4-Lite write signals
	input wire  						awvalid,
	input wire [AXIL_ADDR_WIDTH-1:0]	awaddr,
	input wire  						wvalid,
	input wire [AXIL_DATA_WIDTH-1:0]	wdata,
	input wire [AXIL_DATA_WIDTH/8-1:0]	wstrb,
	input wire  						bready,

	output reg  						awready,
	output reg  						wready,
	output reg  						bvalid,
	output reg [1:0]					bresp
);

	localparam MEMORY_DEPTH = 2**AXIL_ADDR_WIDTH;

	reg [AXIL_DATA_WIDTH-1:0] mem [0:MEMORY_DEPTH-1];

	// Basic memory processing
	always @(posedge clk)
	begin
		// Reading from memory
		rdata <= mem[araddr];
	
		// Writing to memory
		mem[awaddr] <= wdata;
	end

endmodule
