# 🚀 HƯỚNG DẪN SỬ DỤNG - Phiên Bản Linh Hoạt

## 📋 Tổng Quan

Chương trình **compare_flexible.exe** cho phép bạn:
- ✅ **Tự chọn độ dài mật khẩu** (3-8 ký tự)
- ✅ **Tự động sinh mật khẩu ngẫu nhiên** hoặc nhập tùy chỉnh
- ✅ **Chọn độ phức tạp hash** (100 - 50,000 operations)
- ✅ **So sánh hiệu suất** Tuần tự vs OpenMP vs CUDA

---

## 🎯 Cách Chạy

### Cách 1: Chạy trực tiếp
```powershell
.\compare_flexible.exe
```

### Cách 2: Dùng script (nếu cần fix encoding)
```powershell
.\fix_encoding.ps1
```

---

## 📖 Hướng Dẫn Sử Dụng Chi Tiết

### Bước 1: Chọn Chế Độ

```
================================================================
  SETUP BAI TOAN BRUTE FORCE
================================================================

  Ban muon chon che do nao?

  1. AUTO - Tu dong sinh mat khau ngau nhien
  2. CUSTOM - Nhap mat khau tu tuy chinh

  Lua chon cua ban (1 hoac 2): _
```

**Lựa chọn:**
- **1** → Chương trình tự sinh mật khẩu ngẫu nhiên
- **2** → Bạn nhập mật khẩu tùy chỉnh (chỉ dùng A-Z)

---

### Bước 2: Chọn Độ Dài Mật Khẩu

```
  Chon do dai mat khau (3-8 ky tu): _
```

**Ví dụ:**
- **3** → 26³ = 17,576 khả năng (rất nhanh)
- **4** → 26⁴ = 456,976 khả năng (nhanh)
- **5** → 26⁵ = 11,881,376 khả năng (trung bình)
- **6** → 26⁶ = 308,915,776 khả năng (chậm)
- **7** → 26⁷ = 8,031,810,176 khả năng (rất chậm!)
- **8** → 26⁸ = 208,827,064,576 khả năng (cực chậm!)

---

### Bước 3: Chọn Độ Phức Tạp Hash

```
  Chon do phuc tap hash:

  1. DON GIAN    (100 ops)     - Nhanh, demo
  2. TRUNG BINH  (1,000 ops)   - Can bang
  3. PHUC TAP    (10,000 ops)  - Thuc te, cham
  4. CUC PHUC TAP (50,000 ops) - Rat cham!

  Lua chon (1-4): _
```

**Lựa chọn:**
- **1 (Đơn giản)** → Demo, test nhanh
- **2 (Trung bình)** → Cân bằng tốc độ/thực tế
- **3 (Phức tạp)** → Mô phỏng SHA-256, bcrypt
- **4 (Cực phức tạp)** → Mô phỏng scrypt, argon2

---

### Bước 4: Xác Nhận

Chương trình sẽ hiển thị thông tin và dự đoán thời gian:

```
================================================================
  THONG TIN BAI TOAN
================================================================
  * Do dai mat khau: 4 ky tu
  * Khong gian tim kiem: 26^4 = 456976 kha nang
  * Do phuc tap hash: 10000 operations/check
  * Tong phep toan: ~4.57 ty operations
  * Mat khau muc tieu: HACK
  * CPU Cores: 12

  Du doan thoi gian (tuong doi):
    - Tuan tu:  ~4.6 giay
    - OpenMP:   ~0.8 giay (voi 12 cores)
    - CUDA:     ~0.0 giay

  Ban co muon tiep tuc? (y/n): _
```

Nhấn **y** để tiếp tục, **n** để hủy.

---

## 📊 Ví Dụ Các Trường Hợp Sử Dụng

### 🟢 Case 1: Test Nhanh (Dành cho demo)
```
Chế độ: AUTO (1)
Độ dài: 3 ký tự
Hash: Đơn giản (1)

→ Kết quả: ~0.1 giây (rất nhanh!)
→ Mục đích: Demo, test code
```

### 🟡 Case 2: Cân Bằng (Khuyên dùng)
```
Chế độ: AUTO (1)
Độ dài: 4 ký tự
Hash: Phức tạp (3)

→ Kết quả: Tuần tự ~18s, CUDA ~0.02s
→ Mục đích: Thấy rõ sự khác biệt
```

### 🟠 Case 3: Thử Thách
```
Chế độ: CUSTOM (2) → Nhập "PASSWORD"
Độ dài: 5 ký tự
Hash: Phức tạp (3)

→ Kết quả: Tuần tự ~8 phút, CUDA ~1 giây
→ Mục đích: Test sức mạnh GPU thực sự
```

### 🔴 Case 4: Cực Khó (Chỉ với CUDA!)
```
Chế độ: AUTO (1)
Độ dài: 6 ký tự
Hash: Cực phức tạp (4)

→ Kết quả: Tuần tự ~10 giờ, CUDA ~30 giây
→ Mục đích: Mô phỏng thực tế password cracking
```

---

## 💡 Gợi Ý Sử Dụng

### Để thấy rõ sự khác biệt giữa 3 phương pháp:

| Mục tiêu | Độ dài | Hash | Lý do |
|----------|--------|------|-------|
| **Demo nhanh** | 3-4 | Đơn giản | Chạy trong vài giây |
| **Học tập** | 4 | Phức tạp | Thấy rõ speedup |
| **Test GPU** | 5-6 | Phức tạp | GPU thể hiện ưu thế |
| **Thực tế** | 6-7 | Cực phức tạp | Mô phỏng thật |

---

## ⚠️ LƯU Ý

### 1. Thời Gian Chạy

**Độ dài 3-4 ký tự:** Vài giây đến 1 phút
**Độ dài 5 ký tự:** Vài phút đến 10 phút
**Độ dài 6 ký tự:** 30 phút đến vài giờ (tùy hash)
**Độ dài 7-8 ký tự:** VÀI GIỜ đến VÀI NGÀY!

### 2. Khuyến Nghị

- **Lần đầu:** Chọn độ dài 3-4, hash đơn giản/trung bình
- **Sau đó:** Tăng dần độ phức tạp
- **Nếu quá lâu:** Nhấn Ctrl+C để dừng

### 3. Ưu Điểm So Với Phiên Bản Cũ

| Tính năng | Cũ | Mới (Flexible) |
|-----------|-----|----------------|
| Độ dài mật khẩu | Cố định 4 | 3-8 tùy chọn ✅ |
| Mật khẩu | Cố định "HACK" | Tự động/tùy chỉnh ✅ |
| Hash | Cố định 10K ops | 100-50K tùy chọn ✅ |
| Dự đoán thời gian | Không | Có ✅ |

---

## 🎯 Kết Quả Mẫu

### Với độ dài 4, hash phức tạp (10K ops):

```
================================================================
  KET QUA SO SANH
================================================================

  Ket qua:
    Tuan tu:  HACK
    OpenMP:   HACK
    CUDA:     HACK
    Muc tieu: HACK (DUNG!)

  THOI GIAN:
  --------------------------------------------------------
    Tuan tu (1 CPU)          18.111 s      1.00x
    OpenMP (12 CPUs)          3.227 s      5.61x
    CUDA (GPU)                0.019 s      930.38x
  --------------------------------------------------------

  >>> CUDA nhanh hon OpenMP: 165.80x
```

---

## 🚀 Các File Trong Dự Án

| File | Mô tả | Khuyên dùng |
|------|-------|-------------|
| `compare_flexible.exe` | **Linh hoạt nhất** | ⭐⭐⭐⭐⭐ |
| `compare_simple.exe` | Đơn giản, 4 ký tự cố định | ⭐⭐⭐ |
| `compare_all.exe` | PIN 6 số, đơn giản | ⭐⭐ |

---

## 📚 Học Từ Kết Quả

### Quan sát:

1. **Với mật khẩu NGẮN (3-4 ký tự):**
   - OpenMP nhanh ~5-6x
   - CUDA nhanh ~100-1000x

2. **Với mật khẩu DÀI (5-7 ký tự):**
   - OpenMP nhanh ~4-5x (giảm do overhead)
   - CUDA nhanh ~1000-10000x (tăng mạnh!)

3. **Với hash PHỨC TẠP:**
   - GPU càng thể hiện ưu thế
   - CPU bị nghẽn bởi tính toán tuần tự

### Kết luận:
> **Bài toán càng LỚN và PHỨC TẠP, GPU càng BÁ CHỦ!**

---

## ⚖️ Lưu Ý Pháp Lý

⚠️ **QUAN TRỌNG:**
- Chỉ dùng cho **HỌC TẬP** và **NGHIÊN CỨU**
- Chỉ test hệ thống của **CHÍNH BẠN**
- Crack password người khác là **PHẠM PHÁP**
- Tuân thủ luật pháp về an ninh mạng

---

**🎓 Chúc bạn học tốt về Parallel Computing!**

