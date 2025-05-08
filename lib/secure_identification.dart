import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/signers/rsa_signer.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:pointycastle/api.dart' as crypto;
import 'package:cloud_firestore/cloud_firestore.dart';

class SecureIdentification {
  static Future<Map<String, dynamic>> generateKeyPairAndSaveQr({
    required DocumentReference sessionDocRef, // Pass the document reference
    required String sessionId,
    required DateTime expiresAt,
  }) async {
    try {
      // Generate RSA Key Pair (private and public keys)
      final keyPair = await _generateKeyPair();

      final privateKey = keyPair.privateKey as RSAPrivateKey;
      final publicKey = keyPair.publicKey as RSAPublicKey;

      // Create QR code payload
      final payload = {
        'sessionId': sessionId,
        'expiresAt': expiresAt.toIso8601String(),
        'nonce': _generateNonce(),
      };

      final jsonData = jsonEncode(payload);

      // Sign the QR code data with the private key
      final signature = await _signDataWithPrivateKey(jsonData, privateKey);

      // Save the public key to the session document
      await sessionDocRef.update({
        'publicKey': base64Encode(publicKeyModulusAndExponent(publicKey)),
      });

      // Return QR payload without public key
      return {
        'data': jsonData,
        'signature': signature,
      };
    } catch (e) {
      throw Exception('QR Generation failed: $e');
    }
  }

  static Future<void> _savePublicKeyToSession({
    required String sessionId,
    required String publicKey,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .update({
        'publicKey': publicKey,
      });
    } catch (e) {
      print('Error saving public key to session: $e');
      rethrow;
    }
  }

  // Generate RSA Key Pair (private and public keys)
  static Future<crypto.AsymmetricKeyPair<crypto.PublicKey, crypto.PrivateKey>>
      _generateKeyPair() async {
    final keyGen = RSAKeyGenerator();
    final random = FortunaRandom();
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(255));
    }
    random.seed(KeyParameter(Uint8List.fromList(seeds)));

    final params = RSAKeyGeneratorParameters(
      BigInt.parse('65537'),
      2048,
      64,
    );

    keyGen.init(ParametersWithRandom(params, random));

    return keyGen.generateKeyPair();
  }

  // Sign the data using the private key
  static Future<String> _signDataWithPrivateKey(
      String data, RSAPrivateKey privateKey) async {
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    final dataBytes = Uint8List.fromList(utf8.encode(data));
    final signature = signer.generateSignature(dataBytes);

    return base64Encode(signature.bytes);
  }

  // Save signed QR data and public key to Firebase
  static Future<void> _saveQrToFirebase(Map<String, dynamic> qrData) async {
    try {
      await FirebaseFirestore.instance.collection('qr_codes').add(qrData);
    } catch (e) {
      print('Firestore error: $e');
    }
  }

  // Generate a secure random nonce
  static String _generateNonce([int length = 16]) {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  // Helper method to get the modulus and exponent of the public key
  static Uint8List publicKeyModulusAndExponent(RSAPublicKey publicKey) {
    final modulus = publicKey.modulus!;
    final exponent = publicKey.exponent!;

    final modulusBytes = _bigIntToBytes(modulus);
    final exponentBytes = _bigIntToBytes(exponent);

    // Combine modulus and exponent bytes
    final combined = Uint8List(modulusBytes.length + exponentBytes.length);
    combined.setRange(0, modulusBytes.length, modulusBytes);
    combined.setRange(modulusBytes.length, combined.length, exponentBytes);

    return combined;
  }

  static Uint8List _bigIntToBytes(BigInt number) {
    var bytes = (number.bitLength + 7) ~/ 8;
    var b256 = BigInt.from(256);
    var result = Uint8List(bytes);
    for (var i = 0; i < bytes; i++) {
      result[bytes - 1 - i] = (number % b256).toInt();
      number = number ~/ b256;
    }
    return result;
  }

  /* RSA Signature Verification */
  static Future<bool> verifySignature({
    required String publicKeyBase64,
    required String message,
    required String signatureBase64,
  }) async {
    try {
      // Convert the public key from base64 format
      final publicKeyBytes = base64Decode(publicKeyBase64);
      final publicKey = _bytesToPublicKey(publicKeyBytes);

      // Create the signer and initialize with the public key
      final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
      signer.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));

      // Convert the message to bytes and the signature from base64 to bytes
      final messageBytes = Uint8List.fromList(utf8.encode(message));
      final signatureBytes = base64Decode(signatureBase64);

      // Verify the signature
      return signer.verifySignature(messageBytes, RSASignature(signatureBytes));
    } catch (e) {
      //debugPrint('RSA Signature verification error: $e');
      return false;
    }
  }

  // Helper method to convert bytes back to RSAPublicKey
  static RSAPublicKey _bytesToPublicKey(Uint8List bytes) {
    // Split the bytes into modulus and exponent
    // Note: This assumes the first 256 bytes are modulus and the rest are exponent
    // Adjust this based on how you're serializing the key
    final modulusBytes = bytes.sublist(0, 256);
    final exponentBytes = bytes.sublist(256);

    final modulus = _bytesToBigInt(modulusBytes);
    final exponent = _bytesToBigInt(exponentBytes);

    return RSAPublicKey(modulus, exponent);
  }

  static BigInt _bytesToBigInt(Uint8List bytes) {
    BigInt result = BigInt.zero;
    for (int i = 0; i < bytes.length; i++) {
      result = result * BigInt.from(256) + BigInt.from(bytes[i]);
    }
    return result;
  }

  /* Constant-time equality check */
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
