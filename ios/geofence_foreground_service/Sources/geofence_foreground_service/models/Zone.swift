import Foundation
import CoreLocation

class ZonesList: Codable {
    var zones: [Zone]?

    private enum CodingKeys: String, CodingKey {
        case zones
    }

    init(zones: [Zone]?) {
        self.zones = zones
    }

    // MARK: - Codable methods

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        self.zones = try container.decodeIfPresent([Zone].self, forKey: .zones)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )

        try container.encode(zones, forKey: .zones)
    }
}

struct CodableCoordinate: Codable {
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees

    var asCLLocationCoordinate2D: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

class Zone: Codable {
    let id: String
    let radius: Double
    let coordinates: [CodableCoordinate]?
    /// This parameter is ignored on iOS but we still parse it to avoid dropping it.
    let notificationResponsivenessMs: Int?
    /// Event types to monitor (1 = enter, 2 = exit). iOS has no dwell event, so 4 is ignored.
    /// `nil` means "enter and exit".
    let triggers: [Int]?
    /// When the zone is added while the device is already inside (enter) or outside (exit),
    /// this event is delivered immediately, matching Android's `INITIAL_TRIGGER_*`.
    let initialTrigger: Int?

    // These raw values must match the keys the Dart side sends (see `JsonKeys`).
    private enum CodingKeys: String, CodingKey {
        case id
        case radius
        case coordinates
        case notificationResponsivenessMs = "notification_responsiveness_ms"
        case triggers = "fence_triggers"
        case initialTrigger = "fence_initial_trigger"
    }

    init(
        id: String,
        radius: Double,
        coordinates: [CodableCoordinate]?,
        notificationResponsivenessMs: Int?,
        triggers: [Int]? = nil,
        initialTrigger: Int? = nil
    ) {
        self.id = id
        self.radius = radius
        self.coordinates = coordinates
        self.notificationResponsivenessMs = notificationResponsivenessMs
        self.triggers = triggers
        self.initialTrigger = initialTrigger
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        let id = try container.decode(
            String.self,
            forKey: .id
        )

        let radius = try container.decode(
            Double.self,
            forKey: .radius
        )

        let coordinates = try container.decodeIfPresent(
            [CodableCoordinate].self,
            forKey: .coordinates
        )

        let notificationResponsivenessMs = try container.decodeIfPresent(
            Int.self,
            forKey: .notificationResponsivenessMs
        )

        let triggers = try container.decodeIfPresent(
            [Int].self,
            forKey: .triggers
        )

        let initialTrigger = try container.decodeIfPresent(
            Int.self,
            forKey: .initialTrigger
        )

        self.init(
            id: id,
            radius: radius,
            coordinates: coordinates,
            notificationResponsivenessMs: notificationResponsivenessMs,
            triggers: triggers,
            initialTrigger: initialTrigger
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )

        try container.encode(
            id,
            forKey: .id
        )

        try container.encode(
            radius,
            forKey: .radius
        )

        try container.encodeIfPresent(
            coordinates,
            forKey: .coordinates
        )

        try container.encodeIfPresent(
            notificationResponsivenessMs,
            forKey: .notificationResponsivenessMs
        )

        try container.encodeIfPresent(triggers, forKey: .triggers)
        try container.encodeIfPresent(initialTrigger, forKey: .initialTrigger)
    }
}
