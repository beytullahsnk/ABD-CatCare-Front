import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QRScannerScreen extends StatefulWidget {
  final Function(String) onQRCodeScanned;
  final String title;

  const QRScannerScreen({
    super.key,
    required this.onQRCodeScanned,
    this.title = 'Scanner le QR code',
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool hasPermission = false;
  bool isScanning = false;
  bool isTorchOn = false;
  CameraFacing cameraFacing = CameraFacing.back;
  String? lastDetectedCode;
  int detectionCount = 0;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      hasPermission = status == PermissionStatus.granted;
    });
  }

  void _onDetect(BarcodeCapture capture) {
    print('🔍 Détection appelée - Nombre de codes: ${capture.barcodes.length}');
    
    if (capture.barcodes.isNotEmpty) {
      final String? code = capture.barcodes.first.rawValue;
      print(' Code détecté: $code');
      
      if (code != null && code != lastDetectedCode) {
        setState(() {
          lastDetectedCode = code;
          detectionCount++;
        });
        
        print('✅ Nouveau code détecté: $code');
        print(' Nombre de détections: $detectionCount');
        
        if (!isScanning) {
          setState(() {
            isScanning = true;
          });
          
          // Vérifier si c'est un ID RuuviTag valide
          if (_isValidRuuviTagId(code)) {
            print('✅ Code RuuviTag valide: $code');
            // Appeler la callback mais ne pas fermer l'écran
            widget.onQRCodeScanned(code);
            // Ne pas faire Navigator.of(context).pop() ici
          } else {
            print('❌ Code RuuviTag invalide: $code');
            _showInvalidQRCodeDialog();
            setState(() {
              isScanning = false;
            });
          }
        }
      }
    }
  }

  bool _isValidRuuviTagId(String qrCode) {
    print(' Validation du code: $qrCode');
    
    // Vérifier si c'est un ID numérique de 9 chiffres
    if (RegExp(r'^\d{9}$').hasMatch(qrCode)) {
      print('✅ Code numérique valide (9 chiffres)');
      return true;
    }
    
    // Vérifier si c'est un ID personnalisé avec préfixe ruuvi_
    if (qrCode.startsWith('ruuvi_')) {
      print('✅ Code personnalisé valide (ruuvi_)');
      return true;
    }
    
    print('❌ Code invalide');
    return false;
  }

  void _showInvalidQRCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code invalide'),
        content: Text(
          'Ce QR code ne correspond pas à un RuuviTag valide.\n\n'
          'Code détecté: $lastDetectedCode\n\n'
          'Les IDs valides sont :\n'
          '• 9 chiffres (ex: 677224097)\n'
          '• Préfixe ruuvi_ (ex: ruuvi_tag_001)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _toggleTorch() async {
    await controller.toggleTorch();
    setState(() {
      isTorchOn = !isTorchOn;
    });
  }

  void _switchCamera() async {
    await controller.switchCamera();
    setState(() {
      cameraFacing = cameraFacing == CameraFacing.back 
          ? CameraFacing.front 
          : CameraFacing.back;
    });
  }

  void _resetScanning() {
    setState(() {
      isScanning = false;
      lastDetectedCode = null;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!hasPermission) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Permission caméra requise',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Veuillez autoriser l\'accès à la caméra pour scanner le QR code.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: isTorchOn ? Colors.yellow : Colors.grey,
            ),
            onPressed: _toggleTorch,
          ),
          IconButton(
            icon: Icon(
              cameraFacing == CameraFacing.back 
                  ? Icons.camera_rear 
                  : Icons.camera_front,
            ),
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: _onDetect,
                ),
                // Overlay pour montrer l'état de détection
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Détections: $detectionCount',
                          style: const TextStyle(color: Colors.white),
                        ),
                        if (lastDetectedCode != null)
                          Text(
                            'Dernier code: $lastDetectedCode',
                            style: const TextStyle(
                              color: Colors.yellow,
                              fontSize: 12,
                            ),
                          ),
                        if (isScanning)
                          const Text(
                            'Traitement en cours...',
                            style: TextStyle(color: Colors.green),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pointez la caméra vers le QR code du RuuviTag',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID attendu : 9 chiffres ou ruuvi_xxx',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isScanning)
                    ElevatedButton(
                      onPressed: _resetScanning,
                      child: const Text('Réessayer'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 