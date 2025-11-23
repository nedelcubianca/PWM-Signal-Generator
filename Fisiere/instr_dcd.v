module instr_dcd (
    // peripheral clock signals
    input clk,
    input rst_n,
    // towards SPI slave interface signals
    input byte_sync,
    input[7:0] data_in,
    output[7:0] data_out,
    // register access signals
    output read,
    output write,
    output[5:0] addr,
    input[7:0] data_read,
    output[7:0] data_write
);

    // FSM states
    parameter SETUP_STATE = 1'b0;
    parameter DATA_STATE  = 1'b1;
    
    reg state, next_state;
    
    // latched fields from setup byte -> data_in
    reg      rw_bit; // 1=write, 0=read
    reg      high_low; // 1=MSB, 0=LSB
    reg[5:0] base_addr; // lower 6 bits
    
    // registered outputs
    reg      read_r, write_r;
    reg[5:0] addr_r;
    reg[7:0] data_write_r; // reg
    reg[7:0] data_out_r; // spi
    
    assign read       = read_r;
    assign write      = write_r;
    assign addr       = addr_r;
    assign data_write = data_write_r;
    assign data_out   = data_out_r;
    
    // address after MSB/LSB selection
    wire[5:0] eff_addr = base_addr + (high_low ? 6'd1 : 6'd0);
    
    // Sequential part (registers)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin 
            state         <= SETUP_STATE;
            
            rw_bit        <= 1'b0;
            high_low      <= 1'b0;
            base_addr    <= 6'd0;
            
            read_r        <= 1'b0;
            write_r       <= 1'b0;
            addr_r        <= 6'd0;
            data_write_r  <= 8'd0;
            data_out_r    <= 8'd0;
         end else begin 
            state   <= next_state;
            read_r  <= 1'b0;
            write_r <= 1'b0;
            
            case (state) 
                SETUP_STATE: begin
                    if (byte_sync) begin
                        rw_bit    <= data_in[7];
                        high_low  <= data_in[6];
                        base_addr <= data_in[5:0];
                    
                        data_out_r <= 8'h00;
                    end
                end
                DATA_STATE: begin
                    if (byte_sync) begin
                        addr_r       <= eff_addr;
                        
                        if (rw_bit) begin 
                        // ----WRITE----
                        write_r      <= 1'b1;
                        data_write_r <= data_in;
                        data_out_r   <= 8'h00;
                        
                        end else begin
                        // ----READ----
                        read_r       <= 1'b1;
                        data_out_r   <= data_read;
                        end
                   end
                end
            endcase
         end    
    end
    
    
    // Combinational part (next state)
    always @(*) begin
        next_state = state;
        case (state) 
            SETUP_STATE: begin
                if (byte_sync) 
                    next_state = DATA_STATE;
            end
            
            DATA_STATE: begin
                if (byte_sync)
                    next_state = SETUP_STATE;
            end
        
        endcase
    
    end

endmodule
