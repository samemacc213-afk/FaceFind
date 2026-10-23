import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_manager.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FaceFindApp());
  Future.delayed(const Duration(seconds: 2), () {
    AdManager.instance.initialize().catchError((_) {});
  });
}

class FaceFindApp extends StatelessWidget {
  const FaceFindApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => Column(children: [
        Expanded(child: child ?? const SizedBox.shrink()),
        AdManager.instance.bannerSlot(),
      ]),
      title: 'FaceFind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff20d997),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xff101827),
        useMaterial3: true,
      ),
      home: const SearchPage(),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final nameController = TextEditingController();
  final picker = ImagePicker();
  XFile? photo;
  String? error;
  String? faceResult;
  final faceDetector = FaceDetector(options: FaceDetectorOptions());

  Future<void> choosePhoto() async {
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file != null && mounted) {
      setState(() {
        photo = file;
        error = null;
        faceResult = 'ছবি বিশ্লেষণ হচ্ছে...';
      });
      try {
        final input = InputImage.fromFilePath(file.path);
        final faces = await faceDetector.processImage(input);
        if (mounted) setState(() => faceResult = faces.isEmpty
            ? 'ছবিতে কোনো মুখ শনাক্ত হয়নি।'
            : 'ছবিতে ${faces.length}টি মুখ শনাক্ত হয়েছে।');
      } catch (e) {
        if (mounted) setState(() => faceResult = 'মুখ শনাক্ত করা যায়নি: $e');
      }
    }
  }

  Future<void> openSearch(String platform) async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      setState(() => error = 'আগে নাম বা ইউজারনেম লিখুন।');
      return;
    }
    final query = Uri.encodeComponent(name);
    final url = platform == 'Facebook'
        ? 'https://www.google.com/search?q=$query+site%3Afacebook.com'
        : 'https://www.google.com/search?q=$query+site%3Ainstagram.com';
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      setState(() => error = 'সার্চ লিংক খোলা যায়নি। আবার চেষ্টা করুন।');
    }
  }

  @override
  void dispose() {
    faceDetector.close();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔎 FaceFind',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            const Text('Find public social profiles',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'ছবি বেছে নিন অথবা নাম/ইউজারনেম দিয়ে পাবলিক সার্চ করুন।',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xff1e293b),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: choosePhoto,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      height: 190,
                      decoration: BoxDecoration(
                        color: const Color(0xff111827),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: photo == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                    size: 54, color: Color(0xff20d997)),
                                SizedBox(height: 12),
                                Text('বন্ধুর ছবি বেছে নিন'),
                                Text('গ্যালারি খুলতে চাপ দিন',
                                    style: TextStyle(color: Colors.white60)),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                File(photo!.path),
                                fit: BoxFit.contain,
                              ),
                            ),
                    ),
                  ),
                  if (faceResult != null) ...[
                    const SizedBox(height: 10),
                    Text(faceResult!, textAlign: TextAlign.center),
                  ],
                  if (photo != null)
                    TextButton.icon(
                      onPressed: choosePhoto,
                      icon: const Icon(Icons.refresh),
                      label: const Text('অন্য ছবি বাছুন'),
                    ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => openSearch('Facebook'),
                    decoration: InputDecoration(
                      labelText: 'নাম বা ইউজারনেম',
                      hintText: 'যেমন: rahim123',
                      prefixIcon: const Icon(Icons.person_search),
                      filled: true,
                      fillColor: const Color(0xff101827),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!,
                        style: const TextStyle(color: Colors.orangeAccent)),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => openSearch('Facebook'),
                      icon: const Icon(Icons.facebook),
                      label: const Text('Search Facebook'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () => openSearch('Instagram'),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Search Instagram'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'নোট: ছবি নির্বাচন করা যায়, কিন্তু এই সংস্করণ মুখ শনাক্ত করে '
              'Facebook/Instagram অ্যাকাউন্ট খুঁজে পায় না। সার্চ ফলাফল '
              'বাইরের সার্চ ইঞ্জিনের ওপর নির্ভরশীল; কোনো মিল নিশ্চিত নয়।',
              style: TextStyle(color: Colors.white60, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text('FaceFind • Version 1.0.0',
                  style: TextStyle(color: Colors.white38)),
            ),
          ],
        ),
      ),
    );
  }
}
