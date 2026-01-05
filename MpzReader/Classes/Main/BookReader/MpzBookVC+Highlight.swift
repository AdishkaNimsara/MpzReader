//
//  MpzBookReaderVC+Highlight.swift
//  MenuItemKit
//
//  Created by Hasitha Mapalagama on 8/23/19.
//

import Foundation
import UIKit
import ReadiumNavigator
import ReadiumShared
import WebKit
import SwiftyJSON
//extension MpzBookVC : HighlightListDelegate {
////    func highlighDidClick(highlight: Highlight) {
////        if let loc = highlight.locator {
////            self.epubNavigator.go(to: loc, animated: true, completion: {})
////        }
////    }
//    
//    func delegateHighlight(highlight: Highlight) {
//        
//    }
//    
//}

extension MpzBookVC {
    
    func setupHighlightMenu() {
        let mc = UIMenuController.shared
        mc.menuItems = [UIMenuItem(title: "Highlight", action: #selector(didClickHighlight))]
    }
    
    @objc func didClickHighlight() {
        epubNavigator.execJS(script: "mpz_getSelectText('\(self.defaultHightlightColor)')", completion:  { data, err in
            if let str = data as? String, let loc = self.epubNavigator.currentLocation {
                let json = JSON.init(parseJSON: str)
                let hightlight = Highlight.init(json: json,
                                                book: self.reader.book.id,
                                                locator: loc)
                hightlight.save()
                DispatchQueue.main.async {
                    self.isColorHighlightMode = true
                    let rect = self.epubNavigator.view.convert(self.strint2Rect(string: json["frame"].stringValue), to: self.view)
                    self.showHightlightView(forHightlight: hightlight, rect: rect)
                    self.clearSelection()
                }
            }
        })
    }
    
    func showHightlightView(forHightlight highlight: Highlight, rect : CGRect) {
        let vc = HightlightView.create(withHighlight: highlight)
        vc.modalPresentationStyle = .popover
        let popup = vc.popoverPresentationController
        popup?.delegate = self
        popup?.sourceView = self.view
        popup?.sourceRect = rect
        popup?.backgroundColor = .black
        vc.onChangeColor = {
            $0.update()
            self.updateHighlight(highlight: $0)
            vc.dismiss(animated: true, completion: nil)
        }
        
        vc.onRemove = {
            $0.delete()
            self.deleteHighlight(id : $0.id)
            vc.dismiss(animated: true, completion: nil)
        }
        self.present(vc, animated: true, completion: nil)
    }
    
    func clearSelection() {
        self.view.isUserInteractionEnabled = false
        self.view.isUserInteractionEnabled = true
    }
    
    func markHighlights() {
//        guard let href = self.epubNavigator.currentLocation?.href else {
//            return
//        }
//        print(href)
//        for h in Highlight.getHighlights(ForHref: href) {
//            let json = JSON([
//                "range" : h.range,
//                "bgColor" : h.color ?? "yellow",
//                "id" : h.id ?? "-1"
//                ])
//            epubNavigator.execJS(script: "mpz_highlightRangeStr('\(json.rawString()!.toBase64())')")
//            self.clearSelection()
//        }
    }
    
    func deleteHighlight(id : String) {
        self.epubNavigator.execJS(script: "mpz_deleteHighlight('\(id)')")
    }
    
    func updateHighlight(highlight: Highlight) {
        self.epubNavigator.execJS(script: "mpz_updateHighlight('\(highlight.id ?? "")', '\(highlight.color ?? self.defaultHightlightColor)')")
    }
    
    func didTapOnHighlight(data : String) {
        
        let json = JSON.init(parseJSON: data)
        let rect = strint2Rect(string: json["frame"].stringValue)
        
        guard let highlight = Highlight.find(ById: json["id"].stringValue) else {
            return
        }
        showHightlightView(forHightlight: highlight, rect: rect)
    }
    
    
}
