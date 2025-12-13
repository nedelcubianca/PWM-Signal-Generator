`default_nettype none
`timescale 1ns/1ns

module pwm_gen (
    input wire clk,
    input wire rst_n, 
    input wire pwm_en, // Activare generator PWM
    input wire [15:0] period, // Limita maxima a numaratorului
    input wire [7:0] functions, // Selectie mod lucru: [1]=Unaligned, [0]=Right/Left
    input wire [15:0] compare1, // Prag 1 (Duty cycle sau Start pulse)
    input wire [15:0] compare2, // Prag 2 (End pulse - folosit doar la Unaligned)
    input wire [15:0] count_val, // Valoarea curenta primita de la counter
    output wire pwm_out // Semnalul PWM final
);

    // Semnale interne 
    // Calculam valoarea PWM combinational
    wire pwm_logic_result;

    // LOGICA COMBINATIONALA
    assign pwm_logic_result = 
    // Cazul 1: UNALIGNED (functions[1] == 1)
    (functions[1]) ? ((count_val >= compare1) && (count_val < compare2)) :
    
    // Cazul 2: ALIGN_RIGHT (functions[0] == 1)
    (functions[0]) ? (count_val >= compare1) :
    
    // Cazul 3 (Default): ALIGN_LEFT
                     ((compare1 != 16'b0000_0000_0000_0000) && (count_val <= compare1));
            
                           
    // Memoram ultima valoare pentru cand pwm_en devine 0
    reg pwm_last_state; // Fara el, daca pwm_en devine 0, iesirea ar putea sari direct in 0 sau 1 fara control. Astfel, in acest mod, ramane blocata pe ultima stare pana la reactivare

    // LOGICA SECVENTIALA (memorarea)
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 0) begin
            pwm_last_state <= 1'b0;
        end 
        else if (pwm_en != 0) begin
            pwm_last_state <= pwm_logic_result;
        end
    end
    
    // Output: cand PWM e enabled, valoare calculata; altfel, ultima valoare
    assign pwm_out = pwm_en ? pwm_logic_result : pwm_last_state;

endmodule

`default_nettype wire
