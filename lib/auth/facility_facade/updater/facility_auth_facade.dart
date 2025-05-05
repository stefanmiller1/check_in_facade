part of check_in_facade;


@LazySingleton(as: FAuthFacade)
class FacilityFormFacade implements FAuthFacade {

  final FirebaseFirestore _fireStore;
  final FirebaseAuth _firebaseAuth;
  final LOAuthFacade _locationFacade;

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

      final currentUserId = _firebaseAuth.currentUser;
      final listingDoc = await _fireStore.listingDocument(facilityIdValue);

      final listingLocation = await _locationFacade.createNewProfileLocationAuth(location: facilityForm.facilityLocation);
      if (listingLocation.isLeft()) {
        return left(const FacilityFormFailure.facilityFormServerError());
      }

      ListingManagerForm newListingManager = ListingManagerForm.empty();

          newListingManager = newListingManager.copyWith(
            listingProfileService: newListingManager.listingProfileService.copyWith(
                backgroundInfoServices: newListingManager.listingProfileService.backgroundInfoServices.copyWith(
                listingOwner: UniqueId.fromUniqueString(currentUserId!.uid),
                startEndDate: DateTimeRange(start: facilityForm.fromStarting, end: facilityForm.fromEnding) ,
                listingName: facilityForm.rentalTitle,
                listingDescription: facilityForm.rentalDescription1,
                listingEmail: EmailAddress(currentUserId!.email),
              ),
              listingLocationSetting: listingLocation.getOrElse(() => facilityForm.facilityLocation),
              spaceSetting: SpaceSettings(
                  facilityTypeId: facilityForm.facility,
                  spaceTypes: facilityForm.spaceTypes
              )
            ),
            listingRulesService: newListingManager.listingRulesService.copyWith(
              defaultPricingRuleSettings: PricingRuleSettings(
                  spaceId: facilityForm.spaceTypes.value.fold((l) => [], (r) => r)[0].uid,
                  defaultPricingRate: int.parse(facilityForm.basePriceFullSlotOne.replaceAll('\$', '').replaceAll('.', ''))
              ),
            )
          );

      //     listingServiceId: facilityForm.facilityId,
      //     listingProfileService: ListingProfileService(
      //         backgroundInfoServices: BackgroundInfoSettings(
      //             listingOwner: UniqueId.fromUniqueString(currentUserId.uid),
      //             startEndDate: DateTimeRange(start: facilityForm.fromStarting, end: facilityForm.fromEnding) ,
      //             listingName: facilityForm.rentalTitle,
      //             listingDescription: facilityForm.rentalDescription1,
      //             listingEmail: EmailAddress(currentUserId.email),
      //             listingPhone: BackgroundInfoSettings.empty().listingPhone,
      //             listingStatus: BackgroundInfoSettings.empty().listingStatus,
      //             listingWebsite: BackgroundInfoSettings.empty().listingWebsite,
      //             countryRegionLanguage: BackgroundInfoSettings.empty().countryRegionLanguage,
      //             timeZoneRegion: BackgroundInfoSettings.empty().timeZoneRegion,
      //             currency: BackgroundInfoSettings.empty().currency,
      //             profileSocials: BackgroundInfoSettings.empty().profileSocials
      //         ),
      //         listingLocationSetting: listingLocation,
      //         spaceSetting: SpaceSettings(
      //             facilityTypeId: facilityForm.facility,
      //             spaceTypes: facilityForm.spaceTypes
      //         )
      //     ),
      //     listingReservationService: ListingReservationService.empty(),
      //     listingRulesService: ListingRulesService(
      //         isPricingRuleFixed: ListingRulesService.empty().isPricingRuleFixed,
      //         isQuoteRuleFixed: ListingRulesService.empty().isQuoteRuleFixed,
      //         isConditionServiceFixed: ListingRulesService.empty().isConditionServiceFixed,
      //         defaultPricingRuleSettings: PricingRuleSettings(
      //             spaceId: facilityForm.spaceTypes.value.fold((l) => [], (r) => r)[0].uid,
      //             defaultPricingRate: int.parse(facilityForm.basePriceFullSlotOne.replaceAll('\$', '').replaceAll('.', ''))
      //         ),
      //         defaultQuotaRuleSetting: ListingRulesService.empty().defaultQuotaRuleSetting,
      //         defaultConditionsServices: ListingRulesService.empty().defaultConditionsServices,
      //         pricingRuleSettings: ListingRulesService.empty().pricingRuleSettings,
      //         quotaRuleSettings: ListingRulesService.empty().quotaRuleSettings,
      //         conditionServices: ListingRulesService.empty().conditionServices
      //     )
      // );

      // final userProfileSessionDto = ProfileSessionDto.fromDomain(userProfileSession).toJson();
      // await userDoc.sessionDocument.doc(facilityIdValue).set(userProfileSessionDto);

      await createFacilityForm(facilityForm: facilityForm);

      // await _locationFacade.createNewLocationFacilitySession(sessionProfile: userProfileSession);

      final listingFormDto = ListingManagerFormDto.fromDomain(newListingManager).toJson();
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