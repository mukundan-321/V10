import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:two_person_app/core/error/failures.dart';
import 'package:two_person_app/core/utils/result.dart';
import 'package:two_person_app/features/pairing/domain/entities/invite.dart';

class InviteApiClient {
  final String baseHttpUrl;
  final http.Client _client;

  InviteApiClient({required this.baseHttpUrl, http.Client? client})
      : _client = client ?? http.Client();

  Future<Result<Invite>> createInvite() async {
    try {
      final response = await _client
          .post(Uri.parse('$baseHttpUrl/invites'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return Err(UnknownFailure(
            'Signaling server returned ${response.statusCode}.'));
      }

      final map = jsonDecode(response.body) as Map<String, dynamic>;
      return Ok(Invite(
        id: map['inviteId'] as String,
        expiresAt: DateTime.parse(map['expiresAt'] as String),
      ));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }
}
