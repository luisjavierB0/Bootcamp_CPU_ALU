`timescale 1ns/1ps

module tiny8_cpu (
    input  wire       clk,
    input  wire       rst_n,

    // Interfaz hacia fetch SPI
    output reg        fetch_start,
    output wire [7:0] fetch_addr,
    input  wire       fetch_busy,
    input  wire       fetch_done,
    input  wire [15:0] fetch_instr,

    // Salida visible del procesador
    output reg [7:0]  port_out
);

    localparam ST_FETCH_REQ  = 3'd0;
    localparam ST_FETCH_WAIT = 3'd1;
    localparam ST_EXECUTE    = 3'd2;
    localparam ST_HALT       = 3'd3;

    localparam OP_NOP     = 4'h0;
    localparam OP_LDI_ACC = 4'h1;
    localparam OP_LDI_R1  = 4'h2;
    localparam OP_ADD     = 4'h3;
    localparam OP_SUB     = 4'h4;
    localparam OP_AND     = 4'h5;
    localparam OP_OR      = 4'h6;
    localparam OP_XOR     = 4'h7;
    localparam OP_CMP     = 4'h8;
    localparam OP_OUT     = 4'h9;
    localparam OP_JMP     = 4'hA;
    localparam OP_BZ      = 4'hB;
    localparam OP_BNZ     = 4'hC;
    localparam OP_HALT    = 4'hD;

    reg [2:0]  state;
    reg [4:0]  pc;
    reg [15:0] ir;

    reg [7:0]  acc;
    reg [7:0]  r1;

    reg        z;
    reg        n;
    reg        c;

    wire [3:0] opcode = ir[15:12];
    wire [7:0] imm8   = ir[7:0];
    wire [4:0] addr5  = ir[4:0];

    assign fetch_addr = {3'b000, pc};

    reg  [2:0] alu_op;
    wire [7:0] alu_y;
    wire       alu_c;

    alu8 alu_i (
        .a (acc),
        .b (r1),
        .op(alu_op),
        .y (alu_y),
        .c (alu_c)
    );

    always @(*) begin
        case (opcode)
            OP_ADD: alu_op = 3'b000;
            OP_AND: alu_op = 3'b001;
            OP_OR : alu_op = 3'b010;
            OP_XOR: alu_op = 3'b011;
            OP_SUB: alu_op = 3'b100;
            OP_CMP: alu_op = 3'b100;
            default: alu_op = 3'b111;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fetch_start <= 1'b0;
            state       <= ST_FETCH_REQ;
            pc          <= 5'h00;
            ir          <= 16'h0000;
            acc         <= 8'h00;
            r1          <= 8'h00;
            port_out    <= 8'h00;
            z           <= 1'b0;
            n           <= 1'b0;
            c           <= 1'b0;
        end else begin
            fetch_start <= 1'b0;

            case (state)
                ST_FETCH_REQ: begin
                    if (!fetch_busy) begin
                        fetch_start <= 1'b1;
                        state       <= ST_FETCH_WAIT;
                    end
                end

                ST_FETCH_WAIT: begin
                    if (fetch_done) begin
                        ir    <= fetch_instr;
                        state <= ST_EXECUTE;
                    end
                end

                ST_EXECUTE: begin
                    case (opcode)
                        OP_NOP: begin
                            pc    <= pc + 5'd1;
                            state <= ST_FETCH_REQ;
                        end

                        OP_LDI_ACC: begin
                            acc   <= imm8;
                            z     <= (imm8 == 8'h00);
                            n     <= imm8[7];
                            c     <= 1'b0;
                            pc    <= pc + 5'd1;
                            state <= ST_FETCH_REQ;
                        end

                        OP_LDI_R1: begin
                            r1    <= imm8;
                            pc    <= pc + 5'd1;
                            state <= ST_FETCH_REQ;
                        end

                        OP_ADD,
                        OP_SUB,
                        OP_AND,
                        OP_OR,
                        OP_XOR: begin
                            acc   <= alu_y;
                            z     <= (alu_y == 8'h00);
                            n     <= alu_y[7];
                            c     <= alu_c;
                            pc    <= pc + 5'd1;
                            state <= ST_FETCH_REQ;
                        end

                        OP_CMP: begin
                            z     <= (alu_y == 8'h00);
                            n     <= alu_y[7];
                            c     <= alu_c;
                            pc    <= pc + 5'd1;
                            state <= ST_FETCH_REQ;
                        end

                        OP_OUT: begin
                            port_out <= acc;
                            pc       <= pc + 5'd1;
                            state    <= ST_FETCH_REQ;
                        end

                        OP_JMP: begin
                            pc    <= addr5;
                            state <= ST_FETCH_REQ;
                        end

                        OP_BZ: begin
                            if (z)
                                pc <= addr5;
                            else
                                pc <= pc + 5'd1;
                            state <= ST_FETCH_REQ;
                        end

                        OP_BNZ: begin
                            if (!z)
                                pc <= addr5;
                            else
                                pc <= pc + 5'd1;
                            state <= ST_FETCH_REQ;
                        end

                        OP_HALT: begin
                            state <= ST_HALT;
                        end

                        default: begin
                            pc    <= pc + 5'd1;
                            state <= ST_FETCH_REQ;
                        end
                    endcase
                end

                ST_HALT: begin
                    state <= ST_HALT;
                end

                default: begin
                    state <= ST_FETCH_REQ;
                end
            endcase
        end
    end

endmodule