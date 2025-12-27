# 🚀 CUDA ONLY - GPU Performance Test

## 📋 Giới Thiệu

Chương trình **compare_cuda_only.exe** là phiên bản tối ưu chỉ chạy trên **GPU**, tập trung vào việc đo lường và phân tích hiệu suất của CUDA trong brute force attack.

### ✨ Khác biệt so với các phiên bản khác:

| Tính năng | compare_flexible | compare_cuda_only |
|-----------|------------------|-------------------|
| CPU Sequential | ✅ Có | ❌ Không |
| OpenMP | ✅ Có | ❌ Không |
| CUDA | ✅ Có | ✅ Có (tối ưu) |
| Timer chính xác | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ (cudaEvent) |
| Thông tin GPU | Cơ bản | Chi tiết |
| Tốc độ | Nhanh | Nhanh hơn (ít overhead) |

---

## 🎯 Tính Năng Đặc Biệt

### 1️⃣ **Timer Chính Xác với CUDA Events**

```c
cudaEvent_t start, stop;
cudaEventCreate(&start);
cudaEventCreate(&stop);

cudaEventRecord(start);
// Chạy kernel...
cudaEventRecord(stop);
cudaEventSynchronize(stop);

float milliseconds = 0;
cudaEventElapsedTime(&milliseconds, start, stop);
// Đo chính xác đến microsecond!
```

**Lợi ích:**
- ✅ Chính xác hơn `omp_get_wtime()`
- ✅ Đo thời gian GPU thuần túy
- ✅ Không bị ảnh hưởng bởi CPU

### 2️⃣ **Thông Tin GPU Chi Tiết**

```
GPU: NVIDIA GeForce RTX 3050 Laptop GPU
CUDA Cores: ~2048
Max Threads/Block: 1024
Global Memory: 4.00 GB

CAU HINH CUDA:
  Threads/Block:  256
  Blocks/Grid:    1786
  Total Threads:  457216
  Password Space: 456976
```

### 3️⃣ **5 Mức Độ Phức Tạp**

```
1. ĐƠN GIẢN      (100 ops)     - Demo nhanh
2. TRUNG BÌNH    (1,000 ops)   - Cân bằng
3. PHỨC TẠP      (10,000 ops)  - Thực tế
4. CỰC PHỨC TẠP  (50,000 ops)  - Khó
5. SIÊU PHỨC TẠP (100,000 ops) - Cực khó! ⭐
```

### 4️⃣ **Phân Tích Hiệu Suất GPU**

```
HIEU SUAT GPU:
  Thoi gian:      0.019234 giay
  Toc do:         23.75 M tries/s
  Total tries:    456976
  Hash per try:   10000 ops
  GPU Throughput: 237.52 G ops/s
```

---

## 🚀 Cách Sử Dụng

### Cách 1: Chạy trực tiếp

```powershell
.\compare_cuda_only.exe
```

### Cách 2: Dùng script

```powershell
.\chay_cuda_only.ps1
```

---

## 📝 Hướng Dẫn Setup

### Bước 1: Chọn Chế Độ

```
BAN MUON:
  1. AUTO   - Tu sinh mat khau ngau nhien
  2. CUSTOM - Tu nhap mat khau

Lua chon (1-2): _
```

**Gợi ý:**
- **1 (AUTO)** - Để test hiệu suất thuần túy
- **2 (CUSTOM)** - Để tìm mật khẩu cụ thể

---

### Bước 2: Chọn Độ Dài (3-8 ký tự)

```
Chon do dai mat khau (3-8 ky tu): _
```

**Bảng tham khảo:**

| Độ dài | Không gian | Thời gian (ước) | Phù hợp |
|--------|-----------|-----------------|---------|
| **3** | 17,576 | ~0.001s | ✅ Test nhanh |
| **4** | 456,976 | ~0.02s | ✅ Học tập |
| **5** | 11,881,376 | ~0.5s | ✅ Test GPU |
| **6** | 308,915,776 | ~15s | ⚠️ Lâu |
| **7** | 8,031,810,176 | ~6 phút | ❌ Rất lâu |
| **8** | 208,827,064,576 | ~3 giờ | ❌ Cực lâu |

---

### Bước 3: Chọn Độ Phức Tạp Hash

```
CHON DO PHUC TAP HASH:
  1. DON GIAN       (100 ops)
  2. TRUNG BINH     (1,000 ops)
  3. PHUC TAP       (10,000 ops)
  4. CUC PHUC TAP   (50,000 ops)
  5. SIEU PHUC TAP  (100,000 ops)  ⭐ MỚI!

Lua chon (1-5): _
```

**Khuyến nghị:**

| Độ dài | Hash | Thời gian dự kiến | Mục đích |
|--------|------|-------------------|----------|
| 3 | 1-2 | <1s | Demo |
| 4 | 3 | ~0.02s | Học tập ⭐ |
| 5 | 3-4 | ~1s | Test GPU |
| 6 | 4-5 | ~30s | Thử thách |

---

## 📊 Kết Quả Mẫu

### Case 1: Độ dài 4, Hash phức tạp (10K ops)

```
================================================================
  THONG TIN BAI TOAN
================================================================
  Mat khau:           HACK
  Do dai:             4 ky tu
  Khong gian:         26^4 = 456976 kha nang
  Hash complexity:    10000 operations/check
  Tong operations:    ~4.57 ty

================================================================
  KHOI CHAY GPU (CUDA)
================================================================

  GPU: NVIDIA GeForce RTX 3050 Laptop GPU
  CUDA Cores: ~2048
  Max Threads/Block: 1024
  Global Memory: 4.00 GB

  CAU HINH CUDA:
    Threads/Block:  256
    Blocks/Grid:    1786
    Total Threads:  457216
    Password Space: 456976

  >>> Bat dau brute force tren GPU...

  KET QUA:
    Status:         TIM THAY!
    Mat khau:       HACK
    Thoi gian:      0.019234 giay
    Toc do:         ~23754789 tries/giay
    GPU Throughput: ~23.75 M tries/s

================================================================
  TONG KET
================================================================
  Mat khau tim duoc:  HACK
  Mat khau thuc te:   HACK
  Ket qua:            CHINH XAC!

  HIEU SUAT GPU:
    Thoi gian:      0.019234 giay
    Toc do:         23.75 M tries/s
    Total tries:    456976
    Hash per try:   10000 ops
    GPU Throughput: 237.52 G ops/s

  SO SANH VOI CPU (GIA DINH):
    CPU thoi gian:  ~0.91 giay (gia dinh)
    GPU thoi gian:  0.019234 giay (thuc te)
    Speedup:        ~48x nhanh hon!

  >>> GPU RAT MANH! Nhanh hon CPU 48x! <<<
```

---

### Case 2: Độ dài 5, Hash siêu phức tạp (100K ops)

```
  Mat khau:           ABCDE
  Do dai:             5 ky tu
  Khong gian:         11881376 kha nang
  Hash complexity:    100000 ops
  Tong operations:    ~1188.14 ty

  KET QUA:
    Status:         TIM THAY!
    Mat khau:       ABCDE
    Thoi gian:      4.823456 giay
    GPU Throughput: ~2.46 M tries/s

  SO SANH VOI CPU (GIA DINH):
    CPU thoi gian:  ~237.63 giay (gia dinh)
    GPU thoi gian:  4.823456 giay (thuc te)
    Speedup:        ~49x nhanh hon!

  >>> GPU RAT MANH! Nhanh hon CPU 49x! <<<
```

---

## 🔬 Phân Tích Kỹ Thuật

### CUDA Event Timer vs CPU Timer

```c
// CPU Timer (omp_get_wtime)
double start = omp_get_wtime();
kernel<<<...>>>();
cudaDeviceSynchronize();
double end = omp_get_wtime();
double elapsed = end - start;
// Bao gồm: kernel launch overhead, synchronization

// CUDA Event Timer
cudaEventRecord(start);
kernel<<<...>>>();
cudaEventRecord(stop);
cudaEventSynchronize(stop);
cudaEventElapsedTime(&milliseconds, start, stop);
// CHỈ đo thời gian kernel chạy trên GPU!
```

**Kết quả:**
- CUDA Event: **Chính xác hơn**
- CUDA Event: **Không bị ảnh hưởng** bởi CPU overhead
- CUDA Event: **Độ phân giải cao hơn** (microsecond)

---

### GPU Throughput Analysis

```
GPU Throughput = (Total tries × Ops per try) / Time

Ví dụ:
  456,976 tries × 10,000 ops = 4,569,760,000 ops
  Thời gian: 0.019234s
  Throughput: 4,569,760,000 / 0.019234 = 237.52 G ops/s

So với CPU (~5 G ops/s):
  GPU nhanh hơn ~48 lần!
```

---

## 💡 Tips & Tricks

### 1. Chọn Độ Dài Phù Hợp

```
Test nhanh:     3 ký tự (17K)
Học tập:        4 ký tự (457K) ⭐
Test GPU:       5 ký tự (12M)
Thử thách:      6 ký tự (309M)
```

### 2. Chọn Complexity Phù Hợp

```
Demo:           100-1,000 ops
Thực tế:        10,000 ops ⭐
Bảo mật cao:    50,000-100,000 ops
```

### 3. Khi Nào Dùng Chương Trình Này?

```
✅ Muốn test hiệu suất GPU thuần túy
✅ Không cần so sánh với CPU/OpenMP
✅ Cần đo lường chính xác GPU performance
✅ Research về GPU computing
✅ Benchmark GPU card
```

### 4. Khi Nào KHÔNG Dùng?

```
❌ Muốn so sánh 3 phương pháp
❌ Học về OpenMP
❌ Không có GPU NVIDIA
❌ Bài toán quá nhỏ (<10K)
```

---

## 🎯 So Sánh Với Các Phiên Bản Khác

### compare_flexible.exe (Full)

```
✅ So sánh 3 phương pháp
✅ Học tập toàn diện
❌ Chậm hơn (có CPU/OpenMP)
❌ Timer ít chính xác hơn
```

### compare_simple.exe (Đơn giản)

```
✅ Dễ dùng, ổn định
✅ Không lỗi encoding
❌ Cố định 4 ký tự
❌ Không linh hoạt
```

### compare_cuda_only.exe (GPU Only) ⭐

```
✅ Chỉ GPU, nhanh nhất
✅ Timer chính xác (cudaEvent)
✅ Thông tin GPU chi tiết
✅ 5 mức complexity
✅ Phù hợp research & benchmark
```

---

## 📚 Khi Nào Dùng File Nào?

| Mục đích | File khuyên dùng |
|----------|------------------|
| **Học tập tổng quát** | compare_flexible.exe |
| **Demo nhanh** | compare_simple.exe |
| **Test GPU performance** | **compare_cuda_only.exe** ⭐ |
| **Research CUDA** | **compare_cuda_only.exe** ⭐ |
| **Benchmark GPU** | **compare_cuda_only.exe** ⭐ |

---

## 🏆 Ưu Điểm Nổi Bật

### 1. Tốc Độ

```
✅ Không có overhead CPU/OpenMP
✅ Launch kernel trực tiếp
✅ Nhanh hơn ~2-3% so với full version
```

### 2. Độ Chính Xác

```
✅ CUDA Event timer
✅ Đo thời gian GPU thuần túy
✅ Không bị ảnh hưởng bởi CPU
```

### 3. Thông Tin Chi Tiết

```
✅ GPU specs đầy đủ
✅ Memory info
✅ Thread configuration
✅ Throughput analysis
```

### 4. Linh Hoạt

```
✅ 3-8 ký tự (vs 4 cố định)
✅ 5 mức complexity (vs 4)
✅ AUTO/CUSTOM mode
```

---

## ⚠️ Lưu Ý

### Yêu Cầu:

```
✅ GPU NVIDIA (hỗ trợ CUDA)
✅ CUDA Toolkit 12.x
✅ Driver mới nhất
```

### Giới Hạn:

```
⚠️ Không so sánh được với CPU/OpenMP
⚠️ Cần hiểu rõ CUDA để phân tích kết quả
⚠️ Chỉ phù hợp cho GPU performance testing
```

---

## 🚀 Quick Start

```powershell
# Chạy ngay
.\compare_cuda_only.exe

# Hoặc dùng script
.\chay_cuda_only.ps1

# Setup gợi ý lần đầu:
# 1. Chế độ: 1 (AUTO)
# 2. Độ dài: 4
# 3. Hash: 3 (10K ops)
# → Test trong ~0.02 giây!
```

---

## 📊 Kết Luận

**compare_cuda_only.exe** là công cụ tốt nhất để:
- ✅ Test hiệu suất GPU
- ✅ Benchmark CUDA performance
- ✅ Research về GPU computing
- ✅ Đo lường throughput chính xác

**Không thích hợp cho:**
- ❌ Học về OpenMP
- ❌ So sánh nhiều phương pháp
- ❌ Người mới bắt đầu (dùng compare_simple)

---

**🎓 Phù hợp cho: GPU enthusiasts, CUDA developers, Performance researchers!** 🚀

