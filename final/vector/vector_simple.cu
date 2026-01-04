/*
 * ===================================================================
 * TICH VO HUONG 2 VECTOR - SO SANH DON GIAN
 * Sequential vs OpenMP (khong co CUDA, khong co bieu do)
 * ===================================================================
 * 
 * Compile: nvcc vector_simple.cu -o vector_simple.exe -Xcompiler "/openmp"
 * Run: .\vector_simple.exe
 */

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <omp.h>

// ====================================================================
// CPU VERSION - TUAN TU
// ====================================================================
double dot_product_sequential(double *a, double *b, long long N) {
    double sum = 0.0;
    for(long long i = 0; i < N; i++) {
        sum += a[i] * b[i];
    }
    return sum;
}

// ====================================================================
// CPU VERSION - OPENMP
// ====================================================================
double dot_product_openmp(double *a, double *b, long long N) {
    double sum = 0.0;
    
    #pragma omp parallel for reduction(+:sum)
    for(long long i = 0; i < N; i++) {
        sum += a[i] * b[i];
    }
    
    return sum;
}

// ====================================================================
// MAIN
// ====================================================================
int main() {
    system("chcp 65001 > nul");
    
    printf("\n");
    printf("================================================================\n");
    printf("  TICH VO HUONG 2 VECTOR - Sequential vs OpenMP\n");
    printf("================================================================\n\n");
    
    // Chon kich thuoc
    printf("  Chon kich thuoc vector:\n\n");
    printf("  1. NHO           (1,000)\n");
    printf("  2. TRUNG BINH    (100,000)\n");
    printf("  3. LON           (1,000,000)\n");
    printf("  4. RAT LON       (10,000,000)\n");
    printf("  5. CUC LON       (100,000,000)\n");
    printf("  6. SIEU LON      (1,000,000,000)\n\n");
    
    int choice;
    printf("  Lua chon (1-6): ");
    scanf("%d", &choice);
    
    long long N;
    switch(choice) {
        case 1: N = 1000; break;
        case 2: N = 100000; break;
        case 3: N = 1000000; break;
        case 4: N = 10000000; break;
        case 5: N = 100000000; break;
        case 6: N = 1000000000; break;
        default: N = 1000000;
    }
    
    printf("\n");
    printf("================================================================\n");
    printf("  THONG TIN\n");
    printf("================================================================\n");
    printf("  Kich thuoc vector:  %lld phan tu\n", N);
    printf("  Bo nho can:         %.2f MB\n", 
           (2.0 * N * sizeof(double)) / (1024.0 * 1024.0));
    printf("  CPU Cores:          %d\n", omp_get_max_threads());
    
    printf("\n  Dang khoi tao du lieu...\n");
    
    // Cap phat bo nho
    double *h_a = (double*)malloc(N * sizeof(double));
    double *h_b = (double*)malloc(N * sizeof(double));
    
    if(h_a == NULL || h_b == NULL) {
        printf("\n  Loi: Khong du bo nho!\n");
        return 1;
    }
    
    // Khoi tao vector
    srand(time(NULL));
    for(long long i = 0; i < N; i++) {
        h_a[i] = (double)(rand() % 100) / 10.0;
        h_b[i] = (double)(rand() % 100) / 10.0;
    }
    
    // ================================================================
    // PHUONG PHAP 1: TUAN TU
    // ================================================================
    printf("\n");
    printf("================================================================\n");
    printf("  [1] TUAN TU (Sequential)\n");
    printf("================================================================\n");
    
    printf("  Dang tinh toan...\n");
    double seq_start = omp_get_wtime();
    double result_seq = dot_product_sequential(h_a, h_b, N);
    double seq_time = omp_get_wtime() - seq_start;
    
    printf("  Ket qua:   %.6f\n", result_seq);
    printf("  Thoi gian: %.6f giay\n", seq_time);
    
    // ================================================================
    // PHUONG PHAP 2: OPENMP
    // ================================================================
    printf("\n");
    printf("================================================================\n");
    printf("  [2] SONG SONG (OpenMP)\n");
    printf("================================================================\n");
    
    printf("  So threads: %d\n", omp_get_max_threads());
    printf("  Dang tinh toan...\n");
    
    double omp_start = omp_get_wtime();
    double result_omp = dot_product_openmp(h_a, h_b, N);
    double omp_time = omp_get_wtime() - omp_start;
    
    printf("  Ket qua:   %.6f\n", result_omp);
    printf("  Thoi gian: %.6f giay\n", omp_time);
    
    // ================================================================
    // KET QUA
    // ================================================================
    printf("\n");
    printf("================================================================\n");
    printf("  KET QUA\n");
    printf("================================================================\n\n");
    
    double epsilon = 1e-3;
    int match = fabs(result_seq - result_omp) < epsilon;
    
    if(match) {
        printf("  ✓ Ket qua dung!\n\n");
    } else {
        printf("  ✗ Canh bao: Ket qua khac nhau!\n");
        printf("  Sequential: %.6f\n", result_seq);
        printf("  OpenMP:     %.6f\n\n", result_omp);
    }
    
    double speedup = seq_time / omp_time;
    int num_cores = omp_get_max_threads();
    double efficiency = (speedup / num_cores) * 100.0;
    
    printf("  THOI GIAN:\n");
    printf("  --------------------------------------------------\n");
    printf("    Sequential:  %10.6f giay (baseline)\n", seq_time);
    printf("    OpenMP:      %10.6f giay\n", omp_time);
    printf("  --------------------------------------------------\n\n");
    
    printf("  SPEEDUP:\n");
    printf("  --------------------------------------------------\n");
    printf("    OpenMP nhanh hon:  %.2fx\n", speedup);
    printf("    Efficiency:        %.1f%% (voi %d cores)\n", efficiency, num_cores);
    printf("  --------------------------------------------------\n\n");
    
    printf("  TOC DO:\n");
    printf("  --------------------------------------------------\n");
    printf("    Sequential:  %.2f M ops/s\n", (N * 2.0) / (seq_time * 1e6));
    printf("    OpenMP:      %.2f M ops/s\n", (N * 2.0) / (omp_time * 1e6));
    printf("  --------------------------------------------------\n\n");
    
    printf("  DANH GIA:\n");
    printf("  --------------------------------------------------\n");
    if(efficiency >= 75.0) {
        printf("    ✓✓✓ XUAT SAC! Hieu suat %.1f%%\n", efficiency);
    } else if(efficiency >= 50.0) {
        printf("    ✓✓ RAT TOT! Hieu suat %.1f%%\n", efficiency);
    } else if(efficiency >= 30.0) {
        printf("    ✓ TOT! Hieu suat %.1f%% (Memory-bound)\n", efficiency);
    } else if(efficiency >= 20.0) {
        printf("    ✓ CHAP NHAN! Hieu suat %.1f%%\n", efficiency);
    } else {
        printf("    ⚠ THAP! Hieu suat %.1f%%\n", efficiency);
    }
    printf("    Ly thuyet: %.0fx, Thuc te: %.2fx\n", (double)num_cores, speedup);
    printf("  --------------------------------------------------\n");
    
    // Giai phong bo nho
    free(h_a);
    free(h_b);
    
    printf("\n");
    printf("================================================================\n\n");
    
    return 0;
}

