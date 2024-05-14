//
//  PokemonType+Kind.swift
//  poke-index
//
//  Created by Gary Meehan on 10/05/2024.
//

import Foundation

/// A type of a Pokémon. A Pokémon can have multiple types.
enum PokemonType: String, CaseIterable, Codable {
  case normal
  case fire
  case water
  case electric
  case grass
  case ice
  case fighting
  case poison
  case ground
  case flying
  case psychic
  case bug
  case rock
  case ghost
  case dragon
  case dark
  case steel
  case fairy
}
