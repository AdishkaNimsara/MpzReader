//
//  Highlight.swift
//  MpzReader
//
//  Created by Sithu on 8/17/19.
//

import SwiftyJSON
import SQLite
import R2Shared
import R2Navigator

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
            self.resourceHref = loc.href
            self.resourceType = loc.type
            self.locations = loc.locations.jsonString ?? ""
            self.locatorText = loc.text.jsonString ?? ""
            self.resourceTitle = loc.title ?? ""
        }
        
        get {
            
            if self.resourceType == nil || self.resourceHref == nil ||
                self.locations == nil || self.locatorText ==  nil {
                return nil
            }
            return Locator.init(href: self.resourceHref,
                                type: self.resourceType,
                                title: self.resourceTitle,
                                locations: Locations.init(jsonString: self.locations),
                                text: LocatorText.init(jsonString: self.locatorText))
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
