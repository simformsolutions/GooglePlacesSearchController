//
//  ViewController.swift
//  GooglePlacesSearchController
//
//  Created by Dmitry Shmidt on 6/28/15.
//  Copyright (c) 2015 Dmitry Shmidt. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import GooglePlacesSearchController

class ViewController: UIViewController {
    let GoogleMapsAPIServerKey = "AIzaSyC8Cu3t_4J4V3QzRYFRtcyzVpmsNaY5gIc"
    let currentLocation:CLLocation = CLLocation.init(latitude: 23.0259973, longitude: 72.5079086)

    lazy var placesSearchController: GooglePlacesSearchController = {
        let controller = GooglePlacesSearchController(delegate: self,
                                                      apiKey: GoogleMapsAPIServerKey,
                                                      placeType: .address,location:self.currentLocation
            // Optional: coordinate: CLLocationCoordinate2D(latitude: 55.751244, longitude: 37.618423),
            // Optional: radius: 10,
            // Optional: searchBarPlaceholder: "Start typing..."
        )
        //Optional: controller.searchBar.isTranslucent = false
        //Optional: controller.searchBar.barStyle = .black
        //Optional: controller.searchBar.tintColor = .white
        //Optional: controller.searchBar.barTintColor = .black
        return controller
    }()

    @IBAction func searchAddress(_ sender: UIBarButtonItem) {
        present(placesSearchController, animated: true, completion: nil)
    }
}

extension ViewController: GooglePlacesAutocompleteViewControllerDelegate {
    func viewController(didAutocompleteWith place: SearchPlaceDetails) {
        placesSearchController.isActive = false
    }
}


