`timescale 1ns / 1ps

module tb_FIFO
    #(  parameter WIDTH   = 5,
        parameter DEPTH   = 16,   
        parameter T_READ  = 20, // i_dat ns
        parameter T_WRITE = 10 
     );
     
     reg                w_clk;
     reg                w_en;
     reg [WIDTH - 1:0]  i_dat;
     wire               w_full;
     wire               w_almost_full;
     
     reg                r_clk; 
     reg                r_en; 
     wire [WIDTH - 1:0] o_dat; 
     wire               r_empty;
     wire               r_almost_empty; 

    // Write clock
    always
        begin
            #(T_WRITE/2)
            w_clk <= (~w_clk);
        end          
    
    // Read clock
    always
        begin
            #(T_READ/2)
            r_clk <= (~r_clk);
        end
        
    reg rst;    
    reg r1_r_rst, r_rst; 
    reg r1_w_rst, w_rst;
    
    initial
        begin
            w_en   = 0;
            r_en   = 0;
            i_dat     = 0;
            w_clk  = 0;
            r_clk  = 0;
            rst    = 1;
            #(T_READ/4);       
            rst    = 0;
        end
        
    // Synchronize the resets 
    
    always @(posedge r_clk or posedge rst)
        begin
            if(rst) {r_rst, r1_r_rst} <= {2'b11};
            else    {r_rst, r1_r_rst} <= {r1_r_rst, 1'b0};               
        end 
    always @(posedge w_clk or posedge rst)
        begin
            if(rst) {w_rst, r1_w_rst} <= {2'b11};
            else    {w_rst, r1_w_rst} <= {r1_w_rst, 1'b0}; 
        end 
    
    FIFO #( .DEPTH(DEPTH), .WIDTH(WIDTH))
    UUT
    (   .w_clk(w_clk                 ),
        .w_rst(w_rst              ),
        .w_en(w_en                   ),
        .i_dat(i_dat                    ),
        .w_full(w_full                 ),
        .w_almost_full(w_almost_full   ),
        
        .r_clk(r_clk                 ),
        .r_rst(r_rst              ),
        .r_en(r_en                   ),
        .o_dat(o_dat                   ),
        .r_empty(r_empty               ),
        .r_almost_empty(r_almost_empty )
     );   
    
    // Ensure the delay is long enough so that the synchronized resets are '0'
    // by the time w_en = 1.
    
    localparam DELAY  = 3*T_READ;
    initial
        begin: TB
            integer i;
            #(DELAY); 
            
            // Write to FIFO until w_full
            // Purposely Overfill. 
            @(posedge r_clk) w_en = 1; 
            for(i = 0; i < DEPTH+5; i = i + 1)
                begin
                    @(posedge w_clk) i_dat = i+7;  
                end 
                 
            @(posedge w_clk) w_en = 0; 
            #(T_READ/2);
            r_en = 1; 
            
            // Read from FIFO until r_empty. 
            // Should not be able to read when r_empty. (i.e. Output stuck at 1st word) 
            for(i = 0; i < DEPTH+5; i = i + 1)
                begin
                    @(posedge r_clk)
                    ;               
                end
                
            @(posedge w_clk) w_en = 1;
            #(T_WRITE/2);
             
            // Read and Write to FIFO.    
            for(i = 0; i < DEPTH+10; i = i + 1)
                begin
                    @(posedge w_clk) i_dat = (i ^ 7) + 7;
                end     
            $finish(); 
                 
        end // test bench 
endmodule   // async_fifo_tb.v
