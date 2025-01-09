// Inputs: clk, reset, car_north, car_south, car_east, car_west
// outputs: light_north, light_south, light_east, light_west
// left_north, left_south, left_east, left_west

// Anyone who has spent any amount of time in the wonderful city of Las Vegas has encountered one of these, a 4-way traffic stop. 
// This is the top level module for representing one of these glorious feats of engineering. 
module four_way_traffic_stop(
    input logic clk, reset, car_north, car_south, car_east, car_west,
    input logic car_north_left, car_south_left, car_east_left, car_west_left,
    output logic [1:0] light_north, light_south, light_east, light_west,
    output logic [1:0] left_north, left_south, left_east, left_west
);
    // The time from the moment it turns green to the moment it will turn green again is 11 cycles
    parameter integer FULL_TIME = 11;

    // counter to hold the time
    integer counter;
    // 00 is Green, 01 is yellow, 10 is red, 11 is flashing yellow
    logic N_start_cmd, E_start_cmd, S_start_cmd, W_start_cmd;
    logic NL_start_cmd, EL_start_cmd, SL_start_cmd, WL_start_cmd;
    logic NL_flash, EL_flash, SL_flash, WL_flash;
    // We initialize traffic lights, using X_start_cmd to start them
    traffic_light T_NORTH(clk, reset, N_start_cmd, light_north);
    traffic_light T_EAST(clk, reset, E_start_cmd,  light_east);
    traffic_light T_SOUTH(clk, reset, S_start_cmd, light_south);
    traffic_light T_WEST(clk, reset, W_start_cmd, light_west);
    // The left traffic lights have the additional flash input, telling them to start flashing yellow
    left_traffic_light L_NORTH(clk, reset, NL_start_cmd, NL_flash, left_north);
    left_traffic_light L_EAST(clk, reset, NL_start_cmd, EL_flash, left_south);
    left_traffic_light L_SOUTH(clk, reset, NL_start_cmd, SL_flash, left_east);
    left_traffic_light L_WEST(clk, reset, NL_start_cmd, WL_flash, left_west);
    // How many states are there? 
    // BOTH_GREEN means that both sides of the road has through-traffic and both opposite lefts are flashing yellow
    // DOUBLE_GREEN means that you can go forward and left
    // DOUBLE_LEFT means both opposite lefts are green
    typedef enum logic [2:0]{
        NS_BOTH_GREEN = 3'b000,
        N_DOUBLE_GREEN = 3'b001,
        S_DOUBLE_GREEN = 3'b010,
        EW_BOTH_GREEN = 3'b011,
        E_DOUBLE_GREEN = 3'b100,
        W_DOUBLE_GREEN = 3'b101,
        NS_DOUBLE_LEFT = 3'b110,
        EW_DOUBLE_LEFT = 3'b111
    } state_t;

    state_t current_state, next_state; 

    

    always_ff @(posedge clk or posedge reset) begin 
        if (reset) begin
            current_state <= NS_BOTH_GREEN;
        end else begin
            current_state <= next_state;
            
        end
    end

    // This block of combinational logic controls the next state equations
    always_comb begin
        next_state = current_state;
        
        case(current_state)
            NS_BOTH_GREEN: begin
                if(counter == 0) begin
                    if(car_north_left && car_south_left) begin
                        next_state = NS_DOUBLE_LEFT;
                    end else if ((car_north_left && !car_south_left) && car_north) begin
                        next_state = N_DOUBLE_GREEN;
                    end else if (car_south_left && car_south) begin
                        next_state = S_DOUBLE_GREEN;
                    end else begin
                        next_state = EW_BOTH_GREEN;
                    end
                end
            end

            NS_DOUBLE_LEFT: begin
                if(counter == 0) begin
                    next_state = EW_BOTH_GREEN;
                end
            end

            N_DOUBLE_GREEN: begin
                if(counter == 0) begin
                    next_state = EW_BOTH_GREEN;
                end
            end

            S_DOUBLE_GREEN: begin
                if(counter == 0) begin
                    next_state = EW_BOTH_GREEN;
                end
            end


            EW_BOTH_GREEN: begin
                if(counter == 0) begin
                    if(car_east_left && car_west_left) begin
                        next_state = EW_DOUBLE_LEFT;
                    end else if ((car_east_left && !car_west_left) && car_east) begin
                        next_state = E_DOUBLE_GREEN;
                    end else if (car_west_left && car_west) begin
                        next_state = W_DOUBLE_GREEN;
                    end else begin
                        next_state = NS_BOTH_GREEN;
                    end
                end
            end

            EW_DOUBLE_LEFT: begin
                if(counter == 0) begin
                    next_state = NS_BOTH_GREEN;
                end
            end

            E_DOUBLE_GREEN: begin
                if(counter == 0) begin
                    next_state = NS_BOTH_GREEN;
                end
            end

            W_DOUBLE_GREEN: begin
                if(counter == 0) begin
                    next_state = NS_BOTH_GREEN;
                end
            end
        endcase

    end


    // Control signal logic
    always_comb begin
    // By default, set everything to 0
    N_start_cmd  = 1'b0;
    E_start_cmd  = 1'b0;
    S_start_cmd  = 1'b0;
    W_start_cmd  = 1'b0;
    NL_start_cmd = 1'b0;
    EL_start_cmd = 1'b0;
    SL_start_cmd = 1'b0;
    WL_start_cmd = 1'b0;

    NL_flash = 1'b0;
    EL_flash = 1'b0;
    SL_flash = 1'b0;
    WL_flash = 1'b0;

    case (current_state)

        // Both directions are green for N/S, lefts are flashing yellow
        NS_BOTH_GREEN: begin
            N_start_cmd  = 1'b1; 
            S_start_cmd  = 1'b1; 
            NL_flash     = 1'b1; 
            SL_flash     = 1'b1; 
        end

        // North has forward and left green
        N_DOUBLE_GREEN: begin
            N_start_cmd  = 1'b1;
            NL_start_cmd = 1'b1;
        end

        // South has forward and left green
        S_DOUBLE_GREEN: begin
            S_start_cmd  = 1'b1;
            SL_start_cmd = 1'b1;
        end

        // Both directions are green for E/W, lefts are flashing yellow
        EW_BOTH_GREEN: begin
            E_start_cmd  = 1'b1;
            W_start_cmd  = 1'b1;
            EL_flash     = 1'b1; 
            WL_flash     = 1'b1; 
        end

        // East has forward and left green
        E_DOUBLE_GREEN: begin
            E_start_cmd  = 1'b1;
            EL_start_cmd = 1'b1;
        end

        // West has forward and left green
        W_DOUBLE_GREEN: begin
            W_start_cmd  = 1'b1;
            WL_start_cmd = 1'b1;
        end

        // Both north/south left lights are green
        NS_DOUBLE_LEFT: begin
            NL_start_cmd = 1'b1;
            SL_start_cmd = 1'b1;
        end

        // Both east/west left lights are green
        EW_DOUBLE_LEFT: begin
            EL_start_cmd = 1'b1;
            WL_start_cmd = 1'b1;
        end

        // Default case is will reset the whole system
        default: begin
            N_start_cmd  = 1'b0;
            E_start_cmd  = 1'b0;
            S_start_cmd  = 1'b0;
            W_start_cmd  = 1'b0;
            NL_start_cmd = 1'b0;
            EL_start_cmd = 1'b0;
            SL_start_cmd = 1'b0;
            WL_start_cmd = 1'b0;

            NL_flash = 1'b0;
            EL_flash = 1'b0;
            SL_flash = 1'b0;
            WL_flash = 1'b0;
        end
    endcase
end

    // The following code "reloads" the counter, essentially reseting its value each time we change states
    always_ff @(posedge clk) begin
        if (reset) begin
            counter <= FULL_TIME;
        end
        else begin
            if (current_state != next_state) begin
                counter <= FULL_TIME;
            end
            // decrement the counter so long as it is above 0
            if (counter > 0)
                counter <= counter -1;
        end
    end




endmodule

    

