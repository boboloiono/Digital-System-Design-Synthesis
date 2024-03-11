# ECE 551　—　Digital System Design and Synthesis
Introduction to the use of hardware description languages and automated synthesis in design. Advanced design principles. Verilog and systemVerilog description languages.
Synthesis from hardware description languages. Timing-oriented synthesis. Relation of integrated circuit layout to timing-oriented design. Design for reuse.
# Lecture
### content
• Verilog coding styles (structural, dataflow, and behavioral)
• Datapath implementation using dataflow
• Sequential circuits, and how to properly infer flops in verilog.
• Proper coding for synthesis. Coding counters, coding state machines, blocking vs
non-blocking statements,
• Building basic testbenches.
• Simulator mechanics…understanding what goes on “under the hood” of Verilog
simulator.
• Synthesis constraints
• Synthesis commands and writing a synthesis script
• Synthesis optimizations
• Interpreting synthesis timing reports
• Advanced test bench constructs and self-checking test benches
• Understanding synthesis flow and optimizations built into the tool
• Coding for synthesis optimizations
• Intro to gated clocks
• Parasitic capacitance, SDF files and back annotation
• Digital circuit implementations. Std Cell vs FPGA vs Full Custom
• Introduction to Universal Verification Methodology

### Video (Lecture 1-12 & APR tutorial & Modelsim)
https://youtube.com/playlist?list=PLotMpqAftQlt1BPiCmefIb0-GQ22ZS9t9&si=fyK9s-B26IO1dRd0

### Software (CAD Tools)
o ModelSim (Verilog simulation)
o Synopsys Design Compiler (Verilog synthesis to TSMC std cell library)
o Quartus (FPGA synthesis to Altera)
o IC Compiler (Simple APR of netlist)

# Final Project: Maze Runner
### Toplevel Digital of our Design:
![image](https://github.com/boboloiono/UW-Madison-ECE-551/assets/62455939/9e2fec37-49ec-409f-a1b1-34e574900591)
The blocks outlined in red are pure digital blocks, and will be coded with the intent of being synthesized via **Synopsys** to our standard cell library.
### Demo Video
https://youtube.com/shorts/6qb4DCTUtKc?si=v2lmSNh50QzI3fUD

# Learning Outcomes
• “Think Hardware First” then code it to a Hardware Description Language
• Design and Code a digital circuit in a HDL (Verilog) using both dataflow and
behavioral coding styles.
o Partition a functional block (control vs datapath)
o Code verilog for both proper behavior and synthesis
• Properly verify correct functionality of digital implementation
o Evaluate testing requirements for a complex digital system
o Build self-checking test benches
• Simulate their HDL implementation
o Simulate DUT and test bench using ModelSim
o Simulate a post synthesis netlist
• Synthesis of dataflow and behavioral designs
o Understand how to constrain a digital circuit
o Optimize hardware designs (timing, area, power) through synthesis
o Read/understand static timing analysis reports
o Map verilog circuit descriptions to an FPGA implementation
• Partition and complete the implementation of a complex digital circuit
o Work on a team to partition, code, simulate, and synthesize a complex
digital design project.
