import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool mapToggle = false;
  bool sitiosToggle = false;
  bool resetToggle = false;

  var currentLocation;

  var sitios = [];

  var sitioActual;
  var currentBearing;

  GoogleMapController mapController;

  void initState() {
    super.initState();
    setState(() {
      mapToggle = true;
      populateClients();
    });
  }

  populateClients() {
    sitios = [];
    Firestore.instance.collection('markers').getDocuments().then((docs) {
      if (docs.documents.isNotEmpty) {
        setState(() {
          sitiosToggle = true;
        });
        for (int i = 0; i < docs.documents.length; ++i) {
          sitios.add(docs.documents[i].data);
          initMarker(docs.documents[i].data);
        }
      }
    });
  }

  initMarker(sitio) {
    mapController.clearMarkers().then((val) {
      mapController.addMarker(MarkerOptions(
          position:
          LatLng(sitio['location'].latitude, sitio['location'].longitude),
          draggable: false,
          infoWindowText: InfoWindowText(sitio['nombreSitio'], 'Cool')));
    });
  }

  Widget siteCard(sitio) {
    return Padding(
        padding: EdgeInsets.only(left: 2.0, top: 10.0),
        child: InkWell(
            onTap: () {
              setState(() {
                sitioActual = sitio;
                currentBearing = 90.0;
              });
              zoomInMarker(sitio);
            },
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(5.0),
              child: Container(
                  height: 100.0,
                  width: 125.0,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5.0),
                      color: Colors.white),
                  child: Center(child: Text(sitio['nombreSitio']))),
            )));
  }

  zoomInMarker(sitio) {
    mapController
        .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(
            sitio['location'].latitude, sitio['location'].longitude),
        zoom: 17.0,
        bearing: 90.0,
        tilt: 45.0)))
        .then((val) {
      setState(() {
        resetToggle = true;
      });
    });
  }

  markerInicial() {
    mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(51.0533076, 5.9260656), zoom: 5.0))).then((val) {//Alemania, Berlin
      setState(() {
        resetToggle = false;
      });
    });
  }

  girarDerecha() {
    mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
            target: LatLng(sitioActual['location'].latitude,
                sitioActual['location'].longitude
            ),
            bearing: currentBearing == 360.0 ? currentBearing : currentBearing + 90.0,
            zoom: 17.0,
            tilt: 45.0
        )
    )
    ).then((val) {
      setState(() {
        if(currentBearing == 360.0) {}
        else {
          currentBearing = currentBearing + 90.0;
        }
      });
    });
  }

  giroIzquierda() {
    mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
            target: LatLng(sitioActual['location'].latitude,
                sitioActual['location'].longitude
            ),
            bearing: currentBearing == 0.0 ? currentBearing : currentBearing - 90.0,
            zoom: 17.0,
            tilt: 45.0
        )
    )
    ).then((val) {
      setState(() {
        if(currentBearing == 0.0) {}
        else {
          currentBearing = currentBearing - 90.0;
        }
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Flutter+Markers+FireCloud'),
        ),
        body: Column(
          children: <Widget>[
            Stack(
              children: <Widget>[
                Container(
                    height: MediaQuery.of(context).size.height - 80.0,
                    width: double.infinity,
                    child: mapToggle
                        ? GoogleMap(
                      initialCameraPosition: CameraPosition(
                          target: LatLng(48.8583998, 2.2932227),//Paris
                          zoom: 15
                      ),
                      onMapCreated: onMapCreated,
                      myLocationEnabled: true,
                      mapType: MapType.hybrid,
                      compassEnabled: true,
                      trackCameraPosition: true,
                    )
                        : Center(
                        child: Text(
                          'Revisa datos, gps, wifi..',
                          style: TextStyle(fontSize: 20.0),
                        ))),
                //cajas markers segun numero de marcadores
                Positioned(
                    top: MediaQuery.of(context).size.height - 150.0,
                    left: 10.0,
                    child: Container(
                        height: 50.0,
                        width: MediaQuery.of(context).size.width,
                        child: sitiosToggle
                            ? ListView(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.all(8.0),
                          children: sitios.map((element) {
                            return siteCard(element);
                          }).toList(),
                        )
                            : Container(height: 1.0, width: 1.0))),
                //Fin container segun numero de marcadores
                //creamos tres botones giro izquierda derecha i resetar camara
                resetToggle
                    ? Positioned(
                    top: MediaQuery.of(context).size.height -
                        (MediaQuery.of(context).size.height -
                            50.0),
                    right: 15.0,
                    child: FloatingActionButton(
                      onPressed: markerInicial,
                      mini: true,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.refresh),
                    ))
                    : Container(),
                resetToggle
                    ? Positioned(
                    top: MediaQuery.of(context).size.height -
                        (MediaQuery.of(context).size.height -
                            50.0),
                    right: 60.0,
                    child: FloatingActionButton(
                        onPressed: girarDerecha,
                        mini: true,
                        backgroundColor: Colors.green,
                        child: Icon(Icons.rotate_left
                        ))
                )
                    : Container(),
                resetToggle
                    ? Positioned(
                    top: MediaQuery.of(context).size.height -
                        (MediaQuery.of(context).size.height -
                            50.0),
                    right: 110.0,
                    child: FloatingActionButton(
                        onPressed: giroIzquierda,
                        mini: true,
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.rotate_right)
                    ))
                    : Container()
              ],
            )
          ],
        ));
  }

  void onMapCreated(controller) {
    setState(() {
      mapController = controller;
    });
  }
}