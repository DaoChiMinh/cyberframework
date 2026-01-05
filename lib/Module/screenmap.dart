import 'package:cyberframework/cyberframework.dart';
import 'package:get_it/get_it.dart';

final _getIt = GetIt.instance;
// ignore: non_constant_identifier_names
final Map<String, CyberForm Function()> _factoryMap_form = {};
// ignore: non_constant_identifier_names
final Map<String, CyberContentViewForm Function()> _factoryMap_contentView = {};

void buildFactoryMap() {
  _factoryMap_form.clear();
  _factoryMap_contentView.clear();

  // Build Form factory map
  try {
    final forms = _getIt.getAll<CyberForm>();
    for (var form in forms) {
      final lowerName = form.runtimeType.toString().toLowerCase();
      _factoryMap_form[lowerName] = () => form;
    }
    // ignore: empty_catches
  } catch (e) {}

  // Build ContentView factory map
  try {
    final contentViews = _getIt.getAll<CyberContentViewForm>();
    for (var view in contentViews) {
      final lowerName = view.runtimeType.toString().toLowerCase();
      _factoryMap_contentView[lowerName] = () => view;
    }
    // ignore: empty_catches
  } catch (e) {}
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

  if (factory == null) return null;

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

  if (factory == null) return null;

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

  if (factory == null) return null;

  final instance = factory();
  // Initialize instance with parameters using internal setters
  instance.internalCpName = cpName;
  instance.internalStrParameter = strParameter;
  instance.internalObjectData = objectData;

  return instance;
}
