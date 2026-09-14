// ATM core control unit — Moore-style Finite State Machine
// States: IDLE -> DEPOSIT_ST / WITHDRAW_ST -> UPDATE -> IDLE
//         (ERROR_ST reached if the requested operation would violate a limit)

module ATM (
    input clk,
    input rst,
    input deposit,
    input withdraw,
    input [7:0] amount,
    output reg [15:0] balance,
    output reg [2:0] leds       // [0]=deposit ok, [1]=withdraw ok, [2]=error/warning
);

    parameter MAX_BALANCE = 16'd500;

    // State encoding
    localparam IDLE       = 3'b000,
               DEPOSIT_ST  = 3'b001,
               WITHDRAW_ST = 3'b010,
               UPDATE      = 3'b011,
               ERROR_ST    = 3'b100;

    reg [2:0] state, next_state;

    // State register (sequential)
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Next-state logic (combinational)
    always @(*) begin
        case (state)
            IDLE: begin
                if (deposit)
                    next_state = DEPOSIT_ST;
                else if (withdraw)
                    next_state = WITHDRAW_ST;
                else
                    next_state = IDLE;
            end

            DEPOSIT_ST: begin
                if (balance + amount > MAX_BALANCE)
                    next_state = ERROR_ST;
                else
                    next_state = UPDATE;
            end

            WITHDRAW_ST: begin
                if (balance < amount)
                    next_state = ERROR_ST;
                else
                    next_state = UPDATE;
            end

            UPDATE:   next_state = IDLE;
            ERROR_ST: next_state = IDLE;

            default:  next_state = IDLE;
        endcase
    end

    // Registered output / datapath logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            balance <= 16'd0;
            leds    <= 3'b000;
        end else begin
            case (state)
                DEPOSIT_ST: begin
                    if (balance + amount <= MAX_BALANCE) begin
                        balance <= balance + amount;
                        leds    <= 3'b001;   // deposit accepted
                    end
                end

                WITHDRAW_ST: begin
                    if (balance >= amount) begin
                        balance <= balance - amount;
                        leds    <= 3'b010;   // withdraw accepted
                    end
                end

                ERROR_ST: begin
                    leds <= 3'b100;          // limit violated / insufficient funds
                end

                UPDATE, IDLE: begin
                    leds <= 3'b000;          // clear indicators once handled
                end
            endcase
        end
    end

endmodule
