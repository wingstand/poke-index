//
//  Pokemon.swift
//  poke-index
//
//  Created by Gary Meehan on 14/05/2024.
//

import Foundation
import SwiftData

@Model
final class Pokemon: ObservableObject {
  @Attribute(.unique) let name: String
  let url: URL

  var number: Int = 0
  var weight: Int = 0
  var height: Int = 0
  var baseExperience: Int = 0
  var types: [PokemonType] = []
  var statistics: [PokemonStatistic] = []
  var order: Int = 0
  var imageUrl: URL?
  var imageData: Data?
  
  init(name: String, url: URL) {
    self.name = name
    self.url = url
  }
  
  /// The total value of all statistics for this Pokémon.
  var totalStatistic: Int {
    return statistics.reduce(0, { $0 + $1.value })
  }
}

