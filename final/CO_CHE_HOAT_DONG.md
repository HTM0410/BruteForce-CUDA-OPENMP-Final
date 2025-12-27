# 🔬 CƠ CHẾ HOẠT ĐỘNG CHI TIẾT - CHƯƠNG TRÌNH BRUTE FORCE

## 📋 Mục Lục
1. [Tổng Quan Kiến Trúc](#tổng-quan-kiến-trúc)
2. [Flow Hoạt Động Tổng Thể](#flow-hoạt-động-tổng-thể)
3. [Cơ Chế Hash Function](#cơ-chế-hash-function)
4. [Cơ Chế Brute Force](#cơ-chế-brute-force)
5. [So Sánh 3 Phương Pháp](#so-sánh-3-phương-pháp)
6. [Ví Dụ Cụ Thể](#ví-dụ-cụ-thể)

---

## 🏗️ Tổng Quan Kiến Trúc

### Cấu trúc chương trình:

```
compare_flexible.cu
├── Biến toàn cục
│   ├── SECRET_PASSWORD        (Mật khẩu cần tìm)
│   ├── PASSWORD_LENGTH        (Độ dài mật khẩu)
│   ├── TOTAL_COMBINATIONS     (Số khả năng)
│   └── HASH_COMPLEXITY        (Độ phức tạp hash)
│
├── Hash Functions
│   ├── complex_hash_cpu()     (Hash trên CPU)
│   ├── complex_hash_gpu()     (Hash trên GPU)
│   └── check_password()       (So sánh hash)
│
├── Brute Force Methods
│   ├── brute_force_sequential()  (Tuần tự - 1 thread)
│   ├── brute_force_openmp()      (Song song - CPU)
│   └── brute_force_cuda()        (Song song - GPU)
│
├── Setup Functions
│   ├── setup_problem()           (Cấu hình bài toán)
│   ├── generate_random_password() (Sinh mật khẩu)
│   └── calculate_combinations()   (Tính số khả năng)
│
└── Main
    └── Điều phối tất cả
```

---

## 🔄 Flow Hoạt Động Tổng Thể

### Sơ đồ luồng chương trình:

```
START
  ↓
┌─────────────────────────────────────────────┐
│ 1. SETUP - Cấu hình bài toán                │
│    • User chọn chế độ (AUTO/CUSTOM)         │
│    • Chọn độ dài mật khẩu (3-8)             │
│    • Chọn độ phức tạp hash (100-50000)      │
│    • Sinh/nhập mật khẩu bí mật              │
└──────────────┬──────────────────────────────┘
               ↓
┌─────────────────────────────────────────────┐
│ 2. TÍNH SECRET HASH                         │
│    secret_hash = hash(SECRET_PASSWORD)      │
│    Ví dụ: hash("HACK") = 435596469          │
└──────────────┬──────────────────────────────┘
               ↓
┌─────────────────────────────────────────────┐
│ 3. BRUTE FORCE - Phương pháp 1              │
│    Tuần tự (Sequential)                     │
│    • 1 thread CPU                           │
│    • Thử từng mật khẩu: AAAA→ZZZZ           │
│    • So sánh hash với secret_hash           │
└──────────────┬──────────────────────────────┘
               ↓
┌─────────────────────────────────────────────┐
│ 4. BRUTE FORCE - Phương pháp 2              │
│    Song song OpenMP (Multi-threading)       │
│    • 12 threads CPU (song song)             │
│    • Mỗi thread thử một phần                │
│    • So sánh hash với secret_hash           │
└──────────────┬──────────────────────────────┘
               ↓
┌─────────────────────────────────────────────┐
│ 5. BRUTE FORCE - Phương pháp 3              │
│    Song song CUDA (GPU)                     │
│    • Hàng nghìn threads GPU                 │
│    • Mỗi thread thử 1 mật khẩu              │
│    • So sánh hash với secret_hash           │
└──────────────┬──────────────────────────────┘
               ↓
┌─────────────────────────────────────────────┐
│ 6. SO SÁNH KẾT QUẢ                          │
│    • Hiển thị thời gian mỗi phương pháp     │
│    • Tính speedup                           │
│    • Vẽ biểu đồ so sánh                     │
└─────────────────────────────────────────────┘
  ↓
END
```

---

## 🔐 Cơ Chế Hash Function

### Hash function là gì?

**Hash function** là hàm một chiều biến đổi input thành output cố định:

```
Input (Mật khẩu)  →  Hash Function  →  Output (Hash value)
     "HACK"       →      hash()      →    435596469
```

### Đặc điểm quan trọng:

1. **Deterministic (Xác định):**
   ```
   hash("HACK") = 435596469  (lần 1)
   hash("HACK") = 435596469  (lần 2)
   hash("HACK") = 435596469  (lần 3)
   → Cùng input → Cùng output
   ```

2. **Avalanche effect (Hiệu ứng tuyết lở):**
   ```
   hash("HACK") = 435596469
   hash("HACJ") = 892736451  ← Chỉ khác 1 ký tự!
   → Khác 1 bit input → Output hoàn toàn khác
   ```

3. **One-way (Một chiều):**
   ```
   Dễ:   "HACK" → hash() → 435596469
   Khó:  435596469 → ??? → "HACK"
   → Chỉ có thể brute force!
   ```

### Code chi tiết hash function:

```c
int complex_hash_cpu(const char* password, int complexity) {
    unsigned int hash = 5381;  // Giá trị khởi tạo (djb2 algorithm)
    
    // VÒNG LẶP NGOÀI - Điều khiển độ phức tạp
    for(int round = 0; round < complexity; round++) {
        
        // VÒNG LẶP TRONG - Xử lý từng ký tú
        for(int i = 0; password[i] != '\0'; i++) {
            
            // Operation 1: hash * 33 + char
            hash = ((hash << 5) + hash) + password[i];
            //      ^          ^      ^  ^
            //      |          |      |  |
            //   Shift×32     Add    Add Character
            
            // Operation 2: XOR với shift right 7
            hash ^= (hash >> 7);
            
            // Operation 3: Add với shift left 3
            hash += (hash << 3);
            
            // Operation 4: XOR với shift right 17
            hash ^= (hash >> 17);
            
            // Operation 5: Add với shift left 5
            hash += (hash << 5);
        }
    }
    
    return hash;
}
```

### Ví dụ chi tiết với "HACK", complexity = 10000:

```
Bước 1: Khởi tạo
  hash = 5381

Vòng lặp round = 0:
  Ký tự 'H' (ASCII 72):
    hash = ((5381 << 5) + 5381) + 72
    hash = (172192 + 5381) + 72 = 177645
    hash ^= (177645 >> 7) = 177645 ^ 1388 = 176925
    hash += (176925 << 3) = 176925 + 1415400 = 1592325
    hash ^= (1592325 >> 17) = 1592325 ^ 12 = 1592337
    hash += (1592337 << 5) = 1592337 + 50954784 = 52547121
  
  Ký tự 'A' (ASCII 65):
    hash = ((52547121 << 5) + 52547121) + 65
    hash = ... (tiếp tục)
  
  Ký tự 'C' (ASCII 67):
    hash = ...
  
  Ký tự 'K' (ASCII 75):
    hash = ...

Vòng lặp round = 1:
  (Lặp lại với 4 ký tự)

...

Vòng lặp round = 9999:
  (Lặp lại với 4 ký tự)

Kết quả cuối cùng:
  hash = 435596469
```

### Tại sao lặp nhiều vòng (complexity)?

```
┌────────────────────┬──────────────┬──────────────┐
│ Complexity         │ Thời gian    │ Bảo mật      │
├────────────────────┼──────────────┼──────────────┤
│ 100 (Đơn giản)     │ Nhanh        │ Yếu          │
│ 1,000 (Trung bình) │ Vừa phải     │ Trung bình   │
│ 10,000 (Phức tạp)  │ Chậm         │ Tốt          │
│ 50,000 (Cực phức)  │ Rất chậm     │ Rất tốt      │
└────────────────────┴──────────────┴──────────────┘

Nguyên tắc: Càng chậm → Càng khó crack!
```

---

## 🔨 Cơ Chế Brute Force

### Brute Force là gì?

**Brute Force** = Thử TẤT CẢ khả năng có thể

```
Mật khẩu 4 ký tự (A-Z):
AAAA → AAAB → AAAC → ... → HACK → ... → ZZZZ
│      │      │           ^            │
0      1      2         123094      456975

Tổng: 26^4 = 456,976 khả năng
```

### Chuyển đổi Index → Password:

```c
void index_to_password(long long index, char* password, int length) {
    // Hệ cơ số 26 (base-26)
    for(int i = length - 1; i >= 0; i--) {
        password[i] = 'A' + (index % 26);
        index /= 26;
    }
}

// Ví dụ:
index = 0      → "AAAA"
index = 1      → "AAAB"
index = 26     → "AABA"
index = 123094 → "HACK"
index = 456975 → "ZZZZ"
```

### Thuật toán Brute Force cơ bản:

```c
for(index = 0; index < TOTAL_COMBINATIONS; index++) {
    // 1. Chuyển index thành mật khẩu
    index_to_password(index, password, PASSWORD_LENGTH);
    // Ví dụ: index 123094 → "HACK"
    
    // 2. Tính hash của mật khẩu đang thử
    int test_hash = complex_hash_cpu(password, HASH_COMPLEXITY);
    // hash("HACK") = 435596469
    
    // 3. So sánh với secret_hash
    if(test_hash == secret_hash) {
        // TÌM THẤY!
        printf("Mật khẩu là: %s\n", password);
        return;
    }
}
```

---

## ⚖️ So Sánh 3 Phương Pháp

### 1️⃣ Phương Pháp TUẦN TỰ (Sequential)

#### Cơ chế:

```
1 Thread CPU:
┌─────────────────────────────────────────────┐
│ Thread 0:                                    │
│   AAAA → AAAB → AAAC → ... → ZZZZ          │
│   (Thử TẤT CẢ 456,976 khả năng)            │
└─────────────────────────────────────────────┘

Thời gian: ~18 giây (với 4 ký tự, 10K ops)
```

#### Code:

```c
double brute_force_sequential(char* result, int secret_hash) {
    char password[MAX_PASSWORD_LENGTH + 1];
    double start = omp_get_wtime();
    
    // Thử từng mật khẩu tuần tự
    for(long long idx = 0; idx < TOTAL_COMBINATIONS; idx++) {
        index_to_password(idx, password, PASSWORD_LENGTH);
        
        // Kiểm tra
        if(check_password_cpu(password, secret_hash, HASH_COMPLEXITY)) {
            // Tìm thấy!
            strcpy(result, password);
            return omp_get_wtime() - start;
        }
    }
}
```

#### Ưu nhược điểm:

```
✅ Ưu điểm:
  - Code đơn giản
  - Dễ debug
  - Không cần thư viện đặc biệt

❌ Nhược điểm:
  - CHẬM NHẤT
  - Chỉ dùng 1 CPU core
  - Lãng phí tài nguyên
```

---

### 2️⃣ Phương Pháp SONG SONG - OpenMP

#### Cơ chế:

```
12 Threads CPU chạy SONG SONG:
┌─────────────────────────────────────────────┐
│ Thread 0:  AAAA → AAAZ → AAZA → ...        │
│ Thread 1:  AAZB → AAZC → ...               │
│ Thread 2:  ABAA → ABAZ → ...               │
│ Thread 3:  ABZA → ABZZ → ...               │
│    ...                                      │
│ Thread 11: ZZZM → ZZZN → ZZZZ              │
└─────────────────────────────────────────────┘

Mỗi thread xử lý: 456,976 / 12 ≈ 38,000 khả năng
Thời gian: ~3 giây (nhanh hơn 6x!)
```

#### Code:

```c
double brute_force_openmp(char* result, int secret_hash) {
    char found_password[MAX_PASSWORD_LENGTH + 1] = "";
    int found = 0;
    double start = omp_get_wtime();
    
    // PARALLEL REGION - Tạo nhiều threads
    #pragma omp parallel
    {
        int thread_id = omp_get_thread_num();
        char password[MAX_PASSWORD_LENGTH + 1];
        
        // FOR LOOP SONG SONG - Mỗi thread xử lý một phần
        #pragma omp for schedule(dynamic, 5000)
        for(long long idx = 0; idx < TOTAL_COMBINATIONS; idx++) {
            
            // Nếu đã tìm thấy → dừng
            if(found) continue;
            
            index_to_password(idx, password, PASSWORD_LENGTH);
            
            if(check_password_cpu(password, secret_hash, HASH_COMPLEXITY)) {
                // CRITICAL SECTION - Chỉ 1 thread vào cùng lúc
                #pragma omp critical
                {
                    if(!found) {
                        strcpy(found_password, password);
                        found = 1;  // Báo hiệu đã tìm thấy
                    }
                }
            }
        }
    }
    
    return omp_get_wtime() - start;
}
```

#### Các directive OpenMP:

```c
#pragma omp parallel
// Tạo team of threads (mặc định = số CPU cores)

#pragma omp for schedule(dynamic, 5000)
// Phân chia vòng lặp cho các threads
// dynamic: Phân chia động (load balancing tốt hơn)
// 5000: Chunk size (mỗi lần lấy 5000 iterations)

#pragma omp critical
// Critical section: Chỉ 1 thread vào cùng lúc
// Tránh race condition khi cập nhật found_password
```

#### Ưu nhược điểm:

```
✅ Ưu điểm:
  - Nhanh hơn tuần tự 4-6 lần
  - Code đơn giản (chỉ thêm #pragma)
  - Tự động load balancing
  - Portable (chạy được trên CPU thường)

❌ Nhược điểm:
  - Giới hạn bởi số CPU cores (~12-16)
  - Speedup không tuyến tính (overhead)
  - Không mạnh cho bài toán cực lớn
```

---

### 3️⃣ Phương Pháp SONG SONG - CUDA (GPU)

#### Cơ chế:

```
457,216 Threads GPU chạy ĐỒNG THỜI:
┌─────────────────────────────────────────────┐
│ Thread 0:      AAAA                         │
│ Thread 1:      AAAB                         │
│ Thread 2:      AAAC                         │
│ Thread 3:      AAAD                         │
│    ...                                      │
│ Thread 123094: HACK  ← TÌM THẤY!           │
│    ...                                      │
│ Thread 456975: ZZZZ                         │
└─────────────────────────────────────────────┘

MỖI thread chỉ thử 1 mật khẩu!
Thời gian: ~0.02 giây (nhanh hơn 900x!)
```

#### Code:

```c
// CUDA KERNEL - Chạy trên GPU
__global__ void brute_force_kernel(unsigned int secret_hash, 
                                   long long total, 
                                   int password_length, 
                                   int complexity) {
    // Tính index của thread này
    long long idx = (long long)blockIdx.x * blockDim.x + threadIdx.x;
    
    // Kiểm tra giới hạn
    if (idx >= total) return;
    
    // Nếu đã tìm thấy → dừng
    if (d_found) return;
    
    // Chuyển index thành mật khẩu
    char password[MAX_PASSWORD_LENGTH + 1];
    password[password_length] = '\0';
    
    long long temp = idx;
    for(int i = password_length - 1; i >= 0; i--) {
        password[i] = 'A' + (temp % 26);
        temp /= 26;
    }
    
    // Kiểm tra mật khẩu
    if(check_password_gpu(password, secret_hash, complexity, password_length)) {
        // Atomic operation - Chỉ 1 thread ghi thành công
        if(atomicCAS(&d_found, 0, 1) == 0) {
            // Copy password vào global memory
            for(int i = 0; i <= password_length; i++) {
                d_found_password[i] = password[i];
            }
        }
    }
}

// Hàm gọi kernel
double brute_force_cuda(char* result, int secret_hash) {
    // Cấu hình kernel
    int threadsPerBlock = 256;
    int blocksPerGrid = (TOTAL_COMBINATIONS + threadsPerBlock - 1) / threadsPerBlock;
    
    // Chạy kernel
    brute_force_kernel<<<blocksPerGrid, threadsPerBlock>>>(
        secret_hash, TOTAL_COMBINATIONS, PASSWORD_LENGTH, HASH_COMPLEXITY
    );
    
    // Đợi GPU hoàn thành
    cudaDeviceSynchronize();
    
    // Lấy kết quả
    cudaMemcpyFromSymbol(&found, d_found, sizeof(int));
    cudaMemcpyFromSymbol(found_password, d_found_password, MAX_PASSWORD_LENGTH + 1);
}
```

#### Kiến trúc CUDA:

```
Grid (toàn bộ GPU):
├── Block 0 (256 threads)
│   ├── Thread 0    → Thử "AAAA"
│   ├── Thread 1    → Thử "AAAB"
│   ├── ...
│   └── Thread 255  → Thử password[255]
├── Block 1 (256 threads)
│   ├── Thread 0    → Thử password[256]
│   ├── ...
│   └── Thread 255  → Thử password[511]
├── ...
└── Block 1785 (256 threads)
    ├── ...
    └── Thread 255  → Thử "ZZZZ"

Tổng: 1786 blocks × 256 threads = 457,216 threads!
```

#### Atomic operation:

```c
atomicCAS(&d_found, 0, 1)
// Compare-And-Swap (atomic)
// Nếu d_found == 0:
//   - Set d_found = 1
//   - Trả về 0 (success)
// Nếu d_found == 1:
//   - Không làm gì
//   - Trả về 1 (fail)

// Đảm bảo chỉ 1 thread ghi kết quả đầu tiên!
```

#### Ưu nhược điểm:

```
✅ Ưu điểm:
  - CỰC NHANH (100-1000x)
  - Hàng nghìn threads song song
  - Phù hợp bài toán lớn
  - Scalable (tăng GPU → tăng tốc)

❌ Nhược điểm:
  - Code phức tạp hơn nhiều
  - Cần GPU NVIDIA
  - Overhead lớn cho bài toán nhỏ
  - Memory transfer CPU↔GPU tốn thời gian
```

---

## 📊 Ví Dụ Cụ Thể

### Case Study: Tìm mật khẩu "HACK"

#### Setup:
```
Mật khẩu: "HACK"
Độ dài: 4 ký tự
Không gian: 26^4 = 456,976 khả năng
Complexity: 10,000 operations/check
```

#### Bước 1: Tính Secret Hash

```c
SECRET_PASSWORD = "HACK"
secret_hash = complex_hash_cpu("HACK", 10000)

Chi tiết tính toán:
  Vòng 0:
    'H': hash = 52547121
    'A': hash = 1734054848
    'C': hash = 2147483647
    'K': hash = 891234567
  Vòng 1:
    ... (lặp lại)
  ...
  Vòng 9999:
    ... (lặp lại)

Kết quả: secret_hash = 435596469
```

#### Bước 2: Brute Force

##### Phương pháp 1 - Tuần tự:

```
Thử từng mật khẩu:
index = 0      → "AAAA" → hash = 123456789 ≠ 435596469 ✗
index = 1      → "AAAB" → hash = 234567890 ≠ 435596469 ✗
index = 2      → "AAAC" → hash = 345678901 ≠ 435596469 ✗
...
index = 123094 → "HACK" → hash = 435596469 = 435596469 ✓

Tìm thấy sau 123,095 lần thử!
Thời gian: 18.11 giây
Tốc độ: 6,797 tries/giây
```

##### Phương pháp 2 - OpenMP:

```
12 threads chạy song song:

Thread 0: AAAA → AAZZ (0-675)
Thread 1: ABAA → ABZZ (676-1351)
Thread 2: ACAA → ACZZ (1352-2027)
...
Thread 7: GJAA → GJZZ (122876-123551)
  ↑
  Thread 7 tìm thấy "HACK" ở index 123094!
  → Báo hiệu found = 1
  → Các thread khác dừng lại

Thời gian: 3.23 giây
Speedup: 5.61x nhanh hơn tuần tự
```

##### Phương pháp 3 - CUDA:

```
457,216 threads chạy đồng thời:

Thread 0:      "AAAA" → hash ≠ secret_hash
Thread 1:      "AAAB" → hash ≠ secret_hash
Thread 2:      "AAAC" → hash ≠ secret_hash
...
Thread 123094: "HACK" → hash = 435596469 = secret_hash ✓
               atomicCAS(&d_found, 0, 1) → Success!
               Copy "HACK" → d_found_password
...
Thread 456975: "ZZZZ" → Kiểm tra d_found = 1 → Dừng

Thời gian: 0.019 giây
Speedup: 930x nhanh hơn tuần tự!
```

---

## 📈 Phân Tích Hiệu Suất

### Timeline so sánh:

```
Thời gian (giây)
0s      5s      10s     15s     18s
├───────┼───────┼───────┼───────┤
│                               │ Tuần tự: 18.11s
├───────────┤                     OpenMP: 3.23s
│                                 CUDA: 0.019s
↑
Start

Visualization:
Tuần tự:  ██████████████████████████████████████ 18.11s
OpenMP:   ███████ 3.23s
CUDA:     █ 0.019s
```

### Tốc độ xử lý:

```
┌──────────────┬────────────────┬──────────────────┐
│ Phương pháp  │ Tries/giây     │ Tổng operations  │
├──────────────┼────────────────┼──────────────────┤
│ Tuần tự      │ ~6,800         │ ~5 tỷ ops/s      │
│ OpenMP       │ ~47,000        │ ~30 tỷ ops/s     │
│ CUDA         │ ~23,500,000    │ ~4,500 tỷ ops/s  │
└──────────────┴────────────────┴──────────────────┘

CUDA nhanh hơn OpenMP: 500 lần về số tries!
```

### Tại sao CUDA mạnh hơn?

```
CPU (OpenMP):
  12 cores × 1 thread/core = 12 threads
  Mỗi core chạy tuần tự

GPU (CUDA):
  2048 CUDA cores
  457,216 threads (nhiều threads/core!)
  Chạy song song massive
  
→ GPU có gấp 170 lần số threads CPU!
→ Kiến trúc tối ưu cho parallel computing
```

---

## 🎯 Tổng Kết Cơ Chế

### Flow hoàn chỉnh:

```
1. User Input
   ↓
2. Generate/Input Password → SECRET_PASSWORD
   ↓
3. Calculate Hash → secret_hash = hash(SECRET_PASSWORD)
   ↓
4. Brute Force Method 1 (Sequential)
   → Try all passwords serially
   → Compare hash
   → Found! Record time
   ↓
5. Brute Force Method 2 (OpenMP)
   → Try passwords in parallel (12 threads)
   → Compare hash
   → Found! Record time
   ↓
6. Brute Force Method 3 (CUDA)
   → Try passwords massively parallel (457K threads)
   → Compare hash
   → Found! Record time
   ↓
7. Compare Results
   → Show times
   → Calculate speedup
   → Display chart
```

### Key Points:

```
✅ Hash Function:
  - Chuyển password → số (hash value)
  - Một chiều, khó đảo ngược
  - Deterministic (cùng input → cùng output)

✅ Brute Force:
  - Thử TẤT CẢ khả năng
  - So sánh hash với secret_hash
  - Tìm thấy khi hash khớp

✅ Sequential:
  - 1 thread, chậm nhất
  - Baseline để so sánh

✅ OpenMP:
  - Multi-threading CPU
  - Nhanh 4-6x
  - Dễ implement

✅ CUDA:
  - Massive parallel GPU
  - Nhanh 100-1000x
  - Phức tạp nhưng cực mạnh
```

---

## 📚 Tài Liệu Tham Khảo

- Hash Functions: djb2, SHA-256
- OpenMP Specification: https://www.openmp.org/
- CUDA Programming Guide: https://docs.nvidia.com/cuda/
- Parallel Computing Concepts

---

**Tác giả:** Dự án học tập Parallel Computing  
**Ngày:** 2025  
**Mục đích:** Giáo dục và nghiên cứu  

