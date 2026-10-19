import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/services/audio_feedback_service.dart';
import '../../../../core/widgets/visual_feedback_overlay.dart';
import '../../../../core/localization/app_localizations.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  final AudioFeedbackService _audioService = AudioFeedbackService();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? qrData = barcodes.first.rawValue;
    if (qrData == null) return;

    setState(() => _isProcessing = true);

    try {
      final parts = qrData.split('|');
      if (parts.length >= 4 && parts[0] == 'WORKER') {
        final workerId = int.parse(parts[1]);
        final employeeId = parts[2];
        final siteId = int.parse(parts[3]);

        await _audioService.playAttendanceSuccess('Worker $employeeId');
        
        if (mounted) {
          VisualFeedbackOverlay.showAccessibleFeedback(
            context,
            type: FeedbackType.success,
            message: AppLocalizations.of(context)?.registered ?? 'Registered',
            subtitle: 'Employee: $employeeId',
          );

          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.pop(context, {
              'worker_id': workerId,
              'employee_id': employeeId,
              'site_id': siteId,
            });
          }
        }
      } else {
        await _audioService.playAttendanceError();
        if (mounted) {
          VisualFeedbackOverlay.showAccessibleFeedback(
            context,
            type: FeedbackType.error,
            message: AppLocalizations.of(context)?.error ?? 'Error',
            subtitle: 'Invalid QR code format',
          );
        }
      }
    } catch (e) {
      await _audioService.playAttendanceError();
      if (mounted) {
        VisualFeedbackOverlay.showAccessibleFeedback(
          context,
          type: FeedbackType.error,
          message: AppLocalizations.of(context)?.error ?? 'Error',
          subtitle: 'Failed to process QR code',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A192F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          localizations?.scanQrCode ?? 'Scan QR Code',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleQRCode,
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  localizations?.markAttendance ?? 'Position QR code within frame',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: const Color(0xFF6B7280),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6B7280)
      ..style = PaintingStyle.fill;

    final scanAreaSize = size.width * 0.7;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2;
    final scanRect = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(16)),
      borderPaint,
    );

    final cornerPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final cornerLength = 30.0;

    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLength), cornerPaint);

    canvas.drawLine(Offset(left + scanAreaSize, top), 
        Offset(left + scanAreaSize - cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left + scanAreaSize, top), 
        Offset(left + scanAreaSize, top + cornerLength), cornerPaint);

    canvas.drawLine(Offset(left, top + scanAreaSize), 
        Offset(left + cornerLength, top + scanAreaSize), cornerPaint);
    canvas.drawLine(Offset(left, top + scanAreaSize), 
        Offset(left, top + scanAreaSize - cornerLength), cornerPaint);

    canvas.drawLine(Offset(left + scanAreaSize, top + scanAreaSize), 
        Offset(left + scanAreaSize - cornerLength, top + scanAreaSize), cornerPaint);
    canvas.drawLine(Offset(left + scanAreaSize, top + scanAreaSize), 
        Offset(left + scanAreaSize, top + scanAreaSize - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(_ScannerOverlayPainter oldDelegate) => false;
}
