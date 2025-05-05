part of check_in_facade;

@LazySingleton(as: LOAuthFacade)
class LocationAuthFacade implements LOAuthFacade {

  final FirebaseFirestore _fireStore;
  final FirebaseStorage _firebaseStorage;
  final FirebaseAuth _firebaseAuth;

  LocationAuthFacade(
      this._fireStore,
      this._firebaseStorage,
      this._firebaseAuth
      );

  @override
  Future<Either<AuthFailure, Unit>> createNewLocationFacilitySession({required ProfileSession sessionProfile}) async {

    final facilityId = sessionProfile.profileSessionId.getOrCrash();

    try {

      final locationDoc = await _fireStore.locationsDocument(facilityId);

      final profileSessionDto = ProfileSessionDto.fromDomain(sessionProfile).toJson();
      await locationDoc.locationsDocument.doc(facilityId).set(profileSessionDto);

      return right(unit);
    }  catch (e) {
      return left(AuthFailure.serverError());
    }
  }


  @override
  Future<Either<AuthFailure, LocationModel>> createNewProfileLocationAuth({required LocationModel location}) async {
    final facilityId = location.placeId;
    final currentUserId = _firebaseAuth.currentUser;

    try {

      LocationModel newLocationModel = location;

      final List<ImageUpload> imageUploads = [];
      imageUploads.addAll(location.imageUploads ?? []);

      for (ImageUpload image in imageUploads) {
        if (image.imageToUpload != null) {

          /// store image to firebase storage
          final urlId = UniqueId();
          final locationReference = _firebaseStorage.ref('location_media)').child(facilityId);
          await locationReference.putData(image.imageToUpload!);
          /// retrieve link to file stored in firebase storage;
          final uri = await locationReference.child(urlId.getOrCrash()).getDownloadURL();
          /// update list with new link item
          final index = imageUploads.indexWhere((element) => element.key == image.key);
          final ImageUpload newImage = ImageUpload(key: uri, uriPath: uri);
          imageUploads.replaceRange(index, index+1, [newImage]);
        }
      }

      newLocationModel = newLocationModel.copyWith(
        imageUploads: imageUploads
      );

      final userDoc = await _fireStore.userDocument();
      final locationDoc = await _fireStore.locationsDocument(facilityId);

      
      final profileLocationDto = LocationModelDto.fromDomain(newLocationModel).toJson();
      final locationDto = LocationModelDto.fromDomain(newLocationModel).toJson();

      await userDoc.locationsDocument.doc(facilityId).set(profileLocationDto);
      await locationDoc.set(locationDto);

      return right(newLocationModel);
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        return left(AuthFailure.insufficientPermission());
      }
      return left(AuthFailure.serverError());
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> deleteProfileLocationAuth({required String locationId}) {
    // TODO: implement deleteProfileLocationAuth
    throw UnimplementedError();
  }


}