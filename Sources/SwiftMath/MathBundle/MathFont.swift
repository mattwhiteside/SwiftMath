//
//  File.swift
//  
//
//  Created by Peter Tang on 10/9/2023.
//

#if os(iOS)
import UIKit
#endif

#if os(macOS)
import AppKit
#endif

public enum MathFont: String, CaseIterable {
    
    case latinModernFont = "latinmodern-math"
    case kpMathLightFont = "KpMath-Light"
    case kpMathSansFont  = "KpMath-Sans"
    case xitsFont        = "xits-math"
    case termesFont      = "texgyretermes-math"
    
    var fontFamilyName: String {
        switch self {
        case .latinModernFont: return "Latin Modern Math"
        case .kpMathLightFont: return "KpMath"
        case .kpMathSansFont:  return "KpMath"
        case .xitsFont:        return "XITS Math"
        case .termesFont:      return "TeX Gyre Termes Math"
        }
    }
    var fontName: String {
        switch self {
        case .latinModernFont: return "LatinModernMath-Regular"
        case .kpMathLightFont: return "KpMath-Light"
        case .kpMathSansFont:  return "KpMath-Sans"
        case .xitsFont:        return "XITSMath"
        case .termesFont:      return "TeXGyreTermesMath-Regular"
        }
    }
    public func cgFont() -> CGFont? {
        BundleManager.manager.obtainCGFont(font: self)
    }
    public func ctFont(withSize size: CGFloat) -> CTFont? {
        BundleManager.manager.obtainCTFont(font: self, withSize: size)
    }
    #if os(iOS)
    public func uiFont(withSize size: CGFloat) -> UIFont? {
        UIFont(name: fontName, size: size)
    }
    #endif
    #if os(macOS)
    public func nsFont(withSize size: CGFloat) -> NSFont? {
        NSFont(name: fontName, size: size)
    }
    #endif
    internal func mathTable() -> NSDictionary? {
        BundleManager.manager.obtainMathTable(font: self)
    }
    internal func get(nameForGlyph glyph: CGGlyph) -> String {
        let name = cgFont()?.name(for: glyph) as? String
        return name ?? ""
    }
    internal func get(glyphWithName name: String) -> CGGlyph? {
        cgFont()?.getGlyphWithGlyphName(name: name as CFString)
    }
}
internal extension CTFont {
    /** The size of this font in points. */
    var fontSize: CGFloat {
        CTFontGetSize(self)
    }
    var unitsPerEm: UInt {
        return UInt(CTFontGetUnitsPerEm(self))
    }
}
private class BundleManager {
    static fileprivate(set) var manager: BundleManager = {
        return BundleManager()
    }()

    private var cgFonts = [MathFont: CGFont]()
    private var ctFonts = [CTFontPair: CTFont]()
    private var mathTables = [MathFont: NSDictionary]()

    private var initializedOnceAlready: Bool = false
    
    private func registerCGFont(mathFont: MathFont) throws {
        guard let frameworkBundleURL = Bundle.module.url(forResource: "mathFonts", withExtension: "bundle"),
              let resourceBundleURL = Bundle(url: frameworkBundleURL)?.path(forResource: mathFont.rawValue, ofType: "otf") else {
            throw FontError.fontPathNotFound
        }
        guard let fontData = NSData(contentsOfFile: resourceBundleURL), let dataProvider = CGDataProvider(data: fontData) else {
            throw FontError.invalidFontFile
        }
        guard let defaultCGFont = CGFont(dataProvider) else {
            throw FontError.initFontError
        }
        
        cgFonts[mathFont] = defaultCGFont
        
        var errorRef: Unmanaged<CFError>? = nil
        guard CTFontManagerRegisterGraphicsFont(defaultCGFont, &errorRef) else {
            throw FontError.registerFailed
        }
        print("mathFonts bundle resource: \(mathFont.rawValue), font: \(defaultCGFont.fullName) registered.")
    }
    
    private func registerMathTable(mathFont: MathFont) throws {
        guard let frameworkBundleURL = Bundle.module.url(forResource: "mathFonts", withExtension: "bundle"),
              let mathTablePlist = Bundle(url: frameworkBundleURL)?.url(forResource: mathFont.rawValue, withExtension:"plist") else {
            throw FontError.fontPathNotFound
        }
        guard let rawMathTable = NSDictionary(contentsOf: mathTablePlist),
                let version = rawMathTable["version"] as? String,
                version == "1.3" else {
            throw FontError.invalidMathTable
        }
        //FIXME: mathTable = MTFontMathTable(withFont:self, mathTable:rawMathTable)
        mathTables[mathFont] = rawMathTable
        print("mathFonts bundle resource: \(mathFont.rawValue).plist registered.")
    }
    
    private func registerAllBundleResources() {
        guard !initializedOnceAlready else { return }
        MathFont.allCases.forEach { font in
            do {
                try BundleManager.manager.registerCGFont(mathFont: font)
                try BundleManager.manager.registerMathTable(mathFont: font)
            } catch {
                fatalError("MTMathFonts:\(#function) Couldn't load mathFont resource \(font.rawValue), reason \(error)")
            }
        }
        initializedOnceAlready.toggle()
    }
    
    fileprivate func obtainCGFont(font: MathFont) -> CGFont? {
        if !initializedOnceAlready { registerAllBundleResources() }
        return cgFonts[font]
    }
    
    fileprivate func obtainCTFont(font: MathFont, withSize size: CGFloat) -> CTFont? {
        if !initializedOnceAlready { registerAllBundleResources() }
        let fontPair = CTFontPair(font: font, size: size)
        guard let ctFont = ctFonts[fontPair] else {
            if let cgFont = cgFonts[font] {
                let ctFont = CTFontCreateWithGraphicsFont(cgFont, size, nil, nil)
                ctFonts[fontPair] = ctFont
                return ctFont
            }
            return nil
        }
        return ctFont
    }
    fileprivate func obtainMathTable(font: MathFont) -> NSDictionary? {
        if !initializedOnceAlready { registerAllBundleResources() }
        return mathTables[font]
    }
    deinit {
        ctFonts.removeAll()
        var errorRef: Unmanaged<CFError>? = nil
        cgFonts.values.forEach { cgFont in
            CTFontManagerUnregisterGraphicsFont(cgFont, &errorRef)
        }
        cgFonts.removeAll()
    }
    public enum FontError: Error {
        case invalidFontFile
        case fontPathNotFound
        case initFontError
        case registerFailed
        case invalidMathTable
    }
    
    private struct CTFontPair: Hashable {
        let font: MathFont
        let size: CGFloat
    }
}
