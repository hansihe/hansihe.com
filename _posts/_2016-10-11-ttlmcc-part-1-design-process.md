---
layout: post
title:  "CPU Build Part 1: Design process"
date:   2016-10-11 13:47:35 +0200
categories: electronics
series:
    id: ttlcpu
    part: 1
    short_title: Design process
---

{% include series_selector.html %}

I have been working with computers on a software level for most of my life, and I have developed a reasonably complete mental model of how a computer works from assembly and upwards. The part that has always been missing is the actual hardware. I knew how a transistor worked, and how multiple transistors could be assembled into a logic gate. I knew how multiple logic gates could be assembled into a full adder, and how multiple full adders could be combined to add two 8bit numbers. The part I never really grasped was how these components where assembled into a more complete system like a computer, which could actually process data.

Since the way I like to learn new things has always been to challenge myself and jump straight into the deep end, I decided to do the same thing here. I decided to actually build a simple computer out of simple components. The rules and requirements I set for myself where as follows:

* 7400 series logic only. Using any larger integrated circuit which combines multiple components would be cheating.
* Exception to the above rule: Memory. I really didn't feel like doing this manually, for obvious reasons.
* It needs to be able to actually do something. It needs to be able to run something moderately complex/cool to look at. Pong is my primary goal.

## First go at design
Having no clue where to start, I started looking at block diagrams and explainations of how older CPUs worked. I mainly studied the [MOS 6502](https://en.wikipedia.org/wiki/MOS_Technology_6502) which has some nice block diagrams and explainations availible. While there are other homebrew CPUs out there, I deliberately avoided looking at them as this fealt like cheating.

The first piece of software I attempted to use for design was [LogiSim](http://www.cburch.com/logisim/). After finishing the design for a simple ALU, and for parts of the datapath, I realized LogiSim was not the best choice of software for what I was trying to do. There where two reasons for this. LogiSim is a highly GUI and mouse based application, which started to strain my hand after working in it for a while. I also disliked the level of abstraction it was operating in.

The next piece of software I tried was KiCad. I ported what I had so far over, but quickly saw that KiCad was even further from what I wanted in this case. I had to both manually specify every chip I used, and manually draw every data line in every bus.

At this point I had picked up a lot more information, and saw that many of the choices I had made in the design where far from optimal. I threw the design out, and started work on a completely new one. This time I did the design with pen and paper.

## Clean house
Using pen and paper for designing the general architecture worked a lot better then either LogiSim or KiCad. I could freely work at the level of abstraction that I wanted at any time, and being able to sit away from the computer while pondering on the design was a massive advantage. I divided the CPU into modules, and drew each one of them on a separate piece of paper. 

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

Having finished a first revision of the datapath design, I started looking at how I would do control. My original plan was to make the control logic a hardwired circuit, but while working on the design I saw another option. If I where to put all of the combinatorial parts of the control circuit in a lookup table, I could effectively replace much of the control circuitry with a couple of memory chips. This would also make it possible to easily change the instruction set by just writing new data to the memory chips. It turns out this is actually a very common way of doing control in processors, and it is called [microcode](https://en.wikipedia.org/wiki/Microcode).

Before actually ordering the parts, I wanted to be sure the design was actually usable, and that writing software on it was possible. I started off by writing a simple simulator for the architecture with a possible instruction set in python. I also wrote a [simple assembler](https://github.com/hansihe/ttl_cpu/blob/master/toolchain/assemble.py) for it. I also wrote a simple version of [pong](https://github.com/hansihe/ttl_cpu/blob/master/programs/pong.ts), and made changes to the design of the hardware as I saw improvements.

While I knew the imagined instruction set and design were working and could run programs, I was still not completely certain it would actually work in hardware. I had heard of languages like Verilog and VHDL, and knew they where used for defining and validating digital logic, but I had never looked at it before. I went with Verilog, and used [IcarusVerilog](http://iverilog.icarus.com/) as the simulator.

Even after finishing the Verilog model for the design, I was not able to run anything on the hardware because I did not have any microcode written. I wrote a [microcode assembler](https://github.com/hansihe/ttl_cpu/blob/master/toolchain/mcasm.py) implementation, and implemented the instruction set I used for the pong program [in microcode](https://github.com/hansihe/ttl_cpu/blob/master/microcode/microcode.tmcs). Lo and behold, after fixing a couple of errors in the Verilog code, it was successfully able to run pong!

At this point I was reasonably confident in my design, and I placed the order for all of the parts. I ordered the main bulk of the parts from Mouser (see the [order](http://www.mouser.com/ProjectManager/ProjectDetail.aspx?AccessID=d921ff765b)). The rest of the parts, including wire, perfboards, ribbon cables and sockets where ordered from different chinese Ebay sellers.

## Wrapping up
While part one has mostly been me going through the initial design process, and has probably not been all that interesting, the next couple of parts are going to get considerably better. In part two I am going to go through the construction and development of the logic analyzer which I will be using for several things throughout the project.

{% include make_galleries.html %}
