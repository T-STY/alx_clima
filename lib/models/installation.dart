enum InstallationType {
  fullPackage,
  installOnly;

  String get displayName {
    switch (this) {
      case InstallationType.fullPackage:
        return 'Paquete Completo (Equipo + Instalación)';
      case InstallationType.installOnly:
        return 'Solo Instalación';
    }
  }
}

enum FloorLevel {
  first,
  second;

  String get displayName {
    switch (this) {
      case FloorLevel.first:
        return 'Primer Piso';
      case FloorLevel.second:
        return 'Segundo Piso';
    }
  }
}

class InstallationDetails {
  final FloorLevel floorLevel;
  final bool compressorSameFloor;

  const InstallationDetails({
    required this.floorLevel,
    required this.compressorSameFloor,
  });

  InstallationDetails copyWith({
    FloorLevel? floorLevel,
    bool? compressorSameFloor,
  }) {
    return InstallationDetails(
      floorLevel: floorLevel ?? this.floorLevel,
      compressorSameFloor: compressorSameFloor ?? this.compressorSameFloor,
    );
  }
}
