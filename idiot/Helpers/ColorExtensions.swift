import SwiftUI

extension Color {
    init(hex: String) {
        let sanitizedHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var integer: UInt64 = 0
        Scanner(string: sanitizedHex).scanHexInt64(&integer)

        let red = Double((integer >> 16) & 0xFF) / 255
        let green = Double((integer >> 8) & 0xFF) / 255
        let blue = Double(integer & 0xFF) / 255

        self.init(red: red, green: green, blue: blue)
    }

    static let categoryBlue = Color(hex: "#4F8EF7")
    static let categoryGreen = Color(hex: "#34C759")
    static let categoryOrange = Color(hex: "#FF9500")
    static let categoryRed = Color(hex: "#FF3B30")
    static let categoryPurple = Color(hex: "#AF52DE")
    static let categoryYellow = Color(hex: "#FFCC00")
    static let categoryPink = Color(hex: "#FF2D55")
    static let categoryTeal = Color(hex: "#5AC8FA")
}
