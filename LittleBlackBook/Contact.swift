import SwiftData
import Contacts
import Foundation

enum Position: String, CaseIterable, Codable {
    case top = "Top"
    case verseTop = "Verse-Top"
    case verse = "Verse"
    case verseBottom = "Verse-Bottom"
    case bottom = "Bottom"
    case side = "Side"
}

enum PredefinedInterest: String, CaseIterable, Codable {
    case oralGiving = "Oral (giving)"
    case oralReceiving = "Oral (receiving)"
    case rimmingGiving = "Rimming (giving)"
    case rimmingReceiving = "Rimming (receiving)"
    case groupFun = "Group Fun"
    case roughFun = "Rough Fun"
    case bondage = "Bondage"
    case feet = "Feet"
    case waterSports = "Water Sports"
    case party = "Party"
}


@Model
final class ContactRecord {

    // MARK: Identity
    @Attribute(.unique) var id: UUID

    // MARK: App-specific fields
    private var positionRaw: String

    /// Predefined interests stored as strings for persistence stability
    private var predefinedInterestRaw: [String]
    /// Custom interests user adds
    var customInterests: [String]

    // MARK: Wrapped CNContact payload
    /// vCard representation of the contact (portable + stable)
    var vCardData: Data?

    /// Optional: store the system contact identifier too (useful for re-sync)
    var cnIdentifier: String?

    // MARK: Relationships
    @Relationship var events: [Event] = []

    // MARK: - Computed API

    var position: Position {
        get { Position(rawValue: positionRaw) ?? .verse }
        set { positionRaw = newValue.rawValue }
    }

    var predefinedInterests: [PredefinedInterest] {
        get { predefinedInterestRaw.compactMap(PredefinedInterest.init(rawValue:)) }
        set { predefinedInterestRaw = newValue.map(\.rawValue) }
    }

    /// Convenient merged list for UI display/search
    var allInterests: [String] {
        predefinedInterestRaw + customInterests
    }

    func addCustomInterest(_ interest: String) {
            let trimmed = interest.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            if !customInterests.contains(trimmed) {
                customInterests.append(trimmed)
            }
        }

    func removeCustomInterest(_ interest: String) {
        customInterests.removeAll { $0 == interest }
    }
    
    // MARK: - Init

    init(
        id: UUID = UUID(),
        position: Position = .verse,
        predefinedInterests: [PredefinedInterest] = [],
        customInterests: [String] = [],
        contact: CNContact? = nil
    ) {
        self.id = id
        self.positionRaw = position.rawValue
        self.predefinedInterestRaw = predefinedInterests.map(\.rawValue)
        self.customInterests = customInterests

        if let contact {
            self.cnIdentifier = contact.identifier
            self.vCardData = ContactRecord.makeVCardData(from: contact)
        } else {
            self.cnIdentifier = nil
            self.vCardData = nil
        }
    }
}

extension ContactRecord {

    /// Rebuilds a CNMutableContact from stored vCard (or returns an empty one).
    func toCNMutableContact() -> CNMutableContact {
        guard
            let vCardData,
            let contacts = try? CNContactVCardSerialization.contacts(with: vCardData),
            let first = contacts.first
        else {
            return CNMutableContact()
        }

        return first.mutableCopy() as? CNMutableContact ?? CNMutableContact()
    }

    /// Updates the wrapped contact payload from a CNContact / CNMutableContact.
    func updateWrappedContact(from contact: CNContact) {
        self.cnIdentifier = contact.identifier
        self.vCardData = ContactRecord.makeVCardData(from: contact)
    }

    fileprivate static func makeVCardData(from contact: CNContact) -> Data? {
        // CNContactVCardSerialization expects CNContact, and CNMutableContact is a CNContact subclass
        return try? CNContactVCardSerialization.data(with: [contact])
    }
}
