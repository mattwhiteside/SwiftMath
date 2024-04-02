
//
//  Created by Mike Griebling on 2022-12-31.
//  Translated from an Objective-C implementation by Markus Sähn.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

extension MTColor {
    
    public convenience init?(fromHexString hexString:String) {
      if hexString.isEmpty { return nil }
      if !hexString.hasPrefix("#") { return nil }
      guard let rgbValue = UInt64(hexString.replacingOccurrences(of: "#", with: "")) else {
        return nil
      }
      self.init(red: Float64((rgbValue & 0xFF0000) >> 16)/255.0,
                green: Float64((rgbValue & 0xFF00) >> 8)/255.0,
                blue: Float64((rgbValue & 0xFF))/255.0,
                alpha: 1.0)
    }
    
}
