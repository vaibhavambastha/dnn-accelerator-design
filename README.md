# Deep Neural Network Accelerator Design



---

## Project Overview

Created an accelerator core that computes multi-layer perceptron (MLP) inference for the **MNIST handwritten digit dataset**. The system processes 28×28 grayscale images and classifies them into digits (0-9). 

Implementation:
- **Hardware Design**: RTL implementation of matrix-vector operations in Q16.16 fixed-point arithmetic.
- **System Integration**: Interfacing the accelerator with an embedded soft-core CPU and off-chip SDRAM.
- **Software Integration**: Modifying provided software to utilize the accelerator.

### Key Components:
1. **RTL Design**: Accelerator core to compute dot products and apply the ReLU activation function.
2. **Nios II System**: Embedded soft-core CPU for system control.
3. **Off-chip SDRAM Interface**: Handling external memory for weights, activations, and biases.
4. **Clock Management**: Generating system clocks with desired properties using PLLs.
5. **Testing Framework**: Comprehensive testbenches to validate functionality.

---

## Features

- **Accelerator Core**: Computes matrix-vector dot products with Q16.16 fixed-point precision.
- **ReLU Activation**: Implements a hardware version of the rectified linear unit.
- **Avalon Interface**: Supports both servant and master interfaces for flexible data transfer.
- **Pre-trained Model**: Utilizes a pre-trained MLP with two 1000-neuron hidden layers.
- **MNIST Inference**: Performs inference for digit classification.
- **Nios II Integration**: Communicates with the processor for control and debugging.

---

## 🔧 Implementation Details

### Accelerator Design

- **Q16.16 Fixed-Point Arithmetic**: 
  - 32-bit signed integers represent numbers in 1/65536 units.
  - Arithmetic operations adjusted to maintain fractional precision.

- **Avalon Interconnect**: 
  - Reads weights and activations from SDRAM using the master interface.
  - Handles multiple sequential requests for matrix-vector multiplication.

### Memory Mapping
| Word Offset | Description                                |
|-------------|--------------------------------------------|
| 0           | Start computation / Read result           |
| 2           | Weight matrix byte address                |
| 3           | Input activations vector byte address     |
| 5           | Input activations vector length           |

---

## 🔮 Testing

### Hardware Testing
- **Unit Tests**: Use `tb_rtl_dot.sv` to validate individual modules.
- **System Integration Tests**: Mock SDRAM and Avalon interfaces to verify end-to-end functionality.

### Software Testing
- **Functional Verification**: Use Python or C to create a software-only implementation of the matrix-vector product for comparison.
- **On-Hardware Debugging**: Use a DE1-SoC board with JTAG and UART for debugging and result verification.
