import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatelessWidget {
  final String location;

  const MapPage({Key? key, required this.location}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LatLng initialPosition = _parseLocation(location);

    return Scaffold(
      appBar: AppBar(
        title: Text('Location on Map'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: initialPosition,
          zoom: 15,
        ),
        markers: Set.of([
          Marker(
            markerId: MarkerId('distress_location'),
            position: initialPosition,
            infoWindow: InfoWindow(title: 'Distress Location'),
          ),
        ]),
      ),
    );
  }

  LatLng _parseLocation(String location) {
    final pattern = RegExp(r"([-+]?\d*\.?\d+), ([-+]?\d*\.?\d+)");
    final match = pattern.firstMatch(location);
    if (match != null && match.groupCount == 2) {
      final lat = double.parse(match.group(1)!);
      final lng = double.parse(match.group(2)!);
      return LatLng(lat, lng);
    } else {
      // Default location if parsing fails
      return LatLng(0, 0);
    }
  }
}
//
// class GoogleMapsIframe extends StatefulWidget {
//   final String url;
//   const GoogleMapsIframe({Key? key, required this.url}) : super(key: key);
//   @override
//   _GoogleMapsIframeState createState() => _GoogleMapsIframeState();
// }
//
// class _GoogleMapsIframeState extends State {
//   late Widget iframeWidget;
//   final IFrameElement iframeElement = IFrameElement();
//
//   @override
//   void initState() {
//     super.initState();
//     iframeElement.height = '100%';
//     iframeElement.width = '100%';
//     iframeElement.src = widget.url;
//     iframeElement.style.border = 'none';
//     ui.platformViewRegistry.registerViewFactory(
//       widget.url,
//       (int viewId) => iframeElement,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return HtmlElementView(
//       viewType: widget.url,
//     );
//   }
// }
