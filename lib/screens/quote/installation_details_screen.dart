import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:alx_clima/config/theme.dart';
import 'package:alx_clima/models/equipment.dart';
import 'package:alx_clima/models/installation.dart';
import 'package:alx_clima/providers/quote_provider.dart';
import 'package:alx_clima/services/firebase_service.dart';
import 'package:alx_clima/widgets/floor_selector.dart';
import 'package:alx_clima/widgets/futuristic_button.dart';

class InstallationDetailsScreen extends StatefulWidget {
  const InstallationDetailsScreen({super.key});

  @override
  State<InstallationDetailsScreen> createState() =>
      _InstallationDetailsScreenState();
}

class _InstallationDetailsScreenState
    extends State<InstallationDetailsScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  int _soloStep = 0;
  int? _soloBtu;
  String? _soloBrand;
  String? _soloModel;
  String _soloLocation = '';
  List<Map<String, dynamic>> _brands = [];
  List<String> _modelsForBrand = [];
  bool _isLoadingBrands = false;
  bool _pricingLoaded = false;
  bool _isAddingSoloEquipment = false;

  @override
  void initState() {
    super.initState();
    _ensurePricingLoaded();
  }

  Future<void> _ensurePricingLoaded() async {
    final quote = context.read<QuoteProvider>();
    try {
      final pricing = await _firebaseService.getPricingConfig();
      if (pricing != null && mounted) {
        quote.setPricingConfig(pricing);
        setState(() => _pricingLoaded = true);
      }
    } catch (_) {
      if (mounted) setState(() => _pricingLoaded = true);
    }
  }

  Future<void> _loadBrands() async {
    if (_brands.isNotEmpty) return;
    setState(() => _isLoadingBrands = true);
    try {
      final brands = await _firebaseService.getEquipmentBrands();
      if (mounted) {
        setState(() {
          _brands = brands;
          _isLoadingBrands = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBrands = false);
    }
  }

  void _onBrandSelected(String? brand) {
    setState(() {
      _soloBrand = brand;
      _soloModel = null;
      _modelsForBrand = [];
    });
    if (brand != null) {
      final brandData = _brands.firstWhere(
        (b) => b['name'] == brand,
        orElse: () => <String, dynamic>{},
      );
      final models = brandData['models'];
      if (models is List) {
        setState(() => _modelsForBrand = models.cast<String>());
      }
    }
  }

  void _finalizeSoloEquipment() {
    if (_soloBtu == null || _soloBrand == null || _soloModel == null) return;
    final quote = context.read<QuoteProvider>();
    final equipment = Equipment(
      id: 'solo-${DateTime.now().millisecondsSinceEpoch}',
      name: _soloModel!,
      brand: _soloBrand!,
      type: EquipmentType.miniSplit,
      btuCapacity: _soloBtu!,
      price: 0,
      description: 'Equipo del cliente',
    );
    quote.addEquipmentItem(equipment, location: _soloLocation);
    setState(() {
      _isAddingSoloEquipment = false;
      _soloStep = 0;
      _soloBtu = null;
      _soloBrand = null;
      _soloModel = null;
      _soloLocation = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de Instalación'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () {
            if (_soloStep > 0) {
              setState(() => _soloStep--);
              return;
            }
            context.pop();
          },
        ),
      ),
      body: Consumer<QuoteProvider>(
        builder: (context, quote, _) {
          final isSolo =
              quote.installationType == InstallationType.installOnly;
          final hasItems = quote.items.isNotEmpty;

          if (isSolo && (!hasItems || _isAddingSoloEquipment)) {
            return _buildSoloFlow(context, quote);
          }

          if (!hasItems) {
            return const Center(child: CircularProgressIndicator());
          }

          final activeItem = quote.items[quote.activeItemIndex];
          final details = activeItem.installationDetails;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (quote.items.length > 1) ...[
                        _buildItemTabs(context, quote),
                        const SizedBox(height: 20),
                      ],
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Iconsax.cpu_setting,
                                color: AppTheme.primaryColor, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Equipo ${quote.activeItemIndex + 1}: ${activeItem.equipment.name}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                  ),
                                  Text(
                                    '${activeItem.equipment.brand} \u00b7 ${activeItem.equipment.btuFormatted}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  if (activeItem.location != null &&
                                      activeItem.location!.isNotEmpty)
                                    Text(
                                      activeItem.location!,
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
                            ),
                            if (quote.items.length > 1)
                              IconButton(
                                onPressed: () =>
                                    quote.removeItem(quote.activeItemIndex),
                                icon: const Icon(Iconsax.trash,
                                    size: 18, color: AppTheme.errorColor),
                              ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms),
                      const SizedBox(height: 24),
                      FloorSelector(
                        selectedFloor: details.floorLevel,
                        compressorSameFloor: details.compressorSameFloor,
                        onFloorChanged: (floor) => quote.setFloorLevel(floor),
                        onCompressorLocationChanged: (sameFloor) =>
                            quote.setCompressorLocation(sameFloor),
                      ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
                      const SizedBox(height: 20),
                      if (details.floorLevel == FloorLevel.second ||
                          !details.compressorSameFloor)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryColor.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryColor
                                  .withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Iconsax.info_circle,
                                      size: 16, color: AppTheme.primaryColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ajustes de precio',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (details.floorLevel == FloorLevel.second)
                                Text(
                                  'Cargo adicional por instalación en segundo piso',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppTheme.textPrimary),
                                ),
                              if (!details.compressorSameFloor)
                                Text(
                                  'Cargo adicional por compresor en piso diferente',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppTheme.textPrimary),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => _addAnotherEquipment(context, quote),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryColor.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Iconsax.add_circle,
                                  color: AppTheme.primaryColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Agregar otro equipo',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(context, quote, currencyFormat),
            ],
          );
        },
      ),
    );
  }

  static const Map<int, String> _btuTonnage = {
    12000: '1 Ton',
    18000: '1.5 Ton',
    24000: '2 Ton',
    36000: '3 Ton',
  };

  Widget _buildSoloFlow(BuildContext context, QuoteProvider quote) {
    switch (_soloStep) {
      case 0:
        return _buildBtuStep(context);
      case 1:
        return _buildBrandModelStep(context);
      default:
        return _buildBtuStep(context);
    }
  }

  Widget _buildBtuStep(BuildContext context) {
    const btuOptions = [12000, 18000, 24000, 36000];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.05),
                  AppTheme.secondaryColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  ).createShader(bounds),
                  child: const Icon(Iconsax.wind, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  '¿Cuál es la capacidad de tu equipo?',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1, end: 0),
          const SizedBox(height: 24),
          Text('Capacidad (BTU)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...btuOptions.map((btu) {
            final isSelected = _soloBtu == btu;
            final label = '${NumberFormat('#,###').format(btu)} BTU';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() => _soloBtu = btu),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withValues(alpha: 0.1)
                        : AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.wind,
                          size: 20,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondary),
                      const SizedBox(width: 12),
                      Text(label,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.textPrimary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 16,
                          )),
                      const SizedBox(width: 8),
                      Text(_btuTonnage[btu] ?? '',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                      const Spacer(),
                      if (isSelected)
                        const Icon(Iconsax.tick_circle,
                            color: AppTheme.primaryColor, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          FuturisticButton(
            text: 'Continuar',
            icon: Iconsax.arrow_right_3,
            onPressed: _soloBtu != null
                ? () {
                    _loadBrands();
                    setState(() => _soloStep = 1);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBrandModelStep(BuildContext context) {
    final locationCtrl = TextEditingController(text: _soloLocation);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Marca', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (_isLoadingBrands)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator()))
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _soloBrand,
                  hint: const Text('Seleccionar marca'),
                  isExpanded: true,
                  icon: const Icon(Iconsax.arrow_down_1),
                  items: _brands
                      .map((b) => DropdownMenuItem(
                            value: b['name'] as String,
                            child: Text(b['name'] as String),
                          ))
                      .toList(),
                  onChanged: _onBrandSelected,
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text('Modelo', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _soloModel,
                hint: Text(_soloBrand == null
                    ? 'Selecciona una marca primero'
                    : 'Seleccionar modelo'),
                isExpanded: true,
                icon: const Icon(Iconsax.arrow_down_1),
                items: _modelsForBrand
                    .map((m) =>
                        DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: _soloBrand == null
                    ? null
                    : (val) => setState(() => _soloModel = val),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Ubicación del equipo (opcional)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          TextField(
            controller: locationCtrl,
            onChanged: (val) => _soloLocation = val,
            decoration: const InputDecoration(
              hintText: 'Ej. Sala, Recámara, Oficina',
              prefixIcon: Icon(Iconsax.location, size: 20),
            ),
          ),
          const SizedBox(height: 28),
          FuturisticButton(
            text: 'Agregar Equipo',
            icon: Iconsax.tick_circle,
            onPressed: (_soloBrand != null && _soloModel != null)
                ? _finalizeSoloEquipment
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildItemTabs(BuildContext context, QuoteProvider quote) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: quote.items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isActive = index == quote.activeItemIndex;
          return GestureDetector(
            onTap: () => quote.setActiveItem(index),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryColor : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isActive
                        ? AppTheme.primaryColor
                        : AppTheme.dividerColor),
              ),
              child: Text(
                'Equipo ${index + 1}',
                style: TextStyle(
                  color: isActive ? Colors.white : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _addAnotherEquipment(BuildContext context, QuoteProvider quote) {
    if (quote.installationType == InstallationType.fullPackage) {
      context.push('/quote/equipment');
    } else {
      setState(() {
        _soloBtu = null;
        _soloBrand = null;
        _soloModel = null;
        _soloLocation = '';
        _soloStep = 0;
        _isAddingSoloEquipment = true;
      });
    }
  }

  Widget _buildBottomBar(
      BuildContext context, QuoteProvider quote, NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (quote.items.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${quote.items.length} equipos',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    'Descuento multi-equipo aplicado',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Costo de instalación',
                  style: Theme.of(context).textTheme.bodyMedium),
              Text(
                currencyFormat.format(quote.totalInstallCost),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FuturisticButton(
            text: 'Continuar',
            icon: Iconsax.arrow_right_3,
            onPressed: () {
              quote.generateQuote();
              context.push('/quote/summary');
            },
          ),
        ],
      ),
    );
  }
}
