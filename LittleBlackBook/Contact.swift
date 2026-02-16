import Foundation
import SwiftData

@Model
final class Contact {
    var firstName: String
    var lastName: String
    var phone: String?
    var email: String?
    var createdAt: Date

    @Relationship(inverse: \Event.contacts)
    var events: [Event] = []

    init(firstName: String, lastName: String, phone: String? = nil, email: String? = nil, createdAt: Date = .now, events: [Event] = []) {
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.email = email
        self.createdAt = createdAt
        self.events = events
    }
}
