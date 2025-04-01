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
--| FILENAME      : thunderbird_fsm_tb.vhd (TEST BENCH)
--| AUTHOR(S)     : Jaden Liu
--| CREATED       : 03/2025
--| DESCRIPTION   : This file tests the thunderbird_fsm modules.
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : thunderbird_fsm_enumerated.vhd, thunderbird_fsm_binary.vhd, 
--|				   or thunderbird_fsm_onehot.vhd
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
  
entity thunderbird_fsm_tb is
end thunderbird_fsm_tb;

architecture test_bench of thunderbird_fsm_tb is

    component thunderbird_fsm is
        port(
            i_clk, i_reset  : in  std_logic;
            i_left, i_right : in  std_logic;
            o_lights_L      : out std_logic_vector(2 downto 0);
            o_lights_R      : out std_logic_vector(2 downto 0)
        );
    end component;

    signal w_clk       : std_logic := '0';
    signal w_reset     : std_logic := '0';
    signal w_left      : std_logic := '0';
    signal w_right     : std_logic := '0';
    signal w_lights_L  : std_logic_vector(2 downto 0);
    signal w_lights_R  : std_logic_vector(2 downto 0);

    -- 100 MHz => 10 ns period
    constant k_clk_period : time := 10 ns;

begin

    uut: thunderbird_fsm
        port map(
            i_clk      => w_clk,
            i_reset    => w_reset,
            i_left     => w_left,
            i_right    => w_right,
            o_lights_L => w_lights_L,
            o_lights_R => w_lights_R
        );

    clk_proc : process
    begin
        w_clk <= '0';
        wait for k_clk_period/2;
        w_clk <= '1';
        wait for k_clk_period/2;
    end process clk_proc;

    sim_proc : process
    begin
        report "Apply reset" severity note;
        w_reset <= '1';
        wait for k_clk_period;  -- 1 clock
        wait for k_clk_period;  -- 2 clocks
        w_reset <= '0';

        --timing
        wait for k_clk_period;
        assert (w_lights_L = "000" and w_lights_R = "000")
            report "ERROR: Not OFF after reset"
            severity failure;

        report "LEFT turn signal test" severity note;
        w_left <= '1';

        --L1
        wait for k_clk_period;
        assert (w_lights_L = "100")
            report "ERROR: left not L1 => '100'"
            severity failure;

        --L2
        wait for k_clk_period;
        assert (w_lights_L = "110")
            report "ERROR: left not L2 => '110'"
            severity failure;

        --L3
        wait for k_clk_period;
        assert (w_lights_L = "111")
            report "ERROR: left not L3 => '111'"
            severity failure;

        --off
        wait for k_clk_period;
        assert (w_lights_L = "000")
            report "ERROR: left not returning off"
            severity failure;

        w_left <= '0';  
        wait for k_clk_period;

        report "right turn test" severity note;
        w_right <= '1';

        -- R1
        wait for k_clk_period;
        assert (w_lights_R = "100")
            report "ERROR: right not R1"
            severity failure;

        -- R2
        wait for k_clk_period;
        assert (w_lights_R = "110")
            report "ERROR: right not R2"
            severity failure;

        -- R3
        wait for k_clk_period;
        assert (w_lights_R = "111")
            report "ERROR: right not R3"
            severity failure;

        -- revert to off
        wait for k_clk_period;
        assert (w_lights_R = "000")
            report "ERROR: right not returning to off"
            severity failure;

        w_right <= '0';
        wait for k_clk_period;
        
        report "hazard test" severity note;
        w_left  <= '1';
        w_right <= '1';

        -- all on
        wait for k_clk_period;
        assert (w_lights_L = "111" and w_lights_R = "111")
            report "ERROR: hazard lights not on"
            severity failure;

        -- off
        wait for k_clk_period;
        assert (w_lights_L = "000" and w_lights_R = "000")
            report "ERROR: hazard not returning to off"
            severity failure;

        w_left  <= '0';
        w_right <= '0';

        ------------------------------------------------------------------------
        report "tests passed" severity note;
        wait;
    end process sim_proc;

end test_bench;
