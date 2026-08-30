# 真机与发布卡点

## 当前已确认

- App 名称：提词器Prompt。
- Bundle ID：`com.sheng.teleprompterprompt`。
- 版本号：`1.0`。
- 构建号：`1`。
- 最低系统：iOS/iPadOS 17.0。
- 设备范围：iPhone + iPad。
- 权限文案已配置：相机、麦克风、相册写入。
- 隐私清单已配置：不追踪、不声明数据收集、不声明追踪域名。

## 卡点 1：开发者账号 Team ID 为空

当前 `DEVELOPMENT_TEAM` 还是空值。模拟器构建不受影响，但真机安装、Archive、TestFlight 上传都需要 Team。

处理方式：

- 在 Xcode 打开 `TeleprompterApp.xcodeproj`。
- 选择 target `TeleprompterApp`。
- 进入 Signing & Capabilities。
- 勾选 Automatically manage signing。
- Team 选择你的 Apple Developer 团队。
- 如果 App Store Connect 里 Bundle ID 已占用，需要改成你的正式 Bundle ID。

## 卡点 2：真机权限无法用模拟器完全验收

模拟器可以验证 UI 和大部分状态，但不能代表真实相机、麦克风、相册写入链路。

处理方式：

- 接入一台 iPhone。
- 首次进入拍摄提词，确认相机权限先出现，麦克风权限随后出现。
- 拒绝权限一次，确认 App 弹出提示并能跳到系统设置。
- 重新允许权限后，进入拍摄提词，录制 5-10 秒视频。
- 停止录制，确认视频保存到系统相册。

## 卡点 3：App Store 截图还没生成正式版

当前只有模拟器验证截图，不是正式商店展示图。

处理方式：

- 用最终 UI 生成 iPhone 截图：首页、脚本列表、全屏提词、拍摄提词、设置。
- 用最终 UI 生成 iPad 截图：首页、全屏提词、拍摄提词。
- 拍摄提词截图建议用真机实拍或模拟相机占位，避免黑屏显得功能不可用。

## 卡点 4：Archive/TestFlight 需要账号权限

Archive 可以本地触发，但上传 TestFlight 需要登录 Xcode 的 Apple ID，并且账号要有 App Manager 或更高权限。

处理方式：

- Xcode 登录 Apple ID。
- Product -> Archive。
- Organizer 中选择 Distribute App。
- 选择 App Store Connect -> Upload。
- 先走 TestFlight 内部测试，不急着正式提交审核。
