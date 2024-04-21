//
//  ViewController.swift
//  WeatherOnMap
//
//  Created by Mustafa on 4/13/24.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate {
    
    private let map: MKMapView = {
        let map = MKMapView()
        return map
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(map)
        map.delegate = self
        //title = "Home"
        
        LocationManager.shared.getUserLocation { [weak self] location in
            DispatchQueue.main.async {
                guard let strongSelf = self else {
                    return
                }
                strongSelf.addMapPin(with: location)
                strongSelf.map.setRegion(MKCoordinateRegion(center: location.coordinate,
                                                            span: MKCoordinateSpan(
                                                                latitudeDelta: 0.7,
                                                                longitudeDelta: 0.7)),
                                         animated: true)
            }
        }
        for (_, (latitude, longitude)) in usCapitalsCoordinates {
            addMapPin(with: CLLocation(latitude: latitude, longitude: longitude))
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
    }
    
    func addMapPin(with location: CLLocation) {
        let pin = MKPointAnnotation()
        pin.coordinate = location.coordinate
        LocationManager.shared.resolveLocationName(with: location) { locationName in
            pin.title = locationName
        }
        map.addAnnotation(pin)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else { return }
        requestWeatherForLocation(with: CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)) { weatherSummary in
            guard let degrees = Double(weatherSummary) else {
                print("Invalid input. Unable to convert to double.")
                return
            }
            var message = ""
            if(degrees >= 80.0) {
                message = weatherSummary + " Degrees Fahrenheit ☀️"
            } else if(degrees < 80.0 && degrees > 60.0) {
                message = weatherSummary + " Degrees Fahrenheit 💨"
            } else {
                message = weatherSummary + " Degrees Fahrenheit ❄️"
            }
            let alertController = UIAlertController(title: "The weather is...", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            DispatchQueue.main.async {
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func requestWeatherForLocation(with location: CLLocation, completion: @escaping (String) -> Void) {
        let long = location.coordinate.longitude
        let lat = location.coordinate.latitude
        let url = "https://api.pirateweather.net/forecast/5f4y5Dbf4HuNpYznV7zaUpEBDC4HFCf4/\(lat),\(long)"
        
        URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: {data, response, error in
            
            // validation
            guard let data = data, error == nil else {
                print("oops")
                return
            }
            // convert data to models/some object
            var json: WeatherResponse?
            do {
                json = try JSONDecoder().decode(WeatherResponse.self, from: data)
            }
            catch {
                print("error: \(error)")
            }
            
            guard let result = json else {
                return
            }
            
            completion(String(result.currently.temperature))
        }).resume()
    }
    
    let usCapitalsCoordinates: [(String, (Double, Double))] = [
        ("Montgomery", (32.361538, -86.279118)),
        ("Juneau", (58.301935, -134.419740)),
        ("Phoenix", (33.448457, -112.073844)),
        ("Little Rock", (34.736009, -92.331122)),
        ("Sacramento", (38.555605, -121.468926)),
        ("Denver", (39.7391667, -104.984167)),
        ("Hartford", (41.767, -72.677)),
        ("Dover", (39.161921, -75.526755)),
        ("Tallahassee", (30.4518, -84.27277)),
        ("Atlanta", (33.76, -84.39)),
        ("Honolulu", (21.30895, -157.826182)),
        ("Boise", (43.613739, -116.237651)),
        ("Springfield", (39.78325, -89.650373)),
        ("Indianapolis", (39.790942, -86.147685)),
        ("Des Moines", (41.590939, -93.620866)),
        ("Topeka", (39.04, -95.69)),
        ("Frankfort", (38.197274, -84.86311)),
        ("Baton Rouge", (30.45809, -91.140229)),
        ("Augusta", (44.323535, -69.765261)),
        ("Annapolis", (38.972945, -76.501157)),
        ("Boston", (42.2352, -71.0275)),
        ("Lansing", (42.7335, -84.5467)),
        ("Saint Paul", (44.95, -93.094)),
        ("Jackson", (32.32, -90.207)),
        ("Jefferson City", (38.572954, -92.189283)),
        ("Helena", (46.595805, -112.027031)),
        ("Lincoln", (40.809868, -96.675345)),
        ("Carson City", (39.160949, -119.753877)),
        ("Concord", (43.220093, -71.549127)),
        ("Trenton", (40.221741, -74.756138)),
        ("Santa Fe", (35.667231, -105.964575)),
        ("Albany", (42.659829, -73.781339)),
        ("Raleigh", (35.771, -78.638)),
        ("Bismarck", (48.813343, -100.779004)),
        ("Columbus", (39.962245, -83.000647)),
        ("Oklahoma City", (35.482309, -97.534994)),
        ("Salem", (44.931109, -123.029159)),
        ("Harrisburg", (40.269789, -76.875613)),
        ("Providence", (41.82355, -71.422132)),
        ("Columbia", (34.0, -81.035)),
        ("Pierre", (44.367966, -100.336378)),
        ("Nashville", (36.165, -86.784)),
        ("Austin", (30.266667, -97.75)),
        ("Salt Lake City", (40.7547, -111.892622)),
        ("Montpelier", (44.26639, -72.57194)),
        ("Richmond", (37.54, -77.46)),
        ("Olympia", (47.042418, -122.893077)),
        ("Charleston", (38.349497, -81.633294)),
        ("Madison", (43.074722, -89.384444)),
        ("Cheyenne", (41.145548, -104.802042))
    ]
    
    struct WeatherResponse: Codable {
        let latitude: Float
        let longitude: Float
        let timezone: String
        let offset: Int
        let elevation: Int
        let currently: CurrentWeather
        let minutely: MinutelyWeather
        let hourly: HourlyWeather
        let daily: DailyWeather
    }
    
    struct CurrentWeather: Codable {
        let time: Int
        let summary: String
        let icon: String
        let nearestStormDistance: Int
        let nearestStormBearing: Int
        let precipIntensity: Int
        let precipProbability: Int
        let temperature: Double
        let apparentTemperature: Double
        let dewPoint: Double
        let humidity: Double
        let pressure: Double
        let windSpeed: Double
        let windGust: Double
        let windBearing: Int
        let cloudCover: Double
        let uvIndex: Double
        let visibility: Double
        let ozone: Double
    }
    
    struct MinutelyWeather: Codable {
        let summary: String
        let icon: String
        let data: [MinutelyWeatherEntry]
    }
    
    struct MinutelyWeatherEntry: Codable {
        let time: Int
        let precipIntensity: Int
        let precipProbability: Int
        let precipIntensityError: Int
        let precipType: String
    }
    
    struct HourlyWeather: Codable {
        let summary: String
        let icon: String
        let data: [HourlyWeatherEntry]
    }
    
    struct HourlyWeatherEntry: Codable {
        let time: Int
        let summary: String
        let icon: String
        let precipIntensity: Float
        let precipProbability: Double
        let precipType: String?
        let temperature: Double
        let apparentTemperature: Double
        let dewPoint: Double
        let humidity: Double
        let pressure: Double
        let windSpeed: Double
        let windGust: Double
        let windBearing: Int
        let cloudCover: Double
        let uvIndex: Double
        let visibility: Double
        let ozone: Double
    }
    
    struct DailyWeather: Codable {
        let summary: String
        let icon: String
        let data: [DailyWeatherEntry]
    }
    
    struct DailyWeatherEntry: Codable {
        let time: Int
        let summary: String
        let icon: String
        let sunriseTime: Int
        let sunsetTime: Int
        let moonPhase: Double
        let precipIntensity: Float
        let precipIntensityMax: Float
        let precipIntensityMaxTime: Int
        let precipProbability: Double
        let precipType: String?
        let temperatureHigh: Double
        let temperatureHighTime: Int
        let temperatureLow: Double
        let temperatureLowTime: Int
        let apparentTemperatureHigh: Double
        let apparentTemperatureHighTime: Int
        let apparentTemperatureLow: Double
        let apparentTemperatureLowTime: Int
        let dewPoint: Double
        let humidity: Double
        let pressure: Double
        let windSpeed: Double
        let windGust: Double
        let windGustTime: Int
        let windBearing: Int
        let cloudCover: Double
        let uvIndex: Double
        let uvIndexTime: Int
        let visibility: Double
        let temperatureMin: Double
        let temperatureMinTime: Int
        let temperatureMax: Double
        let temperatureMaxTime: Int
        let apparentTemperatureMin: Double
        let apparentTemperatureMinTime: Int
        let apparentTemperatureMax: Double
        let apparentTemperatureMaxTime: Int
    }
    
}
