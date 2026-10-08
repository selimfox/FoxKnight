# 庭院模块化像素资源 · 第二轮切片 v0.2

第三轮原生像素模块已经作为**待接入候选**独立列在 [`PIXEL_MODULES.md`](PIXEL_MODULES.md)：6 种可编辑 3×3 石板模块、2 种三层墙、独立浅水／倒影 mask 与 4×2 边缘装饰。本文件下方仍描述三关目前接入的第二轮资源；在 Coding 完成场景迁移及实机回归前，不把候选写成“已在三关使用”。

状态：**可逐像素编辑且已接入三关的第二轮制作资源；功能与实机截图已检查，创作者审美验收未完成**。创作者已确认左上浅水是纯视觉、可走的表面；狐狸与敌人走过时碰撞和斩击判定不变，进入水域才显示随动作变化的倒影。本目录提供水面、同格遮罩、波纹和光斑素材；倒影与动态灯光实现分别位于 `scripts/world/water_surface.gd`、`scripts/world/courtyard_moonlight.gd`。

## 依据与原创性

- 当前 `docs/GDD.md`：暗黑幻想、像素风、俯视角；战斗区必须优先读清角色、边界和刀型范围。`docs/art/VisualPackagingAudit.md` 仅是包装交接，不扩充规则。
- A 庭院概念图 `assets/art/concepts/level01_mood_A_courtyard_study_v2.png` 只作气氛与色温参考，未裁切、缩小、取样或描摹成这些像素图。
- 用户提供的《赛菲利亚》两张截图用于学习统一像素尺度、明晰色块及场景层级，不复制其角色、房屋、地块轮廓或 UI。归属：TEAM HORAY，[官方 Steam 页面](https://store.steampowered.com/app/2436940/Sephiria/)，2026-09-26 查阅。
- 本批所有图形由仓库内 `build_environment_atlas.py` 在原生 16px 网格上用明确的点、线和封闭色块原创绘制；无第三方贴图或 AI 生成像素输入。脚本是初始绘制配方，`*_source.png` 是可用逐像素工具修改的源稿。重新运行脚本会重置手工修改，故默认拒绝覆盖，只有明确传入 `--force` 才重建。

## 统一样例规格

| 项目 | 规格 |
| --- | --- |
| 原生格 | 16×16 RGBA，1 原生像素 = 2 世界像素；这是本轮可撤销的样例尺度，不锁定项目全局规范 |
| Godot 格 | 32×32 世界像素，TileSet atlas 一格 32×32；导出 `*.png` 为源稿 nearest 2×，不进行滤镜或 AI 缩图 |
| 视口检查 | 当前 960×540；在原生 1×、导出 2×和实际游戏镜头下均需看轮廓、接缝、战斗范围对比 |
| 透明 | 地砖、墙、道具和水面轮廓仅 0/255 alpha；独立月光/火光 wash 有有意设计的 4 级 alpha 台阶，仅作为附加视觉层，不参与碰撞、倒影 mask 或交互 |
| 调色 | 主石 `#30394F`、暗石 `#293247`、缝/轮廓 `#242C3C/#171D2B`、亮边 `#47546A/#65748B`；植物 `#405A49`，浅水下石 `#405065`、高光 `#8BA7B4`；火芯 `#FFD779` 仅用于边缘灯具 |
| 导入建议 | 禁用过滤/纹理 mipmap；保持整数缩放和像素对齐，避免当前整张底图的非整数缩放模糊。具体项目设置与 TileSet 配置由 Coding 确认 |

## 文件与 atlas 格位

坐标均为**零基** `(列,行)`；下表位置在原生 PNG 中乘 16，在导入 PNG 中乘 32。没有图集留白或间距。

| 源稿 / 导入图 | 原生尺寸 / 导入尺寸 | 格位和用途 | 接入层 |
| --- | --- | --- | --- |
| `courtyard_floor_source.png` / `courtyard_floor.png` | 48×32 / 96×64 | 行 0：(0,0) 安静主石 A、(1,0) 错缝 B、(2,0) 暗砖 C；行 1：(0,1) 裂纹 D、(1,1) 月光中间调 E、(2,1) 缺角 F。六种是同一可走地面变化，不编码特殊格 | Floor visual，同既有 Floor TileMap 的碰撞真值分离 |
| `courtyard_slab_source.png` / `courtyard_slab.png` | 128×32 / 256×64 | 四组横排的 2×2 格大型石板，组的左上 TileSet 格位为 (0,0)、(2,0)、(4,0)、(6,0)。每组 32×32 原生像素、64×64 世界像素；可拆成四个 32 世界像素 TileMap 格排布，减少细碎砖纹重复 | Floor visual 的低频主层，与普通单格地砖混排；中央优先用低对比版本 |
| `courtyard_wall_source.png` / `courtyard_wall.png` | 64×48 / 128×96 | 行 0：上边 A/B、上左角、上右角；行 1：下边 A/B、下左角、下右角；行 2：左边 A/B、右边 A/B | Walls visual；碰撞仍以既有 Walls TileMap 为准 |
| `courtyard_decor_source.png` / `courtyard_decor.png` | 64×64 / 128×128 | 原行 0–1 格位保持不变。新增行 2：(0,2) 墙下碎石、(1,2) 破石、(2,2) 左缘藤、(3,2) 右缘藤；行 3：(0,3) 水岸湿碎石、(1,3) 水滴过渡、(2,3) 苍白裂板、(3,3) 墙脚低藤 | 独立透明 Decoration TileMapLayer；新增格位需在 TileSet 登记；碎石藤蔓以边缘为主，水岸过渡摆在池外邻格，不在主战斗区密铺 |
| `courtyard_water_source.png` / `courtyard_water.png` | 48×80 / 96×160 | 原 3×3 格位不变；新增 `(0,3)` 北向外溢、`(1,3)` 西向外溢、`(2,3)` 东向外溢、`(0,4)` 南向外溢。外围四格须接对应中心边格；水下石缝、湿石底和断裂月光点把水与铺石联系起来 | 独立无碰撞 Water Surface TileMapLayer，置于 Floor 之上、角色之下；新格须注册 TileSet |
| `courtyard_reflection_mask_source.png` / `courtyard_reflection_mask.png` | 48×80 / 96×160 | 与全部 13 个水面格位逐一对应；白色表示可显示倒影的水域，透明处不显示。不是已烘焙的狐狸或敌人倒影 | Coding 实时倒影裁剪 mask，必须与水层逐格同坐标 |
| `courtyard_ripple_source.png` / `courtyard_ripple.png` | 64×16 / 128×32 | (0..3,0) 为四个离散扩散帧；单帧 16×16，中心为 (8,8) 原生像素 | 水面上方的纯视觉动效；触发与时长待 Coding/Art 实机验证 |
| `courtyard_props_source.png` / `courtyard_props.png` | 64×160 / 128×320 | 原行 0–2 不变。新增行 3：倒塌石堆 A/B、墙根植物 A/B；行 4：半截石标 A/B、悬垂蔓叶 A/B。16×32 原生一格，新增格位需在 TileSet 登记 | 独立透明 Props；地面物脚底锚 (8,31)，残旗、垂藤和蔓叶墙上锚 (8,0)；视觉道具无碰撞及交互承诺 |
| `courtyard_moon_pool_source.png` / `courtyard_moon_pool.png`；`courtyard_fire_pool_source.png` / `courtyard_fire_pool.png` | 各 128×96 / 256×192 | 可选低透明洗色。原生尺寸为 16 的整数倍，nearest 2×；月光冷蓝白，火光琥珀橙，未包含火焰动画 | 独立 additive 或普通 alpha 光照视觉层，非 TileSet、非底图；由 Coding 在场景中按光源锚点叠加与轻度呼吸，不改命中 |

`courtyard_layout_preview.png` 是使用这些格位拼出的 **960×540 静态排布检查图**，仅验证模块可组合与低频/高频分布；不是可导入的整张背景，不承载碰撞，也不证明动态或正式美术质量。三个关卡应在共用模块基础上重新编排空间与边缘陈设，不复制这张固定排布图。旧截图里全房间的地砖明亮小图案反复出现；第二轮把常用 A 简化，必须同时在三关 TileMap 中把 A 的使用率从当前约 84% 降至约 35–45%，散排 B/C/E，D/F 少量点缀，并按 2×2 石板单元布置 TileSet source 1。否则只换 PNG 仍是规则棋盘，不能宣称已解决重复。

接入新增格位时保留原格位不动：`courtyard_decor_tileset.tres` 将 atlas `(0..3,2..3)` 注册为 8 个独立 32×32 格；`courtyard_props_tileset.tres` 注册 `(0..3,3..4)` 为 8 个独立 32×64 格；`courtyard_water_tileset.tres` 注册 `(0..2,3)` 及 `(0,4)` 为 4 个独立 32×32 水格。水域四个外溢格可按北 `(0,3)`、西 `(1,3)`、东 `(2,3)`、南 `(0,4)` 逐边选用，避免每关都是完整 3×3 方形；若改变水格，实时反射 mask 会随格位同位更新。岸外还可摆少量 Decoration `(0,3)` 湿碎石与 `(1,3)` 水滴，但这两格只是潮湿地面、**不触发倒影**。已有 Floor source 1 的大石板格位无需更新，只需在编辑器中按连续 2×2 原生石板顺序编排；不要用 `author_courtyard_once.gd --force` 覆写关卡。光斑样例建议：月光落点在左上浅水中心稍偏下 20–30 世界像素、暖光只沿四角火盆，不铺到中央战斗线；现有程序光可从 `moon_opacity=0.15–0.17`、`fire_opacity=0.15–0.18` 起实机试，但不应仅凭静图定稿，且闪光亮度不可盖过瞄准圈。

## 排布、层级与交互边界

建议视觉顺序：Floor → Decoration → Water Surface → 动态倒影（受 mask 限制）→ 水纹 → 无碰撞地面 Props → 角色接地影/角色 → 墙上旗帜/前景 Props → HUD。火盆的动态光与角色投影不由静态图代替。现有 Floor/Walls 是**唯一**地形碰撞、寻路和斩击截断来源；新增视觉层不得自行改变它们。水域目前只作纯视觉：所有角色照常走过；水面是材质而非交互、伤害或第二层攻击范围。灯具、植物、碎石和旗帜也不宣称有碰撞或交互。

水域范围须在第一关左上低干扰区域由 Coding/Art 共同排布，避开起始狐狸与主要瞄准圆；只有角色脚底进入 mask 所覆盖的水格，才由 Coding 创建随当前帧、朝向和位置变化的低对比倒影。倒影与接地影是两个不同视觉通道；不能把本图集中的白色 mask 或固定暗块直接当倒影。步入/离开时需连续裁剪，波纹可随接地点启动，不能改变攻击真值。

## 已检查与尚未验收

- 已检查：所有源稿是低分辨率 RGBA 像素文件；导出以 nearest 精确 2×；地砖和墙格边缘无半透明；水与 mask 像素轮廓同位；图集坐标和透明 Props 可由脚本重建。第二轮静态预览已逐图检查：地面重复的高亮记号减少、水下石板可读、边缘有碎石与藤蔓，但整体细节量仍低于 A 庭院概念目标。
- 已接入：新增格位已注册到三个 TileSet；三关 Floor、Decoration、Water Surface、Props 已重新编排，场景中没有整张固定底图。独立月光／火光 wash 与角色当前帧倒影、短水纹已经接入。`tests/acceptance/environment_visual_runner.gd` 验证编辑地格／墙格／装饰、水域进出与原碰撞／斩击；`output/ui_production_level_01.png` 至 `_03.png` 是当前三关实机截图，`output/environment_v2_water_01_enter.png` 至 `_04_exit.png` 是水面序列。
- 仍未完成：与 A 庭院概念相比，地砖细节、墙体厚度、边缘道具密度仍有明显差距；当前并非创作者认可的最终正式美术。后续手工调整应直接在三个 `level_0X.tscn` 的 TileMapLayer 中进行，**不要重跑**一次性 `scripts/world/recompose_courtyard_v2_once.gd` 或旧 `author_courtyard_once.gd --force` 覆盖新编排。
- 接入门槛：编辑任意地格、墙角、浅水和 Props 后画面不依赖固定底图；原有碰撞/胜败不变；960×540 下角色、近弧/远直预告与边界清楚；角色走入/离开水域的视频验证倒影和影子，且光向不冲突。
