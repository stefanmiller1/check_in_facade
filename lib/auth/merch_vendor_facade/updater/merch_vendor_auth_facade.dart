part of check_in_facade;

@LazySingleton(as: MVAuthFacade)
class MerchantVendorAuthFacade implements MVAuthFacade {

  final FirebaseFirestore _fireStore;
  final FirebaseAuth _firebaseAuth;
  final FirebaseStorage _firebaseStorage;

  MerchantVendorAuthFacade(
      this._fireStore,
      this._firebaseAuth,
      this._firebaseStorage
    );


  @override
  Future<Either<ProfileValueFailure, Unit>> createUpdateMerchantVendor({required EventMerchantVendorProfile merchProfileItem}) async {

    late EventMerchantVendorProfile newProfileItem;
    newProfileItem = merchProfileItem;

    try {

      if (_firebaseAuth.currentUser == null) {
        return left(const ProfileValueFailure.profileServerError());
      }

      if (newProfileItem.uriImage?.imageToUpload != null) {
        final Uint8List imageData = newProfileItem.uriImage!.imageToUpload!;

        final urlId = _firebaseAuth.currentUser!.uid;
        final reference = _firebaseStorage.ref('vendor_merch_profile').child(newProfileItem.profileId.getOrCrash());
        await reference.putData(imageData);

        final uri = await reference.getDownloadURL();

        newProfileItem = newProfileItem.copyWith(
           uriImage: ImageUpload(key: uri, uriPath: uri)
        );
      }

      newProfileItem = newProfileItem.copyWith(
        profileOwner: UniqueId.fromUniqueString(_firebaseAuth.currentUser!.uid)
      );


      final merchVendorDto = EventMerchantVendorProfileDto.fromDomain(newProfileItem).toJson();
      final merchVendorDoc = _fireStore.collection('vendor_merch_profile').doc(newProfileItem.profileId.getOrCrash());

      merchVendorDoc.set(merchVendorDto);

      return right(unit);
    } catch (e) {
      return left(ProfileValueFailure.profileServerError(serverResponse: e.toString()));
    }
  }

  @override
  Future<Either<ProfileValueFailure, Unit>> newMerchantVendorPartner({required UniqueId profileId}) async {

    try {

      return left(const ProfileValueFailure.profileServerError());
    } catch (e) {
      return left(ProfileValueFailure.profileServerError(serverResponse: e.toString()));
    }
  }


  @override
  Future<Either<ProfileValueFailure, Unit>> deleteMerchantVendorAccount({required EventMerchantVendorProfile profile}) async {
    /// delete photo too
    try {

      if (_firebaseAuth.currentUser == null) {
        return left(const ProfileValueFailure.profileServerError());
      }

      final reference = _firebaseStorage.ref('vendor_merch_profile').child(profile.profileId.getOrCrash());
      reference.delete();

      final merchantDoc = _fireStore.collection('vendor_merch_profile').doc(profile.profileId.getOrCrash());
      merchantDoc.delete();

      return right(unit);
    } catch (e) {
      return left(ProfileValueFailure.profileServerError(serverResponse: e.toString()));
    }

  }



}