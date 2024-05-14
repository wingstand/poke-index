//
//  PokemonStatistic.swift
//  poke-index
//
//  Created by Gary Meehan on 10/05/2024.
//

import Foundation
import SwiftData

/// A statistic for a Pokémon, e.g., HP, attack, consisting of the kind of statistic and its value.
@Model final class PokemonStatistic {
  enum Kind: String, CaseIterable, Codable {
    case hp
    case attack
    case defense
    case specialAttack = "special-attack"
    case specialDefense = "special-defense"
    case speed
  }
  
  let kind: Kind = Kind.hp
  let value: Int = 0
  
  init(kind: Kind, value: Int) {
    self.kind = kind
    self.value = value
  }
}
