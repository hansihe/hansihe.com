---
layout: post
title:  "CPU Build Part 2: Logic analyzer"
date:   2016-10-13 00:16:50 +0200
categories: electronics
series:
    id: ttlcpu
    part: 2
    short_title: Logic analyzer
---

To make my life easier while working on this project, having a way to instrument and test different parts of the system as I build them is an absolute necessity. Unfortunately I do not own any fancy logic analyzers or other expensive test equipment, and I am not willing to spend the money to buy it just for this one project.

While there are cheap logic analyzers available on the market, they are designed to solve different problems than the ones I have. Products like Saleae's Logic series have a maximum of 16 digital inputs. When looking at multiple buses at once, this is frankly not enough. As I understand it, the limiting factor in most cheap logic analyzers is the bandwidth to the host computer. Because I am able to control the clock rate of the logic I am instrumenting, I don't need a logic analyzer that is capable of sampling millions of times a second. I only need to be able to sample fast enough that I don't get annoyed by waiting too long.

When building my tool for this, I also get to implement some features you would not normally see in a logic analyzer, namely being able to drive pins. This would enable me to both write complete test-suites for the individual hardware components, and I could utilize the same hardware for programming the EEPROM chips I am using for persistent memory.

## Parts
Along with my main order of logic chips, I also ordered a [STMicroelectronics Nucleo-F767ZI](http://www.st.com/content/st_com/en/products/evaluation-tools/product-evaluation-tools/mcu-eval-tools/stm32-mcu-eval-tools/stm32-mcu-nucleo/nucleo-f767zi.html). It is a very capable board, and has more than enough power for what I am using it for. The processor is a STM32F767ZI, a ARM Cortex M7 which is capable of running at a speed of over 200Mhz. The board itself also boasts a built-in JTAG programmer, loads of I/O available in easy-to-connect headers, USB OTG and an Ethernet port.

However, there is one problem. The CPU I am building is operating at 5V, while the ARM processor on the Nucleo board is operating at 3V3. The ARM processor does have 5V tolerant pins, which would enable me to sample them, but if I did that, I would not be able to drive the pins from software. To solve this problem I decided to try using logic level converters. To try to save some money, I ordered some cheap ones from a chinese EBay seller as a first try.

## Building it
I don't really think I realized how much work constructing the whole CPU was going to take before I got started 
