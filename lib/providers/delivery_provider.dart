import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

class DeliveryProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _availableOrders = [];
  List<Map<String, dynamic>> _myDeliveries = [];
  List<Map<String, dynamic>> _earningHistory = [];
  double _availableBalance = 0.0;
  bool _isLoading = false;

  StreamSubscription<Position>? _positionStream;
  String? _activeOrderId;

  List<Map<String, dynamic>> get availableOrders => _availableOrders;
  List<Map<String, dynamic>> get myDeliveries => _myDeliveries;
  List<Map<String, dynamic>> get earningHistory => _earningHistory;
  double get availableBalance => _availableBalance;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  
  bool _isOnline = false;

  Future<String?> toggleOnlineStatus() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 'User not logged in';
    
    _isOnline = !_isOnline;
    notifyListeners();

    try {
      if (_isOnline) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            _isOnline = false;
            notifyListeners();
            return 'Location permission denied';
          }
        }
        if (permission == LocationPermission.deniedForever) {
          _isOnline = false;
          notifyListeners();
          return 'Location permissions are permanently denied';
        }

        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        await _supabase.from('riders').upsert({
          'id': user.id,
          'name': user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? 'Rider',
          'is_online': true,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'last_active': DateTime.now().toUtc().toIso8601String(),
        });
      } else {
        await _supabase.from('riders').update({
          'is_online': false,
          'last_active': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', user.id);
      }
      return null; // Success
    } catch (e) {
      print('Error updating online status: $e');
      _isOnline = !_isOnline; // Revert on failure
      notifyListeners();
      return e.toString();
    }
  }

  Future<void> fetchOnlineStatus() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final res = await _supabase.from('riders').select('is_online').eq('id', user.id).maybeSingle();
      if (res != null) {
        _isOnline = res['is_online'] ?? false;
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching online status: $e');
    }
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Fetch my active deliveries (assigned by admin and out_for_delivery)
      final myRes = await _supabase
          .from('orders')
          .select('*, shops(*)')
          .eq('status', 'out_for_delivery')
          .eq('delivery_partner_id', user.id)
          .order('created_at', ascending: false);

      _myDeliveries = List<Map<String, dynamic>>.from(myRes);

      // Start tracking if there is an active delivery
      if (_myDeliveries.isNotEmpty) {
        _activeOrderId = _myDeliveries.first['id'];
        _startLocationTracking();
      } else {
        _activeOrderId = null;
        _positionStream?.cancel();
      }

      await fetchEarnings();
    } catch (e) {
      print('Fetch orders error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchEarnings() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final deliveredRes = await _supabase
          .from('orders')
          .select('*, shops(*)')
          .eq('status', 'delivered')
          .eq('delivery_partner_id', user.id)
          .order('created_at', ascending: false);

      _earningHistory = List<Map<String, dynamic>>.from(deliveredRes);
      
      _availableBalance = _earningHistory.fold(0.0, (sum, order) {
        final fee = order['delivery_fee'];
        if (fee != null) {
          return sum + (fee as num).toDouble();
        }
        return sum + 40.0; // Fallback fee if missing
      });
      
      notifyListeners();
    } catch (e) {
      print('Fetch earnings error: $e');
    }
  }

  Future<bool> markAsDelivered(String orderId) async {
    try {
      await _supabase.from('orders').update({
        'status': 'delivered',
      }).eq('id', orderId);
      
      _positionStream?.cancel();
      _activeOrderId = null;
      
      await fetchOrders();
      return true;
    } catch (e) {
      print('Deliver order error: $e');
      return false;
    }
  }
  void _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      if (_activeOrderId == null) return;
      
      try {
        final orderRes = await _supabase.from('orders').select('customer_location').eq('id', _activeOrderId!).single();
        final Map<String, dynamic> customerLocation = orderRes['customer_location'] != null 
            ? Map<String, dynamic>.from(orderRes['customer_location']) 
            : {};
            
        customerLocation['rider_lat'] = position.latitude;
        customerLocation['rider_lng'] = position.longitude;
        
        await _supabase.from('orders').update({
          'customer_location': customerLocation,
        }).eq('id', _activeOrderId!);
      } catch (e) {
        print("Error updating location: $e");
      }
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}
