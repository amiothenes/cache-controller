-------------------------------------------------------------------------------
-- Copyright (c) 2025 Xilinx, Inc.
-- All Rights Reserved
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor     : Xilinx
-- \   \   \/     Version    : 13.4
--  \   \         Application: XILINX CORE Generator
--  /   /         Filename   : VIO.vhd
-- /___/   /\     Timestamp  : Tue Sep 30 16:28:53 EDT 2025
-- \   \  /  \
--  \___\/\___\
--
-- Design Name: VHDL Synthesis Wrapper
-------------------------------------------------------------------------------
-- This wrapper is used to integrate with Project Navigator and PlanAhead

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY VIO IS
  port (
    CONTROL: inout std_logic_vector(35 downto 0);
    ASYNC_OUT: out std_logic_vector(17 downto 0));
END VIO;

ARCHITECTURE VIO_a OF VIO IS
BEGIN

END VIO_a;
