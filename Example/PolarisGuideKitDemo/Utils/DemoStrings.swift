//
//  DemoStrings.swift
//  PolarisGuideKitDemo
//
//  Created by noodles on 2025/12/31.
//

import Foundation

/// Demo 界面所有本地化字符串
enum DemoStrings {
    
    private static var isChinese: Bool {
        LanguageManager.shared.shouldUseChinese
    }
    
    // MARK: - ViewController (Main List)
    
    enum Main {
        static var title: String {
            isChinese ? "PolarisGuideKit 示例" : "PolarisGuideKit Demo"
        }
        
        static var sectionHeader: String {
            isChinese ? "选择一个示例" : "Select a Demo"
        }
        
        static var languageSettingTitle: String {
            isChinese ? "语言" : "Language"
        }
    }
    
    // MARK: - Demo Cases
    
    enum DemoCases {
        static var roundedRectTitle: String {
            isChinese ? "圆角矩形聚焦样式" : "Rounded Rect Focus Style"
        }
        static var roundedRectSubtitle: String {
            isChinese ? "使用 UISegmentedControl 切换圆角模式" : "Use UISegmentedControl to switch corner radius modes"
        }
        
        static var circleTitle: String {
            isChinese ? "圆形聚焦样式" : "Circle Focus Style"
        }
        static var circleSubtitle: String {
            isChinese ? "使用 UISegmentedControl 切换半径模式" : "Use UISegmentedControl to switch radius modes"
        }
        
        static var multiStepTitle: String {
            isChinese ? "多步骤引导" : "Multi-Step Guide"
        }
        static var multiStepSubtitle: String {
            isChinese ? "多步骤引导，支持跳过，多种聚焦样式" : "Multiple steps with Skip, various FocusStyles"
        }

        static var audioGuideTitle: String {
            isChinese ? "带音频引导" : "Guide with Audio"
        }
        static var audioGuideSubtitle: String {
            isChinese ? "引导时播放音频并同步 Lottie 动画" : "Play audio and sync Lottie during the guide"
        }
        
        static var touchForwardingTitle: String {
            isChinese ? "触摸转发" : "Touch Forwarding"
        }
        static var touchForwardingSubtitle: String {
            isChinese ? "forwardsTouchEventsToFocusView + ControlEventCompleter" : "forwardsTouchEventsToFocusView + ControlEventCompleter"
        }
        
        static var dismissOnOutsideTapTitle: String {
            isChinese ? "点击外部关闭" : "Dismiss on Outside Tap"
        }
        static var dismissOnOutsideTapSubtitle: String {
            isChinese ? "dismissesOnOutsideTap 行为演示" : "dismissesOnOutsideTap behavior"
        }
    }
    
    // MARK: - Common
    
    enum Common {
        static var startGuide: String {
            isChinese ? "开始引导" : "Start Guide"
        }
        
        static var next: String {
            isChinese ? "下一步 →" : "Next →"
        }
        
        static var skip: String {
            isChinese ? "跳过" : "Skip"
        }
        
        static var back: String {
            isChinese ? "返回" : "Back"
        }
        
        static var cancel: String {
            isChinese ? "取消" : "Cancel"
        }
    }
    
    // MARK: - TouchForwarding Demo
    
    enum TouchForwarding {
        static var tapMeButton: String {
            isChinese ? "点击我！" : "Tap Me!"
        }
        
        static var touchForwardingInfoTitle: String {
            isChinese ? "触摸转发" : "Touch Forwarding"
        }
        static var touchForwardingInfoDesc: String {
            isChinese ? "forwardsTouchEventsToFocusView = true 允许您在引导过程中与高亮按钮进行交互。" : "forwardsTouchEventsToFocusView = true allows you to interact with the highlighted button during the guide."
        }
        
        static var completerInfoTitle: String {
            isChinese ? "ControlEventCompleter" : "ControlEventCompleter"
        }
        static var completerInfoDesc: String {
            isChinese ? "当特定控件事件发生时（如按钮点击）自动完成引导。" : "Automatically completes the guide when a specific control event occurs (e.g., button tap)."
        }
        
        static var arrowBuddyInfoTitle: String {
            isChinese ? "ArrowBuddyView" : "ArrowBuddyView"
        }
        static var arrowBuddyInfoDesc: String {
            isChinese ? "使用 updateLayout() 动态定位箭头和提示相对于聚焦视图的位置。" : "Uses updateLayout() to dynamically position the arrow and hint relative to the focus view."
        }
        
        static var hintBuddyTitle: String {
            isChinese ? "提示" : "Hint"
        }
        
        static var hintBuddyMessage: String {
            isChinese ? "您只能(必须)点击「点击我！」按钮区域才能继续。\n\n点击后引导将自动消失并进入结果界面，效果与直接点击按钮完全一致。" : "You must tap the highlighted area to proceed.\n\nUpon tapping, the guide will automatically dismiss and the event will pass through, navigating you to the result screen just as a direct tap would."
        }
    }
    
    // MARK: - TapResult ViewController
    
    enum TapResult {
        static var title: String {
            isChinese ? "点击结果" : "Tap Result"
        }
        
        static var successTitle: String {
            isChinese ? "🎉 跳转成功" : "🎉 Navigation Success"
        }
        
        static var explanationTitle: String {
            isChinese ? "这说明了什么？" : "What does this mean?"
        }
        
        static var explanationText: String {
            if isChinese {
                return """
                您已经通过原有的点击处理逻辑跳转到了这个新界面。
                
                这证明了 PolarisGuideKit 的新手引导功能：
                
                ✅ 不会侵入您的原有业务逻辑
                ✅ 不需要修改按钮的点击处理代码
                ✅ 完全透明地转发触摸事件
                ✅ 引导完成后业务逻辑正常执行
                
                通过设置 forwardsTouchEventsToFocusView = true，用户在引导过程中点击高亮按钮时，触摸事件会被完整地传递给原始按钮，确保原有的点击行为得以保持。
                """
            } else {
                return """
                You navigated to this screen through the original tap handler logic.
                
                This demonstrates that PolarisGuideKit's guide feature:
                
                ✅ Does not intrude on your existing business logic
                ✅ Does not require modifying button tap handlers
                ✅ Transparently forwards touch events
                ✅ Business logic executes normally after guide
                
                By setting forwardsTouchEventsToFocusView = true, touch events on the highlighted button are fully forwarded to the original button, preserving its original tap behavior.
                """
            }
        }
        
        static var codeComment: String {
            isChinese ? "// 关键代码" : "// Key code"
        }
    }
    
    // MARK: - RoundedRect Demo
    
    enum RoundedRect {
        static var premiumFeatures: String {
            isChinese ? "高级功能" : "Premium Features"
        }
        static var unlockTools: String {
            isChinese ? "解锁所有高级工具" : "Unlock all advanced tools"
        }
        
        static var cornerRadiusMode: String {
            isChinese ? "圆角模式" : "Corner Radius Mode"
        }
        
        static var segmentFixed: String {
            isChinese ? "固定" : "Fixed"
        }
        static var segmentFollow: String {
            isChinese ? "跟随" : "Follow"
        }
        static var segmentScale: String {
            isChinese ? "缩放" : "Scale"
        }
        
        static var fixedInfoTitle: String {
            ".fixed(CGFloat)"
        }
        static var fixedInfoDesc: String {
            isChinese ? "高亮圆角保持固定值不变，无论聚焦视图如何变化。" : "Highlight corner radius stays constant at a fixed value, regardless of focus view changes."
        }
        
        static var followInfoTitle: String {
            ".followFocusView(delta:)"
        }
        static var followInfoDesc: String {
            isChinese ? "高亮圆角 = focusView.cornerRadius + delta。在视图圆角基础上添加固定偏移。" : "Highlight corner radius = focusView.cornerRadius + delta. Adds a fixed offset to the view's corner radius."
        }
        
        static var scaleInfoTitle: String {
            ".scaleWithFocusView(multiplier:)"
        }
        static var scaleInfoDesc: String {
            isChinese ? "高亮圆角 = focusView.cornerRadius × multiplier。与视图成比例缩放。" : "Highlight corner radius = focusView.cornerRadius × multiplier. Scales proportionally with the view."
        }
        
        static var liveDemoTitle: String {
            isChinese ? "实时演示" : "Live Demo"
        }
        static var liveDemoDesc: String {
            isChinese ? "引导开始后，卡片圆角会从 16pt 动画到 28pt。观察不同模式下高亮的不同反应！" : "After guide starts, the card's corner radius animates 16pt → 28pt. Watch how the highlight reacts differently in each mode!"
        }
        
        static var fixedBuddyTitle: String {
            isChinese ? "固定圆角" : "Fixed Radius"
        }
        static var fixedBuddyMessage: String {
            isChinese ? "模式：.fixed(20)\n\n高亮圆角始终保持 20pt。\n\n⏱ 1.5秒后，卡片圆角：16pt → 28pt\n高亮保持 20pt！" : "Mode: .fixed(20)\n\nHighlight corner radius stays at 20pt always.\n\n⏱ In 1.5s, card corner radius: 16pt → 28pt\nHighlight stays at 20pt!"
        }
        
        static var followBuddyTitle: String {
            isChinese ? "跟随 + 偏移" : "Follow + Delta"
        }
        static var followBuddyMessage: String {
            isChinese ? "模式：.followFocusView(delta: 2)\n\n高亮 = card.cornerRadius + 2pt\n\n⏱ 1.5秒后，卡片：16pt → 28pt\n高亮：18pt → 30pt！" : "Mode: .followFocusView(delta: 2)\n\nHighlight = card.cornerRadius + 2pt\n\n⏱ In 1.5s, card: 16pt → 28pt\nHighlight: 18pt → 30pt!"
        }
        
        static var scaleBuddyTitle: String {
            isChinese ? "缩放 × 倍数" : "Scale × Multiplier"
        }
        static var scaleBuddyMessage: String {
            isChinese ? "模式：.scaleWithFocusView(multiplier: 1.25)\n\n高亮 = card.cornerRadius × 1.25\n\n⏱ 1.5秒后，卡片：16pt → 28pt\n高亮：20pt → 35pt！" : "Mode: .scaleWithFocusView(multiplier: 1.25)\n\nHighlight = card.cornerRadius × 1.25\n\n⏱ In 1.5s, card: 16pt → 28pt\nHighlight: 20pt → 35pt!"
        }
    }
    
    // MARK: - Circle Demo
    
    enum Circle {
        static var favorites: String {
            isChinese ? "收藏夹" : "Favorites"
        }
        
        static var radiusMode: String {
            isChinese ? "半径模式" : "Radius Mode"
        }
        
        static var segmentScaled: String {
            isChinese ? "缩放" : "Scaled"
        }
        static var segmentFixed: String {
            isChinese ? "固定" : "Fixed"
        }
        
        static var scaledInfoTitle: String {
            ".scaledToFocusView(factor:)"
        }
        static var scaledInfoDesc: String {
            isChinese ? "圆形半径 = (视图较窄边 / 2) × factor。与视图大小成比例缩放。" : "Circle radius = (view's narrower side / 2) × factor. Scales proportionally with the view size."
        }
        
        static var fixedInfoTitle: String {
            ".fixed(CGFloat)"
        }
        static var fixedInfoDesc: String {
            isChinese ? "圆形始终具有固定半径，无论视图实际大小如何。" : "Circle always has a constant radius, regardless of the view's actual size."
        }
        
        static var liveDemoTitle: String {
            isChinese ? "实时演示" : "Live Demo"
        }
        static var liveDemoDesc: String {
            isChinese ? "引导开始后，图标会从 72pt 增长到 100pt。观察不同模式下圆形高亮的不同反应！" : "After guide starts, the icon will grow from 72pt to 100pt. Watch how the circle highlight reacts differently in each mode!"
        }
        
        static var scaledBuddyTitle: String {
            isChinese ? "缩放圆形" : "Scaled Circle"
        }
        static var scaledBuddyMessage: String {
            isChinese ? "模式：.scaledToFocusView(factor: 1.3)\n\n圆形半径 = (图标大小 / 2) × 1.3\n\n⏱ 1.5秒后，图标：72pt → 100pt\n圆形会按比例增长！" : "Mode: .scaledToFocusView(factor: 1.3)\n\nCircle radius = (icon size / 2) × 1.3\n\n⏱ In 1.5s, icon: 72pt → 100pt\nCircle will grow proportionally!"
        }
        
        static var fixedBuddyTitle: String {
            isChinese ? "固定圆形" : "Fixed Circle"
        }
        static var fixedBuddyMessage: String {
            isChinese ? "模式：.fixed(52)\n\n圆形始终具有 52pt 半径。\n\n⏱ 1.5秒后，图标：72pt → 100pt\n圆形大小保持不变！" : "Mode: .fixed(52)\n\nCircle always has a 52pt radius.\n\n⏱ In 1.5s, icon: 72pt → 100pt\nCircle stays the same size!"
        }
    }
    
    // MARK: - MultiStep Demo
    
    enum MultiStep {
        static var step1: String {
            isChinese ? "步骤 1" : "Step 1"
        }
        static var step2: String {
            isChinese ? "步骤 2" : "Step 2"
        }
        static var step3: String {
            isChinese ? "步骤 3" : "Step 3"
        }
        
        static var aboutThisDemo: String {
            isChinese ? "关于此示例" : "About This Demo"
        }
        
        static var feature1: String {
            isChinese ? "所有步骤使用 RoundedRectFocusStyle" : "RoundedRectFocusStyle for all steps"
        }
        static var feature2: String {
            isChinese ? "跳过按钮可提前退出引导" : "Skip button to exit the guide early"
        }
        static var feature3: String {
            isChinese ? "平滑的过渡动画" : "Smooth transition animations"
        }
        
        static var tipLabel: String {
            isChinese ? "点击「下一步」继续或「跳过」退出。" : "Tap 'Next' to proceed or 'Skip' to exit."
        }
        
        static var step1of3Title: String {
            isChinese ? "第 1 步，共 3 步" : "Step 1 of 3"
        }
        static var step1Message: String {
            isChinese ? "欢迎使用引导！\n\n这是第一步，使用圆角矩形高亮样式。" : "Welcome to the guide!\n\nThis is the first step with a rounded rect highlight style."
        }
        
        static var step2of3Title: String {
            isChinese ? "第 2 步，共 3 步" : "Step 2 of 3"
        }
        static var step2Message: String {
            isChinese ? "进展顺利！\n\n注意步骤之间的平滑动画。" : "Great progress!\n\nNotice the smooth animation between steps."
        }
        
        static var step3of3Title: String {
            isChinese ? "第 3 步，共 3 步" : "Step 3 of 3"
        }
        static var step3Message: String {
            isChinese ? "即将完成！\n\n点击「下一步」完成或「跳过」退出。" : "Almost done!\n\nTap 'Next' to complete or 'Skip' to exit."
        }
    }

    // MARK: - AudioGuide + Lottie Demo

    enum AudioGuide {
        static var headerTitle: String {
            isChinese ? "语音讲解示例" : "Audio Narration Demo"
        }
        static var headerSubtitle: String {
            isChinese ? "引导开始时播放音频，并驱动 Lottie 动画" : "Play audio during the guide and drive the Lottie animation"
        }

        static var cardTitle: String {
            isChinese ? "语音助手" : "Voice Assistant"
        }
        static var cardSubtitle: String {
            isChinese ? "正在讲解功能亮点" : "Explaining key features"
        }

        static var buddyTitle: String {
            isChinese ? "正在讲解" : "Narrating"
        }
        static var buddyMessage: String {
            isChinese ? "音频开始播放时动画会动起来。\n\n播放结束后动画自动停止。" : "The animation plays when audio starts.\n\nIt stops automatically when playback ends."
        }
        static var buddyAction: String {
            isChinese ? "知道了" : "Got it"
        }

        static var statusWaiting: String {
            isChinese ? "等待播放" : "Ready to play"
        }
        static var statusPlaying: String {
            isChinese ? "播放中..." : "Playing..."
        }
        static var statusFinished: String {
            isChinese ? "播放结束" : "Playback finished"
        }
        static var statusFailed: String {
            isChinese ? "播放失败" : "Playback failed"
        }
        static var statusMissingAudio: String {
            isChinese ? "未找到音频文件" : "Audio file not found"
        }
    }
    
    // MARK: - DismissOnOutsideTap Demo
    
    enum DismissOutside {
        static var importantInfo: String {
            isChinese ? "重要信息" : "Important Info"
        }
        static var tapOutsideToDismiss: String {
            isChinese ? "点击外部关闭" : "Tap outside to dismiss"
        }
        
        static var status: String {
            isChinese ? "状态" : "Status"
        }
        static var waiting: String {
            isChinese ? "等待中" : "Waiting"
        }
        static var guideActive: String {
            isChinese ? "引导中..." : "Guide active..."
        }
        static var dismissed: String {
            isChinese ? "已关闭 ✓" : "Dismissed ✓"
        }
        static var completed: String {
            isChinese ? "已完成 ✓" : "Completed ✓"
        }
        
        static var dismissInfoTitle: String {
            isChinese ? "点击外部关闭" : "Dismiss on Outside Tap"
        }
        static var dismissInfoDesc: String {
            isChinese ? "当 dismissesOnOutsideTap = true 时，点击高亮区域外的任何位置都会关闭引导。" : "When dismissesOnOutsideTap = true, tapping anywhere outside the highlighted area will dismiss the guide."
        }
        
        static var callbackInfoTitle: String {
            isChinese ? "onDismiss 回调" : "onDismiss Callback"
        }
        static var callbackInfoDesc: String {
            isChinese ? "context.reason 告诉您引导消失的原因（completed、skipped、outsideTap、completerTriggered 或 programmatic）。" : "The context.reason tells you why the guide was dismissed (completed, skipped, outsideTap, completerTriggered, or programmatic)."
        }
        
        static var useCaseInfoTitle: String {
            isChinese ? "使用场景" : "Use Cases"
        }
        static var useCaseInfoDesc: String {
            isChinese ? "适用于可选提示、工具提示，或任何用户应该能够轻松关闭而无需完成所有步骤的引导。" : "Great for optional tips, tooltips, or any guide where the user should be able to easily dismiss without completing all steps."
        }
        
        static var buddyTitle: String {
            isChinese ? "点击外部关闭" : "Tap Outside to Dismiss"
        }
        static var buddyMessage: String {
            isChinese ? "此引导设置了 dismissesOnOutsideTap = true。\n\n点击高亮区域外的任何位置即可关闭此引导。" : "This guide has dismissesOnOutsideTap = true.\n\nTap anywhere outside the highlighted area to close this guide."
        }
    }
    
    // MARK: - DynamicFocusView Demo
    
    enum DynamicFocus {
        static var title: String {
            isChinese ? "动态 FocusView" : "Dynamic FocusView"
        }
        static var subtitle: String {
            isChinese ? "UITableView reloadData 后高亮区域自动更新" : "Highlight updates after UITableView reloadData"
        }
        
        static var useDynamicSwitch: String {
            isChinese ? "使用动态 FocusView" : "Use Dynamic FocusView"
        }
        
        static var sampleRow: String {
            isChinese ? "示例行" : "Sample Row"
        }
        
        // Info cards
        static var dynamicInfoTitle: String {
            "focusViewProvider"
        }
        static var dynamicInfoDesc: String {
            isChinese ? "使用闭包动态获取 focusView。当 UITableView/UICollectionView 调用 reloadData 后，闭包会返回新的 cell 实例，高亮区域自动更新。" : "Use a closure to dynamically obtain the focusView. After UITableView/UICollectionView calls reloadData, the closure returns the new cell instance and the highlight updates automatically."
        }
        
        static var staticInfoTitle: String {
            "focusView"
        }
        static var staticInfoDesc: String {
            isChinese ? "直接设置 focusView 属性。当 reloadData 后，原 cell 可能被复用或回收，导致高亮区域错位或消失。" : "Set the focusView property directly. After reloadData, the original cell may be reused or recycled, causing the highlight to shift or disappear."
        }
        
        static var liveDemoTitle: String {
            isChinese ? "实时演示" : "Live Demo"
        }
        static var liveDemoDesc: String {
            isChinese ? "引导开始后 2 秒将调用 tableView.reloadData()，观察高亮区域的变化。" : "2 seconds after the guide starts, tableView.reloadData() will be called. Observe how the highlight area changes."
        }
        
        // Buddy view - Dynamic mode
        static var dynamicBuddyTitle: String {
            isChinese ? "动态 FocusView 模式" : "Dynamic FocusView Mode"
        }
        static var dynamicBuddyMessage: String {
            isChinese ? "⏱ 2秒后将调用 reloadData...\n\n请注意观察：高亮区域会始终保持在正确的位置！\n\n💡 建议关闭「使用动态 FocusView」开关后再次体验，对比效果。" : "⏱ reloadData will be called in 2 seconds...\n\nObserve: The highlight will stay in the correct position!\n\n💡 Try turning off 'Use Dynamic FocusView' and show the guide again to compare."
        }
        
        // Buddy view - Static mode
        static var staticBuddyTitle: String {
            isChinese ? "静态 FocusView 模式" : "Static FocusView Mode"
        }
        static var staticBuddyMessage: String {
            isChinese ? "⏱ 2秒后将调用 reloadData...\n\n请注意观察：reloadData 后高亮区域可能会错位或消失，因为原 cell 已被复用。" : "⏱ reloadData will be called in 2 seconds...\n\nObserve: After reloadData, the highlight may shift or disappear because the original cell was reused."
        }
    }
}

// MARK: - Helper to get isChinese

private var isChinese: Bool {
    LanguageManager.shared.shouldUseChinese
}
