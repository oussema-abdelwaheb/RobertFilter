# 📸 VHDL Image Processing — Robert Cross Edge Detection

This project implements a **Robert Cross edge detection filter entirely in VHDL**, capable of detecting image contours by processing a stream of pixel intensities. The project includes a modular hardware architecture, simulation testbench, and waveform verification using ModelSim.

---

## 📌 Overview

Edge detection is a fundamental step in many image processing systems. This project focuses on creating a hardware-efficient implementation of the **Robert Cross operator**, designed for FPGA or ASIC integration.

The Robert operator detects edges using the following formulas:

Gx = I(x, y) - I(x+1, y+1)
Gy = I(x+1, y) - I(x, y+1)

The output is the gradient magnitude which is thresholded to generate a binary edge image.

---

## 🚀 Features

- Fully hardware-implemented Robert Cross gradient operator  
- 8-bit grayscale pixel support  
- Fixed-point arithmetic  
- Adjustable threshold  
- Modular architecture  
- Complete ModelSim testbench  
- Synthesizable VHDL design  

---

## 🧪 Simulation

1. Open ModelSim  
2. Compile all source and testbench files  
3. Run the testbench

## 👤 Author  
Developed by **Oussema** as part of a VHDL digital design learning series.
