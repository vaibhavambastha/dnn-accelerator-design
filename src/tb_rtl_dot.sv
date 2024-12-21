module tb_rtl_dot();


    logic clk;
    logic rst_n;


    logic slave_waitrequest;
    logic [3:0] slave_address;
    logic slave_read;
    logic [31:0] slave_readdata;
    logic slave_write;
    logic [31:0] slave_writedata;


    logic master_waitrequest;
    logic [31:0] master_address;
    logic master_read;
    logic [31:0] master_readdata;
    logic master_readdatavalid;
    logic master_write;
    logic [31:0] master_writedata;


    dot dut(
        .clk(clk),
        .rst_n(rst_n),
        .slave_waitrequest(slave_waitrequest),
        .slave_address(slave_address),
        .slave_read(slave_read),
        .slave_readdata(slave_readdata),
        .slave_write(slave_write),
        .slave_writedata(slave_writedata),
        .master_waitrequest(master_waitrequest),
        .master_address(master_address),
        .master_read(master_read),
        .master_readdata(master_readdata),
        .master_readdatavalid(master_readdatavalid),
        .master_write(master_write),
        .master_writedata(master_writedata)
    );

 
    initial clk = 0;
    always #5 clk = ~clk; 


    integer i;
    logic [31:0] weights[0:7];
    logic [31:0] inputs[0:7];
    logic [31:0] expected_result;


    task slave_write_task(input [3:0] address, input [31:0] data);
        begin
            slave_address = address;
            slave_writedata = data;
            slave_write = 1;
            @(posedge clk);
            slave_write = 0;
        end
    endtask


    task slave_read_task(input [3:0] address, output [31:0] data);
        begin
            slave_address = address;
            slave_read = 1;
            @(posedge clk);
            data = slave_readdata;
            slave_read = 0;
        end
    endtask


    task mock_memory_read(input [31:0] address, output [31:0] data);
        begin
      
            master_waitrequest = 0;
            @(posedge clk);
            master_address = address;
            master_read = 1;
            @(posedge clk);
            master_read = 0;


            @(posedge clk);
            master_readdatavalid = 1;
            master_readdata = data;
            @(posedge clk);
            master_readdatavalid = 0;
        end
    endtask


    initial begin

        rst_n = 0;
        slave_address = 0;
        slave_read = 0;
        slave_write = 0;
        slave_writedata = 0;
        master_waitrequest = 1;
        master_readdatavalid = 0;
        master_readdata = 0;
        expected_result = 0;


        @(posedge clk);
        rst_n = 1;

        // Load weights and inputs
        for (i = 0; i < 8; i = i + 1) begin
            weights[i] = (i + 1) * 100; // Example weights
            inputs[i] = (i + 1) * 50;  // Example inputs
            expected_result += (weights[i] * inputs[i]) >> 16; // Q16.16 scaling
        end

        // Set up addresses and lengths
        slave_write_task(4'd2, 32'h1000); // Weights address
        slave_write_task(4'd3, 32'h2000); // Inputs address
        slave_write_task(4'd5, 8);       // Input length

        // Simulate memory responses
        fork
            for (i = 0; i < 8; i = i + 1) begin
                mock_memory_read(32'h1000 + (i * 4), weights[i]); // Weight memory
                mock_memory_read(32'h2000 + (i * 4), inputs[i]);  // Input memory
            end
        join

        slave_write_task(4'd0, 32'd1);


        slave_read_task(4'd0, slave_readdata);


        if (slave_readdata === expected_result) begin
            $display("Test Passed: Result = %0d", slave_readdata);
        end else begin
            $display("Test Failed: Expected = %0d, Got = %0d", expected_result, slave_readdata);
        end

        $finish;
    end

endmodule: tb_rtl_dot
