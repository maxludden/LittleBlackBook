import SwiftUI
import SwiftData

struct ContactsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Contact.lastName), SortDescriptor(\Contact.firstName)]) private var contacts: [Contact]

    var body: some View {
        NavigationStack {
            List {
                ForEach(contacts) { contact in
                    NavigationLink(value: contact) {
                        VStack(alignment: .leading) {
                            Text("\(contact.firstName) \(contact.lastName)")
                                .font(.headline)
                            if let email = contact.email, !email.isEmpty {
                                Text(email).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Contacts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add") { addSampleContact() }
                }
            }
            .navigationDestination(for: Contact.self) { contact in
                ContactDetailView(contact: contact)
            }
        }
    }

    private func addSampleContact() {
        let contact = Contact(firstName: "Ada", lastName: "Lovelace", email: "ada@example.com")
        context.insert(contact)
        try? context.save()
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { context.delete(contacts[index]) }
        try? context.save()
    }
}

struct ContactDetailView: View {
    let contact: Contact

    var body: some View {
        List {
            Section("Info") {
                Text("Name: \(contact.firstName) \(contact.lastName)")
                if let email = contact.email { Text("Email: \(email)") }
                if let phone = contact.phone { Text("Phone: \(phone)") }
            }
            Section("Events") {
                if contact.events.isEmpty {
                    Text("No events")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(contact.events) { event in
                        VStack(alignment: .leading) {
                            Text(event.title).font(.headline)
                            Text(event.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Contact")
    }
}

#Preview {
    ContactsView()
        .modelContainer(for: [Contact.self, Event.self], inMemory: true)
}
