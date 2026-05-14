# ReCA-MNIST-FPGA

Reservoir Computing with Cellular Automata (ReCA) for MNIST digit classification, implemented in SystemVerilog and targeting the Ultra96-V2 FPGA.

## Overview

This project implements an online-learning image classifier without a CPU. A binary MNIST image is fed through a Cellular Automata (CA) reservoir, downsampled with MaxPooling, and classified by a fully connected layer that updates its weights after every prediction.

## Architecture
