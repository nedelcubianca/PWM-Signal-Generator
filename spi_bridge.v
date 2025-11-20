module spi_bridge (
    // peripheral clock signals
    input clk,
    input rst_n,
    // SPI master facing signals
    input sclk,
    input cs_n,
    input mosi,
    output miso,
    // internal facing 
    output byte_sync,
    output[7:0] data_in,
    input[7:0] data_out
);

reg miso_r;
reg byte_sync_r;
reg [7:0] data_in_r;

assign miso = miso_r;
assign byte_sync = byte_sync_r;
assign data_in = data_in_r;

reg [2:0] counter;
reg byte_done;

always@(posedge sclk or posedge cs_n or negedge rst_n) begin
    if(!rst_n || cs_n) begin
        data_in_r <= 8'b00000000;
        counter <= 3'b000;
        byte_sync_r <= 0;
        byte_done <= 0;
    end
    else begin
        data_in_r <= {data_in_r[6:0] ,mosi};
        counter <= counter + 1;
        if(counter == 3'b111) begin
            byte_sync_r <= 1;
            byte_done <= 1;
        end
        else begin
            byte_sync_r <= 0;
        end
        
        if(byte_done) begin
            counter <= 3'b000;
            byte_done <= 0;
        end
    end
end

reg [2:0] miso_cnt;

always @(negedge cs_n or negedge rst_n) begin
    if (!rst_n)
        miso_cnt <= 3'b111;
    else
        miso_cnt <= 3'b111;   // primul bit transmis este MSB
end

always @(negedge sclk or posedge cs_n or negedge rst_n) begin
    if (!rst_n || cs_n) begin
        miso_r <= 1'b0;
    end else begin
        miso_r <= data_out[miso_cnt];

        if (miso_cnt != 3'b000)
            miso_cnt <= miso_cnt - 1;
    end
end



endmodule