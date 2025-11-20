module regs (
    // peripheral clock signals
    input clk,
    input rst_n,
    // decoder facing signals
    input read,
    input write,
    input[5:0] addr,
    output[7:0] data_read,
    input[7:0] data_write,
    // counter programming signals
    input[15:0] counter_val,
    output[15:0] period,
    output en,
    output count_reset,
    output upnotdown,
    output[7:0] prescale,
    // PWM signal programming values
    output pwm_en,
    output[7:0] functions,
    output[15:0] compare1,
    output[15:0] compare2
);

/*
    All registers that appear in this block should be similar to this. Please try to abide
    to sizes as specified in the architecture documentation.
*/
    reg[15:0] period; // 0x00, 0x01 - LSB, MSB, perioada exprimata in cicli de ceas a numaratorului
    reg       en_r; // 0x02 counter enable, numaratorul este activ sau nu, 1 bit
    reg[15:0] compare1_r; // 0x03, 0x04 - LSB, MSB, valoare la care semnalul PWM se schimba
    reg[15:0] compare2_r; // 0x05, 0x06 - LSB, MSB, valoare la care semnalul PWM se schimba - pt. descentrare
    reg       count_reset_r; // 0x07, doar scriere, reseteaza starea numaratorului la 0 dupa scriere lui, apoi registrul se goleste dupa al doilea ciclu de ceas
    reg[7:0]  prescale_r; // 0x0a, doar citire, numarul de ciclii de ceas dupa care numaratorul va fi incrementat
    reg       upnotdown_r; //0x0b, la 0x08 si 0x09 este counter_val pe care il primeste de la counter.v, directia in care numaratorul incrementeaza valoarea interna
    // counter_val doar citire
    reg       pwm_en_r; // 0x0c, activeaza canalul de iesire a semnalului pwm
    reg[1:0]  functions_r; // 0x0d, bitul 0 - stanga0, dreapta1, bitul 1 - aliniere0, nealiniere1
    
    assign en        = en_r;
    assign compare1  = compare1_r;
    assign compare2  = compare2_r;
    assign prescale  = prescale_r;
    assign upnotdown = upnotdown_r;
    assign pwm_en    = pwm_en_r;
    assign functions = functions_r;
    
    
    
    // Write logic
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            period        <= 16'h0000;
            en_r          <= 1'b0;
            compare1_r    <= 16'h0000;
            compare2_r    <= 16'h0000;
            count_reset_r <= 1'b0;
            prescale_r    <= 8'h00;
            upnotdown_r   <= 1'b0;
            pwm_en_r      <= 1'b0;
            functions_r   <= 2'b00;           
        end else begin
            // Here should be the rest of the implementation
            // COUNTER_RESET goes back to 0 after 1 clk
             count_reset_r <= 1'b0;
             if (write) begin
                case (addr)
                    6'h00: period[7:0]      <= data_write;
                    6'h01: period[15:8]     <= data_write;
                    
                    6'h02: en_r             <= data_write[0];
                    
                    6'h03: compare1_r[7:0]  <= data_write;
                    6'h04: compare1_r[15:8] <= data_write;
                    
                    6'h05: compare2_r[7:0]  <= data_write;
                    6'h06: compare2_r[15:8] <= data_write;
                    
                    6'h07: count_reset_r    <= 1'b1;
                    
                    // COUNTER_VAL (0x08, 0x09) - read only - ignores writes
                    
                    6'h0A: prescale_r      <= data_write;
                    
                    6'h0B: upnotdown_r     <= data_write[0];
                    
                    6'h0C: pwm_en_r        <= data_write[0];
                    
                    6'h0D: functions_r     <= data_write[1: 0];
                    
                    
                endcase
             
             end
        end
    end

    // Read logic
    
    reg[7:0] data_read_r;
    assign data_read = data_read_r;
    
    always @(*) begin
        case (addr) 
            6'h00:   data_read_r = period[7:0];
            6'h01:   data_read_r = period[15:8];
                            
            6'h02:   data_read_r = {7'b0, en_r};
                            
            6'h03:   data_read_r = compare1_r[7:0];
            6'h04:   data_read_r = compare1_r[15:8];
                            
            6'h05:   data_read_r = compare2_r[7:0];
            6'h06:   data_read_r = compare2_r[15:8];
                            
            6'h07:   data_read_r = 8'h00; // write-only
            
            6'h08:   data_read_r = counter_val[7:0];
            6'h09:   data_read_r = counter_val[15:8];
            
                            
            6'h0A:   data_read_r = prescale_r;
                            
            6'h0B:   data_read_r = {7'b0, upnotdown_r};
                            
            6'h0C:   data_read_r = {7'b0, pwm_en_r};
                            
            6'h0D:   data_read_r = {6'b0, functions_r};
            
            default: data_read_r = 8'h00;

        endcase
    
    end


endmodule