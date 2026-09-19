# system-cleanup

> C 盘又红了，但不敢乱删？环境变量一堆，不知道哪个还有用？软件卸载了，垃圾还躺在 AppData 里？

**一个让 AI 编程助手安全帮你清理 Windows 的 Skill。** 你说需求，它扫描、出报告、等你点头，才动手。

适用于任何支持 Agent Skills 标准（SKILL.md 约定）的 agent：**Trae / Claude Code / Cursor / CodeBuddy / ZCode** …有对话栏的地方就能用。

## 它是怎么工作的

```
你说 "C盘满了帮我看看"
        │
        ▼
┌─────────────────────────────────────┐
│  ① 扫描（只读，不删任何东西）          │
│  ② 报告（每项标大小/安全等级/去向）     │
│  ③ 你确认（全删？只删某几项？保留？）   │
│  ④ 执行（自动备份，写日志，可回滚）     │
└─────────────────────────────────────┘
```

没有"一键清理"按钮——**每一步删除都需要你确认**，这是设计，不是缺陷。

## 四件事，做几件你说了算

| 场景 | 它做什么 |
|---|---|
| **"我环境变量好乱"** | 找出 PATH 死条目、失效变量（指向已删除软件/路径的），列表让你勾选清理，删前自动导出 `.reg` 备份 |
| **"这软件卸载了怎么还有残留"** | 交叉比对已安装软件清单 vs AppData/ProgramData 等高发区，找出孤儿目录，按"确定可删/拿不准"分档 |
| **"C盘满了"** | 白名单扫描临时文件/更新缓存/崩溃转储/浏览器缓存等，每项标安全等级，确认后清理并汇报释放量 |
| **"磁盘想重新规划"** | 盘点各盘占用，给出分工方案和迁移清单，确认后用 `robocopy /MOVE` 迁移（数据不丢），同步修正 PATH/环境变量，最后生成《使用规范》文档 |

四件可以全做，也可以只做其中一件——加载后 AI 会先问你要做哪些。

## 安装（30 秒）

把仓库 clone 到你所用 agent 的 skills 目录，目录名保持 `system-cleanup`：

| Agent | 安装位置 |
|---|---|
| **Trae** | `git clone https://github.com/zl2237/system-cleanup.git "$env:USERPROFILE\.trae-cn\skills\system-cleanup"`（全局）或项目 `.trae\skills\` |
| **Claude Code** | `git clone https://github.com/zl2237/system-cleanup.git "$env:USERPROFILE\.claude\skills\system-cleanup"` |
| **Cursor / CodeBuddy / ZCode 等** | clone 到该 agent 对应的 skills 目录（参考其官方文档），同样支持 |

也可以下载 ZIP 解压到上述目录。装完**重启 agent 或新开会话**，直接说：

> 帮我清理 C 盘 / 看看哪些环境变量失效了 / 找找卸载残留

## 为什么敢让它碰你的系统

- **扫描与执行分离**：4 个扫描脚本只读不删；唯一的执行器必须拿到你确认过的 JSON 清单（PlanFile）才会动手
- **注册表先备份**：任何环境变量改动前自动 `reg export`，双击 `.reg` 即可还原
- **迁移不丢数据**：跨盘用 `robocopy /MOVE`，源删失败目标仍在
- **白名单制**：只碰公认的垃圾位置，`hiberfil.sys`、`pagefile.sys`、`Windows.old` 只报告、永不删
- **占用即跳过**：文件被占用时跳过并记录日志，不强杀进程
- **全程留痕**：报告、备份、日志集中在 `桌面\cleanup-report-<日期>\`

## 结构

```
system-cleanup/
├── SKILL.md              # AI 编排指令：四模块流程 + 安全规则
└── scripts/
    ├── env-scan.ps1      # 扫描失效环境变量 / PATH 死条目
    ├── orphan-scan.ps1   # 扫描已装软件清单 + 残留高发区
    ├── junk-scan.ps1     # 扫描垃圾文件（白名单）
    ├── disk-inventory.ps1# 盘点磁盘分布
    ├── clean-executor.ps1# 统一执行器（删变量/PATH条目/目录/清空）
    └── migrate-runner.ps1# 迁移执行器（同卷移动 / 跨卷 robocopy）
```

无需任何依赖：Windows 10/11 + PowerShell 5.1（系统自带）。需要管理员权限的操作会自动弹 UAC。

## FAQ

**Q: 和 CCleaner 这类清理工具有什么区别？**
A: 它不是"一键优化"黑盒。每个删除项都先展示给你（含大小、位置、为什么可删），你确认才执行。判断由 AI 完成（比如区分"钉钉残留"和"还在用的数据目录"），但扣扳机的永远是你。

**Q: 会误删吗？**
A: 扫描是白名单制 + 交叉比对，拿不准的会单独标出来问你，不会混在"可删"里。

**Q: 出问题怎么回滚？**
A: 环境变量有 `.reg` 备份可直接导入；文件删除走回收站逻辑外的目录均有日志记录（Temp/缓存类本身可再生）。

**Q: 不是 Trae 用户，能用吗？**
A: 能。核心是标准 SKILL.md 格式 + 纯 PowerShell 脚本，任何支持 Agent Skills 的客户端加载后即用；脚本本身也可以脱离 agent 手动运行（每个脚本头部有用法注释）。

## License

MIT
