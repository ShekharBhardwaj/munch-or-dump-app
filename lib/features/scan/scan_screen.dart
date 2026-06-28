import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/core/models/analysis_result.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/features/auth/auth_controller.dart';
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

  Future<void> _runPhoto() async {
    final loggedIn = ref.read(authControllerProvider).valueOrNull != null;
    if (!loggedIn) {
      setState(
        () => _message =
            'Sign in to scan label photos. Barcode scanning works without an account.',
      );
      return;
    }
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      imageQuality: 85,
    );
    if (file == null) return;
    await _run(
      () => ref.read(scanServiceProvider).analyzePhotos(<XFile>[file]),
    );
  }

  Future<void> _run(Future<AnalyzeOutcome> Function() op) async {
    if (_busy) return;
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
                        if (_busy || capture.barcodes.isEmpty) return;
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
          if (_busy)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
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
