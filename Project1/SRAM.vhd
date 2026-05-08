----------------------------------------------------------------------------------
-- Company: 		TMU
-- Engineer: 		HACHI NDU
-- 
-- Create Date:    15:35:41 09/30/2025 
-- Design Name: 
-- Module Name:    SRAM - Behavioral 
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SRAM is
    Port ( clk : in  STD_LOGIC;
           ADDR : in  STD_LOGIC_VECTOR (15 downto 0);
           WEN : in  STD_LOGIC;
           DIN : in  STD_LOGIC_VECTOR (7 downto 0);
           DOUT : in  STD_LOGIC_VECTOR (7 downto 0));
end SRAM;

architecture Behavioral of SRAM is

type SRAM_memory_block is array (0 to 255) of std_logic_vector(7 downto 0);
--the cache has 8 row of 32 words. each word is 1 byte or 8 bits

signal sram_memory: SRAM_memory_block(others => (others => (others => '0'))); --0s

begin


end Behavioral;

