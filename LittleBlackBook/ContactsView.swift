//
//  ContactsView.swift
//  LittleBlackBook
//
//  Created by Maxwell Ludden on 2/15/26.
//

import SwiftUI
import SwiftData
import Contacts
import ContactsUI
import Photos
import MediaPlayer

struct ContactsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Person.lastName), SortDescriptor(\Person.firstName)]) private var people: [Person]

    @State private var showingCNPicker = false
    @State private var showingPhotoPicker = false

    var body: some View {
        List {
            ForEach(people) { person in
                NavigationLink(value: person.id) {
                    VStack(alignment: .leading) {
                        Text(fullName(for: person)).font(.headline)
                        if !person.nickname.isEmpty { Text(person.nickname).foregroundStyle(.secondary) }
                        if let firstEmail = person.emails.first { Text(firstEmail).foregroundStyle(.secondary) }
                    }
                }
            }
            .onDelete(perform: deletePeople)
        }
        .navigationDestination(for: UUID.self) { id in
            if let person = people.first(where: { $0.id == id }) {
                PersonDetailView(person: person)
            } else {
                Text("Contact not found")
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button("Import from Contacts", action: { showingCNPicker = true })
                    Button("Add New Contact", action: addPerson)
                    Button("Import from Photos", action: { showingPhotoPicker = true })
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .topBarLeading) { EditButton() }
        }
        .sheet(isPresented: $showingCNPicker) {
            // Placeholder for CNContactPickerViewController via UIViewControllerRepresentable
            ContactPickerSheet { imported in
                importCNContacts(imported)
                showingCNPicker = false
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            // Placeholder for Photo Importer
            PhotoImportSheet { importedPersons in
                for person in importedPersons {
                    modelContext.insert(person)
                }
                showingPhotoPicker = false
            }
        }
    }

    private func fullName(for p: Person) -> String {
        let space = (!p.firstName.isEmpty && !p.lastName.isEmpty) ? " " : ""
        let base = p.firstName + space + p.lastName
        return base.isEmpty ? "Untitled" : base
    }

    private func addPerson() {
        withAnimation {
            let p = Person()
            modelContext.insert(p)
        }
    }

    private func deletePeople(at offsets: IndexSet) {
        withAnimation {
            for index in offsets { modelContext.delete(people[index]) }
        }
    }

    private func importCNContacts(_ contacts: [CNContact]) {
        for c in contacts {
            let person = Person(
                firstName: c.givenName,
                lastName: c.familyName,
                nickname: c.nickname,
                organizationName: c.organizationName,
                jobTitle: c.jobTitle,
                emails: c.emailAddresses.map { $0.value as String },
                phoneNumbers: c.phoneNumbers.map { $0.value.stringValue },
                postalAddresses: c.postalAddresses.map { CNPostalAddressFormatter.string(from: $0.value, style: .mailingAddress) },
                urls: c.urlAddresses.map { $0.value as String },
                notes: c.note
            )
            modelContext.insert(person)
        }
    }
}

// MARK: - Person Detail Placeholder

struct PersonDetailView: View {
    @Bindable var person: Person

    var body: some View {
        Form {
            Section("Name") {
                TextField("First name", text: $person.firstName)
                TextField("Last name", text: $person.lastName)
                TextField("Nickname", text: $person.nickname)
            }
            Section("Contact") {
                TextFieldArray(title: "Emails", items: $person.emails)
                TextFieldArray(title: "Phones", items: $person.phoneNumbers)
                TextFieldArray(title: "Addresses", items: $person.postalAddresses)
                TextFieldArray(title: "URLs", items: $person.urls)
                TextField("Notes", text: $person.notes, axis: .vertical)
            }
        }
        .navigationTitle("Edit Contact")
    }
}

struct TextFieldArray: View {
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

// MARK: - CNContact Picker placeholder implementation

struct ContactPickerSheet: View {
    var onPick: ([CNContact]) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Contact Picker Placeholder")
            Text("Replace with CNContactPickerViewController when ready.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button("Import Sample") {
                onPick([])
            }
            Button("Close") {
                onPick([])
            }
        }
        .padding()
    }
}

// MARK: - Photo Importer placeholder implementation

struct PhotoImportSheet: View {
    var onImport: ([Person]) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Photo Import Placeholder")
            Text("Replace with photo analysis/import logic when ready.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button("Import Sample") {
                onImport([])
            }
            Button("Close") {
                onImport([])
            }
        }
        .padding()
    }
}

