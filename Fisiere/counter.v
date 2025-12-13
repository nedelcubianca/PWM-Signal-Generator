`default_nettype none
`timescale 1ns/1ns

module counter (
    input wire clk,
    input wire rst_n, // Reset asincron, activ pe 0
    input  wire [15:0] period, // Valoarea maxima/limita de numarare
    input  wire en,           
    input  wire count_reset,  // Reset sincron
    input  wire  upnotdown,    // 1=up, 0=down
    input  wire [7:0] prescale,      // Numara la fiecare 2^prescale cicluri
    output reg  [15:0] count_val   // Valoarea actuala a numaratorului
);
    // Semnale interne
    reg [15:0] prescale_cnt;
    wire [15:0] prescale_limit;
    
    // Calculam 2^prescale - 1 (pentru comparatie)
    // Limitam la 16 biti pentru a evita overflow

    //  LOGICA COMBINATIONALA 
    assign prescale_limit = (prescale < 8'b00010000) ? ((16'b0000000000000001 << prescale) - 16'b0000000000000001) : 16'b1111_1111_1111_1111;
    
    // Semnal care indica cand trebuie sa incrementam/decrementam counter-ul principal
    wire tick;
    assign tick = (prescale_cnt >= prescale_limit) && en;

    // LOGICA SECVENTIALA
    // Logica prescaler
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 0) begin
            prescale_cnt <= 16'b0000_0000_0000_0000;
        end else if (count_reset != 0) begin
            prescale_cnt <= 16'b0000_0000_0000_0000;
        end else if (en == 0) begin
            prescale_cnt <= 16'b0000_0000_0000_0000;
       // Daca dam reset sau oprim numaratorul, aducem si divizorul la zero
       // ca sa avem un start curat data viitoare.
        end else begin
            if (prescale_cnt >= prescale_limit) begin
                prescale_cnt <= 16'b0000_0000_0000_0000;
            end else begin
                prescale_cnt <= prescale_cnt + 16'b0000_0000_0000_0001;
            end
        end
    end
    
    // Logica counter principal
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 0) begin
            count_val <= 16'b0000_0000_0000_0000;
        end else if (count_reset != 0) begin
            // Reset explicit al counter-ului
            if (upnotdown != 0) begin
                count_val <= 16'b0000_0000_0000_0000;
            end else begin
                count_val <= period;
            end
        end else if (en != 0 && tick != 0) begin
            // Counter-ul este activ si avem tick de la prescaler
            if (upnotdown != 0) begin
                // Numarare in sus
                if (count_val >= period) begin
                    count_val <= 16'b0000_0000_0000_0000;  // Overflow - reset la 0
                end else begin
                    count_val <= count_val + 16'b0000_0000_0000_0001;
                end
            end else begin
                // Numarare in jos
                if (count_val == 16'b0000_0000_0000_0000) begin
                    count_val <= period;  // Underflow - reset la period
                end else begin
                    count_val <= count_val - 16'b0000_0000_0000_0001;
                end
            end
        end
        // Daca en=0, counter-ul isi pastreaza valoarea
    end

endmodule

`default_nettype wire
