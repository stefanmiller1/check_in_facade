part of check_in_facade;

@LazySingleton(as: AAuthFacade)
class ActivityFormFacade implements AAuthFacade {

  final FirebaseFirestore _fireStore;
  final FirebaseStorage _firebaseStorage;
  final NAuthFacade _notificationFacade;

  ActivityFormFacade(
      this._fireStore,
      this._firebaseStorage,
      this._notificationFacade
    );


  @override
  Future<Either<ActivityFormFailure, Unit>> updateActivitySettingsForm({required ActivityManagerForm activityForm, required activityResId}) async {


    try {

      ActivityManagerForm newActivityForm = activityForm;

      final List<ImageUpload> activityImages = [];
      activityImages.addAll(newActivityForm.profileService.activityBackground.activityProfileImages ?? []);

      /// store activity profile images if new ones exists
      for (ImageUpload images in activityImages) {
        if (images.imageToUpload != null) {
          /// store the file
          final urlId = UniqueId();
          final reference = _firebaseStorage.ref('activity_directory').child(activityResId.getOrCrash());
          await reference.child(urlId.getOrCrash()).putData(images.imageToUpload!);
          /// retrieve link to file stored in firebase storage
          final uri = await reference.child(urlId.getOrCrash()).getDownloadURL();
          /// update list with new link item
          final index = activityImages.indexWhere((element) => element.key == images.key);
          final ImageUpload newImage = ImageUpload(key: uri, uriPath: uri);
          activityImages.replaceRange(index, index+1, [newImage]);
      }
    }

      /// update images in [ActivityProfileBackground]
      newActivityForm = newActivityForm.copyWith(
        activityFormId: activityResId,
        profileService: newActivityForm.profileService.copyWith(
          activityBackground: newActivityForm.profileService.activityBackground.copyWith(
            activityProfileImages: activityImages
          )
        )
      );


      final reservationDoc = await _fireStore.reservationDocument(activityResId.getOrCrash());
      final activityDoc = await _fireStore.activityDocument(activityResId.getOrCrash());
      final activityFormDto = ActivityManagerFormDto.fromDomain(newActivityForm).toJson();
      await activityDoc.set(activityFormDto);

      await _notificationFacade.createUpdatedReservationActivityNotification(reservationId: activityResId.getOrCrash());

      /// update reservation state
      if (activitySetupComplete(newActivityForm)) {
        reservationDoc.update({'isActivity': true});
      } else {
        reservationDoc.update({'isActivity': false});
      }

      return right(unit);
    } on FirebaseAuthException catch (e) {
      if (e.toString().contains('permission-denied') || e.toString().contains('unknown')) {
        return left(const ActivityFormFailure.permissionDenied());
      } else {
        return left(const ActivityFormFailure.activityServerError());
      }
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        return left(const ActivityFormFailure.permissionDenied());
      }
      return left(const ActivityFormFailure.unexpected());
    }
  }


  // @override
  // Future<Either<ActivityFormFailure, Unit>> createCompletedActivityForm({required ActivityCreatorForm activityForm}) async {
  //
  //   final activityId = activityForm.activityFormId.getOrCrash();
  //
  //   try {
  //
  //     final currentUserId = _firebaseAuth.currentUser;
  //     final userProfileSession = ProfileSession(
  //         profileSessionId: UniqueId.fromUniqueString(activityId),
  //         ownerId: UniqueId.fromUniqueString(currentUserId!.uid),
  //         facilityType: ProfileFacilityType.none,
  //         activityType: activityForm.activityType.activity,
  //         isActivity: true,
  //         isFacility: false,
  //         isSession: false
  //     );
  //
  //
  //     await createActivityForm(activityForm: activityForm);
  //     await createActivityManagerProfile(activityForm: activityForm);
  //     await _locationFacade.createNewLocationFacilitySession(sessionProfile: userProfileSession);
  //     await _locationFacade.createNewProfileLocationAuth(location: activityForm.activityLocations);
  //
  //
  //     return right(unit);
  //   } on FirebaseAuthException catch (e) {
  //     if (e.toString().contains('permission-denied') || e.toString().contains('unknown')) {
  //       return left(const ActivityFormFailure.activityServerError());
  //     } else {
  //       return left(const ActivityFormFailure.unexpected());
  //     }
  //   } catch (e) {
  //     if (e.toString().contains('permission-denied')) {
  //       return left(const ActivityFormFailure.permissionDenied());
  //     }
  //     return left(const ActivityFormFailure.unexpected());
  //   }
  //
  // }


  // @override
  // Future<Either<ActivityFormFailure, Unit>> createActivityManagerProfile({required ActivityCreatorForm activityForm}) async {
  //
  //   final activityId = activityForm.activityFormId.getOrCrash();
  //
  //   try {
  //
  //     final currentUserId = _firebaseAuth.currentUser;
  //     final activityDoc = await _fireStore.activityDocument(activityId);
  //
  //
  //     final activityManagerProfile = ActivityManagerProfile(
  //         activityOwnerId: UniqueId.fromUniqueString(currentUserId!.uid),
  //         activityCoOwners: [],
  //         activityName: activityId,
  //         activityStatus: ManagerActivityStatusType.comingUp,
  //         activityLocationId: UniqueId.fromUniqueString(activityForm.activityLocations.placeId),
  //         activityEmail: EmailAddress(currentUserId.email),
  //         activityPhone: PhoneNumber(isoCode: IsoCode.CA, nsn: ''),
  //         sessionStart: activityForm.activityAvailability.fromStarting,
  //         sessionEnd: activityForm.activityAvailability.fromEnding,
  //         activityIsPrivate: false
  //     );
  //
  //
  //     final activityManagerProfileDto = ActivityManagerProfileDto.fromDomain(activityManagerProfile).toJson();
  //     await activityDoc.set(activityManagerProfileDto);
  //
  //     return right(unit);
  //   } catch (e) {
  //     return left(const ActivityFormFailure.unexpected());
  //   }
  // }


  /// UPDATE EVENTS ///

  @override
  Future<Either<ActivityFormFailure, Unit>> updateFacilityManagerProfile({
    required String activityId,
    required activityForm}) {
    // TODO: implement updateFacilityManagerProfile
    throw UnimplementedError();
  }


}


