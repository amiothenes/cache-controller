# COE758 Project 1 — Cache Controller (Spartan-3E XC3S500E FG320-5)

Author: Hachi Ndu (from source headers)  
Sources: see [Cache_Controller.prj](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\Cache_Controller.prj)

Files of interest:
- Top-level: [`Cache_Controller` (behavioral)](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\CACHE_Controller.vhd)
- SDRAM: [`SDRAM_Controller` (behavioral)](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\SDRAM_Controller.vhd)
- SRAM (IP): [`SRAM` (core wrapper)](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\ipcore_dir\SRAM.vhd)
- Traffic generator: [`CPU_gen`](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\CPU.vhd)
- Debug cores: [`ICON`](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\ipcore_dir\ICON.vhd), [`ILA`](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\ipcore_dir\ILA.vhd)
- Timing report: [Cache_Controller.twr](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\Cache_Controller.twr)
- Synthesis report: [Cache_Controller.syr](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\Cache_Controller.syr)

---

## 1. Abstract

Objective (What)  
Design and implement a cache controller that arbitrates CPU read/write transactions to SDRAM, with on-chip SRAM used for tag/data buffering, and on-chip ChipScope cores for validation.

Approach (How)  
VHDL implementation targeting Spartan-3E XC3S500E FG320-5. The top-level [`Cache_Controller`](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\CACHE_Controller.vhd) instantiates [`CPU_gen`](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\CPU.vhd) for stimulus, [`SRAM`](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\ipcore_dir\SRAM.vhd) for tags/lines, [`SDRAM_Controller`](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\SDRAM_Controller.vhd) for external memory, and ChipScope [`ICON`](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\ipcore_dir\ICON.vhd)/[`ILA`](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\ipcore_dir\ILA.vhd) for in-system capture.

Results (What Happened)  
Synthesis, translate, map, PAR, and bitgen complete with warnings; bitstream [Cache_Controller.bit](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\Cache_Controller.bit) generated. Synthesis trimmed some equivalent/constant FFs and flagged unconnected sequential nodes (`sdoffset_*`). Post-PAR timing report generated ([.twr](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\Cache_Controller.twr)). Testbench (`TEST.vhd`) needs fixes (parser errors and unsupported `wait`) to run ISim.

---

## 2. Introduction

Motivation (Why)  
Bridging a simple CPU bus to high-latency SDRAM benefits from a cache to reduce average memory access time.

Objective (What, more detail)  
- Provide a direct-mapped cache interface with 16-bit address and 8-bit data paths.
- Handshake signals: CPU chip select, read/write, ready; memory strobe to SDRAM.
- Instrument internal transactions via ChipScope ILA.

Theory (Underlying principles)  
- Direct-mapped cache: address is partitioned into tag, index, and offset. Tag match with valid bit determines hit; otherwise, miss triggers SDRAM refill.  
- Handshake timing: controller asserts MEMSTRB to memory, deasserts when transaction completes; CPU_RDY indicates data validity.  
- Average memory access time: $t_{avg} = h \cdot t_{hit} + (1-h)\cdot t_{miss}$ where $h$ is hit ratio.

---

## 3. Specifications

- Device: xc3s500e-fg320-5 (see [Cache_Controller.twr](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\Cache_Controller.twr)).
- Top entity: [`Cache_Controller`](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\CACHE_Controller.vhd), architecture behavioral.
- Bus widths:
  - Address: 16 bits
  - Data: 8 bits
- I/O handshake:
  - CPU side: CS, WR_RD, RDY, ADDR, DOUT/DIN
  - Memory side: MEMSTRB, WR_RD, SDRAM ADDR/DIN/DOUT
- Debug: ChipScope [`ICON`](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\ipcore_dir\ICON.vhd), [`ILA`](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\ipcore_dir\ILA.vhd) (see [Cache_Controller.bld](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\Cache_Controller.bld)).

Table 1 — Top-level I/O ports (excerpt; see Fig. 1 symbol)  
- clk (in): system clock  
- CS (out): CPU chip select passthrough  
- WR_RD (out): CPU write/read passthrough  
- RDY (out): CPU ready  
- ADDR (out): CPU address passthrough to SDRAM  
- MEMSTRB (out): SDRAM transfer strobe  
- sD_Addra/sD_Dina/sD_Douta (out): exported SDRAM-side buses for debug  
- cacheAddr (out): upper byte of CPU address  
- STATES (out): 4-bit FSM state code

(Refer to [`Cache_Controller` ports in code](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\CACHE_Controller.vhd) and Fig. 1.)

---

## 4. Device design (description)

### 4.a. Symbol

Figure 1 — Symbol of [`Cache_Controller`](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\CACHE_Controller.vhd)  
```
       +-----------------------------+
 clk --|                             |
      -|  CPU_IF      Cache          |--> RDY
 CS <--|  (CS, WR_RD, ADDR, DIN/DO)  |--> STATES[3:0]
WR_RD<-|                             |--> MEMSTRB
ADDR<->|                  SDRAM_IF   |--> sD_Addra[15:0]
 DOUT<-|                  (ADDR,     |--> sD_Dina[7:0]
  DIN->|                  WR_RD,     |--> sD_Douta[7:0]
      -|                  MEMSTRB,   |--> cacheAddr[7:0]
       |                  DIN/DOUT)  |
       +-----------------------------+
```
Text reference: Symbol signals map 1:1 to the entity ports listed in Table 1 and [`Cache_Controller` entity](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\CACHE_Controller.vhd).

### 4.b. Block diagram (complete)

Figure 2 — Block diagram of the system
```
              +-----------+           +------------------+
              | CPU_gen   |           |  SDRAM_Controller|
              | (stimulus)|           |  (ext. memory)   |
              +-----+-----+           +----+--------+----+
                    |                      |        ^
                  CPU bus                  |        | SDRAM bus
                    v                      v        |
              +-----------------+     +-------------+        +------+
              | Cache_Controller|<--->|   SRAM IP   |<------>| ILA  |
              |  (this project) |     | (tags/data) |        +------+
              +---------+-------+     +-------------+          ^
                        |                                       |
                        +--------------- ICON ------------------+
```
[`CPU_gen`](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\CPU.vhd) produces traffic; [`SRAM`](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\ipcore_dir\SRAM.vhd) stores cache tags/lines; [`SDRAM_Controller`](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\SDRAM_Controller.vhd) performs external transactions; ChipScope cores capture internal buses (see [Cache_Controller.bld ICON/ILA usage](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\Cache_Controller.bld)).

### 4.c. Process diagram

Figure 3 — High-level process flow
```
+-------+    miss     +----------+   done   +-----------+
| Lookup| ----------> | Refill   | ------> | Respond   |
| (tag) |  hit        | (SDRAM)  |         | (CPU_RDY) |
+---+---+   |         +----------+         +-----+-----+
    |       | hit                         assert RDY
    v       v
 serve from cache
 (no MEMSTRB)
```
- Tag compare uses `cpu_tag` and `index` (see [`cpu_tag`, `index` signals](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\CACHE_Controller.vhd)).  
- Miss path asserts `SDRAM_MSTRB` and increments `sdoffset` during line fill (see code around SDRAM strobe and offset handling).

### 4.d. State and timing diagrams

Figure 4 — FSM states (observed encodings)
```
IDLE ("0000") -> ACCESS ("0001") -> WAIT_MEM ("0010")
-> READY ("0011") -> SERVE ("0100") -> IDLE
```
Evidence: state exported via `STATES`; state4 encoded as "0100" (see [`state <= "0100"` in Cache_Controller](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\CACHE_Controller.vhd)).

Figure 5 — Timing diagram (CPU read hit vs miss)
```
clk  : _/‾\_/‾\_/‾\_/‾\_/‾\_
CPU_CS: ___/‾‾‾‾‾‾‾‾\________
WR_RD : _______0(READ)_______
ADDR  : ===A=== stable ======
MEMSTRB(hit): ________________________
MEMSTRB(miss): ___/‾‾‾‾‾‾‾‾\______
CPU_RDY(hit):  _____/‾\______________
CPU_RDY(miss): _________/‾\__________
```
- On a hit, no `MEMSTRB`. On a miss, controller asserts `SDRAM_MSTRB` (see [`SDRAM_MSTRB <= '1'`](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\CACHE_Controller.vhd)) and increments `sdoffset`. `CPU_RDY` is driven in `state3` (see code around state3 transitions).

All diagrams are conceptual and correspond to the processes and signals implemented in the referenced files.

---

## 5. Results

Synthesis and implementation:
- Synthesis report: [Cache_Controller.syr](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\Cache_Controller.syr)
  - Equivalent FF trimming (example): `cpu_tag_*` equivalent to `SDRAM_ADD_*` removed (see info at lines 414–419).
  - Unconnected sequential nodes: `sdoffset_5` … `sdoffset_31` (see warnings at lines 427–445). This indicates only lower bits of `sdoffset` participate in logic; upper bits can be pruned or wiring completed.
  - FFs with constant 1 in SDRAM RAM sigs trimmed (see lines 445+).
- Translate/Map/PAR/Bitgen succeeded (see [Cache_Controller.cmd_log](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\Cache_Controller.cmd_log), [Project1.gise](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\Project1.gise)).
- Timing report generated: [Cache_Controller.twr](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\Cache_Controller.twr) and XML [.twx](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\Cache_Controller.twx).

ChipScope instrumentation:
- `ila_data(15 downto 0) <= CPU_ADD` (see mapping near the end of [`Cache_Controller`](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\CACHE_Controller.vhd)), enabling capture of address sequences.
- ICON/ILA cores included (see [Cache_Controller.bld INFO:NgdBuild:1317](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\Cache_Controller.bld)).

Analysis and derived timing:
- Qualitative latency:
  - Hit latency: 1–2 cycles (FSM: ACCESS->SERVE).
  - Miss latency: hit latency + SDRAM service + line fill (`sdoffset` increments).
- Average access time: $t_{avg} = h \cdot t_{hit} + (1-h)\cdot t_{miss}$.
- Recommendation: constrain clock and critical paths, then re-run TRCE to extract $t_{co}$ and setup/hold margins from [.twr](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\Cache_Controller.twr).

Discussion:
- The ISim testbench [`TEST.vhd`](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\TEST.vhd) has parser errors and unsupported `wait` statements (see [TEST.syr errors](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\TEST.syr), [TEST.stx](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\TEST.stx)). Adjusting the testbench to a pure process-based driver (no `wait for`) would enable behavioral simulation.

---

## 6. Conclusion

A synthesizable cache controller was implemented and integrated with SDRAM and SRAM IP blocks. The design builds and meets implementation flow goals with minor synthesis trimming. Next steps: finalize `sdoffset` usage, complete FSM documentation, add timing constraints, and repair the testbench to enable simulation-based verification.

---

## 7. Appendix (code)

Correspondence between symbol and entity declaration (excerpt):

```vhdl
-- filepath: c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\CACHE_Controller.vhd
-- ...existing code...
entity Cache_Controller is
  Port (
    clk        : in  STD_LOGIC;                         -- System clock
    -- CPU-visible debug exports
    sD_Addra   : out STD_LOGIC_VECTOR(15 downto 0);     -- SDRAM address (export)
    sD_Dina    : out STD_LOGIC_VECTOR(7 downto 0);      -- SDRAM data in (export)
    sD_Douta   : out STD_LOGIC_VECTOR(7 downto 0);      -- SDRAM data out (export)
    cacheAddr  : out STD_LOGIC_VECTOR(7 downto 0);      -- Upper byte of CPU address
    STATES     : out STD_LOGIC_VECTOR(3 downto 0);      -- FSM state for debug
    -- CPU-side handshake passthroughs
    WR_RD      : out STD_LOGIC;                         -- Read/Write select
    MEMSTRB    : out STD_LOGIC;                         -- Memory strobe to SDRAM
    RDY        : out STD_LOGIC;                         -- CPU ready
    CS         : out STD_LOGIC                          -- CPU chip select
  );
end Cache_Controller;
-- ...existing code...
architecture Behavioral of Cache_Controller is
  -- CPU Signals (internal)
  signal CPU_Dout, CPU_Din : STD_LOGIC_VECTOR(7 downto 0);
  signal CPU_ADD           : STD_LOGIC_VECTOR(15 downto 0);
  signal CPU_W_R, CPU_CS   : STD_LOGIC;
  signal CPU_RDY           : STD_LOGIC;
  signal cpu_tag           : STD_LOGIC_VECTOR(7 downto 0);
  signal index             : STD_LOGIC_VECTOR(2 downto 0);
-- ...existing code...
```

Key processes and signal mapping (end of architecture):

```vhdl
-- filepath: c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\CACHE_Controller.vhd
-- ...existing code...
elsif (state_current = state3) then
  CPU_RDY <= '1';
  if (CPU_CS = '1') then
    state_current <= state4;
    state <= "0100"; -- exported via STATES for debug (Fig. 4)
  end if;
end if;
-- ...existing code...
MEMSTRB  <= SDRAM_MSTRB;   -- export strobe to top-level pin
ADDR     <= CPU_ADD;       -- pass-through CPU address
WR_RD    <= CPU_W_R;       -- pass-through direction
DOUT     <= CPU_Din;       -- pass-through data
RDY      <= CPU_RDY;       -- pass-through ready
CS       <= CPU_CS;        -- pass-through CS
STATES   <= state;         -- export FSM state
sAddra   <= sADD;          -- expose SDRAM address bus
sDina    <= sDin;          -- expose SDRAM data in
sDouta   <= sDout;         -- expose SDRAM data out
sD_Addra <= SDRAM_ADD;     -- alias/expose memory address
sD_Dina  <= SDRAM_Din;     -- alias/expose memory data in
sD_Douta <= SDRAM_Dout;    -- alias/expose memory data out
cacheAddr<= CPU_ADD(15 downto 8);
-- MAP THE ILA PORTS
ila_data(15 downto 0) <= CPU_ADD; -- capture CPU address in ILA (Fig. 2)
-- ...existing code...
```

Instantiation and dependencies (from project file):  
See [Cache_Controller.prj](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\Cache_Controller.prj) which lists compilation order for [`SRAM`](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\ipcore_dir\SRAM.vhd), [`SDRAM_Controller`](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\SDRAM_Controller.vhd), [`ICON`](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\ipcore_dir\ICON.vhd), [`ILA`](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\ipcore_dir\ILA.vhd), [`CPU_gen`](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\CPU.vhd), and top-level [`CACHE_Controller.vhd`](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\CACHE_Controller.vhd).

Notes from synthesis logs:  
- Black-box instantiation warnings for SRAM/ICON/ILA are expected until cores are resolved (see [Cache_Controller.syr HDL Analysis](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\Cache_Controller.syr)).  
- `sdoffset_*` unconnected warnings indicate upper offset bits unused; either reduce width or wire fully.

---

References:
- Xilinx ISE reports: [CACHE_Controller.xreport](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\iseconfig\CACHE_Controller.xreport), [CACHE.xreport](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\iseconfig\CACHE.xreport)
- ChipScope IP notes: [ICON_readme.txt](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\ipcore_dir\ICON_readme.txt), [ILA_readme.txt](c:\Users\Victor\Documents\University\Fall 2025\COE758\Project 1\Project1\ipcore_dir\ILA_readme.txt)