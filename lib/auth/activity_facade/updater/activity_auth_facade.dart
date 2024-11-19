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


      /// update documents in each vendor form application
      List<VendorMerchantForm> newVendorForms = [];
      newVendorForms.addAll(newActivityForm.rulesService.vendorMerchantForms ?? []);

      for (VendorMerchantForm vendorForm in newActivityForm.rulesService.vendorMerchantForms ?? []) {
        /// replace document custom rule option with new MVCustomOption
        late VendorMerchantForm newVendorForm = vendorForm;
        late List<MVCustomOption> newOptions = [];
        newOptions.addAll(newVendorForm.customOptions ?? []);

        late MVCustomOption? newCustomOption = getDocumentRuleOption(vendorForm);
        late List<DocumentFormOption> documents = [];
        documents.addAll(getDocumentsList(vendorForm) ?? []);

        for (DocumentFormOption document in documents) {
            if (document.documentForm.imageToUpload != null) {
              final metadata = SettableMetadata(contentType: 'application/pdf');
              final urlId = UniqueId();
              final reference = _firebaseStorage.ref('activity_directory').child(activityResId.getOrCrash());
              await reference.child('vendor_form').child(vendorForm.formId.getOrCrash()).child('${urlId.getOrCrash()}.pdf').putData(document.documentForm.imageToUpload!, metadata);
              /// retrieve link to file
              final uri = await reference.child('vendor_form').child(vendorForm.formId.getOrCrash()).child('${urlId.getOrCrash()}.pdf').getDownloadURL();
              final index = documents.indexWhere((element) => element.documentForm.key == document.documentForm.key);
              final newDocument = DocumentFormOption(documentForm: ImageUpload(key: uri, uriPath: uri), isRequiredOption: document.isRequiredOption);
              documents.replaceRange(index, index + 1, [newDocument]);
          }
        }

        newCustomOption = newCustomOption?.copyWith(
          customRuleOption: newCustomOption.customRuleOption?.copyWith(
            customDocumentOptions: documents
          )
        );

        if (newVendorForm.customOptions != null && newCustomOption != null) {

          final int customIndex = newVendorForm.customOptions!.indexWhere((element) => element.customRuleOption?.ruleId == newCustomOption?.customRuleOption?.ruleId);
          newOptions.replaceRange(customIndex, customIndex + 1, [newCustomOption]);
          newVendorForm = newVendorForm.copyWith(
              customOptions: newOptions
          );

          final venIndex = newVendorForms.indexWhere((element) => element.formId == newVendorForm.formId);
          newVendorForms.replaceRange(venIndex, venIndex + 1, [newVendorForm]);
        }
      }

      newActivityForm = newActivityForm.copyWith(
        rulesService: newActivityForm.rulesService.copyWith(
          vendorMerchantForms: newVendorForms
        )
      );


      final reservationDoc = await _fireStore.reservationDocument(activityResId.getOrCrash());
      final activityDoc = await _fireStore.activityDocument(activityResId.getOrCrash());
      final activityFormDto = ActivityManagerFormDto.fromDomain(newActivityForm).toJson();
      await activityDoc.set(activityFormDto);

      await _notificationFacade.createUpdatedReservationActivityNotification(reservationId: activityResId.getOrCrash());

      /// update reservation state
      if (activitySetupComplete(newActivityForm) && activityIsPublic(newActivityForm)) {
        reservationDoc.update({'isActivity': true});
      } else {
        reservationDoc.update({'isActivity': false});
      }

      /// update published vendor form state
      if (getHasPublishedVendorForms(newActivityForm.rulesService.vendorMerchantForms ?? [])) {
        reservationDoc.update({'isLookingForVendor': true});
      } else {
        reservationDoc.update({'isLookingForVendor': null});
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


class ActivityFormUpdateFacade {

  ActivityFormUpdateFacade._privateConstructor() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      firebaseUser = FirebaseAuth.instance.currentUser;
    });
  }

  /// Current logged in user in Firebase. Does not update automatically.
  /// Use [FirebaseAuth.authStateChanges] to listen to the state changes.
  User? firebaseUser = FirebaseAuth.instance.currentUser;

  /// Gets proper [FirebaseFirestore] instance.
  FirebaseFirestore getFirebaseFirestore() => FirebaseFirestore.instance;

  static final ActivityFormUpdateFacade instance = ActivityFormUpdateFacade._privateConstructor();

  Future<void> updateViewCount({required String activityResId}) async {
    try {

      final String currentUser = firebaseUser?.uid ?? UniqueId().getOrCrash();

      final activityDoc = await getFirebaseFirestore().activityDocument(activityResId);
      final viewDoc = activityDoc.collection('views').doc(currentUser);

      getFirebaseFirestore().runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(viewDoc);

        if (!(snapshot.exists)) {
          transaction.set(viewDoc, {
            'viewCount': 1,
            'viewedBy': currentUser,
            'viewTime': DateTime.now().millisecondsSinceEpoch
          });
        } else {
          int currentCount = snapshot['viewCount'];
          transaction.set(viewDoc, {
            'viewCount': currentCount + 1,
            'viewedBy': currentUser,
            'viewTime': DateTime.now().millisecondsSinceEpoch
          });
        }
      });

    } catch (e) {
      Future.error('Error updating view count: $e');
    }
  }

}


