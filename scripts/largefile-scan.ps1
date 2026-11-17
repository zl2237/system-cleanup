<#
.SYNOPSIS
  大文件 Top-N 定位（辅助扫描 - 只读不删）
.DESCRIPTION
  扫描指定盘符(默认C:)中超过阈值的文件, 按大小排序输出 Top-N, 快速回答"谁吃掉了我的磁盘"。
  hiberfil.sys/pagefile.sys/swapfile.sys 只标注说明, 永不建议删除。
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File largefile-scan.ps1 -Drives C: -MinGB 1 -TopN 50
.OUTPUT
  largefile-scan.json（机器可读）、largefile-report.txt（人类可读）
#>
param(
    [string]$OutDir = "$env:USERPROFILE\Desktop\cleanup-report-$(Get-Date -Format 'yyyyMMdd')",
    [string[]]$Drives = @('C:'),
    [double]$MinGB = 1,
    [int]$TopN = 50
)
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$minBytes = [int64]($MinGB * 1GB)
$sysKnown = @{ 'hiberfil.sys'='休眠文件·只报告永不删'; 'pagefile.sys'='页面文件·只报告永不删'; 'swapfile.sys'='系统交换文件·只报告永不删' }

$hits = @()
foreach ($d in $Drives) {
    Write-Host "扫描 $d\ 中 >= $MinGB GB 的文件(全盘遍历, 大盘可能需要几分钟)..."
    $hits += @(Get-ChildItem -LiteralPath "$d\" -Recurse -Force -File -EA SilentlyContinue |
        Where-Object { $_.Length -ge $minBytes } |
        ForEach-Object {
            [PSCustomObject]@{
                GB = [math]::Round($_.Length/1GB, 2)
                LastWrite = $_.LastWriteTime.ToString('yyyy-MM-dd')
                Path = $_.FullName
                Note = $sysKnown[$_.Name.ToLower()]
            }
        })
}
$hits = @($hits | Sort-Object GB -Descending)
$top = @($hits | Select-Object -First $TopN)

$byExt = @($hits | Group-Object { $e = [IO.Path]::GetExtension($_.Path).ToLower(); if ($e) { $e } else { '(无扩展名)' } } | ForEach-Object {
    [PSCustomObject]@{ Ext = $_.Name; Count = $_.Count; GB = [math]::Round(($_.Group | Measure-Object GB -Sum).Sum, 2) }
} | Sort-Object GB -Descending | Select-Object -First 10)

$totalGB = [math]::Round(($hits | Measure-Object GB -Sum).Sum, 1)
[IO.File]::WriteAllText("$OutDir\largefile-scan.json", (ConvertTo-Json -InputObject @{ Drives = $Drives; MinGB = $MinGB; Hits = $top; ByExtension = $byExt } -Depth 4), [Text.UTF8Encoding]::new($false))

$rpt = New-Object System.Collections.Generic.List[string]
$rpt.Add("大文件扫描报告  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')   盘符: $($Drives -join ' ')   阈值: >=$MinGB GB   命中: $($hits.Count) 个 / 合计 $totalGB GB")
$rpt.Add("")
$rpt.Add(('{0,8} {1,12}  {2,-26} {3}' -f 'GB','修改日期','备注','路径'))
foreach ($h in $top) {
    $rpt.Add(('{0,8} {1,12}  {2,-26} {3}' -f $h.GB, $h.LastWrite, [string]$h.Note, $h.Path))
}
$rpt.Add("")
$rpt.Add("===== 按扩展名汇总(Top10) =====")
foreach ($e in $byExt) { $rpt.Add(('{0,8} GB  {1,4} 个  {2}' -f $e.GB, $e.Count, $e.Ext)) }
$rpt.Add("")
$rpt.Add("说明: 系统文件(hiberfil/pagefile/swapfile)只报告; 其余大文件先与用户逐项确认用途再决定去留, 不自动删")
$rpt | Out-String | Out-File "$OutDir\largefile-report.txt" -Encoding utf8
Write-Host "DONE -> $OutDir\largefile-report.txt ($($hits.Count) hits)"
