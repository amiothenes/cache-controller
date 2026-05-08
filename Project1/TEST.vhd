----------------------------------------------------------------------------------
-- Company: 		TMU
-- Engineer: 		HACHI NDU
-- 
-- Create Date:    17:01:55 09/23/2025 
-- Design Name: 
-- Module Name:    TEST - Behavioral 
-- Project Name: 	XC3S500E
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TEST is
end TEST;

architecture behavior of TEST is

    -- Component Declaration for the Unit Under Test (UUT)
    COMPONENT Cache_Controller
    PORT(
         clk : IN  std_logic;
         ADDR : OUT  std_logic_vector(15 downto 0);
         DOUT : OUT  std_logic_vector(7 downto 0);
         sAddra : OUT  std_logic_vector(7 downto 0);
         sDina : OUT  std_logic_vector(7 downto 0);
         sDouta : OUT  std_logic_vector(7 downto 0);
         sD_Addra : OUT  std_logic_vector(15 downto 0);
         sD_Dina : OUT  std_logic_vector(7 downto 0);
         sD_Douta : OUT  std_logic_vector(7 downto 0);
         cacheAddr : OUT  std_logic_vector(7 downto 0);
			STATES 	: out  STD_LOGIC_VECTOR(3 downto 0);
         WR_RD : OUT  std_logic;
         MEMSTRB : OUT  std_logic;
         RDY : OUT  std_logic;
         CS : OUT  std_logic
        );
    END COMPONENT;
   
   --Inputs
   signal clk : std_logic := '0';

   --Outputs
   signal ADDR : std_logic_vector(15 downto 0);
   signal DOUT : std_logic_vector(7 downto 0);
   signal sAddra : std_logic_vector(7 downto 0);
   signal sDina : std_logic_vector(7 downto 0);
   signal sDouta : std_logic_vector(7 downto 0);
   signal sD_Addra : std_logic_vector(15 downto 0);
   signal sD_Dina : std_logic_vector(7 downto 0);
   signal sD_Douta : std_logic_vector(7 downto 0);
   signal cacheAddr : std_logic_vector(7 downto 0);
	signal STATES 	: STD_LOGIC_VECTOR(3 downto 0);
   signal WR_RD : std_logic;
   signal MEMSTRB : std_logic;
   signal RDY : std_logic;
   signal CS : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
    -- Instantiate the Unit Under Test (UUT)
   uut: Cache_Controller PORT MAP (
          clk => clk,
          ADDR => ADDR,
          DOUT => DOUT,
          sAddra => sAddra,
          sDina => sDina,
          sDouta => sDouta,
          sD_Addra => sD_Addra,
          sD_Dina => sD_Dina,
          sD_Douta => sD_Douta,
          cacheAddr => cacheAddr,
			 STATES => STATES,
          WR_RD => WR_RD,
          MEMSTRB => MEMSTRB,
          RDY => RDY,
          CS => CS
        );

   -- Clock process definitions
   clk_process :process
   begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
   end process;
 
   -- Stimulus process
   stim_proc: process
   begin
      -- Hold reset state for 100 ns.
      wait for 100 ns;

      wait for clk_period*10;

      -- Insert stimulus here
      report "CacheController simulation started" severity note;
     
      -- Monitor cache operations
      wait for 1000 ns;
     
      -- Check if cache controller is responsive
      if RDY = '1' then
          report "Cache controller ready for transactions" severity note;
      end if;

      wait;
   end process;

END;