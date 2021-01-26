//
//  ViewController.swift
//  MapKit
//
//  Created by user191603 on 1/22/21.
//

import UIKit
import MapKit
import Alamofire
import SWXMLHash
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager()
    var lat = [String]()
    var log = [String]()
    var ic = [String]()
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if !(annotation is MKPointAnnotation) {
            return nil
        }
        
        let annotationIdentifier = "AnnotationIdentifier"
     var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView!.canShowCallout = true
        }
        else {
            annotationView!.annotation = annotation
        }
        
     var pinImage = UIImage(named: "car")
//        let size = CGSize(width: 38, height: 44)
//                    UIGraphicsBeginImageContext(size)
//                    UIImage(named: "car")?.draw(in: CGRect(origin: .zero, size: size))
//        pinImage = UIGraphicsGetImageFromCurrentImageContext()
//                    UIGraphicsEndImageContext()
       
        var x = lat.index(of: String((annotationView?.annotation?.coordinate.latitude)!))
        print(x)
        var y = log.index(of: String((annotationView?.annotation?.coordinate.longitude)!))
        print(y)
        if(x == y && x != nil){
            
            DispatchQueue.main.async {
                let request = NSMutableURLRequest(url: URL(string: "https://xp1.siteseer.com/SiteSeer/SDSImages/" + self.ic[x!])!)
                               request.httpMethod = "GET"
                               let session = URLSession(configuration: URLSessionConfiguration.default)
                               let dataTask = session.dataTask(with: request as URLRequest) { (data, response, error) in
                                   if error == nil {
           
                              
                                    pinImage = UIImage(data: data!, scale: UIScreen.main.scale
                                    )
                                    
                                            let size = CGSize(width: 32, height: 32)
                                                        UIGraphicsBeginImageContext(size)
                                    UIImage(data: data!, scale: UIScreen.main.scale
                                    )?.draw(in: CGRect(origin: .zero, size: size))
                                            pinImage = UIGraphicsGetImageFromCurrentImageContext()
                                                        UIGraphicsEndImageContext()
                                       
                                    annotationView!.image = pinImage
                                   }
                               }
           
                               dataTask.resume()
                   }
            
        }
        
        return annotationView
        
    }


    override func viewDidAppear(_ animated: Bool) {
           super.viewDidAppear(animated)
    
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
           determineCurrentLocation()
       }
       
       func determineCurrentLocation()
       {
           locationManager.requestWhenInUseAuthorization()
           
          if CLLocationManager.locationServicesEnabled() {
               
               locationManager.startUpdatingLocation()
           }
       }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.mapType = .mutedStandard
       
        AF.request("https://xp1.siteseer.com/SiteSeer_Mirror/Forms/MapperAPI.aspx?cmd=SiteSeerAPI&prm=model:6,user:andy.straker@siteseer.com,token:dn0n3abyeiaru445jkpjdr55,m:GetLayer,latUL=33.94,latBR=33.90,lonUL=-84.3810,lonBR=-84.29,layer=270", parameters: nil) //Alamofire defaults to GET requests
             .response { response in
                if let data = response.data {
                  print(data) // if you want to check XML data in debug window.
                  var xml = SWXMLHash.parse(data)
                  
                    print(xml["ret"]["result"]["pt"][0])
                    
                    let items = xml["ret"]["result"]["pt"]
                    
                    for item in items.all {
                        
                        print(item["la"].element!.text)
                        
                        let annotation = CustomPointAnnotation()
                        annotation.coordinate = CLLocationCoordinate2D(latitude: Double(item["la"].element!.text)!, longitude: Double(item["lo"].element!.text)!)
                        self.lat.append(item["la"].element!.text)
                        self.log.append(item["lo"].element!.text)
                        self.ic.append(item["ic"].element!.text)
                        
                        
                        annotation.title = item["nm"].element!.text
                         annotation.subtitle = item["id"].element!.text
                         DispatchQueue.main.async {
                             self.mapView.addAnnotation(annotation)

                         }
                        
                    }
                    
                }
             }
        
        
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        print(view.annotation?.coordinate.latitude)
        print(view.annotation?.coordinate.longitude)
    }
   
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        print("Updating location")
        // Call stopUpdatingLocation() to stop listening for location updates,
        // other wise this function will be called every time when user location changes.
       // manager.stopUpdatingLocation()
        
        let center = CLLocationCoordinate2D(latitude: 33.919867, longitude: -84.3527792)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
        
        mapView.setRegion(region, animated: true)
        
        // Drop a pin at user's Current Location
        let myAnnotation: MKPointAnnotation = MKPointAnnotation()
        myAnnotation.coordinate = CLLocationCoordinate2DMake(userLocation.coordinate.latitude, userLocation.coordinate.longitude);
        myAnnotation.title = "Current location"
        mapView.addAnnotation(myAnnotation)
        
        
        
        
    }
   
    

        func locationManager(manager: CLLocationManager, didFailWithError error: NSError)
        {
            print("Error \(error)")
        }


}

extension MKMapView {
    var zoomLevel: Double {
        get {
            return log2(360 * (Double(self.frame.size.width / 256) / self.region.span.longitudeDelta)) + 1
        }

        set (newZoomLevel){
            setCenterCoordinate(coordinate:self.centerCoordinate, zoomLevel: newZoomLevel, animated: false)
        }
    }
    func centerMapOnLocation(_ location: CLLocation, mapView: MKMapView) {
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                  latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    private func setCenterCoordinate(coordinate: CLLocationCoordinate2D, zoomLevel: Double, animated: Bool) {
        let span = MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 360 / pow(2, zoomLevel) * Double(self.frame.size.width) / 256)
        setRegion(MKCoordinateRegion(center: coordinate, span: span), animated: animated)
    }
}


