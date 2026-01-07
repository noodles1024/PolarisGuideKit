//
//  TapResultViewController.swift
//  PolarisGuideKitDemo
//
//  Created by noodles on 2025/12/31.
//

import UIKit

/// 展示触摸转发后业务跳转是否保持的结果页（已去除计数展示）
final class TapResultViewController: UIViewController {
    
    // MARK: - UI
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 26, weight: .bold)
        label.textColor = UIColor(red: 0.15, green: 0.15, blue: 0.20, alpha: 1.0)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let explanationTitle: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = UIColor(red: 0.20, green: 0.20, blue: 0.25, alpha: 1.0)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let explanationText: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor(red: 0.35, green: 0.35, blue: 0.40, alpha: 1.0)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let codeTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)
        textView.layer.cornerRadius = 12
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.textColor = UIColor(red: 0.20, green: 0.25, blue: 0.35, alpha: 1.0)
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Init
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        applyTexts()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [titleLabel, explanationTitle, explanationText, codeTextView].forEach { contentView.addSubview($0) }
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            explanationTitle.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            explanationTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            explanationTitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            explanationText.topAnchor.constraint(equalTo: explanationTitle.bottomAnchor, constant: 8),
            explanationText.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            explanationText.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            codeTextView.topAnchor.constraint(equalTo: explanationText.bottomAnchor, constant: 24),
            codeTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            codeTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            codeTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    private func applyTexts() {
        title = DemoStrings.TapResult.title
        titleLabel.text = DemoStrings.TapResult.successTitle
        explanationTitle.text = DemoStrings.TapResult.explanationTitle
        explanationText.text = DemoStrings.TapResult.explanationText
        
        let codeSample = """
let step = GuideStep()
step.focusView = interactiveButton
step.forwardsTouchEventsToFocusView = true
step.completer = ControlEventCompleter(control: interactiveButton, event: .touchUpInside)
"""
        let codeComment = "\(DemoStrings.TapResult.codeComment)\n"
        let attributed = NSMutableAttributedString(string: codeComment, attributes: [
            .font: UIFont.monospacedSystemFont(ofSize: 13, weight: .regular),
            .foregroundColor: UIColor(red: 0.30, green: 0.55, blue: 0.35, alpha: 1.0)
        ])
        attributed.append(NSAttributedString(string: codeSample, attributes: [
            .font: UIFont.monospacedSystemFont(ofSize: 13, weight: .regular),
            .foregroundColor: UIColor(red: 0.10, green: 0.15, blue: 0.25, alpha: 1.0)
        ]))
        codeTextView.attributedText = attributed
    }
}
