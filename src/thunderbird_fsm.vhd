--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm.vhd
--| AUTHOR(S)     : Jaden Liu
--| CREATED       : 03/2025
--| DESCRIPTION   : This file implements the ECE 281 Lab 2 Thunderbird tail lights
--|					FSM using enumerated types.  This was used to create the
--|					erroneous sim for GR1
--|
--|					Inputs:  i_clk 	 --> 100 MHz clock from FPGA
--|                          i_left  --> left turn signal
--|                          i_right --> right turn signal
--|                          i_reset --> FSM reset
--|
--|					Outputs:  o_lights_L (2:0) --> 3-bit left turn signal lights
--|					          o_lights_R (2:0) --> 3-bit right turn signal lights
--|
--|					Upon reset, the FSM by defaults has all lights off.
--|					Left ON - pattern of increasing lights to left
--|						(OFF, LA, LA/LB, LA/LB/LC, repeat)
--|					Right ON - pattern of increasing lights to right
--|						(OFF, RA, RA/RB, RA/RB/RC, repeat)
--|					L and R ON - hazard lights (OFF, ALL ON, repeat)
--|					A is LSB of lights output and C is MSB.
--|					Once a pattern starts, it finishes back at OFF before it 
--|					can be changed by the inputs
--|					
--|
--|                 One-Hot State Encoding key
--|                 --------------------
--|                  State | Encoding
--|                 --------------------
--|                  OFF   | 10000000
--|                  ON    | 01000000
--|                  R1    | 00100000
--|                  R2    | 00010000
--|                  R3    | 00001000
--|                  L1    | 00000100
--|                  L2    | 00000010
--|                  L3    | 00000001
--|                 --------------------
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : None
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
 
entity thunderbird_fsm is
    port (
        i_clk, i_reset  : in  std_logic;
        i_left, i_right : in  std_logic;
        o_lights_L      : out std_logic_vector(2 downto 0);
        o_lights_R      : out std_logic_vector(2 downto 0)
    );
end thunderbird_fsm;

architecture thunderbird_fsm_arch of thunderbird_fsm is
    --switch over to one hot and define
    constant S_OFF    : std_logic_vector(7 downto 0) := "10000000";  -- OFF
    constant S_HAZARD : std_logic_vector(7 downto 0) := "01000000";  -- HAZARD
    constant S_R1     : std_logic_vector(7 downto 0) := "00100000";  -- R1
    constant S_R2     : std_logic_vector(7 downto 0) := "00010000";  -- R2
    constant S_R3     : std_logic_vector(7 downto 0) := "00001000";  -- R3
    constant S_L1     : std_logic_vector(7 downto 0) := "00000100";  -- L1
    constant S_L2     : std_logic_vector(7 downto 0) := "00000010";  -- L2
    constant S_L3     : std_logic_vector(7 downto 0) := "00000001";  -- L3

    --------------------------------------------------------------------------
    -- State registers
    --------------------------------------------------------------------------
    signal f_Q, f_Q_next : std_logic_vector(7 downto 0) := S_OFF;

begin
    process(i_clk, i_reset)
    begin
        if (i_reset = '1') then
            f_Q <= S_OFF;
        elsif rising_edge(i_clk) then
            f_Q <= f_Q_next;
        end if;
    end process;

    --------------------------------------------------------------------------
    -- NEXT STATE LOGIC
    --------------------------------------------------------------------------
    process(f_Q, i_left, i_right)
    begin
        case f_Q is

            when S_OFF =>
                if (i_left = '1') and (i_right = '1') then
                    f_Q_next <= S_HAZARD;
                elsif (i_left = '1') then
                    f_Q_next <= S_L1;
                elsif (i_right = '1') then
                    f_Q_next <= S_R1;
                else
                    f_Q_next <= S_OFF;
                end if;

            when S_HAZARD =>
                -- switch off next 
                f_Q_next <= S_OFF;

            when S_R1 =>
                f_Q_next <= S_R2;

            when S_R2 =>
                f_Q_next <= S_R3;

            when S_R3 =>
                f_Q_next <= S_OFF;

            when S_L1 =>
                f_Q_next <= S_L2;

            when S_L2 =>
                f_Q_next <= S_L3;

            when S_L3 =>
                f_Q_next <= S_OFF;

            when others =>
                -- default safety net
                f_Q_next <= S_OFF;
        end case;
    end process;

    -- OUTPUT LOGIC
    process(f_Q)
    begin
        case f_Q is

            when S_OFF =>
                o_lights_L <= "000";
                o_lights_R <= "000";

            when S_HAZARD =>
                o_lights_L <= "111";
                o_lights_R <= "111";

            when S_R1 =>
                o_lights_L <= "000";
                o_lights_R <= "100";

            when S_R2 =>
                o_lights_L <= "000";
                o_lights_R <= "110";

            when S_R3 =>
                o_lights_L <= "000";
                o_lights_R <= "111";

            when S_L1 =>
                o_lights_L <= "100";
                o_lights_R <= "000";

            when S_L2 =>
                o_lights_L <= "110";
                o_lights_R <= "000";

            when S_L3 =>
                o_lights_L <= "111";
                o_lights_R <= "000";

            when others =>
                o_lights_L <= (others => '0');
                o_lights_R <= (others => '0');
        end case;
    end process;

end thunderbird_fsm_arch;