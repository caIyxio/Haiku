import SwiftUI
import UIKit

enum HaikuTheme {
    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.53, green: 0.50, blue: 0.46, alpha: 1.0)
            : UIColor(red: 0.95, green: 0.93, blue: 0.89, alpha: 1.0)
    })

    static let surface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.60, green: 0.57, blue: 0.53, alpha: 1.0)
            : UIColor(red: 0.98, green: 0.97, blue: 0.94, alpha: 1.0)
    })

    static let foreground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.14, blue: 0.12, alpha: 1.0)
            : UIColor(red: 0.30, green: 0.25, blue: 0.20, alpha: 1.0)
    })

    static let secondary = foreground.opacity(0.62)
    static let accent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.27, green: 0.24, blue: 0.20, alpha: 1.0)
            : UIColor(red: 0.43, green: 0.34, blue: 0.26, alpha: 1.0)
    })
}
