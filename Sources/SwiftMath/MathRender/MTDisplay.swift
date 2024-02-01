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
@AddMTDisplayConformance
public protocol MTDisplay {
  func draw(_ context:CGContext)
  func displayBounds() -> CGRect
}

extension MTDisplay {
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
