import 'package:simply_sdk/api/being/medication.dart';
import 'package:simply_sdk/api/being/medicationLogs.dart';
import 'package:simply_sdk/api/being/symptomLogs.dart';
import 'package:simply_sdk/api/being/symptoms.dart';

import '../api/main.dart';
import '../simply_sdk.dart';
import '../types/document.dart';
import 'collection.dart';

class BeingStore {
  bool storeInitialized = false;

  List<Document<SymptomData>> _symptoms = [];
  List<Document<MedicationData>> _medication = [];
  List<Document<SymptomLogData>> _symptomLogs = [];
  List<Document<MedicationLogData>> _medicationLogs = [];

  List<Document<SymptomData>> getAllSymptoms() => _symptoms;
  List<Document<MedicationData>> getAllMedication() => _medication;
  List<Document<SymptomLogData>> getAllSymptomLogs() => _symptomLogs;
  List<Document<MedicationLogData>> getAllMedicationLogs() => _medicationLogs;

  List<Function?> _onInitialized = [];

  Future<void> initializeStore() async {
    clearStore();
    _symptoms = await API().symptoms().getAll();
    _medication = await API().medication().getAll();
    _symptomLogs = await API().symptomLogs().getLogEntriesInRange(
        DateTime.now().subtract(Duration(days: 14)).millisecondsSinceEpoch,
        DateTime.now().millisecondsSinceEpoch);
    _medicationLogs = await API().medicationLogs().getLogEntriesInRange(
        DateTime.now().subtract(Duration(days: 14)).millisecondsSinceEpoch,
        DateTime.now().millisecondsSinceEpoch);

    // Emit initial changes
    if (_symptoms.isNotEmpty)
      API().symptoms().propogateChanges(_symptoms.first, EChangeType.Update);

    if (_medication.isNotEmpty)
      API()
          .medication()
          .propogateChanges(_medication.first, EChangeType.Update);

    if (_symptomLogs.isNotEmpty)
      API()
          .symptomLogs()
          .propogateChanges(_symptomLogs.first, EChangeType.Update);

    if (_medicationLogs.isNotEmpty)
      API()
          .medicationLogs()
          .propogateChanges(_medicationLogs.first, EChangeType.Update);

    API().symptoms().listenForChanges(symptomChanged);
    API().medication().listenForChanges(medicationChanged);
    API().symptomLogs().listenForChanges(symptomLogChanged);
    API().medicationLogs().listenForChanges(medicationLogChanged);

    storeInitialized = true;

    _onInitialized.forEach((element) {
      if (element != null) element();
    });
  }

  // Edit this so that in the future we can use "since", in a way that takes in account deletions since
  Future<void> updateStore(int since) async {
    _symptoms = await API().symptoms().getAll();
    _medication = await API().medication().getAll();
    _symptomLogs = await API().symptomLogs().getLogEntriesInRange(
        DateTime.now().subtract(Duration(days: 14)).millisecondsSinceEpoch,
        DateTime.now().millisecondsSinceEpoch);
    _medicationLogs = await API().medicationLogs().getLogEntriesInRange(
        DateTime.now().subtract(Duration(days: 14)).millisecondsSinceEpoch,
        DateTime.now().millisecondsSinceEpoch);
  }

  void clearStore() {
    storeInitialized = false;

    _symptoms = [];
    _medication = [];
    _symptomLogs = [];
    _medicationLogs = [];

    API().symptoms().cancelListenForChanges(symptomChanged);
    API().medication().cancelListenForChanges(medicationChanged);
    API().symptomLogs().cancelListenForChanges(symptomLogChanged);
    API().medicationLogs().cancelListenForChanges(medicationLogChanged);
  }

  void symptomChanged(Document<dynamic> data, EChangeType changeType) {
    updateDocumentInList<SymptomData>(
        _symptoms, data as Document<SymptomData>, changeType);
  }

  void medicationChanged(Document<dynamic> data, EChangeType changeType) {
    updateDocumentInList<MedicationData>(
        _medication, data as Document<MedicationData>, changeType);
  }

  void symptomLogChanged(Document<dynamic> data, EChangeType changeType) {
    updateDocumentInList<SymptomLogData>(
        _symptomLogs, data as Document<SymptomLogData>, changeType);
  }

  void medicationLogChanged(Document<dynamic> data, EChangeType changeType) {
    updateDocumentInList<MedicationLogData>(
        _medicationLogs, data as Document<MedicationLogData>, changeType);
  }
}
