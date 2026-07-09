import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/core/models/analysis_result.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/theme/palette.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';
import 'package:munch_or_dump/core/widgets/forms.dart';
import 'package:munch_or_dump/features/auth/auth_controller.dart';
import 'package:munch_or_dump/features/auth/sign_in_prompts.dart';
import 'package:munch_or_dump/features/scan/scan_quota_modal.dart';
import 'package:munch_or_dump/features/scan/scan_service.dart';

/// The scan screen: live barcode camera + manual barcode entry (works without a
/// camera, e.g. the simulator) + auth-gated label-photo scan. All paths converge
/// on an [AnalyzeOutcome] and push the Result screen on success.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final TextEditingController _manualBarcode = TextEditingController();

  bool _busy = false;
  // Guards the anonymous "sign in to scan" sheet: the camera fires onDetect many
  // times a second, so without this a signed-out scan would stack hundreds of
  // sheets. Held from the moment we open the sheet until it's dismissed.
  bool _signInPromptOpen = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanner.dispose();
    _manualBarcode.dispose();
    super.dispose();
  }

  // We own the controller, so mobile_scanner won't pause the camera on
  // background for us — do it ourselves to free the sensor and the indicator.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_startCamera());
    } else {
      unawaited(_stopCamera());
    }
  }

  Future<void> _startCamera() async {
    try {
      await _scanner.start();
    } on Object catch (_) {
      // No camera available (e.g. the simulator) — ignore.
    }
  }

  Future<void> _stopCamera() async {
    try {
      await _scanner.stop();
    } on Object catch (_) {
      // Already stopped / no camera — ignore.
    }
  }

  Future<void> _runBarcode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    await _run(() => ref.read(scanServiceProvider).analyzeBarcode(trimmed));
  }

  /// Show the "sign in to scan" sheet exactly once at a time. The camera's
  /// onDetect fires continuously, so this guard is what stops a signed-out scan
  /// from stacking the sheet over and over.
  Future<void> _promptSignInToScan() async {
    if (_signInPromptOpen) return;
    _signInPromptOpen = true;
    try {
      await showSignInToScanSheet(context);
    } finally {
      if (mounted) _signInPromptOpen = false;
    }
  }

  Future<void> _runPhoto() async {
    if (ref.read(authControllerProvider).valueOrNull == null) {
      await _promptSignInToScan();
      return;
    }
    // Build a photo set first (front label, ingredients, nutrition…). Analysis
    // starts only when the user taps Analyze — never on the first photo.
    final photos = await showModalBottomSheet<List<XFile>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => const _PhotoSetSheet(),
    );
    if (photos == null || photos.isEmpty) return; // dismissed
    await _run(() => ref.read(scanServiceProvider).analyzePhotos(photos));
  }

  Future<void> _run(Future<AnalyzeOutcome> Function() op) async {
    if (_busy || _signInPromptOpen) return;
    // Scanning requires an account — the API returns 401 for anonymous
    // analyze, so gate before the round-trip rather than failing on it.
    if (ref.read(authControllerProvider).valueOrNull == null) {
      await _promptSignInToScan();
      return;
    }
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final outcome = await op();
      if (!mounted) return;
      switch (outcome) {
        case AnalyzeSuccess(:final result):
          await _stopCamera(); // free the camera while the verdict is on top
          if (!mounted) return;
          await context.pushNamed(Routes.result, extra: result);
          if (mounted) unawaited(_startCamera());
        case AnalyzeNotFound():
          setState(
            () => _message =
                'We couldn’t find that product. Try snapping the ingredients label.',
          );
        case AnalyzeUnsupported(:final message):
          setState(() => _message = message);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loggedIn = ref.watch(authControllerProvider).valueOrNull != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      body: Stack(
        children: <Widget>[
          ListView(
            children: <Widget>[
              SizedBox(
                height: 280,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    MobileScanner(
                      controller: _scanner,
                      onDetect: (capture) {
                        if (_busy ||
                            _signInPromptOpen ||
                            capture.barcodes.isEmpty) {
                          return;
                        }
                        final code = capture.barcodes.first.rawValue;
                        if (code != null && code.isNotEmpty) {
                          unawaited(_runBarcode(code));
                        }
                      },
                      errorBuilder: (context, error) =>
                          const _CameraUnavailable(),
                      placeholderBuilder: (context) =>
                          const ColoredBox(color: Colors.black12),
                    ),
                    IgnorePointer(
                      child: Center(
                        child: Container(
                          width: 230,
                          height: 130,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white70, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Point at a barcode — or type it in',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _manualBarcode,
                            enabled: !_busy,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Barcode',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: _busy ? null : _runBarcode,
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _busy
                              ? null
                              : () => _runBarcode(_manualBarcode.text),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                          child: const Text('Go'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _runPhoto,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Scan a label photo'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size.fromHeight(0),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => context.pushNamed(Routes.receipt),
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('Scan a receipt'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size.fromHeight(0),
                      ),
                    ),
                    if (!loggedIn) ...<Widget>[
                      const SizedBox(height: 16),
                      const Center(
                        child: SignInInline(
                          action: 'Sign in',
                          rest: ' to scan a product and save your verdicts.',
                        ),
                      ),
                    ],
                    if (_message != null) ...<Widget>[
                      const SizedBox(height: 16),
                      Text(
                        _message!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (_busy) const Positioned.fill(child: AnalysisLoader()),
        ],
      ),
    );
  }
}

/// Builds a set of label photos (up to [_PhotoSetSheetState._maxPhotos], the
/// web's cap) before analysis: take photos one at a time or multi-pick from the
/// library, review thumbnails, remove strays, then explicitly tap Analyze.
/// Pops with the chosen files, or null when dismissed.
class _PhotoSetSheet extends StatefulWidget {
  const _PhotoSetSheet();

  @override
  State<_PhotoSetSheet> createState() => _PhotoSetSheetState();
}

class _PhotoSetSheetState extends State<_PhotoSetSheet> {
  static const int _maxPhotos = 4; // matches the web scan page
  final List<XFile> _photos = <XFile>[];
  final ImagePicker _picker = ImagePicker();
  bool _picking = false;

  int get _remaining => _maxPhotos - _photos.length;

  Future<void> _takePhoto() async {
    if (_picking || _remaining == 0) return;
    setState(() => _picking = true);
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2000,
        imageQuality: 85,
      );
      if (file != null && mounted) setState(() => _photos.add(file));
    } on Object catch (_) {
      // Camera denied/unavailable — leave the set as-is.
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _pickFromLibrary() async {
    if (_picking || _remaining == 0) return;
    setState(() => _picking = true);
    try {
      final files = await _picker.pickMultiImage(
        maxWidth: 2000,
        imageQuality: 85,
        limit: _remaining,
      );
      if (files.isNotEmpty && mounted) {
        // `limit` is best-effort on some OS versions — enforce the cap here.
        setState(() => _photos.addAll(files.take(_remaining)));
      }
    } on Object catch (_) {
      // Library denied — leave the set as-is.
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Eyebrow('Scan a label', spacing: 3.6),
            const SizedBox(height: 8),
            Text(
              'Snap the front, the ingredients list, and the nutrition panel — '
              'up to 4 photos. More angles, better verdict.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: palette.inkSecondary,
              ),
            ),
            if (_photos.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => _PhotoThumb(
                    file: _photos[i],
                    onRemove: () => setState(() => _photos.removeAt(i)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            NavRow(
              icon: Icons.photo_camera_outlined,
              label: _photos.isEmpty ? 'Take a photo' : 'Take another photo',
              trailing: const SizedBox.shrink(),
              onTap: _remaining == 0 || _picking ? () {} : _takePhoto,
            ),
            Divider(height: 1, color: palette.hairlineFaint),
            NavRow(
              icon: Icons.photo_library_outlined,
              label: 'Choose from library',
              trailing: const SizedBox.shrink(),
              onTap: _remaining == 0 || _picking ? () {} : _pickFromLibrary,
            ),
            if (_remaining == 0) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'That’s the limit — 4 photos per scan.',
                style: TextStyle(fontSize: 12.5, color: palette.inkFaint),
              ),
            ],
            const SizedBox(height: 16),
            BlackCtaButton(
              label: _photos.length <= 1
                  ? 'Analyze'
                  : 'Analyze ${_photos.length} photos',
              expand: true,
              trailingIcon: null,
              enabled: _photos.isNotEmpty && !_picking,
              onTap: () => Navigator.pop(context, List<XFile>.of(_photos)),
            ),
          ],
        ),
      ),
    );
  }
}

/// One removable thumbnail in the photo-set sheet.
class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.file, required this.onRemove});

  final XFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Stack(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(file.path),
            width: 84,
            height: 84,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 84,
              height: 84,
              color: palette.surfaceAlt,
              child: Icon(Icons.broken_image_outlined, color: palette.inkFaint),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Semantics(
              label: 'Remove photo',
              button: true,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.no_photography_outlined,
                color: Colors.white70,
                size: 40,
              ),
              SizedBox(height: 8),
              Text(
                'Camera unavailable — enter a barcode below',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
