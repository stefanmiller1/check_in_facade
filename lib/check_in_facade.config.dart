// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:check_in_facade/check_in_facade.dart' as _i7;
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:cloud_functions/cloud_functions.dart' as _i809;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:firebase_messaging/firebase_messaging.dart' as _i892;
import 'package:firebase_storage/firebase_storage.dart' as _i457;
import 'package:get_it/get_it.dart' as _i174;
import 'package:google_sign_in/google_sign_in.dart' as _i116;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final firebaseInjectableModule = _$FirebaseInjectableModule();
    gh.lazySingleton<_i59.FirebaseAuth>(
        () => firebaseInjectableModule.firebaseAuth);
    gh.lazySingleton<_i974.FirebaseFirestore>(
        () => firebaseInjectableModule.fireStore);
    gh.lazySingleton<_i457.FirebaseStorage>(
        () => firebaseInjectableModule.firebaseStorage);
    gh.lazySingleton<_i809.FirebaseFunctions>(
        () => firebaseInjectableModule.firebaseFunctions);
    gh.lazySingleton<_i892.FirebaseMessaging>(
        () => firebaseInjectableModule.firebaseMessaging);
    gh.lazySingleton<_i116.GoogleSignIn>(
        () => firebaseInjectableModule.googleSignIn);
    gh.lazySingleton<_i7.FAuthWatcherFacade>(
        () => _i7.FacilityWatcherFormFacade(
              gh<_i974.FirebaseFirestore>(),
              gh<_i59.FirebaseAuth>(),
            ));
    gh.lazySingleton<_i7.SStripeWatcherFacade>(() => _i7.StripeWatcherFacade(
          gh<_i809.FirebaseFunctions>(),
          gh<_i974.FirebaseFirestore>(),
        ));
    gh.factory<_i7.UnAuthFacade>(
        () => _i7.UnAuthFacade(gh<_i974.FirebaseFirestore>()));
    gh.lazySingleton<_i7.AAuthWatcherFacade>(() => _i7.ActivityWatcherFacade(
          gh<_i974.FirebaseFirestore>(),
          gh<_i59.FirebaseAuth>(),
        ));
    gh.lazySingleton<_i7.TWatcherFacade>(
        () => _i7.TicketWatcherFacade(gh<_i974.FirebaseFirestore>()));
    gh.lazySingleton<_i7.MVAuthWatcherFacade>(
        () => _i7.MerchVendorAuthWatcherFacade(gh<_i974.FirebaseFirestore>()));
    gh.lazySingleton<_i7.RAuthWatcherFacade>(() => _i7.ResWatcherFacade(
          gh<_i974.FirebaseFirestore>(),
          gh<_i59.FirebaseAuth>(),
        ));
    gh.lazySingleton<_i7.EAuthFacade>(() => _i7.EmailUpdaterFacade(
          gh<_i59.FirebaseAuth>(),
          gh<_i974.FirebaseFirestore>(),
        ));
    gh.lazySingleton<_i7.NWatcherFacade>(() => _i7.NotificationWatcherFacade(
          gh<_i974.FirebaseFirestore>(),
          gh<_i59.FirebaseAuth>(),
        ));
    gh.lazySingleton<_i7.CAuthWatcherFacade>(() => _i7.CommunityWatcherFacade(
          gh<_i974.FirebaseFirestore>(),
          gh<_i59.FirebaseAuth>(),
        ));
    gh.lazySingleton<_i7.NAuthFacade>(() => _i7.NotificationUpdaterFacade(
          gh<_i974.FirebaseFirestore>(),
          gh<_i892.FirebaseMessaging>(),
          gh<_i809.FirebaseFunctions>(),
          gh<_i59.FirebaseAuth>(),
        ));
    gh.factory<_i7.LocationUnAuthWatcherFacade>(
        () => _i7.LocationUnAuthWatcherFacade(gh<_i974.FirebaseFirestore>()));
    gh.lazySingleton<_i7.LMWatcherFacade>(
        () => _i7.ListingManagerWatcherFacade(gh<_i974.FirebaseFirestore>()));
    gh.lazySingleton<_i7.LOAuthFacade>(() => _i7.LocationAuthFacade(
          gh<_i974.FirebaseFirestore>(),
          gh<_i457.FirebaseStorage>(),
          gh<_i59.FirebaseAuth>(),
        ));
    gh.lazySingleton<_i7.ATTAuthWatcherFacade>(
        () => _i7.AttendanceAuthWatcherFacade(
              gh<_i974.FirebaseFirestore>(),
              gh<_i59.FirebaseAuth>(),
            ));
    gh.lazySingleton<_i7.SStripeFacade>(() => _i7.StripeFacade(
          gh<_i809.FirebaseFunctions>(),
          gh<_i974.FirebaseFirestore>(),
        ));
    gh.lazySingleton<_i7.MMiscFacade>(
        () => _i7.MiscFacade(gh<_i974.FirebaseFirestore>()));
    gh.lazySingleton<_i7.MVAuthFacade>(() => _i7.MerchantVendorAuthFacade(
          gh<_i974.FirebaseFirestore>(),
          gh<_i59.FirebaseAuth>(),
          gh<_i457.FirebaseStorage>(),
        ));
    gh.lazySingleton<_i7.IAuthFacade>(() => _i7.FirebaseAuthFacade(
          gh<_i974.FirebaseFirestore>(),
          gh<_i59.FirebaseAuth>(),
          gh<_i457.FirebaseStorage>(),
          gh<_i7.LOAuthFacade>(),
          gh<_i116.GoogleSignIn>(),
        ));
    gh.lazySingleton<_i7.LMFacade>(() => _i7.ListingManagerFacade(
          gh<_i974.FirebaseFirestore>(),
          gh<_i59.FirebaseAuth>(),
          gh<_i7.LOAuthFacade>(),
        ));
    gh.lazySingleton<_i7.FAuthFacade>(() => _i7.FacilityFormFacade(
          gh<_i974.FirebaseFirestore>(),
          gh<_i59.FirebaseAuth>(),
          gh<_i7.LOAuthFacade>(),
        ));
    gh.lazySingleton<_i7.AAuthFacade>(() => _i7.ActivityFormFacade(
          gh<_i974.FirebaseFirestore>(),
          gh<_i457.FirebaseStorage>(),
          gh<_i7.NAuthFacade>(),
        ));
    gh.lazySingleton<_i7.CommAuthFacade>(() => _i7.CommunicationsUpdateFacade(
          gh<_i7.NAuthFacade>(),
          gh<_i7.EAuthFacade>(),
          gh<_i892.FirebaseMessaging>(),
          gh<_i974.FirebaseFirestore>(),
          gh<_i59.FirebaseAuth>(),
        ));
    gh.lazySingleton<_i7.ATTAuthFacade>(() => _i7.AttendeeFormFacade(
          gh<_i974.FirebaseFirestore>(),
          gh<_i457.FirebaseStorage>(),
          gh<_i59.FirebaseAuth>(),
          gh<_i7.CommAuthFacade>(),
          gh<_i892.FirebaseMessaging>(),
          gh<_i7.EAuthFacade>(),
        ));
    gh.lazySingleton<_i7.RUpdaterFacade>(() => _i7.ResUpdaterFacade(
          gh<_i974.FirebaseFirestore>(),
          gh<_i59.FirebaseAuth>(),
          gh<_i892.FirebaseMessaging>(),
          gh<_i7.AAuthFacade>(),
          gh<_i7.LMFacade>(),
          gh<_i7.ATTAuthFacade>(),
          gh<_i7.CommAuthFacade>(),
        ));
    return this;
  }
}

class _$FirebaseInjectableModule extends _i7.FirebaseInjectableModule {}
