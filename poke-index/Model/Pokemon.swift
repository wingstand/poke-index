//
//  Pokemon.swift
//  poke-index
//
//  Created by Gary Meehan on 14/05/2024.
//

import Foundation
import SwiftData

/// A Pokémon object, to be stored in a SwiftData container.
@Model final class Pokemon: ObservableObject {
  /// The name of this Pokémon, which must be unique.
  @Attribute(.unique) let name: String
  
  /// The URL from which the details of this Pokémon can be downloaded.
  let url: URL

  /// The number (ID) of this Pokémon.
  var number: Int = 0
  
  /// The weight of this Pokémon, in hectograms.
  var weight: Int = 0
  
  /// The height of this Pokémon, in decimetres.
  var height: Int = 0
  
  /// The base experience granted when this Pokémon is captured.
  var baseExperience: Int = 0
  
  /// The types of this Pokémon. Ths is expected to be limited to two elements.
  var types: [PokemonType] = []
  
  /// The statistics for this Pokémon, e.g., health points.
  var statistics: [PokemonStatistic] = []
  
  /// The URL from which to download the image for this Pokémon.
  var imageUrl: URL?
  
  /// The image data for this Pokémon.
  var imageData: Data?
  
  /// Constructs a new Pokémon object.
  /// - Parameter name: the name of the Pokémon.
  /// - Parameter url: the URL from which the details of the Pokémon can be accessed.
  init(name: String, url: URL) {
    self.name = name
    self.url = url
  }
  
  /// The total value of all statistics for this Pokémon.
  var totalStatistic: Int {
    return statistics.reduce(0, { $0 + $1.value })
  }
  
  /// Whether this Pokémon has been downloaded
  var hasBeenDownloaded: Bool {
    // If we've set the weight to a non-zero value, we must have pulled the data from the server.
    return weight != 0
  }
}

