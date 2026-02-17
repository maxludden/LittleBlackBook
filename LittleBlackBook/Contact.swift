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
    case unkown = "Unknown"
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
    case unknown = "Unknown"
}


@Model
final class Contact {

    // MARK: Identity
    @Attribute(.unique)
    var id: UUID
    
    /// Predefined position stored as a string for persistence stability
    private var positionRaw: String

    /// Predefined interests stored as strings for persistence stability
    private var predefinedInterestRaw: [String]
    
    /// Custom interests user adds
    var customInterests: [String]
    
    // MARK: CNContact fields
    /// The name prefix of the contact.
    var namePrefix: String?
    
    /// The given name of the contact.
    var givenName: String?
    
    /// The middle name of the contact.
    var middleName: String?
    
    /// The family name of the contact.
    var familyName: String?
    
    /// A string for the previous family name of the contact.
    var previewFamilyName: String?
    
    /// The name suffix of the contact.
    var nameSuffix: String?
    
    /// The nickname of the contact..
    var nickName: String?
    
    /// The phonetic given name of the contact.
    var phoneticGivenName: String?
    
    /// The phonetic middle name of the contact.
    var phoneticMiddleName: String?
    
    /// A string for the phonetic family name of the contact.
    var phoneticFamilyName: String?
    
    /// An array of labeled postal addresses for a contact.
    var postalAddresses: [CNLabeledValue<CNPostalAddress>]

    ///An array of labeled email addresses for the contact.
    var emailAddresses: [CNLabeledValue<NSString>]
    
    /// An array of labeled URL addresses for a contact.
    var urlAddresses: [CNLabeledValue<NSString>]

    /// An array of labeled phone numbers for a contact.
    var phoneNumbers: [CNLabeledValue<CNPhoneNumber>]
    
    /// An array of labeled social profiles for a contact.
    var socialProfiles: [CNLabeledValue<CNSocialProfile>]
    
    /// A date component for the Gregorian birthday of the contact.
    var birthday: DateComponents?
        
    ///A date component for the non-Gregorian birthday of the contact.
    var nonGregorianBirthday: DateComponents?
    
    /// An array containing labeled Gregorian dates.
    var dates: [CNLabeledValue<NSDateComponents>]
    
    /// A string containing notes for the contact.
    var note: String

    /// The profile picture of a contact.
    var imageData: Data?
    
    ///The thumbnail version of the contact’s profile picture.
    var thumbnailImageData: Data?
    
    /// A Boolean indicating whether a contact has a profile picture.
    var imageDataAvailable: Bool
    
    /// An array of labeled relations for the contact.
    var contactRelations: [CNLabeledValue<CNContactRelation>]
    
    /// An array of labeled IM addresses for the contact.
    var instantMessageAddresses: [CNLabeledValue<CNInstantMessageAddress>]

    
    
    /// Optional: store the system contact identifier too (useful for re-sync)
    var cnIdentifier: String?

    // MARK: Relationships
    @Relationship
    var events: [Event] = []

    /// Position of Contact
    var position: Position {
        get { Position(rawValue: positionRaw) ?? .unkown }
        set { positionRaw = newValue.rawValue }
    }

    // Mark: Interests
    /// Predefined Interests of a Contact
    var predefinedInterests: [PredefinedInterest] {
        get { predefinedInterestRaw.compactMap(PredefinedInterest.init(rawValue:)) }
        set { predefinedInterestRaw = newValue.map(\.rawValue) }
    }

    /// Convenient merged list for UI display/search
    var allInterests: [String] {
        predefinedInterestRaw + customInterests
    }

    /// Add custom interest
    func addCustomInterest(_ interest: String) {
            let trimmed = interest.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            if !customInterests.contains(trimmed) {
                customInterests.append(trimmed)
            }
        }

    /// Remove custom interest
    func removeCustomInterest(_ interest: String) {
        customInterests.removeAll { $0 == interest }
    }
    
    /// Rebuilds a CNMutableContact from stored vCard (or returns an empty one).
    func toCNMutableContact() -> CNMutableContact {
        let mutable = CNMutableContact()

        // Identity / names
        mutable.namePrefix = self.namePrefix ?? ""
        mutable.givenName = self.givenName ?? ""
        mutable.middleName = self.middleName ?? ""
        mutable.familyName = self.familyName ?? ""
        mutable.previousFamilyName = self.previewFamilyName ?? ""
        mutable.nameSuffix = self.nameSuffix ?? ""
        mutable.nickname = self.nickName ?? ""

        // Phonetics
        mutable.phoneticGivenName = self.phoneticGivenName ?? ""
        mutable.phoneticMiddleName = self.phoneticMiddleName ?? ""
        mutable.phoneticFamilyName = self.phoneticFamilyName ?? ""

        // Labeled values collections
        mutable.postalAddresses = self.postalAddresses
        mutable.emailAddresses = self.emailAddresses
        mutable.urlAddresses = self.urlAddresses
        mutable.phoneNumbers = self.phoneNumbers
        mutable.socialProfiles = self.socialProfiles

        // Dates
        mutable.birthday = self.birthday
        mutable.nonGregorianBirthday = self.nonGregorianBirthday
        mutable.dates = self.dates

        // Note
        mutable.note = self.note

        // Images
        mutable.imageData = self.imageData
        // CNContact builds thumbnail automatically from imageData; thumbnailImageData is read-only on CNContact

        // Relationships & IM
        mutable.contactRelations = self.contactRelations
        mutable.instantMessageAddresses = self.instantMessageAddresses

        // If we have a stored identifier, keep it on best-effort basis (CNMutableContact.identifier is get-only, so this is informational only)
        // The identifier is assigned by the contacts store when saving; we cannot set it here.

        return mutable
    }
    
    // This is a computed helper and should not be persisted by SwiftData
    // Keep it as a plain computed property so the macro doesn't synthesize storage
    var vCardData: CNMutableContact { toCNMutableContact() }
    
    fileprivate static func makeVCardData(from self: Contact) -> Data? {
        // CNContactVCardSerialization expects CNContact, and CNMutableContact is a CNContact subclass
        let contact: CNContact = self.toCNMutableContact()
        return try? CNContactVCardSerialization.data(with: [contact])
    }
    
    class func fromCNContact(_ cn: CNContact) throws -> Contact {
        // Build a Contact from a CNContact by mapping fields directly
        let contact = Contact(
            id: UUID(),
            namePrefix: cn.namePrefix.isEmpty ? nil : cn.namePrefix,
            givenName: cn.givenName,
            middleName: cn.middleName.isEmpty ? nil : cn.middleName,
            familyName: cn.familyName.isEmpty ? nil : cn.familyName,
            previewFamilyName: cn.previousFamilyName.isEmpty ? nil : cn.previousFamilyName,
            nameSuffix: cn.nameSuffix.isEmpty ? nil : cn.nameSuffix,
            nickName: cn.nickname.isEmpty ? nil : cn.nickname,
            phoneticGivenName: cn.phoneticGivenName.isEmpty ? nil : cn.phoneticGivenName,
            phoneticMiddleName: cn.phoneticMiddleName.isEmpty ? nil : cn.phoneticMiddleName,
            phoneticFamilyName: cn.phoneticFamilyName.isEmpty ? nil : cn.phoneticFamilyName,
            postalAddresses: cn.postalAddresses,
            emailAddresses: cn.emailAddresses,
            urlAddresses: cn.urlAddresses,
            phoneNumbers: cn.phoneNumbers,
            socialProfiles: cn.socialProfiles,
            birthday: cn.birthday,
            nonGregorianBirthday: cn.nonGregorianBirthday,
            dates: cn.dates,
            note: cn.note,
            imageData: cn.imageDataAvailable ? cn.imageData : nil,
            thumbnailImageData: nil,
            imageDataAvailable: cn.imageDataAvailable,
            contactRelations: cn.contactRelations,
            instantMessageAddresses: cn.instantMessageAddresses,
            position: .unkown,
            predefinedInterests: [],
            customInterests: []
        )
        // Persist the cn identifier for potential re-sync
        contact.cnIdentifier = cn.identifier
        // Default domain-specific fields
        contact.position = .unkown
        contact.predefinedInterests = []
        return contact
    }
        
    // MARK: - Init
    init(
        id: UUID = UUID(),
        namePrefix: String? = nil,
        givenName: String = "",
        middleName: String? = nil,
        familyName: String? = nil,
        previewFamilyName: String? = nil,
        nameSuffix: String? = nil,
        nickName: String? = nil,
        phoneticGivenName: String? = nil,
        phoneticMiddleName: String? = nil,
        phoneticFamilyName: String? = nil,
        postalAddresses: [CNLabeledValue<CNPostalAddress>] = [],
        emailAddresses: [CNLabeledValue<NSString>] = [],
        urlAddresses: [CNLabeledValue<NSString>] = [],
        phoneNumbers: [CNLabeledValue<CNPhoneNumber>] = [],
        socialProfiles: [CNLabeledValue<CNSocialProfile>] = [],
        birthday: DateComponents? = nil,
        nonGregorianBirthday: DateComponents? = nil,
        dates: [CNLabeledValue<NSDateComponents>] = [],
        note: String = "",
        imageData: Data? = nil,
        thumbnailImageData: Data? = nil,
        imageDataAvailable: Bool = false,
        contactRelations: [CNLabeledValue<CNContactRelation>] = [],
        instantMessageAddresses: [CNLabeledValue<CNInstantMessageAddress>] = [],
        position: Position = .unkown,
        predefinedInterests: [PredefinedInterest] = [],
        customInterests: [String] = [],
    ) {
        self.id = id
        self.positionRaw = position.rawValue
        self.predefinedInterestRaw = predefinedInterests.map(\.rawValue)
        self.customInterests = customInterests
        self.namePrefix = namePrefix
        self.givenName = givenName.localizedCapitalized
        self.middleName = middleName?.localizedCapitalized
        self.familyName = familyName?.localizedCapitalized
        self.previewFamilyName = previewFamilyName?.localizedCapitalized
        self.nameSuffix = nameSuffix?.localizedCapitalized
        self.nickName = nickName?.localizedCapitalized
        self.phoneticGivenName = phoneticGivenName?.localizedCapitalized
        self.phoneticMiddleName = phoneticMiddleName?.localizedCapitalized
        self.phoneticFamilyName = phoneticFamilyName?.localizedCapitalized
        self.postalAddresses = postalAddresses
        self.emailAddresses = emailAddresses
        self.urlAddresses = urlAddresses
        self.phoneNumbers = phoneNumbers
        self.socialProfiles = socialProfiles
        self.birthday = birthday
        self.nonGregorianBirthday = nonGregorianBirthday
        self.dates = dates
        self.note = note
        self.imageData = imageData
        self.thumbnailImageData = thumbnailImageData
        self.imageDataAvailable = imageDataAvailable
        self.contactRelations = contactRelations
        self.instantMessageAddresses = instantMessageAddresses
    }
}

