import 'package:geolocator/geolocator.dart';

abstract interface class InspectionLocationService {
  Future<Position> getCurrentPosition();
}

final class InspectionLocationServiceImpl implements InspectionLocationService {
  const InspectionLocationServiceImpl();

  @override
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw const InspectionLocationException(
        'Ative a localização do dispositivo para continuar.',
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const InspectionLocationException(
        'A permissão de localização foi negada.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const InspectionLocationException(
        'A permissão de localização foi bloqueada. '
        'Ative-a nas configurações do aplicativo.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}

final class InspectionLocationException implements Exception {
  const InspectionLocationException(this.message);

  final String message;

  @override
  String toString() => message;
}
