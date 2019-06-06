import 'package:flutter/material.dart';
import 'bottom-navbar-bloc.dart';
import'package:login/login_page.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
class BottomNavBarApp extends StatefulWidget {

  createState() => _BottomNavBarAppState();
}
enum ConfirmAction { CANCEL, ACCEPT }
class _BottomNavBarAppState extends State<BottomNavBarApp> {
  BottomNavBarBloc _bottomNavBarBloc;
  MapType _currentMapType = MapType.normal;
  GoogleMap googleMap;
  bool playing=false;
  Completer<GoogleMapController> _controller = Completer();
  LatLng _lastMapPosition = _center;
  Map<String,double> currentLocation=new Map();
  StreamSubscription<Map<String,double>> locationSubscription;
  Location location=new Location();
  String error;
  final Set<Marker> _markers = {};
  final Dependencies dependencies = new Dependencies();
  final type= TextEditingController();
  final description_panne= TextEditingController();
  static const LatLng _center = const LatLng(34.019190, -5.012127);
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();

  static bool paused;
  @override
  void initState() {
    super.initState();
    currentLocation['latitude']=0.0;
    currentLocation['longitude']=0.0;
    initPlatformState();
    // locationSubscription=location.onLocationChanged().listen(());
    locationSubscription=location.onLocationChanged().listen((Map<String,double> result)
    {
      setState(() {
        currentLocation=result;
      });
    });
    _bottomNavBarBloc = BottomNavBarBloc();
  }
  void initPlatformState() async {
    Map<String,double> my_location;
    try{
      my_location=await location.getLocation();
      error="";
    }on PlatformException catch(e)

    {
      if(e.code=='PERMISSION_DENIED')
      {
        error="Permission Denied";
      }
      else if(e.code=='PERMISSION_DENIED_NEVER_ASK')

        error='Permission denied =please turn On in settings';
      my_location=null;

    }
    setState(() {
      currentLocation=my_location;
    });
  }

  @override
  void dispose() {
    _bottomNavBarBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bonjour Mr '+LoginPage.us),
      ),
      body: StreamBuilder<NavBarItem>(
        stream: _bottomNavBarBloc.itemStream,
        initialData: _bottomNavBarBloc.defaultItem,
        builder: (BuildContext context, AsyncSnapshot<NavBarItem> snapshot) {
          switch (snapshot.data) {
            case NavBarItem.HOME:
              return _homeArea();
            case NavBarItem.ALERT:
              return _alertArea();
            case NavBarItem.SETTINGS:
              return _settingsArea();
          }
        },
      ),
      bottomNavigationBar: StreamBuilder(
        stream: _bottomNavBarBloc.itemStream,
        initialData: _bottomNavBarBloc.defaultItem,
        builder: (BuildContext context, AsyncSnapshot<NavBarItem> snapshot) {
          return BottomNavigationBar(
            fixedColor: Colors.blueAccent,
            currentIndex: snapshot.data.index,
            onTap: _bottomNavBarBloc.pickItem,
            items: [
              BottomNavigationBarItem(
                title: Text('Home'),
                icon: Icon(Icons.home),
              ),
              BottomNavigationBarItem(
                title: Text('Declarer Une Panne'),
                icon: Icon(Icons.settings),
              ),
              BottomNavigationBarItem(
                title: Text('Settings'),
                icon: Icon(Icons.settings),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _alertArea() {
    return  new SafeArea(
      top: false,
      bottom: false,
      child: new Form(
        key: _formKey,
        autovalidate: true,
        child: new ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          children: <Widget>[
            new TextFormField(
              decoration: const InputDecoration(
                icon: const Icon(Icons.settings),
                hintText: 'Type de Panne',
                labelText: 'Type',
              ),
              controller: type,
            ),
            new TextFormField(
              decoration: const InputDecoration(
                icon: const Icon(Icons.directions_bus),
                hintText: 'Enter Description',
                labelText: 'Desciption de panne',
              ),
              controller: description_panne,
              keyboardType: TextInputType.multiline,
            ),


            new Container(
                padding: const EdgeInsets.only(left: 40.0, top: 20.0),
                child: new RaisedButton(
                  child: const Text('Submit'),
                  onPressed: SavePanne,
                )),
          ],
        ),

      ),
    );
  }

  Widget _homeArea() {
    return new Scaffold(
      body: Stack(
        children: <Widget>[
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,

            ),
            mapType: _currentMapType,
            markers: _markers,
            onCameraMove: _onCameraMove,
            // polylines:_poly ,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.topRight,
              child: Column(
                children: <Widget> [
                  FloatingActionButton(
                    onPressed: ()
                    {
                     playing= !playing;
                     setState(() {

                     });
                    },
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    backgroundColor: Colors.green,
                    child: playing?new Icon(Icons.stop):new Icon(Icons.play_circle_outline),
                  ),
                  SizedBox(height: 16.0),
                  Text("00:00:00"),


                ],

                ),),),

        ],
      ),

    );

  }

  Widget _settingsArea() {
    return Center(
      child: Text(
        'Settings Screen',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.blue,
          fontSize: 25.0,
        ),
      ),

    );
  }
  void _onCameraMove(CameraPosition position) {
    _lastMapPosition = position.target;
  }

  void _onMapCreated(GoogleMapController controller){
    _controller.complete(controller);
    setState(() {
      print(currentLocation['latitude']);

       _markers.add(Marker(
        // This marker id can be anything that uniquely identifies each marker.

        markerId: MarkerId(LatLng(currentLocation['latitude'], currentLocation['longitude']).toString()),
        position: LatLng(currentLocation['latitude'], currentLocation['longitude']),
        infoWindow: InfoWindow(
          title: 'Ma position',
          snippet: '',
        ),
        icon: BitmapDescriptor.defaultMarker,
      ));
    });

  }
  void pause()
  {
    setState(() {
      if (dependencies.stopwatch.isRunning) {
        dependencies.stopwatch.stop();
      } else {
        dependencies.stopwatch.start();
      }
    });
  }
  void play()
  {

      setState(() {
        if (dependencies.stopwatch.isRunning) {
          print("${dependencies.stopwatch.elapsedMilliseconds}");
        } else {
          dependencies.stopwatch.reset();
        }
      });
  }


  void SavePanne() async{
    var url="http://bus365.alwaysdata.net/addPane.php";
    final f = new DateFormat('yyyy-MM-dd hh:mm:ss');
    final date=f.format(DateTime.now());
    print(date);
    print(currentLocation['latitude'].toString());
    print(description_panne.text);
    print(DateTime.now());
    final response= await http.post(url,body: {
      "type":type.text,
      "description":description_panne.text,
      'date':date.toString(),
      'lat':currentLocation['latitude'].toString(),
      'log':currentLocation['longitude'].toString()
    });
    var datauser = json.decode(response.body);
    print(datauser);
    if(datauser=="false")
      {
        setState(() {
          Fluttertoast.showToast(msg: "Panne Enregistre avec Success",gravity: ToastGravity.CENTER);
          type.clear();
          description_panne.clear();
        });
      }
  }
}
class ElapsedTime {
  final int hundreds;
  final int seconds;
  final int minutes;

  ElapsedTime({
    this.hundreds,
    this.seconds,
    this.minutes,
  });
}
class Dependencies {

  final List<ValueChanged<ElapsedTime>> timerListeners = <ValueChanged<ElapsedTime>>[];
  final TextStyle textStyle = const TextStyle(fontSize: 90.0, fontFamily: "Bebas Neue");
  final Stopwatch stopwatch = new Stopwatch();
  final int timerMillisecondsRefreshRate = 30;
}