# ML-Based-Optimization-for-RIS-Assisted-ISAC-Systems
Deep learning based optimization framework for RIS-assisted Integrated Sensing and Communication (RIS-ISAC) systems. The model learns the mapping from channel state information to RIS phase shifts and beamforming parameters, enabling low-complexity sum-rate maximization under radar SNR constraints. Based on the work of Liu et al., IEEE TWC 2024.

# Problem Overview
Integrated Sensing and Communication (ISAC) has emerged as a key technology for future wireless networks by enabling simultaneous communication and radar sensing using shared spectrum and hardware resources. Reconfigurable Intelligent Surfaces (RIS) further enhance system performance by intelligently controlling the wireless propagation environment.

In conventional RIS-assisted ISAC systems, the joint optimization of transmit beamforming and RIS phase shifts is formulated as a non-convex optimization problem. Existing approaches rely on iterative optimization algorithms that provide near-optimal solutions but suffer from high computational complexity and latency, making real-time deployment challenging.

This project addresses this issue by employing a Deep Neural Network (DNN) to learn the mapping between Channel State Information (CSI) and optimized RIS phase configurations. The trained model replaces iterative optimization during inference, enabling faster and low-complexity operation while maintaining competitive communication performance.

# Methodology
The proposed framework consists of the following stages:

## 1. Dataset Generation
Generate wireless channel realizations for RIS-assisted ISAC scenarios.
Obtain optimized RIS phase shifts using the benchmark optimization algorithm.
Construct input-output training pairs.

## 2. Data Preprocessing
Extract real and imaginary components of channel coefficients.
Normalize channel features.
Augment input features with transmit power information.

## 3. Deep Neural Network Training
Input: Channel State Information (CSI) features.
Hidden Layers:
Dense Layers
Batch Normalization
LeakyReLU Activation
Dropout Regularization
Output:
Real and imaginary components of RIS reflection coefficients.

## 4. RIS Reconstruction
Reconstruct complex RIS reflection coefficients from network predictions.
Apply unit-modulus normalization to satisfy RIS hardware constraints.

## 5. Beamforming Design
Construct the effective RIS-assisted channel.
Apply Zero-Forcing (ZF) beamforming to suppress multi-user interference.

## 6. Performance Evaluation
Evaluate achievable sum-rate under different transmit power levels.
Compare ML predictions with optimization-based benchmark methods.
Results and Observations
Key Findings
The proposed DNN successfully learns the nonlinear relationship between CSI and optimized RIS phase shifts.
The ML-based framework significantly reduces computational complexity compared to iterative optimization approaches.
Achievable sum-rate increases consistently with transmit power.
The trained model achieves performance close to optimization-based solutions while requiring only a forward pass during inference.
Zero-Forcing beamforming effectively suppresses multi-user interference after RIS phase prediction.
The framework demonstrates good generalization across different channel realizations and power levels.
Performance Metrics
Achievable Sum-Rate
Sum-Rate vs Transmit Power
Prediction Accuracy
Computational Complexity Reduction

## 7. Reference

This work is inspired by:

R. Liu, M. Li, Q. Liu, and A. L. Swindlehurst, "SNR/CRB-Constrained Joint Beamforming and Reflection Designs for RIS-ISAC Systems", IEEE Transactions on Wireless Communications, 2024.
