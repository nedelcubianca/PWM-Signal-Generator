module pwm_gen (
    // peripheral clock signals
    input clk,
    input rst_n,
    // PWM signal register configuration
    input pwm_en,
    input[15:0] period, 
    input[7:0] functions,
    input[15:0] compare1,
    input[15:0] compare2,
    input[15:0] count_val,
    // top facing signals
    output pwm_out
);

    // Registrul intern care tine starea curenta a iesirii
    reg pwm_output_state;
    // Variabila temporara pentru calculul starii urmatoare (logica combinationala)
    reg next_pwm_state; 
    
    // Conectam registrul intern la portul de iesire
    assign pwm_out = pwm_output_state;

    wire is_at_start = (count_val == 16'b0000_0000_0000_0000); 
    wire is_at_comp1 = (count_val == compare1);
    wire is_at_comp2 = (count_val == compare2);

    //Logica Combinationala
    always @(*) begin
        next_pwm_state = pwm_output_state;
       
        if (functions[1] == 1'b1) begin
            //MOD NEALINIAT
            // Ordinea IF-urilor conteaza! Ultimul valid castiga.
            
            if (is_at_start) begin
                next_pwm_state = 1'b0;
            end
            
            if (is_at_comp1) begin
                next_pwm_state = 1'b1; 
            end
            
            if (is_at_comp2) begin
                next_pwm_state = 1'b0; 
            end
        end
        else begin
            //MOD ALINIAT (Stanga/Dreapta)             
            if (is_at_start) begin
                if (functions[0] == 1'b0) begin
                    next_pwm_state = 1'b1; 
                end
                else begin
                    next_pwm_state = 1'b0;
                end
            end

            if (is_at_comp1) begin
                if (functions[0] == 1'b0) begin
                    next_pwm_state = 1'b0; // Aliniat Stanga: Cade pe 0
                end
                else begin
                    next_pwm_state = 1'b1; // Aliniat Dreapta: Urca pe 1
                end
            end
        end
    end

    //Logica Secventiala
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            pwm_output_state <= 1'b0;
        end
        else if (pwm_en == 1'b0) begin
            // Cand este dezactivat, pastreaza starea curenta
            pwm_output_state <= pwm_output_state; 
        end
        else begin
            pwm_output_state <= next_pwm_state; 
        end
    end

endmodule