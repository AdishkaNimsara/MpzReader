//
//  MpzColors.swift
//  MpzReader
//
//  Created by Sithu on 8/17/19.
//

import Foundation
import ReadiumShared
public class MpzColors {
    public var primary : UIColor = UIColor(red:0.25, green:0.32, blue:0.71, alpha:1.0)
    public var secondary : UIColor = UIColor(red:0.19, green:0.25, blue:0.62, alpha:1.0)
    public var textColor : UIColor = UIColor.white
    public var background : UIColor = UIColor.white
    
    init() {
        
    }
    
    init(primary : UIColor, secondary : UIColor, textColor : UIColor, background : UIColor) {
        self.primary = primary
        self.secondary = secondary
        self.textColor = textColor
        self.background = background
    }
    
}
