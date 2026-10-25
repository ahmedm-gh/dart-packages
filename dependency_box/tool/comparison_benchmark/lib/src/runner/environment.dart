import 'dart:io';

/// Captures machine, OS, Dart SDK, and execution mode metadata.
class BenchmarkEnvironment {
  final String dartVersion;
  final String os;
  final String osVersion;
  final int numberOfProcessors;
  final String executable;
  final String executionMode;
  final DateTime timestamp;

  BenchmarkEnvironment({
    required this.dartVersion,
    required this.os,
    required this.osVersion,
    required this.numberOfProcessors,
    required this.executable,
    required this.executionMode,
    required this.timestamp,
  });

  factory BenchmarkEnvironment.detect({required String mode}) {
    return BenchmarkEnvironment(
      dartVersion: Platform.version,
      os: Platform.operatingSystem,
      osVersion: Platform.operatingSystemVersion,
      numberOfProcessors: Platform.numberOfProcessors,
      executable: Platform.resolvedExecutable,
      executionMode: mode,
      timestamp: DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dart_version': dartVersion,
      'os': os,
      'os_version': osVersion,
      'number_of_processors': numberOfProcessors,
      'executable': executable,
      'execution_mode': executionMode,
      'timestamp_utc': timestamp.toIso8601String(),
    };
  }
}
