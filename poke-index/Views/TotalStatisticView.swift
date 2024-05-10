//
//  TotalStatisticView.swift
//  poke-index
//
//  Created by Gary Meehan on 10/05/2024.
//

import SwiftUI

struct TotalStatisticView: View {
  @State private var value: Int = 0
  @State private var timer = Timer.publish(every: 1 / 30, on: .main, in: .common).autoconnect()

  let total: Int
  
  var body: some View {
    HStack {
      Text("Total")
        .font(.headline)
        .foregroundColor(.primary)
      
      Spacer()
      
      Text(value.description)
        .font(.body)
        .foregroundColor(.primary)
    }
    .onReceive(timer) {
      input in
      
      value = min(total, value + 10)

      if value == total {
        self.timer.upstream.connect().cancel()
      }
    }
  }
}

struct TotalStatisticView_Previews: PreviewProvider {
  static var previews: some View {
    TotalStatisticView(total: 300)
  }
}
