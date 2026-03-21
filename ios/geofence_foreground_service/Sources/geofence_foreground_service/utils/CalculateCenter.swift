import Foundation
import CoreLocation

func calculateCenter(coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
    if coordinates.count == 1 {
        return coordinates.first!
    }

    var sumLatitude: Double = 0.0
    var sumLongitude: Double = 0.0

    for coordinate in coordinates {
        sumLatitude += coordinate.latitude
        sumLongitude += coordinate.longitude
    }

    let centerLatitude = sumLatitude / Double(coordinates.count)
    let centerLongitude = sumLongitude / Double(coordinates.count)

    return CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
}

