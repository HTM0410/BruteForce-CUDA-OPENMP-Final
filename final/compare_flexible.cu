/*
 * ===================================================================
 * SO SANH: TUAN TU vs OPENMP vs CUDA - LINH HOAT
 * Tu dong sinh mat khau, tu chon do dai
 * ===================================================================
 * 
 * Compile: nvcc compare_flexible.cu -o compare_flexible.exe -Xcompiler "/openmp"
 * Run: .\compare_flexible.exe
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <omp.h>
#include <cuda_runtime.h>

#define MAX_PASSWORD_LENGTH 8
#define CHARSET_SIZE 26  // A-Z

// Bien toan cuc
char SECRET_PASSWORD[MAX_PASSWORD_LENGTH + 1];
int PASSWORD_LENGTH = 4;
long long TOTAL_COMBINATIONS = 456976;
int HASH_COMPLEXITY = 1000;  // So vong lap hash

__device__ int d_found = 0;
__device__ char d_found_password[MAX_PASSWORD_LENGTH + 1];

// ====================================================================
// HAM TINH TOAN
// ====================================================================

// Tinh so to hop (26^n)
long long calculate_combinations(int length) {
    long long result = 1;
    for(int i = 0; i < length; i++) {
        result *= CHARSET_SIZE;
    }
    return result;
}

// Sinh mat khau ngau nhien
void generate_random_password(char* password, int length) {
    srand(time(NULL));
    for(int i = 0; i < length; i++) {
        password[i] = 'A' + (rand() % CHARSET_SIZE);
    }
    password[length] = '\0';
}

// Hash function co the dieu chinh do phuc tap
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

int check_password_cpu(const char* password, int secret_hash, int complexity) {
    int test_hash = complex_hash_cpu(password, complexity);
    return test_hash == secret_hash;
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
// CHUYEN DOI INDEX -> PASSWORD
// ====================================================================
void index_to_password(long long index, char* password, int length) {
    for(int i = length - 1; i >= 0; i--) {
        password[i] = 'A' + (index % CHARSET_SIZE);
        index /= CHARSET_SIZE;
    }
    password[length] = '\0';
}

// ====================================================================
// METHOD 1: TUAN TU
// ====================================================================
double brute_force_sequential(char* result, int secret_hash) {
    printf("\n================================================================\n");
    printf("  [1] PHUONG PHAP TUAN TU (Sequential)\n");
    printf("================================================================\n\n");
    
    char password[MAX_PASSWORD_LENGTH + 1];
    long long tries = 0;
    double start = omp_get_wtime();
    
    printf("  Dang tim kiem...\n");
    
    long long progress_step = TOTAL_COMBINATIONS / 10;
    if(progress_step == 0) progress_step = 1;
    
    for(long long idx = 0; idx < TOTAL_COMBINATIONS; idx++) {
        tries++;
        index_to_password(idx, password, PASSWORD_LENGTH);
        
        if(idx % progress_step == 0 && idx > 0) {
            double elapsed = omp_get_wtime() - start;
            double progress = (idx * 100.0) / TOTAL_COMBINATIONS;
            printf("  [%s] %.1f%% - Thoi gian: %.1fs\n", 
                   password, progress, elapsed);
        }
        
        if(check_password_cpu(password, secret_hash, HASH_COMPLEXITY)) {
            double end = omp_get_wtime();
            double elapsed = end - start;
            printf("\n  >>> TIM THAY! Mat khau = %s\n", password);
            printf("  So lan thu: %lld\n", tries);
            printf("  Thoi gian: %.3f giay\n", elapsed);
            printf("  Toc do: %.0f tries/giay\n\n", tries / elapsed);
            strcpy(result, password);
            return elapsed;
        }
    }
    
    strcpy(result, "");
    return omp_get_wtime() - start;
}

// ====================================================================
// METHOD 2: OPENMP
// ====================================================================
double brute_force_openmp(char* result, int secret_hash) {
    printf("\n================================================================\n");
    printf("  [2] PHUONG PHAP SONG SONG (OpenMP)\n");
    printf("================================================================\n\n");
    
    char found_password[MAX_PASSWORD_LENGTH + 1] = "";
    long long total_tries = 0;
    int found = 0;
    double start = omp_get_wtime();
    
    int num_threads = omp_get_max_threads();
    printf("  So threads: %d\n", num_threads);
    printf("  Dang chay song song...\n\n");
    
    long long progress_step = TOTAL_COMBINATIONS / 10;
    if(progress_step == 0) progress_step = 1;
    
    #pragma omp parallel
    {
        int thread_id = omp_get_thread_num();
        char password[MAX_PASSWORD_LENGTH + 1];
        long long my_tries = 0;
        
        #pragma omp for schedule(dynamic, 5000)
        for(long long idx = 0; idx < TOTAL_COMBINATIONS; idx++) {
            if(found) continue;
            my_tries++;
            index_to_password(idx, password, PASSWORD_LENGTH);
            
            if(thread_id == 0 && idx % progress_step == 0 && idx > 0) {
                double elapsed = omp_get_wtime() - start;
                double progress = (idx * 100.0) / TOTAL_COMBINATIONS;
                printf("  [Thread %d][%s] %.1f%%\n", thread_id, password, progress);
            }
            
            if(check_password_cpu(password, secret_hash, HASH_COMPLEXITY)) {
                #pragma omp critical
                {
                    if(!found) {
                        double end = omp_get_wtime();
                        strcpy(found_password, password);
                        found = 1;
                        printf("\n  >>> THREAD %d TIM THAY! Mat khau = %s\n", 
                               thread_id, password);
                        printf("  Thoi gian: %.3f giay\n\n", end - start);
                    }
                }
            }
        }
        
        #pragma omp atomic
        total_tries += my_tries;
    }
    
    double elapsed = omp_get_wtime() - start;
    printf("  Tong so lan thu: %lld\n", total_tries);
    printf("  Toc do: %.0f tries/giay\n\n", (double)total_tries / elapsed);
    strcpy(result, found_password);
    return elapsed;
}

// ====================================================================
// METHOD 3: CUDA
// ====================================================================
double brute_force_cuda(char* result, int secret_hash) {
    printf("\n================================================================\n");
    printf("  [3] PHUONG PHAP GPU (CUDA)\n");
    printf("================================================================\n\n");
    
    cudaDeviceProp prop;
    cudaGetDeviceProperties(&prop, 0);
    printf("  GPU: %s\n", prop.name);
    printf("  CUDA Cores: ~%d\n", prop.multiProcessorCount * 128);
    
    int init_found = 0;
    char init_password[MAX_PASSWORD_LENGTH + 1] = "";
    cudaMemcpyToSymbol(d_found, &init_found, sizeof(int));
    cudaMemcpyToSymbol(d_found_password, init_password, MAX_PASSWORD_LENGTH + 1);
    
    int threadsPerBlock = 256;
    long long blocksPerGrid = (TOTAL_COMBINATIONS + threadsPerBlock - 1) / threadsPerBlock;
    
    // Gioi han so blocks tren GPU
    if(blocksPerGrid > 2147483647LL) {
        printf("  Canh bao: Khong gian qua lon, se chia nho!\n");
        blocksPerGrid = 2147483647LL;
    }
    
    printf("  Cau hinh: %d threads/block, %lld blocks\n", threadsPerBlock, blocksPerGrid);
    printf("  Dang chay tren GPU...\n");
    
    double start = omp_get_wtime();
    brute_force_kernel<<<(int)blocksPerGrid, threadsPerBlock>>>(
        secret_hash, TOTAL_COMBINATIONS, PASSWORD_LENGTH, HASH_COMPLEXITY);
    cudaDeviceSynchronize();
    double elapsed = omp_get_wtime() - start;
    
    int found;
    char found_password[MAX_PASSWORD_LENGTH + 1];
    cudaMemcpyFromSymbol(&found, d_found, sizeof(int));
    cudaMemcpyFromSymbol(found_password, d_found_password, MAX_PASSWORD_LENGTH + 1);
    
    if(found) {
        printf("\n  >>> GPU TIM THAY! Mat khau = %s\n", found_password);
        printf("  Thoi gian: %.3f giay\n", elapsed);
        printf("  Toc do: ~%.0f tries/giay\n\n", (double)TOTAL_COMBINATIONS / elapsed);
        strcpy(result, found_password);
    } else {
        printf("\n  Khong tim thay!\n\n");
        strcpy(result, "");
    }
    
    cudaError_t error = cudaGetLastError();
    if(error != cudaSuccess) {
        printf("  CUDA Error: %s\n", cudaGetErrorString(error));
    }
    
    return elapsed;
}

// ====================================================================
// MENU VA SETUP
// ====================================================================
void display_menu() {
    printf("\n================================================================\n");
    printf("  SETUP BAI TOAN BRUTE FORCE\n");
    printf("================================================================\n\n");
    
    printf("  Ban muon chon che do nao?\n\n");
    printf("  1. AUTO - Tu dong sinh mat khau ngau nhien\n");
    printf("  2. CUSTOM - Nhap mat khau tu tuy chinh\n\n");
}

void display_complexity_menu() {
    printf("\n  Chon do phuc tap hash:\n\n");
    printf("  1. DON GIAN    (300 ops)     - Nhanh, demo (~MD5)\n");
    printf("  2. TRUNG BINH  (600 ops)   - Can bang (~SHA-1)\n");
    printf("  3. PHUC TAP    (1,000 ops)  - Thuc te, (~SHA-256) cham\n");
    printf("  4. CUC PHUC TAP (10,000 ops) - Rat cham!\n\n");
}

int select_password_length() {
    int length;
    printf("\n  Chon do dai mat khau (3-8 ky tu): ");
    scanf("%d", &length);
    
    if(length < 3) length = 3;
    if(length > 8) length = 8;
    
    return length;
}

void setup_problem() {
    system("chcp 65001 > nul");
    
    display_menu();
    
    int mode;
    printf("  Lua chon cua ban (1 hoac 2): ");
    scanf("%d", &mode);
    
    // Chon do dai
    PASSWORD_LENGTH = select_password_length();
    TOTAL_COMBINATIONS = calculate_combinations(PASSWORD_LENGTH);
    
    // Chon do phuc tap hash
    display_complexity_menu();
    int complexity_choice;
    printf("  Lua chon (1-4): ");
    scanf("%d", &complexity_choice);
    
    switch(complexity_choice) {
        case 1: HASH_COMPLEXITY = 300; break;
        case 2: HASH_COMPLEXITY = 600; break;
        case 3: HASH_COMPLEXITY = 1000; break;
        case 4: HASH_COMPLEXITY = 10000; break;
        default: HASH_COMPLEXITY = 1000;
    }
    
    // Sinh hoac nhap mat khau
    if(mode == 1) {
        generate_random_password(SECRET_PASSWORD, PASSWORD_LENGTH);
        printf("\n  => Mat khau ngau nhien da sinh: %s\n", SECRET_PASSWORD);
    } else {
        printf("\n  Nhap mat khau (chi chu cai HOA A-Z): ");
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
    // Setup bai toan
    setup_problem();
    
    // Hien thi thong tin
    printf("\n");
    printf("================================================================\n");
    printf("  THONG TIN BAI TOAN\n");
    printf("================================================================\n");
    printf("  * Do dai mat khau: %d ky tu\n", PASSWORD_LENGTH);
    printf("  * Khong gian tim kiem: 26^%d = %lld kha nang\n", 
           PASSWORD_LENGTH, TOTAL_COMBINATIONS);
    printf("  * Do phuc tap hash: %d operations/check\n", HASH_COMPLEXITY);
    printf("  * Tong phep toan: ~%.2f ty operations\n", 
           (double)TOTAL_COMBINATIONS * HASH_COMPLEXITY / 1000000000.0);
    printf("  * Mat khau muc tieu: %s\n", SECRET_PASSWORD);
    printf("  * CPU Cores: %d\n", omp_get_max_threads());
    
    // Du doan thoi gian
    double estimated_seq = TOTAL_COMBINATIONS * HASH_COMPLEXITY / 1000000000.0;
    printf("\n  Du doan thoi gian (tuong doi):\n");
    printf("    - Tuan tu:  ~%.1f giay\n", estimated_seq);
    printf("    - OpenMP:   ~%.1f giay (voi %d cores)\n", 
           estimated_seq / omp_get_max_threads() * 2, omp_get_max_threads());
    printf("    - CUDA:     ~%.1f giay\n", estimated_seq / 1000);
    
    // Xac nhan
    printf("\n  Ban co muon tiep tuc? (y/n): ");
    char confirm;
    scanf(" %c", &confirm);
    if(confirm != 'y' && confirm != 'Y') {
        printf("\n  Da huy!\n");
        return 0;
    }
    
    // Tinh hash cua mat khau bi mat
    int secret_hash = complex_hash_cpu(SECRET_PASSWORD, HASH_COMPLEXITY);
    printf("\n  Secret hash: %u\n", secret_hash);
    
    char result1[MAX_PASSWORD_LENGTH + 1], result2[MAX_PASSWORD_LENGTH + 1], 
         result3[MAX_PASSWORD_LENGTH + 1];
    double time1, time2, time3;
    
    printf("\n================================================================\n");
    time1 = brute_force_sequential(result1, secret_hash);
    
    printf("\n================================================================\n");
    time2 = brute_force_openmp(result2, secret_hash);
    
    printf("\n================================================================\n");
    time3 = brute_force_cuda(result3, secret_hash);
    
    // KET QUA
    printf("\n");
    printf("================================================================\n");
    printf("  KET QUA SO SANH\n");
    printf("================================================================\n\n");
    
    printf("  Ket qua:\n");
    printf("    Tuan tu:  %s\n", strlen(result1) > 0 ? result1 : "Khong tim thay");
    printf("    OpenMP:   %s\n", strlen(result2) > 0 ? result2 : "Khong tim thay");
    printf("    CUDA:     %s\n", strlen(result3) > 0 ? result3 : "Khong tim thay");
    printf("    Muc tieu: %s %s\n\n", SECRET_PASSWORD, 
           strcmp(result3, SECRET_PASSWORD) == 0 ? "(DUNG!)" : "(SAI!)");
    
    printf("  THOI GIAN:\n");
    printf("  --------------------------------------------------------\n");
    printf("    Tuan tu (1 CPU)      %10.3f s      1.00x\n", time1);
    printf("    OpenMP (%2d CPUs)     %10.3f s      %.2fx\n", 
           omp_get_max_threads(), time2, time1/time2);
    printf("    CUDA (GPU)           %10.3f s      %.2fx\n", 
           time3, time1/time3);
    printf("  --------------------------------------------------------\n\n");
    
    printf("  >>> CUDA nhanh hon OpenMP: %.2fx\n\n", time2/time3);
    
    // BIEU DO
    printf("  BIEU DO:\n\n");
    int max_bars = 50;
    printf("  Tuan tu:  ");
    for(int i = 0; i < max_bars; i++) printf("#");
    printf(" %.1fs\n", time1);
    
    printf("  OpenMP:   ");
    int bars2 = (int)(max_bars * time2 / time1);
    if(bars2 < 1) bars2 = 1;
    for(int i = 0; i < bars2; i++) printf("#");
    printf(" %.1fs\n", time2);
    
    printf("  CUDA:     ");
    int bars3 = (int)(max_bars * time3 / time1);
    if(bars3 < 1) bars3 = 1;
    for(int i = 0; i < bars3; i++) printf("#");
    printf(" %.1fs\n\n", time3);
    
    printf("================================================================\n\n");
    
    return 0;
}

