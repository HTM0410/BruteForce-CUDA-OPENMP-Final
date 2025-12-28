/*
 * ===================================================================
 * NHAN MA TRAN VOI CUDA - PHIEN BAN CAI TIEN
 * So sanh CPU vs GPU, hien thi ro rang
 * ===================================================================
 * 
 * Compile: nvcc matrices_improved.cu -o matrices_improved.exe
 * Run: .\matrices_improved.exe
 */

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define MAX_DISPLAY_SIZE 10

// ====================================================================
// CUDA KERNEL - NHAN MA TRAN TREN GPU
// ====================================================================
__global__ void matrix_multiply_gpu(double *a, double *b, double *c, int N) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;  // Hang (row)
    int j = blockIdx.y * blockDim.y + threadIdx.y;  // Cot (column)
    
    if (i < N && j < N) {
        double sum = 0.0;
        for(int k = 0; k < N; k++) {
            sum += a[i * N + k] * b[k * N + j];
        }
        c[i * N + j] = sum;
    }
}

// ====================================================================
// CPU VERSION - NHAN MA TRAN TREN CPU
// ====================================================================
void matrix_multiply_cpu(double *a, double *b, double *c, int N) {
    for(int i = 0; i < N; i++) {
        for(int j = 0; j < N; j++) {
            double sum = 0.0;
            for(int k = 0; k < N; k++) {
                sum += a[i * N + k] * b[k * N + j];
            }
            c[i * N + j] = sum;
        }
    }
}

// ====================================================================
// HIEN THI MA TRAN
// ====================================================================
void display_matrix(double *matrix, int N, const char* name) {
    printf("\n  Ma tran %s (%dx%d):\n", name, N, N);
    printf("  ┌");
    for(int i = 0; i < N * 8; i++) printf(" ");
    printf("┐\n");
    
    for(int i = 0; i < N; i++) {
        printf("  │ ");
        for(int j = 0; j < N; j++) {
            printf("%6.1lf ", matrix[i * N + j]);
        }
        printf("│\n");
    }
    
    printf("  └");
    for(int i = 0; i < N * 8; i++) printf(" ");
    printf("┘\n");
}

// ====================================================================
// KIEM TRA KET QUA
// ====================================================================
int verify_result(double *cpu_result, double *gpu_result, int N) {
    double epsilon = 1e-5;
    for(int i = 0; i < N * N; i++) {
        if(fabs(cpu_result[i] - gpu_result[i]) > epsilon) {
            return 0;
        }
    }
    return 1;
}

// ====================================================================
// MAIN
// ====================================================================
int main() {
    system("chcp 65001 > nul");
    
    printf("\n");
    printf("================================================================\n");
    printf("  NHAN MA TRAN VOI CUDA - GPU vs CPU\n");
    printf("================================================================\n\n");
    
    // Chon kich thuoc ma tran
    printf("  Chon kich thuoc ma tran:\n\n");
    printf("  1. NHO      (5x5)      - Hien thi day du\n");
    printf("  2. TRUNG    (10x10)    - Hien thi day du\n");
    printf("  3. LON      (100x100)  - Chi hien thi ket qua\n");
    printf("  4. RAT LON  (500x500)  - Chi hien thi ket qua\n");
    printf("  5. CUC LON  (1000x1000)- Chi hien thi ket qua\n");
    printf("  6. SIEU LON (2000x2000)- Chi hien thi ket qua\n\n");
    
    int choice;
    printf("  Lua chon cua ban (1-6): ");
    scanf("%d", &choice);
    
    int N;
    switch(choice) {
        case 1: N = 5; break;
        case 2: N = 10; break;
        case 3: N = 100; break;
        case 4: N = 500; break;
        case 5: N = 1000; break;
        case 6: N = 2000; break;
        default: N = 10;
    }
    
    printf("\n");
    printf("================================================================\n");
    printf("  THONG TIN BAI TOAN\n");
    printf("================================================================\n");
    printf("  Kich thuoc ma tran: %d x %d\n", N, N);
    printf("  Tong phan tu:       %d\n", N * N);
    printf("  Tong phep nhan:     %lld (= %d^3)\n", (long long)N * N * N, N);
    printf("  Bo nho can:         %.2f MB\n", 
           (3.0 * N * N * sizeof(double)) / (1024.0 * 1024.0));
    
    // Thong tin GPU
    cudaDeviceProp prop;
    cudaGetDeviceProperties(&prop, 0);
    printf("\n  GPU: %s\n", prop.name);
    printf("  CUDA Cores: ~%d\n", prop.multiProcessorCount * 128);
    printf("  Global Memory: %.2f GB\n", 
           prop.totalGlobalMem / (1024.0 * 1024.0 * 1024.0));
    
    printf("\n  Dang khoi tao du lieu...\n");
    
    // Cap phat bo nho tren CPU
    size_t size = N * N * sizeof(double);
    double *h_a = (double*)malloc(size);
    double *h_b = (double*)malloc(size);
    double *h_c_cpu = (double*)malloc(size);
    double *h_c_gpu = (double*)malloc(size);
    
    // Khoi tao ma tran ngau nhien
    srand(time(NULL));
    for(int i = 0; i < N * N; i++) {
        h_a[i] = (double)(rand() % 10);
        h_b[i] = (double)(rand() % 10);
        h_c_cpu[i] = 0.0;
        h_c_gpu[i] = 0.0;
    }
    
    // Hien thi ma tran input neu nho
    if(N <= MAX_DISPLAY_SIZE) {
        display_matrix(h_a, N, "A");
        display_matrix(h_b, N, "B");
    }
    
    printf("\n");
    printf("================================================================\n");
    printf("  PHUONG PHAP 1: TINH TREN CPU (Tuan tu)\n");
    printf("================================================================\n");
    
    clock_t cpu_start = clock();
    matrix_multiply_cpu(h_a, h_b, h_c_cpu, N);
    clock_t cpu_end = clock();
    double cpu_time = (double)(cpu_end - cpu_start) / CLOCKS_PER_SEC;
    
    printf("\n  ✓ Hoan thanh!\n");
    printf("  Thoi gian CPU: %.6f giay\n", cpu_time);
    printf("  Toc do:        %.2f GFLOPS\n", 
           (2.0 * N * N * N) / (cpu_time * 1e9));
    
    if(N <= MAX_DISPLAY_SIZE) {
        display_matrix(h_c_cpu, N, "C (CPU)");
    }
    
    printf("\n");
    printf("================================================================\n");
    printf("  PHUONG PHAP 2: TINH TREN GPU (Song song)\n");
    printf("================================================================\n");
    
    // Cap phat bo nho tren GPU
    double *d_a, *d_b, *d_c;
    cudaMalloc((void**)&d_a, size);
    cudaMalloc((void**)&d_b, size);
    cudaMalloc((void**)&d_c, size);
    
    // Copy du lieu len GPU
    cudaMemcpy(d_a, h_a, size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, h_b, size, cudaMemcpyHostToDevice);
    
    // Cau hinh CUDA
    dim3 threadsPerBlock(16, 16);
    dim3 blocksPerGrid(
        (N + threadsPerBlock.x - 1) / threadsPerBlock.x,
        (N + threadsPerBlock.y - 1) / threadsPerBlock.y
    );
    
    printf("\n  Cau hinh CUDA:\n");
    printf("  --------------------------------------------------------\n");
    printf("    Threads/Block:  %d x %d = %d threads\n", 
           threadsPerBlock.x, threadsPerBlock.y, 
           threadsPerBlock.x * threadsPerBlock.y);
    printf("    Blocks/Grid:    %d x %d = %d blocks\n", 
           blocksPerGrid.x, blocksPerGrid.y, 
           blocksPerGrid.x * blocksPerGrid.y);
    printf("    Total Threads:  %d\n", 
           threadsPerBlock.x * threadsPerBlock.y * 
           blocksPerGrid.x * blocksPerGrid.y);
    printf("  --------------------------------------------------------\n");
    
    printf("\n  >>> Bat dau tinh toan tren GPU...\n");
    
    // Warmup run (optional)
    matrix_multiply_gpu<<<blocksPerGrid, threadsPerBlock>>>(d_a, d_b, d_c, N);
    cudaDeviceSynchronize();
    
    // Bat dau timer GPU
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);
    
    // Chay kernel
    matrix_multiply_gpu<<<blocksPerGrid, threadsPerBlock>>>(d_a, d_b, d_c, N);
    
    // Ket thuc timer
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    
    float gpu_milliseconds = 0;
    cudaEventElapsedTime(&gpu_milliseconds, start, stop);
    double gpu_time = gpu_milliseconds / 1000.0;
    
    // Copy ket qua ve CPU
    cudaMemcpy(h_c_gpu, d_c, size, cudaMemcpyDeviceToHost);
    
    printf("\n  ✓ Hoan thanh!\n");
    printf("  Thoi gian GPU: %.6f giay\n", gpu_time);
    printf("  Toc do:        %.2f GFLOPS\n", 
           (2.0 * N * N * N) / (gpu_time * 1e9));
    
    if(N <= MAX_DISPLAY_SIZE) {
        display_matrix(h_c_gpu, N, "C (GPU)");
    }
    
    // Kiem tra ket qua
    printf("\n");
    printf("================================================================\n");
    printf("  KIEM TRA KET QUA\n");
    printf("================================================================\n");
    
    int correct = verify_result(h_c_cpu, h_c_gpu, N);
    if(correct) {
        printf("\n  ✓✓✓ KET QUA DUNG! GPU va CPU cho ket qua giong nhau!\n");
    } else {
        printf("\n  ✗✗✗ CANH BAO: Ket qua khac nhau!\n");
    }
    
    // So sanh hieu suat
    printf("\n");
    printf("================================================================\n");
    printf("  SO SANH HIEU SUAT\n");
    printf("================================================================\n\n");
    
    double speedup = cpu_time / gpu_time;
    
    printf("  THOI GIAN:\n");
    printf("  --------------------------------------------------------\n");
    printf("    CPU (Tuan tu):    %10.6f giay\n", cpu_time);
    printf("    GPU (Song song):  %10.6f giay\n", gpu_time);
    printf("  --------------------------------------------------------\n");
    printf("    SPEEDUP:          %.2fx nhanh hon!\n\n", speedup);
    
    // Bieu do
    printf("  BIEU DO (thoi gian):\n\n");
    printf("  CPU:  ");
    int max_bars = 50;
    for(int i = 0; i < max_bars; i++) printf("█");
    printf(" %.3fs\n", cpu_time);
    
    printf("  GPU:  ");
    int gpu_bars = (int)(max_bars * gpu_time / cpu_time);
    if(gpu_bars < 1) gpu_bars = 1;
    for(int i = 0; i < gpu_bars; i++) printf("█");
    printf(" %.3fs\n\n", gpu_time);
    
    // Danh gia
    if(speedup >= 100) {
        printf("  🚀🚀🚀 GPU CUC MANH! Nhanh hon CPU %.0fx!\n", speedup);
    } else if(speedup >= 50) {
        printf("  🚀🚀 GPU RAT MANH! Nhanh hon CPU %.0fx!\n", speedup);
    } else if(speedup >= 10) {
        printf("  🚀 GPU MANH! Nhanh hon CPU %.0fx!\n", speedup);
    } else if(speedup >= 2) {
        printf("  ✓ GPU nhanh hon CPU %.2fx\n", speedup);
    } else {
        printf("  ⚠ GPU khong nhanh hon nhieu (overhead)\n");
    }
    
    // Hieu suat theo GFLOPS
    double cpu_gflops = (2.0 * N * N * N) / (cpu_time * 1e9);
    double gpu_gflops = (2.0 * N * N * N) / (gpu_time * 1e9);
    
    printf("\n  TOC DO TINH TOAN:\n");
    printf("  --------------------------------------------------------\n");
    printf("    CPU: %10.2f GFLOPS\n", cpu_gflops);
    printf("    GPU: %10.2f GFLOPS\n", gpu_gflops);
    printf("  --------------------------------------------------------\n");
    
    // Giai phong bo nho
    cudaFree(d_a);
    cudaFree(d_b);
    cudaFree(d_c);
    free(h_a);
    free(h_b);
    free(h_c_cpu);
    free(h_c_gpu);
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
    
    printf("\n");
    printf("================================================================\n");
    printf("  KET LUAN\n");
    printf("================================================================\n");
    printf("\n  • GPU phu hop cho cac phep tinh ma tran lon\n");
    printf("  • Voi N = %d, GPU nhanh hon CPU %.2fx\n", N, speedup);
    printf("  • GPU dat %.2f GFLOPS (ty phep tinh/giay)\n", gpu_gflops);
    printf("\n");
    printf("================================================================\n\n");
    
    return 0;
}

