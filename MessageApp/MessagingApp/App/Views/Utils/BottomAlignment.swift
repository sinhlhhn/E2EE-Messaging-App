//
//  BottomAlignment.swift
//  MessagingApp
//
//  Created by Sam on 20/5/25.
//

import SwiftUI

private struct BottomAlignment: AlignmentID {
    static func defaultValue(in d: ViewDimensions) -> CGFloat {
        // fallback if no explicit alignment
        d[.bottom]
    }
}

extension VerticalAlignment {
    static let bottomAligned = VerticalAlignment(BottomAlignment.self)
}
