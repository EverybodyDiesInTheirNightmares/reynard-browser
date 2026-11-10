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
        case primary
        case secondary
        case tertiary
        case history
        
        var text: SettingsSectionText {
            switch self {
            case .primary:
                return SettingsSectionText(
                    headerTitle: "mmmm",
                    footerTitle: NSLocalizedString("Type mmmm in the address bar to open this website, or pppp to return to this page.", comment: "")
                )
            case .secondary:
                return SettingsSectionText(
                    headerTitle: "llll",
                    footerTitle: NSLocalizedString("Type llll in the address bar to open this website.", comment: "")
                )
            case .tertiary:
                return SettingsSectionText(
                    headerTitle: "oooo",
                    footerTitle: NSLocalizedString("Type oooo in the address bar to open this website.", comment: "")
                )
            case .history:
                return SettingsSectionText(
                    headerTitle: NSLocalizedString("History", comment: ""),
                    footerTitle: NSLocalizedString("When off, Reynard does not add pages to history and clears existing history on launch. Sign-ins are kept.", comment: "")
                )
            }
        }
        
        var placeholder: String {
            switch self {
            case .primary:
                return Prefs.PrivateShortcutSettings.defaultTargetURL
            case .secondary, .tertiary:
                return "https://"
            case .history:
                return ""
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
        
        let section = Section.allCases[indexPath.section]
        switch section {
        case .primary, .secondary, .tertiary:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: UX.targetCellReuseIdentifier,
                for: indexPath
            ) as? CustomSearchTemplateCell else {
                return UITableViewCell()
            }
            cell.textField.delegate = self
            cell.textField.placeholder = section.placeholder
            cell.textField.text = targetValue(for: section)
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
        saveVisibleTargets()
        view.endEditing(true)
    }
    
    @objc private func doneButtonTapped() {
        saveVisibleTargets()
        dismiss(animated: true)
    }
    
    @objc private func historySwitchChanged(_ sender: UISwitch) {
        Prefs.HistorySettings.recordsBrowsingHistory = sender.isOn
    }
    
    private func saveVisibleTargets() {
        for section in [Section.primary, .secondary, .tertiary] {
            guard let index = Section.allCases.firstIndex(of: section),
                  let cell = tableView.cellForRow(
                    at: IndexPath(row: 0, section: index)
                  ) as? CustomSearchTemplateCell else {
                continue
            }
            saveTarget(for: section, in: cell)
        }
    }
    
    private func saveTarget(for section: Section, in cell: CustomSearchTemplateCell) {
        let value = (cell.textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        if value.isEmpty {
            if section == .primary {
                cell.textField.text = Prefs.PrivateShortcutSettings.defaultTargetURL
                setTargetURL(Prefs.PrivateShortcutSettings.defaultTargetURL, for: section)
            } else {
                cell.textField.text = ""
                setTargetURL("", for: section)
            }
            return
        }
        
        guard let url = URLUtils.normalizedCustomURL(from: value) else {
            AlertPresenter.show(
                title: NSLocalizedString("Invalid Address", comment: ""),
                message: NSLocalizedString("Enter a valid http or https address.", comment: "")
            )
            cell.textField.text = targetValue(for: section)
            return
        }
        
        setTargetURL(url.absoluteString, for: section)
        cell.textField.text = url.absoluteString
    }
    
    private func targetValue(for section: Section) -> String {
        switch section {
        case .primary:
            return Prefs.PrivateShortcutSettings.targetURL
        case .secondary:
            return Prefs.PrivateShortcutSettings.secondaryTargetURL
        case .tertiary:
            return Prefs.PrivateShortcutSettings.tertiaryTargetURL
        case .history:
            return ""
        }
    }
    
    private func setTargetURL(_ value: String, for section: Section) {
        switch section {
        case .primary:
            Prefs.PrivateShortcutSettings.targetURL = value
        case .secondary:
            Prefs.PrivateShortcutSettings.secondaryTargetURL = value
        case .tertiary:
            Prefs.PrivateShortcutSettings.tertiaryTargetURL = value
        case .history:
            break
        }
    }
}

// MARK: - UITextFieldDelegate

extension PrivateShortcutPreferencesViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        saveTarget(for: textField)
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        saveTarget(for: textField)
    }
    
    private func saveTarget(for textField: UITextField) {
        guard let cell = tableView.visibleCells
            .compactMap({ $0 as? CustomSearchTemplateCell })
            .first(where: { $0.textField === textField }),
            let indexPath = tableView.indexPath(for: cell),
            Section.allCases.indices.contains(indexPath.section) else {
            return
        }
        
        saveTarget(for: Section.allCases[indexPath.section], in: cell)
    }
}
