import 'package:url_launcher/url_launcher.dart';

Future<void> launchNavigation(String address) async {
  if (address.isEmpty) return;
  final fullAddress = '$address, México';
  final encoded = Uri.encodeComponent(fullAddress);
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$encoded',
  );
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
}
