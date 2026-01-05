//
//  ViewController.swift
//  MpzReader
//
//  Created by mapalagama93 on 08/16/2019.
//  Copyright (c) 2019 mapalagama93. All rights reserved.
//

import UIKit
import MpzReader

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  
    

    @IBOutlet weak var tableView: UITableView!
    var list = [ MpzBook ]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        list = [
            MpzBook.init(withPath: urlFor(book: "1"), id : "1", name : "Bisaw Sigiri"),
            MpzBook.init(withPath: urlFor(book: "2"), id : "2", name : "Robin hood"),
            MpzBook.init(withPath: urlFor(book: "3"), id : "3", name : "Alevikarana"),
            MpzBook.init(withPath: urlFor(book: "4"), id : "4", name : "Hediyakage dina potha"),
            MpzBook.init(withPath: urlFor(book: "5"), id : "5", name : "Kurrodaya")
        ]
        tableView.delegate = self
        tableView.dataSource = self
    }

    func urlFor(book : String) -> URL {
        let url = Bundle.main.path(forResource: book, ofType: "epub")
        return URL.init(fileURLWithPath: url!)
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.textLabel?.text = list[indexPath.item].epubName
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       MpzReader.configs.lightColors.primary = UIColor.orange
       MpzReader.configs.isEnableManualBookmarking = true
       MpzReader.configs.isHighlightsEnabled = true
        
       let mpzreader = MpzReader.init(withBook: list[indexPath.item])
        
       mpzreader.present(inViewController: self)
    }
}

