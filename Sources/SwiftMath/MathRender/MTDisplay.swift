//
//  File.swift
//  
//
//  Created by Matthew Whiteside on 4/9/23.
//

import Foundation
import QuartzCore
import CoreText
import SwiftUI

// The Downshift protocol allows an MTDisplay to be shifted down by a given amount.
protocol MTDisplayDS : MTDisplay {
    var shiftDown:CGFloat { set get }
}

// MARK: - MTDisplay

/// The base class for rendering a math equation.
public protocol MTDisplay {
  
  /// The distance from the axis to the top of the display
  var ascent:CGFloat{
    get
    set
  }
  
  /// The distance from the axis to the bottom of the display
  var descent:CGFloat{
    get
    set
  }
  
  /// The width of the display
  var width:CGFloat{
    get
    set
  }
  
  /// Position of the display with respect to the parent view or display.
  var position: CGPoint{
    get
    set
  }
  
  /// The range of characters supported by this item
  var range:NSRange{
    get
    set
  }
  
  /// Whether the display has a subscript/superscript following it.
  var hasScript:Bool{
    get
    set
  }
  
  /// The text color for this display
  var textColor: MTColor?{
    get
    set
  }
  
  /// The local color, if the color was mutated local with the color command
  var localTextColor: MTColor?{
    get
    set
  }
  
  /// The background color for this display
  var localBackgroundColor: MTColor?{
    get
    set
  }
  
  func draw(_ context:CGContext)
  func displayBounds() -> CGRect
}

extension MTDisplay {
  internal typealias Storage = MTDisplay_Storage
  internal func defaultDraw(_ context:CGContext) {
    if self.localBackgroundColor != nil {
      context.saveGState()
      context.setBlendMode(.normal)
      context.setFillColor(self.localBackgroundColor!.cgColor)
      context.fill(self.displayBounds())
      context.restoreGState()
    }
  }
  
  public func draw(_ context:CGContext) {
    defaultDraw(context)
  }
  
  public func displayBounds() -> CGRect {
    CGRectMake(self.position.x, self.position.y - self.descent, self.width, self.ascent + self.descent)
  }

}

internal struct MTDisplay_Storage {
  var ascent:CGFloat = 5
  /// The distance from the axis to the bottom of the display
  var descent:CGFloat = 0
  /// The width of the display
  var width:CGFloat = 0
  /// Position of the display with respect to the parent view or display.
  var position = CGPoint.zero
  /// The range of characters supported by this item
  var range = NSMakeRange(0, 0)
  /// Whether the display has a subscript/superscript following it.
  var hasScript:Bool = false
  /// The text color for this display
  var textColor: MTColor?
  /// The local color, if the color was mutated local with the color command
  var localTextColor: MTColor?
  /// The background color for this display
  var localBackgroundColor: MTColor?
}
