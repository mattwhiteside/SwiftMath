//
//  Created by Mike Griebling on 2022-12-31.
//  Translated from an Objective-C implementation by Kostub Deshmukh.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import FoundationEssentials
import QuartzCore
import CoreText
import SwiftUI

@attached(peer, names: arbitrary)
public macro AddConformances(_ structSkeletons:String...) = #externalMacro(module: "MattsMacrosImpl", type: "ContextWalkerMacro")

public enum MT {
    
  public protocol MathAtom: Sendable {
    var type:MT.AtomType {get set}/*MT.AtomType.ordinary*/
    /** An optional subscript. */
    var subScript: MTMathList? {get set}
    /** An optional superscript. */
    var superScript: MTMathList? {get set}
    /** The nucleus of the atom. */
    var nucleus: String {get set}
    
    /// The index range in the MTMathList this MTMathAtom tracks. This is used by the finalizing and preprocessing steps
    /// which fuse MTMathAtoms to track the position of the current MTMathAtom in the original list.
    var indexRange:__NSRange {get set}/* = NSRange(location: 0, length: 0)*/ // indexRange in list that this atom tracks:
    
    /** The font style to be used for the atom. */
    var fontStyle: MTFontStyle {get set}
    
    /// If this atom was formed by fusion of multiple atoms, then this stores the list of atoms that were fused to create this one.
    /// This is used in the finalizing and preprocessing steps.
    var fusedAtoms:[any MT.MathAtom]{get set}
    
    var core:GenericMathAtom {get set}
    
    init()
    
    init(_ atom:(any MT.MathAtom)?)
        
    /// Factory function to create an atom with a given type and value.
    /// - parameter type: The type of the atom to instantiate.
    /// - parameter value: The value of the atoms nucleus. The value is ignored for fractions and radicals.
    init(type:MT.AtomType, value:String)
    
    var description: String {get}
    /// Returns a finalized copy of the atom
    var finalized: Self {get}
    var string:String {get}
    // Fuse the given atom with this one by combining their nucleii.
    mutating func fused(with atom: any MT.MathAtom)
    
    /** Returns true if this atom allows scripts (sub or super). */
    func isScriptAllowed() -> Bool/* { self.type.isScriptAllowed() }*/
    
    func isNotBinaryOperator() -> Bool /*{ self.type.isNotBinaryOperator() }*/
  }
  
  public struct GenericMathAtom: MT.MathAtom {
    public init() {
      type = .ordinary
      nucleus = ""
    }
    
    public var type: MT.AtomType
    public var nucleus:String
//    public init() {
//      self.type = .ordinary
//      self.nucleus = ""
//    }
    
    public var core: MT.GenericMathAtom {
      get {
        self
      }
      set {
        self = newValue
      }
    }
    
    //public let type: MT.AtomType
    public var subScript: MTMathList? {
      didSet {
        if subScript != nil && !self.isScriptAllowed() {
          subScript = nil
          NSException(name: NSExceptionName(rawValue: "Error"), reason: "Subscripts not allowed for atom of type \(self.type)").raise()
        }
      }
    }

    public var superScript: MTMathList? {
      didSet {
        if superScript != nil && !self.isScriptAllowed() {
          superScript = nil
          NSException(name: NSExceptionName(rawValue: "Error"), reason: "Superscripts not allowed for atom of type \(self.type)").raise()
        }
      }
    }
    
    /** The nucleus of the atom. */
    //public let nucleus: String
      
    public var indexRange = __NSRange(location: 0, length: 0) // indexRange in list that this atom tracks:
      
    /** The font style to be used for the atom. */
    public var fontStyle: MTFontStyle = .defaultStyle
      
    /// If this atom was formed by fusion of multiple atoms, then this stores the list of atoms that were fused to create this one.
    /// This is used in the finalizing and preprocessing steps.
    public var fusedAtoms = [any MT.MathAtom]()
      
    public init(_ atom:(any MT.MathAtom)?) {
      self.init()
      if let atom  {
        self.nucleus = atom.nucleus
        self.subScript = MTMathList(atom.subScript)
        self.superScript = MTMathList(atom.superScript)
        self.indexRange = atom.indexRange
        self.fontStyle = atom.fontStyle
        self.fusedAtoms = atom.fusedAtoms
      }
    }
      
      
    /// Factory function to create an atom with a given type and value.
    /// - parameter type: The type of the atom to instantiate.
    /// - parameter value: The value of the atoms nucleus. The value is ignored for fractions and radicals.
    public init(type:MT.AtomType = .ordinary, value:String = "") {
      self.type = type
      self.nucleus = type == .radical ? "" : value
    }
      
//      /// Returns a copy of `self`.
//      public func copy() -> MTMathAtom {
//          switch self.type {
//              case .largeOperator:
//                  return MTLargeOperator(self as? MTLargeOperator)
//              case .fraction:
//                  return MTFraction(self as? MTFraction)
//              case .radical:
//                  return MTRadical(self as? MTRadical)
//              case .style:
//                  return MTMathStyle(self as? MTMathStyle)
//              case .inner:
//                  return MTInner(self as? MTInner)
//              case .underline:
//                  return MTUnderLine(self as? MTUnderLine)
//              case .overline:
//                  return MTOverLine(self as? MTOverLine)
//              case .accent:
//                  return MTAccent(self as? MTAccent)
//              case .space:
//                  return MTMathSpace(self as? MTMathSpace)
//              case .color:
//                  return MTMathColor(self as? MTMathColor)
//              case .textcolor:
//                  return MTMathTextColor(self as? MTMathTextColor)
//              case .colorBox:
//                  return MTMathColorbox(self as? MTMathColorbox)
//              case .table:
//                  return MTMathTable(self as! MTMathTable)
//              default:
//                  return MTMathAtom(self)
//          }
//      }
      
    public var description: String {
      var string = ""
      string += self.nucleus
      if self.superScript != nil {
        string += "^{\(self.superScript!.description)}"
      }
      if self.subScript != nil {
        string += "_{\(self.subScript!.description)}"
      }
      return string
    }
      
    /// Returns a finalized copy of the atom
    public var finalized: MT.MathAtom {
      var finalized = self
      finalized.superScript = finalized.superScript?.finalized
      finalized.subScript = finalized.subScript?.finalized
      return finalized
    }
      
    public var string:String {
      var str = self.nucleus
      if let superScript = self.superScript {
        str.append("^{\(superScript.string)}")
      }
      if let subScript = self.subScript {
        str.append("_{\(subScript.string)}")
      }
      return str
    }
      
    // Fuse the given atom with this one by combining their nucleii.
    public mutating func fuse(with atom: any MT.MathAtom) {
      assert(self.subScript == nil, "Cannot fuse into an atom which has a subscript: \(self)");
      assert(self.superScript == nil, "Cannot fuse into an atom which has a superscript: \(self)");
      assert(atom.type == self.type, "Only atoms of the same type can be fused. \(self), \(atom)");
      guard self.subScript == nil, self.superScript == nil, self.type == atom.type
      else { print("Can't fuse these 2 atoms"); return }
      
      // Update the fused atoms list
      if self.fusedAtoms.isEmpty {
        self.fusedAtoms.append(self)
      }

      if atom.fusedAtoms.count > 0 {
        self.fusedAtoms.append(contentsOf: atom.fusedAtoms)
      } else {
        self.fusedAtoms.append(atom)
      }
      
      // Update nucleus:
      self.nucleus += atom.nucleus
      
      // Update range:
      self.indexRange.length += atom.indexRange.length
      
      // Update super/subscript:
      self.superScript = atom.superScript
      self.subScript = atom.subScript
    }
      
    /** Returns true if this atom allows scripts (sub or super). */
    public func isScriptAllowed() -> Bool { self.type.isScriptAllowed() }
      
    public func isNotBinaryOperator() -> Bool { self.type.isNotBinaryOperator() }
  }

  
//  public struct GenericMathAtom: MT.MathAtom {
//    
//    public let type = MT.AtomType.ordinary
//    public var nucleus: String = ""
//    public var indexRange = __NSRange(location: 0, length: 0)
//    public var fontStyle = MTFontStyle.defaultStyle
//    public var fusedAtoms = [any MT.MathAtom]()
//    
//    public var core:GenericMathAtom {
//      get {
//        self
//      }
//      set {
//        self = newValue
//      }
//    }
//    
//    public var subScript: MTMathList? {
//      didSet {
//        if subScript != nil && !self.isScriptAllowed() {
//          subScript = nil
//          NSException(name: NSExceptionName(rawValue: "Error"), reason: "Subscripts not allowed for atom of type \\(self.type)").raise()
//        }
//      }
//    }
//    
//    public var superScript: MTMathList? {
//      didSet {
//        if superScript != nil && !self.isScriptAllowed() {
//          superScript = nil
//          NSException(name: NSExceptionName(rawValue: "Error"), reason: "Superscripts not allowed for atom of type \\(self.type)").raise()
//        }
//      }
//    }
//      
//    public var finalized: any MT.MathAtom {
//      var finalized = self
//      finalized.superScript = finalized.superScript?.finalized
//      finalized.subScript = finalized.subScript?.finalized
//      return finalized
//    }
//  }

  public struct Fraction: MT.MathAtom {    

    public var hasRule: Bool = true
    public var leftDelimiter = ""
    public var rightDelimiter = ""
    public var numerator: MTMathList?
    public var denominator: MTMathList?
    public var core:GenericMathAtom = GenericMathAtom(type: .fraction)
      
    init(_ frac: MT.Fraction?) {
      self.core = GenericMathAtom(type: .fraction)
      if let frac = frac {
        self.numerator = MTMathList(frac.numerator)
        self.denominator = MTMathList(frac.denominator)
        self.hasRule = frac.hasRule
        self.leftDelimiter = frac.leftDelimiter
        self.rightDelimiter = frac.rightDelimiter
      }
    }
     
    public init() {
    }
    
    init(hasRule rule:Bool = true) {
      self.hasRule = rule
    }
      
    public var description: String {
      var string = self.hasRule ? "\\frac" : "\\atop"
      if !self.leftDelimiter.isEmpty {
        string += "[\(self.leftDelimiter)]"
      }
      if !self.rightDelimiter.isEmpty {
        string += "[\(self.rightDelimiter)]"
      }
      string += "{\(self.numerator?.description ?? "placeholder")}{\(self.denominator?.description ?? "placeholder")}"
      if self.superScript != nil {
        string += "^{\(self.superScript!.description)}"
      }
      if self.subScript != nil {
        string += "_{\(self.subScript!.description)}"
      }
      return string
    }
      
    public var finalized: MT.MathAtom {
      let _core = core.finalized as! MT.Fraction
      var ret = MT.Fraction(_core)
      ret.numerator = self.numerator?.finalized
      ret.denominator = self.denominator?.finalized
      return ret
    }
      
  }


//  public struct Fraction: MT.MathAtom {
//    
//    public let type = MT.AtomType.fraction
//    
//    public var hasRule: Bool = true
//    public var leftDelimiter = ""
//    public var rightDelimiter = ""
//    private let _numerator: MTMathList
//    private let _denominator: MTMathList
//    
//    public var core = GenericMathAtom()
//    
//    var numerator:MTMathList {
//      get {
//        return _numerator
//      }
//      set {
//        self = .init(numerator:newValue, denominator:_denominator, hasRule:hasRule)
//      }
//    }
//    
//    var denominator:MTMathList {
//      get {
//        return _denominator
//      }
//      set {
//        self = .init(numerator:_numerator, denominator:newValue, hasRule:hasRule)
//      }
//    }
//      
//    public init(){
//      self._numerator = MTMathList(atoms:[MTMathAtomFactory.placeholder()])
//      self._denominator = MTMathList(atoms:[MTMathAtomFactory.placeholder()])
//    }
//    
//    init(numerator:MTMathList?, denominator:MTMathList?, hasRule rule:Bool = true) {
//      self.init()
//      self.hasRule = rule
//      if let num = numerator {
//        self._numerator = num
//      }
//      if let denom = denominator {
//        self._denominator = denom
//      }
//    }
//      
//    public var description: String {
//      var string = self.hasRule ? "\\frac" : "\\atop"
//      if !self.leftDelimiter.isEmpty {
//        string += "[\(self.leftDelimiter)]"
//      }
//      if !self.rightDelimiter.isEmpty {
//        string += "[\(self.rightDelimiter)]"
//      }
//      string += "{\(self.numerator.description)}{\(self.denominator.description)}"
//      if let sup = self.superScript {
//        string += "^{\(sup.description)}"
//      }
//      if let sub = self.subScript {
//        string += "_{\(sub.description)}"
//      }
//      return string
//    }
//      
//    public var finalized: MT.Fraction {
//      var copy = core.finalized
//      copy.numerator = copy.numerator.finalized
//      copy.denominator = copy.denominator.finalized
//      return copy
//    }
//  }

  // MARK: - Inner
  /** An inner atom. This denotes an atom which contains a math list inside it. An inner atom
   has optional boundaries. Note: Only one boundary may be present, it is not required to have
   both. */
  public struct Inner: MT.MathAtom {
    public var core: GenericMathAtom
    
    public init() {
      self.core = GenericMathAtom(type:.inner)
    }
    
    private var _leftBoundary: MT.MathAtom?
    private var _rightBoundary: MT.MathAtom?
      /// The inner math list
    public var innerList: MTMathList?

    /// The left boundary atom. This must be a node of type kMT.MathAtomBoundary
    public var leftBoundary: MT.MathAtom? {
      didSet {
        if let left = _leftBoundary, left.type != .boundary {
          leftBoundary = nil
          NSException(name: NSExceptionName(rawValue: "Error"), reason: "Left boundary must be of type .boundary").raise()
        }
      }
    }
    
    /// The right boundary atom. This must be a node of type kMT.MathAtomBoundary
    public var rightBoundary: MT.MathAtom? {
      didSet {
        if let right = _rightBoundary, right.type != .boundary {
          rightBoundary = nil
          NSException(name: NSExceptionName(rawValue: "Error"), reason: "Right boundary must be of type .boundary").raise()
        }
      }
    }
      
    init(_ inner:MT.Inner? = nil) {
      self.core =  GenericMathAtom.init(inner)
      self.innerList = MTMathList(inner?.innerList)
      self.leftBoundary = MT.GenericMathAtom(inner?.leftBoundary)
      self.rightBoundary = MT.GenericMathAtom(inner?.rightBoundary)
    }
      
    public var description: String {
      var string = "\\inner"
      if let left = self.leftBoundary {
        string += "[\(left.nucleus)]"
      }
      string += "{\(self.innerList!.description)}"
      if let right = self.rightBoundary {
        string += "[\(right.nucleus)]"
      }
      if let sup = self.superScript {
        string += "^{\(sup.description)}"
      }
      if let sub = self.subScript {
        string += "_{\(sub.description)}"
      }
      return string
    }
      
    public var finalized: MT.Inner {
      var ret = self
      ret.innerList = ret.innerList?.finalized
      return ret
    }
  }

  // MARK: - OverLIne
  /** An atom with a line over the contained math list. */
  public struct OverLine: MT.MathAtom {

    public init() {
    }

    public var core = GenericMathAtom(type: .overline)
    public var innerList:  MTMathList?
    
    public var finalized: MT.OverLine {
      var newOverline = self
      newOverline.innerList = newOverline.innerList?.finalized
      return newOverline
    }
      
    init(_ over: MT.OverLine?) {
      self.innerList = MTMathList(over!.innerList)
    }
  }

  // MARK: - UnderLine
  /** An atom with a line under the contained math list. */
  public struct UnderLine: MT.MathAtom {
    
    public init() {
      self.core = GenericMathAtom(type: .underline)
    }

    public var core:GenericMathAtom

    public var innerList:  MTMathList?
    
    public var finalized: MT.MathAtom {
      var newUnderline = self
      newUnderline.innerList = newUnderline.innerList?.finalized
      return newUnderline
    }
      
    init(_ under: MT.UnderLine?) {
      self.init()
      self.innerList = MTMathList(under?.innerList)
    }
  }

  public struct Accent:MT.MathAtom {
    public var core = GenericMathAtom(type: .accent)
    public init(){}
    public let type: MT.AtomType = .accent
      
    public var innerList:  MTMathList?
      
    public var finalized: MT.MathAtom {
      var newAccent = self
      newAccent.innerList = newAccent.innerList?.finalized
      return newAccent
    }
      
    init(_ accent: MT.Accent?) {
      self.init()
      self.innerList = MTMathList(accent?.innerList)
    }
      
    init(value: String) {
      self.init()
      self.nucleus = value
    }
  }

  // MARK: - MathSpace
  /** An atom representing space.
   Note: None of the usual fields of the `MT.MathAtom` apply even though this
   class inherits from `MT.MathAtom`. i.e. it is meaningless to have a value
   in the nucleus, subscript or superscript fields. */
  public struct MathSpace: MT.MathAtom {
    public var core = GenericMathAtom(type: .space)

    public init() {
      
    }

    public var subScript: MTMathList?
          
    /** The amount of space represented by this object in mu units. */
    public var space: CGFloat = 0
    
    /// Creates a new `MT.MathSpace` with the given spacing.
    /// - parameter space: The amount of space in mu units.
        
    init(_ space: MathSpace? = nil) {
      self.space = space?.space ?? 0
    }
    
    init(space:CGFloat) {
      self.space = space
    }
  }

  // MARK: - MathStyle
  /** An atom representing a style change.
   Note: None of the usual fields of the `MT.MathAtom` apply even though this
   class inherits from `MT.MathAtom`. i.e. it is meaningless to have a value
   in the nucleus, subscript or superscript fields. */
  public struct MathStyle: MT.MathAtom {
    public var core = GenericMathAtom(type: .style)
    public var style:MTLineStyle = .display
    public init(){}
    init(_ style:MT.MathStyle?) {
      self.init()
      self.style = style!.style
    }
      
    init(style:MTLineStyle) {
      self.init()
      self.style = style
    }
  }

  // MARK: - MathColor
  /** An atom representing an color element.
   Note: None of the usual fields of the `MT.MathAtom` apply even though this
   class inherits from `MT.MathAtom`. i.e. it is meaningless to have a value
   in the nucleus, subscript or superscript fields. */
  public struct MathColor: MT.MathAtom {
    
    public var core = GenericMathAtom(type:.color)
    public var colorString:String = ""
    public var innerList:MTMathList?
    
    public init(){}
    
    init(_ color: MT.MathColor?) {
      self.colorString = color?.colorString ?? ""
      self.innerList = MTMathList(color?.innerList)
    }
          
    public var string: String {
      "\\color{\(self.colorString)}{\(self.innerList!.string)}"
    }
      
    public var finalized: MT.MathAtom {
      var newColor = self
      newColor.innerList = newColor.innerList?.finalized
      return newColor
    }
  }

  // MARK: - MathTextColor
  /** An atom representing an textcolor element.
   Note: None of the usual fields of the `MT.MathAtom` apply even though this
   class inherits from `MT.MathAtom`. i.e. it is meaningless to have a value
   in the nucleus, subscript or superscript fields. */
  public struct MathTextColor: MT.MathAtom {
    public var core = GenericMathAtom(type:.textcolor)
    public init(){}
    public var colorString:String=""
    public var innerList:MTMathList?

    init(_ color: MT.MathTextColor?) {
      self.colorString = color?.colorString ?? ""
      self.innerList = MTMathList(color?.innerList)
    }

    public var string: String {
      "\\textcolor{\(self.colorString)}{\(self.innerList!.string)}"
    }

    public var finalized: MT.MathAtom {
      var newColor = self
      newColor.innerList = newColor.innerList?.finalized
      return newColor
    }
  }

  // MARK: - MathColorbox
  /** An atom representing an colorbox element.
   Note: None of the usual fields of the `MT.MathAtom` apply even though this
   class inherits from `MT.MathAtom`. i.e. it is meaningless to have a value
   in the nucleus, subscript or superscript fields. */
  public struct MathColorbox: MT.MathAtom {
    public var core = GenericMathAtom(type:.colorBox)
    public var colorString=""
    public var innerList:MTMathList?
    public init(){}
    init(_ cbox: MT.MathColorbox?) {
      self.colorString = cbox?.colorString ?? ""
      self.innerList = MTMathList(cbox?.innerList)
    }

    public var string: String {
      "\\colorbox{\(self.colorString)}{\(self.innerList!.string)}"
    }
      
    public var finalized: MT.MathAtom {
      var newColor = self
      newColor.innerList = newColor.innerList?.finalized
      return newColor
    }
  }

  // MARK: - MTMathTable
  /** An atom representing an table element. This atom is not like other
   atoms and is not present in TeX. We use it to represent the `\halign` command
   in TeX with some simplifications. This is used for matrices, equation
   alignments and other uses of multiline environments.
   
   The cells in the table are represented as a two dimensional array of
   `MTMathList` objects. The `MTMathList`s could be empty to denote a missing
   value in the cell. Additionally an array of alignments indicates how each
   column will be aligned.
   */
  public struct MathTable: MT.MathAtom {
    public var core = GenericMathAtom(type:.table)
    /// The alignment for each column (left, right, center). The default alignment
    /// for a column (if not set) is center.
    public var alignments = [MTColumnAlignment]()
    /// The cells in the table as a two dimensional array.
    public var cells = [[MTMathList]]()
    /// The name of the environment that this table denotes.
    public var environment = ""
    /// Spacing between each column in mu units.
    public var interColumnSpacing: CGFloat = 0
    /// Additional spacing between rows in jots (one jot is 0.3 times font size).
    /// If the additional spacing is 0, then normal row spacing is used are used.
    public var interRowAdditionalSpacing: CGFloat = 0
    
    public var finalized: MT.MathTable {
      var ret = self
      ret.core = core.finalized
      for i in 0..<self.cells.count {
        for j in 0..<self.cells[i].count {
          ret.cells[i][j] = self.cells[i][j].finalized
        }
      }
      return ret
    }
    
    public init(){}
    
    init(environment: String? = nil) {
      self.core = GenericMathAtom(type:.table)
      self.environment = environment ?? ""
    }
      
    init(_ table:MT.MathTable) {
      self.core = GenericMathAtom(table)
      self.alignments = table.alignments
      self.interRowAdditionalSpacing = table.interRowAdditionalSpacing
      self.interColumnSpacing = table.interColumnSpacing
      self.environment = table.environment
      var cellCopy = [[MTMathList]]()
      for row in table.cells {
        var newRow = [MTMathList]()
        for col in row {
          newRow.append(MTMathList(col)!)
        }
        cellCopy.append(newRow)
      }
      self.cells = cellCopy
    }
            
      /// Set the value of a given cell. The table is automatically resized to contain this cell.
      mutating public func set(cell list: MTMathList, forRow row:Int, column:Int) {
          if self.cells.count <= row {
              for _ in self.cells.count...row {
                  self.cells.append([])
              }
          }
          let rows = self.cells[row].count
          if rows <= column {
              for _ in rows...column {
                  self.cells[row].append(MTMathList())
              }
          }
          self.cells[row][column] = list
      }
      
      /// Set the alignment of a particular column. The table is automatically resized to
      /// contain this column and any new columns added have their alignment set to center.
      public mutating func set(alignment: MTColumnAlignment, forColumn col: Int) {
          if self.alignments.count <= col {
              for _ in self.alignments.count...col {
                  self.alignments.append(MTColumnAlignment.center)
              }
          }
          
          self.alignments[col] = alignment
      }
      
      /// Gets the alignment for a given column. If the alignment is not specified it defaults
      /// to center.
      public func get(alignmentForColumn col: Int) -> MTColumnAlignment {
        if self.alignments.count <= col {
          return MTColumnAlignment.center
        } else {
          return self.alignments[col]
        }
      }
      
      public var numColumns: Int {
          var numberOfCols = 0
          for row in self.cells {
              numberOfCols = max(numberOfCols, row.count)
          }
          return numberOfCols
      }
      
      public var numRows: Int { self.cells.count }
  }

  // MARK: - MathTable
  /** An atom representing an table element. This atom is not like other
   atoms and is not present in TeX. We use it to represent the `\\halign` command
   in TeX with some simplifications. This is used for matrices, equation
   alignments and other uses of multiline environments.
   
   The cells in the table are represented as a two dimensional array of
   `MathList` objects. The `MathList`s could be empty to denote a missing
   value in the cell. Additionally an array of alignments indicates how each
   column will be aligned.
   */
//  public struct MathTable: MT.MathAtom {
//    public let type = .table
//
//    /// The alignment for each column (left, right, center). The default alignment
//    /// for a column (if not set) is center.
//    public var alignments = [MTColumnAlignment]()
//    /// The cells in the table as a two dimensional array.
//    public var cells = [[MTMathList]]()
//    /// The name of the environment that this table denotes.
//    public var environment = ""
//    /// Spacing between each column in mu units.
//    public var interColumnSpacing: CGFloat = 0
//    /// Additional spacing between rows in jots (one jot is 0.3 times font size).
//    /// If the additional spacing is 0, then normal row spacing is used are used.
//    public var interRowAdditionalSpacing: CGFloat = 0
//      
//    public var finalized: MT.MathAtom {
//      var table = self
//      for j in 0..<table.cells.count {
//        for i in 0..<table.cells[j].count {
//          table.cells[j][i] = table.cells[j][i].finalized
//        }
//      }
//      return table
//    }
//    
//    init(environment: String?) {
//      self.init()
//      self.environment = environment ?? ""
//    }
//      
//    init(_ table:MT.MathTable) {
//      self.init()
//      self.alignments = table.alignments
//      self.interRowAdditionalSpacing = table.interRowAdditionalSpacing
//      self.interColumnSpacing = table.interColumnSpacing
//      self.environment = table.environment
//      var cellCopy = [[MT.MathList]]()
//      for row in table.cells {
//        var newRow = [MT.MathList]()
//        for col in row {
//          newRow.append(MT.MathList(col)!)
//        }
//        cellCopy.append(newRow)
//      }
//      self.cells = cellCopy
//    }
//      
//      /// Set the value of a given cell. The table is automatically resized to contain this cell.
//    mutating public func set(cell list: MTMathList, forRow row:Int, column:Int) {
//      if self.cells.count <= row {
//        for _ in self.cells.count...row {
//          self.cells.append([])
//        }
//      }
//      let rows = self.cells[row].count
//      if rows <= column {
//        for _ in rows...column {
//          self.cells[row].append(MT.MathList())
//        }
//      }
//      self.cells[row][column] = list
//    }
//      
//    /// Set the alignment of a particular column. The table is automatically resized to
//    /// contain this column and any new columns added have their alignment set to center.
//    mutating public func set(alignment: MTColumnAlignment, forColumn col: Int) {
//      if self.alignments.count <= col {
//        for _ in self.alignments.count...col {
//          self.alignments.append(MTColumnAlignment.center)
//        }
//      }
//      
//      self.alignments[col] = alignment
//    }
//      
//    /// Gets the alignment for a given column. If the alignment is not specified it defaults
//    /// to center.
//    public func get(alignmentForColumn col: Int) -> MTColumnAlignment {
//      if self.alignments.count <= col {
//        return MTColumnAlignment.center
//      } else {
//        return self.alignments[col]
//      }
//    }
//      
//    public var numColumns: Int {
//      var numberOfCols = 0
//      for row in self.cells {
//        numberOfCols = max(numberOfCols, row.count)
//      }
//      return numberOfCols
//    }
//      
//    public var numRows: Int { self.cells.count }
//  }

  // MARK: - Radical
  /** An atom of type radical (square root). */
  public struct Radical:MT.MathAtom {

    public var core = GenericMathAtom(type:.radical)
    
    public init(){}
    /// Denotes the term under the square root sign
    public var radicand:  MTMathList?

      /// Denotes the degree of the radical, i.e. the value to the top left of the radical sign
      /// This can be null if there is no degree.
    public var degree:  MTMathList?
      
          
    public var description: String {
      var string = "\\sqrt"
      if self.degree != nil {
        string += "[\(self.degree!.description)]"
      }
      if self.radicand != nil {
        string += "{\(self.radicand?.description ?? "placeholder")}"
      }
      if let sup = self.superScript {
        string += "^{\(sup.description)}"
      }
      if let sub = self.subScript {
        string += "_{\(sub.description)}"
      }
      return string
    }
      
    public var finalized: MT.MathAtom {
      var ret = self
      ret.radicand = ret.radicand?.finalized
      ret.degree = ret.degree?.finalized
      return ret
    }
  }

  // MARK: - LargeOperator
  public struct LargeOperator:MT.MathAtom {

    public var core = GenericMathAtom(type:.largeOperator)
    public init(){}
    /** Indicates whether the limits (if present) should be displayed
     above and below the operator in display mode.  If limits is false
     then the limits (if present) are displayed like a regular subscript/superscript.
     */
    public var limits: Bool = false
    
    init(value: String, limits: Bool) {
      self.nucleus = value
      self.limits = limits
    }
  }

  @AddConformances(
"""
public struct CTLineDisplay {
    /// The CTLine being displayed
    public var line:CTLine!
    /// The attributed string used to generate the CTLineRef. Note setting this does not reset the dimensions of
    /// the display. So set only when
    var attributedString:FoundationEssentials.AttributedString? {
        didSet {
            line = CTLineCreateWithAttributedString(NSAttributedString(attributedString!))
        }
    }
    
    /// An array of MT.MathAtoms that this CTLine displays. Used for indexing back into the MTMathList
    public fileprivate(set) var atoms = [MT.MathAtom]()
    
    init(withString attrString:FoundationEssentials.AttributedString?, position:CGPoint, range:__NSRange, font:MTFont?, atoms:[MT.MathAtom]) {
        _position = position
        self.attributedString = attrString
        self.line = CTLineCreateWithAttributedString(NSAttributedString(attrString!))
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
        var newAttrStr = attributedString!            
        let range = newAttrStr.characters.startIndex..<newAttrStr.characters.endIndex
        newAttrStr[range].foregroundColor = self.textColor!.cgColor
        self.attributedString = newAttrStr
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
    public enum LinePosition : Int, Sendable {
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
    
    init(withDisplays displays:[any Display], range:__NSRange) {
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
    init(withGlpyh glyph:CGGlyph, range:__NSRange, font:MTFont?) {
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
    
    init(withNumerator numerator:MT.MathListDisplay?, denominator:MT.MathListDisplay?, position:CGPoint, range:__NSRange) {
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
    
    init(withRadicand radicand:MT.MathListDisplay?, glyph:any Display, position:CGPoint, range:__NSRange) {
        self.radicand = radicand
        _radicalGlyph = glyph
        _radicalShift = 0

        self.position = position
        self.range = range
    }

    mutating func setDegree(_ degree:MT.MathListDisplay?, fontMetrics:MTFont) {
        // sets up the degree of the radical
        var kernBefore = fontMetrics.radicalKernBeforeDegree
        let kernAfter = fontMetrics.radicalKernAfterDegree
        let raise = fontMetrics.radicalDegreeBottomRaisePercent * (self.ascent - self.descent);

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
  
  init(withInner inner:MT.MathListDisplay?, position:CGPoint, range:__NSRange) {
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
    
    init(withAccent glyph:GlyphDisplay?, accentee:MathListDisplay?, range:__NSRange) {
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
    var range:__NSRange{
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
  
  public enum AtomType: Int, CustomStringConvertible, Comparable, Sendable {
      /// A number or text in ordinary format - Ord in TeX
      case ordinary = 1
      /// A number - Does not exist in TeX
      case number
      /// A variable (i.e. text in italic format) - Does not exist in TeX
      case variable
      /// A large operator such as (sin/cos, integral etc.) - Op in TeX
      case largeOperator
      /// A binary operator - Bin in TeX
      case binaryOperator
      /// A unary operator - Does not exist in TeX.
      case unaryOperator
      /// A relation, e.g. = > < etc. - Rel in TeX
      case relation
      /// Open brackets - Open in TeX
      case open
      /// Close brackets - Close in TeX
      case close
      /// A fraction e.g 1/2 - generalized fraction node in TeX
      case fraction
      /// A radical operator e.g. sqrt(2)
      case radical
      /// Punctuation such as , - Punct in TeX
      case punctuation
      /// A placeholder square for future input. Does not exist in TeX
      case placeholder
      /// An inner atom, i.e. an embedded math list - Inner in TeX
      case inner
      /// An underlined atom - Under in TeX
      case underline
      /// An overlined atom - Over in TeX
      case overline
      /// An accented atom - Accent in TeX
      case accent
      
      // Atoms after this point do not support subscripts or superscripts
      
      /// A left atom - Left & Right in TeX. We don't need two since we track boundaries separately.
      case boundary = 101
      
      // Atoms after this are non-math TeX nodes that are still useful in math mode. They do not have
      // the usual structure.
      
      /// Spacing between math atoms. This denotes both glue and kern for TeX. We do not
      /// distinguish between glue and kern.
      case space = 201
      
      /// Denotes style changes during rendering.
      case style
      case color
      case textcolor
      case colorBox
      
      // Atoms after this point are not part of TeX and do not have the usual structure.
      
      /// An table atom. This atom does not exist in TeX. It is equivalent to the TeX command
      /// halign which is handled outside of the TeX math rendering engine. We bring it into our
      /// math typesetting to handle matrices and other tables.
      case table = 1001
      
      func isNotBinaryOperator() -> Bool {
          switch self {
              case .binaryOperator, .relation, .open, .punctuation, .largeOperator: return true
              default: return false
          }
      }
      
      func isScriptAllowed() -> Bool { self < .boundary }
      
      // we want string representations to be capitalized
      public var description: String {
          switch self {
              case .ordinary:       return "Ordinary"
              case .number:         return "Number"
              case .variable:       return "Variable"
              case .largeOperator:  return "Large Operator"
              case .binaryOperator: return "Binary Operator"
              case .unaryOperator:  return "Unary Operator"
              case .relation:       return "Relation"
              case .open:           return "Open"
              case .close:          return "Close"
              case .fraction:       return "Fraction"
              case .radical:        return "Radical"
              case .punctuation:    return "Punctuation"
              case .placeholder:    return "Placeholder"
              case .inner:          return "Inner"
              case .underline:      return "Underline"
              case .overline:       return "Overline"
              case .accent:         return "Accent"
              case .boundary:       return "Boundary"
              case .space:          return "Space"
              case .style:          return "Style"
              case .color:          return "Color"
              case .textcolor:      return "TextColor"
              case .colorBox:       return "Colorbox"
              case .table:          return "Table"
          }
      }
      
    // comparable support
    public static func < (lhs: AtomType, rhs: AtomType) -> Bool { lhs.rawValue < rhs.rawValue }
  }

}




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
