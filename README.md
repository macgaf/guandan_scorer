# 惯蛋记分器 iOS App

这是一个专门为惯蛋扑克牌游戏设计的iOS记分应用。

## 功能特点

- **首页**：查看所有历史对局记录，支持按玩家姓名搜索
- **新建对局**：输入两组4名玩家信息，选择庄家开始游戏
- **游戏界面**：
  - 实时显示两组分数和庄家状态
  - 点击团队区域选择记分动作（双贡、单贡、自贡、胜利）
  - 支持撤销和重做操作
- **数据持久化**：所有游戏记录自动保存

## 开发环境要求

- macOS 12.0 或更高版本
- Xcode 14.0 或更高版本
- iOS 15.0 或更高版本的设备或模拟器

## 如何运行

1. 打开 Xcode
2. 选择 "Create a new Xcode project"
3. 选择 iOS > App，点击 Next
4. 填写项目信息：
   - Product Name: GuandanScorer
   - Team: 选择你的开发团队
   - Organization Identifier: 填写你的组织标识符（如 com.yourname）
   - Interface: SwiftUI
   - Language: Swift
   - 取消勾选 "Use Core Data" 和 "Include Tests"
5. 选择项目保存位置为 `GuandanScorer` 文件夹
6. 将生成的项目中的所有 Swift 文件替换为本项目中的文件
7. 运行项目（Command + R）

## 项目结构

```
GuandanScorer/
├── GuandanScorer/
│   ├── GuandanScorerApp.swift    # 应用入口
│   ├── Info.plist                 # 应用配置
│   ├── Models/
│   │   └── Game.swift             # 数据模型
│   ├── ViewModels/
│   │   └── GameViewModel.swift    # 游戏逻辑
│   └── Views/
│       ├── ContentView.swift      # 主视图
│       ├── HomeView.swift         # 首页
│       ├── NewGameView.swift      # 新建对局
│       └── GameView.swift         # 游戏界面
└── README.md
```

## 游戏规则说明

### 记分等级
2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 → J → Q → K → A1 → A2 → A3

### 升级规则
- **双贡**：本队双下，对方升3级，对方成为庄家
- **单贡**：本队单下，对方升2级，对方成为庄家
- **自贡**：本队自贡，本队升1级，保持庄家不变
- **胜利**：当一方打到Ax（第x次打A）或对方打到A3时可以选择胜利

## 注意事项

- 应用使用 UserDefaults 存储游戏记录，数据保存在本地
- 应用仅支持竖屏模式
- 最低支持 iOS 15.0 