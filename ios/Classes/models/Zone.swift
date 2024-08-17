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

    private enum CodingKeys: String, CodingKey {
        case id
        case radius
        case coordinates
        case notificationResponsivenessMs
    }

    init(
        id: String,
        radius: Double,
        coordinates: [CodableCoordinate]?,
        notificationResponsivenessMs: Int?
    ) {
        self.id = id
        self.radius = radius
        self.coordinates = coordinates
        self.notificationResponsivenessMs = notificationResponsivenessMs
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

        self.init(
            id: id,
            radius: radius,
            coordinates: coordinates,
            notificationResponsivenessMs: notificationResponsivenessMs
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
    }
}
