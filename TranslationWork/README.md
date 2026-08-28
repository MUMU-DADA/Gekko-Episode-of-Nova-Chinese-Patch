# Gekko Episode of Nova 汉化工作区

`TranslationPatch_Archive/Tools/ExtractTextCandidates.ps1` 只读扫描 `sharedassets0.assets`，生成待翻译候选表。它不会修改原始游戏文件。

运行时补丁读取 `BepInEx/plugins` 下所有 `GekkoNova_*.tsv`，按完整字符串精确替换 Unity UI 文本，并为包含日文/中文字符的文本尝试使用 Windows 中文字体。

当前可直接交给测试的文件位于 `BepInEx/plugins`：`GekkoNovaPatch.dll`、`GekkoNova_zh.tsv`、`GekkoNova_titles.tsv`、`GekkoNova_route_01.tsv`、`GekkoNova_route_02.tsv` 以及 `GekkoNova_story_01.tsv` 至 `GekkoNova_story_61.tsv`。BepInEx 已部署在游戏根目录，启动游戏时会自动加载插件。

剧情翻译按连续场景拆分为 `GekkoNova_story_XX.tsv`。插件会自动读取全部同名前缀词表，无需把文件手工合并。

补丁不覆盖原始 `*_Data` 资源；翻译表缺失的句子会继续显示原文，便于逐章补齐和定位遗漏。

如修改了插件或翻译表，从游戏根目录运行 `TranslationPatch_Archive/Tools/BuildPatch.ps1`。脚本会先检查来源键、重复项、Utage 标签、变量与换行，再离线重编译插件；无需 NuGet 或网络。也可以单独运行 `TranslationPatch_Archive/Tools/ValidateTranslations.ps1` 检查词表。

当前校验覆盖 9,387 条译表记录（9,352 个唯一源文）；候选表中的对白类文本已全部建立译文。剩余候选主要是背景、立绘、CG、音效等资源标识，是否翻译取决于是否希望汉化回顾/资源列表中的名称。

剧情翻译必须保留 Utage 标签、变量、换行和语音标记；后续翻译表应以剧情段落为单位补齐，避免逐句脱离上下文。
