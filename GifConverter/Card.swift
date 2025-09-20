//
//  Card.swift
//  GifConverter
//
//  Created by Rosales,Brian on 9/18/25.
//

import SwiftUI

// MARK: - Card

/// `ViewModifier` that wraps a view in a card
private struct CardViewModifier: ViewModifier {
    private let borderColor: Color
    private let cornerRadius: CGFloat
    private let shimmerColor: Color

    init(borderColor: Color, cornerRadius: CGFloat, shimmerColor: Color) {
        self.borderColor = borderColor
        self.cornerRadius = cornerRadius
        self.shimmerColor = shimmerColor
    }

    func body(content: Content) -> some View {
        content
            .clipShape(.rect(cornerRadius: cornerRadius, style: .circular))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .circular)
                    .strokeBorder()
                    .foregroundStyle(borderColor)
            }
    }
}

public extension View {
    /// Wraps the view in a card by giving it a border, loading shimmer, and rounded corners
    func card(
        borderColor: Color = .black,
        cornerRadius: CGFloat = 24,
        shimmerColor: Color = .gray
    ) -> some View {
        modifier(CardViewModifier(
            borderColor: borderColor,
            cornerRadius: cornerRadius,
            shimmerColor: shimmerColor
        ))
    }
}

// MARK: - Previews

#Preview(traits: .sizeThatFitsLayout) {
    ZStack {
        Color.blue
        Text("Test")
    }
    .frame(width: 200, height: 200)
    .card()
    .padding(20)
    .background(Color.red.opacity(0.5))
}
