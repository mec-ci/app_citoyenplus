import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';

const _orange = Color(0xFFE65C00);

/// Visionneuse PDF.
///
/// Gère trois types de sources :
/// - un asset local (`assets/...`) ;
/// - une URL réseau absolue (`https://...`) — téléchargée puis rendue en mémoire ;
/// - un chemin relatif (`/uploads/...`) — préfixé par l'hôte de l'API.
///
/// Affiche un état de chargement, une gestion d'erreur (avec repli vers le
/// navigateur), l'indicateur de page courante et libère le contrôleur.
class LivrePdfView extends StatefulWidget {
  final String pdf;
  final String? title;

  const LivrePdfView({super.key, required this.pdf, this.title});

  @override
  // ignore: library_private_types_in_public_api
  LivrePdfViewState createState() => LivrePdfViewState();
}

class LivrePdfViewState extends State<LivrePdfView> {
  PdfControllerPinch? _controller;
  bool _loading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // Tout ce qui n'est pas un asset local est servi via le réseau.
  bool get _isNetwork => !widget.pdf.trim().startsWith('assets/');

  String get _resolvedUrl {
    final source = widget.pdf.trim();
    if (source.startsWith('http')) return source;
    return '${ApiConfig.host}${source.startsWith('/') ? '' : '/'}$source';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final source = widget.pdf.trim();
      final PdfControllerPinch controller;

      if (source.startsWith('assets/')) {
        controller = PdfControllerPinch(
          document: PdfDocument.openAsset(source),
        );
      } else {
        // Source réseau : on télécharge les octets puis on rend en mémoire
        // (pdfx ne sait pas ouvrir directement une URL).
        final response = await Dio().get<List<int>>(
          _resolvedUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        final bytes = Uint8List.fromList(response.data ?? const <int>[]);
        if (bytes.isEmpty) {
          throw Exception('Document vide');
        }
        controller = PdfControllerPinch(
          document: PdfDocument.openData(bytes),
        );
      }

      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible d’ouvrir le document.';
      });
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.tryParse(_resolvedUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        title: Text(
          widget.title?.trim().isNotEmpty == true
              ? widget.title!.trim()
              : 'Lecture PDF',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_isNetwork)
            IconButton(
              tooltip: 'Ouvrir dans le navigateur',
              icon: const Icon(Icons.open_in_new),
              onPressed: _openInBrowser,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _orange));
    }

    if (_error != null || _controller == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf_outlined,
                  size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                _error ?? 'Document indisponible.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Réessayer'),
                  ),
                  if (_isNetwork)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                      ),
                      onPressed: _openInBrowser,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Ouvrir dans le navigateur'),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        PdfViewPinch(
          controller: _controller!,
          onDocumentLoaded: (document) {
            if (mounted) setState(() => _totalPages = document.pagesCount);
          },
          onPageChanged: (page) {
            if (mounted) setState(() => _currentPage = page);
          },
        ),
        if (_totalPages > 0)
          Positioned(
            bottom: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Page $_currentPage / $_totalPages',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
