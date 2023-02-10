part of check_in_facade;

abstract class MMiscFacade {

  /// location services watcher
  Stream<Either<PermissionStatus, LocationData>> getCurrentPosition();
  Stream<Either<AuthFailure, LocationVerificationType>> getVerificationStatus();

  /// app updates and news services watcher
  Stream<Either<AuthFailure, NewsUpdateModel>> watchNewsUpdates();

}