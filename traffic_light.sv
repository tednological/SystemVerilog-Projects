module traffic_light(
    input logic clk, reset, start,
    output logic [1:0] light_color
);
    // Define the number of clk cycles for each light
    parameter integer GREEN_TIME = 5;
    parameter integer YELLOW_TIME =2;
    parameter integer RED_TIME = 4;

    // counter to hold the time spent in a given state
    integer counter;

    // The light can be in one of three states, green/yellow/red
    typedef enum logic [1:0]{
        S_GREEN = 2'b00,
        S_YELLOW = 2'b01,
        S_RED = 2'b10
    } state_t;

    state_t current_state, next_state; 

    

    // The next-state logic for the light
    always_comb begin 
        next_state = current_state;

        case(current_state)
            S_GREEN: begin 
                if(counter == 0) begin
                    next_state = S_YELLOW;
                end
            end
            S_YELLOW: begin
                if (counter == 0) begin
                    next_state = S_RED;
                end
            end
            S_RED: begin 
                if (counter == 0) begin
                    next_state = S_GREEN;
                end
            end

            default: next_state = S_GREEN;
        endcase
    end

    // The following code "reloads" the counter, essentially reseting its value each time we change states
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= RED_TIME;
            current_state <= S_RED;
        end
        else begin
            if (current_state != next_state) begin
                case (next_state) 
                    S_GREEN: counter <= GREEN_TIME;
                    S_YELLOW: counter <= YELLOW_TIME;
                    S_RED: counter <= RED_TIME;
                    default: counter <= GREEN_TIME;
                endcase
            end
            if (start) begin
            current_state <= next_state;

            if (counter > 0)
                counter <= counter - 1;
            end
        end
    end

    // This is the output logic, assigning the logic high if and only if it is the current state.
    assign light_color = current_state;
endmodule
