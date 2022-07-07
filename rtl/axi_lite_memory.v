
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
	output wire [1:0]					rresp,
	
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
	output wire [1:0]					bresp
);

	localparam MEMORY_DEPTH = 2**AXIL_ADDR_WIDTH;

	reg [AXIL_DATA_WIDTH-1:0] mem [0:MEMORY_DEPTH-1]; // memory
	
	// additional registers - buffers operations
    reg [AXIL_ADDR_WIDTH-1:0] araddr_nxt, awaddr_nxt; 
    reg [AXIL_ADDR_WIDTH-1:0] araddr_buff, awaddr_buff;
    reg [AXIL_DATA_WIDTH-1:0] wdata_nxt;
    reg [AXIL_DATA_WIDTH-1:0] wdata_buff;
    
    assign bresp = 2'b00; // set to "okay" response - to be change later
    assign rresp = 2'b00; // set to "okay" response - to be change later
//------------------------------------------------------------------------------------------------------------------------
// Combinational logic - buffers operations
    always @(*)
    begin
        // Reading from memory
        // Adress buffer
        if (arready == 1)
        begin
            araddr_nxt = araddr;
        end
        else
        begin
            araddr_nxt = araddr_buff;
        end
        
        // Writing to memory
        // Adress buffer
        if (awready == 1)
        begin
            awaddr_nxt = awaddr;
        end
        else
        begin
            awaddr_nxt = awaddr_buff;
        end
        
        // Data buffer
        if (wready == 1)
        begin
            wdata_nxt = wdata;
        end
        else
        begin
            wdata_nxt = wdata_buff;
        end
    end
//------------------------------------------------------------------------------------------------------------------------
// Sequential logic
	always @(posedge clk)
	begin
		if(!reset)
		begin
		    // requirements in accordance with AXI4-Lite protocol
			rvalid <= 1'b0;
			bvalid <= 1'b0;
		end
		else
		begin
//------------------------------------------------------------------------------------------------------------------------
// Reading from memory - requirements presented as conditions/cases
			if((rvalid == 1) && (rready == 0))
			begin
			    arready <= 1'b0;
			end
			else
			begin
			    arready <= 1'b1;
			end
			
			if( ((arvalid == 1) || (arready == 0)) || ((rvalid == 1) && (rready == 0)) )
			begin
				rvalid <= 1'b1;
			end
			else
			begin
			    rvalid <= 1'b0;
			end
			
			if((rvalid == 1) && (rready == 0))
			begin
			    arready <= 1'b0;
			end
			else
			begin
				arready <= 1'b1;
			end
			
            if (arready == 1)
            begin
                araddr_buff <= araddr;
            end
            else
            begin
                araddr_buff <= 0;
            end
            
			if((rvalid == 0) || (rready == 1))
			begin
				rdata <= mem[araddr_nxt]; // read from memory operation
			end
//------------------------------------------------------------------------------------------------------------------------		
// Writing to memory - requirements presented as conditions/cases
            if((wvalid == 1) || (wready == 0))
            begin
                awready <= 1'b1;
            end
            else
            begin
                awready <= 1'b0;
            end
            
            if((awvalid == 1) || (awready == 0))
            begin
                wready <= 1'b1;
            end
            else
            begin
                wready <= 1'b0;
            end
			
			if (awready == 1)
            begin
                awaddr_buff <= awaddr;
            end
            else
            begin
                awaddr_buff <= 0;
            end
            
            if (wready == 1)
            begin
                wdata_buff <= wdata;
            end
            else
            begin
                wdata_buff <= 0;
            end
			
			if( ((awvalid == 1) || (awready == 0)) && ((wvalid == 1) || (wready == 0)) )
			begin
			    bvalid <= 1'b1;
			end
			else
			begin
			    bvalid <= 1'b0;
			end
			
			if( ((bvalid == 0) || (bready == 1)) && ((awvalid == 1) || (awready == 0)) && ((wvalid == 1) || (wready == 0)) )
			begin
			     mem[awaddr_nxt] <= wdata_nxt; // write to memory operation
			end
		end
	end

endmodule
