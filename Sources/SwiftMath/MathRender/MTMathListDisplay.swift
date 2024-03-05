//
//  Created by Mike Griebling on 2022-12-31.
//  Translated from an Objective-C implementation by Kostub Deshmukh.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import Foundation
import QuartzCore
import CoreText
import SwiftUI

//@attached(extension, names:arbitrary, conformances:MTDisplay)
@attached(peer,
  names: named(CTLineDisplay),
         named(MathListDisplay),
         named(GlyphDisplay),
         named(GlyphConstructionDisplay),
         named(LargeOpLimitsDisplay),
         named(FractionDisplay),
         named(RadicalDisplay),
         named(LineDisplay),
         named(AccentDisplay)
)
public macro AddMTDisplayConformances(_ structSkeletons:String...) = #externalMacro(module: "MattsMacrosImpl", type: "ContextWalkerMacro")

public enum MT {
  @AddMTDisplayConformances(
"""
public struct CTLineDisplay {
    /// The CTLine being displayed
    public var line:CTLine!
    /// The attributed string used to generate the CTLineRef. Note setting this does not reset the dimensions of
    /// the display. So set only when
    var attributedString:NSAttributedString? {
        didSet {
            line = CTLineCreateWithAttributedString(attributedString!)
        }
    }
    
    /// An array of MTMathAtoms that this CTLine displays. Used for indexing back into the MTMathList
    public fileprivate(set) var atoms = [MTMathAtom]()
    
    init(withString attrString:NSAttributedString?, position:CGPoint, range:NSRange, font:MTFont?, atoms:[MTMathAtom]) {
        _position = position
        self.attributedString = attrString
        self.line = CTLineCreateWithAttributedString(attrString!)
        _range = range
        self.atoms = atoms
        // We can't use typographic bounds here as the ascent and descent returned are for the font and not for the line.
        _width = CTLineGetTypographicBounds(line, nil, nil, nil);
        let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        _ascent = max(0, CGRectGetMaxY(bounds) - 0);
        _descent = max(0, 0 - CGRectGetMinY(bounds));
        // TODO: Should we use this width vs the typographic width? They are slightly different. Don't know why.
        // _width = CGRectGetMaxX(bounds);
    }
    
    public var textColor: MTColor? {
        set {
            _textColor = newValue
            let attrStr = attributedString!.mutableCopy() as! NSMutableAttributedString
            let foregroundColor = NSAttributedString.Key(kCTForegroundColorAttributeName as String)
            attrStr.addAttribute(foregroundColor, value:self.textColor!.cgColor, range:NSMakeRange(0, attrStr.length))
            self.attributedString = attrStr
        }
        get { _textColor }
    }

    mutating func computeDimensions(_ font:MTFont?) {
        let runs = CTLineGetGlyphRuns(line) as NSArray
        for obj in runs {
            let run = obj as! CTRun?
            let numGlyphs = CTRunGetGlyphCount(run!)
            var glyphs = [CGGlyph]()
            glyphs.reserveCapacity(numGlyphs)
            CTRunGetGlyphs(run!, CFRangeMake(0, numGlyphs), &glyphs);
            let bounds = CTFontGetBoundingRectsForGlyphs(font!.ctFont, .horizontal, glyphs, nil, numGlyphs);
            let ascent = max(0, CGRectGetMaxY(bounds) - 0);
            // Descent is how much the line goes below the origin. However if the line is all above the origin, then descent can't be negative.
            let descent = max(0, 0 - CGRectGetMinY(bounds));
            if (ascent > self.ascent) {
                self.ascent = ascent;
            }
            if (descent > self.descent) {
                self.descent = descent;
            }
        }
    }
    
    public func draw(_ context: CGContext) {
        defaultDraw(context)
        context.saveGState()
        
        context.textPosition = self.position
        CTLineDraw(line, context)
        context.restoreGState()
    }
    
}
""",
"""
public struct MathListDisplay {

    /**
          The type of position for a line, i.e. subscript/superscript or regular.
     */
    public enum LinePosition : Int {
        /// Regular
        case regular
        /// Positioned at a subscript
        case ssubscript
        /// Positioned at a superscript
        case superscript
    }
    
    /// Where the line is positioned
    public var type:LinePosition = .regular
    /// An array of MTDisplays which are positioned relative to the position of the
    /// the current display.
    public fileprivate(set) var subDisplays = [any Display]()
    /// If a subscript or superscript this denotes the location in the parent MTList. For a
    /// regular list this is NSNotFound
    public var index: Int = 0
    
    init(withDisplays displays:[any Display], range:NSRange) {
        self.subDisplays = displays
        self.position = CGPoint.zero
        self.type = .regular
        self.index = NSNotFound
        self.range = range
        self.recomputeDimensions()
    }
  
    public var textColor: MTColor? {
        set {
            _textColor = newValue
            for i in 0..<self.subDisplays.count {
              if self.subDisplays[i].localTextColor == nil {
                self.subDisplays[i].textColor = newValue
              } else {
                self.subDisplays[i].textColor = self.subDisplays[i].localTextColor
              }
            }
        }
        get { _textColor }
    }

    public func draw(_ context: CGContext) {
        defaultDraw(context)
        context.saveGState()
        
        // Make the current position the origin as all the positions of the sub atoms are relative to the origin.
        context.translateBy(x: self.position.x, y: self.position.y)
        context.textPosition = CGPoint.zero
      
        // draw each atom separately
        for displayAtom in self.subDisplays {
            displayAtom.draw(context)
        }
        
        context.restoreGState()
    }

    mutating func recomputeDimensions() {
        var max_ascent:CGFloat = 0
        var max_descent:CGFloat = 0
        var max_width:CGFloat = 0
        for atom in self.subDisplays {
            let ascent = max(0, atom.position.y + atom.ascent);
            if (ascent > max_ascent) {
                max_ascent = ascent;
            }
            
            let descent = max(0, 0 - (atom.position.y - atom.descent));
            if (descent > max_descent) {
                max_descent = descent;
            }
            let width = atom.width + atom.position.x;
            if (width > max_width) {
                max_width = width;
            }
        }
        self.ascent = max_ascent;
        self.descent = max_descent;
        self.width = max_width;
    }
    
}
""",
"""
struct GlyphDisplay : MTDisplayDS {
    
    var glyph:CGGlyph!
    var font:MTFont?
    public var shiftDown:CGFloat = 0
    init(withGlpyh glyph:CGGlyph, range:NSRange, font:MTFont?) {
        self.font = font
        self.glyph = glyph

        self.position = CGPoint.zero
        self.range = range
    }

    public func draw(_ context: CGContext) {
        defaultDraw(context)
        context.saveGState()

        if let color = self.textColor?.cgColor {
            context.setFillColor(color)
        }
        
        // Make the current position the origin as all the positions of the sub atoms are relative to the origin.
        
        context.translateBy(x: self.position.x, y: self.position.y - self.shiftDown);
        context.textPosition = CGPoint.zero

        var pos = CGPoint.zero
        if let __glyph = glyph {
          var _glyph = __glyph
          CTFontDrawGlyphs(font!.ctFont, &_glyph, &pos, 1, context);
        }
            
        context.restoreGState();
    }

    var ascent:CGFloat {
        set { _ascent = newValue }
        get { _ascent - self.shiftDown }
    }

    var descent:CGFloat {
        set { _descent = newValue }
        get { _descent + self.shiftDown }
    }
}
""",
"""
struct GlyphConstructionDisplay:MTDisplayDS {
    var glyphs = [CGGlyph]()
    var positions = [CGPoint]()
    var font:MTFont?
    var numGlyphs:Int=0
    var shiftDown:CGFloat = 0
    init(withGlyphs glyphs:[NSNumber?], offsets:[NSNumber?], font:MTFont?) {
        assert(glyphs.count == offsets.count, "Glyphs and offsets need to match")
        self.numGlyphs = glyphs.count;
        self.glyphs = [CGGlyph](repeating: CGGlyph(), count: self.numGlyphs)  //malloc(sizeof(CGGlyph) * _numGlyphs);
        self.positions = [CGPoint](repeating: CGPoint.zero, count: self.numGlyphs) //malloc(sizeof(CGPoint) * _numGlyphs);
        for i in 0 ..< self.numGlyphs {
            self.glyphs[i] = glyphs[i]!.uint16Value
            self.positions[i] = CGPointMake(0, CGFloat(offsets[i]!.floatValue))
        }
        self.font = font
        self.position = CGPoint.zero
    }
    
    public func draw(_ context: CGContext) {
        defaultDraw(context)
        context.saveGState()
        
        if let color = self.textColor?.cgColor {
            context.setFillColor(color)
        }

        // Make the current position the origin as all the positions of the sub atoms are relative to the origin.
        context.translateBy(x: self.position.x, y: self.position.y - self.shiftDown)
        context.textPosition = CGPoint.zero
        
        // Draw the glyphs.
        CTFontDrawGlyphs(font!.ctFont, glyphs, positions, numGlyphs, context)
        
        context.restoreGState()
    }
    
    var ascent:CGFloat {
        set { _ascent = newValue }
        get { _ascent - self.shiftDown }
    }

    var descent:CGFloat {
        set { _descent = newValue }
        get { _descent + self.shiftDown }
    }
    
}
""",
"""
struct LargeOpLimitsDisplay {
    
    /** A display representing the upper limit of the large operator. Its position is relative
     to the parent is not treated as a sub-display.
     */
    var upperLimit:MT.MathListDisplay?
    /** A display representing the lower limit of the large operator. Its position is relative
     to the parent is not treated as a sub-display.
     */
    var lowerLimit:MT.MathListDisplay?
    
    var limitShift:CGFloat=0
    var upperLimitGap:CGFloat=0 { didSet { self.updateUpperLimitPosition() } }
    var lowerLimitGap:CGFloat=0 { didSet { self.updateLowerLimitPosition() } }
    var extraPadding:CGFloat=0

    var nucleus:(any Display)?
    
    init(withNucleus nucleus:(any Display)?, upperLimit:MT.MathListDisplay?, lowerLimit:MT.MathListDisplay?, limitShift:CGFloat, extraPadding:CGFloat) {
        self.upperLimit = upperLimit;
        self.lowerLimit = lowerLimit;
        self.nucleus = nucleus;
        
        var maxWidth = max(nucleus!.width, upperLimit?.width ?? 0)
        maxWidth = max(maxWidth, lowerLimit?.width ?? 0)
        
        self.limitShift = limitShift;
        self.upperLimitGap = 0;
        self.lowerLimitGap = 0;
        self.extraPadding = extraPadding;  // corresponds to \\xi_13 in TeX
        self.width = maxWidth;
    }

    var ascent:CGFloat {
        set { _ascent = newValue }
        get {
            if self.upperLimit != nil {
                return nucleus!.ascent + extraPadding + self.upperLimit!.ascent + upperLimitGap + self.upperLimit!.descent
            } else {
                return nucleus!.ascent
            }
        }
    }

    var descent:CGFloat {
        set { _descent = newValue }
        get {
            if self.lowerLimit != nil {
                return nucleus!.descent + extraPadding + lowerLimitGap + self.lowerLimit!.descent + self.lowerLimit!.ascent;
            } else {
                return nucleus!.descent;
            }
        }
    }
    
    var position: CGPoint {
        set {
            _position = newValue
            self.updateLowerLimitPosition()
            self.updateUpperLimitPosition()
            self.updateNucleusPosition()
        }
        get { _position }
    }

    mutating func updateLowerLimitPosition() {
        if self.lowerLimit != nil {
            // The position of the lower limit includes the position of the MTLargeOpLimitsDisplay
            // This is to make the positioning of the radical consistent with fractions and radicals
            // Move the starting point to below the nucleus leaving a gap of _lowerLimitGap and subtract
            // the ascent to to get the baseline. Also center and shift it to the left by _limitShift.
            self.lowerLimit!.position = CGPointMake(self.position.x - limitShift + (self.width - lowerLimit!.width)/2,
                                                   self.position.y - nucleus!.descent - lowerLimitGap - self.lowerLimit!.ascent);
        }
    }

    mutating func updateUpperLimitPosition() {
        if self.upperLimit != nil {
            // The position of the upper limit includes the position of the MTLargeOpLimitsDisplay
            // This is to make the positioning of the radical consistent with fractions and radicals
            // Move the starting point to above the nucleus leaving a gap of _upperLimitGap and add
            // the descent to to get the baseline. Also center and shift it to the right by _limitShift.
            self.upperLimit!.position = CGPointMake(self.position.x + limitShift + (self.width - self.upperLimit!.width)/2,
                                                   self.position.y + nucleus!.ascent + upperLimitGap + self.upperLimit!.descent);
        }
    }

    mutating func updateNucleusPosition() {
        // Center the nucleus
      let copy = self
      nucleus?.position = CGPointMake(copy.position.x + (copy.width - copy.nucleus!.width)/2, copy.position.y);
    }
    
    var textColor: MTColor? {
        set {
            _textColor = newValue
            self.upperLimit?.textColor = newValue
            self.lowerLimit?.textColor = newValue
            nucleus?.textColor = newValue
        }
        get { _textColor }
    }

    func draw(_ context:CGContext) {
        defaultDraw(context)
        // Draw the elements.
        self.upperLimit?.draw(context)
        self.lowerLimit?.draw(context)
        nucleus?.draw(context)
    }
}
""",
"""
public struct FractionDisplay {
    /** A display representing the numerator of the fraction. Its position is relative
     to the parent and is not treated as a sub-display.
     */
    public fileprivate(set) var numerator:MT.MathListDisplay?
    /** A display representing the denominator of the fraction. Its position is relative
     to the parent is not treated as a sub-display.
     */
    public fileprivate(set) var denominator:MT.MathListDisplay?
    
    var numeratorUp:CGFloat=0 { didSet { self.updateNumeratorPosition() } }
    var denominatorDown:CGFloat=0 { didSet { self.updateDenominatorPosition() } }
    var linePosition:CGFloat=0
    var lineThickness:CGFloat=0
    
    init(withNumerator numerator:MT.MathListDisplay?, denominator:MT.MathListDisplay?, position:CGPoint, range:NSRange) {
        self.numerator = numerator;
        self.denominator = denominator;
        self.position = position;
        self.range = range;
        assert(self.range.length == 1, "Fraction range length not 1 - range (\\(range.location), \\(range.length)")
    }

    public var ascent:CGFloat {
        set { _ascent = newValue }
        get { numerator!.ascent + self.numeratorUp }
    }

    public var descent:CGFloat {
        set { _descent = newValue }
        get { denominator!.descent + self.denominatorDown }
    }

    public var width:CGFloat {
        set { _width = newValue }
        get { max(numerator!.width, denominator!.width) }
    }

    mutating func updateDenominatorPosition() {
        guard denominator != nil else { return }
        denominator!.position = CGPointMake(self.position.x + (self.width - denominator!.width)/2, self.position.y - self.denominatorDown)
    }

    mutating func updateNumeratorPosition() {
        guard numerator != nil else { return }
        numerator!.position = CGPointMake(self.position.x + (self.width - numerator!.width)/2, self.position.y + self.numeratorUp)
    }

    public var position: CGPoint {
        set {
            _position = newValue
            self.updateDenominatorPosition()
            self.updateNumeratorPosition()
        }
        get { _position }
    }
    
    public var textColor: MTColor? {
        set {
            _textColor = newValue
            numerator?.textColor = newValue
            denominator?.textColor = newValue
        }
        get { _textColor }
    }

    public func draw(_ context:CGContext) {
        defaultDraw(context)
        numerator?.draw(context)
        denominator?.draw(context)

        context.saveGState()
        
        if let color = self.textColor?.cgColor {
            context.setStrokeColor(color)
        }

        // draw the horizontal line
        // Note: line thickness of 0 draws the thinnest possible line - we want no line so check for 0s
        if self.lineThickness > 0 {
            context.move(to: CGPointMake(self.position.x, self.position.y + self.linePosition))
            context.addLine(to: CGPointMake(self.position.x + self.width, self.position.y + self.linePosition))
            context.setLineWidth(self.lineThickness)
            context.strokePath()
        }
        
        context.restoreGState()
    }
    
}
""",
"""
struct RadicalDisplay {
    
    /** A display representing the radicand of the radical. Its position is relative
     to the parent is not treated as a sub-display.
     */
    public fileprivate(set) var radicand:MT.MathListDisplay?
    /** A display representing the degree of the radical. Its position is relative
     to the parent is not treated as a sub-display.
     */
    public fileprivate(set) var degree:MT.MathListDisplay?
    
    var position: CGPoint {
        set {
            self._position = newValue
            self.updateRadicandPosition()
        }
        get { _position }
    }
    
    var textColor: MTColor? {
        set {
            _textColor = newValue
            self.radicand?.textColor = newValue
            self.degree?.textColor = newValue
        }
        get { _textColor }
    }
    
    private var _radicalGlyph:(any Display)?
    private var _radicalShift:CGFloat=0
    
    var topKern:CGFloat=0
    var lineThickness:CGFloat=0
    
    init(withRadicand radicand:MT.MathListDisplay?, glyph:any Display, position:CGPoint, range:NSRange) {
        self.radicand = radicand
        _radicalGlyph = glyph
        _radicalShift = 0

        self.position = position
        self.range = range
    }

    mutating func setDegree(_ degree:MT.MathListDisplay?, fontMetrics:MTFontMathTable?) {
        // sets up the degree of the radical
        var kernBefore = fontMetrics!.radicalKernBeforeDegree;
        let kernAfter = fontMetrics!.radicalKernAfterDegree;
        let raise = fontMetrics!.radicalDegreeBottomRaisePercent * (self.ascent - self.descent);

        // The layout is:
        // kernBefore, raise, degree, kernAfter, radical
        self.degree = degree;

        // the radical is now shifted by kernBefore + degree.width + kernAfter
        _radicalShift = kernBefore + degree!.width + kernAfter;
        if _radicalShift < 0 {
            // we can't have the radical shift backwards, so instead we increase the kernBefore such
            // that _radicalShift will be 0.
            kernBefore -= _radicalShift;
            _radicalShift = 0;
        }
        
        // Note: position of degree is relative to parent.
        self.degree!.position = CGPointMake(self.position.x + kernBefore, self.position.y + raise);
        // Update the width by the _radicalShift
        self.width = _radicalShift + _radicalGlyph!.width + self.radicand!.width;
        // update the position of the radicand
        self.updateRadicandPosition()
    }

    mutating func updateRadicandPosition() {
        // The position of the radicand includes the position of the MTRadicalDisplay
        // This is to make the positioning of the radical consistent with fractions and
        // have the cursor position finding algorithm work correctly.
        // move the radicand by the width of the radical sign
        self.radicand!.position = CGPointMake(self.position.x + _radicalShift + _radicalGlyph!.width, self.position.y);
    }

    public func draw(_ context: CGContext) {
        defaultDraw(context)
        
        // draw the radicand & degree at its position
        self.radicand?.draw(context)
        self.degree?.draw(context)

        context.saveGState();
        if let color = self.textColor?.cgColor {
          context.setStrokeColor(color)
          context.setFillColor(color)
        }
      
        // Make the current position the origin as all the positions of the sub atoms are relative to the origin.
        context.translateBy(x: self.position.x + _radicalShift, y: self.position.y);
        context.textPosition = CGPoint.zero

        // Draw the glyph.
        _radicalGlyph?.draw(context)

        // Draw the VBOX
        // for the kern of, we don't need to draw anything.
        let heightFromTop = topKern;

        // draw the horizontal line with the given thickness
        let lineStart = CGPointMake(_radicalGlyph!.width, self.ascent - heightFromTop - self.lineThickness / 2); // subtract half the line thickness to center the line
        let lineEnd = CGPointMake(lineStart.x + self.radicand!.width, lineStart.y);
        context.move(to: lineStart)
        context.addLine(to: lineEnd)
        context.setLineWidth(lineThickness)
        context.setLineCap(.round)
        context.strokePath()
        context.restoreGState();
    }
}
""",
"""
struct LineDisplay {
    
  /** A display representing the inner list that is underlined. Its position is relative
   to the parent is not treated as a sub-display.
   */
  var inner:MT.MathListDisplay?
  var lineShiftUp:CGFloat=0
  var lineThickness:CGFloat=0
  
  init(withInner inner:MT.MathListDisplay?, position:CGPoint, range:NSRange) {
    self.inner = inner;
    self.position = position;
    self.range = range;
  }
    
  var textColor: MTColor? {
    set {
      _textColor = newValue
      inner?.textColor = newValue
    }
    get { _textColor }
  }
    
    var position: CGPoint {
        set {
            _position = newValue
            self.updateInnerPosition()
        }
        get { _position }
    }

    func draw(_ context:CGContext) {
        defaultDraw(context)
        self.inner?.draw(context)
        
        context.saveGState();
        
        if let color = self.textColor?.cgColor {
            context.setStrokeColor(color)
        }

        // draw the horizontal line
        let path = MTBezierPath()
        let lineStart = CGPointMake(self.position.x, self.position.y + self.lineShiftUp);
        let lineEnd = CGPointMake(lineStart.x + self.inner!.width, lineStart.y);
        path.move(to:lineStart)
        path.addLine(to: lineEnd)
        path.lineWidth = self.lineThickness;
        context.strokePath()
        
        context.restoreGState();
    }

    mutating func updateInnerPosition() {
      if let copy = self.inner?.position {
        self.inner?.position = CGPointMake(copy.x, copy.y);
      }
    }
    
}
""",
"""
struct AccentDisplay {
    
    /** A display representing the inner list that is accented. Its position is relative
     to the parent is not treated as a sub-display.
     */
    var accentee:MathListDisplay?
    
    /** A display representing the accent. Its position is relative to the current display.
     */
    var accent:GlyphDisplay?
    
    init(withAccent glyph:GlyphDisplay?, accentee:MathListDisplay?, range:NSRange) {
        self.accent = glyph
        self.accentee = accentee
        self.accentee?.position = CGPoint.zero
        self.range = range
    }
    
    var textColor: MTColor? {
        set {
            _textColor = newValue
            accentee?.textColor = newValue
            accent?.textColor = newValue
        }
        get { _textColor }
    }

    var position: CGPoint {
        set {
            _position = newValue
            self.updateAccenteePosition()
        }
        get { _position }
    }

    mutating func updateAccenteePosition() {
      if let copy = self.accentee?.position {
        self.accentee?.position = CGPointMake(copy.x, copy.y);
      }
    }

    func draw(_ context:CGContext) {
        defaultDraw(context)
        self.accentee?.draw(context)

        context.saveGState();
        context.translateBy(x: self.position.x, y: self.position.y);
        context.textPosition = CGPoint.zero

        self.accent?.draw(context)

        context.restoreGState();
    }
    
}
""")
  public protocol Display {
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
}

//public typealias MTDisplay = MTDisplayConformances.MTDisplay
//public typealias MT.MathListDisplay = MTDisplayConformances.MT.MathListDisplay
//public typealias MTCTLineDisplay = MTDisplayConformances.MTCTLineDisplay
//typealias MTGlyphDisplay = MTDisplayConformances.MTGlyphDisplay
//typealias MTGlyphConstructionDisplay = MTDisplayConformances.MTGlyphConstructionDisplay

extension MT.Display {
  
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

#if os(iOS)
  func debugQuickLookObject() -> Any {
      let size = CGSizeMake(self.width, self.ascent + self.descent);
      UIGraphicsBeginImageContext(size);
      
      // get a reference to that context we created
      let context = UIGraphicsGetCurrentContext()!
      // translate/flip the graphics context (for transforming from CG* coords to UI* coords
      context.translateBy(x: 0, y: size.height);
      context.scaleBy(x: 1.0, y: -1.0);
      // move the position to (0,0)
      context.translateBy(x: -self.position.x, y: -self.position.y);
      
      // Move the line up by self.descent
      context.translateBy(x: 0, y: self.descent);
      // Draw self on context
      self.draw(context)
      
      // generate a new UIImage from the graphics context we drew onto
      let img = UIGraphicsGetImageFromCurrentImageContext()
      return img as Any
  }
#endif
}
