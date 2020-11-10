// @dart=2.3

import 'package:shared_preferences/shared_preferences.dart';

/// Declares a contract to remember which Feature Discoveries were already viewed by
/// the user, and to inquire about such past views.
abstract class PersistenceProvider {
  /// Returns true if the step identified by [featureId] has completed by the user earlier,
  /// false otherwise.
  Future<bool> hasCompletedStep(String featureId);

  /// Returns the list of steps (as strings) that the user has previously completed from
  /// the provided [featuresIds] set.
  Future<Set<String>> completedSteps(Iterable<String> featuresIds);

  /// Informs the persistence layer that the user has completed the step identified by
  /// [featureId], and that it should record it in the persistence layer.
  Future<void> completeStep(String featureId);

  /// Requests that the persistence layer should remove the completion of the step
  /// identified by [featureId].
  Future<void> clearStep(String featureId);

  /// Requests that the historic steps identified by [featuresIds] be cleared from
  /// the persistence layer.
  Future<void> clearSteps(Iterable<String> featuresIds);
}

/// Implementation of [PersistenceProvider] using the 3rd party [SharedPreferences] plugin.
class SharedPreferencesProvider implements PersistenceProvider {
  /// Instantiates a new [SharedPreferencesProvider].
  ///
  /// If [sharedPrefsPrefix] is provided, it will be prepended to all step identifiers passed
  /// to the different methods. If [sharedPrefsPrefix] is not provided, the step
  /// identifiers will be used as-is.
  const SharedPreferencesProvider([String sharedPrefsPrefix])
      : sharedPrefsPrefix = sharedPrefsPrefix ?? '';

  /// Use this string a prefix for all steps identifiers.
  final String sharedPrefsPrefix;

  @override
  Future<bool> hasCompletedStep(String featureId) async {
    final prefs = await SharedPreferences.getInstance();
    final hasCompleted = await prefs.getBool(_normalizeFeatureId(featureId));
    return hasCompleted == true;
  }

  @override
  Future<Set<String>> completedSteps(Iterable<String> featuresIds) async {
    final prefs = await SharedPreferences.getInstance();
    return featuresIds
        .where((featureId) => prefs.getBool(_normalizeFeatureId(featureId)) == true)
        .toSet();
  }

  @override
  Future<void> completeStep(String featureId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_normalizeFeatureId(featureId), true);
  }

  @override
  Future<void> clearStep(String featureId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_normalizeFeatureId(featureId));
  }

  @override
  Future<void> clearSteps(Iterable<String> featuresIds) async {
    final prefs = await SharedPreferences.getInstance();
    featuresIds.map<Future>((featureId) => prefs.remove(_normalizeFeatureId(featureId)));
  }

  String _normalizeFeatureId(String featureId) => '$sharedPrefsPrefix$featureId';
}

/// Implementation of [PersistenceProvider] that uses internal memory for persistence.
///
/// Of course, once the app is stopped or cleared from memory, the internal memory is deleted
/// and historic persistence of completed steps are lost.
///
/// This is a great implementation for testing.
class MemoryPersistenceProvider implements PersistenceProvider {
  MemoryPersistenceProvider();

  final _steps = <String>{};

  @override
  Future<bool> hasCompletedStep(String featureId) async => _steps.contains(featureId);

  @override
  Future<Set<String>> completedSteps(Iterable<String> featuresIds) async =>
      featuresIds.where((featureId) => _steps.contains(featureId)).toSet();

  @override
  Future<void> completeStep(String featureId) async => _steps.add(featureId);

  @override
  Future<void> clearStep(String featureId) async => _steps.remove(featureId);

  @override
  Future<void> clearSteps(Iterable<String> featuresIds) async => featuresIds.forEach(clearStep);
}

/// Implementation of [PersistenceProvider] that does absolutely nothing.
///
/// The return values of [hasCompletedStep] is false, and of [completedSteps] is an empty set.
class NoPersistenceProvider implements PersistenceProvider {
  const NoPersistenceProvider();

  @override
  Future<bool> hasCompletedStep(String featureId) async => false;

  @override
  Future<Set<String>> completedSteps(Iterable<String> featuresIds) async => <String>{};

  @override
  Future<void> completeStep(String featureId) async {
    // NO-OP
  }

  @override
  Future<void> clearStep(String featureId) async {
    // NO-OP
  }

  @override
  Future<void> clearSteps(Iterable<String> featuresIds) async {
    // NO-OP
  }
}
