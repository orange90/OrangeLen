__global__ void scale(float *x) { x[threadIdx.x] *= 2.0f; }
