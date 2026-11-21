import SwiftUI
import UIKit

enum HaikuTheme {
    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1.0)
            : UIColor(red: 0.96, green: 0.95, blue: 0.91, alpha: 1.0)
    })

    static let surface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.19, green: 0.19, blue: 0.19, alpha: 1.0)
            : UIColor(red: 0.99, green: 0.985, blue: 0.96, alpha: 1.0)
    })

    static let foreground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.91, green: 0.90, blue: 0.86, alpha: 1.0)
            : UIColor(red: 0.29, green: 0.25, blue: 0.20, alpha: 1.0)
    })

    static let secondary = foreground.opacity(0.62)
    static let accent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.79, green: 0.70, blue: 0.55, alpha: 1.0)
            : UIColor(red: 0.43, green: 0.34, blue: 0.26, alpha: 1.0)
    })
}
