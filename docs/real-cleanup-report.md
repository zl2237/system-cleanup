# 一次真实的清理记录 — 2026-11-17

> 本文件是 `cleanup-report-2026-11-17/SUMMARY.md` 的脱敏原样存档（仅隐去用户目录名），未做任何数字修饰。
> 背景：作者对本机执行「模块 1 环境变量 + 模块 2 卸载残留 + 模块 3 垃圾清理」，全部项逐项确认后执行。

## 总览

**C 盘剩余：89.8 GB → 96.08 GB（共释放 6.28 GB）**，32/32 项全部成功，零误删。

## 模块 1 · 环境变量（8/8 成功）

- 删变量：`M2_HOME`、`MAVEN_HOME`、`PATH_BAK`（Machine）；`IntelliJ IDEA`（User）
- 删 PATH 死条目：`apache-maven-3.9.11\bin`（Machine）；`IntelliJ IDEA 2024.1.7\bin`、`Tesseract-OCR\`、`.dotnet\tools`（User）
- 保留：`CLASSPATH`（jmeter 本体在用）← **AI 判断保留的例子**
- 注册表备份：`backup-env-User.reg` / `backup-env-Machine.reg`（双击可还原）

## 模块 2 · 卸载残留（14/14 成功，约 2.0 GB）

- 删除：JetBrains IDEA 2024.1 与 PyCharm **2024.3 旧版** Local+Roaming；clash_win、YLH、`Local\node`、v2b-updater、WorkBuddy 三件、`.jdks`、`.paddlex`
- **PyCharm 2025.2 在用，未动** ← **AI 区分"旧版残留"与"在用版本"的例子**
- 保留（用户决定）：puccinialin 637MB、SysCeo/DrvCeo 556MB、`.codemoss`、`.m2`、Typora、Apowersoft ← **拿不准的单独询问，不混入可删清单**

## 模块 3 · 垃圾清理（10/10 成功，约 4.73 GB）

双 Temp 3.07GB + Edge/Chrome 缓存 1.43GB + WER/崩溃转储/缩略图/D3DSCache 0.23GB；
未动：CBS 日志、Prefetch（谨慎项）。

## 开发者缓存扫描（用户未勾选执行，等待后续确认）

| 缓存 | 大小 | 分级 |
|---|---|---|
| npm 缓存 | 5.19 GB | 可删·重下 |
| NuGet 全局包 | 2.61 GB | 可删·重下 |
| pip 缓存 | 2.03 GB | 可删·重下 |
| NuGet 下载缓存 | 0.66 GB | 可删·重建 |
| Maven 本地仓库 | 0.17 GB | **建议官方命令**（依赖全部重下代价大） |

合计：可直接删 0.66 GB / 可删但重下 9.83 GB / 建议官方命令 0.17 GB。

## 系统产出物（本仓库每次运行都会生成）

```
桌面\cleanup-report-<日期>\
├── SUMMARY.md            # 本次汇总
├── *-report.txt/.json    # 各扫描器的报告（人读 + 计划用）
├── *-plan.json           # 用户逐项确认后的执行清单
├── backup-env-*.reg      # 注册表备份
└── clean-log-*.txt       # 执行日志
```
