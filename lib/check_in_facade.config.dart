// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i5;
import 'package:cloud_functions/cloud_functions.dart' as _i6;
import 'package:firebase_auth/firebase_auth.dart' as _i3;
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart' as _i4;
import 'package:firebase_messaging/firebase_messaging.dart' as _i7;
import 'package:get_it/get_it.dart' as _i1;
import 'package:google_sign_in/google_sign_in.dart' as _i8;
import 'package:injectable/injectable.dart' as _i2;

import 'check_in_facade.dart' as _i9; // ignore_for_file: unnecessary_lambdas

// ignore_for_file: lines_longer_than_80_chars
/// initializes the registration of provided dependencies inside of [GetIt]
_i1.GetIt $initGetIt(
  _i1.GetIt get, {
  String? environment,
  _i2.EnvironmentFilter? environmentFilter,
}) {
  final gh = _i2.GetItHelper(
    get,
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
  gh.lazySingleton<_i8.GoogleSignIn>(
      () => firebaseInjectableModule.googleSignIn);
  gh.lazySingleton<_i9.LMWatcherFacade>(
      () => _i9.ListingManagerWatcherFacade(get<_i5.FirebaseFirestore>()));
  gh.factory<_i9.LocationAuthFacade>(() => _i9.LocationAuthFacade(
        get<_i5.FirebaseFirestore>(),
        get<_i3.FirebaseAuth>(),
      ));
  gh.factory<_i9.LocationUnAuthWatcherFacade>(
      () => _i9.LocationUnAuthWatcherFacade(get<_i5.FirebaseFirestore>()));
  gh.lazySingleton<_i9.MMiscFacade>(
      () => _i9.MiscFacade(get<_i5.FirebaseFirestore>()));
  gh.lazySingleton<_i9.RAuthWatcherFacade>(() => _i9.ResWatcherFacade(
        get<_i5.FirebaseFirestore>(),
        get<_i3.FirebaseAuth>(),
      ));
  gh.lazySingleton<_i9.RUpdaterFacade>(() => _i9.ResUpdaterFacade(
        get<_i5.FirebaseFirestore>(),
        get<_i3.FirebaseAuth>(),
        get<_i4.FirebaseDynamicLinks>(),
        get<_i7.FirebaseMessaging>(),
        get<_i6.FirebaseFunctions>(),
      ));
  gh.lazySingleton<_i9.SStripeFacade>(() => _i9.StripeFacade(
        get<_i6.FirebaseFunctions>(),
        get<_i5.FirebaseFirestore>(),
      ));
  gh.lazySingleton<_i9.SStripeWatcherFacade>(() => _i9.StripeWatcherFacade(
        get<_i6.FirebaseFunctions>(),
        get<_i5.FirebaseFirestore>(),
      ));
  gh.factory<_i9.UnAuthFacade>(
      () => _i9.UnAuthFacade(get<_i5.FirebaseFirestore>()));
  gh.lazySingleton<_i9.AAuthFacade>(() => _i9.ActivityFormFacade(
        get<_i5.FirebaseFirestore>(),
        get<_i3.FirebaseAuth>(),
        get<_i9.LocationAuthFacade>(),
      ));
  gh.lazySingleton<_i9.AAuthWatcherFacade>(() => _i9.ActivityWatcherFacade(
        get<_i5.FirebaseFirestore>(),
        get<_i3.FirebaseAuth>(),
      ));
  gh.lazySingleton<_i9.FAuthFacade>(() => _i9.FacilityFormFacade(
        get<_i5.FirebaseFirestore>(),
        get<_i3.FirebaseAuth>(),
        get<_i9.LocationAuthFacade>(),
      ));
  gh.lazySingleton<_i9.FAuthWatcherFacade>(() => _i9.FacilityWatcherFormFacade(
        get<_i5.FirebaseFirestore>(),
        get<_i3.FirebaseAuth>(),
      ));
  gh.lazySingleton<_i9.IAuthFacade>(() => _i9.FirebaseAuthFacade(
        get<_i5.FirebaseFirestore>(),
        get<_i3.FirebaseAuth>(),
        get<_i9.LocationAuthFacade>(),
        get<_i8.GoogleSignIn>(),
      ));
  gh.lazySingleton<_i9.LMFacade>(() => _i9.ListingManagerFacade(
        get<_i5.FirebaseFirestore>(),
        get<_i3.FirebaseAuth>(),
        get<_i9.LocationAuthFacade>(),
      ));
  return get;
}

class _$FirebaseInjectableModule extends _i9.FirebaseInjectableModule {}
