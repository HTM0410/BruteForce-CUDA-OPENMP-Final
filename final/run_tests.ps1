# Script tu dong chay cac test case va luu ket qua
# Thu nghiem cho bao cao

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "     CHAY CAC TEST CASE TU DONG" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$testCases = @(
    @{Length=4; Complexity=1; Desc="4 ky tu - DON GIAN (300 ops)"},
    @{Length=4; Complexity=2; Desc="4 ky tu - TRUNG BINH (600 ops)"},
    @{Length=4; Complexity=3; Desc="4 ky tu - PHUC TAP (1000 ops)"},
    @{Length=5; Complexity=1; Desc="5 ky tu - DON GIAN (300 ops)"},
    @{Length=5; Complexity=2; Desc="5 ky tu - TRUNG BINH (600 ops)"},
    @{Length=5; Complexity=3; Desc="5 ky tu - PHUC TAP (1000 ops)"},
    @{Length=6; Complexity=1; Desc="6 ky tu - DON GIAN (300 ops)"},
    @{Length=6; Complexity=2; Desc="6 ky tu - TRUNG BINH (600 ops)"}
)

$results = @()
$testNum = 1

foreach ($test in $testCases) {
    Write-Host "`n--- TEST $testNum/$($testCases.Count): $($test.Desc) ---" -ForegroundColor Yellow
    
    # Tao input cho chuong trinh: 1 (AUTO), do dai, do phuc tap, y (tiep tuc)
    $input = "1`n$($test.Length)`n$($test.Complexity)`ny`n"
    
    # Chay chuong trinh
    $output = $input | .\compare_flexible.exe
    
    # Luu ket qua
    $results += @{
        Test = $testNum
        Desc = $test.Desc
        Output = $output
    }
    
    Write-Host "Hoan thanh!" -ForegroundColor Green
    Start-Sleep -Seconds 2
    $testNum++
}

# Luu ket qua ra file
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$outputFile = "test_results_$timestamp.txt"

"=" * 80 | Out-File $outputFile
"KET QUA THU NGHIEM BRUTE FORCE" | Out-File $outputFile -Append
"Thoi gian: $(Get-Date)" | Out-File $outputFile -Append
"=" * 80 | Out-File $outputFile -Append

foreach ($result in $results) {
    "`n`n" | Out-File $outputFile -Append
    "TEST $($result.Test): $($result.Desc)" | Out-File $outputFile -Append
    "-" * 80 | Out-File $outputFile -Append
    $result.Output | Out-File $outputFile -Append
}

Write-Host "`n`n========================================" -ForegroundColor Cyan
Write-Host "     HOAN THANH!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Ket qua da duoc luu vao: $outputFile" -ForegroundColor Yellow
Write-Host "`nBam phim bat ky de dong..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

