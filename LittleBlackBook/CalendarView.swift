import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Event.startDate, order: .forward)]) private var events: [Event]
    @Query(sort: [SortDescriptor(\Contact.givenName, order: .forward), SortDescriptor(\Contact.familyName, order: .forward)]) private var contacts: [Contact]

    var body: some View {
        NavigationStack {
            List(events) { event in
                VStack(alignment: .leading) {
                    Text(event.title).font(.headline)
                    Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !event.contacts.isEmpty {
                        Text("Contacts: " + event.contacts.map { (contact) in
                            let given = contact.givenName ?? ""
                            let family = contact.familyName ?? ""
                            let full = [given, family].filter { !$0.isEmpty }.joined(separator: " ")
                            return full
                        }.filter { !$0.isEmpty }.joined(separator: ", "))
                            .font(.subheadline)
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        if let idx = events.firstIndex(of: event) {
                            delete(at: IndexSet(integer: idx))
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add") { addSampleEvent() }
                }
            }
        }
    }

    private func addSampleEvent() {
        var associated: [Contact] = []
        if let first = contacts.first { associated = [first] }
        let event = Event(title: "Hookup", notes: "Discuss roadmap", startDate: Date.now.addingTimeInterval(3600), contacts: associated)
        context.insert(event)
        try? context.save()
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { context.delete(events[index]) }
        try? context.save()
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [Contact.self, Event.self], inMemory: true)
}
