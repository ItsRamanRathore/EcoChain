import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../repository/recycler_repository.dart';
import '../../../models/api/recycler_model.dart';

/// Fetches the device GPS position (requests permission if needed).
final locationProvider = FutureProvider<Position>((ref) async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception('Location services are disabled. Please enable GPS.');
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied.');
    }
  }
  if (permission == LocationPermission.deniedForever) {
    throw Exception('Location permission permanently denied.');
  }

  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 5),
      ),
    );
  } catch (e) {
    // Fallback for emulator if GPS times out
    return Position(
      longitude: 72.8777,
      latitude: 19.0760, // Mumbai coordinates
      timestamp: DateTime.now(),
      accuracy: 100,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }
});

/// Parameter bundle for recycler matching.
typedef RecyclerMatchParams = ({double lat, double lng, String category});

/// Matches recyclers for a given lat/lng + category.
final matchedRecyclersProvider =
    FutureProvider.family<List<RecyclerModel>, RecyclerMatchParams>(
  (ref, params) async {
    final repo = ref.read(recyclerRepositoryProvider);
    return repo.matchRecyclers(
      lat: params.lat,
      lng: params.lng,
      category: params.category,
    );
  },
);
