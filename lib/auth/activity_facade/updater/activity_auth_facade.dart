part of check_in_facade;

@LazySingleton(as: AAuthFacade)
class ActivityFormFacade implements AAuthFacade {

  final FirebaseFirestore _fireStore;
  final FirebaseAuth _firebaseAuth;
  final LocationAuthFacade _locationFacade;


  ActivityFormFacade(
      this._fireStore,
      this._firebaseAuth,
      this._locationFacade
      );


  @override
  Future<Either<ActivityFormFailure, Unit>> createActivityForm({required ActivityCreatorForm activityForm}) async {

    final activityId = activityForm.activityFormId.getOrCrash();

    try {

      final currentUserId = _firebaseAuth.currentUser;
      final userDoc = await _fireStore.userDocument();
      final activityDoc = await _fireStore.activityDocument(activityId);

      final userProfileSession = ProfileSession(
        profileSessionId: UniqueId.fromUniqueString(activityId),
        ownerId: UniqueId.fromUniqueString(currentUserId!.uid),
        facilityType: ProfileFacilityType.none,
        activityType: activityForm.activityType.activity,
        isActivity: true,
        isFacility: false,
        isSession: false
      );


      final userProfileSessionDto = ProfileSessionDto.fromDomain(userProfileSession).toJson();
      await userDoc.sessionDocument.doc(activityId).set(userProfileSessionDto);

      final activityFormDto = ActivityCreatorFormDto.fromDomain(activityForm).toJson();
      await activityDoc.set(activityFormDto);

      return right(unit);
    } on FirebaseAuthException catch (e) {
      print(e);
      if (e.toString().contains('permission-denied') || e.toString().contains('unknown')) {
        return left(const ActivityFormFailure.permissionDenied());
      } else {
        return left(const ActivityFormFailure.activityServerError());
      }
    } catch (e) {
      print(e);
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
