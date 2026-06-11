# zcanny

Implementation of the Canny Edge detection algorithm using Zig, for learning purposes.

### Image Pipeline

<div>
  <p>Original Image</p>
  <img src="./dev.png" width="600" alt="original" />
  <p>Stage 1: Gaussian Blur</p>
  <img src="./output/gaussian_blur.png" width="600" alt="gaussian" />
  <p>Stage 2: Gradient Computation with Sobel kernels</p>
  <img src="./output/mag.png" width="600" alt="gradients" />
  <p>Stage 3: Thinned magnitude with non-max suppression</p>
  <img src="./output/thinned_mag.png" width="600" alt="gradients" />
</div>

### References
1. [Canny Edge Detection](https://en.wikipedia.org/wiki/Canny_edge_detector)
2. [Zig](https://ziglang.org/)
