# ReCA-MNIST-FPGA

Reservoir Computing with Cellular Automata (ReCA) for MNIST digit classification, implemented in SystemVerilog and targeting the Ultra96-V2 FPGA.

## Overview

This project implements an online-learning image classifier without a CPU. A binary MNIST image is fed through a Cellular Automata (CA) reservoir, downsampled with MaxPooling, and classified by a fully connected layer that updates its weights after every prediction.


## Modules


## Module Hierarchy

```
NeuromorphicAccelerator
├── ReservoirLayer
│   ├── ReservoirControl
│   ├── CellularAutomata
│   │   └── ReservoirColumn
│   │       └── ReservoirNeuron
│   ├── Maxpool
│   │   └── MaxpoolCell
│   └── Flatten
└── PerceptronLayer
    ├── PerceptronControl
    ├── OutputNeuron
    ├── WinnerTakesAll
    ├── Weights
    ├── Biases
    └── ParameterUpdate
```


| Module | Description |
|---|---|
| `Cellular_Automata` | ECA Rule 90 reservoir, MxN grid |
| `MaxPool` | 2x2 maxpool with stride 2 |
| `Flatten` | Shift register flattening of MaxPool output |
| `Logit` | Computes class score: Σ Wᵢxᵢ + b |
| `Argmax_sequential` | Finds the highest scoring class |
| `Update_parameters` | Online weight and bias update |
| `Weights_BRAM` | Block RAM storing weights (0-63) |
| `Bias_BRAM` | Block RAM storing biases (0-64) |
| `ReCA_CU` | FSM controlling the CA pipeline |
| `FC_CU` | FSM controlling the FC pipeline |

## Parameters

| Parameter | Default | Description |
|---|---|---|
| `N` | 28 | Image width (pixels) |
| `M` | 28 | Image height (pixels) |
| `ITERS` | 8 | CA generations per image |
| `NUM_CLASSES` | 10 | Output classes (0-9) |
| `WIDTH_W` | 6 | Weight bit width |
| `WIDTH_B` | 7 | Bias bit width |

## Repository Structure

| Folder | Description |
|---|---|
| `SystemVerilog/` | RTL source files |
| `bit_hwh/` | Bitstream and hardware handoff files for programming the Ultra96-V2 |
| `notebooks/` | Jupyter notebooks for training, evaluation, and real-time inference |

## Target Device

Xilinx Ultra96-V2

## License

MIT
