part of check_in_facade;

final GetIt getIt = GetIt.instance;

const String prodEnvFacade = Environment.prod;

@injectableInit
void configureInjectionFacade(String env) {
  $initGetIt(getIt, environment: env);
}