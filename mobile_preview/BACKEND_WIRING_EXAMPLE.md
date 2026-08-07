# Worked example — wiring the **Fits** feature to the real backend

Companion to `BACKEND_WIRING.md`. This shows the **exact, copy-paste** changes for one
feature (Fits → `GET /job-offers`), using the real class names that already exist in
`mobile_preview/`. Every other feature follows the same three-step shape.

> Domain entities (`FitItem`), the repository interface (`FitsRepository`), the model
> (`FitItemModel`), the bloc, and the page **do not change**. You only add a remote
> datasource and flip one DI line.

---

## Step A — add a remote datasource next to the mock

The existing abstract port is `FitsLocalDataSource` with `Future<List<FitItemModel>> getFits(FitKind kind)`
(`features/fits/data/datasources/fits_local_datasource.dart`). Implement it with Dio:

```dart
// features/fits/data/datasources/fits_remote_datasource.dart
import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/fit_item.dart';
import '../models/fit_item_model.dart';
import 'fits_local_datasource.dart';

/// Real implementation: GET /job-offers → FitItemModel.
/// (Professionals tab has no recruitment endpoint yet — see BACKEND_WIRING.md §5.)
class FitsRemoteDataSource implements FitsLocalDataSource {
  final Dio dio;
  FitsRemoteDataSource(this.dio);

  @override
  Future<List<FitItemModel>> getFits(FitKind kind) async {
    if (kind == FitKind.professional) {
      // No candidate-feed endpoint yet: return empty (or keep mock for this tab).
      return const [];
    }
    try {
      final res = await dio.get('/job-offers', queryParameters: {
        'page': 0,
        'size': 20,
      });
      // Spring Page<> → { content: [...], totalElements, ... }. Adjust if your
      // controller returns a bare list.
      final data = res.data;
      final list = (data is Map && data['content'] is List)
          ? data['content'] as List
          : data as List;
      return list
          .map((j) => _fromJobOffer(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error');
    }
  }

  /// Maps the backend JobOfferResponse JSON onto the existing FitItemModel.
  FitItemModel _fromJobOffer(Map<String, dynamic> j) {
    final city = j['locationCity'] as String?;
    final country = j['locationCountry'] as String?;
    final remote = j['locationRemote'] == true;
    final location = remote
        ? 'Remote'
        : [city, country].where((s) => s != null && s.isNotEmpty).join(', ');

    final salaryMin = j['salaryMin'];
    final salaryMax = j['salaryMax'];
    final cur = j['salaryCurrency'] as String? ?? '';
    final salary = (salaryMin != null || salaryMax != null)
        ? '${salaryMin ?? ''}–${salaryMax ?? ''} $cur'.trim()
        : null;

    final tags = <String>[
      if (j['experienceLevel'] != null) _pretty(j['experienceLevel']),
      if (j['contractType'] != null) _pretty(j['contractType']),
      if (j['workplaceType'] != null) _pretty(j['workplaceType']),
      if (j['openToInternational'] == true) 'International candidates welcome',
    ];

    return FitItemModel(
      id: j['id'] as String,
      kind: FitKind.jobOffer,
      fitScore: 0, // fill via GET /fit-scores?candidateId&jobOfferId if needed
      name: j['companyName'] as String? ?? '',
      imageUrl: '', // backend has no logo field; FitCard already has a fallback
      role: j['title'] as String? ?? '',
      location: location,
      tags: tags,
      salary: salary,
      about: j['description'] as String?,
    );
  }

  // FULL_TIME -> "Full time", ON_SITE -> "On site"
  String _pretty(Object e) => e
      .toString()
      .split('_')
      .map((w) => w.isEmpty ? w : w[0] + w.substring(1).toLowerCase())
      .join(' ');
}
```

> If `core/error/exceptions.dart` doesn't have `ServerException`, either add it or reuse the
> existing `CacheException` — `FitsRepositoryImpl` currently catches `CacheException`. Simplest:
> add a `ServerException`/`ServerFailure` pair and a matching `catch` in the repo impl.

---

## Step B — (optional) enrich with the fit score

The `fitScore` % is a **separate** endpoint. If you want the real number on each card, after
loading offers call `GET /fit-scores?candidateId={me}&jobOfferId={offer}` per offer (or batch
it). For Phase A you can leave it `0` or hardcode for the demo.

---

## Step C — flip the DI registration (one line)

In `core/di/injection.dart`, the Fits block is:

```dart
// ───── Feature : fits (deck swipe, données mock) ─────
sl.registerSingleton<FitsLocalDataSource>(FitsMockDataSource());           // ← was mock
sl.registerSingleton<FitsRepository>(FitsRepositoryImpl(local: sl()));
sl.registerSingleton(GetFits(sl()));
sl.registerFactory(() => FitsBloc(getFits: sl()));
```

Change the first line to the remote datasource (Dio is already registered at line ~58):

```dart
import '../../features/fits/data/datasources/fits_remote_datasource.dart';
// ...
sl.registerSingleton<FitsLocalDataSource>(FitsRemoteDataSource(sl<Dio>()));
```

Everything downstream (repository → usecase → bloc → page) is unchanged. Done.

---

## The auth header (Phase A) — register once

`initDependencies({required String apiBaseUrl})` already builds and registers Dio via
`DioClient.create(...)` (line ~58). Add the dev identity interceptor right after:

```dart
final dio = DioClient.create(baseUrl: apiBaseUrl, storage: storage);
dio.interceptors.add(DevIdentityInterceptor());   // Phase A only
sl.registerSingleton(dio);
```

(See `BACKEND_WIRING.md` §3 for `DevIdentityInterceptor`. In Phase B you drop it and rely on
the already-present `AuthInterceptor` + a real login.)

---

## Phase B — minimal login (when Identity is merged)

```dart
// features/auth/data/auth_remote_datasource.dart
class AuthRemoteDataSource {
  final Dio dio;
  final FlutterSecureStorage storage;
  AuthRemoteDataSource(this.dio, this.storage);

  Future<String> login(String email, String password) async {
    final res = await dio.post('/auth/login',
        data: {'email': email, 'password': password});
    await storage.write(key: 'access_token', value: res.data['accessToken']);
    await storage.write(key: 'refresh_token', value: res.data['refreshToken']);
    final me = await dio.get('/users/me');           // {id, email, role, ...}
    return me.data['role'] as String;                 // CANDIDATE | RECRUITER | ADMIN
  }
}

// after login:
appIsRecruiter.value = (role == 'RECRUITER');         // drives the whole UI
context.go('/home');
```

The keys `access_token` / `refresh_token` are exactly what the existing `AuthInterceptor`
reads, so Bearer-attach + refresh-on-401 work with **zero** extra code.

---

## Apply the same pattern to the rest of the recruitment flow

| Feature | New remote datasource calls | DI line to flip |
|---|---|---|
| Swipe (in Fits bloc/repo) | `POST /swipes` | add a `SwipesRemoteDataSource` + repo method |
| Job detail | `GET /job-offers/{id}` | job-detail datasource |
| Apply | `POST /applications` | — |
| Assessment submit | `POST /assessment-attempts` | assessment datasource |
| Careers offers | `GET /recruiters/me/job-offers` | careers datasource (mock → remote) |
| Create offer | `POST /job-offers` + `PATCH /job-offers/{id}/status` | — |
| Tests | `GET /assessments/mine`, `POST /assessments` | careers/tests datasource |
| Scores | `GET /assessment-attempts?jobOfferId=` | scores datasource |
| Opportunity + OTP | `POST /job-opportunity-offers`, `/confirm`, `/verify-otp` | chat/opportunity datasource |

See `BACKEND_WIRING.md` §4 for the full endpoint table, field maps, and exact enum strings.
