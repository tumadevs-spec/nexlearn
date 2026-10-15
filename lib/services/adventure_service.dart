
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

      // Call the Firebase Cloud Function.
      final callable = _functions.httpsCallable('generateGame');

      final result = await callable.call<Map<String, dynamic>>({
        'subject': subject,
        'topicName': topicName,
        'classNumber': classNumber,
        'age': age,
        'learningObjectives': learningObjectives,
      });

      // Convert the response into a Dart map.
      final adventure = Map<String, dynamic>.from(result.data);

      // Validate the required adventure fields.
      if (adventure['title'] is! String ||
          adventure['spawn'] is! Map ||
          adventure['clues'] is! List ||
          adventure['exit'] is! Map ||
          adventure['environment'] is! Map) {
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
