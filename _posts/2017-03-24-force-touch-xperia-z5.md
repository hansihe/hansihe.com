---
layout: post
title:  "Force touch on Xperia Z5 using Air pressure sensor"
date:   2017-03-24 10:10:58 +0200
---

Newer Apple devices have a feature called Force touch. It allows the device to accurately measure the pressure that is applied to the screen by the user. This is done by a dedicated sensor located on the back of the screen.

The Xperia Z5 by Sony does not have such a sensor, and thus can not directly measure the pressure which is applied to the screen surface. However, the phone is waterproof. This has the side-effect of making the air pressure within the phone increase momentarily when there is pressure applied to the screen. As it turns out, this can be used to determine the amount of absolute pressure on the screen relatively accurately.

<div style='position:relative;padding-bottom:89%'><iframe src='https://gfycat.com/ifr/FlashyJoyfulKiskadee' frameborder='0' scrolling='no' width='100%' height='100%' style='position:absolute;top:0;left:0;' allowfullscreen></iframe></div>

The graph above shows various stages of the filters that gets applied to the data.

* Blue - Raw sensor data, before all filtering. This is fairly noisy.
* Red - Sensor data after a kalman filter. The data is much smoother, but with some latency.
* Green - Atmospheric baseline.
* Purple - Air leakage compensation factor. You can't really see it move here.
* Turquoise - The final calculated pressure. This is the output of the filter.

<div style='position:relative;padding-bottom:89%'><iframe src='https://gfycat.com/ifr/AridViciousGossamerwingedbutterfly' frameborder='0' scrolling='no' width='100%' height='100%' style='position:absolute;top:0;left:0;' allowfullscreen></iframe></div>

Notice that when pressure is applied for some amount of time, the air inside will start leaking out. This is compensated for with an air leakage compensation factor which is calculated by looking at the pressure difference between ambient and current.

## Algorithm

I mostly made things up as I went along, and I have no experience within digital signal processing. If anyone has any suggestions on what I can do to improve the filters, please let me know!

The first layer of filtering applied to the input data is a Kalman filter. This is done to help smooth any large spikes or noise in the input data. It does introduce some latency, which can probably be mostly eliminated by tweaking some of the parameters in the filter.

To find the atmospheric baseline is a bit tricky. Asking the user to manually calibrate this would be an option, but I tried to avoid doing that. I ended up keeping a history of the last 30 samples, and summing the deltas between those. I then run the summed deltas through a sigmoid function to get a "confidence factor" between 0 and 1. This "confidence factor" represents how sure the algorithm is that the current sensor data is resting at the atmospheric baseline. This "confidence factor" is then used to offset the green line.

To find the actual pressure value, the delta between the current and last value is added every tick. To correct for air leakage, a leakage factor is added. This leakage factor is calculated by looking at the difference between the atmospheric baseline and the current sensor value.

Lastly, screen touch events are used to reset the pressure every time the user starts or stops pressing the screen.
