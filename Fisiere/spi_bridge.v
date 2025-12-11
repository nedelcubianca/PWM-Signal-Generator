`default_nettype none
`timescale 1ns/1ns

module spi_bridge (
    input  wire clk,
    input  wire rst_n,
    input  wire sclk,
    input  wire cs_n,
    input  wire miso,
    output wire mosi,
    output reg byte_sync,
    output reg [7:0] data_in,
    input  wire [7:0] data_out
);
    // retine 8 biti cititi pe miso
    reg [7:0] data_shift;
    
    // bitul curent primit
    reg [2:0] bit_cnt;
    
    // anunta terminarea transmiterii unui octet
    reg byte_done;
    
    // retine valoarea finala a octetului citit pe miso
    reg [7:0] data_final;
    
    // reset pentru shift register (doar la rst_n sau cs_n)
    wire shift_reset = !rst_n | cs_n;
    
    // primirea de la master pe frontul cresc?tor sclk
    always @(posedge sclk or posedge shift_reset) begin
        if (shift_reset) begin
            data_shift <= 8'b0000_0000;
            bit_cnt  <= 3'b000;
        end 
        else begin
            // shift catre stanga adaug pe LSB miso
            data_shift <= {data_shift[6:0], miso};
            bit_cnt  <= bit_cnt + 1'b1;
        end
    end
    
    // captureaza octetul final citit
    always @(posedge sclk or negedge rst_n) begin
        if (!rst_n) begin
            byte_done <= 1'b0;
            data_final <= 8'b0000_0000;
        end 
        else if (!cs_n) begin
            if (bit_cnt == 3'b111) begin
                byte_done <= ~byte_done;
                data_final <= {data_shift[6:0], miso};
            end
        end
    end
    
    // transmisia catre master pe frontul descresc?tor sclk
    reg [7:0] data_out_shift;
    
    always @(negedge sclk or posedge shift_reset) begin
        if (shift_reset) begin
            data_out_shift <= 8'b0000_0000;
        end else begin
            if (bit_cnt == 3'b000) begin
                data_out_shift <= data_out;
            end else begin
                data_out_shift <= {data_out_shift[6:0], 1'b0};
            end
        end
    end
    
    // mosi primeste MSB
    assign mosi = data_out_shift[7];
    
    // sincronizare cu domeniul clk
    
    // sincronizeaza semnalul byte_done cu ceasul clk
    reg [1:0] toggle_sync;
    
    // valoarea anterioara a toggle_sync[1]
    reg toggle_prev;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            toggle_sync <= 2'b00;
            toggle_prev <= 1'b0;
            byte_sync   <= 1'b0;
            data_in     <= 8'b0000_0000;
        end 
        else begin
            // retin valoarea din byte_done
            toggle_sync <= {toggle_sync[0], byte_done};
            
            toggle_prev <= toggle_sync[1];
            
            // detectare tranzitie - completarea unui octet
            if (toggle_sync[1] != toggle_prev) begin
                byte_sync <= 1'b1;
                data_in   <= data_final;
            end 
            else begin
                byte_sync <= 1'b0;
            end
        end
    end

endmodule

`default_nettype wire
