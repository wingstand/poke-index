//
//  Pokemon+UI.swift
//  poke-index
//
//  Created by Gary Meehan on 09/05/2024.
//

import Foundation

/// Helper methods for displaying Pokémon attributes in the UI
extension Pokemon {
  /// A string describing the weight of the Pokémon, using the local measuring system.
  var weightDescription: String {
    // The weight is stored in hectograms, which even iOS doesn't support,
    // so translate it into kilograms.
    let measurement = Measurement(value: Double(weight) / 10.0, unit: UnitMass.kilograms)
    
    return Self.measurementFormatter.string(from: measurement)
  }
  
  /// A string describing the height of the Pokémon, using the local measuring system.
  var heightDescription: String {
    let measurement = Measurement(value: Double(height), unit: UnitLength.decimeters)
    
    return Self.measurementFormatter.string(from: measurement)
  }
  
  /// Whether this Pokémon has been downloaded
  var hasBeenDownloaded: Bool {
    // If we've set the order to a non-zero value, we must have pulled the data from the server.
    return order != 0
  }
  
  private static var measurementFormatter: MeasurementFormatter = {
    let numberFormatter = NumberFormatter()
    
    numberFormatter.maximumFractionDigits = 1
    
    let formatter = MeasurementFormatter()
    
    formatter.unitStyle = .medium
    formatter.unitOptions = .naturalScale
    formatter.numberFormatter = numberFormatter
    
    return formatter
  }()
}
