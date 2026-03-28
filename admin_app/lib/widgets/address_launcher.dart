import 'package:url_launcher/url_launcher.dart';

Future<void> launchNavigation(String address) async {
  if (address.isEmpty) return;
  final encoded = Uri.encodeComponent(address);
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$encoded',
  );
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
}
