//
//  Extensions.swift
//  itelo
//
//  Created for shared view modifiers.
//

import SwiftUI

extension View {
    /// Applies a glass effect background with the specified material and shape.
    func glassEffect(_ style: Material, in shape: some Shape) -> some View {
        self.background(style, in: shape)
    }
}
