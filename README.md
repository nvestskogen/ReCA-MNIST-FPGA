# ReCA-MNIST-FPGA

Reservoir Computing with Cellular Automata (ReCA) for MNIST digit classification, implemented in SystemVerilog and targeting the Ultra96-V2 FPGA.

## Overview

This project implements an online-learning image classifier using a ReCA with a perceptron layer . A binary MNIST image is fed through a Cellular Automata (CA) reservoir, downsampled with MaxPooling, and classified by a fully connected layer that updates its weights after every prediction.


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

## Parameters

| Parameter | Default | Description |
|---|---|---|
| `N` | 28 | Image width (pixels) |
| `M` | 28 | Image height (pixels) |
| `RECA`| 1 | CA enabled|
| `ITERS` | 8 | CA generations per image |
| `NUM_CLASSES` | 10 | Output classes (0-9) |
| `WIDTH_W` | 6 | Weight bit width |
| `WIDTH_B` | 7 | Bias bit width |

## Repository Folders

| Folder | Description |
|---|---|
| `SystemVerilog/` | RTL source files |
| `bit_hwh/` | Bitstream and hardware handoff files for programming the Ultra96-V2 |
| `notebooks/` | Jupyter notebooks for training, evaluation, and real-time inference |

## Target Device

Xilinx Ultra96-V2

## License

MIT
