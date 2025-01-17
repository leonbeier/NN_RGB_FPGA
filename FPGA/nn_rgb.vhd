-- nn_rgb.vhd
--
-- top level
-- manual entry of NN parameters
--
-- FPGA Vision Remote Lab http://h-brs.de/fpga-vision-lab
-- (c) Thomas Florkowski, Hochschule Bonn-Rhein-Sieg, 21.04.2020
--     Release: Marco Winzker, Hochschule Bonn-Rhein-Sieg, 17.09.2020

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity nn_rgb is
    port (clk       : in  std_logic;                      -- input clock 74.25 MHz, video 720p
        reset_n   : in  std_logic;                      -- reset (invoked during configuration)
        enable_in : in  std_logic_vector(2 downto 0);   -- three slide switches
        -- video in
        vs_in     : in  std_logic;                      -- vertical sync
        hs_in     : in  std_logic;                      -- horizontal sync
        de_in     : in  std_logic;                      -- data enable is '1' for valid pixel
        r_in      : in  std_logic_vector(7 downto 0);   -- red component of pixel
        g_in      : in  std_logic_vector(7 downto 0);   -- green component of pixel
        b_in      : in  std_logic_vector(7 downto 0);   -- blue component of pixel
        -- video out
        vs_out    : out std_logic;                      -- corresponding to video-in
        hs_out    : out std_logic;
        de_out    : out std_logic;
        r_out     : out std_logic_vector(7 downto 0);
        g_out     : out std_logic_vector(7 downto 0);
        b_out     : out std_logic_vector(7 downto 0);
        --
        clk_o     : out std_logic;                      -- output clock (do not modify)
        led       : out std_logic_vector(2 downto 0));  -- not supported by remote lab
end nn_rgb;

architecture behave of nn_rgb is

    -- input FFs
    signal reset                   : std_logic;
    signal enable                  : std_logic_vector(2 downto 0);
    signal vs_0, hs_0, de_0        : std_logic;
    signal r_0, g_0, b_0           : integer;
    
    -- internal Signals between neurons
    signal h_0, h_1, h_2, output_1, output_2   : integer range 0 to 255;
    -- output of signal processing
    signal vs_1, hs_1, de_1        : std_logic;
    signal result_1, result_2      : std_logic_vector(7 downto 0);


begin

    hidden0: entity work.neuron
    generic map ( w1 => 226,
        w2 => -662,
        w3 => -354,
        bias => 9449)
    port map (   clk    => clk,
        x1     => r_0,
        x2     => g_0,
        x3     => b_0,
        output => h_0);

    hidden1: entity work.neuron
    generic map ( w1 => -508,
        w2 => 682,
        w3 => 139,
        bias => -4197)
    port map (   clk    => clk,
        x1     => r_0,
        x2     => g_0,
        x3     => b_0,
        output => h_1);
    
    hidden2: entity work.neuron
    generic map ( w1 => 230,
        w2 => -327,
        w3 => 368,
        bias => -51596)
    port map (   clk    => clk,
        x1     => r_0,
        x2     => g_0,
        x3     => b_0,
        output => h_2);
    
    output0: entity work.neuron
    generic map ( w1 => -243,
        w2 => -231,
        w3 => -220,
        bias => 29152)
    port map (   clk    => clk,
        x1     => h_0,
        x2     => h_1,
        x3     => h_2,
        output => output_1);
    
--    output1: entity work.neuron
--    generic map ( w1 => -247,
--        w2 => 127,
--        w3 => -135,
--        bias => 2274)
--    port map (   clk    => clk,
--        x1     => h_0,
--        x2     => h_1,
--        x3     => h_2,
--        output => output_2);
    
    control: entity work.control
    generic map (delay => 9)
    port map (  clk      => clk,
        reset    => reset,
        vs_in    => vs_0,
        hs_in    => hs_0,
        de_in    => de_0,
        vs_out   => vs_1,
        hs_out   => hs_1,
        de_out   => de_1);
    

    
    process
    begin
        wait until rising_edge(clk);
        
    -- input FFs for control
        reset <= not reset_n;
        enable <= enable_in;
    -- input FFs for video signal
        vs_0  <= vs_in;
        hs_0  <= hs_in;
        de_0  <= de_in;
        r_0   <= to_integer(unsigned(r_in));
        g_0   <= to_integer(unsigned(g_in));
        b_0   <= to_integer(unsigned(b_in));

        
    end process;
    
    process
    begin
        wait until rising_edge(clk);
        
        if(output_1 > 127) then
        result_1 <= (others => '1');
    else
        result_1 <= (others => '0');
    end if;
    
    if(output_2 > 127) then
    result_2 <= (others => '1');
else
    result_2 <= (others => '0');
end if;

        -- output FFs
vs_out  <= vs_1;
hs_out  <= hs_1;
de_out  <= de_1;
r_out   <= result_1;
g_out   <= result_2;
b_out   <= x"00";

end process;

clk_o <= clk;
led   <= "000";

end behave;
