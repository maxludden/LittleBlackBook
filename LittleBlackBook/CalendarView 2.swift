import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Event.date, order: .forward)]) private var events: [Event]
    @Query(sort: [SortDescriptor(\Contact.lastName), SortDescriptor(\Contact.firstName)]) private var contacts: [Contact]

    var body: some View {
        NavigationStack {
            List {
                ForEach(events) { event in
                    VStack(alignment: .leading) {
                        Text(event.title).font(.headline)
                        Text(event.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if !event.contacts.isEmpty {
                            Text("Contacts: " + event.contacts.map { "\($0.firstName) \($0.lastName)" }.joined(separator: ", "))
                                .font(.subheadline)
                        }
                    }
                }
                .onDelete(perform: delete)
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
        let event = Event(title: "Meeting", date: .now.addingTimeInterval(3600), notes: "Discuss roadmap", contacts: associated)
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
