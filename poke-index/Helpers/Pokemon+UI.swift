//
//  Pokemon+UI.swift
//  poke-index
//
//  Created by Gary Meehan on 09/05/2024.
//

import Foundation

/// Helper methods for displaying Pokémon attributes in the UI
extension Pokemon {
  /// The name to use when displaying this Pokémon
  var displayName: String {
    return name.replacingOccurrences(of: "-", with: " ").capitalized
  }
    
  /// The weight measurement for this Pokémon.
  var weightMeasurement: Measurement<UnitMass> {
    // The weight is stored in hectograms, which even iOS doesn't support,
    // so translate it into kilograms manually.
    return Measurement(value: Double(weight) / 10.0, unit: UnitMass.kilograms)
  }
  
  /// The height measurement for this Pokémon.
  var heightMeasurement: Measurement<UnitLength> {
    Measurement(value: Double(height), unit: UnitLength.decimeters)
  }
  
  /// A string describing the weight of the Pokémon, using the local measuring system and medium units.
  var weightDescription: String {
    return Self.measurementFormatter.string(from: weightMeasurement)
  }
  
  /// A string describing the height of the Pokémon, using the local measuring system and medium units.
  var heightDescription: String {
    return Self.measurementFormatter.string(from: heightMeasurement)
  }
  
  /// A string describing the weight of the Pokémon, using the local measuring system and long units.
  var fullWeightDescription: String {
    return Self.fullMeasurementFormatter.string(from: weightMeasurement)
  }
  
  /// A string describing the height of the Pokémon, using the local measuring system and long units.
  var fullHeightDescription: String {
    return Self.fullMeasurementFormatter.string(from: heightMeasurement)
  }
  
  /// The standard formatter for measurements used by this Pokémon, with units in medium
  /// form (e.g., kg).
  private static var measurementFormatter: MeasurementFormatter = {
    let numberFormatter = NumberFormatter()
    
    numberFormatter.maximumFractionDigits = 1
    
    let formatter = MeasurementFormatter()
    
    formatter.unitStyle = .medium
    formatter.unitOptions = .naturalScale
    formatter.numberFormatter = numberFormatter
    
    return formatter
  }()
  
  /// The standard formatter for measurements used by this Pokémon, with units in long
  /// form (e.g., kilograms).
  private static var fullMeasurementFormatter: MeasurementFormatter = {
    let numberFormatter = NumberFormatter()
    
    numberFormatter.maximumFractionDigits = 1
    
    let formatter = MeasurementFormatter()
    
    formatter.unitStyle = .long
    formatter.unitOptions = .naturalScale
    formatter.numberFormatter = numberFormatter
    
    return formatter
  }()
}
