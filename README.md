# set-associative-cache-controller

## 📌 Overview

This project implements a 2-way set associative cache controller in Verilog with 8 sets and 128-bit cache lines (4×32-bit words). The design supports read/write operations, LRU-based replacement, and a write-back policy with dirty-bit management.

A 4-state FSM (IDLE, LOOKUP, WRITEBACK, ALLOCATE) handles cache hits, misses, eviction, and memory allocation. The controller interfaces with a block-based memory system and ensures single-cycle hit latency with multi-cycle miss handling.

The design is fully verified using a custom testbench and memory model, covering scenarios like cache hits, compulsory misses, conflict misses, and write-back operations.

## Cache Architecture
- **Associativity**: 2-way set associative
- **Number of Sets**: 8
- **Total Cache Lines**: 16
- **Block Size**: 128 bits (4 × 32-bit words)
- **Address Width**: 32-bit
- **Replacement Policy**: LRU (1-bit per set)
- **Write Policy**: Write-back

## Features
- Parameterized design (scalable sets, block size, data width)
- Single-cycle cache hit latency
- Multi-cycle miss handling (WRITEBACK + ALLOCATE)
- LRU-based replacement policy
- Dirty bit optimization for reduced memory writes
- Block-based memory interface (128-bit transfers)
- Word-level access within cache blocks

## FSM Design

The controller is implemented using a 4-state Finite State Machine (FSM):

| State	| Description |
|-------|-------------|
| IDLE|	Waits for CPU request |
| LOOKUP|	Checks for hit/miss |
| WRITEBACK|	Writes dirty block to memory |
| ALLOCATE|	Fetches new block from memory |

## Working Principle
- CPU sends read/write request
- Cache performs tag comparison
- If Cache Hit:
     - Data is returned in 1 clock cycle
- If Cache Miss:
     - If dirty → WRITEBACK
     - Fetch new block → ALLOCATE
- Retry access → The operation is completed.

## Verification
Developed a custom testbench with memory model.
Tested scenarios:
- Cache hits (read/write)
- Compulsory misses
- Conflict misses
- LRU-based eviction
- Write-back operations

## 🛠 Tools Used
- Verilog HDL
- Simulation: Xilinx Vivado
- Waveform analysis for debugging

## Output Waveform

<img width="1337" height="630" alt="Image" src="https://github.com/user-attachments/assets/4e34c837-1672-4544-9b29-12f2a00c3552" />

## Console Output

<img width="629" height="159" alt="Image" src="https://github.com/user-attachments/assets/9682107d-12fa-43cb-b1f7-025b6062b106" />
