//
//  StatisticView.swift
//  poke-index
//
//  Created by Gary Meehan on 10/05/2024.
//

import SwiftUI

struct StatisticView: View {
  @State private var value: Int16 = 0
  @State private var timer = Timer.publish(every: 1 / 30, on: .main, in: .common).autoconnect()

  let statistic: Statistic
  
  var body: some View {
    VStack {
      HStack {
        Text(statistic.kind.description)
          .font(.body)
          .foregroundColor(.primary)
        
        Spacer()
        
        Text(value.description)
          .font(.body)
          .foregroundColor(.secondary)
      }
      
      ProgressView(value: Float(value) / 255.0)
        .progressViewStyle(.linear)
        .padding(.vertical, 0)
        .cornerRadius(4)
        .tint(Statistic.color(forValue: value))
    }
    .onReceive(timer) {
      input in
      
      value = min(statistic.baseValue, value + 3)

      if value == statistic.baseValue {
        self.timer.upstream.connect().cancel()
      }
    }
  }
  
  var maximumValue: Float {
    return Float(statistic.baseValue) / 255.0
  }
}

struct StatisticView_Previews: PreviewProvider {
  static var previews: some View {
    let persistence = PersistenceController.preview
    let pokemon = persistence.pokemon(forName: "clefairy")!
    let statistic: Statistic = pokemon.stats!.first(where: { _ in return true }) as! Statistic
    
    StatisticView(statistic: statistic)
  }
}
