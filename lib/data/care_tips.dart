import 'package:flutter/material.dart';

class CareTip {
  final String title;
  final String description;
  final IconData icon;

  const CareTip({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class CareTips {
  CareTips._();

  static const List<CareTip> items = [
    CareTip(
      title: 'Limpia los filtros regularmente',
      description:
          'Limpia o reemplaza los filtros de tu equipo cada 2 a 4 semanas. '
          'Los filtros sucios reducen la eficiencia del sistema, aumentan '
          'el consumo de energía y pueden afectar la calidad del aire interior.',
      icon: Icons.filter_alt_outlined,
    ),
    CareTip(
      title: 'Programa mantenimiento profesional',
      description:
          'Agenda un servicio de mantenimiento profesional cada 6 meses. '
          'Un técnico certificado revisará el estado general del equipo, '
          'limpiará componentes internos y verificará los niveles de gas '
          'refrigerante.',
      icon: Icons.build_outlined,
    ),
    CareTip(
      title: 'Mantén despejada la unidad exterior',
      description:
          'Asegúrate de que la unidad condensadora (exterior) esté libre '
          'de hojas, basura, plantas o cualquier obstrucción. Mantén al '
          'menos 50 cm de espacio libre alrededor para una ventilación '
          'adecuada.',
      icon: Icons.yard_outlined,
    ),
    CareTip(
      title: 'Revisa el gas refrigerante anualmente',
      description:
          'Un nivel bajo de gas refrigerante reduce la capacidad de '
          'enfriamiento y puede dañar el compresor. Solicita a un técnico '
          'que verifique los niveles al menos una vez al año.',
      icon: Icons.thermostat_outlined,
    ),
    CareTip(
      title: 'No bloquees las salidas de aire',
      description:
          'Evita colocar muebles, cortinas u objetos frente a las salidas '
          'de aire del equipo interior. Bloquear el flujo de aire reduce '
          'la eficiencia y puede causar un enfriamiento desigual.',
      icon: Icons.air_outlined,
    ),
    CareTip(
      title: 'Usa temperaturas recomendadas',
      description:
          'Configura el termostato entre 22°C y 24°C para un balance '
          'óptimo entre confort y ahorro energético. Cada grado por debajo '
          'de esta cifra puede aumentar el consumo hasta un 8%.',
      icon: Icons.device_thermostat_outlined,
    ),
    CareTip(
      title: 'Escucha ruidos inusuales',
      description:
          'Presta atención a ruidos extraños como golpeteos, chirridos o '
          'zumbidos fuertes. Estos pueden indicar problemas mecánicos que '
          'requieren atención inmediata de un técnico.',
      icon: Icons.hearing_outlined,
    ),
    CareTip(
      title: 'Verifica el drenaje del condensado',
      description:
          'Revisa periódicamente que la tubería de drenaje no esté '
          'obstruida. Una tubería tapada puede causar fugas de agua y '
          'daños a paredes o techos. Limpia el drenaje cada 3 meses.',
      icon: Icons.water_drop_outlined,
    ),
    CareTip(
      title: 'Apaga el equipo al salir',
      description:
          'Si vas a estar fuera de casa por varias horas, apaga el equipo '
          'o programa el temporizador. Esto reduce el desgaste del '
          'compresor y ahorra energía significativamente.',
      icon: Icons.power_settings_new_outlined,
    ),
    CareTip(
      title: 'Sella puertas y ventanas',
      description:
          'Asegúrate de que las puertas y ventanas estén bien selladas '
          'cuando el equipo esté en funcionamiento. Las fugas de aire '
          'obligan al sistema a trabajar más y aumentan el consumo '
          'eléctrico.',
      icon: Icons.door_front_door_outlined,
    ),
  ];
}
