import 'package:stackwallet/services/ordinals_api.dart';
import 'package:stackwallet/dto/ordinals/feed_response.dart';

mixin OrdinalsInterface {
  Future<FeedResponse> fetchLatestInscriptions(OrdinalsAPI ordinalsAPI) async {
    try {
      final feedResponse = await ordinalsAPI.getLatestInscriptions();
      // Process the feedResponse data as needed
      print('Latest Inscriptions:');
      for (var inscription in feedResponse.inscriptions) {
        print('Title: ${inscription.title}, Href: ${inscription.href}');
      }
      return feedResponse;
    } catch (e) {
      // Handle errors
      throw Exception('Error in OrdinalsInterface: $e');
    }
  }
}
