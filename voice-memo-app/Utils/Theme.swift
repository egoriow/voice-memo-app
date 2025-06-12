import SwiftUI

enum Theme {
    static let accent = Color(red: 0.1, green: 0.6, blue: 0.8)
    static let gradient = LinearGradient(
        gradient: Gradient(colors: [Color(red: 0.1, green: 0.3, blue: 0.6), Color(red: 0.4, green: 0.8, blue: 0.9)]),
        startPoint: .top,
        endPoint: .bottom
    )
}
