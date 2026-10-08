# 正式场景接入与回归 · 2026-10-01

本报告记录 Coding 完成的已批准美术替换，不定义新玩法。当前入口仍 GDD v0.1 / TDD_v0.1；未修改 GDD、TDD、窗口设置或 Git。

## 当前接入

- 角色：E R4，狐狸 48×48 原生留白画布，脚锚 [24,39]；士兵 32×36，[16,33]；CharacterAnimation 从可替换 atlas + frames.json 消费四向 idle/walk/stop/ready/ready_walk/cancel/straight/arc/post，敌人 idle/walk/hit/death。删除不再消费的 generated 演员 texture exports 与旧 DeathBurst。取消和移动瞄准不锁输入；死亡资格与计数时点不变。
- 墙边：演员 Visual z4 高于 Walls/Props，GroundShadow 仍保持低层；四边实机证据 actor_edge_*.png。
- 环境：三关各独立 9×12 atlas、12 个 3×3 完整宏；中心八种安静朝向，显著错缝/湿/破外围。外部 TileSet .tres 可编辑；每关保留现场读取到的 420 Floor、82 Walls、9 Water cells。水 atlas 按邻接选岸，源图修正双瓣岸线后重新导入。Props 与光源位置不变；火焰六帧8fps。
- 水：脚底 mask 驱动反射/水纹。倒影 24%，依据当前 frame height 与 anchor 对齐翻转后的脚。水纹 .24s；压地影独立 factor .45，在 .08s 进出水，和死亡 fade 相乘。
- UI：R3 当前导出，透明 focus 叠层，按下 content top/bottom 8/4 产生 2world 像素下沉。旧 TitleMotion 金色双重焦点与glint退役。R4菜单头像正式96×96。HUD数字米白，刀型签 y18，提示短时显示，关卡提示轻量。双刀型预览用独立世界2px栅格，弱圈只透明度呼吸；填充 arc .055 / straight .065。查询尺寸、截断和真实斩击均未改。
- 结果：先按真实幸存sprite Canvas rect+8margin选择上/下条；两侧均冲突拆224×146结果块和194宽动作块，搜索不交叠位置，也避开HUD。已有三关及六目标密集配置已验证；控件重排保留重试/下一关/最终返回分支。
- 死亡余迹：即时命中FX，.10s后进入death视觉时出death余迹，不延迟死亡真值；对应FX专门回归由主控维护。

## 证据

本机 output/art_revision_20260930/ 中的 smoke_test.log、campaign_test.log、character_test.log、environment_test.log、ui_test.log、integration_test.log 均 RESULT PASS。capture.log 记录82张实际Godot图形截图。包括菜单960×540/1280×720/1920×1080/1600×540、三关 observe/arc/straight/moving_aim/cancel/release00..05/result、四边靠墙、水中四向及退出、30帧连续实际控制器入水/转向/出水、真实六士兵密集结果避让。功能通过不能证明最终审美或游戏体验。

新增专项检查覆盖移动瞄准持续动画、取消不耗刀、完整状态/四向、实际翻转脚锚、水内地影减弱且不覆盖死亡fade、离水恢复、上下均冲突及六目标密集结果不遮sprite+8margin、重排后最终返回分支。环境可编辑层测试保持编辑、墙碰撞生成与斩击截断有效。

## 复核与限制

Environment Art 已在修水后的三关、南墙与水转向/退出实机图复核：单片不规则水岸、地面演员对比、火盆连接和南墙脚底静态可读。角色Art已完成最终48版角色、头像、L2士兵、四边靠墙、密集结果与全部30张连续过水原图的独立目测，未发现阻塞缺陷；证据见[角色复核报告](../../../../assets/art/production/characters/e_20260930/REVIEW_20261001.md)。保留近身士兵局部遮脸/手、低亮阴影与倒影层次不易区分，以及0.08s采样间单帧未覆盖的限制。窗口对照只提供证据，本轮未决定或更改整数倍率/留边/扩展视野取舍。自动化断言不代替实际运行审美验收。

连续水取证：water_sequence_00..29.png 为每.08s采样的实际Input控制过程。每样本校验脚底mask与反射visible一致，四向转向样本处于mask内，实际进入与退出均发生；capture.log记录WATER SEQUENCE PASS。对应30帧的入水、四向移动/转向、出水已由Art逐张目测复核；该结论不代表完整逐渲染帧视频或所有动作组合均已覆盖。

## 退出资源清理收口

主控精确退休13张旧generated占位导出及对应import，共26文件。逐文件备份与SHA-256见[退休清单](../../RetiredPlaceholders_2026-10-01.json)。仍使用的旧floor/wall和历史审稿引用未删除。清理后导入日志`post_cleanup_import.log`（本机 output/art_revision_20260930/）退出0，功能烟测`post_cleanup_smoke.log`（本机 output/art_revision_20260930/）为PASS；最终引用清单为56文件、0缺失。此处记录主控清理结果，未额外运行测试或修改代码。

> 上传说明：本目录保存交付页使用的精选截图。文中日志来自既有本机测试记录，未随此快照上传；此次上传未重新运行游戏验收。
