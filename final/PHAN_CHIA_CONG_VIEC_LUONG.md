# 🔀 PHÂN CHIA CÔNG VIỆC GIỮA CÁC LUỒNG - OPENMP VÀ CUDA

## 📋 Mục Lục
1. [Tổng Quan](#tổng-quan)
2. [OpenMP - Cách Chia Công Việc](#openmp---cách-chia-công-việc)
3. [CUDA - Cách Chia Công Việc](#cuda---cách-chia-công-việc)
4. [Cơ Chế Biết Kết Thúc](#cơ-chế-biết-kết-thúc)
5. [So Sánh Chi Tiết](#so-sánh-chi-tiết)
6. [Ví Dụ Thực Tế](#ví-dụ-thực-tế)

---

## 🎯 Tổng Quan

Khi thực hiện brute force tìm mật khẩu, cả **OpenMP** (CPU) và **CUDA** (GPU) đều sử dụng kỹ thuật song song hóa, nhưng với cách tiếp cận hoàn toàn khác nhau:

```
┌─────────────────────────────────────────────────────────┐
│  BÀI TOÁN: Tìm mật khẩu 4 ký tự (A-Z)                  │
│  Không gian tìm kiếm: 26^4 = 456,976 khả năng          │
└─────────────────────────────────────────────────────────┘
                         │
        ┌────────────────┴────────────────┐
        │                                  │
    OpenMP                              CUDA
  12-16 threads                    ~457,000 threads
  Mỗi thread xử lý                 Mỗi thread xử lý
  nhiều mật khẩu                   1 mật khẩu
```

---

## 🔄 OpenMP - Cách Chia Công Việc

### 📌 Kiến Trúc Phân Chia

OpenMP sử dụng **Work Sharing** - chia không gian tìm kiếm thành các phần và phân cho threads.

```c
#pragma omp parallel
{
    int thread_id = omp_get_thread_num();
    char password[MAX_PASSWORD_LENGTH + 1];
    long long my_tries = 0;
    
    #pragma omp for schedule(dynamic, 5000)
    for(long long idx = 0; idx < TOTAL_COMBINATIONS; idx++) {
        if(found) continue;  // Nếu đã tìm thấy → bỏ qua
        
        my_tries++;
        index_to_password(idx, password, PASSWORD_LENGTH);
        
        if(check_password_cpu(password, secret_hash, HASH_COMPLEXITY)) {
            #pragma omp critical
            {
                if(!found) {
                    strcpy(found_password, password);
                    found = 1;  // Báo hiệu tìm thấy!
                }
            }
        }
    }
}
```

### 🎯 Các Thành Phần Quan Trọng

#### 1. **`#pragma omp parallel`** - Tạo Team of Threads

```
CPU với 12 cores:
┌─────────────────────────────────────────────────┐
│  Thread 0  Thread 1  Thread 2  ...  Thread 11  │
│    Core 0    Core 1    Core 2  ...    Core 11  │
└─────────────────────────────────────────────────┘

Mỗi thread chạy trên 1 CPU core
```

#### 2. **`#pragma omp for schedule(dynamic, 5000)`** - Phân Chia Động

```
STATIC Scheduling (mặc định):
┌────────────────────────────────────────────────┐
│ Thread 0: [0-38081]        (cố định)           │
│ Thread 1: [38082-76163]    (cố định)           │
│ Thread 2: [76164-114245]   (cố định)           │
│ ...                                            │
│ Thread 11: [418895-456976] (cố định)           │
└────────────────────────────────────────────────┘

DYNAMIC Scheduling (dynamic, 5000):
┌────────────────────────────────────────────────┐
│ Thread 0: Lấy chunk [0-4999]                   │
│ Thread 1: Lấy chunk [5000-9999]                │
│ Thread 2: Lấy chunk [10000-14999]              │
│ ...                                            │
│ Thread 0: (Xong) → Lấy chunk [60000-64999]    │
│ Thread 5: (Xong) → Lấy chunk [65000-69999]    │
└────────────────────────────────────────────────┘

Ưu điểm DYNAMIC: Load balancing tốt hơn!
Nếu thread nào xong sớm → lấy việc mới ngay
```

### 📊 Ví Dụ Chi Tiết

**Giả sử:** 456,976 khả năng, 12 threads, chunk size = 5000

```
Ban đầu:
  Thread 0:  [0-4999]         → AAAA - AAJW (5000 passwords)
  Thread 1:  [5000-9999]      → AAJX - AAVS (5000 passwords)
  Thread 2:  [10000-14999]    → AAVT - BAHP (5000 passwords)
  Thread 3:  [15000-19999]    → BAHQ - BAUL (5000 passwords)
  Thread 4:  [20000-24999]    → BAUM - BCGH (5000 passwords)
  Thread 5:  [25000-29999]    → BCGI - BCSD (5000 passwords)
  Thread 6:  [30000-34999]    → BCSE - CDEZ (5000 passwords)
  Thread 7:  [35000-39999]    → CDFA - CDVV (5000 passwords)
  Thread 8:  [40000-44999]    → CDVW - CEHR (5000 passwords)
  Thread 9:  [45000-49999]    → CEHS - CETN (5000 passwords)
  Thread 10: [50000-54999]    → CETO - CFFJ (5000 passwords)
  Thread 11: [55000-59999]    → CFFK - CFRF (5000 passwords)

Sau 2 giây:
  Thread 4:  (Xong chunk đầu) → Lấy [60000-64999]
  Thread 9:  (Xong chunk đầu) → Lấy [65000-69999]
  ...

Thread 7 tìm thấy "HACK" ở index 123,094:
  Thread 7:  Set found = 1
  Threads khác: Thấy found=1 → Dừng xử lý
```

### 🔍 Chi Tiết Cơ Chế Index → Password

```c
void index_to_password(long long index, char* password, int length) {
    // Chuyển đổi số decimal → base-26
    for(int i = length - 1; i >= 0; i--) {
        password[i] = 'A' + (index % 26);
        index /= 26;
    }
    password[length] = '\0';
}

// Ví dụ:
index = 0      → AAAA (0,0,0,0)
index = 1      → AAAB (0,0,0,1)
index = 26     → AABA (0,0,1,0)
index = 676    → ABAA (0,1,0,0)
index = 123094 → HACK (7,0,2,10) = H(7)A(0)C(2)K(10)
index = 456975 → ZZZZ (25,25,25,25)
```

---

## 🎮 CUDA - Cách Chia Công Việc

### 📌 Kiến Trúc Phân Chia

CUDA sử dụng **Massive Parallelism** - mỗi thread chỉ xử lý 1 mật khẩu duy nhất!

```c
__global__ void brute_force_kernel(unsigned int secret_hash, 
                                   long long total, 
                                   int password_length, 
                                   int complexity) {
    // Tính index duy nhất cho thread này
    long long idx = (long long)blockIdx.x * blockDim.x + threadIdx.x;
    
    // Kiểm tra giới hạn
    if (idx >= total) return;
    
    // Nếu đã tìm thấy → thoát ngay
    if (d_found) return;
    
    // Chuyển index thành mật khẩu
    char password[MAX_PASSWORD_LENGTH + 1];
    password[password_length] = '\0';
    
    long long temp = idx;
    for(int i = password_length - 1; i >= 0; i--) {
        password[i] = 'A' + (temp % CHARSET_SIZE);
        temp /= CHARSET_SIZE;
    }
    
    // Kiểm tra mật khẩu này
    if(check_password_gpu(password, secret_hash, complexity, password_length)) {
        // Atomic operation - chỉ 1 thread thành công
        if(atomicCAS(&d_found, 0, 1) == 0) {
            for(int i = 0; i <= password_length; i++) {
                d_found_password[i] = password[i];
            }
        }
    }
}
```

### 🎯 Cấu Trúc Grid-Block-Thread

```
GPU Grid:
┌─────────────────────────────────────────────────────────────┐
│  Block 0 (256 threads)                                       │
│  ┌───┬───┬───┬───┬─────────────┬───┬───┬───┐                │
│  │ 0 │ 1 │ 2 │ 3 │ ... ... ... │253│254│255│                │
│  └───┴───┴───┴───┴─────────────┴───┴───┴───┘                │
│  AAAA AAAB AAAC AAAD ...         AAIX                        │
├─────────────────────────────────────────────────────────────┤
│  Block 1 (256 threads)                                       │
│  ┌───┬───┬───┬───┬─────────────┬───┬───┬───┐                │
│  │ 0 │ 1 │ 2 │ 3 │ ... ... ... │253│254│255│                │
│  └───┴───┴───┴───┴─────────────┴───┴───┴───┘                │
│  AAIY AAIZ AAJA AAJB ...         AAVE                        │
├─────────────────────────────────────────────────────────────┤
│  Block 2 (256 threads)                                       │
│  ...                                                          │
├─────────────────────────────────────────────────────────────┤
│  Block 480 (256 threads) - Chứa "HACK"                       │
│  ┌───┬───┬───┬─────────┬───┬───┬───┐                        │
│  │...│214│215│ ... ... │253│254│255│                        │
│  └───┴───┴───┴─────────┴───┴───┴───┘                        │
│      HACK                                                     │
├─────────────────────────────────────────────────────────────┤
│  ...                                                          │
│  Block 1785 (256 threads) - Block cuối                       │
│  ┌───┬───┬───┬───┬─────────────┬───┬───┬────┐               │
│  │ 0 │ 1 │ 2 │ 3 │ ... ... ... │ 13│ 14│ 15 │               │
│  └───┴───┴───┴───┴─────────────┴───┴───┴────┘               │
│  ZZZK ZZZL ZZZM ZZZN ...         ZZZY ZZZZ                   │
└─────────────────────────────────────────────────────────────┘

Tổng: 1786 blocks × 256 threads/block = 457,216 threads
```

### 📐 Công Thức Tính Index

```c
idx = blockIdx.x * blockDim.x + threadIdx.x
```

**Ví dụ cụ thể:**

| Block | Thread | Công thức | Index | Password |
|-------|--------|-----------|-------|----------|
| 0 | 0 | 0×256 + 0 | 0 | AAAA |
| 0 | 1 | 0×256 + 1 | 1 | AAAB |
| 0 | 255 | 0×256 + 255 | 255 | AAIX |
| 1 | 0 | 1×256 + 0 | 256 | AAIY |
| 1 | 1 | 1×256 + 1 | 257 | AAIZ |
| 480 | 214 | 480×256 + 214 | 123,094 | **HACK** ← Tìm thấy! |
| 1785 | 0 | 1785×256 + 0 | 456,960 | ZZZK |
| 1785 | 15 | 1785×256 + 15 | 456,975 | ZZZZ |

### 🚀 Cấu Hình Kernel

```c
// Host code (CPU)
int threadsPerBlock = 256;
long long blocksPerGrid = (TOTAL_COMBINATIONS + threadsPerBlock - 1) / threadsPerBlock;
// blocksPerGrid = (456976 + 255) / 256 = 1786

brute_force_kernel<<<blocksPerGrid, threadsPerBlock>>>(
    secret_hash, TOTAL_COMBINATIONS, PASSWORD_LENGTH, HASH_COMPLEXITY
);
```

**Giải thích:**
- `<<<blocksPerGrid, threadsPerBlock>>>`: Cú pháp launch kernel
- `blocksPerGrid = 1786`: Số blocks trong grid
- `threadsPerBlock = 256`: Số threads trong mỗi block
- Tổng threads = 1786 × 256 = 457,216 threads

---

## 🛑 Cơ Chế Biết Kết Thúc

### 🔹 OpenMP - Sử Dụng Flag + Critical Section

#### Code:

```c
int found = 0;  // Biến flag chung

#pragma omp parallel
{
    #pragma omp for
    for(long long idx = 0; idx < TOTAL_COMBINATIONS; idx++) {
        // Kiểm tra flag trước khi xử lý
        if(found) continue;
        
        // Xử lý...
        if(tìm_thấy) {
            #pragma omp critical  // Vùng tới hạn
            {
                if(!found) {  // Double-check
                    found = 1;
                    // Lưu kết quả
                }
            }
        }
    }
}
// Sau khi thoát parallel region → tất cả threads đã join
```

#### Timeline Chi Tiết:

```
Time 0.000s:
  ┌─────────────────────────────────────────────────┐
  │ Thread 0,1,2,...,11 bắt đầu song song          │
  │ found = 0                                       │
  └─────────────────────────────────────────────────┘

Time 1.523s:
  ┌─────────────────────────────────────────────────┐
  │ Thread 7: Tìm thấy "HACK" ở index 123,094      │
  │ Thread 7: Vào critical section                  │
  │ Thread 7: Kiểm tra found == 0 → TRUE           │
  │ Thread 7: Set found = 1                         │
  │ Thread 7: Lưu "HACK" vào found_password        │
  │ Thread 7: Thoát critical section                │
  └─────────────────────────────────────────────────┘

Time 1.524s:
  ┌─────────────────────────────────────────────────┐
  │ Thread 0: Kiểm tra found == 1 → continue       │
  │ Thread 1: Kiểm tra found == 1 → continue       │
  │ Thread 2: Kiểm tra found == 1 → continue       │
  │ ...                                             │
  │ Thread 11: Kiểm tra found == 1 → continue      │
  └─────────────────────────────────────────────────┘

Time 2.845s:
  ┌─────────────────────────────────────────────────┐
  │ Tất cả threads đã xử lý hết chunks của mình    │
  │ Tất cả threads thoát vòng lặp                   │
  │ Barrier tự động → Join tất cả threads           │
  │ KẾT THÚC                                        │
  └─────────────────────────────────────────────────┘
```

#### Giải Thích Critical Section:

```
#pragma omp critical
{
    // CHỈ 1 thread vào cùng lúc
    if(!found) {
        found = 1;
        strcpy(found_password, password);
    }
}

Tại sao cần critical?
┌─────────────────────────────────────────────────┐
│ KHÔNG có critical (RACE CONDITION):             │
│                                                  │
│ Thread 7: Đọc found=0                           │
│ Thread 9: Đọc found=0 (cùng lúc!)              │
│ Thread 7: Ghi found=1, lưu "HACK"              │
│ Thread 9: Ghi found=1, lưu "XXXX" (GHI ĐÈ!)   │
│ → KẾT QUẢ SAI!                                  │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ CÓ critical (AN TOÀN):                          │
│                                                  │
│ Thread 7: Vào critical, lock                    │
│ Thread 9: Chờ ở cửa critical                    │
│ Thread 7: Kiểm tra found=0, set=1, lưu "HACK"  │
│ Thread 7: Thoát critical, unlock                │
│ Thread 9: Vào critical                           │
│ Thread 9: Kiểm tra found=1 → KHÔNG làm gì      │
│ Thread 9: Thoát critical                         │
│ → KẾT QUẢ ĐÚNG!                                 │
└─────────────────────────────────────────────────┘
```

---

### 🔹 CUDA - Sử Dụng Atomic Operation

#### Code:

```c
__device__ int d_found = 0;  // Biến global trên GPU
__device__ char d_found_password[9];

__global__ void brute_force_kernel(...) {
    long long idx = blockIdx.x * blockDim.x + threadIdx.x;
    
    // Early exit nếu đã tìm thấy
    if (d_found) return;
    
    // Xử lý...
    if(tìm_thấy) {
        // Atomic Compare-And-Swap
        if(atomicCAS(&d_found, 0, 1) == 0) {
            // Chỉ thread ĐẦU TIÊN vào đây!
            for(int i = 0; i <= password_length; i++) {
                d_found_password[i] = password[i];
            }
        }
    }
}

// Host code
cudaDeviceSynchronize();  // Đợi TẤT CẢ threads GPU
cudaMemcpyFromSymbol(&found, d_found, sizeof(int));
```

#### Giải Thích `atomicCAS`:

```c
atomicCAS(&d_found, 0, 1)
// Compare-And-Swap (CAS)

Cơ chế:
  1. So sánh d_found với 0
  2. Nếu d_found == 0:
     - Set d_found = 1
     - Return 0 (giá trị cũ)
  3. Nếu d_found != 0:
     - KHÔNG thay đổi gì
     - Return giá trị hiện tại của d_found

Đặc điểm: ATOMIC (không thể bị gián đoạn)
```

#### Timeline Chi Tiết:

```
Time 0.000s:
  ┌─────────────────────────────────────────────────┐
  │ 457,216 threads khởi động ĐỒNG THỜI             │
  │ d_found = 0                                      │
  └─────────────────────────────────────────────────┘

Time 0.015s:
  ┌─────────────────────────────────────────────────┐
  │ Thread 123,094: Tìm thấy "HACK"!                │
  │ Thread 123,094: Gọi atomicCAS(&d_found, 0, 1)  │
  │ Thread 123,094: d_found==0 → Set=1, return 0   │
  │ Thread 123,094: Vào if → Lưu "HACK"            │
  └─────────────────────────────────────────────────┘

Time 0.016s:
  ┌─────────────────────────────────────────────────┐
  │ Thread 200,000: Cũng tìm thấy (do data khác)   │
  │ Thread 200,000: Gọi atomicCAS(&d_found, 0, 1)  │
  │ Thread 200,000: d_found==1 → return 1           │
  │ Thread 200,000: KHÔNG vào if                    │
  └─────────────────────────────────────────────────┘

Time 0.017s - 0.019s:
  ┌─────────────────────────────────────────────────┐
  │ Các threads khác: Kiểm tra if(d_found) → return│
  │ Tất cả threads thoát kernel                     │
  └─────────────────────────────────────────────────┘

Time 0.019s:
  ┌─────────────────────────────────────────────────┐
  │ cudaDeviceSynchronize() hoàn thành              │
  │ Copy kết quả từ GPU → CPU                       │
  │ KẾT THÚC                                         │
  └─────────────────────────────────────────────────┘
```

#### Tại Sao Cần Atomic?

```
┌─────────────────────────────────────────────────┐
│ KHÔNG có atomic (RACE CONDITION trên GPU):      │
│                                                  │
│ Time T:                                          │
│   Thread A: Đọc d_found = 0                     │
│   Thread B: Đọc d_found = 0 (cùng lúc!)        │
│                                                  │
│ Time T+1:                                        │
│   Thread A: Ghi d_found = 1                     │
│   Thread B: Ghi d_found = 1 (cùng lúc!)        │
│                                                  │
│ Time T+2:                                        │
│   Thread A: Ghi password[0] = 'H'               │
│   Thread B: Ghi password[0] = 'X' (GHI ĐÈ!)    │
│   Thread A: Ghi password[1] = 'A'               │
│   Thread B: Ghi password[1] = 'Y' (GHI ĐÈ!)    │
│   → KẾT QUẢ BỊ LỆCH: "XYHK" hoặc rác           │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ CÓ atomicCAS (AN TOÀN):                         │
│                                                  │
│ Time T:                                          │
│   Thread A: atomicCAS(&d_found, 0, 1)           │
│     → Hardware lock, đọc 0, ghi 1, return 0     │
│   Thread B: atomicCAS(&d_found, 0, 1) - CHỜ!   │
│                                                  │
│ Time T+1:                                        │
│   Thread A: return 0 → Vào if → Lưu "HACK"     │
│   Thread B: atomicCAS hoàn thành, return 1      │
│     → KHÔNG vào if                               │
│                                                  │
│ → KẾT QUẢ ĐÚNG: "HACK"                          │
└─────────────────────────────────────────────────┘
```

---

## ⚖️ So Sánh Chi Tiết

### 📊 Bảng So Sánh Tổng Quan

| Tiêu Chí | OpenMP (CPU) | CUDA (GPU) |
|----------|--------------|------------|
| **Số lượng threads** | 12-16 threads | ~457,000 threads |
| **Kiến trúc** | Multi-core CPU | Thousands of cores |
| **Công việc/thread** | Hàng nghìn passwords | 1 password |
| **Phân chia công việc** | Dynamic/Static scheduling | Index cố định |
| **Cơ chế kết thúc** | `found` flag + critical | `atomicCAS` + `d_found` |
| **Đồng bộ** | Implicit barrier | `cudaDeviceSynchronize()` |
| **Memory** | Shared memory | Global memory (GPU) |
| **Overhead** | Thấp | Cao (CPU↔GPU transfer) |
| **Tốc độ (thực tế)** | 4-6x nhanh hơn tuần tự | 100-1000x nhanh hơn tuần tự |
| **Phù hợp** | Bài toán vừa/nhỏ | Bài toán lớn/cực lớn |
| **Độ phức tạp code** | Đơn giản | Phức tạp hơn |

### 🔄 Workflow So Sánh

```
┌─────────────────────────────────────────────────────────────┐
│                         OPENMP                               │
├─────────────────────────────────────────────────────────────┤
│ 1. Tạo 12 threads                                            │
│ 2. Chia 456,976 khả năng thành chunks (5000/chunk)          │
│ 3. Mỗi thread lấy chunk, xử lý tuần tự trong chunk          │
│ 4. Thread tìm thấy → Set found=1 (critical section)         │
│ 5. Threads khác thấy found=1 → Bỏ qua chunks còn lại       │
│ 6. Tất cả threads về barrier → Join → Kết thúc              │
│                                                              │
│ Thời gian: ~3 giây                                           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                          CUDA                                │
├─────────────────────────────────────────────────────────────┤
│ 1. Tạo 457,216 threads (1786 blocks × 256 threads/block)   │
│ 2. MỖI thread xử lý ĐÚNG 1 password dựa trên index của nó  │
│ 3. Thread tìm thấy → atomicCAS(&d_found, 0, 1)             │
│ 4. Threads khác thấy d_found=1 → Return ngay                │
│ 5. cudaDeviceSynchronize() → Đợi tất cả threads             │
│ 6. Copy kết quả GPU → CPU → Kết thúc                        │
│                                                              │
│ Thời gian: ~0.019 giây                                       │
└─────────────────────────────────────────────────────────────┘
```

### 📈 Hiệu Suất Thực Tế

**Test case: Mật khẩu 4 ký tự, hash complexity = 10,000**

```
┌──────────────┬─────────────┬──────────────┬──────────────┐
│  Phương pháp │  Thời gian  │   Speedup    │  Tries/giây  │
├──────────────┼─────────────┼──────────────┼──────────────┤
│  Tuần tự     │  18.11 s    │    1.00x     │    6,800     │
│  OpenMP      │   3.23 s    │    5.61x     │   47,000     │
│  CUDA        │   0.019 s   │  953.68x     │ 23,500,000   │
└──────────────┴─────────────┴──────────────┴──────────────┘

Visualization:
Tuần tự:  ██████████████████████████████████████████████████ 18.11s
OpenMP:   █████████ 3.23s
CUDA:     █ 0.019s

CUDA nhanh hơn OpenMP: ~170 lần!
CUDA nhanh hơn Tuần tự: ~950 lần!
```

---

## 🎓 Ví Dụ Thực Tế

### 📝 Case Study: Tìm Mật Khẩu "HACK"

#### Setup:
```
Mật khẩu: "HACK"
Index của "HACK": 123,094
Độ dài: 4 ký tự
Không gian: 26^4 = 456,976 khả năng
Hash complexity: 10,000 operations/check
```

#### Phương Pháp 1 - Tuần Tự:

```
Thread duy nhất thử tuần tự:
  idx=0      → "AAAA" → hash=98765432  ≠ secret_hash ✗
  idx=1      → "AAAB" → hash=12345678  ≠ secret_hash ✗
  idx=2      → "AAAC" → hash=87654321  ≠ secret_hash ✗
  ...
  idx=123093 → "HACJ" → hash=11111111  ≠ secret_hash ✗
  idx=123094 → "HACK" → hash=435596469 = secret_hash ✓

Kết quả:
  ✓ Tìm thấy sau: 123,095 lần thử
  ⏱ Thời gian: 18.11 giây
  🚀 Tốc độ: 6,797 tries/giây
```

#### Phương Pháp 2 - OpenMP:

```
12 threads chạy song song (chunk size = 5000):

Thread 0:  [0-4999]         AAAA-AAJW
Thread 1:  [5000-9999]      AAJX-AAVS
Thread 2:  [10000-14999]    AAVT-BAHP
Thread 3:  [15000-19999]    BAHQ-BAUL
Thread 4:  [20000-24999]    BAUM-BCGH
Thread 5:  [25000-29999]    BCGI-BCSD
Thread 6:  [30000-34999]    BCSE-CDEZ
Thread 7:  [35000-39999]    CDFA-CDVV
Thread 8:  [40000-44999]    CDVW-CEHR
Thread 9:  [45000-49999]    CEHS-CETN
Thread 10: [50000-54999]    CETO-CFFJ
Thread 11: [55000-59999]    CFFK-CFRF

Sau 1.5 giây, một số threads xong và lấy chunks mới:
Thread 4:  [60000-64999]    ...
Thread 9:  [65000-69999]    ...
...

Thread 7 (đang xử lý chunk thứ 5):
  [120000-124999]
  idx=123094 → "HACK" → hash=435596469 = secret_hash ✓
  
Thread 7 vào critical section:
  found = 1
  found_password = "HACK"
  
Các threads khác:
  Kiểm tra found == 1 → continue (bỏ qua)
  
Kết quả:
  ✓ Thread 7 tìm thấy: "HACK"
  ⏱ Thời gian: 3.23 giây
  🚀 Speedup: 5.61x
  📊 Tổng tries: ~150,000 (một số threads đã dừng sớm)
```

#### Phương Pháp 3 - CUDA:

```
457,216 threads chạy ĐỒNG THỜI trên GPU:

Block 0:
  Thread 0:   idx=0      → "AAAA" (kiểm tra...)
  Thread 1:   idx=1      → "AAAB" (kiểm tra...)
  ...
  Thread 255: idx=255    → "AAIX" (kiểm tra...)

Block 1:
  Thread 0:   idx=256    → "AAIY" (kiểm tra...)
  Thread 1:   idx=257    → "AAIZ" (kiểm tra...)
  ...

Block 480:
  Thread 0:   idx=122880 → "HABS" (kiểm tra...)
  ...
  Thread 214: idx=123094 → "HACK" (kiểm tra...)
    → check_password_gpu() return TRUE!
    → atomicCAS(&d_found, 0, 1)
    → d_found == 0, set d_found = 1, return 0
    → Vào if → Lưu "HACK" vào d_found_password
  Thread 215: idx=123095 → "HACL" (kiểm tra...)
  ...

Block 481-1785:
  Các threads kiểm tra d_found == 1 → return

cudaDeviceSynchronize() → Đợi tất cả threads
cudaMemcpyFromSymbol() → Copy kết quả về CPU

Kết quả:
  ✓ GPU tìm thấy: "HACK"
  ⏱ Thời gian: 0.019 giây
  🚀 Speedup: 953.68x
  🔥 Tốc độ: 23.5 triệu tries/giây
```

---

## 💡 Tóm Tắt Quan Trọng

### 🎯 OpenMP

```
✅ ƯU ĐIỂM:
  • Code đơn giản (chỉ thêm #pragma)
  • Không cần GPU
  • Tự động load balancing (dynamic scheduling)
  • Phù hợp bài toán vừa và nhỏ
  • Dễ debug

❌ NHƯỢC ĐIỂM:
  • Giới hạn số threads (~12-16)
  • Không thể scale lớn
  • Chậm hơn CUDA rất nhiều cho bài toán lớn
```

### 🎮 CUDA

```
✅ ƯU ĐIỂM:
  • CỰC NHANH (100-1000x)
  • Hàng nghìn threads đồng thời
  • Phù hợp bài toán cực lớn
  • Scalable (GPU mạnh hơn → nhanh hơn)

❌ NHƯỢC ĐIỂM:
  • Code phức tạp
  • Cần GPU NVIDIA + CUDA Toolkit
  • Overhead lớn (memory transfer CPU↔GPU)
  • Khó debug
  • Không phù hợp bài toán nhỏ
```

### 🔑 Kết Thúc

**OpenMP:**
- Dùng biến `found` (shared)
- Critical section đảm bảo chỉ 1 thread ghi
- Threads tự động join khi hết vòng lặp

**CUDA:**
- Dùng `atomicCAS` (atomic operation)
- Đảm bảo chỉ thread đầu tiên ghi được
- `cudaDeviceSynchronize()` đợi tất cả threads

---

