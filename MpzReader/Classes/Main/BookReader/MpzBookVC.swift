//
//  MpzBookView.swift
//  MpzReader
//
//  Created by Hasitha Mapalagama on 8/16/19.
//

import Foundation
import UIKit
import ReadiumNavigator
import ReadiumShared
import ReadiumAdapterGCDWebServer
import WebKit
import SwiftyJSON
import Lightbox
import ScreenShield

protocol MpzBookViewSettingsDelegate {
    // Removed: func getUserSettings() -> UserSettings
    // Removed: func updateUserSettings()
    // Settings now use EPUBPreferences directly via the navigator
    func updateReaderColors()
}

class MpzBookVC : UIViewController {
    
    @IBOutlet weak var settingsView: SettingsView!
    @IBOutlet weak var stackView: UIStackView!
    private var rightBarButtons = [UIBarButtonItem]()
    private var leftBarButtons = [UIBarButtonItem]()
    var epubNavigator : MpzEpubNavigatorController!
    var reader : MpzReader!
    var httpServer: HTTPServer! // Required for serving publication content in Readium 3.x
    var scripts = [WKUserScript]()
    var jsEventHandlers = [String : (Any) -> Void]()
    var isColorHighlightMode = false
    var defaultHightlightColor = "#C9FB53"
    //var bookmark : Bookmark!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initializeScripts()
        self.initializeHandlers()
        //self.initializeBookmark()
        self.setupViews()
        self.initializeSettingsView()
        applyScreenshotProtection()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? MpzSettingsVC {
            vc.delegate = self
            // Pass the navigator instance to settings VC
            // Note: epubNavigator is now typealias for EPUBNavigatorViewController
            vc.navigator = self.epubNavigator
        }
    }
    
    private func initializeSettingsView() {
        self.settingsView.isUserInteractionEnabled = false
        self.settingsView.alpha = 0
    }
    
    private func initializeScripts() {
        let jquery = Bundle.init(for: type(of: self)).path(forResource: "jquery", ofType: "js")!
        let highlight = Bundle.init(for: type(of: self)).path(forResource: "highlight", ofType: "js")!
        let app = Bundle.init(for: type(of: self)).path(forResource: "app", ofType: "js")!
        let guesture = Bundle.init(for: type(of: self)).path(forResource: "guesture", ofType: "js")!
        
        scripts.append(WKUserScript.init(source: try! String(contentsOfFile: guesture), injectionTime: .atDocumentStart, forMainFrameOnly: true))
        scripts.append(WKUserScript.init(source: try! String(contentsOfFile: jquery), injectionTime: .atDocumentStart, forMainFrameOnly: true))
        scripts.append(WKUserScript.init(source: try! String(contentsOfFile: highlight), injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        scripts.append(WKUserScript.init(source: try! String(contentsOfFile: app), injectionTime: .atDocumentEnd, forMainFrameOnly: true))
    }
    
    private func initializeHandlers() {
        jsEventHandlers["didTapOnHighlight"] = {
            if let data = $0 as? String {
                self.didTapOnHighlight(data: data)
            }
        }
        
        jsEventHandlers["didClickImage"] = {
            if let data = $0 as? String {
                self.showImage(url: data)
            }
        }
    }
    
    private func showImage(url : String) {
        let imagePath = url.replacingOccurrences(of: "file://", with: "")
        if let image = UIImage.init(contentsOfFile: imagePath) {
            let images = [LightboxImage.init(image:  image)]
            let lbvc = LightboxController.init(images: images, startIndex: 0)
            lbvc.footerView.isHidden = true
            lbvc.modalPresentationStyle = .fullScreen
            self.present(lbvc, animated: true, completion: nil)
        }
    }
    
    func strint2Rect(string : String) -> CGRect {
        return NSCoder.cgRect(for: string)
    }
    
    @IBAction func didClickClose(_ sender: Any) {
        self.dismiss(animated: true, completion: {
            MpzReader.configs.onDismiss?()
        })
    }
    
}

extension MpzBookVC {
    
    /// Get the current theme from the navigator's preferences
    /// Note: Preferences API needs further investigation in Readium 3.x
    var currentTheme: Theme? {
        // TODO: Fix preferences access in Readium 3.x
        // The preferences API may have changed or requires different access pattern
        return nil // Default to light theme for now
    }
    
    func setupViews() {
        // Migration: Commenting out legacy action setup for now
        /*
        var actions = [EditingAction]()
        if MpzReader.configs.isShareEnabled {
            actions.append(.share)
        }
        if MpzReader.configs.isLookupEnabled {
            actions.append(.lookup)
        }
        */
        
        var initialLocator : Locator?
//        if let loc = self.bookmark.locator {
//            initialLocator = loc
//        }
        
        // Migration: Configuration setup
        var config = EPUBNavigatorViewController.Configuration()
        
        // config.editingActions = actions // Not directly supported in simple config init or changed API
        
        // Migration: Scripts and Event Handlers need to be migrated to UserScript mechanism
        // For now, we disable them to get basic opening working
        /*
        configs.customScripts = scripts
        configs.jsEventHandlers = jsEventHandlers
        configs.transformHtml = MpzReader.configs.onHtmlTransform
        */
        
        guard let publication = self.reader.publication else {
            print("publication nil. cannot create EPUBNavigator")
            self.dismiss(animated: true) { MpzReader.configs.onError?() }
            return
        }
        
        do {
            // Create HTTP server for serving publication content
            // In Readium 3.x, GCDHTTPServer requires an assetRetriever parameter
            self.httpServer = GCDHTTPServer(assetRetriever: self.reader.assetRetriever)
            
            // Create MpzEpubNavigatorController which inherits from EPUBNavigatorViewController
            // In Readium 3.x, it inherits all initializers automatically
            self.epubNavigator = try MpzEpubNavigatorController(
                publication: publication,
                initialLocation: initialLocator,
                config: config,
                httpServer: self.httpServer
            )
            
            //self.epubNavigator.delegate = self
            
            // Add navigator to view hierarchy
            self.addChild(self.epubNavigator)
            self.epubNavigator.view.translatesAutoresizingMaskIntoConstraints = false
            self.stackView.addArrangedSubview(self.epubNavigator.view)
            self.epubNavigator.didMove(toParent: self)
            
        } catch {
            print("Error creating navigator: \(error)")
            self.dismiss(animated: true) { MpzReader.configs.onError?() }
            return
        }
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.markHighlights()
        }
        
        // Migration: Highlights temporarily commented if they depend on scripts
        /*
        if MpzReader.configs.isHighlightsEnabled {
            setupHighlightMenu()
        }
        */
        updateReaderUI()
        setupNavigationButtons()
    }
    
    
    func updateReaderUI() {
        let colors = reader.getColors(forTheme: self.currentTheme)
        self.epubNavigator.view.backgroundColor = colors.background
        self.view.backgroundColor = colors.background
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = colors.primary
        self.navigationController?.navigationBar.tintColor = colors.textColor
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: colors.textColor]
    }
    
    func setupNavigationButtons() {
        self.rightBarButtons = []
        self.leftBarButtons = []
        
        let contentNB = UIBarButtonItem.init(image: UIImage.inBundle(named: "chapters"),
                                             style: .plain, target: self, action: #selector(didClickContent))
        
        let closeNB = UIBarButtonItem.init(image: UIImage.inBundle(named: "close"),
                                           style: .plain, target: self, action: #selector(didClickCloseClick))
        
        
        let settingsNB = UIBarButtonItem.init(image: UIImage.inBundle(named: "text"),
                                              style: .plain, target: self, action: #selector(didClickSettings(_:)))
        
        let bookmarkNB = UIBarButtonItem.init(image: UIImage.inBundle(named: "bookmark"),
                                              style: .plain, target: self, action: #selector(didBookmark(_:)))
        
        self.leftBarButtons.append(closeNB)
        
        if MpzReader.configs.isSettingsEnabled {
            self.rightBarButtons.append(settingsNB)
        }
        
        if MpzReader.configs.isContentEnabled {
            self.leftBarButtons.append(contentNB)
        }
        
        if MpzReader.configs.isEnableManualBookmarking {
            self.rightBarButtons.append(bookmarkNB)
        }
        
        
        self.navigationItem.rightBarButtonItems = self.rightBarButtons
        self.navigationItem.leftBarButtonItems = self.leftBarButtons
    }
    
    @objc func didClickContent() {
        guard let publication = reader.publication else { return }
        //let vc = MPZPageViewController.create(withHightlights: Highlight.list, highlightDelegate: self, publication: publication, contentDelegate: self)
        //self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func didClickHighlightsNav() {
        //let vc = HighlightListVC.create(withHightlights: Highlight.list, delegate: self)
        //self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    @objc func didClickSettings(_ button : UIBarButtonItem) {
        self.settingsView.isUserInteractionEnabled = true
        self.settingsView.delegate = self
        self.settingsView.navigator = self.epubNavigator // Pass navigator reference
        self.settingsView.prepare()
        self.settingsView.clickHide = {
            self.settingsView.isUserInteractionEnabled = false
            UIView.animate(withDuration: 0.5) {
                self.settingsView.alpha = 0
            }
        }
        UIView.animate(withDuration: 0.5) {
            self.settingsView.alpha = 1
        }
    }
    
    @objc func didClickCloseClick(_ sender: Any) {
        self.dismiss(animated: true, completion: {
            MpzReader.configs.onDismiss?()
        })
    }
    
    @objc func didBookmark(_ sender: Any) {
        //saveBookmark()
        let bookmarkImage = UIImage.inBundle(named: "bookmark-large")
        let bView = UIImageView.init(image: bookmarkImage)
        bView.frame = CGRect.init(x: stackView.frame.width - 100, y: -100, width: 100, height: 100)
        bView.alpha = 0
        bView.isUserInteractionEnabled = false
        self.view.addSubview(bView)
        self.view.bringSubviewToFront(bView)
        
        UIView.animate(withDuration: 0.3,delay: 0, options: .curveEaseOut, animations: {
            bView.alpha = 0.7
            bView.frame.origin.y = 0
        }) { _ in
            UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseInOut, animations: {
                bView.alpha = 0
            }) { _ in
                bView.removeFromSuperview()
            }
        }
    }
    
}

extension MpzBookVC : UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

//extension MpzBookVC : EPUBNavigatorDelegate {
//    
//    func initializeBookmark() {
//        self.bookmark = Bookmark.get(forBook: self.reader.book.id)
//    }
//    
//    func saveBookmark() {
//        guard
//            let locator = epubNavigator.currentLocation,
//            let publication = reader.publication,
//            let resourceIndex = publication.readingOrder.firstIndex(withHREF: locator.href) else
//        {
//            return
//        }
//        self.bookmark.locator = locator
//        self.bookmark.resourceIndex = resourceIndex
//        print("save bookmark")
//        self.bookmark.save()
//    }
//    
//    func navigator(_ navigator: Navigator, presentExternalURL url: URL) {
//        // Handle external URL if needed
//    }
//    
//    func navigator(_ navigator: Navigator, locationDidChange locator: Locator) {
//        print("location did changed")
//        self.markHighlights()
//        if !MpzReader.configs.isEnableManualBookmarking {
//            self.saveBookmark()
//        }
//    }
//    
//    func navigator(_ navigator: Navigator, presentError error: any Error) {
//        print("navigator present error", error.localizedDescription)
//    }
//    
//}

extension MpzBookVC : MpzBookViewSettingsDelegate {
    func updateReaderColors() {
        self.updateReaderUI()
    }
    
    // Note: getUserSettings() and updateUserSettings() have been removed.
    // Settings now use EPUBPreferences directly via the navigator.
}

//extension MpzBookVC : MpzContentsDelegate {
//    func contentRequest(navigateTo locator: Locator) {
//        let _ = self.epubNavigator.go(to: locator, animated: true, completion: {})
//    }
//    
//}


extension UIViewController {

    private struct Constants {
        static let protectionContainerTag = 13371337
    }

    /// This function restructures the view hierarchy to protect it from screenshots.
    func applyScreenshotProtection() {
        
//        if view.viewWithTag(Constants.protectionContainerTag) != nil {
//            print("Screenshot protection has already been applied.")
//            return
//        }
//
//        let container = UIView()
//        container.translatesAutoresizingMaskIntoConstraints = false
//        container.backgroundColor = .clear
//        container.tag = Constants.protectionContainerTag
//
//        self.view.addSubview(container)
//
//        NSLayoutConstraint.activate([
//            container.topAnchor.constraint(equalTo: self.view.topAnchor),
//            container.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
//            container.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
//            container.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
//        ])
//        
//        for subview in self.view.subviews where subview !== container {
//            container.addSubview(subview)
//        }
//        
//        ScreenShield.shared.protect(view: container)
//        ScreenShield.shared.protectFromScreenRecording()
    }
}

