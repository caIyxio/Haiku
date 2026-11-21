import SwiftUI
import UIKit

enum HaikuTheme {
    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.34, green: 0.27, blue: 0.21, alpha: 1.0)
            : UIColor(red: 0.97, green: 0.94, blue: 0.88, alpha: 1.0)
    })

    static let surface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.40, green: 0.32, blue: 0.25, alpha: 1.0)
            : UIColor(red: 0.99, green: 0.97, blue: 0.93, alpha: 1.0)
    })

    static let foreground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.96, green: 0.91, blue: 0.84, alpha: 1.0)
            : UIColor(red: 0.30, green: 0.23, blue: 0.17, alpha: 1.0)
    })

    static let secondary = foreground.opacity(0.62)
    static let accent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.82, green: 0.70, blue: 0.55, alpha: 1.0)
            : UIColor(red: 0.43, green: 0.32, blue: 0.23, alpha: 1.0)
    })
}
