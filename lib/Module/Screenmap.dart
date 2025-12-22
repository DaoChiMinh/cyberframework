import 'package:cyberframework/Controller/CyberContentView.dart';
import 'package:cyberframework/Module/cyber.form.dart';
import 'package:get_it/get_it.dart';

final _getIt = GetIt.instance;
final Map<String, CyberForm Function()> _factoryMap_form = {};
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
  } catch (e) {
    print('⚠️ No CyberForm registered: $e');
  }

  // Build ContentView factory map
  try {
    final contentViews = _getIt.getAll<CyberContentViewForm>();
    for (var view in contentViews) {
      final lowerName = view.runtimeType.toString().toLowerCase();
      _factoryMap_contentView[lowerName] = () => view;
    }
  } catch (e) {
    print('⚠️ No CyberContentViewForm registered: $e');
  }
}
// void buildFactoryMap() {
//   _factoryMap_form.clear();
//   _factoryMap_contentView.clear();

//   // Build Form factory map
//   final forms = _getIt.getAll<CyberForm>();
//   for (var form in forms) {
//     final lowerName = form.runtimeType.toString().toLowerCase();
//     _factoryMap_form[lowerName] = () => form;
//   }

//   // Build ContentView factory map
//   final contentViews = _getIt.getAll<CyberContentViewForm>();
//   for (var view in contentViews) {
//     final lowerName = view.runtimeType.toString().toLowerCase();
//     _factoryMap_contentView[lowerName] = () => view;
//   }
// }

/// Get CyberFormView từ tên form
CyberFormView? V_getScreen(
  String strfrm,
  String title,
  String cpName,
  String strparameter, {
  bool hideAppBar = false,
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
  );
}

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
