# ReCA-MNIST-FPGA
Reservoir Computing with Cellular Automata (ReCA) for MNIST digit classification, implemented in SystemVerilog and targeting the Ultra96-V2 FPGA.

## Background

This project is part of a bachelor thesis with the following objective:

> *"[...] develop an autonomous robot capable of navigating an area > 1.5m×1.5m. In the constrained area, objects with Modified National Institute of Standards and Technology (MNIST) numbers printed on them will be present. The robot should be able to explore and locate these objects. When the robot has successfully located an object, the robot should be able to focus, read and classify the MNIST number present on the object utilizing an FPGA."*

This repository contains the FPGA implementation of the MNIST classifier. A key design goal is minimizing inference energy consumption. The energy consumed during inference is defined as:

$$
\begin{aligned}
E &= (P_{\text{static}} + P_{\text{dyn}}) \cdot t \\
&= (VI_{\text{leak}} + \alpha CV^2 f) \cdot t
\end{aligned}
$$

where $P_{\text{dyn}} \propto f$. Minimizing FPGA resource usage (FFs, LUTs, BRAMs)
and the clock frequency reduces $P_{\text{dyn}}$, and therefore $E_{\text{dyn}}$, while minimizing inference time $t$ reduces the static
leakage energy $E_{\text{static}}$,

## Overview
This project implements an image classifier using a ReCA with a perceptron layer. A binary MNIST image is fed through a Cellular Automata (CA) reservoir, downsampled with MaxPooling, and classified by a fully connected layer that updates its weights after every prediction. The PYNQ framework was used in Jupyter Notebook to train and evaluate the model.

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

The design is fully parameterized to allow for exploration of accuracy/resource/energy trade-off.

| Parameter | Default | Description |
|---|---|---|
| `N` | 28 | Image width (pixels) |
| `M` | 28 | Image height (pixels) |
| `RECA` | 1 | CA reservoir enabled (1) or bypass (0) |
| `ITERS` | 8 | CA generations |
| `NUM_CLASSES` | 10 | Output classes |
| `WIDTH_W` | 6 | Weight bit width |
| `WIDTH_B` | 7 | Bias bit width |


## Inference Results

A 100 MHz clock was used as the baseline for inference energy analysis. At this frequency, 73% of the total inference power is static power, making clock frequency and board selection the primary levers for energy reduction.

When the clock is scaled by a factor $A$ relative to the 100 MHz baseline, the inference energy can be estimated as:

$$
\begin{aligned}
E_{\text{inference}} &= (0.221\text{ W} + A \cdot 0.080\text{ W}) \cdot \frac{78.71\,\mu\text{s}}{A} \\
                     &\approx \underbrace{\frac{17.4\,\mu\text{J}}{A}}_{E_{\text{static}}} + \underbrace{6.3\,\mu\text{J}}_{E_{\text{dynamic}}}
\end{aligned}
$$

As clock frequency increases, static energy falls while dynamic energy remains constant, giving a theoretical minimum of:

$$
\lim_{f \to \infty} E_{\text{inference}} = 6.3\,\mu\text{J}
$$

The maximum achievable clock frequency without timing violations, for our design, is $f_{\text{max}} \approx 139$ MHz on the Ultra96-V2, giving estimated $E_{\text{inference}} \approx 18.81\,\mu\text{J}$ with $A = 1.39$.

### Power and Timing Results

Metrics are derived from post-implementation power and timing simulations. Energy savings are relative to the 100 MHz Ultra96-V2 baseline. \*Denotes board $f_{\text{max}}$.

| Board | Clock (MHz) | $P_{\text{static}}$ (W) | $P_{\text{dyn}}$ (W) | Inference Speed (μs) | Inference Energy (μJ) | Energy Savings (%) |
|---|---|---|---|---|---|---|
| Ultra96-V2 | 100 | 0.221 | 0.080 | 78.71 | 23.69 | — |
| Ultra96-V2 | 139\* | 0.221 | 0.108 | 56.45 | 18.00 | 24.0 |
| ZUBoard 1CG | 100 | 0.162 | 0.041 | 78.71 | 15.98 | 32.5 |
| ZUBoard 1CG | 142\* | 0.162 | 0.122 | 55.19 | 15.67 | 33.9 |

The ZUBoard 1CG achieves the lowest inference energy (15.67 μJ at $f_{\text{max}}$), giving us a potential reduction of **33.9% energy** over the baseline, primarily due to its lower static power.

## Repository Folders
| Folder | Description |
|---|---|
| `SystemVerilog/` | RTL source files |
| `bit_hwh/` | Bitstream and hardware handoff files for programming the Ultra96-V2 |
| `notebooks/` | Jupyter notebooks for training, evaluation, and real-time inference |


## License
MIT

