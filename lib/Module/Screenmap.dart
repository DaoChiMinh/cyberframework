import 'package:cyberframework/cyberframework.dart';
import 'package:get_it/get_it.dart';

final _getIt = GetIt.instance;

// ignore: non_constant_identifier_names
final Map<String, CyberForm Function()> _factoryMap_form = {};
// ignore: non_constant_identifier_names
final Map<String, CyberContentViewForm Function()> _factoryMap_contentView = {};

// ✅ NEW: Cache runtime types for factory creation
final Map<String, Type> _formTypes = {};
final Map<String, Type> _contentViewTypes = {};

/// ✅ FIXED: Build factory map WITHOUT capturing instances
void buildFactoryMap() {
  _factoryMap_form.clear();
  _factoryMap_contentView.clear();
  _formTypes.clear();
  _contentViewTypes.clear();

  // ============================================================================
  // ✅ Build Form factory map
  // ============================================================================
  try {
    final forms = _getIt.getAll<CyberForm>();

    for (var form in forms) {
      final lowerName = form.runtimeType.toString().toLowerCase();
      final formType = form.runtimeType;

      // ✅ Store type for later use
      _formTypes[lowerName] = formType;

      // ✅ FIX: Create factory that calls GetIt to create NEW instance
      // Instead of: () => form (captures same instance forever)
      // We do: () => _createFormInstance(formType) (creates new instance each time)
      _factoryMap_form[lowerName] = () {
        try {
          // ✅ Get NEW instance from GetIt (if registered as factory)
          // If registered as singleton, GetIt returns same instance (user's choice)
          return _getIt.get<CyberForm>(instanceName: lowerName);
        } catch (e) {
          // ✅ Fallback: Try generic get
          try {
            return _getIt.get(type: formType) as CyberForm;
          } catch (e2) {
            // ✅ Last resort: Try without instance name
            try {
              return _getIt.get<CyberForm>();
            } catch (e3) {
              // ✅ If all fail, create reflection-based instance
              return _createInstanceByType<CyberForm>(formType);
            }
          }
        }
      };
    }
  } catch (e) {
    debugPrint('⚠️ Error building form factory map: $e');
  }

  // ============================================================================
  // ✅ Build ContentView factory map
  // ============================================================================
  try {
    final contentViews = _getIt.getAll<CyberContentViewForm>();

    for (var view in contentViews) {
      final lowerName = view.runtimeType.toString().toLowerCase();
      final viewType = view.runtimeType;

      // ✅ Store type
      _contentViewTypes[lowerName] = viewType;

      // ✅ FIX: Factory that creates NEW instance
      _factoryMap_contentView[lowerName] = () {
        try {
          return _getIt.get<CyberContentViewForm>(instanceName: lowerName);
        } catch (e) {
          try {
            return _getIt.get(type: viewType) as CyberContentViewForm;
          } catch (e2) {
            try {
              return _getIt.get<CyberContentViewForm>();
            } catch (e3) {
              return _createInstanceByType<CyberContentViewForm>(viewType);
            }
          }
        }
      };
    }
  } catch (e) {
    debugPrint('⚠️ Error building contentview factory map: $e');
  }

  // ✅ Log statistics
  debugPrint('📋 Factory map built:');
  debugPrint('   - Forms: ${_factoryMap_form.length}');
  debugPrint('   - ContentViews: ${_factoryMap_contentView.length}');
}

/// ✅ NEW: Create instance by Type using reflection
/// This is fallback when GetIt fails
T _createInstanceByType<T>(Type type) {
  // Note: This requires forms to have default constructors
  // If your forms have required parameters, this will fail

  try {
    // ✅ Try to get from GetIt first (might be registered differently)
    return _getIt.get(type: type) as T;
  } catch (e) {
    // ✅ If GetIt fails, throw error with helpful message
    throw Exception(
      'Cannot create instance of $type. '
      'Make sure it is registered in GetIt as factory: '
      'GetIt.I.registerFactory(() => YourForm())',
    );
  }
}

/// Get CyberFormView từ tên form
// ignore: non_constant_identifier_names
CyberFormView? V_getScreen(
  String strfrm,
  String title,
  String cpName,
  String strparameter, {
  bool hideAppBar = false,
  bool isMainScreen = false,
}) {
  final normalizedName = strfrm.toLowerCase().trim();
  final factory = _factoryMap_form[normalizedName];

  if (factory == null) {
    debugPrint('⚠️ Form not found: $strfrm (normalized: $normalizedName)');
    debugPrint('   Available forms: ${_factoryMap_form.keys.join(", ")}');
    return null;
  }

  // ✅ Factory now creates NEW instance each time!
  return CyberFormView(
    title: title,
    formBuilder: factory,
    cp_name: cpName,
    strparameter: strparameter,
    hideAppBar: hideAppBar,
    isMainScreen: isMainScreen,
  );
}

// ignore: non_constant_identifier_names
CyberContentViewWidget? V_getView(
  String viewName, {
  String cpName = "",
  String strParameter = "",
  dynamic objectData,
}) {
  final normalizedName = viewName.toLowerCase().trim();
  final factory = _factoryMap_contentView[normalizedName];

  if (factory == null) {
    debugPrint(
      '⚠️ ContentView not found: $viewName (normalized: $normalizedName)',
    );
    debugPrint(
      '   Available views: ${_factoryMap_contentView.keys.join(", ")}',
    );
    return null;
  }

  return CyberContentViewWidget(
    formBuilder: factory,
    cpName: cpName,
    strParameter: strParameter,
    objectData: objectData,
  );
}

// ignore: non_constant_identifier_names
CyberContentViewForm? V_getViewInstance(
  String viewName, {
  String cpName = "",
  String strParameter = "",
  dynamic objectData,
}) {
  final normalizedName = viewName.toLowerCase().trim();
  final factory = _factoryMap_contentView[normalizedName];

  if (factory == null) {
    debugPrint('⚠️ ContentView not found: $viewName');
    return null;
  }

  // ✅ Factory creates NEW instance
  final instance = factory();

  // Initialize instance with parameters
  instance.internalCpName = cpName;
  instance.internalStrParameter = strParameter;
  instance.internalObjectData = objectData;

  return instance;
}
