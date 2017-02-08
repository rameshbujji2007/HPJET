//
//  ViewController.swift
//  HPJET
//
//  Created by Kanakaraju Chinnam on 1/25/17.
//  Copyright © 2017 ABC. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import UserNotifications

class ViewController: UIViewController {

    
    @IBOutlet var mapView: MKMapView!
    
    fileprivate var locations = [MKPointAnnotation]()
    
    var locationManager: CLLocationManager = CLLocationManager()
    var monitoredRegions: Dictionary<String, NSDate> = [:]
    
    var enterRegion = CLRegion()
    var exitRegion = CLRegion()
    
    @IBAction func zoomToCurrentLocation(sender: AnyObject) {
        
        mapView.zoomToUserLocation()
    }
    
    // MARK: - User Notifications Methods
    
    func requestAuthorization(completionHandler: @escaping (_ success: Bool) -> ()) {
        
        // Request Authorization
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (success, error) in
            if let error = error {
                print("Request Authorization Failed (\(error), \(error.localizedDescription))")
            }
            
            completionHandler(success)
        }
    }
    
    
    func scheduleNotification(withlatitude:Double, longitude:Double, title:String, region:CLRegion) {
        
        
        let coordinates = CLLocationCoordinate2D(latitude: withlatitude,longitude: longitude)
        print(coordinates)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.2, repeats: false)
        
        let content = UNMutableNotificationContent()
       // content.title = "HP Inc"
        //content.subtitle = "Connect to Printer"
        content.title = "Printer Profile Available"
        content.body = "A new printer profile is available for download."
        content.body = title
        content.sound = UNNotificationSound.default()
        content.categoryIdentifier = "actionCategory"
        
        if let path = Bundle.main.path(forResource: "banner", ofType: "png") {
            let url = URL(fileURLWithPath: path)
            
            do {
                let attachment = try UNNotificationAttachment(identifier: "banner", url: url, options: nil)
                content.attachments = [attachment]
            } catch {
                print("The attachment was not loaded.")
            }
        }
        
        let request = UNNotificationRequest(identifier: "HP Inc_local_notification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().add(request) {(error) in
            if let error = error {
                print("Uh oh! We had an error: \(error)")
            }
        }
        
    }
    
    // MARK: - Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        UNUserNotificationCenter.current().delegate = self
        
            locationManager.requestWhenInUseAuthorization()
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.distanceFilter = kCLDistanceFilterNone
            locationManager.delegate = self
            locationManager.startUpdatingLocation()
        
        // setup mapView
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        self.createGeofence()
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // status is not determined
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
            // authorization were denied
        else if CLLocationManager.authorizationStatus() == .denied {
            showAlert(title: "Location services were previously denied. Please enable location services for this app in Settings.")
        }
            // we do have authorization
        else if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
    
    // MARK: - Creating Geofencing
    
    
    func createGeofence() {
        
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            
            for location in Locations.locations {
                
                let title = location.0
                let coordinate = location.1
                let regionRadius = 100.0
                
                // setup region
                let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: coordinate.latitude,longitude: coordinate.longitude), radius: regionRadius, identifier: title)
                
                locationManager.startMonitoring(for: region)
                
                // setup annotation
                let fenceAnnotation = MKPointAnnotation()
                fenceAnnotation.coordinate = coordinate;
                fenceAnnotation.title = "\(location.0)";
                mapView.addAnnotation(fenceAnnotation)
                
                // setup circle
                let circle = MKCircle(center: coordinate, radius: regionRadius)
                mapView.add(circle)
                
                
                let identifier = NSUUID().uuidString
                 
                 let notification = UNMutableNotificationContent()
                 notification.title = "Printer Profile Available"
                 notification.body = "A new printer profile is available for download."
                 notification.sound = UNNotificationSound.default()
                 notification.categoryIdentifier = "actionCategory"
                 
                 if let path = Bundle.main.path(forResource: "banner", ofType: "png") {
                 let url = URL(fileURLWithPath: path)
                 
                 do {
                 let attachment = try UNNotificationAttachment(identifier: "banner", url: url, options: nil)
                 notification.attachments = [attachment]
                 } catch {
                 print("The attachment was not loaded.")
                 }
                 }
                 
                 region.notifyOnExit = false
                 region.notifyOnEntry = true
                 let trigger = UNLocationNotificationTrigger(region: region, repeats: true)
                 
                 UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                 
                 UNUserNotificationCenter.current().add(
                 UNNotificationRequest(identifier: identifier, content: notification, trigger: trigger))
            }
        }
            
        else {
            print("System can't track regions")
        }
    }
    
    // MARK: - Helpers
    
    func showAlert(title: String) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
}


extension ViewController:MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let circleRenderer = CircleRenderer(overlay: overlay)
        return circleRenderer
    }

}


extension ViewController:CLLocationManagerDelegate{
    
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
       // let lat = (region as! CLCircularRegion).center.latitude
        //let lng = (region as! CLCircularRegion).center.longitude

        self.enterRegion = region
        
        monitoredRegions[region.identifier] = NSDate()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        
        //let lat = (region as! CLCircularRegion).center.latitude
        //let lng = (region as! CLCircularRegion).center.longitude
        
        self.exitRegion = region
     
        monitoredRegions.removeValue(forKey: region.identifier)
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        
        let lat = (region as! CLCircularRegion).center.latitude
        let lng = (region as! CLCircularRegion).center.longitude
        let radius = (region as! CLCircularRegion).radius
        
        
        print("Starting monitoring for region \(region) lat \(lat) lng \(lng) of radius \(radius)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            print("Requesting State for region \(region) lat \(lat) lng \(lng)")
            
            self.locationManager.requestState(for: region)
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        
        print("State for region " + region.identifier)
        if state == CLRegionState.inside {
            print("In \(region.identifier)")
            // Notify
        }
        else if state == CLRegionState.outside {
            print("Not in \(region.identifier)")
            // Notify
        }
        else {
            print("Not determined")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        
        print("Monitoring region " + region!.identifier + " failed " + error.localizedDescription)
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // let userLocation:CLLocation = locations[0]
        let userLocation: CLLocation = locations[locations.count - 1]
        
        let lat = userLocation.coordinate.latitude;
        let long = userLocation.coordinate.longitude;
        
         print("locations = \(lat) \(long)")
        
        
        
        if UIApplication.shared.applicationState == .active {
            mapView.showAnnotations(self.locations, animated: true)
            
            updateRegionsWithLocation(location: locations[0])
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager failed with the following error: \(error)")
        
    }
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        // App may no longer be authorized to obtain location
        //information. Check status here and respond accordingly.
    }
    
    // MARK: - Comples business logic
   
    func updateRegionsWithLocation(location: CLLocation) {
        
        let long = location.coordinate.longitude
        let lat = location.coordinate.latitude;
        
        let regionMaxVisiting = 10.0
        var regionsToDelete: [String] = []
        
        print(monitoredRegions)
        
        for regionIdentifier in monitoredRegions.keys {
            if NSDate().timeIntervalSince(monitoredRegions[regionIdentifier]! as Date) > regionMaxVisiting {
                
                self.scheduleNotification(withlatitude: lat, longitude: long, title: regionIdentifier, region: self.enterRegion)

                regionsToDelete.append(regionIdentifier)
            }
        }
        
        for regionIdentifier in regionsToDelete {
            monitoredRegions.removeValue(forKey: regionIdentifier)
        }
    }
    
}


extension ViewController:UNUserNotificationCenterDelegate {
    
    //for displaying notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler([.alert,.badge])
    }
    
    // For handling tap and user actions
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case "Ok":
            print("OK  Tapped")
            
            let baseUrl = URL(string: "http://10.30.2.24:3000/firstprofile" as String)
            
            if UIApplication.shared.canOpenURL(baseUrl!) {
                UIApplication.shared.open(baseUrl!, completionHandler: { (success) in
                    print("Settings opened: \(success)")
                })
            }
            
        case "Cancel":
            print("CANCEL  Tapped")
        default:
            break
        }
        completionHandler()
    }
}


class CircleRenderer: MKCircleRenderer {
    override func fillPath(_ path: CGPath, in context: CGContext) {
        let rect: CGRect = path.boundingBox
        context.addPath(path)
        context.clip()
        let gradientLocations: [CGFloat]  = [0.6, 1.0]
        let gradientColors: [CGFloat] = [1.0, 1.0, 1.0, 0.25, 0.0, 1.0, 0.0, 0.25]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let gradient = CGGradient(colorSpace: colorSpace, colorComponents: gradientColors, locations: gradientLocations, count: 2) else { return }
        
        let gradientCenter = CGPoint(x: rect.midX, y: rect.midY)
        let gradientRadius = min(rect.size.width, rect.size.height) / 2
        context.drawRadialGradient(gradient, startCenter: gradientCenter, startRadius: 0, endCenter: gradientCenter, endRadius: gradientRadius, options: .drawsAfterEndLocation)
    }
}

class Locations {
    static let locations:[String:CLLocationCoordinate2D] = [
        "HP Inc's": CLLocationCoordinate2D(latitude: 17.4223440630888, longitude: 78.3792699591678)
    ]
}


extension MKMapView {
    func zoomToUserLocation() {
        guard let coordinate = userLocation.location?.coordinate else { return }
        let region = MKCoordinateRegionMakeWithDistance(coordinate, 5000, 5000)
        setRegion(region, animated: true)
    }
}
