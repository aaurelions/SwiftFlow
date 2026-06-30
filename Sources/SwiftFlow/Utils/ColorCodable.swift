import SwiftUI

struct CodableColor: Codable, Equatable, Sendable, Hashable {
  var red: Double
  var green: Double
  var blue: Double
  var opacity: Double

  init(red: Double, green: Double, blue: Double, opacity: Double) {
    self.red = red
    self.green = green
    self.blue = blue
    self.opacity = opacity
  }

  init(_ color: Color) throws {
    #if canImport(UIKit)
      let platformColor = UIColor(color)
      var red: CGFloat = 0
      var green: CGFloat = 0
      var blue: CGFloat = 0
      var alpha: CGFloat = 0
      guard platformColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
        throw EncodingError.invalidValue(
          color,
          EncodingError.Context(
            codingPath: [],
            debugDescription:
              "Color cannot be represented as an RGBA value. Use an explicit RGB color for Codable styles."
          ))
      }
    #elseif canImport(AppKit)
      let platformColor = NSColor(color)
      guard let rgbColor = platformColor.usingColorSpace(.deviceRGB) else {
        throw EncodingError.invalidValue(
          color,
          EncodingError.Context(
            codingPath: [],
            debugDescription:
              "Color cannot be represented as an RGBA value. Use an explicit RGB color for Codable styles."
          ))
      }
      let red = rgbColor.redComponent
      let green = rgbColor.greenComponent
      let blue = rgbColor.blueComponent
      let alpha = rgbColor.alphaComponent
    #else
      throw EncodingError.invalidValue(
        color,
        EncodingError.Context(
          codingPath: [],
          debugDescription: "Codable Color styles require UIKit or AppKit."
        ))
    #endif

    self.init(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
  }

  var color: Color {
    Color(red: red, green: green, blue: blue, opacity: opacity)
  }
}
