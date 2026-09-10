import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../repository/recycler_repository.dart';
import '../../../models/api/recycler_model.dart';

/// Fetches the device GPS position (requests permission if needed).
final locationProvider = FutureProvider<Position>((ref) async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.deniedForever) {
    throw Exception('Location permission permanently denied.');
  }
  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
  );
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
