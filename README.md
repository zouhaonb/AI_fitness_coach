# 智练鸿蒙 — AI 私人健身教练

基于 HarmonyOS NEXT 开发的智能健身训练应用，内置 18 种运动动作库，集成 DeepSeek AI 生成个性化训练建议，配合 TTS 语音播报，打造你的 AI 私人健身教练。

## 功能特性

### 今日计划
- 根据训练目标和频率自动生成每日训练计划
- 训练进度实时追踪，支持完成/跳过操作
- 连续打卡天数统计

### 运动执行
- 倒计时 / 计数双模式自动切换
- TTS 语音播报训练指令（动作名称、组数、倒计时）
- 动作间自动休息倒计时
- 训练完成总结（运动时长、消耗卡路里）

### 运动库
- 18 种常见运动，按胸、背、腿、肩、手臂、核心分类
- 支持名称搜索和分类筛选
- 运动详情页含图文描述和参考参数

### 数据统计
- 打卡日历热力图（近 12 周）
- 本周运动次数、时长、卡路里统计
- 训练部位占比饼图（Canvas 自定义绘制）
- AI 智能训练建议（训练量 / 部位均衡 / 计划优化 / 休息建议）

### 个人中心
- 训练目标设置（减脂 / 增肌 / 保持健康）
- 训练频率设置（每周 1-7 天）
- 训练提醒开关
- AI 激励语（基于训练数据生成个性化鼓励）

## 技术栈

| 层面 | 技术 |
|------|------|
| 开发语言 | ArkTS |
| UI 框架 | ArkUI 声明式组件 |
| 状态管理 | @State + @Prop + AppStorage |
| 数据持久化 | Preferences（配置）+ RDB（运动记录） |
| TTS 语音 | @ohos.multimedia.audio TextToSpeech |
| AI 服务 | DeepSeek API（chat/completions） |
| 图表绘制 | Canvas 自定义绘制 |
| 网络请求 | @kit.RemoteCommunicationKit |

## 开发环境

- DevEco Studio 6.0.2 Release
- HarmonyOS 6.0.2 Release SDK (API 22)
- 测试设备：华为手机 / 平板

## 项目结构

```
entry/src/main/ets/
├── common/                # 公共模块
│   ├── ConfigState.ets    # 配置状态管理
│   ├── DataState.ets      # 数据状态管理
│   ├── DeviceUtils.ets    # 设备适配工具
│   ├── ExerciseUtils.ts   # 运动工具函数
│   └── GlobalContext.ts   # 全局上下文
├── entryability/          # 应用入口
├── model/                 # 数据模型
│   ├── ExerciseModel.ts   # 运动模型
│   └── PlanModel.ts       # 计划模型
├── pages/                 # 页面
│   ├── Index.ets          # 首页（今日计划）
│   ├── Login.ets          # 登录页
│   ├── ExerciseLibrary.ets # 运动库
│   ├── ExerciseDetail.ets  # 运动详情
│   ├── ExerciseExecution.ets # 运动执行
│   ├── Statistics.ets     # 数据统计
│   ├── Profile.ets        # 个人中心
│   ├── PlanSetting.ets    # 训练计划设置
│   ├── AboutApp.ets       # 关于应用
│   └── AuthorInfo.ets     # 作者介绍
└── service/               # 服务层
    ├── AIService.ts       # DeepSeek AI 服务
    ├── AuthService.ts     # 认证服务
    ├── ConfigService.ts   # 配置服务
    ├── DatabaseService.ts # 数据库服务
    ├── PlanService.ts     # 计划服务
    ├── TTSService.ts      # TTS 语音服务
    └── InitData.ts        # 初始数据
```

## 快速开始

1. 克隆项目
   ```bash
   git clone https://github.com/<your-username>/AI_fitness_coach.git
   ```

2. 使用 DevEco Studio 6.0.2+ 打开项目

3. 等待依赖安装完成（ohpm install）

4. 连接真机或启动模拟器，点击 Run 运行

> **注意：** AI 功能需要配置 DeepSeek API Key，请在 `AIService.ts` 中替换为自己的 Key。

## 适配说明

应用已适配手机和平板设备，使用栅格布局 + 百分比宽度实现响应式设计：

- **手机竖屏**：单列布局，底部 TabBar 导航
- **平板/横屏**：自适应宽度，内容区域居中

## 许可证

本项目仅用于学习交流。
