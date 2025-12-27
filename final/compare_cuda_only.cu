/*
 * ===================================================================
 * SO SANH: CHI CHAY CUDA - GPU ONLY
 * Tu chon do dai mat khau, chi test GPU performance
 * ===================================================================
 * 
 * Compile: nvcc compare_cuda_only.cu -o compare_cuda_only.exe
 * Run: .\compare_cuda_only.exe
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <cuda_runtime.h>

#define MAX_PASSWORD_LENGTH 8
#define CHARSET_SIZE 26

// Bien toan cuc
char SECRET_PASSWORD[MAX_PASSWORD_LENGTH + 1];
int PASSWORD_LENGTH = 4;
long long TOTAL_COMBINATIONS = 456976;
int HASH_COMPLEXITY = 1000;

__device__ int d_found = 0;
__device__ char d_found_password[MAX_PASSWORD_LENGTH + 1];

// ====================================================================
// HAM TINH TOAN
// ====================================================================

long long calculate_combinations(int length) {
    long long result = 1;
    for(int i = 0; i < length; i++) {
        result *= CHARSET_SIZE;
    }
    return result;
}

void generate_random_password(char* password, int length) {
    srand(time(NULL));
    for(int i = 0; i < length; i++) {
        password[i] = 'A' + (rand() % CHARSET_SIZE);
    }
    password[length] = '\0';
}

// ====================================================================
// HASH FUNCTIONS - CPU & GPU
// ====================================================================

int complex_hash_cpu(const char* password, int complexity) {
    unsigned int hash = 5381;
    for(int round = 0; round < complexity; round++) {
        for(int i = 0; password[i] != '\0'; i++) {
            hash = ((hash << 5) + hash) + password[i];
            hash ^= (hash >> 7);
            hash += (hash << 3);
            hash ^= (hash >> 17);
            hash += (hash << 5);
        }
    }
    return hash;
}

__device__ unsigned int complex_hash_gpu(const char* password, int complexity, int length) {
    unsigned int hash = 5381;
    for(int round = 0; round < complexity; round++) {
        for(int i = 0; i < length; i++) {
            hash = ((hash << 5) + hash) + password[i];
            hash ^= (hash >> 7);
            hash += (hash << 3);
            hash ^= (hash >> 17);
            hash += (hash << 5);
        }
    }
    return hash;
}

__device__ int check_password_gpu(const char* password, unsigned int secret_hash, 
                                   int complexity, int length) {
    unsigned int test_hash = complex_hash_gpu(password, complexity, length);
    return test_hash == secret_hash;
}

// ====================================================================
// CUDA KERNEL
// ====================================================================
__global__ void brute_force_kernel(unsigned int secret_hash, long long total, 
                                   int password_length, int complexity) {
    long long idx = (long long)blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= total) return;
    if (d_found) return;
    
    char password[MAX_PASSWORD_LENGTH + 1];
    password[password_length] = '\0';
    
    long long temp = idx;
    for(int i = password_length - 1; i >= 0; i--) {
        password[i] = 'A' + (temp % CHARSET_SIZE);
        temp /= CHARSET_SIZE;
    }
    
    if(check_password_gpu(password, secret_hash, complexity, password_length)) {
        if(atomicCAS(&d_found, 0, 1) == 0) {
            for(int i = 0; i <= password_length; i++) {
                d_found_password[i] = password[i];
            }
        }
    }
}

// ====================================================================
// CUDA BRUTE FORCE
// ====================================================================
double brute_force_cuda(char* result, int secret_hash) {
    printf("\n================================================================\n");
    printf("  KHOI CHAY GPU (CUDA)\n");
    printf("================================================================\n\n");
    
    // Thong tin GPU
    cudaDeviceProp prop;
    cudaGetDeviceProperties(&prop, 0);
    printf("  GPU: %s\n", prop.name);
    printf("  CUDA Cores: ~%d\n", prop.multiProcessorCount * 128);
    printf("  Max Threads/Block: %d\n", prop.maxThreadsPerBlock);
    printf("  Global Memory: %.2f GB\n", prop.totalGlobalMem / 1024.0 / 1024.0 / 1024.0);
    
    // Reset ket qua
    int init_found = 0;
    char init_password[MAX_PASSWORD_LENGTH + 1] = "";
    cudaMemcpyToSymbol(d_found, &init_found, sizeof(int));
    cudaMemcpyToSymbol(d_found_password, init_password, MAX_PASSWORD_LENGTH + 1);
    
    // Cau hinh kernel
    int threadsPerBlock = 256;
    long long blocksPerGrid = (TOTAL_COMBINATIONS + threadsPerBlock - 1) / threadsPerBlock;
    
    if(blocksPerGrid > 2147483647LL) {
        printf("  Canh bao: Khong gian qua lon, se chia nho!\n");
        blocksPerGrid = 2147483647LL;
    }
    
    printf("\n  CAU HINH CUDA:\n");
    printf("  --------------------------------------------------------\n");
    printf("    Threads/Block:  %d\n", threadsPerBlock);
    printf("    Blocks/Grid:    %lld\n", blocksPerGrid);
    printf("    Total Threads:  %lld\n", (long long)threadsPerBlock * blocksPerGrid);
    printf("    Password Space: %lld\n", TOTAL_COMBINATIONS);
    printf("  --------------------------------------------------------\n");
    
    printf("\n  >>> Bat dau brute force tren GPU...\n");
    
    // Bat dau timer
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);
    
    // Chay kernel
    brute_force_kernel<<<(int)blocksPerGrid, threadsPerBlock>>>(
        secret_hash, TOTAL_COMBINATIONS, PASSWORD_LENGTH, HASH_COMPLEXITY);
    
    // Dong bo
    cudaDeviceSynchronize();
    
    // Dung timer
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    
    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);
    double elapsed = milliseconds / 1000.0;
    
    // Lay ket qua
    int found;
    char found_password[MAX_PASSWORD_LENGTH + 1];
    cudaMemcpyFromSymbol(&found, d_found, sizeof(int));
    cudaMemcpyFromSymbol(found_password, d_found_password, MAX_PASSWORD_LENGTH + 1);
    
    printf("\n  KET QUA:\n");
    printf("  --------------------------------------------------------\n");
    if(found) {
        printf("    Status:         TIM THAY!\n");
        printf("    Mat khau:       %s\n", found_password);
        printf("    Thoi gian:      %.6f giay\n", elapsed);
        printf("    Toc do:         ~%.0f tries/giay\n", (double)TOTAL_COMBINATIONS / elapsed);
        printf("    GPU Throughput: ~%.2f M tries/s\n", 
               (double)TOTAL_COMBINATIONS / elapsed / 1000000.0);
        strcpy(result, found_password);
    } else {
        printf("    Status:         KHONG TIM THAY!\n");
        printf("    Thoi gian:      %.6f giay\n", elapsed);
        strcpy(result, "");
    }
    printf("  --------------------------------------------------------\n\n");
    
    // Kiem tra loi
    cudaError_t error = cudaGetLastError();
    if(error != cudaSuccess) {
        printf("  CUDA Error: %s\n", cudaGetErrorString(error));
    }
    
    // Cleanup
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
    
    return elapsed;
}

// ====================================================================
// MENU VA SETUP
// ====================================================================

void display_banner() {
    printf("\n");
    printf("================================================================\n");
    printf("  CUDA BRUTE FORCE - GPU PERFORMANCE TEST\n");
    printf("  Test suc manh GPU voi brute force attack\n");
    printf("================================================================\n");
}

void display_menu() {
    printf("\n  BAN MUON:\n");
    printf("  --------------------------------------------------------\n");
    printf("  1. AUTO   - Tu sinh mat khau ngau nhien\n");
    printf("  2. CUSTOM - Tu nhap mat khau\n");
    printf("  --------------------------------------------------------\n");
}

void display_complexity_menu() {
    printf("\n  CHON DO PHUC TAP HASH:\n");
    printf("  --------------------------------------------------------\n");
    printf("  1. DON GIAN       (100 ops)     - Nhanh, demo\n");
    printf("  2. TRUNG BINH     (1,000 ops)   - Can bang\n");
    printf("  3. PHUC TAP       (10,000 ops)  - Thuc te\n");
    printf("  4. CUC PHUC TAP   (50,000 ops)  - Kho\n");
    printf("  5. SIEU PHUC TAP  (100,000 ops) - Cuc kho!\n");
    printf("  --------------------------------------------------------\n");
}

void setup_problem() {
    system("chcp 65001 > nul");
    
    display_banner();
    display_menu();
    
    int mode;
    printf("\n  Lua chon (1-2): ");
    scanf("%d", &mode);
    
    // Chon do dai
    printf("\n  Chon do dai mat khau (3-8 ky tu): ");
    scanf("%d", &PASSWORD_LENGTH);
    if(PASSWORD_LENGTH < 3) PASSWORD_LENGTH = 3;
    if(PASSWORD_LENGTH > 8) PASSWORD_LENGTH = 8;
    
    TOTAL_COMBINATIONS = calculate_combinations(PASSWORD_LENGTH);
    
    // Chon do phuc tap
    display_complexity_menu();
    int complexity_choice;
    printf("\n  Lua chon (1-5): ");
    scanf("%d", &complexity_choice);
    
    switch(complexity_choice) {
        case 1: HASH_COMPLEXITY = 100; break;
        case 2: HASH_COMPLEXITY = 1000; break;
        case 3: HASH_COMPLEXITY = 10000; break;
        case 4: HASH_COMPLEXITY = 50000; break;
        case 5: HASH_COMPLEXITY = 100000; break;
        default: HASH_COMPLEXITY = 1000;
    }
    
    // Sinh hoac nhap mat khau
    if(mode == 1) {
        generate_random_password(SECRET_PASSWORD, PASSWORD_LENGTH);
        printf("\n  => Mat khau ngau nhien: %s\n", SECRET_PASSWORD);
    } else {
        printf("\n  Nhap mat khau (CHU HOA A-Z): ");
        scanf("%s", SECRET_PASSWORD);
        
        // Validate
        for(int i = 0; i < strlen(SECRET_PASSWORD); i++) {
            if(SECRET_PASSWORD[i] < 'A' || SECRET_PASSWORD[i] > 'Z') {
                SECRET_PASSWORD[i] = 'A';
            }
        }
        SECRET_PASSWORD[PASSWORD_LENGTH] = '\0';
        printf("  => Mat khau muc tieu: %s\n", SECRET_PASSWORD);
    }
}

// ====================================================================
// MAIN
// ====================================================================
int main() {
    // Setup
    setup_problem();
    
    // Hien thi thong tin
    printf("\n");
    printf("================================================================\n");
    printf("  THONG TIN BAI TOAN\n");
    printf("================================================================\n");
    printf("  Mat khau:           %s\n", SECRET_PASSWORD);
    printf("  Do dai:             %d ky tu\n", PASSWORD_LENGTH);
    printf("  Khong gian:         26^%d = %lld kha nang\n", 
           PASSWORD_LENGTH, TOTAL_COMBINATIONS);
    printf("  Hash complexity:    %d operations/check\n", HASH_COMPLEXITY);
    printf("  Tong operations:    ~%.2f ty\n", 
           (double)TOTAL_COMBINATIONS * HASH_COMPLEXITY / 1000000000.0);
    
    // Du doan thoi gian GPU
    double estimated_gpu = (double)TOTAL_COMBINATIONS * HASH_COMPLEXITY / 1000000000.0 / 1000;
    printf("\n  DU DOAN THOI GIAN GPU:\n");
    printf("  --------------------------------------------------------\n");
    printf("    Best case:  ~%.3f giay\n", estimated_gpu * 0.5);
    printf("    Expected:   ~%.3f giay\n", estimated_gpu);
    printf("    Worst case: ~%.3f giay\n", estimated_gpu * 2);
    printf("  --------------------------------------------------------\n");
    
    // Xac nhan
    printf("\n  Ban co muon tiep tuc? (y/n): ");
    char confirm;
    scanf(" %c", &confirm);
    if(confirm != 'y' && confirm != 'Y') {
        printf("\n  Da huy!\n\n");
        return 0;
    }
    
    // Tinh hash cua mat khau bi mat
    int secret_hash = complex_hash_cpu(SECRET_PASSWORD, HASH_COMPLEXITY);
    printf("\n  Secret hash: %u\n", secret_hash);
    
    // Chay CUDA
    char result[MAX_PASSWORD_LENGTH + 1];
    double time_cuda = brute_force_cuda(result, secret_hash);
    
    // Ket qua cuoi cung
    printf("\n");
    printf("================================================================\n");
    printf("  TONG KET\n");
    printf("================================================================\n");
    printf("  Mat khau tim duoc:  %s\n", strlen(result) > 0 ? result : "Khong tim thay");
    printf("  Mat khau thuc te:   %s\n", SECRET_PASSWORD);
    printf("  Ket qua:            %s\n", 
           strcmp(result, SECRET_PASSWORD) == 0 ? "CHINH XAC!" : "SAI!");
    printf("\n");
    printf("  HIEU SUAT GPU:\n");
    printf("  --------------------------------------------------------\n");
    printf("    Thoi gian:      %.6f giay\n", time_cuda);
    printf("    Toc do:         %.2f M tries/s\n", 
           (double)TOTAL_COMBINATIONS / time_cuda / 1000000.0);
    printf("    Total tries:    %lld\n", TOTAL_COMBINATIONS);
    printf("    Hash per try:   %d ops\n", HASH_COMPLEXITY);
    printf("    GPU Throughput: %.2f G ops/s\n", 
           (double)TOTAL_COMBINATIONS * HASH_COMPLEXITY / time_cuda / 1000000000.0);
    printf("  --------------------------------------------------------\n");
    
    // So sanh voi CPU gia dinh
    double estimated_cpu = (double)TOTAL_COMBINATIONS * HASH_COMPLEXITY / 5000000000.0;
    double speedup = estimated_cpu / time_cuda;
    
    printf("\n  SO SANH VOI CPU (GIA DINH):\n");
    printf("  --------------------------------------------------------\n");
    printf("    CPU thoi gian:  ~%.2f giay (gia dinh)\n", estimated_cpu);
    printf("    GPU thoi gian:  %.6f giay (thuc te)\n", time_cuda);
    printf("    Speedup:        ~%.0fx nhanh hon!\n", speedup);
    printf("  --------------------------------------------------------\n");
    
    if(speedup >= 1000) {
        printf("\n  >>> GPU CUC MANH! Nhanh hon CPU %.0fx! <<<\n", speedup);
    } else if(speedup >= 500) {
        printf("\n  >>> GPU RAT MANH! Nhanh hon CPU %.0fx! <<<\n", speedup);
    } else if(speedup >= 100) {
        printf("\n  >>> GPU MANH! Nhanh hon CPU %.0fx! <<<\n", speedup);
    }
    
    printf("\n");
    printf("================================================================\n");
    printf("  KET LUAN: GPU la lua chon tot nhat cho brute force!\n");
    printf("================================================================\n\n");
    
    return 0;
}

