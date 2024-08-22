// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:check_in_facade/check_in_facade.dart' as _i9;
import 'package:cloud_firestore/cloud_firestore.dart' as _i4;
import 'package:cloud_functions/cloud_functions.dart' as _i5;
import 'package:firebase_auth/firebase_auth.dart' as _i3;
import 'package:firebase_messaging/firebase_messaging.dart' as _i6;
import 'package:firebase_storage/firebase_storage.dart' as _i7;
import 'package:get_it/get_it.dart' as _i1;
import 'package:google_sign_in/google_sign_in.dart' as _i8;
import 'package:injectable/injectable.dart' as _i2;

extension GetItInjectableX on _i1.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i1.GetIt init({
    String? environment,
    _i2.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i2.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final firebaseInjectableModule = _$FirebaseInjectableModule();
    gh.lazySingleton<_i3.FirebaseAuth>(
        () => firebaseInjectableModule.firebaseAuth);
    gh.lazySingleton<_i4.FirebaseFirestore>(
        () => firebaseInjectableModule.fireStore);
    gh.lazySingleton<_i5.FirebaseFunctions>(
        () => firebaseInjectableModule.firebaseFunctions);
    gh.lazySingleton<_i6.FirebaseMessaging>(
        () => firebaseInjectableModule.firebaseMessaging);
    gh.lazySingleton<_i7.FirebaseStorage>(
        () => firebaseInjectableModule.firebaseStorage);
    gh.lazySingleton<_i8.GoogleSignIn>(
        () => firebaseInjectableModule.googleSignIn);
    gh.lazySingleton<_i9.LMWatcherFacade>(
        () => _i9.ListingManagerWatcherFacade(gh<_i4.FirebaseFirestore>()));
    gh.factory<_i9.LocationAuthFacade>(() => _i9.LocationAuthFacade(
          gh<_i4.FirebaseFirestore>(),
          gh<_i3.FirebaseAuth>(),
        ));
    gh.factory<_i9.LocationUnAuthWatcherFacade>(
        () => _i9.LocationUnAuthWatcherFacade(gh<_i4.FirebaseFirestore>()));
    gh.lazySingleton<_i9.MMiscFacade>(
        () => _i9.MiscFacade(gh<_i4.FirebaseFirestore>()));
    gh.lazySingleton<_i9.MVAuthFacade>(() => _i9.MerchantVendorAuthFacade(
          gh<_i4.FirebaseFirestore>(),
          gh<_i3.FirebaseAuth>(),
          gh<_i7.FirebaseStorage>(),
        ));
    gh.lazySingleton<_i9.MVAuthWatcherFacade>(
        () => _i9.MerchVendorAuthWatcherFacade(gh<_i4.FirebaseFirestore>()));
    gh.lazySingleton<_i9.NAuthFacade>(() => _i9.NotificationUpdaterFacade(
          gh<_i4.FirebaseFirestore>(),
          gh<_i6.FirebaseMessaging>(),
          gh<_i3.FirebaseAuth>(),
        ));
    gh.lazySingleton<_i9.NWatcherFacade>(() => _i9.NotificationWatcherFacade(
          gh<_i4.FirebaseFirestore>(),
          gh<_i3.FirebaseAuth>(),
        ));
    gh.lazySingleton<_i9.RAuthWatcherFacade>(() => _i9.ResWatcherFacade(
          gh<_i4.FirebaseFirestore>(),
          gh<_i3.FirebaseAuth>(),
        ));
    gh.lazySingleton<_i9.SStripeFacade>(() => _i9.StripeFacade(
          gh<_i5.FirebaseFunctions>(),
          gh<_i4.FirebaseFirestore>(),
        ));
    gh.lazySingleton<_i9.SStripeWatcherFacade>(() => _i9.StripeWatcherFacade(
          gh<_i5.FirebaseFunctions>(),
          gh<_i4.FirebaseFirestore>(),
        ));
    gh.lazySingleton<_i9.TWatcherFacade>(
        () => _i9.TicketWatcherFacade(gh<_i4.FirebaseFirestore>()));
    gh.factory<_i9.UnAuthFacade>(
        () => _i9.UnAuthFacade(gh<_i4.FirebaseFirestore>()));
    gh.lazySingleton<_i9.AAuthFacade>(() => _i9.ActivityFormFacade(
          gh<_i4.FirebaseFirestore>(),
          gh<_i7.FirebaseStorage>(),
          gh<_i9.NAuthFacade>(),
        ));
    gh.lazySingleton<_i9.AAuthWatcherFacade>(() => _i9.ActivityWatcherFacade(
          gh<_i4.FirebaseFirestore>(),
          gh<_i3.FirebaseAuth>(),
        ));
    gh.lazySingleton<_i9.ATTAuthWatcherFacade>(
        () => _i9.AttendanceAuthWatcherFacade(
              gh<_i4.FirebaseFirestore>(),
              gh<_i3.FirebaseAuth>(),
            ));
    gh.lazySingleton<_i9.CAuthWatcherFacade>(() => _i9.CommunityWatcherFacade(
          gh<_i4.FirebaseFirestore>(),
          gh<_i3.FirebaseAuth>(),
        ));
    gh.lazySingleton<_i9.EAuthFacade>(() => _i9.EmailUpdaterFacade(
          gh<_i3.FirebaseAuth>(),
          gh<_i4.FirebaseFirestore>(),
        ));
    gh.lazySingleton<_i9.FAuthFacade>(() => _i9.FacilityFormFacade(
          gh<_i4.FirebaseFirestore>(),
          gh<_i3.FirebaseAuth>(),
          gh<_i9.LocationAuthFacade>(),
        ));
    gh.lazySingleton<_i9.FAuthWatcherFacade>(
        () => _i9.FacilityWatcherFormFacade(
              gh<_i4.FirebaseFirestore>(),
              gh<_i3.FirebaseAuth>(),
            ));
    gh.lazySingleton<_i9.IAuthFacade>(() => _i9.FirebaseAuthFacade(
          gh<_i4.FirebaseFirestore>(),
          gh<_i3.FirebaseAuth>(),
          gh<_i7.FirebaseStorage>(),
          gh<_i9.LocationAuthFacade>(),
          gh<_i8.GoogleSignIn>(),
        ));
    gh.lazySingleton<_i9.LMFacade>(() => _i9.ListingManagerFacade(
          gh<_i4.FirebaseFirestore>(),
          gh<_i3.FirebaseAuth>(),
          gh<_i9.LocationAuthFacade>(),
        ));
    gh.lazySingleton<_i9.ATTAuthFacade>(() => _i9.AttendeeFormFacade(
          gh<_i4.FirebaseFirestore>(),
          gh<_i7.FirebaseStorage>(),
          gh<_i3.FirebaseAuth>(),
          gh<_i9.NAuthFacade>(),
          gh<_i6.FirebaseMessaging>(),
          gh<_i9.EAuthFacade>(),
        ));
    gh.lazySingleton<_i9.RUpdaterFacade>(() => _i9.ResUpdaterFacade(
          gh<_i4.FirebaseFirestore>(),
          gh<_i3.FirebaseAuth>(),
          gh<_i6.FirebaseMessaging>(),
          gh<_i9.ATTAuthFacade>(),
          gh<_i9.NAuthFacade>(),
          gh<_i9.EAuthFacade>(),
        ));
    return this;
  }
}

class _$FirebaseInjectableModule extends _i9.FirebaseInjectableModule {}
