import Foundation
import MapKit
struct Place: Codable {
    let name: String
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let address: String
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    static func getFormattedAddress(with placemark: CLPlacemark) -> String {
        var address = ""
        
        // The street address associated with the placemark
        if let street = placemark.thoroughfare {
            address += street // rua
        }
        if let number = placemark.subThoroughfare {
            address += " \(number)" // número
        }
        if let subLocality = placemark.subLocality {
            address += ", \(subLocality)" // bairro
        }
        if let state = placemark.administrativeArea {
            address += " - \(state)" // estado
        }
        if let postalCode = placemark.postalCode {
            address += " \nCEP:  \(postalCode)" // CEP
        }
        if let country = placemark.country {
            address += "\n\(country)" // País
        }
        return address
    }
}
// definindo uma regra para haver criterio de comparacao
extension Place: Equatable {
    static func ==(lhs: Place, rhs: Place) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
