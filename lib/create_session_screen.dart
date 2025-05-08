import 'dart:convert';
import 'dart:math';
import 'secure_identification.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'attendance_list_screen.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _classIdController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  @override
  void dispose() {
    _classIdController.dispose();
    _durationController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  String _generateNonce([int length = 12]) {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => charset[rand.nextInt(charset.length)])
        .join();
  }

  Future<void> _createSession() async {
    if (_formKey.currentState!.validate()) {
      final startTime = DateTime.now();
      final durationMinutes = int.parse(_durationController.text);
      final expiresAt = startTime.add(Duration(minutes: durationMinutes));
      final nonce = _generateNonce();
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

      // Get document reference first
      final sessionDocRef =
          FirebaseFirestore.instance.collection('sessions').doc(sessionId);

      // Prepare initial session data
      final sessionData = {
        'sessionId': sessionId,
        'classId': _classIdController.text,
        'duration': durationMinutes,
        'subject': _subjectController.text,
        'startTime': startTime.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'nonce': nonce,
        'status': 'active',
        // publicKey and signature will be added later
      };

      try {
        // First create the document with initial data
        await sessionDocRef.set(sessionData);

        // Then generate keys and add to document
        final encryptedSessionData =
            await SecureIdentification.generateKeyPairAndSaveQr(
          sessionDocRef: sessionDocRef, // Pass the reference
          sessionId: sessionId,
          expiresAt: expiresAt,
        );

        // Update with signature (publicKey was already added by generateKeyPairAndSaveQr)
        await sessionDocRef.update({
          'signature': encryptedSessionData['signature'],
        });

        // Navigate to QR code screen with encrypted payload
        final qrPayloadString = jsonEncode(encryptedSessionData);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SessionQRCodeScreen(
                qrData: qrPayloadString,
                startTime: startTime,
                subject: _subjectController.text,
                classId: _classIdController.text,
                sessionId: sessionId,
              ),
            ),
          );
        }
      } on FirebaseException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Firebase Error: ${e.message}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('General Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFF7F9FB),
        appBar: AppBar(
          title: const Text(
            'Create Session',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF2C3E5D),
          elevation: 0,
        ),
        body: Container(
          // decoration: BoxDecoration(
          //   gradient: LinearGradient(
          //     begin: Alignment.topCenter,
          //     end: Alignment.bottomCenter,
          //     colors: [
          //       Theme.of(context).primaryColor.withOpacity(0.1),
          //       Color(0xFF2C3E5D),
          //     ],
          //   ),
          // ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 500,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          color: const Color(0xFF2C3E5D),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Session Details',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: _classIdController,
                                  decoration: InputDecoration(
                                    labelText: 'Class ID',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(Icons.class_),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                          ? 'Please enter class ID'
                                          : null,
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _durationController,
                                  decoration: InputDecoration(
                                    labelText: 'Duration (minutes)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(Icons.timer),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter duration';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Enter a valid number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _subjectController,
                                  decoration: InputDecoration(
                                    labelText: 'Subject',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(Icons.book),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                          ? 'Please enter subject'
                                          : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _createSession,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5CA6D1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Create Session',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white, // ✅ Move it inside TextStyle
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}

class SessionQRCodeScreen extends StatelessWidget {
  final String qrData;
  final DateTime startTime;
  final String subject;
  final String classId;
  final String sessionId;

  const SessionQRCodeScreen({
    super.key,
    required this.qrData,
    required this.startTime,
    required this.subject,
    required this.classId,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session QR Code'),
        elevation: 0,
      ),
      body: Container(
        // decoration: BoxDecoration(
        //   gradient: LinearGradient(
        //     begin: Alignment.topCenter,
        //     end: Alignment.bottomCenter,
        //     colors: [
        //       Theme.of(context).primaryColor.withOpacity(0.1),
        //       Colors.white,
        //     ],
        //   ),
        // ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  color: const Color(0xFF2C3E5D),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Text(
                          'Session QR Code',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 250.0,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 24),
                        DefaultTextStyle(
                          style: const TextStyle(color: Colors.white),
                          child:
                              _buildInfoRow(Icons.class_, 'Class ID: $classId'),
                        ),
                        const SizedBox(height: 12),
                        DefaultTextStyle(
                          style: const TextStyle(color: Colors.white),
                          child: _buildInfoRow(Icons.book, 'Subject: $subject'),
                        ),
                        const SizedBox(height: 12),
                        DefaultTextStyle(
                          style: const TextStyle(color: Colors.white),
                          child: _buildInfoRow(
                            Icons.timer,
                            'Started at: ${startTime.toLocal().toString().split('.')[0]}',
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AttendanceListScreen(
                                  sessionId: sessionId,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.people),
                          label: const Text(
                            'View Attendance List',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
