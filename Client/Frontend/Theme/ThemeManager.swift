/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import Foundation

enum ThemeManagerPrefs: String {
    case systemThemeIsOn = "prefKeySystemThemeSwitchOnOff"
    case automaticSwitchIsOn = "prefKeyAutomaticSwitchOnOff"
    case automaticSliderValue = "prefKeyAutomaticSliderValue"
    case themeName = "prefKeyThemeName"
}

class ThemeManager {
    static let instance = ThemeManager()

    var current: Theme = themeFrom(name: UserDefaults.standard.string(forKey: ThemeManagerPrefs.themeName.rawValue)) {
        didSet {
            UserDefaults.standard.set(current.name, forKey: ThemeManagerPrefs.themeName.rawValue)
            NotificationCenter.default.post(name: .DisplayThemeChanged, object: nil)
        }
    }

    var currentName: BuiltinThemeName {
        return BuiltinThemeName(rawValue: ThemeManager.instance.current.name) ?? .normal
    }

    var automaticBrightnessValue: Float = UserDefaults.standard.float(forKey: ThemeManagerPrefs.automaticSliderValue.rawValue) {
        didSet {
            UserDefaults.standard.set(automaticBrightnessValue, forKey: ThemeManagerPrefs.automaticSliderValue.rawValue)
        }
    }

    var automaticBrightnessIsOn: Bool = UserDefaults.standard.bool(forKey: ThemeManagerPrefs.automaticSwitchIsOn.rawValue) {
        didSet {
            UserDefaults.standard.set(automaticBrightnessIsOn, forKey: ThemeManagerPrefs.automaticSwitchIsOn.rawValue)
        }
    }

    var systemThemeIsOn: Bool = UserDefaults.standard.bool(forKey: ThemeManagerPrefs.systemThemeIsOn.rawValue) {
        didSet {
            UserDefaults.standard.set(systemThemeIsOn, forKey: ThemeManagerPrefs.systemThemeIsOn.rawValue)
        }
    }

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(brightnessChanged), name: UIScreen.brightnessDidChangeNotification, object: nil)
    }

    // UIViewControllers / UINavigationControllers need to have `preferredStatusBarStyle` and call this.
    var statusBarStyle: UIStatusBarStyle {
        // On iPad the dark and normal theme both have a dark tab bar
        guard UIDevice.current.userInterfaceIdiom == .phone else { return .lightContent }
        return currentName == .dark ? .lightContent : .default
    }

    func updateCurrentThemeBasedOnScreenBrightness() {
        let prefValue = UserDefaults.standard.float(forKey: ThemeManagerPrefs.automaticSliderValue.rawValue)

        let screenLessThanPref = Float(UIScreen.main.brightness) < prefValue

        if screenLessThanPref, self.currentName == .normal {
            self.current = DarkTheme()
        } else if !screenLessThanPref, self.currentName == .dark {
            self.current = NormalTheme()
        }
    }

    @objc private func brightnessChanged() {
        guard automaticBrightnessIsOn else { return }
        updateCurrentThemeBasedOnScreenBrightness()
    }
}

fileprivate func themeFrom(name: String?) -> Theme {
    guard let name = name, let theme = BuiltinThemeName(rawValue: name) else { return NormalTheme() }
    switch theme {
    case .dark:
        return DarkTheme()
    default:
        return NormalTheme()
    }
}
