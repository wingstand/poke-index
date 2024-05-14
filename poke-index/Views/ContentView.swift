//
//  ContentView.swift
//  poke-index
//
//  Created by Gary Meehan on 09/05/2024.
//

import SwiftUI
import SwiftData

/// The main content view.
struct ContentView: View {
  @Environment(\.modelContext) private var modelContext

  /// The controller used for downloading data from the server. Defaults to shared
  /// but previews have their own in-memory versions
  var controller: DataController = .shared
 
  /// Whether the Pokémon are automatically downloaded. We don't want
  /// to do this if we're previewing
  var shouldAutomaticallyDownloadAllPokemon = true
  
  /// The search text used to filter the Pokémon we're displaying. This can either be part
  /// of  a name (case-insensitive), or an exact number.
  @State private var searchText = ""
  
  /// The visibility of the columns of our split view. By default, we show all (well, both.
  @State private var columnVisibility = NavigationSplitViewVisibility.all

  @State private var filteredPokemon: [Pokemon] = []
  
  /// The body of this view.
  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      PokemonListView(searchText: searchText)
      .toolbar {
        ToolbarItem {
          Button(action: refreshAllPokemon) {
            Image(systemName: "arrow.clockwise")
          }
          .accessibilityElement()
          .accessibilityLabel(Text("Refresh all Pokémon."))
        }
      }
    } detail: {
      Text("No Pokémon")
        .font(.largeTitle)
        .foregroundColor(.secondary)
    }
    .navigationSplitViewStyle(.balanced)
    .searchable(text: $searchText, placement: .automatic, prompt: "Name or Number")
    .onAppear {
      initializeAllPokemon()
    }
  }
  
  /// Downloads any remaining Pokémon that we haven't already done so. This is _not_
  /// done if we're previewing.
  private func initializeAllPokemon() {
    if shouldAutomaticallyDownloadAllPokemon {
      controller.downloadAllPokemon()
    }
  }
  
  /// Deletes all Pokémon in the store and starts downloading them again.
  @MainActor private func refreshAllPokemon() {
    controller.deleteAllPokemon()
    controller.downloadAllPokemon()
  }
}

// MARK: - previews

#Preview {
  let controller = DataController.preview
  
  return ContentView(controller: controller, shouldAutomaticallyDownloadAllPokemon: false)
    .modelContainer(controller.container)
}

