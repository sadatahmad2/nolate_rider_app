import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const MapTrackingScreen({super.key, required this.order});

  @override
  State<MapTrackingScreen> createState() => _MapTrackingScreenState();
}

class _MapTrackingScreenState extends State<MapTrackingScreen> {
  final MapController _mapController = MapController();
  
  LatLng? _shopLocation;
  LatLng? _customerLocation;

  @override
  void initState() {
    super.initState();
    _extractLocations();
  }

  void _extractLocations() {
    try {
      final shop = widget.order['shops'];
      if (shop != null && shop['latitude'] != null && shop['longitude'] != null) {
        _shopLocation = LatLng((shop['latitude'] as num).toDouble(), (shop['longitude'] as num).toDouble());
      }

      final customerLoc = widget.order['customer_location'];
      if (customerLoc != null && customerLoc['lat'] != null && customerLoc['lng'] != null) {
        _customerLocation = LatLng((customerLoc['lat'] as num).toDouble(), (customerLoc['lng'] as num).toDouble());
      }
    } catch (e) {
      print('Error parsing locations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final shortId = widget.order['id'].toString().substring(0, 6).toUpperCase();
    
    // Provide some default fallback location in case data is completely missing
    // We will use Connaught Place, New Delhi as default fallback (28.630, 77.218)
    final fallbackLoc = const LatLng(28.630, 77.218);
    final centerLoc = _shopLocation ?? _customerLocation ?? fallbackLoc;

    List<Marker> markers = [];
    if (_shopLocation != null) {
      markers.add(
        Marker(
          point: _shopLocation!,
          width: 80,
          height: 80,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange)),
                child: const Text('Pickup', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Icon(Icons.store, color: Colors.orange, size: 30),
            ],
          ),
        ),
      );
    }
    
    if (_customerLocation != null) {
      markers.add(
        Marker(
          point: _customerLocation!,
          width: 80,
          height: 80,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red)),
                child: const Text('Drop-off', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Icon(Icons.location_on, color: Colors.red, size: 30),
            ],
          ),
        ),
      );
    }

    List<Polyline> polylines = [];
    if (_shopLocation != null && _customerLocation != null) {
      polylines.add(
        Polyline(
          points: [_shopLocation!, _customerLocation!],
          color: const Color(0xFFFF6B35),
          strokeWidth: 4.0,
        )
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #$shortId'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: centerLoc,
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.riderapp',
          ),
          PolylineLayer(polylines: polylines),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}
