import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/glass_card.dart';
import 'client_detail.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                'Clientes',
                style: GoogleFonts.exo2(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: TextField(
                  style: GoogleFonts.exo2(fontSize: 14),
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar cliente...',
                    hintStyle: GoogleFonts.exo2(fontSize: 14),
                    prefixIcon: Icon(
                      Iconsax.search_normal,
                      size: 18,
                      color: isDark
                          ? Colors.white38
                          : const Color(0xFF9E9EB8),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white.withValues(alpha: 0.7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snapshot.data?.docs ?? [];

        if (_search.isNotEmpty) {
          final lower = _search.toLowerCase();
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final phone = (data['phone'] ?? '').toString().toLowerCase();
            return name.contains(lower) || phone.contains(lower);
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Text(
              'Sin clientes',
              style: GoogleFonts.exo2(fontSize: 14),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final suspended = data['suspended'] == true;

            return GestureDetector(
              onTap: () => showClientDetail(context, docs[i]),
              child: GlassCard(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AdminTheme.primaryColor.withValues(alpha: 0.2),
                            AdminTheme.primaryColor.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Iconsax.user,
                        size: 18,
                        color: AdminTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? 'Sin nombre',
                            style: GoogleFonts.exo2(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data['phone'] ?? '',
                            style: GoogleFonts.exo2(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (suspended)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              AdminTheme.errorColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Suspendido',
                          style: GoogleFonts.exo2(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AdminTheme.errorColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 200.ms, delay: (i * 30).ms);
          },
        );
      },
    );
  }
}
