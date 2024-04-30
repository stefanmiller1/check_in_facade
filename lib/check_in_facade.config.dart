// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:check_in_facade/check_in_facade.dart' as _i10;
import 'package:cloud_firestore/cloud_firestore.dart' as _i5;
import 'package:cloud_functions/cloud_functions.dart' as _i6;
import 'package:firebase_auth/firebase_auth.dart' as _i3;
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart' as _i4;
import 'package:firebase_messaging/firebase_messaging.dart' as _i7;
import 'package:firebase_storage/firebase_storage.dart' as _i8;
import 'package:get_it/get_it.dart' as _i1;
import 'package:google_sign_in/google_sign_in.dart' as _i9;
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
    gh.lazySingleton<_i4.FirebaseDynamicLinks>(
        () => firebaseInjectableModule.firebaseDynamicLinks);
    gh.lazySingleton<_i5.FirebaseFirestore>(
        () => firebaseInjectableModule.fireStore);
    gh.lazySingleton<_i6.FirebaseFunctions>(
        () => firebaseInjectableModule.firebaseFunctions);
    gh.lazySingleton<_i7.FirebaseMessaging>(
        () => firebaseInjectableModule.firebaseMessaging);
    gh.lazySingleton<_i8.FirebaseStorage>(
        () => firebaseInjectableModule.firebaseStorage);
    gh.lazySingleton<_i9.GoogleSignIn>(
        () => firebaseInjectableModule.googleSignIn);
    gh.lazySingleton<_i10.LMWatcherFacade>(
        () => _i10.ListingManagerWatcherFacade(gh<_i5.FirebaseFirestore>()));
    gh.factory<_i10.LocationAuthFacade>(() => _i10.LocationAuthFacade(
          gh<_i5.FirebaseFirestore>(),
          gh<_i3.FirebaseAuth>(),
        ));
    gh.factory<_i10.LocationUnAuthWatcherFacade>(
        () => _i10.LocationUnAuthWatcherFacade(gh<_i5.FirebaseFirestore>()));
    gh.lazySingleton<_i10.MMiscFacade>(
        () => _i10.MiscFacade(gh<_i5.FirebaseFirestore>()));
    gh.lazySingleton<_i10.MVAuthFacade>(() => _i10.MerchantVendorAuthFacade(
          gh<_i5.FirebaseFirestore>(),
          gh<_i3.FirebaseAuth>(),
          gh<_i8.FirebaseStorage>(),
        ));
    gh.lazySingleton<_i10.MVAuthWatcherFacade>(
        () => _i10.MerchVendorAuthWatcherFacade(gh<_i5.FirebaseFirestore>()));
    gh.lazySingleton<_i10.NAuthFacade>(() => _i10.NotificationUpdaterFacade(
          gh<_i5.FirebaseFirestore>(),
          gh<_i7.FirebaseMessaging>(),
          gh<_i3.FirebaseAuth>(),
        ));
    gh.lazySingleton<_i10.NWatcherFacade>(() => _i10.NotificationWatcherFacade(
          gh<_i5.FirebaseFirestore>(),
          gh<_i3.FirebaseAuth>(),
        ));
    gh.lazySingleton<_i10.RAuthWatcherFacade>(() => _i10.ResWatcherFacade(
          gh<_i5.FirebaseFirestore>(),
          gh<_i3.FirebaseAuth>(),
        ));
    gh.lazySingleton<_i10.SStripeFacade>(() => _i10.StripeFacade(
          gh<_i6.FirebaseFunctions>(),
          gh<_i5.FirebaseFirestore>(),
        ));
    gh.lazySingleton<_i10.SStripeWatcherFacade>(() => _i10.StripeWatcherFacade(
          gh<_i6.FirebaseFunctions>(),
          gh<_i5.FirebaseFirestore>(),
        ));
    gh.lazySingleton<_i10.TWatcherFacade>(
        () => _i10.TicketWatcherFacade(gh<_i5.FirebaseFirestore>()));
    gh.factory<_i10.UnAuthFacade>(
        () => _i10.UnAuthFacade(gh<_i5.FirebaseFirestore>()));
    gh.lazySingleton<_i10.AAuthFacade>(() => _i10.ActivityFormFacade(
          gh<_i5.FirebaseFirestore>(),
          gh<_i8.FirebaseStorage>(),
          gh<_i10.NAuthFacade>(),
        ));
    gh.lazySingleton<_i10.AAuthWatcherFacade>(() => _i10.ActivityWatcherFacade(
          gh<_i5.FirebaseFirestore>(),
          gh<_i3.FirebaseAuth>(),
        ));
    gh.lazySingleton<_i10.ATTAuthFacade>(() => _i10.AttendeeFormFacade(
          gh<_i5.FirebaseFirestore>(),
          gh<_i8.FirebaseStorage>(),
          gh<_i10.NAuthFacade>(),
          gh<_i7.FirebaseMessaging>(),
        ));
    gh.lazySingleton<_i10.ATTAuthWatcherFacade>(
        () => _i10.AttendanceAuthWatcherFacade(
              gh<_i5.FirebaseFirestore>(),
              gh<_i3.FirebaseAuth>(),
            ));
    gh.lazySingleton<_i10.CAuthWatcherFacade>(() => _i10.CommunityWatcherFacade(
          gh<_i5.FirebaseFirestore>(),
          gh<_i3.FirebaseAuth>(),
        ));
    gh.lazySingleton<_i10.FAuthFacade>(() => _i10.FacilityFormFacade(
          gh<_i5.FirebaseFirestore>(),
          gh<_i3.FirebaseAuth>(),
          gh<_i10.LocationAuthFacade>(),
        ));
    gh.lazySingleton<_i10.FAuthWatcherFacade>(
        () => _i10.FacilityWatcherFormFacade(
              gh<_i5.FirebaseFirestore>(),
              gh<_i3.FirebaseAuth>(),
            ));
    gh.lazySingleton<_i10.IAuthFacade>(() => _i10.FirebaseAuthFacade(
          gh<_i5.FirebaseFirestore>(),
          gh<_i3.FirebaseAuth>(),
          gh<_i8.FirebaseStorage>(),
          gh<_i10.LocationAuthFacade>(),
          gh<_i9.GoogleSignIn>(),
        ));
    gh.lazySingleton<_i10.LMFacade>(() => _i10.ListingManagerFacade(
          gh<_i5.FirebaseFirestore>(),
          gh<_i3.FirebaseAuth>(),
          gh<_i10.LocationAuthFacade>(),
        ));
    gh.lazySingleton<_i10.RUpdaterFacade>(() => _i10.ResUpdaterFacade(
          gh<_i5.FirebaseFirestore>(),
          gh<_i3.FirebaseAuth>(),
          gh<_i4.FirebaseDynamicLinks>(),
          gh<_i7.FirebaseMessaging>(),
          gh<_i10.ATTAuthFacade>(),
          gh<_i10.NAuthFacade>(),
        ));
    return this;
  }
}

class _$FirebaseInjectableModule extends _i10.FirebaseInjectableModule {}
