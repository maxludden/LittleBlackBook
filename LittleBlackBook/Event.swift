import Foundation
import SwiftData

@Model
final class Event {
    var title: String
    var date: Date
    var notes: String?
    
    @Relationship(inverse: \Contact.events)
    var contacts: [Contact] = []

    init(title: String, date: Date = .now, notes: String? = nil, contacts: [Contact] = []) {
        self.title = title
        self.date = date
        self.notes = notes
        self.contacts = contacts
    }
}
