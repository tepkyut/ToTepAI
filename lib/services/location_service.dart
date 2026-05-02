import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String cityName;
  final String countryCode;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    required this.countryCode,
  });
}

class LocationService {
  static Future<bool> _checkLocationPermission() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  static Future<LocationData?> getCurrentLocation() async {
    try {
      // Check permissions first
      bool hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        throw Exception('Location permission denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Get placemarks from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String cityName = place.locality ?? 
                         place.subAdministrativeArea ?? 
                         place.administrativeArea ?? 
                         'Unknown';
        String countryCode = place.isoCountryCode ?? 'Unknown';

        return LocationData(
          latitude: position.latitude,
          longitude: position.longitude,
          cityName: cityName,
          countryCode: countryCode,
        );
      }

      // Fallback if no placemarks found
      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        cityName: 'Unknown',
        countryCode: 'Unknown',
      );
    } catch (e) {
      throw Exception('Error getting location: $e');
    }
  }

  static Future<LocationData?> getLocationByCityName(String cityName) async {
    try {
      List<Location> locations = await locationFromAddress(cityName);
      
      if (locations.isNotEmpty) {
        Location location = locations.first;
        
        // Get placemarks for more details
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );

        String finalCityName = cityName;
        String countryCode = 'Unknown';

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          finalCityName = place.locality ?? 
                         place.subAdministrativeArea ?? 
                         place.administrativeArea ?? 
                         cityName;
          countryCode = place.isoCountryCode ?? 'Unknown';
        }

        return LocationData(
          latitude: location.latitude,
          longitude: location.longitude,
          cityName: finalCityName,
          countryCode: countryCode,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Error getting location by city name: $e');
    }
  }

  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}
