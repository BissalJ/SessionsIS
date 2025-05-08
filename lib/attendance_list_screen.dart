import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AttendanceListScreen extends StatefulWidget {
  final String sessionId;

  const AttendanceListScreen({super.key, required this.sessionId});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  bool _isExporting = false;

  Future<void> _exportToCSV() async {
    setState(() => _isExporting = true);

    try {
      // Get session and attendance data
      final session = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId)
          .get();

      final attendees = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId)
          .collection('attendees')
          .orderBy('timestamp')
          .get();

      // Prepare CSV data
      final csvData = [
        ['Session ID', 'Class', 'CMS ID', 'Name', 'Timestamp'],
        ...attendees.docs.map((doc) {
          final data = doc.data();
          return [
            widget.sessionId,
            session['classId'] ?? 'N/A',
            data['cmsId'] ?? 'N/A',
            data['name'] ?? 'Unknown',
            (data['timestamp'] as Timestamp?)?.toDate().toString() ?? 'N/A',
          ];
        })
      ];

      // Create CSV file in temporary directory
      final csvString = const ListToCsvConverter().convert(csvData);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/attendance_${widget.sessionId}.csv');
      await file.writeAsString(csvString);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Attendance for ${session['classId']}',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance exported successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance List'),
        actions: [
          IconButton(
            icon: _isExporting
                ? const CircularProgressIndicator()
                : const Icon(Icons.download),
            onPressed: _isExporting ? null : _exportToCSV,
            tooltip: 'Export to CSV',
          ),
        ],
      ),
      body: _buildAttendanceList(),
    );
  }

  Widget _buildAttendanceList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId)
          .collection('attendees')
          .orderBy('timestamp')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final attendees = snapshot.data!.docs;

        if (attendees.isEmpty) {
          return const Center(child: Text('No attendance records yet'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: attendees.length,
          itemBuilder: (context, index) {
            final data = attendees[index].data() as Map<String, dynamic>;
            final time =
                (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(data['name'] ?? 'Unknown'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CMS ID: ${data['cmsId'] ?? 'N/A'}'),
                    Text('Time: ${time.toString().split('.')[0]}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
