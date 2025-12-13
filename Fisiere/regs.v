`default_nettype none
`timescale 1ns/1ns

module regs (
    // Semnale de ceas si reset
    input  wire        clk,
    input  wire        rst_n,
    
    // Interfata cu decodorul de instructiuni 
    input  wire        read,
    input  wire        write,
    input  wire [5:0]  addr,
    output reg  [7:0]  data_read,
    input  wire [7:0]  data_write,
    
    // Interfata cu counter (intrari)
    input  wire [15:0] counter_val,
    
    // Interfata cu counter (iesiri)
    output reg  [15:0] period,
    output reg         en,           // COUNTER_EN
    output reg         count_reset,  // COUNTER_RESET
    output reg         upnotdown,
    output reg  [7:0]  prescale,
    
    // Interfata cu generatorul de semnale 
    output reg         pwm_en,
    output reg  [7:0]  functions,    // Doar [1:0] sunt folositi
    output reg  [15:0] compare1,
    output reg  [15:0] compare2
);

    // Adressele din tabel
    localparam ADDR_PERIOD_L       = 6'b00_0000;
    localparam ADDR_PERIOD_H       = 6'b00_0001;
    localparam ADDR_COUNTER_EN     = 6'b00_0010;
    localparam ADDR_COMPARE1_L     = 6'b00_0011;
    localparam ADDR_COMPARE1_H     = 6'b00_0100;
    localparam ADDR_COMPARE2_L     = 6'b00_0101;
    localparam ADDR_COMPARE2_H     = 6'b00_0110;
    localparam ADDR_COUNTER_RESET  = 6'b00_0111;
    localparam ADDR_COUNTER_VAL_L  = 6'b00_1000;
    localparam ADDR_COUNTER_VAL_H  = 6'b00_1001;
    localparam ADDR_PRESCALE       = 6'b00_1010;
    localparam ADDR_UPNOTDOWN      = 6'b00_1011;
    localparam ADDR_PWM_EN         = 6'b00_1100;
    localparam ADDR_FUNCTIONS      = 6'b00_1101;

    // Counter pentru auto-clear la COUNTER_RESET
    // Reset-ul se auto-goleste dupa 2 cicluri de ceas (este necesar un counter de 2 biti)
    reg [1:0] reset_clear_cnt;

    // Logica de scriere (Secventiala) 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            period          <= 16'b0000_0000_0000_0000;
            en              <= 1'b0;
            compare1        <= 16'b0000_0000_0000_0000;
            compare2        <= 16'b0000_0000_0000_0000;
            count_reset     <= 1'b0;
            prescale        <= 8'b0000_0000;
            upnotdown       <= 1'b1;
            pwm_en          <= 1'b0;
            functions       <= 8'b0000_0000;
            reset_clear_cnt <= 2'b00;
        end else begin
            // Auto-clear pentru COUNTER_RESET dupa 2 cicluri
            if (count_reset) begin
                if (reset_clear_cnt >= 2'b01) begin // daca a trecut cel putin 1 ciclu (de la 0 la 1)
                    count_reset <= 1'b0;           // golesc registrul (reset puls terminat)
                    reset_clear_cnt <= 2'b00;       // resetez counter-ul
                end else begin
                    reset_clear_cnt <= reset_clear_cnt + 2'b01;  // incrementez counter-ul 
                end
            end
            
            // Procesarea operatiei de scriere 
            if (write) begin // se scrie doar cand semnalul 'write' este activ (puls de 1 ciclu)
                case (addr)
                    ADDR_PERIOD_L:      period[7:0]   <= data_write;     
                    ADDR_PERIOD_H:      period[15:8]  <= data_write;     
                    ADDR_COUNTER_EN:    en            <= data_write[0];  
                    ADDR_COMPARE1_L:    compare1[7:0] <= data_write;     
                    ADDR_COMPARE1_H:    compare1[15:8]<= data_write;
                    ADDR_COMPARE2_L:    compare2[7:0] <= data_write;
                    ADDR_COMPARE2_H:    compare2[15:8]<= data_write;
                    ADDR_COUNTER_RESET: begin
                        // Scriere puls COUNTER_RESET, activez semnalul si resetez counter-ul de auto-clear
                        count_reset <= data_write[0];
                        reset_clear_cnt <= 2'b00;
                    end
                    ADDR_PRESCALE:      prescale      <= data_write;
                    ADDR_UPNOTDOWN:     upnotdown     <= data_write[0];
                    ADDR_PWM_EN:        pwm_en        <= data_write[0];
                    ADDR_FUNCTIONS:     functions     <= data_write;
                    // Alte adrese: ignorate
                    default: ;
                endcase
            end
        end
    end

    // Logica de citire (Combinationala)
    always @(*) begin
        case (addr)
            ADDR_PERIOD_L:      data_read = period[7:0];
            ADDR_PERIOD_H:      data_read = period[15:8];
            ADDR_COUNTER_EN:    data_read = {7'b000_0000, en};
            ADDR_COMPARE1_L:    data_read = compare1[7:0];
            ADDR_COMPARE1_H:    data_read = compare1[15:8];
            ADDR_COMPARE2_L:    data_read = compare2[7:0];
            ADDR_COMPARE2_H:    data_read = compare2[15:8];
            ADDR_COUNTER_RESET: data_read = 8'b0000_0000;  // Write-only, returneaza 0
            ADDR_COUNTER_VAL_L: data_read = counter_val[7:0];
            ADDR_COUNTER_VAL_H: data_read = counter_val[15:8];
            ADDR_PRESCALE:      data_read = prescale;
            ADDR_UPNOTDOWN:     data_read = {7'b000_0000, upnotdown};
            ADDR_PWM_EN:        data_read = {7'b000_0000, pwm_en};
            ADDR_FUNCTIONS:     data_read = functions;
            default:            data_read = 8'b0000_0000;  // Adrese nedefinite
        endcase
    end

endmodule
`default_nettype wire
