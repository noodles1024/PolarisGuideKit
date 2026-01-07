//
//  LanguageManager.swift
//  PolarisGuideKitDemo
//
//  Created by noodles on 2025/12/31.
//

import Foundation

enum LanguageSetting: Int, CaseIterable {
    case auto = 0
    case chinese = 1
    case english = 2
    
    var displayName: String {
        switch self {
        case .auto:
            return LanguageManager.shared.shouldUseChinese ? "自动" : "Auto"
        case .chinese:
            return "中文"
        case .english:
            return "English"
        }
    }
    
    var icon: String {
        switch self {
        case .auto:
            return "globe"
        case .chinese:
            return "character.zh"
        case .english:
            return "character.en"
        }
    }
}

final class LanguageManager {
    static let shared = LanguageManager()
    
    private init() {}
    
    var currentSetting: LanguageSetting = .auto
    
    var shouldUseChinese: Bool {
        switch currentSetting {
        case .auto:
            return isAutoModeChinese
        case .chinese:
            return true
        case .english:
            return false
        }
    }
    
    private var isAutoModeChinese: Bool {
        let isGMT8 = TimeZone.current.secondsFromGMT() == 8 * 3600
        
        let preferredLanguages = Locale.preferredLanguages
        let isChineseLang = preferredLanguages.contains { languageCode in
            languageCode.hasPrefix("zh")
        }
        
        return isGMT8 || isChineseLang
    }
}

