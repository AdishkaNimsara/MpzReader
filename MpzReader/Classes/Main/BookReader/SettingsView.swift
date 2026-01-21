//
//  SettingsView.swift
//  MpzReader
//
//  Created by Hasitha Mapalagama on 9/2/20.
//

import Foundation
import UIKit
import ReadiumNavigator
import ReadiumShared

class SettingsView: UIView {
    var view: UIView!
    
    @IBOutlet weak var innerContainer: UIView!
    @IBOutlet weak var bottomConstrain: NSLayoutConstraint!
    
    var clickHide: (() -> ())?
    var delegate: MpzBookViewSettingsDelegate?
    
    // Reference to the navigator to access preferences
    weak var navigator: EPUBNavigatorViewController?
    
    @IBOutlet weak var fontSlider: UISlider!
    @IBOutlet weak var vertical: UIView!
    @IBOutlet weak var horizontal: UIView!
    @IBOutlet weak var dark: UIView!
    @IBOutlet weak var light: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupXib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupXib()
    }
    
    private func setupXib() {
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: Bundle.init(for: type(of: self)))
        self.view = nib.instantiate(withOwner: self, options: nil)[0] as? UIView
        self.view.frame = bounds
        self.view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        addSubview(self.view)
    }

    func prepare() {
        setupFontSize()
        setModeUI()
        //setScrollModeUI()
    }
    
    @IBAction func didClickOutside(_ sender: Any) {
        self.clickHide?()
    }
    
    // MARK: - Setup UI
    
    private func setupFontSize() {
        // guard let preferences = navigator?.preferences else { return }
        
        // Font size in Readium 3.x is a percentage (1.0 = 100%)
        // Convert to slider range 80-200
        // Use default if preferences not available yet
        /*
        if let fontSize = preferences.fontSize {
            let percentage = fontSize * 100
            self.fontSlider.maximumValue = 200.0
            self.fontSlider.minimumValue = 80.0
            self.fontSlider.value = Float(percentage)
        } else {
            // Default to 100%
            self.fontSlider.maximumValue = 200.0
            self.fontSlider.minimumValue = 80.0
            self.fontSlider.value = 100.0
        }
        */
    }
    
    private func setModeUI() {
        /*
        guard let preferences = navigator?.preferences else { return }
        
        switch preferences.theme {
        case .dark:
            light.alpha = 0.3
            dark.alpha = 1.0
        case .light, .sepia, nil:
            light.alpha = 1.0
            dark.alpha = 0.3
        @unknown default:
            light.alpha = 1.0
            dark.alpha = 0.3
        }
        */
    }
    
    private func setScrollModeUI() {
        /*
        guard let preferences = navigator?.preferences else { return }
        
        let isScrollEnabled = preferences.scroll ?? false
        if isScrollEnabled {
            vertical.alpha = 1.0
            horizontal.alpha = 0.3
        } else {
            vertical.alpha = 0.3
            horizontal.alpha = 1.0
        }
        */
    }
    
    // MARK: - Actions
    
    func changeMode(isNight: Bool) {
        guard let navigator = navigator else { return }
        
        var newPreferences = EPUBPreferences()
        newPreferences.theme = isNight ? .dark : .light
        
        navigator.submitPreferences(newPreferences)
        self.delegate?.updateReaderColors()
        
        // Update UI locally since we don't have stream of prefs
        if isNight {
            light.alpha = 0.3
            dark.alpha = 1.0
        } else {
            light.alpha = 1.0
            dark.alpha = 0.3
        }
    }
    
    func changeScrollMode(isVertical: Bool) {
        guard let navigator = navigator else { return }
        
        var newPreferences = EPUBPreferences()
        newPreferences.scroll = isVertical
        
        navigator.submitPreferences(newPreferences)
        
        // Update UI locally
        if isVertical {
            vertical.alpha = 1.0
            horizontal.alpha = 0.3
        } else {
            vertical.alpha = 0.3
            horizontal.alpha = 1.0
        }
    }
    
    @IBAction func didChangeValue(_ sender: Any) {
        guard let navigator = navigator else { return }
        
        // Convert slider value (80-200) to percentage (0.8-2.0)
        let percentage = Double(fontSlider.value) / 100.0
        
        var newPreferences = EPUBPreferences()
        newPreferences.fontSize = percentage
        
        navigator.submitPreferences(newPreferences)
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
}
