part of check_in_facade;

abstract class MVAuthFacade {

  Future<Either<ProfileValueFailure, Unit>> createUpdateMerchantVendor({
    required EventMerchantVendorProfile merchProfileItem,
  });

  Future<Either<ProfileValueFailure, Unit>> newMerchantVendorPartner({
    required UniqueId profileId
  });

  Future<Either<ProfileValueFailure, Unit>> deleteMerchantVendorAccount({
    required EventMerchantVendorProfile profile
  });

}