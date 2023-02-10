// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i4;
import 'package:cloud_functions/cloud_functions.dart' as _i5;
import 'package:firebase_auth/firebase_auth.dart' as _i3;
import 'package:get_it/get_it.dart' as _i1;
import 'package:google_sign_in/google_sign_in.dart' as _i6;
import 'package:injectable/injectable.dart' as _i2;

import 'check_in_facade.dart' as _i7; // ignore_for_file: unnecessary_lambdas

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
  gh.lazySingleton<_i4.FirebaseFirestore>(
      () => firebaseInjectableModule.fireStore);
  gh.lazySingleton<_i5.FirebaseFunctions>(
      () => firebaseInjectableModule.firebaseFunctions);
  gh.lazySingleton<_i6.GoogleSignIn>(
      () => firebaseInjectableModule.googleSignIn);
  gh.lazySingleton<_i7.LMWatcherFacade>(
      () => _i7.ListingManagerWatcherFacade(get<_i4.FirebaseFirestore>()));
  gh.factory<_i7.LocationAuthFacade>(() => _i7.LocationAuthFacade(
        get<_i4.FirebaseFirestore>(),
        get<_i3.FirebaseAuth>(),
      ));
  gh.factory<_i7.LocationUnAuthWatcherFacade>(
      () => _i7.LocationUnAuthWatcherFacade(get<_i4.FirebaseFirestore>()));
  gh.lazySingleton<_i7.MMiscFacade>(() => _i7.MiscFacade());
  gh.lazySingleton<_i7.RAuthWatcherFacade>(() => _i7.ResWatcherFacade(
        get<_i4.FirebaseFirestore>(),
        get<_i3.FirebaseAuth>(),
      ));
  gh.lazySingleton<_i7.RUpdaterFacade>(() => _i7.ResUpdaterFacade(
        get<_i4.FirebaseFirestore>(),
        get<_i3.FirebaseAuth>(),
      ));
  gh.lazySingleton<_i7.SStripeFacade>(() => _i7.StripeFacade(
        get<_i5.FirebaseFunctions>(),
        get<_i4.FirebaseFirestore>(),
      ));
  gh.lazySingleton<_i7.SStripeWatcherFacade>(() => _i7.StripeWatcherFacade(
        get<_i5.FirebaseFunctions>(),
        get<_i4.FirebaseFirestore>(),
      ));
  gh.factory<_i7.UnAuthFacade>(() => _i7.UnAuthFacade());
  gh.lazySingleton<_i7.AAuthFacade>(() => _i7.ActivityFormFacade(
        get<_i4.FirebaseFirestore>(),
        get<_i3.FirebaseAuth>(),
        get<_i7.LocationAuthFacade>(),
      ));
  gh.lazySingleton<_i7.AAuthWatcherFacade>(
      () => _i7.ActivityWatcherFacade(get<_i4.FirebaseFirestore>()));
  gh.lazySingleton<_i7.FAuthFacade>(() => _i7.FacilityFormFacade(
        get<_i4.FirebaseFirestore>(),
        get<_i3.FirebaseAuth>(),
        get<_i7.LocationAuthFacade>(),
      ));
  gh.lazySingleton<_i7.FAuthWatcherFacade>(() => _i7.FacilityWatcherFormFacade(
        get<_i4.FirebaseFirestore>(),
        get<_i3.FirebaseAuth>(),
      ));
  gh.lazySingleton<_i7.IAuthFacade>(() => _i7.FirebaseAuthFacade(
        get<_i4.FirebaseFirestore>(),
        get<_i3.FirebaseAuth>(),
        get<_i7.LocationAuthFacade>(),
        get<_i6.GoogleSignIn>(),
      ));
  gh.lazySingleton<_i7.LMFacade>(() => _i7.ListingManagerFacade(
        get<_i4.FirebaseFirestore>(),
        get<_i3.FirebaseAuth>(),
        get<_i7.LocationAuthFacade>(),
      ));
  return get;
}

class _$FirebaseInjectableModule extends _i7.FirebaseInjectableModule {}
