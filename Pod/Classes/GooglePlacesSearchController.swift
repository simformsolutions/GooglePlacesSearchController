//
//  GooglePlacesAutocomplete.swift
//  GooglePlacesAutocomplete
//
//  Created by Howard Wilson on 10/02/2015.
//  Copyright (c) 2015 Howard Wilson. All rights reserved.
//
//
//  Created by Dmitry Shmidt on 6/28/15.
//  Copyright (c) 2015 Dmitry Shmidt. All rights reserved.

import UIKit
import CoreLocation

public enum PlaceType: String {
    case all = ""
    case geocode
    case address
    case establishment
    case regions = "(regions)"
    case cities = "(cities)"
}

open class Place: NSObject {
    open let id: String
    open let mainAddress: String
    open let secondaryAddress: String
    
    override open var description: String {
        get { return "\(mainAddress), \(secondaryAddress)" }
    }
    
    init(id: String, mainAddress: String, secondaryAddress: String) {
        self.id = id
        self.mainAddress = mainAddress
        self.secondaryAddress = secondaryAddress
    }
    
    convenience init(prediction: [String: Any]) {
        let structuredFormatting = prediction["structured_formatting"] as? [String: Any]
        
        self.init(
            id: prediction["place_id"] as? String ?? "",
            mainAddress: structuredFormatting?["main_text"] as? String ?? "",
            secondaryAddress: structuredFormatting?["secondary_text"] as? String ?? ""
        )
    }
}

open class SearchPlaceDetails: NSObject {
    
    open let mainAddress: String
    open let secondaryAddress: String
    open let coordinate: CLLocationCoordinate2D
    open let location : CLLocation
    
    override open var description: String {
        get { return "\(mainAddress), \(secondaryAddress)" }
    }
    
    init(mainAddress: String, secondaryAddress: String,coordinate: CLLocationCoordinate2D,location : CLLocation) {
        self.mainAddress = mainAddress
        self.secondaryAddress = secondaryAddress
        self.coordinate = coordinate
        self.location = location
    }
    
    convenience init(prediction: [String: Any]) {
        var featchCoordinate : CLLocationCoordinate2D?
        if let geometry = prediction["geometry"] as? [String: Any],
            let location = geometry["location"] as? [String: Any],
            let latitude = location["lat"] as? CLLocationDegrees,
            let longitude = location["lng"] as? CLLocationDegrees {
            featchCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
        self.init(
            mainAddress: prediction["name"] as? String ?? "",
            secondaryAddress: prediction["formatted_address"] as? String ?? "",
            coordinate : featchCoordinate ?? kCLLocationCoordinate2DInvalid,
            location : CLLocation(latitude: (featchCoordinate?.latitude)!, longitude: (featchCoordinate?.longitude)!)
        )
    }
}



open class PlaceDetails: CustomStringConvertible {
    open let formattedAddress: String
    open var streetNumber: String? = nil
    open var route: String? = nil
    open var postalCode: String? = nil
    open var country: String? = nil
    open var countryCode: String? = nil
    
    open var locality: String? = nil
    open var subLocality: String? = nil
    open var administrativeArea: String? = nil
    open var administrativeAreaCode: String? = nil
    open var subAdministrativeArea: String? = nil
    
    open var coordinate: CLLocationCoordinate2D? = nil
    
    init?(json: [String: Any]) {
        guard let result = json["result"] as? [String: Any],
            let formattedAddress = result["formatted_address"] as? String
            else { return nil }
        
        self.formattedAddress = formattedAddress
        
        if let addressComponents = result["address_components"] as? [[String: Any]] {
            streetNumber = get("street_number", from: addressComponents, ofType: .short)
            route = get("route", from: addressComponents, ofType: .short)
            postalCode = get("postal_code", from: addressComponents, ofType: .long)
            country = get("country", from: addressComponents, ofType: .long)
            countryCode = get("country", from: addressComponents, ofType: .short)
            
            locality = get("locality", from: addressComponents, ofType: .long)
            subLocality = get("sublocality", from: addressComponents, ofType: .long)
            administrativeArea = get("administrative_area_level_1", from: addressComponents, ofType: .long)
            administrativeAreaCode = get("administrative_area_level_1", from: addressComponents, ofType: .short)
            subAdministrativeArea = get("administrative_area_level_2", from: addressComponents, ofType: .long)
        }
        
        if let geometry = result["geometry"] as? [String: Any],
            let location = geometry["location"] as? [String: Any],
            let latitude = location["lat"] as? CLLocationDegrees,
            let longitude = location["lng"] as? CLLocationDegrees {
            coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    
    open var description: String {
        return "\nAddress: \(formattedAddress)\ncoordinate: (\(coordinate?.latitude ?? 0), \(coordinate?.longitude ?? 0))\n"
    }
}



private extension PlaceDetails {
    
    enum ComponentType: String {
        case short = "short_name"
        case long = "long_name"
    }
    
    /// Parses the element value with the specified type from the array or components.
    /// Example: `{ "long_name" : "90", "short_name" : "90", "types" : [ "street_number" ] }`
    ///
    /// - Parameters:
    ///   - component: The name of the element.
    ///   - array: The root component array to search from.
    ///   - ofType: The type of element to extract the value from.
    func get(_ component: String, from array: [[String: Any]], ofType: ComponentType) -> String? {
        return (array.first { ($0["types"] as? [String])?.contains(component) == true })?[ofType.rawValue] as? String
    }
}

private extension SearchPlaceDetails {
    
    enum ComponentType: String {
        case short = "short_name"
        case long = "long_name"
    }
    
    /// Parses the element value with the specified type from the array or components.
    /// Example: `{ "long_name" : "90", "short_name" : "90", "types" : [ "street_number" ] }`
    ///
    /// - Parameters:
    ///   - component: The name of the element.
    ///   - array: The root component array to search from.
    ///   - ofType: The type of element to extract the value from.
    func get(_ component: String, from array: [[String: Any]], ofType: ComponentType) -> String? {
        return (array.first { ($0["types"] as? [String])?.contains(component) == true })?[ofType.rawValue] as? String
    }
}

open class GooglePlacesSearchController: UISearchController, UISearchBarDelegate {
    
    convenience public init(delegate: GooglePlacesAutocompleteViewControllerDelegate, apiKey: String, placeType: PlaceType = .all, coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid, radius: CLLocationDistance = 0, searchBarPlaceholder: String = "Enter Address", location:CLLocation?) {
        assert(!apiKey.isEmpty, "Provide your API key")
        assert(location != nil, "Provide your current location")
        
        let gpaViewController = GooglePlacesAutocompleteContainer(
            delegate: delegate,
            apiKey: apiKey,
            placeType: placeType,
            coordinate: (location?.coordinate)!,
            radius: radius,
            location: location!
        )
        
        self.init(searchResultsController: gpaViewController)
        
        self.searchResultsUpdater = gpaViewController
        self.hidesNavigationBarDuringPresentation = false
        self.definesPresentationContext = true
        self.searchBar.placeholder = searchBarPlaceholder
    }
}

public protocol GooglePlacesAutocompleteViewControllerDelegate: class {
    func viewController(didAutocompleteWith place: SearchPlaceDetails)
}

open class GooglePlacesAutocompleteContainer: UITableViewController {
    private weak var delegate: GooglePlacesAutocompleteViewControllerDelegate?
    private var apiKey: String = ""
    private var placeType: PlaceType = .all
    private var coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
    private var radius: Double = 0.0
    private let cellIdentifier = String(describing: LocationSearchTableViewCell.self)
    private var location:CLLocation?
    private var places = [SearchPlaceDetails]() {
        didSet { tableView.reloadData() }
    }
    
    convenience init(delegate: GooglePlacesAutocompleteViewControllerDelegate, apiKey: String, placeType: PlaceType = .all, coordinate: CLLocationCoordinate2D, radius: Double, location:CLLocation) {
        self.init()
        self.delegate = delegate
        self.apiKey = apiKey
        self.placeType = placeType
        self.coordinate = coordinate
        self.radius = radius
        self.location = location
        let bundle = Bundle(for: LocationSearchTableViewCell.self)
        
        self.tableView.register(UINib(nibName: String(describing: LocationSearchTableViewCell.self), bundle: bundle), forCellReuseIdentifier:String(describing: LocationSearchTableViewCell.self))
        self.tableView.separatorStyle = .none
    }
}

extension GooglePlacesAutocompleteContainer {
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count
    }
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? LocationSearchTableViewCell
        let place = places[indexPath.row]
        cell?.titleLabel.text = place.mainAddress
        cell?.subTitleLable.text = place.secondaryAddress
        cell?.mileLabel.text = self.location?.getMile(location: place.location)
        return cell!
    }
    
    open override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let place = places[indexPath.row]
        self.delegate?.viewController(didAutocompleteWith: place)
    }
}

extension GooglePlacesAutocompleteContainer: UISearchBarDelegate, UISearchResultsUpdating {
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard !searchText.isEmpty else { places = []; return }
        let parameters = getParameters(for: searchText)

        GooglePlacesRequestHelpers.getTextSearch(with: parameters) {
            self.places = $0
        }
    }
    
    public func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else { places = []; return }
        let parameters = getParameters(for: searchText)
        
        GooglePlacesRequestHelpers.getTextSearch(with: parameters) {
            self.places = $0
        }
    }
    
    private func getParameters(for text: String) -> [String: String] {
        var params = [
            "query": text,
            "key": apiKey,
            "language": "en"
        ]
//        "query": text,
        // "types": placeType.rawValue,
        if CLLocationCoordinate2DIsValid(coordinate) {
            params["location"] = "\(coordinate.latitude),\(coordinate.longitude)"
            
            if radius > 0 {
                params["radius"] = "\(radius)"
            }
        }
        
        return params
    }
}

private class GooglePlacesRequestHelpers {
    
    static func doRequest(_ urlString: String, params: [String: String], completion: @escaping (NSDictionary) -> Void) {
        var components = URLComponents(string: urlString)
        components?.queryItems = params.map { URLQueryItem(name: $0, value: $1) }
        
        guard let url = components?.url else { return }
        
        let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            if let error = error {
                print("GooglePlaces Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data, let response = response as? HTTPURLResponse else {
                print("GooglePlaces Error: No response from API")
                return
            }
            
            guard response.statusCode == 200 else {
                print("GooglePlaces Error: Invalid status code \(response.statusCode) from API")
                return
            }
            
            let object: NSDictionary?
            do {
                object = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary
            } catch {
                object = nil
                print("GooglePlaces Error")
                return
            }
            
            guard object?["status"] as? String == "OK" else {
                print("GooglePlaces API Error: \(object?["status"] ?? "")")
                return
            }
            
            guard let json = object else {
                print("GooglePlaces Parse Error")
                return
            }
            
            // Perform table updates on UI thread
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                let trimJson = NSMutableDictionary.init(dictionary: json)
                trimJson.removeObjects(forKeys: ["html_attributions","status","next_page_token"])
                completion(trimJson)
            }
        })
        
        task.resume()
    }
    
    static func getPlaces(with parameters: [String: String], completion: @escaping ([Place]) -> Void) {
        doRequest(
            "https://maps.googleapis.com/maps/api/place/autocomplete/json",
            params: parameters,
            completion: {
                guard let predictions = $0["predictions"] as? [[String: Any]] else { return }
                completion(predictions.map { Place(prediction: $0) })
        }
        )
    }
    static func getTextSearch(with parameters: [String: String], completion: @escaping ([SearchPlaceDetails]) -> Void) {
        doRequest(
            "https://maps.googleapis.com/maps/api/place/textsearch/json",
            params: parameters,
            completion: {
                guard let predictions = $0["results"] as? [[String: Any]] else { return }
                completion(predictions.map { SearchPlaceDetails(prediction: $0) })
        }
        )
    }
    static func getPlaceDetails(id: String, apiKey:
        
        String, completion: @escaping (PlaceDetails?) -> Void) {
        doRequest(
            "https://maps.googleapis.com/maps/api/place/details/json",
            params: [ "placeid": id, "key": apiKey ],
            completion: { completion(PlaceDetails(json: $0 as? [String: Any] ?? [:])) }
        )
    }
}

extension CLLocation {
    func getMile(location:CLLocation) -> String {
        return "\((self.distance(from: location)/1609.34).rounded(toPlaces: 1)) m"
    }
}

extension Double {
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
