import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:ramadhan_companion_app/helper/distance_calculation.dart';
import 'package:ramadhan_companion_app/provider/sadaqah_provider.dart';
import 'package:ramadhan_companion_app/provider/webview_provider.dart';
import 'payment_results_view.dart';

class WebViewPage extends StatelessWidget {
  final String url;
  final String title;
  final String? notificationDocId;
  final String? sadaqahId;
  final String? programmeId;

  const WebViewPage({
    super.key,
    required this.url,
    required this.title,
    this.notificationDocId,
    this.sadaqahId,
    this.programmeId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PaymentWebViewProvider(),
      child: Consumer<PaymentWebViewProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(context, title),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Column(
                      children: [
                        // 🔵 PROGRESS BAR
                        provider.progress < 1
                            ? LinearProgressIndicator(
                                value: provider.progress,
                                backgroundColor: Colors.grey.shade300,
                                minHeight: 4,
                              )
                            : const SizedBox.shrink(),

                        // 🔵 WEBVIEW
                        Expanded(
                          child: InAppWebView(
                            initialUrlRequest: URLRequest(
                              url: WebUri(formatUrl(url)),
                            ),

                            // ⬅️ update loading progress
                            onProgressChanged: (controller, progress) {
                              provider.setProgress(progress / 100);
                            },

                            onLoadStop: (controller, uri) async {
                              if (uri == null) return;
                              final currentUrl = uri.toString();
                              debugPrint("Redirected to: $currentUrl");

                              if (currentUrl.contains("/success/")) {
                                provider.setStatus("success");

                                try {
                                  if (notificationDocId != null) {
                                    await FirebaseFirestore.instance
                                        .collection('notifications')
                                        .doc(notificationDocId)
                                        .update({'paid': true});
                                  }

                                  bool isProgramme = false;

                                  if (sadaqahId != null) {
                                    await context
                                        .read<SadaqahProvider>()
                                        .paySadaqah(sadaqahId!);
                                  }

                                  if (programmeId != null) {
                                    isProgramme = true;
                                    await FirebaseFirestore.instance
                                        .collection('masjidProgrammes')
                                        .doc(programmeId)
                                        .update({
                                          'status': 'paid',
                                          'paid': true,
                                        });
                                  }

                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PaymentResultsView(
                                        isSuccess: true,
                                        isProgramme: isProgramme,
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  debugPrint("❌ Firestore update error: $e");
                                }
                              } else if (currentUrl.contains("/failure/")) {
                                provider.setStatus("failure");
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PaymentResultsView(
                                      isSuccess: false,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget _buildAppBar(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
        ),
      ],
    ),
  );
}
