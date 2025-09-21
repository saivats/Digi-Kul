import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// You will need to import these from their new, separate files
import '../services/api_service.dart';
import '../models/lecture.dart';
import '../models/material.dart';

// --- THEME COLORS ---
const Color primaryColor = Color(0xFF5247eb);
const Color backgroundLight = Color(0xFFf6f6f8);

class LectureDetailsScreen extends StatefulWidget {
  final Lecture lecture;
  const LectureDetailsScreen({super.key, required this.lecture});

  @override
  State<LectureDetailsScreen> createState() => _LectureDetailsScreenState();
}

class _LectureDetailsScreenState extends State<LectureDetailsScreen> {
  late Future<List<MaterialItem>> _materialsFuture;
  bool _isEnrolling = false;

  @override
  void initState() {
    super.initState();
    _materialsFuture = ApiService.getLectureMaterials(widget.lecture.id);
  }

  Future<void> _enroll() async {
    setState(() => _isEnrolling = true);
    try {
      await ApiService.enrollInLecture(widget.lecture.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Successfully Enrolled!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.red,
            content: Text('Enrollment Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isEnrolling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Lecture Details',
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              widget.lecture.title,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 16),
            _buildLecturerInfo(),
            const SizedBox(height: 8),
            Text(
              widget.lecture.description,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const Divider(height: 48, color: Colors.black12),
            _buildMaterialsSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLecturerInfo() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 28,
          // Placeholder image - you can fetch this from your teacher data
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5'),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lecture.teacherName,
              style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              widget.lecture.scheduledTime, // Use the dynamic time
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (widget.lecture.sessionActive) ...[
           ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.sensors),
            label: const Text('Join Live Session',
                style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              // TODO: Implement join live session logic
            },
          ),
          const SizedBox(height: 12),
        ],
        _isEnrolling
          ? const Center(child: CircularProgressIndicator())
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor.withOpacity(0.2),
                foregroundColor: primaryColor,
                elevation: 0,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _enroll,
              child: const Text('Enroll in Course',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
      ],
    );
  }

  Widget _buildMaterialsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Study Materials (for Offline Use)',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<MaterialItem>>(
          future: _materialsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No materials uploaded.'));
            }
            final materials = snapshot.data!;
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: materials.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _StudyMaterialCard(material: materials[index]);
              },
            );
          },
        ),
      ],
    );
  }
}

class _StudyMaterialCard extends StatelessWidget {
  final MaterialItem material;
  const _StudyMaterialCard({required this.material});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.picture_as_pdf, color: primaryColor), // Icon can be dynamic
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  '${material.fileType.toUpperCase()} - ${material.fileSizeMb.toStringAsFixed(1)} MB',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.grey),
            onPressed: () async {
               final url = Uri.parse(ApiService.getDownloadUrl(material.id));
               if (await canLaunchUrl(url)) {
                 await launchUrl(url, mode: LaunchMode.externalApplication);
               }
            },
          ),
        ],
      ),
    );
  }
}