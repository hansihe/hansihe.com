---
layout: post
title: "I built a computer from scratch"
date: 2016-11-25 05:35:15 +0200
---

###### Video

Ever since I started programming, I have been interested in how the stack works all the way down to the bottom. Although I don’t know the specifics on a lot of things, I like to think I have developed a reasonably complete understanding of how a modern computer works all the way down to the assembly level. The levels below that have always been more or less shrouded in a thick fog of mystery for me. A couple of months ago I decided to do something about that, and what better way to learn something new then to jump straight into the deep end. I decided to design and build my own computer from scratch.

## Design

Having never really worked with or designed digital logic before, I had no clue where I would start or what I was getting into. I decided to start by looking at and trying to understand how early microprocessors like the MOS 6502 worked. After trying a couple of different options, I settled on using plain old pen and paper for drawing the diagrams for the design. This has the advantage of being able to work at the exact level of abstraction I want to work at when pondering the design, something which I found vastly outweighed the disadvantage of not being able to directly simulate the design once finished. To make sure there where no fatal flaws in my design, I wrote both a python simulator for the architecture, as well as a Verilog model for it.

{% gallery cpu-plans %}
ttlcpu-plans/alu.jpg::ALU diagram
ttlcpu-plans/alu-modes.jpg::ALU control modes
ttlcpu-plans/datapath.jpg::Main datapath diagram
ttlcpu-plans/icu.jpg::Instruction control diagram
ttlcpu-plans/pc.jpg::Program counter diagram
ttlcpu-plans/ramaddr.jpg::Ram addressing diagram
ttlcpu-plans/ioexp.jpg::IO expansion diagram
ttlcpu-plans/display.jpg::Display module diagram
{% endgallery %}

## Parts

When deciding what parts to use for the computer, I decided to limit myself to using only 7400 series logic (with the exception of memory). When I decided I was mostly happy with the design itself I ordered the parts from Mouser. I made sure to order plenty of spares of everything so that I could change and improve the design as I went along.

<img src="/assets/galleries/ttlcpu/pile_of_parts.jpg" alt="Box of electronics parts"/>

## Building

I considered using wire-wrap for connecting the different components together, but after looking at the price of wire-wrap sockets, I decided I could not afford it and decided to go with regular soldering instead. As you can probably imagine this turned out to be incredibly tedious. Soldering one wire took between two and five minutes, something which really adds up when you are soldering hundreds of wires.

The computer itself ended up being split into three different PCBs that (more or less) handle different parts of the computer; the ALU board, the datapath board and the control board.

* What the ALU does is fairly self-explanatory, it does arithmetic and logic. My design is capable of adding, subtracting, bitwise AND, OR and XOR. The ALU board contains only combinatorial logic, it’s outputs depend solely on the input signals. Because of this, I built this board first.

<img src="/assets/galleries/ttlcpu/alu_board_annotated.jpg" alt="Annotated picture of ALU"/>

* The second board I built was the datapath board. The datapath contains mostly stateful logic, including the RAM memory, registers, and I/O logic.

###### Annotated picture of datapath

* The third board is probably the most interesting one, the control board. Although the ALU and datapath contains most of the logic that deals with data being processed, there needs to be something that asserts the correct control signals at the correct time to orchestrate the actual data processing. This is what the control board does. Although an old computer would probably use a combination of combinatorial logic and a state machine, this would significantly complicate and increase the amount of control logic needed. I decided to cheat a bit and use modern EEPROM memory (the same type of chips I use to actually store the programs) to implement a form of microcode. This enables me to completely alter the instruction set of the processor simply by flashing a new microcode program.

###### Annotated picture of control

## Testing

I knew I needed a way to automatically test different functions of the different boards as I went along. For this purpose I ordered a STM32 Nucleo board along with the other parts. After building a simple logic-level converter board, and writing some firmware, this enabled me to write test suites in python for validating the actual physical boards. This helped me a lot while building both the ALU and the datapath. I also implemented a EEPROM programmer for programming the memory chips.

###### Picture of stm32 debugger with e2prom programmer

## Making it work

As you can imagine, everything did not, in fact, work the first time I plugged it in. Besides the usual couple of forgotten and misplaced wires, there where a couple of problems that where harder to hunt down. It turns out the cheapo chinesium-grade IC sockets I used for this project where not as reliable as I hoped they would be, and some of the IC pins where making bad contact. Bending the pins of the ICs so that they push into the socket sides makes this problem better, but it is still a source of the occasional issue. Because wires are soldered directly to the bottom of the wires, replacing sockets is not an option. I am open to ideas on how to fix this.

## Conclusion

Overall the design and build process was a really good learning experience for me. Where I before had no clue how complex digital logic worked, and how a computer was built on the hardware level, I now feel that I have gained a decent understanding of these things.

This has been a quick overview of the build process. This post does not dive into details, and doesn’t even touch on the software I have written for it, the instruction set, or the actual architecture of the processor. If anyone is interested in seeing articles on those things as well, please tell me.

{% include make_galleries.html %}
