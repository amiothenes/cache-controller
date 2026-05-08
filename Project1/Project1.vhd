----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:33:14 09/23/2025 
-- Design Name: 
-- Module Name:    CACHE CONTROLLER - Behavioral 
-- Project Name: 
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

entity CACHE CONTROLLER is
    Port ( clk : in  STD_LOGIC;
           cpu_WR/RD_In : in  STD_LOGIC;
           cpu_CS : in  STD_LOGIC;
           cpu_ADDR_In : in  STD_LOGIC_VECTOR (15 downto 0);
           cpu_RDY : out  STD_LOGIC;
           sdram_ADDR : out  STD_LOGIC_VECTOR (15 downto 0);
           sdram_WR/RD : out  STD_LOGIC;
           sdram_WR/RD : out  STD_LOGIC;
           sdram_MEMSTRB : out  STD_LOGIC;
           sram_WEN : out  STD_LOGIC;
           sram_ADDR : out  STD_LOGIC_VECTOR (7 downto 0);
           sram_DIN : out  STD_LOGIC;
           sram_DOUT : out  STD_LOGIC);
end CACHE CONTROLLER;

architecture Behavioral of CACHE CONTROLLER is

begin


end Behavioral;

