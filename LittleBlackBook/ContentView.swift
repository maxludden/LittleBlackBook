//
//  ContentView.swift
//  LittleBlackBook
//
//  Created by Maxwell Ludden on 2/15/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ContactsView()
                    .navigationTitle("Contacts")
            }
            .tabItem {
                Label("Contacts", systemImage: "person.2")
            }

            NavigationStack {
                CalendarView()
                    .navigationTitle("Calendar")
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Contact.self, Event.self], inMemory: true)
}
