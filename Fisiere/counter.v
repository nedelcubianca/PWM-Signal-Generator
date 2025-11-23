module counter (
    // peripheral clock signals
    input clk,
    input rst_n,
    // register facing signals
    output[15:0] count_val,
    input[15:0] period,
    input en,
    input count_reset,
    input upnotdown,
    input[7:0] prescale
);

    // Prescaler Intern 
    reg[7:0] prescaler_counter; // Registru intern pentru a numara ciclii de ceas ai prescaler-ului
    reg[7:0] next_prescaler_counter; //pentru logica combinationala 
    wire[7:0] prescale_target = (1 << prescale) - 1;
    // prescaler_en = 1 pentru un singur ciclu de ceas
    // doar atunci cand prescaler-ul a atins tinta (prescale_target) si numaratorul principal e activat (en = 1)
    wire prescaler_en = (prescaler_counter == prescale_target) && en;

    always @(*) begin

        next_prescaler_counter = prescaler_counter;
        if (en == 0) begin
            next_prescaler_counter = 8'b0000_0000; // Resetam prescaler-ul cand numartorul e oprit

        end
        else if (prescaler_en == 1) begin
            next_prescaler_counter = 8'b0000_0000; // Se reseteaza la 0 dupa ce a atins tinta (prescale_target)

        end
        else begin
            next_prescaler_counter = prescaler_counter + 1; // Altfel, incrementeaza
        end
    end

    // Logica secventiala pentru prescaler
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 0) begin
            prescaler_counter <= 8'b0000_0000;
        end
        else begin
            prescaler_counter <= next_prescaler_counter; 
        end
    end

    // Numaratorul Principal 

    // Registrul intern care tine valoarea curenta a numaratorului
    reg[15:0] counter_value;  
    reg[15:0] next_counter_value;
    // il conectam la portul de iesire
    assign count_val = counter_value; 

    always @(*) begin
        next_counter_value = counter_value;

        if (count_reset == 1) begin
            next_counter_value = 16'b0000_0000_0000_0000; //declansat de registrul COUNTER_RESET

        end
        else if (en == 1 && prescaler_en == 1) begin           
            if (upnotdown == 1) begin
                //Modul Incrementare
                if (counter_value == period) begin
                    next_counter_value = 16'b0000_0000_0000_0000; // Overflow--> inapoi la 0
                end
                else begin
                    next_counter_value = counter_value + 1;
                end
            end
            else begin
                //Modul Decrementare
                if (counter_value == 16'b0000_0000_0000_0000) begin
                    next_counter_value = period; // Underflow--> inapoi la period
                end
                else begin
                    next_counter_value = counter_value - 1;
                end
            end
        end
    end

    // Logica secventiala pentru numaratorul principal
    always @(posedge clk or negedge rst_n) begin
        // daca rst_n == 0, circuitul intra in reset; daca rst_n == 1, circuitul functioneaza normal, numara.
        if (rst_n == 0) begin
            counter_value <= 16'b0000_0000_0000_0000; 
        end
        else begin
            counter_value <= next_counter_value;
        end
            
    end
    
endmodule