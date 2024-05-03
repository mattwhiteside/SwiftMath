//
//  MathView.swift
//
//
//  Created by Matthew Whiteside on 3/4/23.
//

import SwiftUI


@available(macOS 13.0, *)
public struct MathView : View {
  
    /** The latex string to be displayed. Setting this will remove any `mathList` that
   has been set. If latex has not been set, this will return the latex output for the
   `mathList` that is set.
   @see error */
  @State private var latex:String

  /** This contains any error that occurred when parsing the latex. */
  @State private var error:String?
  
  /** If true, if there is an error it displays the error message inline. Default true. */
  @State private var displayErrorInline = true
  
  /** The MTFont to use for rendering. */
  @State private var font:MTFont
  @State private var fontSize:CGFloat = 12
  @State private var textColor:MTColor? = MTColor.black

  @State private var contentInsets:MTEdgeInsets
  
  /** The Label mode for the label. The default mode is Display */
  @State private var labelMode:MTMathUILabelMode = MTMathUILabelMode.display

  /** Horizontal alignment for the text. The default is align left. */
  @State private var textAlignment:MTTextAlignment = MTTextAlignment.left
  
//  /** The internal display of the MTMathUILabel. This is for advanced use only. */
//  public var displayList: MT.MathListDisplay? { _displayList }
//  private var _displayList:MT.MathListDisplay?
  public var currentStyle:MTLineStyle {
    switch labelMode {
      case .display: return .display
      case .text: return .text
    }
  }
  

  public init(latexExpr: String, fontSize:Double) {
    self.fontSize = CGFloat(fontSize)
    do {
      if let __font = try MTFontManager().termesFont(withSize: fontSize) {
        font = __font
      } else {
        font = MTFontManager.fontManager.defaultFont!
      }
      //self.textColor = .textColor
      textAlignment = .center
      contentInsets = MTEdgeInsetsZero
      latex = latexExpr//this should go last
    }
    catch let anyError {
      fatalError("Error: \(anyError)")
    }
  }
    
  public var body: some View {
    Canvas { context, size in
      var _error:String? = nil
      if let mathList = MTMathListBuilder.build(fromString: self.latex, error: &_error) {
        // print("Pre list = \(_mathList!)")
        if let _displayList = try? MTTypesetter.createLineForMathList(mathList, font: font, style: currentStyle) {
          var displayList = _displayList
          displayList.textColor = textColor
          // print("Post list = \(_mathList!)")
          var textX = CGFloat(0)
          let _temp = displayList.width - contentInsets.right
          switch self.textAlignment {
            case .left:   textX = contentInsets.left
            case .center: textX = (size.width - contentInsets.left - contentInsets.right - displayList.width) / 2 + contentInsets.left
            case .right:  textX = size.width - _temp
          }
          let availableHeight = size.height - contentInsets.bottom - contentInsets.top
          
          // center things vertically
          var height = displayList.ascent + displayList.descent
          if height < fontSize/2 {
            height = fontSize/2  // set height to half the font size
          }
          let textY = (availableHeight - height) / 2 + displayList.descent + contentInsets.bottom
          displayList.position = CGPointMake(textX, textY)
          context.withCGContext{ (cgContext:CGContext) in
            cgContext.saveGState()
            cgContext.translateBy(x:0, y:size.height)
            cgContext.scaleBy(x: 1, y: -1)
            displayList.draw(cgContext)
            cgContext.restoreGState()
          }
        }
      }
    }
    if let _error = error, displayErrorInline {
      Text(_error.description).foregroundColor(.red)
    }
  }

}
