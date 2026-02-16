//
//  ContactsView.swift
//  LittleBlackBook
//
//  Updated to use ContactRecord
//

import SwiftUI
import SwiftData
import Contacts

struct ContactsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var contacts: [ContactRecord]

    @State private var showingCNPicker = false

    var body: some View {
        List {
            ForEach(contacts) { record in
                NavigationLink(value: record.id) {
                    let cn = record.toCNMutableContact()
                    VStack(alignment: .leading) {
                        Text("\(cn.givenName) \(cn.familyName)")
                            .font(.headline)
                        Text(record.position.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteContacts)
        }
        .navigationDestination(for: UUID.self) { id in
            if let record = contacts.first(where: { $0.id == id }) {
                ContactDetailView(record: record)
            } else {
                Text("Contact not found")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCNPicker = true
                } label: {
                    Label("Import", systemImage: "person.crop.circle.badge.plus")
                }
            }
            ToolbarItem(placement: .topBarLeading) { EditButton() }
        }
        .sheet(isPresented: $showingCNPicker) {
            ContactPickerSheet { imported in
                importCNContacts(imported)
                showingCNPicker = false
            }
        }
    }

    private func deleteContacts(at offsets: IndexSet) {
        withAnimation {
            for index in offsets { modelContext.delete(contacts[index]) }
        }
    }

    private func importCNContacts(_ imported: [CNContact]) {
        for c in imported {
            let rec = ContactRecord(contact: c)
            modelContext.insert(rec)
        }
    }
}

struct ContactDetailView: View {
    @Bindable var record: ContactRecord
    @Environment(\.modelContext) private var modelContext

    // Local editable CNContact fields
    @State private var givenName: String = ""
    @State private var familyName: String = ""
    @State private var nickname: String = ""
    @State private var emails: [String] = []
    @State private var phones: [String] = []

    @State private var newCustomInterest: String = ""

    var body: some View {
        Form {
            Section("Name") {
                TextField("First name", text: $givenName)
                TextField("Last name", text: $familyName)
                TextField("Nickname", text: $nickname)
                Button("Save Name to Contact") { saveCNContactBasics() }
            }
            Section("Contact Methods") {
                EditableStringArray(title: "Emails", items: $emails)
                EditableStringArray(title: "Phones", items: $phones)
                Button("Save Methods to Contact") { saveCNContactMethods() }
            }
            Section("Position") {
                Picker("Position", selection: Binding(
                    get: { record.position },
                    set: { record.position = $0 }
                )) {
                    ForEach(Position.allCases, id: \.self) { pos in
                        Text(pos.rawValue).tag(pos)
                    }
                }
                .pickerStyle(.segmented)
            }
            Section("Interests") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Predefined")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    ForEach(PredefinedInterest.allCases, id: \.self) { interest in
                        let isOn = record.predefinedInterests.contains(interest)
                        Toggle(interest.rawValue, isOn: Binding(
                            get: { isOn },
                            set: { on in
                                var current = record.predefinedInterests
                                if on {
                                    if !current.contains(interest) { current.append(interest) }
                                } else {
                                    current.removeAll { $0 == interest }
                                }
                                record.predefinedInterests = current
                            }
                        ))
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack {
                        TextField("Add interest", text: $newCustomInterest)
                        Button("Add") {
                            record.addCustomInterest(newCustomInterest)
                            newCustomInterest = ""
                        }
                        .disabled(newCustomInterest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    if record.customInterests.isEmpty {
                        Text("No custom interests")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(record.customInterests, id: \.self) { item in
                            HStack {
                                Text(item)
                                Spacer()
                                Button(role: .destructive) {
                                    record.removeCustomInterest(item)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
            }
            Section("Events") {
                if record.events.isEmpty {
                    Text("No linked events")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(record.events) { event in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(event.title)
                                    .font(.headline)
                                Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(role: .destructive) { unlink(event: event) } label: {
                                Image(systemName: "link.badge.minus")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                NavigationLink("Link Events") { EventLinkerView(record: record) }
            }
        }
        .navigationTitle("Contact")
        .onAppear(perform: loadFromCNContact)
    }

    private func loadFromCNContact() {
        let cn = record.toCNMutableContact()
        givenName = cn.givenName
        familyName = cn.familyName
        nickname = cn.nickname
        emails = cn.emailAddresses.map { $0.value as String }
        phones = cn.phoneNumbers.map { $0.value.stringValue }
    }

    private func saveCNContactBasics() {
        var cn = record.toCNMutableContact()
        cn.givenName = givenName
        cn.familyName = familyName
        cn.nickname = nickname
        record.updateWrappedContact(from: cn)
    }

    private func saveCNContactMethods() {
        var cn = record.toCNMutableContact()
        cn.emailAddresses = emails.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { CNLabeledValue(label: CNLabelHome, value: NSString(string: $0)) }
        cn.phoneNumbers = phones.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: $0)) }
        record.updateWrappedContact(from: cn)
    }

    private func unlink(event: Event) {
        if let idx = record.events.firstIndex(where: { $0.id == event.id }) {
            record.events.remove(at: idx)
        }
        if let cidx = event.contacts.firstIndex(where: { $0.id == record.id }) {
            event.contacts.remove(at: cidx)
        }
    }
}

// Reusable small component for editing arrays of strings
struct EditableStringArray: View {
    let title: String
    @Binding var items: [String]

    var body: some View {
        Section(title) {
            ForEach(items.indices, id: \.self) { idx in
                TextField("\(title) #\(idx+1)", text: Binding(
                    get: { items[idx] },
                    set: { items[idx] = $0 }
                ))
            }
            .onDelete { offsets in
                items.remove(atOffsets: offsets)
            }
            Button { items.append("") } label: {
                Label("Add \(title.dropLast(title.hasSuffix("s") ? 1 : 0))", systemImage: "plus")
            }
        }
    }
}

struct EventLinkerView: View {
    @Bindable var record: ContactRecord
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Event.startDate, order: .forward)]) private var allEvents: [Event]

    var body: some View {
        List {
            ForEach(allEvents) { event in
                let linked = event.contacts.contains { $0.id == record.id }
                HStack {
                    VStack(alignment: .leading) {
                        Text(event.title)
                        Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if linked {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleLink(event)
                }
            }
        }
        .navigationTitle("Link Events")
    }

    private func toggleLink(_ event: Event) {
        if let idx = event.contacts.firstIndex(where: { $0.id == record.id }) {
            event.contacts.remove(at: idx)
        } else {
            event.contacts.append(record)
        }
    }
}

// Placeholder CNContact picker; replace with real UI when needed
struct ContactPickerSheet: View {
    var onPick: ([CNContact]) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Contact Picker Placeholder")
            Button("Import Sample (Empty)") { onPick([]) }
            Button("Close") { onPick([]) }
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        ContactsView()
    }
    .modelContainer(for: [ContactRecord.self, Event.self], inMemory: true)
}


