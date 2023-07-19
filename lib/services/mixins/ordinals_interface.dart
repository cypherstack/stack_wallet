import 'package:stackwallet/dto/ordinals/feed_response.dart'; // Assuming this import is necessary
import 'package:stackwallet/services/ordinals_api.dart'; // Assuming this import is necessary

mixin OrdinalsInterface {
  final OrdinalsAPI ordinalsAPI = OrdinalsAPI(baseUrl: 'http://ord-litecoin.stackwallet.com');

  Future<FeedResponse> fetchLatestInscriptions() async {
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