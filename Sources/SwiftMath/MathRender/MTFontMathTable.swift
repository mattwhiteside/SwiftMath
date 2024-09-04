//
//  Created by Mike Griebling on 2022-12-31.
//  Translated from an Objective-C implementation by Kostub Deshmukh.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import FoundationEssentials
import CoreText

struct Error: LocalizedError {
  let description: String

  init(_ description: String) {
    self.description = description
  }

  var errorDescription: String? {
    description
  }
}

struct GlyphPart {
  /// The glyph that represents this part
  var glyph: CGGlyph!

  /// Full advance width/height for this part, in the direction of the extension in points.
  var fullAdvance: CGFloat = 0

  /// Advance width/ height of the straight bar connector material at the beginning of the glyph in points.
  var startConnectorLength: CGFloat = 0

  /// Advance width/ height of the straight bar connector material at the end of the glyph in points.
  var endConnectorLength: CGFloat = 0

  /// If this part is an extender. If set, the part can be skipped or repeated.
  var isExtender: Bool = false
}


