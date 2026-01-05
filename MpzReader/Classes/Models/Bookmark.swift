//
//  Bookmark.swift
//  MpzReader
//
//  Created by Sithu on 8/17/19.
//

import Foundation
import ReadiumShared
import SwiftyJSON
//class Bookmark {
//    
//    public var id: String!
//    public var resourceIndex: Int!
//    public var resourceHref: String!
//    public var resourceTitle: String!
//    public var resourceType: String!
//    public var locations: String!
//    public var locatorText: String!
//    
//    public var locator : Locator? {
//        set {
//            guard let loc = newValue else {
//                return
//            }
//            self.resourceHref = loc.href
//            self.resourceType = loc.type
//            self.locations = loc.locations.jsonString ?? ""
//            self.locatorText = loc.text.jsonString ?? ""
//            self.resourceTitle = loc.title ?? ""
//        }
//        
//        get {
//
//            if self.resourceType == nil || self.resourceHref == nil ||
//                self.locations == nil || self.locatorText ==  nil {
//                return nil
//            }
//            return Locator.init(href: self.resourceHref,
//                                type: self.resourceType,
//                                title: self.resourceTitle,
//                                locations: Locations.init(jsonString: self.locations),
//                                text: LocatorText.init(jsonString: self.locatorText))
//        }
//    }
//    
//    init() {
//        
//    }
//    
//    init(json : JSON) {
//        fill(json)
//    }
//    
//    fileprivate func fill(_ json: JSON) {
//        self.resourceIndex = json["resourceIndex"].intValue
//        self.resourceHref = json["resourceHref"].stringValue
//        self.resourceTitle = json["resourceTitle"].stringValue
//        self.resourceType = json["resourceType"].stringValue
//        self.locations = json["locations"].stringValue
//        self.locatorText = json["locatorText"].stringValue
//    }
//    
//    static func get(forBook book : String) -> Bookmark  {
//        let mark = Bookmark()
//        mark.id = book
//        mark.sync()
//        return mark
//    }
//    
//    func sync() {
//        if let bookmarkJson = UserDefaults.standard.string(forKey: "\(id!)-bm") {
//            let json = JSON.init(parseJSON: bookmarkJson)
//            self.fill(json)
//        }
//    }
//    
//    func save() {
//        let json = JSON([
//            "id" : self.id,
//            "resourceIndex" : self.resourceIndex,
//            "resourceHref" : self.resourceHref,
//            "resourceTitle" : self.resourceTitle,
//            "resourceType" : self.resourceType,
//            "locations" : self.locations,
//            "locatorText" : self.locatorText
//            ])
//        UserDefaults.standard.set(json.rawString() ?? "{}", forKey: "\(id!)-bm")
//    }
//    
//    
//    
//}
