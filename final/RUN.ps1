# ===================================================================
# Script chay nhanh cac chuong trinh trong thu muc FINAL
# ===================================================================

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  THU MUC FINAL - CHUONG TRINH CHINH" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Ban muon chay chuong trinh nao?" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. compare_flexible.exe  - SO SANH DAY DU (Tuan tu, OpenMP, CUDA)" -ForegroundColor White
Write-Host "  2. compare_cuda_only.exe - CHI GPU (Test hieu suat GPU)" -ForegroundColor White
Write-Host "  3. Doc tai lieu          - CO_CHE_HOAT_DONG.md" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Lua chon cua ban (1-3)"

Write-Host ""

switch ($choice) {
    "1" {
        Write-Host "================================================================" -ForegroundColor Green
        Write-Host "  CHAY: compare_flexible.exe" -ForegroundColor Green
        Write-Host "  So sanh: Tuan tu vs OpenMP vs CUDA" -ForegroundColor Green
        Write-Host "================================================================" -ForegroundColor Green
        Write-Host ""
        .\compare_flexible.exe
    }
    "2" {
        Write-Host "================================================================" -ForegroundColor Magenta
        Write-Host "  CHAY: compare_cuda_only.exe" -ForegroundColor Magenta
        Write-Host "  Test hieu suat GPU" -ForegroundColor Magenta
        Write-Host "================================================================" -ForegroundColor Magenta
        Write-Host ""
        .\compare_cuda_only.exe
    }
    "3" {
        Write-Host "Mo tai lieu..." -ForegroundColor Yellow
        notepad CO_CHE_HOAT_DONG.md
    }
    default {
        Write-Host "Lua chon khong hop le!" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Hoan thanh!" -ForegroundColor Green
Write-Host ""

