//
//  PokemonType+UI.swift
//  poke-index
//
//  Created by Gary Meehan on 10/05/2024.
//

import SwiftUI

extension PokemonType: CustomStringConvertible {
  var description: String {
    switch self {
    case .normal:
      return "Normal"
    case .fire:
      return "Fire"
    case .water:
      return "Water"
    case .electric:
      return "Electric"
    case .grass:
      return "Grass"
    case .ice:
      return "Ice"
    case .fighting:
      return "Fighting"
    case .poison:
      return "Poison"
    case .ground:
      return "Ground"
    case .flying:
      return "Flying"
    case .psychic:
      return "Psychic"
    case .bug:
      return "Bug"
    case .rock:
      return "Rock"
    case .ghost:
      return "Ghost"
    case .dragon:
      return "Dragon"
    case .dark:
      return "Dark"
    case .steel:
      return "Steel"
    case .fairy:
      return "Fairy"
    }
  }
}

extension PokemonType {
  var color: Color {
    switch self {
    case .normal:
      return .gray
    case .fire:
      return .orange
    case .water:
      return .blue
    case .electric:
      return .yellow
    case .grass:
      return .green
    case .ice:
      return .cyan
    case .fighting:
      return .red
    case .poison:
      return .purple
    case .ground:
      return .brown
    case .flying:
      return .indigo
    case .psychic:
      return .pink
    case .bug:
      return .mint
    case .rock:
      return .gray
    case .ghost:
      return .indigo
    case .dragon:
      return .blue
    case .dark:
      return .orange
    case .steel:
      return .cyan
    case .fairy:
      return .pink
    }
  }
}
