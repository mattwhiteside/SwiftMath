//
//  Created by Mike Griebling on 2022-12-31.
//  Translated from an Objective-C implementation by Kostub Deshmukh.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import Foundation
 

/**
 The font style of a character.

 The fontstyle of the atom determines what style the character is rendered in. This only applies to atoms
 of type kMT.MathAtomVariable and kMT.MathAtomNumber. None of the other atom types change their font style.
 */
public enum MTFontStyle:Int, Sendable {
    /// The default latex rendering style. i.e. variables are italic and numbers are roman.
    case defaultStyle = 0,
    /// Roman font style i.e. \mathrm
    roman,
    /// Bold font style i.e. \mathbf
    bold,
    /// Caligraphic font style i.e. \mathcal
    caligraphic,
    /// Typewriter (monospace) style i.e. \mathtt
    typewriter,
    /// Italic style i.e. \mathit
    italic,
    /// San-serif font i.e. \mathss
    sansSerif,
    /// Fractur font i.e \mathfrak
    fraktur,
    /// Blackboard font i.e. \mathbb
    blackboard,
    /// Bold italic
    boldItalic
}

// MARK: - MT.MathAtom

/** A `MT.MathAtom` is the basic unit of a math list. Each atom represents a single character
 or mathematical operator in a list. However certain atoms can represent more complex structures
 such as fractions and radicals. Each atom has a type which determines how the atom is rendered and
 a nucleus. The nucleus contains the character(s) that need to be rendered. However the nucleus may
 be empty for certain types of atoms. An atom has an optional subscript or superscript which represents
 the subscript or superscript that is to be rendered.
 
 Certain types of atoms inherit from `MT.MathAtom` and may have additional fields.
 */
extension MT.MathAtom {
  
  public init(_ atom:(any MT.MathAtom)?) {
    self.init()
    guard let atom = atom else { return }
    //self.nucleus = atom.nucleus
    self.subScript = MTMathList(atom.subScript)
    self.superScript = MTMathList(atom.superScript)
    self.indexRange = atom.indexRange
    self.fontStyle = atom.fontStyle
    self.fusedAtoms = atom.fusedAtoms
  }
  
  public var nucleus:String {
    get {
      return core.nucleus
    }
    set {
      if var _self = self as? MT.GenericMathAtom {
        _self.nucleus = newValue
      }
      else {
        core.nucleus = newValue
      }

    }
  }
  
  public var type:MT.AtomType {
    get {
      core.type
    }
    set {
      core.type = newValue
    }
  }
  
  public var subScript: MTMathList? {
    get{
      core.subScript
    }
    set {
      core.superScript = newValue
    }
  }
  
  public var superScript: MTMathList? {
    get {
      core.superScript
    }
    set {
      core.superScript = newValue
    }
  }
  
  public var indexRange: __NSRange {
    get {
      core.indexRange
    }
    set {
      core.indexRange = newValue
    }
  }
  
  public var fontStyle: MTFontStyle {
    get {
      core.fontStyle
    }
    set {
      core.fontStyle = newValue
    }
  }
  
  public var fusedAtoms: [any MT.MathAtom] {
    get {
      core.fusedAtoms
    }
    set {
      core.fusedAtoms = newValue
    }
  }

  /// Factory function to create an atom with a given type and value.
  /// - parameter type: The type of the atom to instantiate.
  /// - parameter value: The value of the atoms nucleus. The value is ignored for fractions and radicals.
  public init(type:MT.AtomType, value:String) {
    self.init()
    self.nucleus = type == .radical ? "" : value
  }
  
  /// Returns a copy of `self`.
//  public func copy() -> MTMathAtom {
//      switch self.type {
//          case .largeOperator:
//              return MTLargeOperator(self as? MTLargeOperator)
//          case .fraction:
//              return MT.Fraction(self as? MT.Fraction)
//          case .radical:
//              return MTRadical(self as? MTRadical)
//          case .style:
//              return MTMathStyle(self as? MTMathStyle)
//          case .inner:
//              return MTInner(self as? MTInner)
//          case .underline:
//              return MTUnderLine(self as? MTUnderLine)
//          case .overline:
//              return MTOverLine(self as? MTOverLine)
//          case .accent:
//              return MTAccent(self as? MTAccent)
//          case .space:
//              return MT.MathSpace(self as? MT.MathSpace)
//          case .color:
//              return MTMathColor(self as? MTMathColor)
//          case .textcolor:
//              return MTMathTextColor(self as? MTMathTextColor)
//          case .colorBox:
//              return MTMathColorbox(self as? MTMathColorbox)
//          case .table:
//              return MTMathTable(self as! MTMathTable)
//          default:
//              return MTMathAtom(self)
//      }
//  }
  
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
  public var finalized: Self {
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
  public mutating func fused(with atom: any MT.MathAtom) {
    
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

func isNotBinaryOperator(_ prevNode:MT.MathAtom?) -> Bool {
  guard let prevNode = prevNode else { return true }
  return prevNode.type.isNotBinaryOperator()
}


// MARK: - MTAccent



/**
 Styling of a line of math
 */
public enum MTLineStyle:Int, Comparable, Sendable {
    /// Display style
    case display
    /// Text style (inline)
    case text
    /// Script style (for sub/super scripts)
    case script
    /// Script script style (for scripts of scripts)
    case scriptOfScript
    
    public func inc() -> MTLineStyle {
        let raw = self.rawValue + 1
        if let style = MTLineStyle(rawValue: raw) { return style }
        return .display
    }
    
    public var isNotScript:Bool { self < .script }
    public static func < (lhs: MTLineStyle, rhs: MTLineStyle) -> Bool { lhs.rawValue < rhs.rawValue }
}



/**
    Alignment for a column of MTMathTable
 */
public enum MTColumnAlignment: Sendable {
    case left
    case center
    case right
}


// MARK: - MTMathList

extension MTMathList {
    public var description: String { self.atoms.description }
    /// converts the MTMathList to a string form. Note: This is not the LaTeX form.
    public var string: String { self.description }
}

extension NSRange {
  init(_ range:__NSRange) {
    self = NSMakeRange(range.location, range.length)
  }
}
/** A representation of a list of math objects.

    This list can be constructed directly or built with
    the help of the MTMathListBuilder. It is not required that the mathematics represented make sense
    (i.e. this can represent something like "x 2 = +". This list can be used for display using MTLine
    or can be a list of tokens to be used by a parser after finalizedMTMathList is called.
 
    Note: This class is for **advanced** usage only.
 */
public struct MTMathList: Sendable {
      
  init?(_ list:MTMathList?) {
    guard let list = list else {
      return nil
    }
    for atom in list.atoms {
      self.atoms.append(atom)
    }
  }

    /// A list of MathAtoms
    public var atoms = [MT.MathAtom]()
    
    /// Create a new math list as a final expression and update atoms
    /// by combining like atoms that occur together and converting unary operators to binary operators.
    /// This function does not modify the current MTMathList
    public var finalized: MTMathList {
        var finalizedList = MTMathList()
        let zeroRange = NSMakeRange(0, 0)
        
        var prevNode: MT.MathAtom? = nil
        for atom in self.atoms {
            var newNode = atom.finalized
            
            if NSEqualRanges(zeroRange, NSRange(atom.indexRange)) {
              let index = prevNode == nil ? 0 : prevNode!.indexRange.location + prevNode!.indexRange.length
              newNode.indexRange = __NSRange(location:index, length:1)
            }
            
            switch newNode.type {
            case .binaryOperator:
                if isNotBinaryOperator(prevNode)  {
                  fatalError()
                  //newNode.type = .unaryOperator
                }
            case .relation, .punctuation, .close:
                if prevNode != nil && prevNode!.type == .binaryOperator {
                  fatalError()
                  //prevNode!.type = .unaryOperator
                }
            case .number:
                if prevNode != nil && prevNode!.type == .number && prevNode!.subScript == nil && prevNode!.superScript == nil {
                  prevNode!.fused(with: newNode)
                  continue // skip the current node, we are done here.
                }
            default: break
            }
            finalizedList.add(newNode)
            prevNode = newNode
        }
        if prevNode != nil && prevNode!.type == .binaryOperator {
          fatalError()
          //prevNode!.type = .unaryOperator
        }
        return finalizedList
    }
    
    public init(atoms: [MT.MathAtom] = []) {
        self.atoms.append(contentsOf: atoms)
    }
    
    public init(atom: MT.MathAtom) {
        self.atoms.append(atom)
    }
        
    func NSParamException(_ param:Any?) {
        if param == nil {
            NSException(name: NSExceptionName(rawValue: "Error"), reason: "Parameter cannot be nil").raise()
        }
    }
    
    func NSIndexException(_ array:[Any], index: Int) {
        guard !array.indices.contains(index) else { return }
        NSException(name: NSExceptionName(rawValue: "Error"), reason: "Index \(index) out of bounds").raise()
    }
    
    /// Add an atom to the end of the list.
    /// - parameter atom: The atom to be inserted. This cannot be `nil` and cannot have the type `kMT.MathAtomBoundary`.
    /// - throws NSException if the atom is of type `kMT.MathAtomBoundary`
    public mutating func add(_ atom: MT.MathAtom?) {
        guard let atom = atom else { return }
        if self.isAtomAllowed(atom) {
            self.atoms.append(atom)
        } else {
            NSException(name: NSExceptionName(rawValue: "Error"), reason: "Cannot add atom of type \(atom.type.rawValue) into mathlist").raise()
        }
    }
    
    /// Inserts an atom at the given index. If index is already occupied, the objects at index and beyond are
    /// shifted by adding 1 to their indices to make room. An insert to an `index` greater than the number of atoms
    /// is ignored.  Insertions of nil atoms is ignored.
    /// - parameter atom: The atom to be inserted. This cannot be `nil` and cannot have the type `kMT.MathAtom.boundary`.
    /// - parameter index: The index where the atom is to be inserted. The index should be less than or equal to the
    ///  number of elements in the math list.
    /// - throws NSException if the atom is of type kMT.MathAtomBoundary
    public mutating func insert(_ atom: MT.MathAtom?, at index: Int) {
        // NSParamException(atom)
        guard let atom = atom else { return }
        guard self.atoms.indices.contains(index) || index == self.atoms.endIndex else { return }
        // guard self.atoms.endIndex >= index else { NSIndexException(); return }
        if self.isAtomAllowed(atom) {
            // NSIndexException(self.atoms, index: index)
            self.atoms.insert(atom, at: index)
        } else {
            NSException(name: NSExceptionName(rawValue: "Error"), reason: "Cannot add atom of type \(atom.type.rawValue) into mathlist").raise()
        }
    }
    
    /// Append the given list to the end of the current list.
    /// - parameter list: The list to append.
    public mutating func append(_ list: MTMathList?) {
        guard let list = list else { return }
        self.atoms += list.atoms
    }
    
    /** Removes the last atom from the math list. If there are no atoms in the list this does nothing. */
    public mutating func removeLastAtom() {
        if !self.atoms.isEmpty {
            self.atoms.removeLast()
        }
    }
    
    /// Removes the atom at the given index.
    /// - parameter index: The index at which to remove the atom. Must be less than the number of atoms
    /// in the list.
    public mutating func removeAtom(at index: Int) {
        NSIndexException(self.atoms, index:index)
        self.atoms.remove(at: index)
    }
    
    /** Removes all the atoms within the given range. */
    public mutating func removeAtoms(in range: ClosedRange<Int>) {
        NSIndexException(self.atoms, index: range.lowerBound)
        NSIndexException(self.atoms, index: range.upperBound)
        self.atoms.removeSubrange(range)
    }
    
    func isAtomAllowed(_ atom: MT.MathAtom?) -> Bool { atom?.type != .boundary }
}
