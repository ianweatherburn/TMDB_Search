//
//  SymbolEffects.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2026/03/01.
//

import SwiftUI

struct SymbolHoverModifier<E: IndefiniteSymbolEffect & SymbolEffect>: ViewModifier {
  let effect: E
  let options: SymbolEffectOptions
  
  @State private var isHovering = false
  
  func body(content: Content) -> some View {
    content
      .symbolEffect(effect, options: options, isActive: isHovering)
      .onHover { hovering in
        withAnimation(.spring(duration: 0.2)) {
          isHovering = hovering
        }
      }
  }
}

extension View {
  func hoverEffect<E: IndefiniteSymbolEffect & SymbolEffect>(
    _ effect: E = .scale.up,
    options: SymbolEffectOptions = .default
  ) -> some View {
    self.modifier(SymbolHoverModifier(effect: effect, options: options))
  }
}

