module dot(input logic clk, input logic rst_n,
          // slave (CPU-facing)
          output logic slave_waitrequest,
          input logic [3:0] slave_address,
          input logic slave_read, output logic [31:0] slave_readdata,
          input logic slave_write, input logic [31:0] slave_writedata,
          // master (memory-facing)
          input logic master_waitrequest,
          output logic [31:0] master_address,
          output logic master_read, input logic [31:0] master_readdata, input logic master_readdatavalid,
          output logic master_write, output logic [31:0] master_writedata);




   // your code here


/*
   word offset meaning
0   write: starts accelerator; read: stalls and provides result
1   reserved
2   weight matrix byte address
3   input activations vector byte address
4   reserved
5   input activations vector length
6   reserved
7   reserved
*/




enum {IDLE, WAIT_READ_WEIGHT, READ_WEIGHT, WAIT_READ_INPUT, READ_INPUT, COMPUTE, DONE} state;




logic [31:0] weight_address;
logic [31:0] input_address;
logic [31:0] input_length;
logic signed [31:0] total;
logic signed [63:0] product;
logic signed [31:0] weight_value, input_value;
logic [31:0] count;




always_ff @(posedge clk) begin
   if (!rst_n) begin
       state <= IDLE;
       total <= 0;
       count <= 0;
       weight_address <= 0;
       input_address <= 0;
       input_length <= 0;
   end else begin
       case (state)
           IDLE: begin
               if (slave_write) begin
                   case (slave_address)
                        4'd0: state <= WAIT_READ_WEIGHT;
                        4'd2: weight_address <= slave_writedata;
                        4'd3: input_address <= slave_writedata;
                        4'd5: input_length <= slave_writedata;
                   endcase
               end
               total <= 0;
               count <= 0;
           end
         
           WAIT_READ_WEIGHT: begin
               if (count < input_length) begin
                   if(master_waitrequest) state <= WAIT_READ_WEIGHT;
                   else state <= READ_WEIGHT;
               end else state <= DONE;
           end
         
           READ_WEIGHT: begin
               if (master_readdatavalid) state <= WAIT_READ_INPUT;
           end
         
           WAIT_READ_INPUT: begin
               if(master_waitrequest) state <= WAIT_READ_INPUT;
               else state <= READ_INPUT;
           end




           READ_INPUT: begin
               if (master_readdatavalid) begin
                   state <= COMPUTE;
               end
           end




           COMPUTE: begin
               if (master_readdatavalid) begin
                   product = weight_value * input_value;
                   total <= total + product[63:32];
                   count <= count + 1;
                   state <= WAIT_READ_WEIGHT;
               end
           end




           DONE: begin
               if (slave_read) begin
                   state <= IDLE;
               end
           end
       endcase
   end
end


   always_comb begin
       case(state)
           IDLE: begin
               slave_waitrequest = 1'b0;
               master_address = 32'd0;
               master_read = 1'd0;
               master_writedata = 32'd0;
               master_write = 1'd0;
               slave_readdata = 32'd0;
           end
           WAIT_READ_WEIGHT: begin
               slave_waitrequest = 1'b1;
               master_address = weight_address + (count << 2);
               master_read = 1'b1;
               master_writedata = 32'd0;
               master_write = 1'b0;
               slave_readdata = 32'd0;
           end
           READ_WEIGHT: begin
               slave_waitrequest = 1'd1;
               master_address = weight_address + (count << 2);
               master_read = 1'b0;
               master_writedata = 32'd0;
               master_write = 1'b0;
               slave_readdata = 32'd0;
           end
           WAIT_READ_INPUT: begin
               slave_waitrequest = 1'b1;
               master_address = input_address + (count << 2);
               master_read = 1'b1;
               master_writedata = 32'd0;
               master_write = 1'b0;  
               slave_readdata = 32'd0;            
           end
           READ_INPUT: begin
               slave_waitrequest = 1'd1;
               master_address = input_address + (count << 2);
               master_read = 1'b0;
               master_writedata = 32'd0;
               master_write = 1'b0;
               slave_readdata = 32'd0;
           end
           COMPUTE: begin
               slave_waitrequest = 1'b1;
               master_address = 32'd0;
               master_read = 1'b0;
               master_writedata = 32'd0;
               master_write = 1'b0;  
               slave_readdata = 32'd0;            
           end
           DONE: begin
               slave_waitrequest = 1'd0;
               master_address = 32'd0;
               master_read = 1'b1;
               master_writedata = 32'd0;
               master_write = 1'b0;  
               if(slave_read) begin
                   slave_readdata = total;
               end
               else slave_readdata = 32'd0;            
           end
           default: begin
               slave_waitrequest = 1'b0;
               master_address = 32'd0;
               master_read = 1'b0;
               master_writedata = 32'd0;
               master_write = 1'b0;
               slave_readdata = 32'd0;
           end
       endcase
   end

endmodule: dot