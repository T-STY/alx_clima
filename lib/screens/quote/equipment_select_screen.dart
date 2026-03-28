import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:alx_clima/config/theme.dart';
import 'package:alx_clima/models/equipment.dart';
import 'package:alx_clima/providers/quote_provider.dart';
import 'package:alx_clima/services/firebase_service.dart';
import 'package:alx_clima/widgets/futuristic_button.dart';

class EquipmentSelectScreen extends StatefulWidget {
  const EquipmentSelectScreen({super.key});

  @override
  State<EquipmentSelectScreen> createState() => _EquipmentSelectScreenState();
}

class _EquipmentSelectScreenState extends State<EquipmentSelectScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _currencyFormat =
      NumberFormat.currency(symbol: '\$', decimalDigits: 0);

  List<Map<String, dynamic>> _catalog = [];
  List<String> _types = [];
  bool _isLoading = true;

  String? _selectedType;
  int? _selectedBtu;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _firebaseService.getQuoteCatalog(),
        _firebaseService.getEquipmentTypes(),
        _firebaseService.getPricingConfig(),
      ]);

      final catalog = results[0] as List<Map<String, dynamic>>;
      final types = results[1] as List<String>;
      final pricing = results[2] as Map<String, dynamic>?;

      if (pricing != null && mounted) {
        context.read<QuoteProvider>().setPricingConfig(pricing);
      }

      if (mounted) {
        setState(() {
          _catalog = catalog;
          _types = types;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Equipment> get _filteredEquipment {
    var items = _catalog.map(_mapToEquipment).toList();
    if (_selectedType != null) {
      items = items.where((e) => e.type.displayName == _selectedType).toList();
    }
    if (_selectedBtu != null) {
      items = items.where((e) => e.btuCapacity == _selectedBtu).toList();
    }
    return items;
  }

  Equipment _mapToEquipment(Map<String, dynamic> data) {
    final typeStr = (data['type'] ?? 'miniSplit') as String;
    final type = EquipmentType.values.firstWhere(
      (e) => e.name == typeStr || e.displayName == typeStr,
      orElse: () => EquipmentType.miniSplit,
    );

    return Equipment(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      type: type,
      btuCapacity: data['btuCapacity'] ?? 12000,
      price: (data['price'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      manufacturerWarrantyYears:
          (data['manufacturerWarrantyYears'] ?? 1).toDouble(),
      manufacturerWarrantyDetails:
          data['manufacturerWarrantyDetails'] ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona tu Equipo'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_types.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTypeChip('Todos', null),
                          const SizedBox(width: 8),
                          ..._types.map((t) => Padding(
                                padding:
                                    const EdgeInsets.only(right: 8),
                                child: _buildTypeChip(t, t),
                              )),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildBtuChip('Todos', null),
                        const SizedBox(width: 8),
                        _buildBtuChip('12,000 BTU', 12000),
                        const SizedBox(width: 8),
                        _buildBtuChip('18,000 BTU', 18000),
                        const SizedBox(width: 8),
                        _buildBtuChip('24,000 BTU', 24000),
                        const SizedBox(width: 8),
                        _buildBtuChip('36,000 BTU', 36000),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredEquipment.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Iconsax.search_normal,
                                size: 48,
                                color: AppTheme.textSecondary
                                    .withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No se encontraron equipos',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium,
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: _filteredEquipment.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final equipment = _filteredEquipment[index];
                            return _EquipmentCard(
                              equipment: equipment,
                              currencyFormat: _currencyFormat,
                              onTap: () => _showEquipmentDetail(
                                  context, equipment),
                            )
                                .animate()
                                .fadeIn(
                                    duration: 400.ms,
                                    delay: (index * 80).ms)
                                .slideY(begin: 0.1, end: 0);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildTypeChip(String label, String? type) {
    final isSelected = _selectedType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedType = type),
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.12),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected
            ? AppTheme.primaryColor
            : AppTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 13,
      ),
    );
  }

  Widget _buildBtuChip(String label, int? btu) {
    final isSelected = _selectedBtu == btu;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedBtu = btu),
      selectedColor: AppTheme.secondaryColor.withValues(alpha: 0.12),
      checkmarkColor: AppTheme.secondaryColor,
      labelStyle: TextStyle(
        color: isSelected
            ? AppTheme.secondaryColor
            : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 13,
      ),
    );
  }

  void _showEquipmentDetail(
      BuildContext context, Equipment equipment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  equipment.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  equipment.brand,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _specBadge(
                        context, Iconsax.wind, equipment.btuFormatted),
                    const SizedBox(width: 8),
                    _specBadge(context, Iconsax.category,
                        equipment.type.displayName),
                  ],
                ),
                const SizedBox(height: 16),
                if (equipment.description.isNotEmpty)
                  Text(
                    equipment.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                if (equipment.manufacturerWarrantyDetails.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor
                          .withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.successColor
                            .withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.shield_tick,
                            color: AppTheme.successColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            equipment.manufacturerWarrantyDetails,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppTheme.successColor,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Precio del equipo',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Precio aproximado',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                    Text(
                      _currencyFormat.format(equipment.price),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FuturisticButton(
                  text: 'Seleccionar',
                  icon: Iconsax.tick_circle,
                  onPressed: () {
                    context
                        .read<QuoteProvider>()
                        .selectEquipment(equipment);
                    Navigator.of(ctx).pop();
                    context.push('/quote/installation');
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _specBadge(
      BuildContext context, IconData icon, String text) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            text,
            style:
                Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
          ),
        ],
      ),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  final Equipment equipment;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;

  const _EquipmentCard({
    required this.equipment,
    required this.currencyFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.dividerColor),
          boxShadow: [
            BoxShadow(
              color:
                  AppTheme.primaryColor.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.surfaceColor,
                    AppTheme.dividerColor.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.network(
                  'https://img.icons8.com/ios/100/air-conditioner.png',
                  errorBuilder: (_, __, ___) => const Icon(
                    Iconsax.cpu_setting,
                    color: AppTheme.textSecondary,
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          equipment.brand,
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          equipment.btuFormatted,
                          style: TextStyle(
                            color: AppTheme.secondaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                        currencyFormat.format(equipment.price),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Iconsax.arrow_right_3,
                color:
                    AppTheme.textSecondary.withValues(alpha: 0.6),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
