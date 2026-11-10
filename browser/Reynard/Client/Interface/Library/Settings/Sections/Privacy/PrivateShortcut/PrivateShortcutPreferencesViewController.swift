//
//  PrivateShortcutPreferencesViewController.swift
//  Reynard
//

import UIKit

final class PrivateShortcutPreferencesViewController: SettingsTableViewController {
    private enum UX {
        static let targetCellReuseIdentifier = "PrivateShortcutTargetCell"
    }
    
    private enum Section: CaseIterable {
        case target
        case history
        
        var text: SettingsSectionText {
            switch self {
            case .target:
                return SettingsSectionText(
                    headerTitle: NSLocalizedString("Shortcut Target", comment: ""),
                    footerTitle: NSLocalizedString("Type mmmm in the address bar to open this website, or pppp to return to this page.", comment: "")
                )
            case .history:
                return SettingsSectionText(
                    headerTitle: NSLocalizedString("History", comment: ""),
                    footerTitle: NSLocalizedString("When off, Reynard does not add pages to history and clears existing history on launch. Sign-ins are kept.", comment: "")
                )
            }
        }
    }
    
    private let historySwitch = UISwitch()
    private let showsDoneButton: Bool
    
    init(showsDoneButton: Bool = false) {
        self.showsDoneButton = showsDoneButton
        super.init(style: .insetGrouped)
        title = NSLocalizedString("Private Shortcut", comment: "")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(
            CustomSearchTemplateCell.self,
            forCellReuseIdentifier: UX.targetCellReuseIdentifier
        )
        historySwitch.addTarget(self, action: #selector(historySwitchChanged(_:)), for: .valueChanged)
        historySwitch.isOn = Prefs.HistorySettings.recordsBrowsingHistory
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Save", comment: ""),
            style: .done,
            target: self,
            action: #selector(saveButtonTapped)
        )
        
        if showsDoneButton {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: NSLocalizedString("Done", comment: ""),
                style: .done,
                target: self,
                action: #selector(doneButtonTapped)
            )
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        historySwitch.isOn = Prefs.HistorySettings.recordsBrowsingHistory
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard Section.allCases.indices.contains(section) else {
            return 0
        }
        return 1
    }
    
    override func sectionText(for section: Int) -> SettingsSectionText {
        guard Section.allCases.indices.contains(section) else {
            return SettingsSectionText()
        }
        return Section.allCases[section].text
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard Section.allCases.indices.contains(indexPath.section) else {
            return UITableViewCell()
        }
        
        switch Section.allCases[indexPath.section] {
        case .target:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: UX.targetCellReuseIdentifier,
                for: indexPath
            ) as? CustomSearchTemplateCell else {
                return UITableViewCell()
            }
            cell.textField.delegate = self
            cell.textField.placeholder = Prefs.PrivateShortcutSettings.defaultTargetURL
            cell.textField.text = Prefs.PrivateShortcutSettings.targetURL
            return cell
        case .history:
            let cell = SettingsTableViewCell(style: .default, reuseIdentifier: nil)
            cell.selectionStyle = .none
            cell.textLabel?.text = NSLocalizedString("Record Browsing History", comment: "")
            cell.accessoryView = historySwitch
            return cell
        }
    }
    
    @objc private func saveButtonTapped() {
        saveTarget()
        view.endEditing(true)
    }
    
    @objc private func doneButtonTapped() {
        saveTarget()
        dismiss(animated: true)
    }
    
    @objc private func historySwitchChanged(_ sender: UISwitch) {
        Prefs.HistorySettings.recordsBrowsingHistory = sender.isOn
    }
    
    private func saveTarget() {
        guard let cell = tableView.cellForRow(
            at: IndexPath(row: 0, section: 0)
        ) as? CustomSearchTemplateCell else {
            return
        }
        
        let value = (cell.textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            cell.textField.text = Prefs.PrivateShortcutSettings.defaultTargetURL
            Prefs.PrivateShortcutSettings.targetURL = Prefs.PrivateShortcutSettings.defaultTargetURL
            return
        }
        
        guard let url = URLUtils.normalizedCustomURL(from: value) else {
            AlertPresenter.show(
                title: NSLocalizedString("Invalid Address", comment: ""),
                message: NSLocalizedString("Enter a valid http or https address.", comment: "")
            )
            cell.textField.text = Prefs.PrivateShortcutSettings.targetURL
            return
        }
        
        Prefs.PrivateShortcutSettings.targetURL = url.absoluteString
        cell.textField.text = url.absoluteString
    }
}

// MARK: - UITextFieldDelegate

extension PrivateShortcutPreferencesViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        saveTarget()
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        saveTarget()
    }
}
