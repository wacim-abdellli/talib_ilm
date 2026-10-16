import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../app/theme/app_palette.dart';

/// Represents a validated compass heading reading.
class CompassReading {
  final double heading; // 0..360 degrees
  final double? accuracy;
  final bool isSensorAvailable;

  const CompassReading({
    required this.heading,
    this.accuracy,
    this.isSensorAvailable = true,
  });
}

/// Robust dual-engine Compass Service.
///
/// Attempts to use [FlutterCompass] first. If [FlutterCompass] fails, is null,
/// or stays silent on devices with broken [Sensor.TYPE_ROTATION_VECTOR] (frequent on Samsung/Xiaomi),
/// it automatically falls back to raw 3D trigonometric azimuth calculation from
/// [accelerometerEventStream] + [magnetometerEventStream] via [sensors_plus].
///
/// If the device physically lacks a magnetometer, it emits [isSensorAvailable: false].
class CompassService {
  static final CompassService _instance = CompassService._internal();
  factory CompassService() => _instance;
  CompassService._internal();

  StreamController<CompassReading>? _controller;
  StreamSubscription? _compassSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  AccelerometerEvent? _lastAccel;
  MagnetometerEvent? _lastMag;
  double _filteredHeading = 0.0;
  bool _hasEmitted = false;
  bool _useSensorsPlus = false;
  Timer? _fallbackTimer;
  Timer? _sensorCheckTimer;

  Stream<CompassReading> get stream {
    _controller ??= StreamController<CompassReading>.broadcast(
      onListen: _startListening,
      onCancel: _stopListening,
    );
    return _controller!.stream;
  }

  void _startListening() {
    _hasEmitted = false;
    _useSensorsPlus = false;

    // 1. Try FlutterCompass first
    try {
      final compassEvents = FlutterCompass.events;
      if (compassEvents != null) {
        _compassSub = compassEvents.listen(
          (event) {
            final h = event.heading;
            if (h != null && !h.isNaN) {
              _hasEmitted = true;
              _fallbackTimer?.cancel();
              _sensorCheckTimer?.cancel();
              _controller?.add(
                CompassReading(
                  heading: (h % 360 + 360) % 360,
                  accuracy: event.accuracy,
                  isSensorAvailable: true,
                ),
              );
            }
          },
          onError: (e) {
            debugPrint('CompassService: FlutterCompass error ($e), falling back to sensors_plus');
            _switchToSensorsPlus();
          },
        );
      } else {
        _switchToSensorsPlus();
      }
    } catch (e) {
      debugPrint('CompassService: FlutterCompass init failed ($e), falling back to sensors_plus');
      _switchToSensorsPlus();
    }

    // 2. If no event received from FlutterCompass within 600ms, start sensors_plus
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer(AppMotion.deliberate, () {
      if (!_hasEmitted) {
        _switchToSensorsPlus();
      }
    });

    // 3. Sensor availability check: after 2.5s, if no sensor has responded, mark unavailable
    _sensorCheckTimer?.cancel();
    _sensorCheckTimer = Timer(AppMotion.toast, () {
      if (!_hasEmitted && (_controller?.hasListener ?? false)) {
        _controller?.add(
          const CompassReading(
            heading: 0,
            isSensorAvailable: false,
          ),
        );
      }
    });
  }

  void _switchToSensorsPlus() {
    if (_useSensorsPlus) return;
    _useSensorsPlus = true;
    _compassSub?.cancel();
    _compassSub = null;

    try {
      _accelSub = accelerometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(
        (event) {
          _lastAccel = event;
          _computeHeading();
        },
        onError: (e) {
          debugPrint('CompassService: Accelerometer error: $e');
        },
      );

      _magSub = magnetometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(
        (event) {
          _lastMag = event;
          _computeHeading();
        },
        onError: (e) {
          debugPrint('CompassService: Magnetometer error (sensor missing): $e');
          _controller?.add(
            const CompassReading(
              heading: 0,
              isSensorAvailable: false,
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('CompassService: SensorsPlus init error: $e');
      _controller?.add(
        const CompassReading(
          heading: 0,
          isSensorAvailable: false,
        ),
      );
    }
  }

  void _computeHeading() {
    final a = _lastAccel;
    final m = _lastMag;
    if (a == null || m == null) return;

    final ax = a.x;
    final ay = a.y;
    final az = a.z;
    final mx = m.x;
    final my = m.y;
    final mz = m.z;

    // Cross product: East = Magnetometer x Accelerometer
    final ex = my * az - mz * ay;
    final ey = mz * ax - mx * az;
    final ez = mx * ay - my * ax;
    final normE = math.sqrt(ex * ex + ey * ey + ez * ez);
    if (normE < 0.001) return;

    final eX = ex / normE;
    final eY = ey / normE;
    final eZ = ez / normE;

    // Cross product: North = Accelerometer x East
    final normA = math.sqrt(ax * ax + ay * ay + az * az);
    if (normA < 0.001) return;
    final aX = ax / normA;
    final aZ = az / normA;

    final nY = aZ * eX - aX * eZ;

    // Azimuth heading in degrees relative to true magnetic North
    var rawHeading = math.atan2(eY, nY) * (180.0 / math.pi);
    if (rawHeading < 0) {
      rawHeading += 360.0;
    }

    // Exponential smoothing for fluid and dignified compass needle motion
    if (!_hasEmitted) {
      _filteredHeading = rawHeading;
      _hasEmitted = true;
      _sensorCheckTimer?.cancel();
    } else {
      var diff = rawHeading - _filteredHeading;
      while (diff < -180.0) {
        diff += 360.0;
      }
      while (diff > 180.0) {
        diff -= 360.0;
      }
      _filteredHeading = (_filteredHeading + diff * 0.30 + 360.0) % 360.0;
    }

    _controller?.add(
      CompassReading(
        heading: _filteredHeading,
        accuracy: 15.0,
        isSensorAvailable: true,
      ),
    );
  }

  void _stopListening() {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    _sensorCheckTimer?.cancel();
    _sensorCheckTimer = null;
    _compassSub?.cancel();
    _compassSub = null;
    _accelSub?.cancel();
    _accelSub = null;
    _magSub?.cancel();
    _magSub = null;
    _controller?.close();
    _controller = null;
  }
}
