import Foundation
import SwiftData

@Model
final class Event: Identifiable {
    @Attribute(.unique) var id: UUID = UUID()

    // Basic event info mirroring common EventKit fields
    var title: String
    var notes: String?
    var location: String?
    var isAllDay: Bool
    var startDate: Date
    var endDate: Date?
    
    @Relationship(deleteRule: .nullify)
    var contacts: [ContactRecord] = []

    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        location: String? = nil,
        isAllDay: Bool = false,
        startDate: Date = .now,
        endDate: Date? = nil,
        contacts: [ContactRecord] = []
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.location = location
        self.isAllDay = isAllDay
        self.startDate = startDate
        self.endDate = endDate
        self.contacts = contacts
    }
}

