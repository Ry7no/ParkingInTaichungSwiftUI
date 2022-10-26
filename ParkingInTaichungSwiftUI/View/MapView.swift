//
//  MapView.swift
//  ParkingInTaichungSwiftUI
//
//  Created by @Ryan on 2022/10/24.
//

import SwiftUI
import CoreLocation
import GoogleMaps
import GoogleMapsUtils

struct MapView: View {
    
    @EnvironmentObject private var dataManager: DataManager
//    @StateObject private var dataManager = DataManager()

    var body: some View {
        
        ZStack {
            
            GoogleMapAdapterView()
            
            Button {

                DispatchQueue.main.async {
                    dataManager.fetchedParkingLots.removeAll()
                    dataManager.getParkingData()
                    dataManager.isUpdatingMapView = true
                }


            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 15).bold())
                    .rotationEffect(Angle(degrees: 90))
                    .scaledToFit()
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 60, height: 60)
                    .background(content: {
                        Circle()
                            .fill(.thinMaterial)
                    })
                    .clipShape(Circle())
                    .overlay {
                        Circle().stroke(lineWidth: 2).foregroundColor(.white)
                    }
            }
            .offset(x: UIScreen.main.bounds.width/2.5, y: UIScreen.main.bounds.height/3.2)

        }

        
    }
}

struct GoogleMapAdapterView: UIViewRepresentable {
    
//    @EnvironmentObject private var dataManager: DataManager
    @ObservedObject var dataManager = DataManager()
    @ObservedObject var locationManager = LocationManager()
    
    private var clusterManager: GMUClusterManager!
     
    typealias UIViewType = GMSMapView
    
    private static let defaultCamera = GMSCameraPosition.camera(withLatitude: 24.157788, longitude: 120.668099, zoom: 10.0)
    private let mapView : GMSMapView
//    private weak var mapDelegate: GMSMapViewDelegateWrapper?
    
    @State var parkingLotsAll: [ParkingLot] = []
    @State var isUpdatingMap: Bool = true
    
    init() {
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: GMSCameraPosition.camera(withTarget: CLLocationCoordinate2D(latitude: 25.044633, longitude: 121.559722), zoom: 18))
        mapView.isMyLocationEnabled = true
        self.mapView = mapView
//        let mapDelegateWrapper = GMSMapViewDelegateWrapper()
//        self.mapDelegate = mapDelegateWrapper
//        self.mapView.delegate = mapDelegateWrapper
//        let iconGenerator = GMUDefaultClusterIconGenerator()
//        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
//        let renderer = GMUDefaultClusterRenderer(mapView: mapView,
//                                                 clusterIconGenerator: iconGenerator)
//        clusterManager = GMUClusterManager(map: mapView, algorithm: algorithm,
//                                           renderer: renderer)
//        clusterManager.setMapDelegate(mapView.delegate)
        dataManager.isUpdatingMapView = true
        dataManager.isReloadingCamera = true
        dataManager.getParkingData()
    }
    
    /// Creates a `UIView` instance to be presented.
    func makeUIView(context: Self.Context) -> UIViewType {
        
        let zoom = calculateZoom(radius: Float(dataManager.radius))
        let camera = GMSCameraPosition.camera(withTarget: locationManager.userPosition, zoom: zoom)
        let mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        
        
        if #available(iOS 13.0, *) {
            
            if UITraitCollection.current.userInterfaceStyle == .dark {
                
                do {
                    // Set the map style by passing the URL of the local file.
                    if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
                        mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
                    } else {
                        NSLog("Unable to find style.json")
                    }
                } catch {
                    NSLog("One or more of the map styles failed to load. \(error)")
                }
            }
        }
        
        
        mapView.delegate = context.coordinator
        mapView.setMinZoom(13, maxZoom: 23)
        mapView.settings.myLocationButton = true
        mapView.isMyLocationEnabled = true
        mapView.animate(toZoom: zoom)

        return mapView
    }

    /// Updates the presented `UIView` (and coordinator) to the latest
    /// configuration.
    func updateUIView(_ mapView: UIViewType , context: Self.Context) {
        
        if dataManager.isUpdatingMapView {

            DispatchQueue.main.async {
                
                mapView.clear()
//                clusterManager.clearItems()
                
                if dataManager.isReloadingCamera {
                    mapView.camera = GMSCameraPosition.camera(withTarget: locationManager.userPosition, zoom: 18)
                }

                print("dataManager.fetchedParkingLots.isEmpty: \(dataManager.fetchedParkingLots.isEmpty)")

                let parkingLot = dataManager.fetchedParkingLots
                
                for i in 0..<parkingLot.count {
                    
                    let parkingNumber = parkingLot[i].PS_ID
                    let parkingType = parkingLot[i].PS_type
                    let parkingLotLat = Double(parkingLot[i].PS_Lat) ?? 0.0
                    let parkingLotLng = Double(parkingLot[i].PS_Lng) ?? 0.0
                    let parkingLotPosition = CLLocationCoordinate2D(latitude: parkingLotLat, longitude: parkingLotLng)
                    
                    let parkingLotMarker = GMSMarker()
                    
                    parkingLotMarker.position = parkingLotPosition
                    let image = UIImage(named: parkingLot[i].status == "0" ? "greenDot" : "redDot")
                    parkingLotMarker.icon = image
                    
                    parkingLotMarker.map = mapView
                    parkingLotMarker.title = "[\(dataManager.parkingLotType(Type: parkingType))] #\(parkingNumber)"
//                    parkingLotMarker.snippet = ""
                    parkingLotMarker.accessibilityLabel = "\(i)"
                    parkingLotMarker.tracksInfoWindowChanges = false
//                    clusterManager.add(parkingLotMarker)
                }
                
//                clusterManager.cluster()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                    dataManager.isUpdatingMapView = false
                    dataManager.isReloadingCamera = false
                }

            }
        }
        
        
    }
    
   
    func update(cameraPosition: GMSCameraPosition) -> some View {
        mapView.animate(to: cameraPosition)
        return self
    }
    
    func update(items: [CLLocationCoordinate2D]) -> some View {
        // Creates a marker in the center of the map.
        // 1. clear old markers
        self.clusterManager.clearItems()
        // 2. check item not empty otherwise we have to return self.
        guard items.isEmpty == false else { return self}
        
        // 3. recreate you marker view. whether you use google-map-utilites or you use default GMSMarkerView
//        self.clusterManager.add(items)
        self.clusterManager.cluster()
        // 4. if you use the GMSMarker you have to add to `self.map`
        return self
    }
    
    func update(zoom level: Float) -> some View {
        mapView.animate(toZoom: level)
        return self
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(owner: self)
    }
    
    final class Coordinator: NSObject, GMSMapViewDelegate {
        
        let owner: GoogleMapAdapterView
        
        init(owner: GoogleMapAdapterView){
            self.owner = owner
        }
        
        func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {

            let latDouble = Double(marker.position.latitude)
            let longDouble = Double(marker.position.longitude)

            if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {  //if phone has an app
                
                if let url = URL(string: "comgooglemaps-x-callback://?saddr=&daddr=\(latDouble),\(longDouble)&directionsmode=driving") {
                    UIApplication.shared.open(url, options: [:])
                }}
            else {
                //Open in browser
                if let urlDestination = URL.init(string: "https://www.google.co.in/maps/dir/?saddr=&daddr=\(latDouble),\(longDouble)&directionsmode=driving") {
                    UIApplication.shared.open(urlDestination)
                }
            }
        }

}

@objc
class GMSMapViewDelegateWrapper: NSObject, GMSMapViewDelegate {
        
    var shouldHandleTap: Bool = true
    
    deinit {
        
    }
    
    func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {
        return shouldHandleTap
    }
    
    func mapView(_ mapView: GMSMapView, didTapMyLocation location: CLLocationCoordinate2D) {
        
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        print("Tap")
    }
    
//    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
//
//        let latDouble = Double(marker.position.latitude)
//        let longDouble = Double(marker.position.longitude)
//
//        if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {  //if phone has an app
//
//            if let url = URL(string: "comgooglemaps-x-callback://?saddr=&daddr=\(latDouble),\(longDouble)&directionsmode=driving") {
//                UIApplication.shared.open(url, options: [:])
//            }}
//        else {
//            //Open in browser
//            if let urlDestination = URL.init(string: "https://www.google.co.in/maps/dir/?saddr=&daddr=\(latDouble),\(longDouble)&directionsmode=driving") {
//                UIApplication.shared.open(urlDestination)
//            }
//        }
//    }
    
    
    
}

//struct gmapView: UIViewRepresentable {
//
//    @ObservedObject var dataManager = DataManager()
//    @ObservedObject var locationManager = LocationManager()
//
//    private var clusterManager: GMUClusterManager!
//
//    typealias UIViewType = GMSMapView
//
//
//    func makeUIView(context: Context) -> GMSMapView {
//
//        let camera = GMSCameraPosition.camera(withTarget: locationManager.userPosition, zoom: 18)
//        let mapView = GMSMapView.map(withFrame: .zero, camera: camera)
//        let zoom = calculateZoom(radius: Float(dataManager.radius))
//
//        if #available(iOS 13.0, *) {
//
//            if UITraitCollection.current.userInterfaceStyle == .dark {
//
//                do {
//                  // Set the map style by passing the URL of the local file.
//                  if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
//                    mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
//                  } else {
//                    NSLog("Unable to find style.json")
//                  }
//                } catch {
//                  NSLog("One or more of the map styles failed to load. \(error)")
//                }
//            }
//        }
//
//
////        mapView.delegate = context.coordinator
//        mapView.setMinZoom(13, maxZoom: 23)
//        mapView.settings.myLocationButton = true
//        mapView.isMyLocationEnabled = true
//        mapView.animate(toZoom: zoom)
//
//        // 300  16.5  // 700 1.7 // 800 1  //
//        // 1000 14.8
//        // 1800 13.9
//
//        return mapView
//    }
//
//
//    func updateUIView(_ uiView: GMSMapView, context: Context) {
//
////        let iconGenerator = GMUDefaultClusterIconGenerator()
////        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
////        let renderer = GMUDefaultClusterRenderer(mapView: uiView,
////                                                 clusterIconGenerator: iconGenerator)
////        self.clusterManager = GMUClusterManager(map: uiView,
////                                           algorithm: algorithm,
////                                           renderer: renderer)
////        self.clusterManager.setMapDelegate(uiView.delegate)
//
////        print("Button status: \(medDataModel.isStopUpdate)")
////        print(uiView.camera.zoom)
//
//            let zoom = calculateZoom(radius: Float(dataManager.radius))
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//
//                uiView.clear()
//                uiView.camera = GMSCameraPosition.camera(withTarget: locationManager.userPosition, zoom: zoom)
//
//                let circle = GMSCircle(position: locationManager.userPosition, radius: CLLocationDistance(dataManager.radius))
//                circle.fillColor = UIColor(white: 0.7, alpha: 0.3)
//                circle.strokeWidth = 3
//                circle.strokeColor = .orange
//                circle.map = uiView
//
//                if dataManager.fetchedParkingLots.isEmpty {
//                    dataManager.getParkingData()
//                }
//                clusterManager.clearItems()
//
//                let parkingLot = dataManager.fetchedParkingLots
//
//                for i in 0..<parkingLot.count {
//
//
//                    let parkingType = parkingLot[i].PS_type
//                    let parkingLotLat = Double(parkingLot[i].PS_Lat) ?? 0.0
//                    let parkingLotLng = Double(parkingLot[i].PS_Lng) ?? 0.0
//                    let parkingLotPosition = CLLocationCoordinate2D(latitude: parkingLotLat, longitude: parkingLotLng)
//
//                    let parkingLotMarker = GMSMarker()
//                    parkingLotMarker.position = parkingLotPosition
//                    parkingLotMarker.icon = createImage(Int(parkingType)!)
//
//                    parkingLotMarker.map = uiView
//                    parkingLotMarker.title = "[車位]"
//                    parkingLotMarker.accessibilityLabel = "\(i)"
//                    parkingLotMarker.tracksInfoWindowChanges = false
//                    clusterManager.add(parkingLotMarker)
//                }
//
//                clusterManager.cluster()
//
//            }
//        }
//    }
    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(owner: self)
//    }
    
    //    static func dismantleUIView(_ uiView: GMSMapView, coordinator: Coordinator) {
    //        uiView.removeObserver(coordinator, forKeyPath: "myLocation")
    //    }
    
//    final class Coordinator: NSObject, GMSMapViewDelegate {
//
//        let owner: gmapView
//
//        init(owner: gmapView){
//            self.owner = owner
//        }
//
//        func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
//
//            let latDouble = Double(marker.position.latitude)
//            let longDouble = Double(marker.position.longitude)
//
//            if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {  //if phone has an app
//
//                if let url = URL(string: "comgooglemaps-x-callback://?saddr=&daddr=\(latDouble),\(longDouble)&directionsmode=driving") {
//                    UIApplication.shared.open(url, options: [:])
//                }}
//            else {
//                //Open in browser
//                if let urlDestination = URL.init(string: "https://www.google.co.in/maps/dir/?saddr=&daddr=\(latDouble),\(longDouble)&directionsmode=driving") {
//                    UIApplication.shared.open(urlDestination)
//                }
//            }
//        }
//
////        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
////            print(1)
////            return true
////        }
//
////        func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
////            let callout = UIHostingController(rootView: MarkerView())
////            callout.view.frame = CGRect(x: 0, y: 0, width: mapView.frame.width - 60, height: 200)
////            return callout.view
////        }
//
//        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//            if let location = change?[.newKey] as? CLLocation, let mapView = object as? GMSMapView {
//                mapView.animate(toLocation: location.coordinate)
//            }
//        }
//    }
    
    // -x => Move Left, +x => Move Right
    // -y => Move up, +y => Move down
    
    // Float(16.5 - (medDataModel.radius - 300) * 0.0017)
    
    func calculateZoom(radius: Float) -> Float {
        
        var zoomValue: Float = 0
        
        if radius >= 300 && radius <= 500 {
            zoomValue = 16.5 - ((radius - 300) * 0.004)
        }
        else if radius > 500 && radius < 1000 {
            zoomValue = 15.8 - ((radius - 500) * 0.002)
        }
        else if radius >= 1000 && radius < 1200 {
            zoomValue = 14.8 - ((radius - 1000) * 0.001)
        }
        else if radius >= 1200 && radius <= 1800 {
            zoomValue = 14.5 - ((radius - 1200) * 0.001)
        }
        
        return Float(zoomValue)
    }
    
    func createOrangePin(_ count: Int) -> UIImage {
        
        let color = count > 100 ? UIColor.black : UIColor.red
        // select needed color
        let string = count < 100 ? " \(UInt(count))" : "\(UInt(count))"
        // the string to colorize
        let attrs: [NSAttributedString.Key: Any] = [.foregroundColor: color, .font: UIFont.boldSystemFont(ofSize: 14)]
        let attrStr = NSAttributedString(string: string, attributes: attrs)
        // add Font according to your need
        let image = UIImage(named: "OrangePin")!
        // The image on which text has to be added
        UIGraphicsBeginImageContext(image.size)
        image.draw(in: CGRect(x: CGFloat(count < 10 ? 0.6 : 4.5), y: CGFloat(-0.4), width: CGFloat(image.size.width), height: CGFloat(image.size.height)))
        let rect = CGRect(x: CGFloat(13.5), y: CGFloat(24), width: CGFloat(image.size.width), height: CGFloat(image.size.height))
        // -x => Move Left, +x => Move Right
        // -y => Move up, +y => Move down
        
        attrStr.draw(in: rect)
        
        let markerImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return markerImage
    }
    
    func createImage(_ count: Int) -> UIImage {
        
        let color = count > 100 ? UIColor.black : UIColor.red
        // select needed color
        let string = count < 100 ? " \(UInt(count))" : "\(UInt(count))"
        // the string to colorize
        let attrs: [NSAttributedString.Key: Any] = [.foregroundColor: color, .font: UIFont.systemFont(ofSize: 12)]
        let attrStr = NSAttributedString(string: string, attributes: attrs)
        // add Font according to your need
        let image = UIImage(named: "greenDot")!
        // The image on which text has to be added
        UIGraphicsBeginImageContext(image.size)
        image.draw(in: CGRect(x: CGFloat(count < 10 ? 0.6 : 4.5), y: CGFloat(-0.4), width: CGFloat(image.size.width), height: CGFloat(image.size.height)))
        let rect = CGRect(x: CGFloat(11.3), y: CGFloat(18), width: CGFloat(image.size.width), height: CGFloat(image.size.height))
        // -x => Move Left, +x => Move Right
        // -y => Move up, +y => Move down
        
        attrStr.draw(in: rect)
        
        let markerImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return markerImage
    }
    
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
