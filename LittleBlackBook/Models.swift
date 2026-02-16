//
//  Models.swift
//  LittleBlackBook
//
//  Created by Maxwell Ludden on 2/15/26.
//

import Foundation
import SwiftData

@Model
final class Person: Identifiable {
    // Identity
    @Attribute(.unique) var id: UUID
    var firstName: String
    var lastName: String
    var nickname: String

    // Contact details (subset, extend as needed)
    var organizationName: String
    var jobTitle: String
    var emails: [String]
    var phoneNumbers: [String]
    var postalAddresses: [String]
    var urls: [String]
    var notes: String

    // Media references as bookmark Data (file URLs to Photos, videos, GIFs, etc.)
    // Store security-scoped bookmarks to access files later
    var mediaBookmarks: [Data]

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \EventItem.attendees) var events: [EventItem]

    init(
        id: UUID = UUID(),
        firstName: String = "",
        lastName: String = "",
        nickname: String = "",
        organizationName: String = "",
        jobTitle: String = "",
        emails: [String] = [],
        phoneNumbers: [String] = [],
        postalAddresses: [String] = [],
        urls: [String] = [],
        notes: String = "",
        mediaBookmarks: [Data] = []
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.nickname = nickname
        self.organizationName = organizationName
        self.jobTitle = jobTitle
        self.emails = emails
        self.phoneNumbers = phoneNumbers
        self.postalAddresses = postalAddresses
        self.urls = urls
        self.notes = notes
        self.mediaBookmarks = mediaBookmarks
        self.events = []
    }
}

@Model
final class EventItem: Identifiable {
    @Attribute(.unique) var id: UUID

    // Basic event info mirroring common EventKit fields
    var title: String
    var notes: String
    var location: String
    var isAllDay: Bool
    var startDate: Date
    var endDate: Date

    // Link to multiple attendees (Persons)
    @Relationship(deleteRule: .nullify) var attendees: [Person]

    init(
        id: UUID = UUID(),
        title: String = "",
        notes: String = "",
        location: String = "",
        isAllDay: Bool = false,
        startDate: Date = .now,
        endDate: Date = .now,
        attendees: [Person] = []
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.location = location
        self.isAllDay = isAllDay
        self.startDate = startDate
        self.endDate = endDate
        self.attendees = attendees
    }
}
