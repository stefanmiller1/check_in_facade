part of check_in_facade;


@LazySingleton(as: FAuthFacade)
class FacilityFormFacade implements FAuthFacade {

  final FirebaseFirestore _fireStore;
  final FirebaseAuth _firebaseAuth;
  final LocationAuthFacade _locationFacade;

  FacilityFormFacade(
      this._fireStore,
      this._firebaseAuth,
      this._locationFacade
      );

  @injectable
  @override
  Future<Either<FacilityFormFailure, Unit>> createFacilityForm({
    required FacilityCreatorForm facilityForm}) async {

    try {

      final userDoc = await _fireStore.userDocument();

      final facilityTypeDto = FacilityCreatorFormDto.fromDomain(facilityForm).toJson();
      await userDoc.facilityDocument.doc(facilityForm.facilityId.getOrCrash()).set(facilityTypeDto);


      return right(unit);
    } on FirebaseAuthException catch (e) {
      if (e.toString().contains('permission-denied') || e.toString().contains('unknown')) {
        return left(const FacilityFormFailure.facilityFormServerError());
      } else {
        return left(const FacilityFormFailure.unexpected());
      }
    } catch (e) {
      return left(const FacilityFormFailure.unexpected());
    }
  }


  @override
  Future<Either<FacilityFormFailure, Unit>> createCompletedFacilityForm({required FacilityCreatorForm facilityForm}) async {

    final facilityIdValue = facilityForm.facilityId.getOrCrash();

    try {

      print('checking');

      final currentUserId = _firebaseAuth.currentUser;
      final userDoc = await _fireStore.userDocument();
      final listingDoc = await _fireStore.listingDocument(facilityIdValue);

      final userProfileSession = ProfileSession(
          profileSessionId: facilityForm.facilityId,
          ownerId: UniqueId.fromUniqueString(currentUserId!.uid),
          facilityType: facilityForm.facility.type,
          activityType: ProfileActivityOption.none,
          isActivity: false,
          isFacility: true,
          isSession: false
      );

      final listingProfile = ListingManagerForm(
          listingServiceId: facilityForm.facilityId,
          listingProfileService: ListingProfileService(
              backgroundInfoServices: BackgroundInfoSettings(
                  listingOwner: UniqueId.fromUniqueString(currentUserId.uid),
                  startEndDate: DateTimeRange(start: facilityForm.fromStarting, end: facilityForm.fromEnding) ,
                  listingName: facilityForm.rentalTitle,
                  listingDescription: facilityForm.rentalDescription1,
                  listingEmail: EmailAddress(currentUserId.email),
                  listingPhone: BackgroundInfoSettings.empty().listingPhone,
                  listingStatus: BackgroundInfoSettings.empty().listingStatus,
                  listingWebsite: BackgroundInfoSettings.empty().listingWebsite,
                  countryRegionLanguage: BackgroundInfoSettings.empty().countryRegionLanguage,
                  timeZoneRegion: BackgroundInfoSettings.empty().timeZoneRegion,
                  currency: BackgroundInfoSettings.empty().currency,
                  profileSocials: BackgroundInfoSettings.empty().profileSocials
              ),
              listingLocationSetting: facilityForm.facilityLocation,
              spaceSetting: SpaceSettings(
                  facilityTypeId: facilityForm.facility,
                  spaceTypes: facilityForm.spaceTypes
              )
          ),
          listingReservationService: ListingReservationService.empty(),
          listingRulesService: ListingRulesService(
              isPricingRuleFixed: ListingRulesService.empty().isPricingRuleFixed,
              isQuoteRuleFixed: ListingRulesService.empty().isQuoteRuleFixed,
              isConditionServiceFixed: ListingRulesService.empty().isConditionServiceFixed,
              defaultPricingRuleSettings: PricingRuleSettings(
                  spaceId: facilityForm.spaceTypes.value.fold((l) => [], (r) => r)[0].uid,
                  defaultPricingRate: int.parse(facilityForm.basePriceFullSlotOne.replaceAll('\$', '').replaceAll('.', ''))
              ),
              defaultQuotaRuleSetting: ListingRulesService.empty().defaultQuotaRuleSetting,
              defaultConditionsServices: ListingRulesService.empty().defaultConditionsServices,
              pricingRuleSettings: ListingRulesService.empty().pricingRuleSettings,
              quotaRuleSettings: ListingRulesService.empty().quotaRuleSettings,
              conditionServices: ListingRulesService.empty().conditionServices
          )
      );

      final userProfileSessionDto = ProfileSessionDto.fromDomain(userProfileSession).toJson();
      await userDoc.sessionDocument.doc(facilityIdValue).set(userProfileSessionDto);

      await createFacilityForm(facilityForm: facilityForm);

      await _locationFacade.createNewLocationFacilitySession(sessionProfile: userProfileSession);
      await _locationFacade.createNewProfileLocationAuth(location: facilityForm.facilityLocation);

      final listingFormDto = ListingManagerFormDto.fromDomain(listingProfile).toJson();
      await listingDoc.set(listingFormDto);

      return right(unit);
    } on FirebaseAuthException catch (e) {
      if (e.toString().contains('permission-denied') || e.toString().contains('unknown')) {
        return left(const FacilityFormFailure.facilityFormServerError());
      } else {
        return left(const FacilityFormFailure.unexpected());
      }
    } catch (e) {
      return left(const FacilityFormFailure.unexpected());
    }
  }


}