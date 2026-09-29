`timescale 1ns / 1ps

module tb_Mem_Interface;

    reg Clock;
     
    reg EnableA;
    reg WriteEnableA;
    reg [9:0] AddressA;
    reg [15:0] DataInA;
    wire [15:0] DataOutA;

    reg EnableB;
    reg WriteEnableB;
    reg [9:0] AddressB;
    reg [15:0] DataInB;
    wire [15:0] DataOutB;
    
    MemoryInterface uut(
        .Clock(Clock),
        .EnableA(EnableA),
        .WriteEnableA(WriteEnableA),
        .AddressA(AddressA),
        .DataInA(DataInA),
        .DataOutA(DataOutA),
        .EnableB(EnableB),
        .WriteEnableB(WriteEnableB),
        .AddressB(AddressB),
        .DataInB(DataInB),
        .DataOutB(DataOutB)
    ); 

    integer errors;
    
    always #10 Clock = ~Clock;
    
    task read_a(input [9:0] addr, input [15:0] expected);
        begin
            @(negedge Clock); // Needs to not be posedge triggered otherwise it will interfere with design logic
            AddressA     = addr;
            EnableA      = 1'b1;
            WriteEnableA = 1'b0;
            @(posedge Clock);
            #1;
            if (DataOutA !== expected) begin
                $display("Failed read for port A | addr=%0d expected=%h got=%h", addr, expected, DataOutA);
                errors = errors + 1;
            end else begin
                $display("Pass read for port A | addr=%0d data=%h", addr, DataOutA);
            end
            @(negedge Clock);
            EnableA = 1'b0;
        end
    endtask
 
    task write_a(input [9:0] addr, input [15:0] data);
        begin
            @(negedge Clock);
            AddressA     = addr;
            DataInA      = data;
            EnableA      = 1'b1;
            WriteEnableA = 1'b1;
            @(posedge Clock);
            #1;
            
            if (uut.Memory[addr] !== data) begin
                $display("Failed write for Port A | addr=%0d expected=%h got=%h", addr, data, uut.Memory[addr]);
                errors = errors + 1;
            end else begin
                $display("Pass write for Port A | addr=%0d data=%h", addr, data);
            end
            
            @(negedge Clock);
            EnableA      = 1'b0;
            WriteEnableA = 1'b0;
        end
    endtask
 
    task read_b(input [9:0] addr, input [15:0] expected);
        begin
            @(negedge Clock);
            AddressB     = addr;
            EnableB      = 1'b1;
            WriteEnableB = 1'b0;
            @(posedge Clock);
            #1;
            
            if (DataOutB !== expected) begin
                $display("Failed read for port B | addr=%0d expected=%h got=%h", addr, expected, DataOutB);
                errors = errors + 1;
            end else begin
                $display("Pass read for port B |  addr=%0d data=%h", addr, DataOutB);
            end
            
            @(negedge Clock);
            EnableB = 1'b0;
        end
    endtask
 
    task write_b(input [9:0] addr, input [15:0] data);
        begin
            @(negedge Clock);
            AddressB     = addr;
            DataInB      = data;
            EnableB      = 1'b1;
            WriteEnableB = 1'b1;
            @(posedge Clock);
            #1;
            
            if (uut.Memory[addr] !== data) begin
                $display("Failed write for Port B | addr=%0d expected=%h got=%h", addr, data, uut.Memory[addr]);
                errors = errors + 1;
            end else begin
                $display("Pass write for Port B | addr=%0d data=%h", addr, data);
            end
            
            @(negedge Clock);
            EnableB      = 1'b0;
            WriteEnableB = 1'b0;
        end
    endtask
 
    initial begin
        Clock = 1'b0;
        errors       = 0;
        EnableA      = 0; 
        WriteEnableA = 0; 
        AddressA = 0; 
        DataInA = 0;
        EnableB      = 0; 
        WriteEnableB = 0; 
        AddressB = 0; 
        DataInB = 0;
 
        // Initial values
        read_a(10'd0,   16'h0010);
        read_a(10'd1,   16'h0020);
        read_a(10'd510, 16'h0040);
        read_a(10'd511, 16'h0050);
        read_a(10'd512, 16'h0060);
        read_a(10'd513, 16'h0070);
 
        // Write and read
        write_a(10'd12,  16'hFFFF);
        read_a (10'd12,  16'hFFFF);
        write_a(10'd511, 16'hABCD);
        read_a (10'd511, 16'hABCD);
        write_a(10'd512, 16'h1234);
        read_a (10'd512, 16'h1234);
        write_b(10'd1, 16'h5555);
        read_b (10'd1, 16'h5555);
 
        if (errors == 0)
            $display("All pass");
        else
            $display("%0d fails", errors);
 
        $finish;
    end

endmodule
