
module axi_lite_memory_tb;

    localparam ADDR_WIDTH = 4;
    localparam DATA_WIDTH = 32;
    localparam MEMORY_DEPTH = 2**ADDR_WIDTH;

    logic                      clk = 1'b0;
    logic                      reset;
    logic                      awvalid;
    logic                      awready;
    logic [ADDR_WIDTH-1:0]     awaddr;
    logic                      wvalid;
    logic                      wready;
    logic [DATA_WIDTH-1:0]     wdata;
    logic [DATA_WIDTH/8-1:0]   wstrb;
    logic                      bvalid;
    logic                      bready;
    logic [1:0]                bresp;
    logic                      arvalid;
    logic                      arready;
    logic [ADDR_WIDTH-1:0]     araddr;
    logic                      rvalid;
    logic                      rready;
    logic [DATA_WIDTH-1:0]     rdata;
    logic [1:0]                rresp;

    axi_lite_memory #(
        .AXIL_DATA_WIDTH ( DATA_WIDTH  ),
        .AXIL_ADDR_WIDTH ( ADDR_WIDTH  )
    )
    dut (
        .clk     ( clk     ),
        .reset   ( reset   ),
        .awvalid ( awvalid ),
        .awready ( awready ),
        .awaddr  ( awaddr  ),
        .wvalid  ( wvalid  ),
        .wready  ( wready  ),
        .wdata   ( wdata   ),
        .wstrb   ( wstrb   ),
        .bvalid  ( bvalid  ),
        .bready  ( bready  ),
        .bresp   ( bresp   ),
        .arvalid ( arvalid ),
        .arready ( arready ),
        .araddr  ( araddr  ),
        .rvalid  ( rvalid  ),
        .rready  ( rready  ),
        .rdata   ( rdata   ),
        .rresp   ( rresp   )
    );

    initial begin
        forever begin
            clk <= ~clk;
            #4;
        end
    end
    initial begin
        reset <= 1'b1;
        repeat(10) @(posedge clk);
        reset <= 1'b0;
    end

    bit [DATA_WIDTH-1:0] memory [MEMORY_DEPTH];

    typedef struct {
        bit [ADDR_WIDTH-1:0]  addr;
        bit [DATA_WIDTH-1:0]  data;
    } write_msg_t;
    write_msg_t write_msg_que[$];
    write_msg_t write_msg_to_send_que[$];
    write_msg_t write_msg_to_ack_que[$];
    bit[ADDR_WIDTH-1:0] read_msg_que[$];
    bit[ADDR_WIDTH-1:0] read_msg_to_ack_que[$];

    function void generate_write_msg;
        write_msg_t write_msg_func;
        write_msg_func.addr = $urandom*4;
        write_msg_func.data = $urandom;
        write_msg_que.push_back(write_msg_func);
    endfunction : generate_write_msg

    function void generate_read_msg;
        bit[ADDR_WIDTH-1:0] addr_func;
        addr_func = $urandom*4;
        read_msg_que.push_back(addr_func);
    endfunction : generate_read_msg

    function bit queues_are_empty;
        if (write_msg_que.size() == 0 && write_msg_to_send_que.size() == 0 && write_msg_to_ack_que.size() == 0 &&
            read_msg_que.size() == 0 && read_msg_to_ack_que.size() == 0) begin
            return 1'b1;
        end
        else begin
            return 1'b0;
        end
    endfunction : queues_are_empty

    write_msg_t write_msg;
    bit[ADDR_WIDTH-1:0] read_msg;
    always @(posedge clk)
    if (reset) begin
        awvalid <= 1'b0;
        wvalid <= 1'b0;
        bready <= 1'b0;
        rready <= 1'b0;
        arvalid <= 1'b0;
    end
    else begin
        if (awready) begin
            awvalid <= 1'b0;
        end
        if ((awready || !awvalid) && $urandom % 2 != 0 && write_msg_que.size() != 0) begin
            write_msg = write_msg_que.pop_front();
            awvalid <= 1'b1;
            awaddr <= write_msg.addr;
            write_msg_to_send_que.push_back(write_msg);
        end

        if (wready) begin
            wvalid <= 1'b0;
        end
        if ((wready || !wvalid) && $urandom % 2 != 0 && write_msg_to_send_que.size() != 0) begin
            write_msg = write_msg_to_send_que.pop_front();
            wvalid <= 1'b1;
            wdata <= write_msg.data;
            wstrb <= '1;
            write_msg_to_ack_que.push_back(write_msg);
        end

        if (bvalid) begin
            bready <= 1'b0;
        end
        if ((bvalid || !bready) && $urandom % 2 != 0 && write_msg_to_ack_que.size() != 0) begin
            bready <= 1'b1;
        end

        if (bready && bvalid) begin
            write_msg = write_msg_to_ack_que.pop_front();
            memory[write_msg.addr] = write_msg.data;
        end

        if (arready) begin
            arvalid <= 1'b0;
        end
        if ((arready || !arvalid) && $urandom % 2 != 0 && read_msg_que.size() != 0) begin
            read_msg = read_msg_que.pop_front();
            arvalid <= 1'b1;
            araddr <= read_msg;
            read_msg_to_ack_que.push_back(read_msg);
        end

        if (rvalid) begin
            rready <= 1'b0;
        end
        if ((rvalid || !rready) && $urandom % 2 != 0 && read_msg_to_ack_que.size() != 0) begin
            rready <= 1'b1;
        end

        if (rready && rvalid) begin
            read_msg = read_msg_to_ack_que.pop_front();
            assert(memory[read_msg] == rdata)
            else begin
                $fatal(1, "Received wrong data from addr: %0d. Was: %h Should be: %h", read_msg,rdata,memory[read_msg]);
            end
        end
    end

    initial begin
        for (int j=0; j < 10; j++) begin
            for (int i=0;i< 1000; i++) begin
                generate_write_msg();
            end
            while(!queues_are_empty()) begin
                @(posedge clk);
            end
            for (int i=0;i< 1000; i++) begin
                generate_read_msg();
            end
            while(!queues_are_empty()) begin
                @(posedge clk);
            end
        end
        $display("TEST DONE!",);
        $finish();
    end

endmodule : axi_lite_memory_tb
