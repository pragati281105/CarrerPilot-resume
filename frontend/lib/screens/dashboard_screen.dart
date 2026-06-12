// lib/screens/dashboard_screen.dart

import 'dart:io';
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
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {

  ATSResult ? atsResult;

  File? selectedFile;

  final TextEditingController jdController =
      TextEditingController();

  @override
  void dispose() {
    jdController.dispose();
    super.dispose();
  }

  Future<void> analyzeResume() async {
    if (selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select a resume first",
          ),
        ),
      );
      return;
    }

    try {
      final response =
          await ApiService.uploadResume(
        filePath: selectedFile!.path,
        jdText: jdController.text,
      );

      print(response);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Resume analyzed successfully",
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
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
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const _TopBar(),
                      const SizedBox(height: 24),

                      Expanded(
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [

                            Expanded(
                              flex: 2,
                              child: _UploadCard(
                                onFileSelected: (file) {
                                  setState(() {
                                    selectedFile = file;
                                  });
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
                                      controller:jdController,
                                      onAnalyze:analyzeResume,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 20,
                                  ),

                                  Expanded(
                                    child: _ATSCard(
                                      atsResult: atsResult,
                                    ),
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

// ── Ambient background — two drifting amber orbs + dot grid ──────────────────

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
                  Color(0x28F59E0B), // amber at 16%
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
                    Color(0x1AD97706), // deep gold at 10%
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

// ── Dot grid overlay painter ──────────────────────────────────────────────────

class DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04);

    const spacing = 24.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(
          Offset(x, y),
          1,
          paint,
        );
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
          // Logo mark
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
        // Active amber indicator line on the left edge
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


// ── Reusable glass card wrapper ───────────────────────────────────────────────

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
// ── Resume Upload card ────────────────────────────────────────────────────────
class _UploadCard extends StatelessWidget {
  final Function(File file) onFileSelected;

  const _UploadCard({
    super.key,
    required this.onFileSelected,
  });
  @override
  @override
Widget build(BuildContext context) {
  return _GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.upload_file_outlined,
              color: AppTheme.amber,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Resume',
              style: GoogleFonts.inter(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        Expanded(
          child: DottedBorder(
            color: AppTheme.amber,
            dashPattern: const [8, 4],
            borderType: BorderType.RRect,
            radius: const Radius.circular(16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppTheme.amber.withOpacity(0.04),
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
                    child: const Icon(
                      Icons.cloud_upload_outlined,
                      color: AppTheme.amber,
                      size: 28,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Drag your resume here',
                    style: GoogleFonts.inter(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'PDF, DOCX, JPG, PNG',
                    style: GoogleFonts.inter(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
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
                        );

                        if (result != null) {
                          final file = File(
                            result.files.single.path!,
                          );

                          onFileSelected(file);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.amber,
                        side: const BorderSide(
                          color: AppTheme.amber,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Browse files',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                        ),
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
                  padding:
                      const EdgeInsets.only(right: 8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.glassWhite,
                      borderRadius:
                          BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.glassBorder,
                      ),
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

  const _JDCard({
    super.key,
    required this.controller,
    required this.onAnalyze,
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
              const Icon(
                Icons.link,
                color: AppTheme.amber,
                size: 18,
              ),
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
                  horizontal: 12,
                  vertical: 6,
                ),
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
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.glassWhite,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Text Area',
                  style: TextStyle(
                    color: Colors.white,
                  ),
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
              onPressed:onAnalyze,
              child: Text(
                'Analyze Resume',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ATS Score card ────────────────────────────────────────────────────────────

class _ATSCard extends StatelessWidget {
  final ATSResult? atsResult;

  const _ATSCard({
    super.key,
    required this.atsResult,
  });

  String get verdict {
    final score = atsResult?.finalScore ?? 0;

    if (score >= 80) {
      return "Excellent Match";
    }

    if (score >= 65) {
      return "Good Match";
    }

    if (score >= 50) {
      return "Average Match";
    }

    return "Poor Match";
  }

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined,
                  color: AppTheme.amber, size: 18),
              const SizedBox(width: 8),
              Text(
                'ATS Score',
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${atsResult?.finalScore.toStringAsFixed(0) ?? 0}/100',
                style: GoogleFonts.inter(
                  color: AppTheme.amber,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Circular ATS score dial
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: (atsResult?.finalScore ?? 0) / 100,
                      strokeWidth: 10,
                      backgroundColor: AppTheme.glassWhite,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.amber,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${atsResult?.finalScore.toStringAsFixed(0) ?? 0}',
                        style: GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'ATS Score',
                        style: GoogleFonts.inter(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppTheme.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                verdict,
                style: GoogleFonts.inter(
                  color: AppTheme.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _ScoreBar(label: 'JD Match', value: (atsResult?.matchRate??0)/100),
          const SizedBox(height: 10),
          _ScoreBar(label: 'Format', value: (atsResult?.similarityScore??0)/100),
          const SizedBox(height: 10),
          _ScoreBar(label: 'Keywords', value: (atsResult?.matchRate??0)/100),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double value; // 0.0 to 1.0

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
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.amber),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}