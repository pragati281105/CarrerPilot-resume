// lib/screens/dashboard_screen.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';

import '../theme/app_theme.dart';
import '../models/ats_result.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  ATSResult? atsResult;
  PlatformFile? selectedFile; // ← changed from File to PlatformFile
  bool isLoading = false;     // ← added loading state

  final TextEditingController jdController = TextEditingController();

  @override
  void dispose() {
    jdController.dispose();
    super.dispose();
  }

  Future<void> analyzeResume() async {
    if (selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a resume first")),
      );
      return;
    }

    if (jdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a job URL or JD text")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await ApiService.uploadResume(
        file: selectedFile!, // ← passes PlatformFile directly
        jdText: jdController.text.trim(),
      );

      setState(() {
        atsResult = ATSResult.fromJson(response);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Resume analyzed successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Stack(
        children: [
          const _AmbientBackground(),
          Row(
            children: [
              const _Sidebar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _TopBar(),
                      const SizedBox(height: 24),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _UploadCard(
                                selectedFile: selectedFile,
                                onFileSelected: (file) {
                                  setState(() => selectedFile = file);
                                },
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: _JDCard(
                                      controller: jdController,
                                      onAnalyze: analyzeResume,
                                      isLoading: isLoading,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Expanded(
                                    child: _ATSCard(atsData: atsResult?.toJson()),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Ambient background ────────────────────────────────────────────────────────

class _AmbientBackground extends StatefulWidget {
  const _AmbientBackground();

  @override
  State<_AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<_AmbientBackground>
    with TickerProviderStateMixin {
  late final AnimationController _c1;
  late final AnimationController _c2;
  late final Animation<Alignment> _orb1;
  late final Animation<Alignment> _orb2;

  @override
  void initState() {
    super.initState();

    _c1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _c2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 11),
    )..repeat(reverse: true);

    _orb1 = AlignmentTween(
      begin: const Alignment(-0.6, -0.5),
      end: const Alignment(0.2, 0.4),
    ).animate(CurvedAnimation(parent: _c1, curve: Curves.easeInOut));

    _orb2 = AlignmentTween(
      begin: const Alignment(0.5, 0.3),
      end: const Alignment(-0.1, -0.6),
    ).animate(CurvedAnimation(parent: _c2, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c1.dispose();
    _c2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_c1, _c2]),
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: _orb1.value,
                radius: 0.9,
                colors: const [
                  Color(0x28F59E0B),
                  Colors.transparent,
                ],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: _orb2.value,
                  radius: 0.7,
                  colors: const [
                    Color(0x1AD97706),
                    Colors.transparent,
                  ],
                ),
              ),
              child: CustomPaint(
                painter: DotGridPainter(),
                size: Size.infinite,
              ),
            ),
          );
        },
      ),
    );
  }
}

class DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.04);
    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Sidebar ───────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          right: BorderSide(color: AppTheme.glassBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.amber,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bolt, color: Colors.black, size: 20),
          ),
          const SizedBox(height: 40),
          _SidebarIcon(icon: Icons.upload_file_outlined, isActive: true),
          const SizedBox(height: 28),
          _SidebarIcon(icon: Icons.analytics_outlined),
          const SizedBox(height: 28),
          _SidebarIcon(icon: Icons.work_outline),
          const SizedBox(height: 28),
          _SidebarIcon(icon: Icons.settings_outlined),
          const Spacer(),
          _SidebarIcon(icon: Icons.person_outline),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SidebarIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;

  const _SidebarIcon({required this.icon, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        if (isActive)
          Positioned(
            left: 0,
            child: Container(
              width: 3,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.amber,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        Center(
          child: Icon(
            icon,
            color: isActive ? AppTheme.amber : AppTheme.textMuted,
            size: 22,
          ),
        ),
      ],
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'CareerPilot',
          style: GoogleFonts.inter(
            color: AppTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.amberGlow,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.amber.withOpacity(0.4)),
          ),
          child: Text(
            'AI',
            style: GoogleFonts.inter(
              color: AppTheme.amber,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.glassWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.add, color: AppTheme.amber, size: 16),
              const SizedBox(width: 6),
              Text(
                'New Application',
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Glass card ────────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const _GlassCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.glassWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.glassBorder, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Upload card ───────────────────────────────────────────────────────────────

class _UploadCard extends StatelessWidget {
  final PlatformFile? selectedFile; // ← shows file name after selection
  final Function(PlatformFile file) onFileSelected; // ← PlatformFile not File

  const _UploadCard({
    required this.onFileSelected,
    this.selectedFile,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.upload_file_outlined,
                  color: AppTheme.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'Resume',
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Show selected filename in the header
              if (selectedFile != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedFile!.name,
                    style: GoogleFonts.inter(
                      color: AppTheme.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: DottedBorder(
              color: selectedFile != null
                  ? AppTheme.amber
                  : AppTheme.amber.withOpacity(0.5),
              dashPattern: const [8, 4],
              borderType: BorderType.RRect,
              radius: const Radius.circular(16),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: selectedFile != null
                      ? AppTheme.amber.withOpacity(0.08)
                      : AppTheme.amber.withOpacity(0.04),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.amberGlow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        selectedFile != null
                            ? Icons.check_circle_outline
                            : Icons.cloud_upload_outlined,
                        color: AppTheme.amber,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      selectedFile != null
                          ? 'File selected!'
                          : 'Drag your resume here',
                      style: GoogleFonts.inter(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedFile != null
                          ? selectedFile!.name
                          : 'PDF, DOCX, JPG, PNG',
                      style: GoogleFonts.inter(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 140,
                      child: OutlinedButton(
                        onPressed: () async {
                          final result =
                              await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: [
                              'pdf',
                              'docx',
                              'jpg',
                              'png',
                            ],
                            withData: true, // ← required for web
                          );

                          if (result != null &&
                              result.files.isNotEmpty) {
                            onFileSelected(result.files.first);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.amber,
                          side: const BorderSide(color: AppTheme.amber),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          selectedFile != null
                              ? 'Change file'
                              : 'Browse files',
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: ['PDF', 'DOCX', 'JPG', 'PNG']
                .map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.glassWhite,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: Text(
                        type,
                        style: GoogleFonts.inter(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Job Description card ──────────────────────────────────────────────────────

class _JDCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAnalyze;
  final bool isLoading; // ← added loading state

  const _JDCard({
    required this.controller,
    required this.onAnalyze,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, color: AppTheme.amber, size: 18),
              const SizedBox(width: 8),
              Text(
                'Job Description',
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'URL',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.glassWhite,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Text Area',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            style: GoogleFonts.inter(
              color: AppTheme.textPrimary,
              fontSize: 13,
            ),
            decoration: const InputDecoration(
              hintText: 'Paste job URL or JD text...',
              prefixIcon: Icon(
                Icons.search,
                color: AppTheme.textMuted,
                size: 18,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onAnalyze, // ← disabled while loading
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text(
                      'Analyze Resume',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ATS Score Card (Fixed - Null Safe) ───────────────────────────────────────
class _ATSCard extends StatelessWidget {
  final Map<String, dynamic>? atsData;

  const _ATSCard({super.key, this.atsData});

  @override
  Widget build(BuildContext context) {
    // Show placeholder when no data
    if (atsData == null || atsData!.isEmpty) {
      return _GlassCard(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics_outlined, size: 48, color: Colors.white38),
              SizedBox(height: 16),
              Text(
                "ATS Score will appear here",
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Safe extraction with fallbacks
    final score = (atsData!['final_score'] ??
                   atsData!['finalScore'] ??
                   atsData!['similarity_score'] ?? 0).toDouble();

    final verdict = (atsData!['verdict'] ?? 'Poor Match').toString();
    final missing = atsData!['missing_keywords'] ??
                    atsData!['missingKeywords'] ?? [];

    // Dynamic color
    Color scoreColor = AppTheme.danger;
    if (score >= 80) {
      scoreColor = const Color(0xFF10B981); // green
    } else if (score >= 60) {
      scoreColor = AppTheme.amber;
    }

    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined, color: AppTheme.amber, size: 18),
                const SizedBox(width: 8),
                Text('ATS Score',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${score.toStringAsFixed(0)}/100',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.amber)),
              ],
            ),
            const SizedBox(height: 24),

            // Circular Progress
            Center(
              child: SizedBox(
                width: 135,
                height: 135,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 13,
                      backgroundColor: AppTheme.glassBorder,
                      valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          score.toStringAsFixed(0),
                          style: GoogleFonts.inter(
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text("Score", style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  verdict,
                  style: GoogleFonts.inter(
                    color: scoreColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            if (missing.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                "Missing Keywords",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: missing.take(8).map<Widget>((keyword) => Chip(
                  label: Text(keyword.toString()),
                  backgroundColor: AppTheme.danger.withOpacity(0.15),
                  labelStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double value;

  const _ScoreBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: AppTheme.glassWhite,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.amber),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}