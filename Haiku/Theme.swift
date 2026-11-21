import SwiftUI
import UIKit

enum HaikuTheme {
    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.58, green: 0.50, blue: 0.41, alpha: 1.0)
            : UIColor(red: 0.97, green: 0.94, blue: 0.88, alpha: 1.0)
    })

    static let surface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.65, green: 0.57, blue: 0.48, alpha: 1.0)
            : UIColor(red: 0.99, green: 0.97, blue: 0.93, alpha: 1.0)
    })

    static let foreground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.19, green: 0.15, blue: 0.11, alpha: 1.0)
            : UIColor(red: 0.30, green: 0.23, blue: 0.17, alpha: 1.0)
    })

    static let secondary = foreground.opacity(0.62)
    static let accent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.31, green: 0.24, blue: 0.17, alpha: 1.0)
            : UIColor(red: 0.43, green: 0.32, blue: 0.23, alpha: 1.0)
    })
}
