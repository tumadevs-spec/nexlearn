import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdventureService {
  AdventureService({
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> generateAdventure({
    required String subject,
    required String topicName,
    required int classNumber,
    required int age,
    required List<String> learningObjectives,
  }) async {
    try {
      // Authenticate the player before calling the protected function.
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }

      final callable = _functions.httpsCallable('generateGame');

      final result = await callable.call<Map<String, dynamic>>({
        'subject': subject,
        'topicName': topicName,
        'classNumber': classNumber,
        'age': age,
        'learningObjectives': learningObjectives,
        // Older naming, accepted by the server as a fallback.
        'strand': subject,
        'playerAge': age,
      });

      final adventure = Map<String, dynamic>.from(result.data);

      final rawVersion = adventure['specVersion'];
      final version = rawVersion is num ? rawVersion.toInt() : null;

      if (version != 2 && version != 3) {
        throw const FormatException(
          'The adventure server is sending an old format. '
          'Update the generateGame function.',
        );
      }

      final complete = adventure['title'] is String &&
          adventure['puzzles'] is List &&
          (version == 3
              ? adventure['stages'] is List
              : (adventure['entities'] is List &&
                  adventure['spawn'] is Map &&
                  adventure['environment'] is Map));

      if (!complete) {
        throw const FormatException(
          'The AI returned an incomplete adventure.',
        );
      }

      return adventure;
    } on FirebaseAuthException catch (error) {
      throw Exception(
        'Player authentication failed '
        '[${error.code}]: '
        '${error.message ?? "Unknown authentication error"}',
      );
    } on FirebaseFunctionsException catch (error) {
      throw Exception(
        'Adventure generation failed '
        '[${error.code}]: '
        '${error.message ?? "Unknown Firebase Functions error"}',
      );
    } on FormatException catch (error) {
      throw Exception(error.message);
    }
  }
}