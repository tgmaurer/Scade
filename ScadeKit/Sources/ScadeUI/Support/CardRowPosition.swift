import SwiftUI

/// Where a row sits inside its card.
///
/// A card is one shape made of several rows, so only its outermost corners
/// round. Rounding every row turns one card into a stack of pills with
/// notches between them.
enum CardRowPosition {
    case only
    case first
    case middle
    case last

    init(index: Int, count: Int) {
        if count <= 1 {
            self = .only
        } else if index == 0 {
            self = .first
        } else if index == count - 1 {
            self = .last
        } else {
            self = .middle
        }
    }

    var topRadius: Double {
        switch self {
        case .only, .first: ScadeDesign.cardCornerRadius
        case .middle, .last: 0
        }
    }

    var bottomRadius: Double {
        switch self {
        case .only, .last: ScadeDesign.cardCornerRadius
        case .first, .middle: 0
        }
    }

    /// Whether a separator belongs *under* this row: only where another row
    /// follows it inside the same card.
    var hasRowBelow: Bool {
        switch self {
        case .first, .middle: true
        case .only, .last: false
        }
    }
}
