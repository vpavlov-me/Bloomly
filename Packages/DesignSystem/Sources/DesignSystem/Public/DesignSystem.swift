//
//  DesignSystem.swift
//  BabyTrack
//
//  Defines shared styles, typography, and spacing tokens for the app UI.
//

import SwiftUI

public enum BabyTrackSpacing: CGFloat, CaseIterable {
    case xSmall = 4
    case small = 8
    case medium = 12
    case regular = 16
    case large = 24
    case xLarge = 32
}

public struct BabyTrackCornerRadius {
    public static let regular: CGFloat = 12
    public static let pill: CGFloat = 22
    private init() {}
}

public enum BabyTrackFont {
    public static func heading(_ size: CGFloat) -> Font {
        Font.system(size: size, weight: .semibold, design: .rounded)
    }

    public static func body(_ size: CGFloat) -> Font {
        Font.system(size: size, weight: .regular, design: .rounded)
    }

    private init() {}
}
