//
//  File.swift
//  
//
//  Created by Matthew Whiteside on 4/9/23.
//

import QuartzCore
import CoreText
import SwiftUI

// The Downshift protocol allows an MTDisplay to be shifted down by a given amount.
protocol MTDisplayDS : MT.Display {
    var shiftDown:CGFloat { set get }
}
