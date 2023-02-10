part of check_in_facade;

@LazySingleton(as: MMiscFacade)
class MiscFacade implements MMiscFacade {

  // final FirebaseFirestore _firestore;
  Location _location = Location();

  MiscFacade(
      // this._firestore
  );

  /// location services
  @override
  Stream<Either<PermissionStatus, LocationData>> getCurrentPosition() async* {
    bool _serviceEnabled;
    PermissionStatus _permission;

    _permission = await _location.hasPermission();
    _serviceEnabled = await _location.serviceEnabled();

    try {

      if (_permission == PermissionStatus.deniedForever) {
        await _location.requestPermission();
        yield left(_permission);
      }

      if (!_serviceEnabled) {
        await _location.requestService();
        yield left(_permission);
      }

      final position = await _location.getLocation().then(
                (position) => position);

      yield right(position);
    } catch (e) {
      yield left(_permission);
    }

  }

  @override
  Stream<Either<AuthFailure, LocationVerificationType>> getVerificationStatus() async* {

    try {
      yield right(LocationVerificationType.unverified);
    } catch (e) {
      yield left(AuthFailure.serverError());
    }
  }
  //
  //
  // /// news & updates services
  //
  @override
  Stream<Either<AuthFailure, NewsUpdateModel>> watchNewsUpdates() async* {
    try {
      yield right(NewsUpdateModel.empty());
    } catch (e) {
      yield left(AuthFailure.serverError());
    }
  }
}