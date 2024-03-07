part of check_in_facade;

class LocationSearchModel {

  final String key;
  final String placeId;
  final String description;
  final String secondary;
  final String postalCode;

  LocationSearchModel(this.key, this.placeId, this.description, this.secondary, this.postalCode);

}


class AutoCompleteSearchModel extends ChangeNotifier {

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String _query = '';
  String get query => _query;
  String? _sessionToken;


  double _placeLat = 0;
  double get placeLat => _placeLat;

  double _placeLng = 0;
  double get placeLng => _placeLng;

  List<LocationSearchModel> _suggestions = history;
  List<LocationSearchModel> get suggestions => _suggestions;

  var uuid = Uuid();

  void onQueryChanged(BuildContext context, String query, String language) async {
    _sessionToken ??= uuid.v4();
    if (query == _query) return;

    _query = query;
    _isLoading = true;
    notifyListeners();

    if (_query.isEmpty) {
      _suggestions = history;

    } else {
      final String selectedLanguage = language;
      const String type = 'geocode&language';


      const String baseURL = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
      final String request = '$baseURL?input=$_query&types=$type=$selectedLanguage&key=$PLACES_API_KEY&sessiontoken=$_sessionToken';

      try {
        print('trying');
        final http.Response response = await http.get(Uri.parse(request));
        final predictions = jsonDecode(response.body)['predictions'] as List;



        _suggestions = predictions.map((e) =>
            LocationSearchModel(
                'search',
                e['place_id'] as String,
                e['description'] as String,
                e['structured_formatting']['secondary_text'] as String,
                e['structured_formatting']['secondary_text'] as String
            )
        ).toList();
      } catch (e) {
        _isLoading = false;
      }
    }
    _isLoading = false;
  }


  void onLoadedLocations(List<LocationSearchModel> locations) async {
    try {
      if (locations.isNotEmpty != null) {
        _isLoading = true;
        notifyListeners();

        _suggestions = locations.map(
                (e) => LocationSearchModel(
                'history',
                e.placeId,
                e.description,
                e.secondary,
                e.postalCode,
            )
        ).toList();
      }
    } catch (e) {
      _isLoading = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  void endLoading() {
    _isLoading = false;
  }

  void clear() {
    _suggestions = history;
    _isLoading = false;
    notifyListeners();
  }

}

List<LocationSearchModel> history = [

];