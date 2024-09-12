
//
//  Created by Mike Griebling on 2022-12-31.
//  Translated from an Objective-C implementation by Kostub Deshmukh.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import Foundation

public final class MTFontManager:Sendable {
    
    static public let manager: MTFontManager = {
        MTFontManager()
    }()
    
    let kDefaultFontSize = CGFloat(20)
    
    static var fontManager : MTFontManager {
        return manager
    }

    let nameToFontMap: [String: MTFont]

    private init() {
      do {
        let size = kDefaultFontSize
        var _nameToFontMap = [String: MTFont]()
        func _font(withName name:String, size:CGFloat) throws -> MTFont? {
          var f = _nameToFontMap[name]
          if f == nil {
            f = try MTFont(name: name, size: size)
            _nameToFontMap[name] = f
          }
            
          if f!.fontSize == size { return f }
          else { return try f!.copy(withSize: size) }
        }

        let _ = try _font(withName: "latinmodern-math", size: size)
        let _ = try _font(withName: "KpMath-Light", size: size)
        let _ = try _font(withName: "KpMath-Sans", size: size)
        let _ = try _font(withName: "xits-math", size: size)
        let _ = try _font(withName: "texgyretermes-math", size: size)
        nameToFontMap = _nameToFontMap
      }
      catch let anyError
      {
        fatalError("Error: \(anyError)")
      }
    }
    
  internal func font(withName name:String, size:CGFloat) throws -> MTFont? {
    guard let f = nameToFontMap[name] else {
      fatalError()
    }
    if f.fontSize == size { return f }
    return try f.copy(withSize: size)
  }
    
  public func latinModernFont(withSize size:CGFloat) throws -> MTFont? {
    try MTFontManager.fontManager.font(withName: "latinmodern-math", size: size)
  }
  
  public func kpMathLightFont(withSize size:CGFloat) throws -> MTFont? {
    try MTFontManager.fontManager.font(withName: "KpMath-Light", size: size)
  }
  
  public func kpMathSansFont(withSize size:CGFloat) throws -> MTFont? {
    try MTFontManager.fontManager.font(withName: "KpMath-Sans", size: size)
  }
  
  public func xitsFont(withSize size:CGFloat) throws -> MTFont? {
    try MTFontManager.fontManager.font(withName: "xits-math", size: size)
  }
  
  public func termesFont(withSize size:CGFloat) throws -> MTFont? {
    try MTFontManager.fontManager.font(withName: "texgyretermes-math", size: size)
  }
  
    public var defaultFont: MTFont? {
      do {
        return try MTFontManager.fontManager.latinModernFont(withSize: kDefaultFontSize)
      }
      catch let anyError {
        print("No default font found: \(anyError)")
        return nil
      }
    }


}
