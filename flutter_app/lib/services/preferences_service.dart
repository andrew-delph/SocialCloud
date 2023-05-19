import 'package:flutter_app/utils/utils.dart';
import 'package:get/get.dart';

import 'options_service.dart';

class PreferencesService extends GetxController {
  final OptionsProvider optionsProvider = OptionsProvider();
  final RxMap<String, String> constantAttributes = <String, String>{}.obs;
  final RxMap<String, String> constantFilters = <String, String>{}.obs;
  final RxMap<String, String> customAttributes = <String, String>{}.obs;
  final RxMap<String, String> customFilters = <String, String>{}.obs;
  final RxDouble priority = (0.0).obs;
  RxBool unsavedChanges = false.obs;
  RxBool loading = false.obs;

  PreferencesService() {
    constantAttributes.listen((p0) {
      unsavedChanges(true);
    });
    constantFilters.listen((p0) {
      unsavedChanges(true);
    });
    customAttributes.listen((p0) {
      unsavedChanges(true);
    });
    customFilters.listen((p0) {
      unsavedChanges(true);
    });
  }

  Future<void> loadAttributes() async {
    loading(true);
    return optionsProvider.getPreferences().then((response) {
      Preferences? preferences = response.body;

      if (validStatusCode(response.statusCode) && preferences != null) {
      } else {
        String errorMsg = ('Failed to load preferences data.').toString();
        throw Exception(errorMsg);
      }

      constantAttributes.addAll(preferences.constantAttributes);
      constantFilters.addAll(preferences.constantFilters);
      customAttributes.addAll(preferences.customAttributes);
      customFilters.addAll(preferences.customFilters);
      priority(preferences.priority);
      unsavedChanges(false);
      loading(false);
    });
  }

  Future<void> updateAttributes() {
    final body = {
      'attributes': {
        'constant': constantAttributes,
        'custom': customAttributes
      },
      'filters': {
        'constant': constantFilters,
        'custom': customFilters,
      }
    };
    loading(true);
    return optionsProvider.updatePreferences(body).then((response) {
      if (validStatusCode(response.statusCode)) {
      } else {
        const String errorMsg = 'Failed to update preferences.';
        throw Exception(response.body.toString());
      }
    }).then((value) => loadAttributes());
  }
}
