//
//  ViewController.swift
//  PolarisGuideKitDemo
//
//  Created by noodles on 2025/12/31.
//

import UIKit

// MARK: - Demo Cases

enum DemoCase: Int, CaseIterable {
    case roundedRectStyle = 0
    case circleStyle
    case multiStepGuide
    case touchForwarding
    case dismissOnOutsideTap
    case guideWithAudio
    case dynamicFocusView
    
    var title: String {
        switch self {
        case .roundedRectStyle:
            return DemoStrings.DemoCases.roundedRectTitle
        case .circleStyle:
            return DemoStrings.DemoCases.circleTitle
        case .multiStepGuide:
            return DemoStrings.DemoCases.multiStepTitle
        case .touchForwarding:
            return DemoStrings.DemoCases.touchForwardingTitle
        case .dismissOnOutsideTap:
            return DemoStrings.DemoCases.dismissOnOutsideTapTitle
        case .guideWithAudio:
            return DemoStrings.DemoCases.audioGuideTitle
        case .dynamicFocusView:
            return DemoStrings.DynamicFocus.title
        }
    }
    
    var subtitle: String {
        switch self {
        case .roundedRectStyle:
            return DemoStrings.DemoCases.roundedRectSubtitle
        case .circleStyle:
            return DemoStrings.DemoCases.circleSubtitle
        case .multiStepGuide:
            return DemoStrings.DemoCases.multiStepSubtitle
        case .guideWithAudio:
            return DemoStrings.DemoCases.audioGuideSubtitle
        case .touchForwarding:
            return DemoStrings.DemoCases.touchForwardingSubtitle
        case .dismissOnOutsideTap:
            return DemoStrings.DemoCases.dismissOnOutsideTapSubtitle
        case .dynamicFocusView:
            return DemoStrings.DynamicFocus.subtitle
        }
    }
    
    var viewController: UIViewController {
        switch self {
        case .roundedRectStyle:
            return RoundedRectStyleDemoVC()
        case .circleStyle:
            return CircleStyleDemoVC()
        case .multiStepGuide:
            return MultiStepGuideDemoVC()
        case .guideWithAudio:
            return GuideWithAudioDemoVC()
        case .touchForwarding:
            return TouchForwardingDemoVC()
        case .dismissOnOutsideTap:
            return DismissOnOutsideTapDemoVC()
        case .dynamicFocusView:
            return DynamicFocusViewDemoVC()
        }
    }
}

// MARK: - ViewController

class ViewController: UIViewController {
    
    // MARK: - Properties
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        setupNavigationBar()
        setupTableView()
        updateTitle()
    }
    
    // MARK: - Setup
    
    private func setupNavigationBar() {
        updateLanguageMenu()
    }
    
    private func updateLanguageMenu() {
        let currentSetting = LanguageManager.shared.currentSetting
        
        let actions = LanguageSetting.allCases.map { setting in
            UIAction(
                title: setting.displayName,
                image: UIImage(systemName: setting.icon),
                state: setting == currentSetting ? .on : .off
            ) { [weak self] _ in
                self?.changeLanguage(to: setting)
            }
        }
        
        let menu = UIMenu(
            title: DemoStrings.Main.languageSettingTitle,
            image: UIImage(systemName: "globe"),
            children: actions
        )
        
        let barButton = UIBarButtonItem(
            image: UIImage(systemName: "globe"),
            style: .plain,
            target: nil,
            action: nil
        )
        if #available(iOS 14.0, *) {
            barButton.menu = menu
        } else {
            barButton.target = self
            barButton.action = #selector(showLanguagePicker)
        }
        navigationItem.rightBarButtonItem = barButton
    }
    
    @objc private func showLanguagePicker() {
        let alert = UIAlertController(
            title: DemoStrings.Main.languageSettingTitle,
            message: nil,
            preferredStyle: .actionSheet
        )
        
        for setting in LanguageSetting.allCases {
            let isSelected = setting == LanguageManager.shared.currentSetting
            let title = isSelected ? "✓ \(setting.displayName)" : setting.displayName
            
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.changeLanguage(to: setting)
            })
        }
        
        alert.addAction(UIAlertAction(title: DemoStrings.Common.cancel, style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(alert, animated: true)
    }
    
    private func changeLanguage(to setting: LanguageSetting) {
        LanguageManager.shared.currentSetting = setting
        
        updateTitle()
        updateLanguageMenu()
        tableView.reloadData()
    }
    
    private func updateTitle() {
        title = DemoStrings.Main.title
    }
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DemoCell")
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DemoCase.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DemoCell", for: indexPath)
        
        guard let demoCase = DemoCase(rawValue: indexPath.row) else {
            return cell
        }
        
        if #available(iOS 14.0, *) {
            var content = cell.defaultContentConfiguration()
            content.text = demoCase.title
            content.secondaryText = demoCase.subtitle
            content.secondaryTextProperties.color = .secondaryLabel
            content.secondaryTextProperties.font = .systemFont(ofSize: 12)
            cell.contentConfiguration = content
        } else {
            cell.textLabel?.text = demoCase.title
            cell.detailTextLabel?.text = demoCase.subtitle
            cell.detailTextLabel?.textColor = .secondaryLabel
            cell.detailTextLabel?.font = .systemFont(ofSize: 12)
        }
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let demoCase = DemoCase(rawValue: indexPath.row) else {
            return
        }
        
        let demoVC = demoCase.viewController
        demoVC.title = demoCase.title
        navigationController?.pushViewController(demoVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return DemoStrings.Main.sectionHeader
    }
}
