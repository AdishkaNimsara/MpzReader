//
//  Highlight.swift
//  MpzReader
//
//  Created by Sithu on 8/17/19.
//

import SwiftyJSON
import SQLite
import ReadiumShared
import ReadiumNavigator
import Foundation

public class Highlight {
    
    static var list = [Highlight]()
    static var connection : Connection?
    
    var id : String!
    var book : String!
    var hightlightedText : String?
    var createdAt : String!
    var range : String?
    var color : String?
    
    var resourceHref: String!
    var resourceTitle: String!
    var resourceType: String!
    var locations: String!
    var locatorText: String!
    
    public var locator : Locator? {
        set {
            guard let loc = newValue else {
                return
            }
            // Fix: AnyURL to String
            self.resourceHref = loc.href.string
            // Fix: mediaType to String
            self.resourceType = loc.mediaType.string
            
            // Fix: Serialize Locations using Readium's JSON property
            if let data = try? JSONSerialization.data(withJSONObject: loc.locations.json) {
                self.locations = String(data: data, encoding: .utf8) ?? ""
            } else {
                self.locations = "{}"
            }
            
            // Fix: Serialize Text using Readium's JSON property
            // loc.text is non-optional in Readium 3.x
            if let data = try? JSONSerialization.data(withJSONObject: loc.text.json) {
                self.locatorText = String(data: data, encoding: .utf8) ?? ""
            } else {
                self.locatorText = "{}"
            }
            
            self.resourceTitle = loc.title ?? ""
        }
        
        get {
            
            if self.resourceType == nil || self.resourceHref == nil ||
                self.locations == nil || self.locatorText ==  nil {
                return nil
            }
            
            // Fix: Deserialize Locations
            let locationsObj: Locator.Locations
            // Try explicit JSON decoding using Readium's JSON init
            if let data = self.locations.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let obj = try? Locator.Locations(json: json) {
                locationsObj = obj
            } else {
                locationsObj = Locator.Locations()
            }
            
            // Fix: Deserialize Text
            let textObj: Locator.Text
            if let data = self.locatorText.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let obj = try? Locator.Text(json: json) {
                textObj = obj
            } else {
                textObj = Locator.Text()
            }
            
            // Fix: Create AnyURL and MediaType
            guard let hrefUrl = AnyURL(string: self.resourceHref) else { return nil }
            let mType = MediaType(self.resourceType) ?? .html
            
            return Locator(
                href: hrefUrl,
                mediaType: mType,
                title: self.resourceTitle,
                locations: locationsObj,
                text: textObj
            )
        }
    }
    
    static let TABLE = Table("highlight")
    static let tbl_id = Expression<String>(value: "id")
    static let tbl_book = Expression<String>(value: "book")
    static let tbl_hightlightedText = Expression<String?>(value: "hightlightedText")
    static let tbl_createdAt = Expression<String>(value: "createdAt")
    static let tbl_range = Expression<String?>(value: "range")
    static let tbl_color = Expression<String?>(value: "color")


    static let tbl_recource_href = Expression<String>(value: "resourceHref")
    static let tbl_recource_type = Expression<String>(value: "resourceType")
    static let tbl_recource_title = Expression<String>(value: "resourceTitle")
    static let tbl_locations = Expression<String>(value: "locations")
    static let tbl_locator_text = Expression<String>(value: "locatorText")
    
    init() {
        
    }
    
    init(json : JSON, book : String, locator : Locator) {
        self.id = json["id"].stringValue
        self.book = book
        self.hightlightedText = json["text"].string
        self.createdAt = "Now"
        self.range = json["range"].rawString()
        self.color = json["color"].stringValue
        self.locator = locator
    }
    
}

extension Highlight {
    
    func save() {
        Highlight.list.append(self)
        let insert = Highlight.TABLE.insert(
            Highlight.tbl_id <- self.id,
            Highlight.tbl_book <- self.book,
            Highlight.tbl_hightlightedText <- self.hightlightedText ?? "",
            Highlight.tbl_createdAt <- self.createdAt,
            Highlight.tbl_range <- self.range ?? "",
            Highlight.tbl_color <- self.color ?? "",
            Highlight.tbl_recource_href <- self.resourceHref,
            Highlight.tbl_recource_type <- self.resourceType,
            Highlight.tbl_recource_title <- self.resourceTitle,
            Highlight.tbl_locations <- self.locations,
            Highlight.tbl_locator_text <- self.locatorText
        )
        guard let connection = MPZDBService.connection else {
            return
        }
        let res = try? connection.run(insert)
        print("save hightlight = ", self.id, ", result = ", res as Any)
    }
    
    func update() {
        let row = Highlight.TABLE.filter(Highlight.tbl_id == self.id)
        let update = row.update(
            Highlight.tbl_color <- self.color ?? ""
        )
        guard let connection = MPZDBService.connection else {
            return
        }
        let res = try? connection.run(update)
        print("update hightlight = ", self.id, ", result = ", res as Any)
    }
    
    func delete() {
        Highlight.list.removeAll(where: {$0.id == self.id})
        let row = Highlight.TABLE.filter(Highlight.tbl_id == self.id)
        guard let connection = MPZDBService.connection else {
            return
        }
        let res = try? connection.run(row.delete())
        print("delete hightlight = ", self.id, ", result = ", res as Any)
    }
    
    static func fetch(ForBook id : String) {
        Highlight.list = []
        let select = Highlight.TABLE.filter(Highlight.tbl_book == id)
        guard let connection = MPZDBService.connection else {
            return
        }
        
        try? connection.prepare(select).forEach({ (row) in
            let h = Highlight()
            h.id = row[Highlight.tbl_id]
            h.book = row[Highlight.tbl_book]
            h.hightlightedText = row[Highlight.tbl_hightlightedText]
            h.createdAt = row[Highlight.tbl_createdAt]
            h.range = row[Highlight.tbl_range]
            h.color = row[Highlight.tbl_color]
            h.resourceType = row[Highlight.tbl_recource_type]
            h.resourceTitle = row[Highlight.tbl_recource_title]
            h.resourceHref = row[Highlight.tbl_recource_href]
            h.locations = row[Highlight.tbl_locations]
            h.locatorText = row[Highlight.tbl_locator_text]
            Highlight.list.append(h)
        })
    }
    
    static func find(ById id : String) -> Highlight? {
        return Highlight.list.filter({$0.id == id}).first
    }
    
    static func initialize() {
        guard let connection = MPZDBService.connection else {
            return
        }
        let _ = try? connection.run(Highlight.TABLE.create(temporary: false, ifNotExists: true) { t in
            t.column(Highlight.tbl_id, unique: true)
            t.column(Highlight.tbl_book)
            t.column(Highlight.tbl_hightlightedText)
            t.column(Highlight.tbl_createdAt)
            t.column(Highlight.tbl_range)
            t.column(Highlight.tbl_color)
            t.column(Highlight.tbl_recource_href)
            t.column(Highlight.tbl_recource_type)
            t.column(Highlight.tbl_recource_title)
            t.column(Highlight.tbl_locations)
            t.column(Highlight.tbl_locator_text)
        })
        
        print("highlight table created in not exisit")
    }
    
    static func getHighlights(ForHref href : String) -> [Highlight] {
        return Highlight.list.filter({$0.resourceHref == href})
    }
    
}
