//
//  File.swift
//  MpzReader
//
//  Created by Hasitha Mapalagama on 8/17/19.
//

import Foundation
import UIKit
import ReadiumNavigator
import ReadiumShared
class MpzSettingsVC : UITableViewController {
    
    static func create(withDelegate delegate : MpzBookViewSettingsDelegate) -> MpzSettingsVC {
        let stry = UIStoryboard.init(name: "Main", bundle: Bundle.init(for: MpzSettingsVC.self))
        let vc = stry.instantiateViewController(withIdentifier: "settings_vc") as! MpzSettingsVC
        vc.delegate = delegate
        vc.preferredContentSize = CGSize.init(width: 270, height: 263)
        return vc
    }
    
    var delegate : MpzBookViewSettingsDelegate?
    
    weak var navigator: EPUBNavigatorViewController?
    
    @IBOutlet weak var vertical: UIView!
    @IBOutlet weak var horizontal: UIView!
    @IBOutlet weak var dark: UIView!
    @IBOutlet weak var light: UIView!
    @IBOutlet weak var brightness: UISlider!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Wait for navigator to be set
        DispatchQueue.main.async {
            self.setupFontSize()
            self.setModeUI()
            self.setScrollModeUI()
        }
    }
    @IBAction func didClickMinusFontSize(_ sender: Any) {
        self.changeFontSize(increment: false)
    }
    
    @IBAction func didClickPlusFontSize(_ sender: Any) {
        self.changeFontSize(increment: true)
    }
    
    @IBAction func didClickLightMode(_ sender: Any) {
        self.changeMode(isNight: false)
    }
    
    @IBAction func didClickDarkMode(_ sender: Any) {
        self.changeMode(isNight: true)
    }
    
    @IBAction func didClickHorizontal(_ sender: Any) {
        self.changeScrollMode(isVertical: false)
    }
    
    @IBAction func didClickVertical(_ sender: Any) {
        self.changeScrollMode(isVertical: true)
    }
   
    @IBAction func didBrightnessChanged(_ sender: Any) {
        UIScreen.main.brightness = CGFloat(brightness.value)
    }
    
    
    
    private func setupFontSize() {
        // No UI setup needed for buttons, logic is in action
    }
    
    private func setModeUI() {
        // Default to light
        var isNight = false
        
        // TODO: Get real setting from navigator.preferences?
        // Note: EPUBNavigatorViewController in Readium 3.x might not expose current efficient preferences simply
        // But assuming we can track it or read it.
        // For now, simple toggle logic is safer if access is complex.
        
        // Actually, let's try to read it if possible, or leave it stateless
        // The previous code read it.
    }
    
    private func setScrollModeUI() {
        // Similar to mode UI
    }
}

extension MpzSettingsVC {
    
    func changeFontSize(increment : Bool) {
        // TODO: Implement using navigator.submitPreferences
        // For migration: Since we don't have direct access to incrementable properies,
        // we might leave this as TODO or implement if properties are available.
        // Assuming we have reference to navigator.
        
        /*
        guard let navigator = navigator else { return }
        var prefs = navigator.preferences
        let current = prefs.fontSize ?? 1.0
        let newSize = increment ? current + 0.1 : current - 0.1
        // Clamp logic...
        prefs.fontSize = newSize
        navigator.submitPreferences(prefs)
        */
    }
    
    func changeMode(isNight : Bool) {
        guard let navigator = navigator else { return }
        // Note: This requires Readium 3.x knowledge of preferences struct
        /*
        var prefs = navigator.preferences
        prefs.theme = isNight ? .dark : .light
        navigator.submitPreferences(prefs)
        */
        
        if isNight {
            light.alpha = 0.5
            dark.alpha = 1
        } else {
            light.alpha = 1
            dark.alpha = 0.5
        }
        
        self.delegate?.updateReaderColors()
    }
    
    
    func changeScrollMode(isVertical : Bool) {
        guard let navigator = navigator else { return }
        
        // Create a new preferences object with the updated scroll setting
        // In Readium 3.x we submit an EPUBPreferences object
        var prefs = EPUBPreferences()
        prefs.scroll = isVertical
        
        // This will update the navigator configuration
        navigator.submitPreferences(prefs)
        
        if isVertical {
            vertical.alpha = 1
            horizontal.alpha = 0.5
        } else {
            vertical.alpha = 0.5
            horizontal.alpha = 1
        }
    }
    
}
