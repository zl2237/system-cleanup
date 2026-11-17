<#
.SYNOPSIS
  扫描开发者工具缓存（模块3 扩展 - 扫描阶段，只读不删）
.DESCRIPTION
  白名单覆盖 npm/pnpm/yarn/pip/uv/Maven/Gradle/NuGet/Go/Cargo/HuggingFace/PyTorch/Conda/Docker 等。
  分级: safe=可删(自动重建) / redownload=可删(代价是重新联网下载) / confirm=不建议直接删(给官方命令) / report=仅报告(永不删)
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File dev-cache-scan.ps1 -OutDir "$env:USERPROFILE\Desktop\cleanup-report"
.OUTPUT
  dev-cache-scan.json（机器可读）、dev-cache-report.txt（人类可读）
#>
param([string]$OutDir = "$env:USERPROFILE\Desktop\cleanup-report-$(Get-Date -Format 'yyyyMMdd')",
      [string]$HomeDir = $env:USERPROFILE)
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$L = $env:LOCALAPPDATA
$targets = @(
    # safe: 删除后自动重建, 几乎无感
    @{ Tool='Go构建缓存';       Path="$L\go-build";                    Level='safe' },
    @{ Tool='NuGet下载缓存';    Path="$L\NuGet\v3-cache";              Level='safe' },
    @{ Tool='electron下载缓存'; Path="$L\electron\Cache";              Level='safe' },
    @{ Tool='node-gyp头文件';   Path="$HomeDir\.node-gyp";             Level='safe' },
    # redownload: 可删, 首次使用会重新联网下载
    @{ Tool='npm缓存';          Path="$L\npm-cache";                   Level='redownload' },
    @{ Tool='pnpm store';       Path="$L\pnpm\store";                  Level='redownload' },
    @{ Tool='yarn缓存';         Path="$L\Yarn\Cache";                  Level='redownload' },
    @{ Tool='yarn berry缓存';   Path="$L\Yarn\Berry\cache";            Level='redownload' },
    @{ Tool='pip缓存';          Path="$L\pip\cache";                   Level='redownload' },
    @{ Tool='uv缓存';           Path="$L\uv\cache";                    Level='redownload' },
    @{ Tool='Gradle依赖缓存';   Path="$HomeDir\.gradle\caches";        Level='redownload' },
    @{ Tool='Gradle发行版';     Path="$HomeDir\.gradle\wrapper\dists"; Level='redownload' },
    @{ Tool='NuGet全局包';      Path="$HomeDir\.nuget\packages";       Level='redownload' },
    @{ Tool='Go模块缓存';       Path="$HomeDir\go\pkg\mod";            Level='redownload' },
    @{ Tool='Cargo注册表缓存';  Path="$HomeDir\.cargo\registry";       Level='redownload' },
    @{ Tool='HuggingFace模型';  Path="$HomeDir\.cache\huggingface";    Level='redownload' },
    @{ Tool='PyTorch缓存';      Path="$HomeDir\.cache\torch";          Level='redownload' },
    # confirm: 不建议脚本直接删, 优先官方命令
    @{ Tool='Maven本地仓库';    Path="$HomeDir\.m2\repository";        Level='confirm'; Note='所有Java依赖将重新下载, 项目多时代价大; 可只删旧版本' },
    @{ Tool='Conda包缓存';      Path="$HomeDir\.conda\pkgs";           Level='confirm'; Note='直接删可能破坏现有环境(硬链接), 建议 conda clean --all' },
    @{ Tool='Conda(miniconda3)'; Path="$HomeDir\miniconda3\pkgs";      Level='confirm'; Note='同上, 建议 conda clean --all' },
    @{ Tool='Conda(anaconda3)'; Path="$HomeDir\anaconda3\pkgs";        Level='confirm'; Note='同上, 建议 conda clean --all' },
    # report: 虚拟磁盘, 只报大小 + 给指引, 永不删除
    @{ Tool='Docker数据盘';     Path="$L\Docker\wsl\data\ext4.vhdx";   Level='report'; Note='不能删; Docker Desktop 内清理/迁移磁盘镜像位置' },
    @{ Tool='Docker数据盘v2';   Path="$L\Docker\wsl\disk\docker_data.vhdx"; Level='report'; Note='不能删; 同上' },
    @{ Tool='WSL发行版数据盘';  Path="$L\Packages\*\LocalState\ext4.vhdx"; Level='report'; Note='不能删; wsl --export/--import 可迁移到其他盘' }
)

$rows = @()
foreach ($t in $targets) {
    $paths = @(Resolve-Path -Path $t.Path -EA SilentlyContinue)
    if ($paths.Count -eq 0) { continue }
    $size = 0; $count = 0
    foreach ($rp in $paths) {
        Get-ChildItem -LiteralPath $rp.Path -Recurse -Force -File -EA SilentlyContinue | ForEach-Object { $size += $_.Length; $count++ }
    }
    $rows += [PSCustomObject]@{
        Tool = $t.Tool; Path = $t.Path; Level = $t.Level
        GB = [math]::Round($size/1GB, 3); Files = $count
        Note = $t.Note
    }
}
$rows = @($rows | Sort-Object GB -Descending)

[IO.File]::WriteAllText("$OutDir\dev-cache-scan.json", ($rows | ConvertTo-Json -Depth 3), [Text.UTF8Encoding]::new($false))

$levelCn = @{ safe='可删·重建'; redownload='可删·重下'; confirm='官方命令'; report='仅报告' }
$sum = @{}
foreach ($lv in 'safe','redownload','confirm','report') {
    $sum[$lv] = [math]::Round((($rows | Where-Object Level -eq $lv) | Measure-Object GB -Sum).Sum, 2)
}
$rpt = New-Object System.Collections.Generic.List[string]
$rpt.Add("开发者缓存扫描报告  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$rpt.Add("分级: safe=可删(自动重建)  redownload=可删(重新联网下载)  confirm=建议用官方命令  report=仅报告永不删")
$rpt.Add("")
foreach ($r in $rows) {
    $rpt.Add(('{0,-26} {1,9} GB  [{2}]  {3}' -f $r.Tool, $r.GB, $levelCn[$r.Level], $r.Note))
    $rpt.Add("    $($r.Path)")
}
$rpt.Add("")
$rpt.Add("合计: 可直接删(safe) $($sum['safe']) GB / 可删但重下(redownload) $($sum['redownload']) GB / 官方命令(confirm) $($sum['confirm']) GB / 仅报告(report) $($sum['report']) GB")
$rpt.Add("清理方式: safe/redownload 项经用户确认后写入 junk-plan.json(removeDir/cleanDir) 交 clean-executor 执行")
$rpt.Add("confirm/report 项不进清理计划, 按各自行内指引处理")
$rpt | Out-String | Out-File "$OutDir\dev-cache-report.txt" -Encoding utf8
Write-Host "DONE -> $OutDir\dev-cache-report.txt ($($rows.Count) items)"
