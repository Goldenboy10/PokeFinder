//
//  ViewController.swift
//  PokeFinder
//
//  Created by Mickaele Perez on 5/8/17.
//  Copyright © 2017 Code. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    var mapHasCenteredOnce = false
    
    var geoFire: GeoFire!
    var geoFireRef: FIRDatabaseReference!
    
    var selectedPokemonId: Int!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        mapView.delegate = self
        //tracks user location
        mapView.userTrackingMode = MKUserTrackingMode.follow
        
        //it's just a firebase database reference
        geoFireRef = FIRDatabase.database().reference()
        geoFire = GeoFire(firebaseRef: geoFireRef)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        locationAuthStatus()
    }
    
    func locationAuthStatus() {
        //use in use so we don't drain the users battery
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        }
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    //when GPS on phone updates, you want to center map
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if let loc = userLocation.location {
            if !mapHasCenteredOnce {
                centerMapOnLocation(location: loc)
                mapHasCenteredOnce = true
            }
        }
    }
    
    
    //user location is an annotation
    //function is called whenever we add an annotation to the mapView
    //when mapView.addAnnotation() is called, this will be called
    //lets you figure out what you want to do with your annotation and customize it before you plot in on the map
    //we created a sighting so now we will plot it on the map with this function
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        //created an identifier for the pokemon
        let annoIdentifier = "Pokemon"
        var annotationView: MKAnnotationView?
        
        //if it is a user, uses 'ash' location
        //checks if this is a user location annotation
        if annotation.isKind(of: MKUserLocation.self) {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
            annotationView?.image = UIImage(named: "ash")
        }
        //if not then it tries to deque a reusuable cell
        //made to reuse annotation if needed
        else if let deqAno = mapView.dequeueReusableAnnotationView(withIdentifier: annoIdentifier) {
            annotationView = deqAno
            annotationView?.annotation = annotation
        }
        //default if you can't create an annotation
        //if you can't reuse an annotation then you create the annotation
        //need this just in case the deque fails from the else if statement
        //need to create a default annotation
        else {
            let av = MKAnnotationView(annotation: annotation, reuseIdentifier: annoIdentifier)
            //popup to appear with map icon
            av.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            annotationView = av
        }
        
        //where we customize the annotation
        //if it is a default case or any case, we will go in and customize it
        //making sure the annotaitonView is not nil
        //making sure we can successful cast the annotation as a PokeAnnotation
        if let annotationView = annotationView, let anno = annotation as? PokeAnnotation {
            
            // .canShowCallout is the popup when you select one
            //if you set a callout then you need to set a title
            //shows map
            annotationView.canShowCallout = true
            annotationView.image = UIImage(named: "\(anno.pokemonNumber)")
            
            let btn = UIButton()
            btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            btn.setImage(UIImage(named: "map"), for: .normal)
            annotationView.rightCalloutAccessoryView = btn
            
        }
        
        return annotationView
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //using pokemon ID's instead of actual names
    func createSighting(forlocation location: CLLocation, withPokemon pokeId: Int) {
        geoFire.setLocation(location, forKey: "\(pokeId)")
    }
    
    func showSightingsOnMap(location: CLLocation) {
        let circleQuery = geoFire!.query(at: location, withRadius: 2.5)
        
        //if you don't want a result you can use an underscore
        //you just want an action to happen
        //observe whenever it finds a sighting, if i have 50 pokemon, it will be called 50 times
        _ = circleQuery?.observe(GFEventType.keyEntered, with: { (key, location) in
            //these can both be nil, so we making both exist
            //renaming key and location varialbe so that it accesses it from the local scope instead of accessing it from the outer scope
            if let key = key, let location = location {
                let anno = PokeAnnotation(coordinate: location.coordinate, pokemonNumber: Int(key)!)
                //adds annotation to the map
                self.mapView.addAnnotation(anno)
                
            }
            
        })
        
    }
    
    //grabbing the locations of the center of the map where the user is scrolling
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        showSightingsOnMap(location: loc)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        //you tap the pop up or the pokemon and a pop up appears with the map on it
        if let anno = view.annotation as? PokeAnnotation {
            
            var place: MKPlacemark!
            if #available(iOS 10.0, *) {
                place = MKPlacemark(coordinate: anno.coordinate)
            } else {
                // Fallback on earlier versions
                place = MKPlacemark(coordinate: anno.coordinate, addressDictionary: nil)
            }
            let destination = MKMapItem(placemark: place)
            destination.name = "Pokemon Sighting"
            let regionDistance: CLLocationDistance = 1000
            let regionSpan = MKCoordinateRegionMakeWithDistance(anno.coordinate, regionDistance, regionDistance)
            
            let options = [MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center), MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span), MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving] as [String : Any]
            
            MKMapItem.openMaps(with: [destination], launchOptions: options)
            
        }
    }

    @IBAction func spotRandomPokemon(_ sender: Any) {
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        let rand = arc4random_uniform(151) + 1
        createSighting(forlocation: loc, withPokemon: Int(rand))
    }

}

