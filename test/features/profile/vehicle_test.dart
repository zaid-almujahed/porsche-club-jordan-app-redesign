import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pcj_v5/core/cache/memory_cache.dart';
import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/network/pcj_api_client.dart';
import 'package:pcj_v5/core/network/token_store.dart';
import 'package:pcj_v5/core/services/image_picker_service.dart';
import 'package:pcj_v5/core/validation/vehicle_rules.dart';
import 'package:pcj_v5/features/profile/data/repositories/api_profile_repository.dart';
import 'package:pcj_v5/features/profile/domain/repositories/profile_repository.dart';
import 'package:pcj_v5/features/profile/presentation/controllers/profile_controller.dart';
import 'package:pcj_v5/features/profile/presentation/controllers/vehicle_form_controller.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';
import 'package:pcj_v5/shared/domain/entities/vehicle.dart';

const Vehicle _car = Vehicle(
  id: '1',
  model: '911 Carrera',
  year: 2020,
  vin: 'WP0ZZZ99ZTS392124',
  licensePlate: '12-34567',
);

// Picked photos always have a path; the name comes from it.
XFile _photo() => XFile.fromData(
  Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0xE0]),
  path: 'plate.jpg',
);

void main() {
  group('VehicleRules', () {
    test('model, year and a 10- or 17-character VIN are required', () {
      String? check(String model, String year, String vin) =>
          VehicleRules.validationMessage(model: model, year: year, vin: vin);

      expect(check('911', '2020', 'WP0ZZZ99ZTS392124'), isNull);
      expect(check('356', '1960', '1234567890'), isNull);
      expect(check(' ', '2020', 'WP0ZZZ99ZTS392124'), 'Enter the car model.');
      expect(check('911', '1947', 'WP0ZZZ99ZTS392124'), contains('1948'));
      expect(check('911', '2020', 'SHORT'), contains('10 or 17'));
    });
  });

  group('VehicleFormController', () {
    test('adding a car needs a licence plate photo', () async {
      final VehicleFormController form = VehicleFormController(
        pickPhoto: () async => _photo(),
      );
      addTearDown(form.dispose);
      form.modelController.text = '911 Carrera';
      form.yearController.text = '2020';
      form.vinController.text = 'WP0ZZZ99ZTS392124';

      expect(await form.buildDraft(), isNull);
      expect(form.error, 'Add a photo of the licence plate.');

      await form.pickPhoto();
      final VehicleDraft? draft = await form.buildDraft();
      expect(draft?.licensePlatePhoto?.fileName, 'plate.jpg');
      expect(draft?.licensePlate, isEmpty);
    });

    test('editing starts from the car and keeps its photo', () async {
      final VehicleFormController form = VehicleFormController(
        pickPhoto: () async => null,
        vehicle: _car,
      );
      addTearDown(form.dispose);

      expect(form.modelController.text, '911 Carrera');
      expect(form.yearController.text, '2020');
      expect(form.plateController.text, '12-34567');

      form.modelController.text = '911 Turbo';
      final VehicleDraft? draft = await form.buildDraft();
      expect(draft?.model, '911 Turbo');
      expect(draft?.licensePlatePhoto, isNull);
    });
  });

  group('ProfileController', () {
    test('add, update and remove refresh the garage', () async {
      final _FakeProfileRepository repository = _FakeProfileRepository();
      final ProfileController controller = ProfileController(
        repository: repository,
        imagePickerService: ImagePickerService(),
      );
      addTearDown(controller.dispose);
      await controller.load();

      const VehicleDraft draft = VehicleDraft(
        vin: 'WP0ZZZ99ZTS392124',
        model: '911 Carrera',
        year: 2020,
      );
      expect(await controller.addVehicle(draft), isTrue);
      expect(controller.vehicles.single.model, '911 Carrera');

      expect(
        await controller.updateVehicle(
          '1',
          const VehicleDraft(
            vin: 'WP0ZZZ99ZTS392124',
            model: '911 Turbo',
            year: 2020,
          ),
        ),
        isTrue,
      );
      expect(controller.vehicles.single.model, '911 Turbo');

      expect(await controller.deleteVehicle('1'), isTrue);
      expect(controller.vehicles, isEmpty);
      expect(repository.calls, <String>['add', 'update 1', 'delete 1']);
    });

    test('a failed request is shown and nothing changes', () async {
      final _FakeProfileRepository repository = _FakeProfileRepository()
        ..error = const AppException('VIN already registered.');
      final ProfileController controller = ProfileController(
        repository: repository,
        imagePickerService: ImagePickerService(),
      );
      addTearDown(controller.dispose);
      await controller.load();

      expect(
        await controller.addVehicle(
          const VehicleDraft(
            vin: 'WP0ZZZ99ZTS392124',
            model: '911',
            year: 2020,
          ),
        ),
        isFalse,
      );
      expect(
        readableError(controller.vehicleError!),
        'VIN already registered.',
      );
      expect(controller.vehicles, isEmpty);
      expect(controller.isSavingVehicle, isFalse);
    });
  });

  group('ApiProfileRepository sends /member/cars as documented', () {
    late List<http.Request> requests;
    late ApiProfileRepository repository;

    setUp(() {
      requests = <http.Request>[];
      final MockClient client = MockClient((http.Request request) async {
        requests.add(request);
        final Object body = switch (request.url.path) {
          '/member/profile' => <String, Object>{'id': 1, 'name': 'Member'},
          '/member/membership' => <String, Object>{'status': 'ACTIVE'},
          '/member/cars' => <String, Object>{'cars': <Object>[]},
          _ => <String, Object>{'message': 'OK'},
        };
        return http.Response(jsonEncode(body), 200);
      });
      repository = ApiProfileRepository(
        apiClient: PcjApiClient(client, tokenStore: _MemoryTokenStore()),
        cache: MemoryCache(),
      );
    });

    // Latin-1 keeps the photo bytes readable as text.
    String sent(http.Request request) => latin1.decode(request.bodyBytes);

    test('POST with the fields and the licence plate photo', () async {
      await repository.addVehicle(
        VehicleDraft(
          vin: 'WP0ZZZ99ZTS392124',
          model: '911 Carrera',
          year: 2020,
          licensePlate: '12-34567',
          licensePlatePhoto: VehiclePhoto(
            bytes: Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF]),
            fileName: 'plate.jpg',
          ),
        ),
      );

      final http.Request post = requests.first;
      expect('${post.method} ${post.url.path}', 'POST /member/cars');
      expect(post.headers['content-type'], startsWith('multipart/form-data'));
      for (final String part in <String>[
        'name="VIN_Number"',
        'name="model"',
        'name="year"',
        'name="License_Plate"',
        'name="license_plate_photo"; filename="plate.jpg"',
      ]) {
        expect(sent(post), contains(part));
      }
      // The refreshed garage is read back.
      expect(
        requests.map((http.Request r) => r.url.path),
        contains('/member/cars'),
      );
    });

    test('PUT without a new photo, and no empty plate', () async {
      await repository.updateVehicle(
        '7',
        const VehicleDraft(
          vin: 'WP0ZZZ99ZTS392124',
          model: '911 Turbo',
          year: 2021,
          licensePlate: ' ',
        ),
      );

      final http.Request put = requests.first;
      expect('${put.method} ${put.url.path}', 'PUT /member/cars/7');
      expect(sent(put), contains('911 Turbo'));
      expect(sent(put), isNot(contains('license_plate_photo')));
      expect(sent(put), isNot(contains('License_Plate')));
    });

    test('DELETE by car id; a car without a numeric id is refused', () async {
      await repository.deleteVehicle('7');
      expect(
        '${requests.first.method} ${requests.first.url.path}',
        'DELETE /member/cars/7',
      );

      requests.clear();
      await expectLater(
        repository.deleteVehicle('WP0ZZZ99ZTS392124'),
        throwsA(isA<AppException>()),
      );
      expect(requests, isEmpty);
    });
  });
}

class _MemoryTokenStore implements TokenStore {
  @override
  Future<String?> read() async => 'token';

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> write(String token, {String? refreshToken}) async {}

  @override
  Future<void> clear() async {}
}

/// Keeps the member's cars in memory, like the backend.
class _FakeProfileRepository implements ProfileRepository {
  final List<String> calls = <String>[];
  final List<Vehicle> cars = <Vehicle>[];

  /// Thrown by the next change.
  Object? error;

  User get _user => User(
    id: '1',
    name: 'Member',
    email: 'member@example.com',
    phoneNumber: '+962790000000',
    applicationStatus: ApplicationStatus.approved,
    membershipStatus: MembershipStatus.active,
    vehicles: List<Vehicle>.of(cars),
  );

  Vehicle _fromDraft(String id, VehicleDraft draft) => Vehicle(
    id: id,
    model: draft.model,
    year: draft.year,
    vin: draft.vin,
    licensePlate: draft.licensePlate ?? '',
  );

  Future<User> _change(String call, void Function() apply) async {
    final Object? failure = error;
    error = null;
    if (failure != null) throw failure;
    calls.add(call);
    apply();
    return _user;
  }

  @override
  Future<User> getProfile({bool forceRefresh = false}) async => _user;

  @override
  Future<User> addVehicle(VehicleDraft vehicle) =>
      _change('add', () => cars.add(_fromDraft('1', vehicle)));

  @override
  Future<User> updateVehicle(String vehicleId, VehicleDraft vehicle) =>
      _change('update $vehicleId', () {
        final int index = cars.indexWhere((Vehicle car) => car.id == vehicleId);
        cars[index] = _fromDraft(vehicleId, vehicle);
      });

  @override
  Future<User> deleteVehicle(String vehicleId) => _change(
    'delete $vehicleId',
    () => cars.removeWhere((Vehicle car) => car.id == vehicleId),
  );

  @override
  Future<User> updateProfile(ProfileUpdate update) =>
      throw UnimplementedError();

  @override
  Future<User> updatePhoneNumber(String phoneNumber) =>
      throw UnimplementedError();

  @override
  Future<void> deleteAccount() => throw UnimplementedError();
}
