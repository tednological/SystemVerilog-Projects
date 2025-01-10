module four_way_traffic_stop(
    input  logic        clk,
    input  logic        reset,
    input  logic        car_north,
    input  logic        car_south,
    input  logic        car_east,
    input  logic        car_west,
    input  logic        car_north_left,
    input  logic        car_south_left,
    input  logic        car_east_left,
    input  logic        car_west_left,
    output logic [1:0]  light_north,
    output logic [1:0]  light_south,
    output logic [1:0]  light_east,
    output logic [1:0]  light_west,
    output logic [1:0]  left_north,
    output logic [1:0]  left_south,
    output logic [1:0]  left_east,
    output logic [1:0]  left_west
);

  // These parameters determine how long you will be in a given state
  parameter integer T_ALL_RED       = 4;
  parameter integer T_NS_BOTH_GREEN = 10;
  parameter integer T_N_DOUBLE_GREEN= 5;
  parameter integer T_S_DOUBLE_GREEN= 5;
  parameter integer T_EW_BOTH_GREEN = 10;
  parameter integer T_E_DOUBLE_GREEN= 5;
  parameter integer T_W_DOUBLE_GREEN= 5;
  parameter integer T_NS_DOUBLE_LEFT= 5;
  parameter integer T_EW_DOUBLE_LEFT= 5;

  // We can define the states in a single enumerated type
  typedef enum logic [3:0] {
    ALL_RED         = 4'b1000,
    NS_BOTH_GREEN   = 4'b0000,
    N_DOUBLE_GREEN  = 4'b0001,
    S_DOUBLE_GREEN  = 4'b0010,
    EW_BOTH_GREEN   = 4'b0011,
    E_DOUBLE_GREEN  = 4'b0100,
    W_DOUBLE_GREEN  = 4'b0101,
    NS_DOUBLE_LEFT  = 4'b0110,
    EW_DOUBLE_LEFT  = 4'b0111
  } state_t;

  state_t current_state, next_state;
  
  // master_timer keeps track of how long we've been in the current state
  integer master_timer;

  // update current state and master_timer each clock
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      current_state  <= ALL_RED;
    end
    else begin
      current_state <= next_state;

      
    end
  end

   // next-state logic and reloading the master_timer
   always_comb begin
    next_state = current_state; 

    // If our timer has expired, time to move on
    if (master_timer == 0) begin
      case (current_state)

        ALL_RED: begin
          // Move into NS_BOTH_GREEN after ALL_RED
          next_state = NS_BOTH_GREEN;
        end

        NS_BOTH_GREEN: begin
          
          if (car_north_left && car_south_left)
            next_state = NS_DOUBLE_LEFT;
          else if (car_north_left && car_north)
            next_state = N_DOUBLE_GREEN;
          else if (car_south_left && car_south)
            next_state = S_DOUBLE_GREEN;
          else
            next_state = EW_BOTH_GREEN;
        end

        N_DOUBLE_GREEN:   next_state = EW_BOTH_GREEN;
        S_DOUBLE_GREEN:   next_state = EW_BOTH_GREEN;

        EW_BOTH_GREEN: begin
          if (car_east_left && car_west_left)
            next_state = EW_DOUBLE_LEFT;
          else if (car_east_left && car_east)
            next_state = E_DOUBLE_GREEN;
          else if (car_west_left && car_west)
            next_state = W_DOUBLE_GREEN;
          else
            next_state = NS_BOTH_GREEN;
        end

        E_DOUBLE_GREEN:   next_state = NS_BOTH_GREEN;
        W_DOUBLE_GREEN:   next_state = NS_BOTH_GREEN;
        NS_DOUBLE_LEFT:   next_state = EW_BOTH_GREEN;
        EW_DOUBLE_LEFT:   next_state = NS_BOTH_GREEN;

        default:          next_state = ALL_RED;
      endcase
    end
  end

  // reload the master_timer each time we change states
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      master_timer <= T_ALL_RED;
    end
    else if (current_state != next_state) begin
      case (next_state)
        ALL_RED:         master_timer <= T_ALL_RED;
        NS_BOTH_GREEN:   master_timer <= T_NS_BOTH_GREEN;
        N_DOUBLE_GREEN:  master_timer <= T_N_DOUBLE_GREEN;
        S_DOUBLE_GREEN:  master_timer <= T_S_DOUBLE_GREEN;
        EW_BOTH_GREEN:   master_timer <= T_EW_BOTH_GREEN;
        E_DOUBLE_GREEN:  master_timer <= T_E_DOUBLE_GREEN;
        W_DOUBLE_GREEN:  master_timer <= T_W_DOUBLE_GREEN;
        NS_DOUBLE_LEFT:  master_timer <= T_NS_DOUBLE_LEFT;
        EW_DOUBLE_LEFT:  master_timer <= T_EW_DOUBLE_LEFT;
        default:         master_timer <= T_ALL_RED;
      endcase
      // Decrement master_timer if it's still positive
    end
    if (!reset) begin
        if (master_timer > 0)
        master_timer <= master_timer - 1;
      else
        master_timer <= master_timer;
    end
  end

  
  // the output logic drives lights based on the current state
  
  always_comb begin
    // Default all lights to red 
    light_north = 2'b10;
    light_south = 2'b10;
    light_east  = 2'b10;
    light_west  = 2'b10;
    left_north  = 2'b10;
    left_south  = 2'b10;
    left_east   = 2'b10;
    left_west   = 2'b10;

    case (current_state)

      ALL_RED: begin
        // Everything is red already 
      end

      NS_BOTH_GREEN: begin
        // north south go green, their left lights get flashing yellow
        light_north = 2'b00; 
        light_south = 2'b00;
        left_north  = 2'b11; 
        left_south  = 2'b11;
      end

      N_DOUBLE_GREEN: begin
        light_north = 2'b00; 
        left_north  = 2'b00; 
        
      end

      S_DOUBLE_GREEN: begin
        light_south = 2'b00;
        left_south  = 2'b00;
      end

      EW_BOTH_GREEN: begin
        light_east  = 2'b00; 
        light_west  = 2'b00;
        left_east   = 2'b11; 
        left_west   = 2'b11;
      end

      E_DOUBLE_GREEN: begin
        light_east = 2'b00; 
        left_east  = 2'b00; 
      end

      W_DOUBLE_GREEN: begin
        light_west = 2'b00; 
        left_west  = 2'b00;
      end

      NS_DOUBLE_LEFT: begin
        left_north  = 2'b00;
        left_south  = 2'b00;
      end

      EW_DOUBLE_LEFT: begin
        left_east  = 2'b00;
        left_west  = 2'b00;
      end

      default: begin
        // already set to red
      end
    endcase
  end

endmodule
