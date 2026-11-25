# COE758 Project 1 — Cache Controller (Spartan-3E XC3S500E FG320-5)

Built jointly with my labmate Hachi Ndu, on his machine — that's why the VHDL source headers list his name. Joint COE758 project, not solo work.

Sources: see [Cache_Controller.prj](Cache_Controller.prj)

Files of interest:
- Top-level: [`Cache_Controller` (behavioral)](CACHE_Controller.vhd)
- SDRAM: [`SDRAM_Controller` (behavioral)](SDRAM_Controller.vhd)
- SRAM (IP): [`SRAM` (core wrapper)](ipcore_dir/SRAM.vhd)
- Traffic generator: [`CPU_gen`](CPU.vhd)
- Debug cores: [`ICON`](ipcore_dir/ICON.vhd), [`ILA`](ipcore_dir/ILA.vhd)
- Timing report: [Cache_Controller.twr](Cache_Controller.twr)
- Synthesis report: [Cache_Controller.syr](Cache_Controller.syr)

---

## 1. Abstract

Objective (What)
Design and implement a cache controller that arbitrates CPU read/write transactions to SDRAM, with on-chip SRAM used for tag/data buffering, and on-chip ChipScope cores for validation.

Approach (How)
VHDL implementation targeting Spartan-3E XC3S500E FG320-5. The top-level [`Cache_Controller`](CACHE_Controller.vhd) instantiates [`CPU_gen`](CPU.vhd) for stimulus, [`SRAM`](ipcore_dir/SRAM.vhd) for tags/lines, [`SDRAM_Controller`](SDRAM_Controller.vhd) for external memory, and ChipScope [`ICON`](ipcore_dir/ICON.vhd)/[`ILA`](ipcore_dir/ILA.vhd) for in-system capture.

Results (What Happened)
Synthesis, translate, map, PAR, and bitgen complete with warnings; bitstream [Cache_Controller.bit](Cache_Controller.bit) generated. Synthesis trimmed some equivalent/constant FFs and flagged unconnected sequential nodes (`sdoffset_*`). Post-PAR timing report generated ([.twr](Cache_Controller.twr)). Testbench (`TEST.vhd`) needs fixes (parser errors and unsupported `wait`) to run ISim.

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

- Device: xc3s500e-fg320-5 (see [Cache_Controller.twr](Cache_Controller.twr)).
- Top entity: [`Cache_Controller`](CACHE_Controller.vhd), architecture behavioral.
- Bus widths:
  - Address: 16 bits
  - Data: 8 bits
- I/O handshake:
  - CPU side: CS, WR_RD, RDY, ADDR, DOUT/DIN
  - Memory side: MEMSTRB, WR_RD, SDRAM ADDR/DIN/DOUT
- Debug: ChipScope [`ICON`](ipcore_dir/ICON.vhd), [`ILA`](ipcore_dir/ILA.vhd) (see [Cache_Controller.bld](Cache_Controller.bld)).

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

(Refer to [`Cache_Controller` ports in code](CACHE_Controller.vhd) and Fig. 1.)

---

## 4. Device design (description)

### 4.a. Symbol

Figure 1 — Symbol of [`Cache_Controller`](CACHE_Controller.vhd)
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
Text reference: Symbol signals map 1:1 to the entity ports listed in Table 1 and [`Cache_Controller` entity](CACHE_Controller.vhd).

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
[`CPU_gen`](CPU.vhd) produces traffic; [`SRAM`](ipcore_dir/SRAM.vhd) stores cache tags/lines; [`SDRAM_Controller`](SDRAM_Controller.vhd) performs external transactions; ChipScope cores capture internal buses (see [Cache_Controller.bld ICON/ILA usage](Cache_Controller.bld)).

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
- Tag compare uses `cpu_tag` and `index` (see [`cpu_tag`, `index` signals](CACHE_Controller.vhd)).
- Miss path asserts `SDRAM_MSTRB` and increments `sdoffset` during line fill (see code around SDRAM strobe and offset handling).

### 4.d. State and timing diagrams

Figure 4 — FSM states (observed encodings)
```
IDLE ("0000") -> ACCESS ("0001") -> WAIT_MEM ("0010")
-> READY ("0011") -> SERVE ("0100") -> IDLE
```
Evidence: state exported via `STATES`; state4 encoded as "0100" (see [`state <= "0100"` in Cache_Controller](CACHE_Controller.vhd)).

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
- On a hit, no `MEMSTRB`. On a miss, controller asserts `SDRAM_MSTRB` (see [`SDRAM_MSTRB <= '1'`](CACHE_Controller.vhd)) and increments `sdoffset`. `CPU_RDY` is driven in `state3` (see code around state3 transitions).

All diagrams are conceptual and correspond to the processes and signals implemented in the referenced files.

---

## 5. Results

Synthesis and implementation:
- Synthesis report: [Cache_Controller.syr](Cache_Controller.syr)
  - Equivalent FF trimming (example): `cpu_tag_*` equivalent to `SDRAM_ADD_*` removed (see info at lines 414–419).
  - Unconnected sequential nodes: `sdoffset_5` … `sdoffset_31` (see warnings at lines 427–445). This indicates only lower bits of `sdoffset` participate in logic; upper bits can be pruned or wiring completed.
  - FFs with constant 1 in SDRAM RAM sigs trimmed (see lines 445+).
- Translate/Map/PAR/Bitgen succeeded (see [Cache_Controller.cmd_log](Cache_Controller.cmd_log), [Project1.gise](Project1.gise)).
- Timing report generated: [Cache_Controller.twr](Cache_Controller.twr) and XML [.twx](Cache_Controller.twx).

ChipScope instrumentation:
- `ila_data(15 downto 0) <= CPU_ADD` (see mapping near the end of [`Cache_Controller`](CACHE_Controller.vhd)), enabling capture of address sequences.
- ICON/ILA cores included (see [Cache_Controller.bld INFO:NgdBuild:1317](Cache_Controller.bld)).

Analysis and derived timing:
- Qualitative latency:
  - Hit latency: 1–2 cycles (FSM: ACCESS->SERVE).
  - Miss latency: hit latency + SDRAM service + line fill (`sdoffset` increments).
- Average access time: $t_{avg} = h \cdot t_{hit} + (1-h)\cdot t_{miss}$.
- Recommendation: constrain clock and critical paths, then re-run TRCE to extract $t_{co}$ and setup/hold margins from [.twr](Cache_Controller.twr).

Discussion:
- The ISim testbench [`TEST.vhd`](TEST.vhd) has parser errors and unsupported `wait` statements (see [TEST.syr errors](TEST.syr), [TEST.stx](TEST.stx)). Adjusting the testbench to a pure process-based driver (no `wait for`) would enable behavioral simulation.

---

## 6. Conclusion

A synthesizable cache controller was implemented and integrated with SDRAM and SRAM IP blocks. The design builds and meets implementation flow goals with minor synthesis trimming. Next steps: finalize `sdoffset` usage, complete FSM documentation, add timing constraints, and repair the testbench to enable simulation-based verification.

---

## 7. Appendix (code)

Correspondence between symbol and entity declaration (excerpt):

```vhdl
-- filepath: CACHE_Controller.vhd
-- ...existing code...
entity Cache_Controller is
  Port (
    clk        : in  STD_LOGIC;                         -- System clock
    sD_Addra   : out STD_LOGIC_VECTOR(15 downto 0);     -- SDRAM address (export)
    sD_Dina    : out STD_LOGIC_VECTOR(7 downto 0);      -- SDRAM data in (export)
    sD_Douta   : out STD_LOGIC_VECTOR(7 downto 0);      -- SDRAM data out (export)
    cacheAddr  : out STD_LOGIC_VECTOR(7 downto 0);      -- Upper byte of CPU address
    STATES     : out STD_LOGIC_VECTOR(3 downto 0);      -- FSM state for debug
    WR_RD      : out STD_LOGIC;                         -- Read/Write select
    MEMSTRB    : out STD_LOGIC;                         -- Memory strobe to SDRAM
    RDY        : out STD_LOGIC;                         -- CPU ready
    CS         : out STD_LOGIC                          -- CPU chip select
  );
end Cache_Controller;
-- ...existing code...
architecture Behavioral of Cache_Controller is
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
-- filepath: CACHE_Controller.vhd
-- ...existing code...
elsif (state_current = state3) then
  CPU_RDY <= '1';
  if (CPU_CS = '1') then
    state_current <= state4;
    state <= "0100"; -- exported via STATES for debug (Fig. 4)
  end if;
end if;
-- ...existing code...
MEMSTRB  <= SDRAM_MSTRB;
ADDR     <= CPU_ADD;
WR_RD    <= CPU_W_R;
DOUT     <= CPU_Din;
RDY      <= CPU_RDY;
CS       <= CPU_CS;
STATES   <= state;
sAddra   <= sADD;
sDina    <= sDin;
sDouta   <= sDout;
sD_Addra <= SDRAM_ADD;
sD_Dina  <= SDRAM_Din;
sD_Douta <= SDRAM_Dout;
cacheAddr<= CPU_ADD(15 downto 8);
ila_data(15 downto 0) <= CPU_ADD;
-- ...existing code...
```

Instantiation and dependencies (from project file):
See [Cache_Controller.prj](Cache_Controller.prj) which lists compilation order for [`SRAM`](ipcore_dir/SRAM.vhd), [`SDRAM_Controller`](SDRAM_Controller.vhd), [`ICON`](ipcore_dir/ICON.vhd), [`ILA`](ipcore_dir/ILA.vhd), [`CPU_gen`](CPU.vhd), and top-level [`CACHE_Controller.vhd`](CACHE_Controller.vhd).

Notes from synthesis logs:
- Black-box instantiation warnings for SRAM/ICON/ILA are expected until cores are resolved (see [Cache_Controller.syr HDL Analysis](Cache_Controller.syr)).
- `sdoffset_*` unconnected warnings indicate upper offset bits unused; either reduce width or wire fully.

---

References:
- Xilinx ISE reports: [CACHE_Controller.xreport](iseconfig/CACHE_Controller.xreport), [CACHE.xreport](iseconfig/CACHE.xreport)
- ChipScope IP notes: [ICON_readme.txt](ipcore_dir/ICON_readme.txt), [ILA_readme.txt](ipcore_dir/ILA_readme.txt)
