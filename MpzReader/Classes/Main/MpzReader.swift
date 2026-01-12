//
//  MpzReader.swift
//  MpzReader
//
//  Created by Hasitha Mapalagama on 8/16/19.
//
import UIKit
import Foundation
import ReadiumStreamer
import ReadiumShared
import ReadiumNavigator
import SQLite
import ZIPFoundation
public class MpzReader {
    
    public static var configs = MpzConfig()
    public var book : MpzBook!
    public var publication: Publication?
    public var assetRetriever: AssetRetriever!
    public var publicationOpener: PublicationOpener!
    public var extractToPath: URL?
    
    public init(withBook book : MpzBook) {
        self.book = book
        self.initializeDatabase()
    }
    
    public func present(inViewController viewController: UIViewController) {
        // Since opening a publication is async, we need to handle it properly
        Task {
            do {
                try await self.openPublication()
                
                await MainActor.run {
                    if self.publication == nil {
                        MpzReader.configs.onError?()
                        MpzReader.configs.onDismiss?()
                        return
                    }
                    
                    let navigationController = self.createBookView()
                    viewController.present(navigationController, animated: true, completion: nil)
                }
            } catch {
                print("Error opening publication: \(error)")
                await MainActor.run {
                    MpzReader.configs.onError?()
                }
            }
        }
    }
    
    private func openPublication() async throws {
        // Initialize Readium components
        let httpClient = DefaultHTTPClient()
        self.assetRetriever = AssetRetriever(httpClient: httpClient)
        
        // Initialize Custom Content Protection
        let contentProtection = AESContentProtection()
        
        self.publicationOpener = PublicationOpener(
            parser: DefaultPublicationParser(
                httpClient: httpClient,
                assetRetriever: self.assetRetriever,
                pdfFactory: DefaultPDFDocumentFactory()
            ),
            contentProtections: [contentProtection]
        )
        
        // Convert URL to FileURL
        guard let fileUrl = FileURL(string: self.book.epubPath.absoluteString) else {
            throw NSError(domain: "Invalid EPUB path", code: -1)
        }
        
        // Retrieve asset
        let assetResult = await self.assetRetriever.retrieve(url: fileUrl)
        guard case .success(let asset) = assetResult else {
            throw NSError(domain: "Failed to retrieve asset", code: -1)
        }
        
        // Open publication
        let openResult = await self.publicationOpener.open(
            asset: asset,
            allowUserInteraction: false
        )
        
        switch openResult {
        case .success(let publication):
            self.publication = publication
            print("EPUB opened successfully at \(self.book.epubPath)")
            
            // Extract if needed (optional - you may not need this with GCDWebServer adapter)
            //self.extractEpubIfNeeded()
            
        case .failure(let error):
            throw error
        }
    }
    
    private func createBookView() -> UINavigationController {
        let stry = UIStoryboard.init(name: "Main", bundle: Bundle.init(for: type(of: self)))
        let vc = stry.instantiateViewController(withIdentifier: "reader") as! MpzBookVC
        vc.reader = self
        let navController = UINavigationController()
        navController.viewControllers = [vc]
        navController.modalPresentationStyle = .fullScreen
        return navController
    }
    
    // MARK: - EPUB Extraction (if needed for legacy reasons)
    
    /// Extracts the EPUB file to a temporary directory
    /// Note: In Readium 3.x, this is usually NOT needed as the GCDWebServer adapter
    /// can serve content directly from the archive. Only use if you have a specific need.
    private func extractEpubIfNeeded() {
        // If you don't actually need extraction, you can remove this method entirely
        // The GCDWebServer adapter handles serving from archives automatically
        
//        guard FileManager.default.fileExists(atPath: self.book.epubPath.path) else {
//            print("EPUB file not found at path")
//            return
//        }
//        
//        do {
//            var tmpFolder = URL(fileURLWithPath: NSTemporaryDirectory())
//            tmpFolder = tmpFolder.appendingPathComponent(UUID().uuidString)
//            try FileManager.default.createDirectory(at: tmpFolder, withIntermediateDirectories: true, attributes: nil)
//            
//            self.extractToPath = tmpFolder
//            print("Extracting EPUB to: \(tmpFolder)")
//            
//            // Extract using ZIPFoundation directly from the EPUB file
//            let fileManager = FileManager()
//            try fileManager.unzipItem(at: self.book.epubPath, to: tmpFolder)
//            
//            print("EPUB extracted successfully")
//        } catch {
//            print("Error extracting EPUB: \(error.localizedDescription)")
//            // Don't fail - extraction is optional with Readium 3.x
//        }
    }
    
    private func initializeDatabase() {
        let url = try? FileManager.default.url(
            for: .libraryDirectory,
            in: .userDomainMask,
            appropriateFor: nil, create: true
        )
        
        guard let rootPath = url else {
            print("database path initilization failed")
            return
        }
        
        guard let connection = try? Connection(rootPath.appendingPathComponent("db_fl").absoluteString) else {
            print("database initilization failed")
            return
        }
        
        MPZDBService.connection = connection
        Highlight.initialize()
        Highlight.fetch(ForBook: book.id)
    }
    
    /// Get colors based on EPUB theme/appearance
    /// In Readium 3.x, we use EPUBPreferences theme instead of deprecated UserProperty
    func getColors(forTheme theme: Theme?) -> MpzColors {
        guard let theme = theme else {
            return MpzColors()
        }
        
        switch theme {
        case .dark:
            return MpzReader.configs.darkColors
        case .light, .sepia:
            return MpzReader.configs.lightColors
        @unknown default:
            return MpzReader.configs.lightColors
        }
    }
}


public class MpzConfig {
    public var lightColors = MpzColors()
    public var darkColors = MpzColors.init(primary: UIColor.black, secondary: .white, textColor: .white, background: .black)
    public var isSettingsEnabled = true
    public var isEnableManualBookmarking = true
    public var isContentEnabled = true
    public var isHighlightsEnabled = true
    public var isShareEnabled = false
    public var isLookupEnabled = false
    public var fontName = "Helvetica"
    public var onDismiss : (() -> Void)?
    public var onError : (() -> Void)?
    public var onHtmlTransform : ((_ raw : String) -> String)?
    public var bookTitle : String? = nil
}
