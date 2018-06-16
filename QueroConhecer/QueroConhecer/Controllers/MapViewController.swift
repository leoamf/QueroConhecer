//
//  MapViewController.swift
//  QueroConhecer
//
//  Created by aluno on 02/06/18.
//  Copyright © 2018 aluno. All rights reserved.
//

import UIKit
import MapKit

enum MapMessageType {
    case routeError
    case authorizationWarning
}
class MapViewController: UIViewController{

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var viInfo: UIView!
    @IBOutlet weak var lbAddress: UILabel!
    @IBOutlet weak var lbName: UILabel!

    @IBOutlet weak var loading: UIActivityIndicatorView!
    var places:[Place]!
    var poi :[MKAnnotation] = []
    lazy var locationManager = CLLocationManager()
    var btUserLocation: MKUserTrackingButton!
    
    var selectedAnnotation: PlaceAnnotation?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        for place in places{
            addMap(place)
        }
        showPlaces()
        // esconder os componentes
        searchBar.isHidden = true
        viInfo.isHidden = true
        mapView.mapType = .mutedStandard
        
        
        // configura o título
        if places.count == 1 {
            title = places[0].name
        } else {
            title = "Meus lugares"
        }
        configureLocationButton()
        
        requestUserLocationAuthorization()
        
        
        locationManager.delegate = self

    }
    
    
    func configureLocationButton() {
        btUserLocation = MKUserTrackingButton(mapView: mapView)
        btUserLocation.backgroundColor = .white
        btUserLocation.frame.origin.x = 10
        btUserLocation.frame.origin.y = 10
        btUserLocation.layer.cornerRadius = 5
        btUserLocation.layer.borderWidth = 1
        btUserLocation.layer.borderColor = UIColor(named: "main")?.cgColor
    }
    
    func requestUserLocationAuthorization() {
        if CLLocationManager.locationServicesEnabled() {
            // usario esta com esse recurso habilitado no momento
            
            switch CLLocationManager.authorizationStatus() {
            case .authorizedWhenInUse, .authorizedAlways: // precisa ter os dois?
                
                print("mostrar botao de localizacao no mapa")
                mapView.addSubview(btUserLocation)
                
            case .denied:
                showMessage(type: .authorizationWarning)
            case .notDetermined:
                // request verification here
                locationManager.requestWhenInUseAuthorization()
            case .restricted:
                // TODO
                break
                
            }
        } else {
            // precisa habilitar localizacao para acessar essa tela
            showMessage(type: .authorizationWarning)
        }
        
    }
    func showMessage(type: MapMessageType) {
        
        let title: String, message: String
        var hasConfirmation: Bool = false
        
        switch type {
        case .authorizationWarning:
            title = "Requer permissão"
            message = "Gostaria de acessar as configurações do app. para autorizar a permissão de 'Localização' ?"
            hasConfirmation = true
            
        case .routeError:
            title = "Erro"
            message = "Error ao tentar traçar uma rota"
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        if hasConfirmation {
            let confirmationAction = UIAlertAction(title: "Ajustes", style: .default) { (action) in
                print("User confirmou action - OK!!!")
                
                if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                }
                
                self.dismiss(animated: true, completion: nil)
            }
            alert.addAction(confirmationAction)
        }
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func showRoute(_ sender: UIBarButtonItem) {
        print("Show Route")
        
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
            showMessage(type: .authorizationWarning)
            return
        }
        
        if selectedAnnotation == nil {
            showMessage(type: .routeError)
        }
        
        let request = MKDirectionsRequest()
        request.destination = MKMapItem(placemark:  MKPlacemark(coordinate: selectedAnnotation!.coordinate))
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: locationManager.location!.coordinate))
        let directions = MKDirections(request: request)
        directions.calculate { (directionResponse, error) in
            if error == nil {
                
                if let response = directionResponse {
                    self.mapView.removeOverlays(self.mapView.overlays)
                    let route = response.routes.first!
                    print("Nome: ", route.name)
                    print("Distância: ", route.distance)
                    print("Duração: ", route.expectedTravelTime)
                    print("############################")
                    
                    for step in route.steps {
                        print("Em \(step.distance) metro(s), \(step.instructions)")
                    }
                    
                    // desenho da rota
                    self.mapView.add(route.polyline, level: .aboveRoads)
                    
                    // mostrar toda a rota (gambiarra? - mas funciona)
                    
                    // fazer um filtro do que não é PlaceAnnotation (assim teremos somente a localizacao do usuario)
                    var annotations = self.mapView.annotations.filter({!($0 is PlaceAnnotation)})
                    // ja temos o atual PlaceAnnotation escolhida pelo usuario
                    annotations.append(self.selectedAnnotation!)
                    
                    // mostrará o ponto que usuario está até o ponto de interesse escolhido
                    self.mapView.showAnnotations(annotations, animated: true)
                }
                
            } else {
                self.showMessage(type: .routeError)
            }
        }

    }
    @IBAction func showSearchBar(_ sender: UIButton) {
        self.searchBar.resignFirstResponder()
        self.searchBar.isHidden = !self.searchBar.isHidden
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addMap(_ place: Place){
        print("Place -> \(place.name)")
      //  places.append(place)
        
        // usando PlaceAnnotation do nosso model
        let annotation = PlaceAnnotation(coordinate: place.coordinate, type: .place)
        
        annotation.address = place.address
        annotation.coordinate = place.coordinate // variavel computada
        annotation.title = place.name
        mapView.addAnnotation(annotation)
 
    }
    func showPlaces() {
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MapViewController: UISearchBarDelegate {
    
     func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.isHidden = true
        searchBar.resignFirstResponder()
        
        // começa animação do loading
        loading.startAnimating()
        
        // prepara uma busca em pontos de interesse do mapa
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBar.text
        
        // em qual regiao será realizado a pesquisa
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            if error == nil {
                guard let response = response else {
                    DispatchQueue.main.async {
                        self.loading.stopAnimating()
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.mapView.removeAnnotations(self.poi)
                    self.poi.removeAll()
                    for item in response.mapItems {
                        let annotation = PlaceAnnotation(coordinate: item.placemark.coordinate, type: .poi)
                        annotation.title = item.name
                        annotation.subtitle = item.phoneNumber
                        annotation.address = Place.getFormattedAddress(with: item.placemark)
                        self.poi.append(annotation)
                    }
                    self.mapView.addAnnotations(self.poi)
                    self.mapView.showAnnotations(self.poi, animated: true)
                }
                
            } else {
                print(error.debugDescription)
            }
            
            DispatchQueue.main.async {
                self.loading.stopAnimating()
            }
        }
        
    }

    
}


extension MapViewController: MKMapViewDelegate {
    
    // usado para recuperar uma annotationView para permitir modifica-la
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if !(annotation is PlaceAnnotation) {
            // mantem o default caso nao seja o tipo esperado.
            return nil
        }
        
        let placeAnnotation = annotation as! PlaceAnnotation
        let type = placeAnnotation.type
        let identifier = "\(type)"
        // tentando reusar uma view do pino padrao (MKMarkerAnnotationView)
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        
        if annotationView == nil {
            // criando pela primeira vez uma annotation view
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        annotationView?.annotation = annotation
        annotationView?.canShowCallout = true // informacoes extras na forma de um balao
        // usando Point of Interess
        annotationView?.markerTintColor = type == .place ? UIColor(named: "main") : UIColor(named: "poi")

        annotationView?.glyphImage = type == .place ?  #imageLiteral(resourceName: "placeGlyph") :  #imageLiteral(resourceName: "poiGlyph")
        annotationView?.displayPriority = type == .place ? .required : .defaultHigh
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("--->>> didSelect")
        
        // visualizando
        let camera = MKMapCamera()
        camera.centerCoordinate = view.annotation!.coordinate
        camera.pitch = 80 // angulo da camera
        camera.altitude = 100
        mapView.setCamera(camera, animated: true)
        
        selectedAnnotation = (view.annotation as? PlaceAnnotation)
        showInfo()
    }
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        viInfo.isHidden = true
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor(named: "main")?.withAlphaComponent(0.8)
            renderer.lineWidth = 5.0
            
            return renderer
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
    func showInfo() {
        if selectedAnnotation != nil {
            
            lbName.text = selectedAnnotation?.title
            lbAddress.text = selectedAnnotation?.address
            viInfo.isHidden = false
        }
    }
}
extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("--->>> didChangeAuthorization (respondendo a uma mudanca de status) <<<---")
        
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true
            mapView.addSubview(btUserLocation)
            locationManager.startUpdatingLocation()
        case .denied:
            showMessage(type: .authorizationWarning)
        default:
            // TODO
            break
        }
    }
    
    // notificado quando tiver mudanca de localizacao
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print(locations.last!)
    }
    
}
