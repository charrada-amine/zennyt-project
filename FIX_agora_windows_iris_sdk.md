# Fix — Erreur build Windows avec `agora_rtc_engine: ^6.6.3`

## Symptôme

`flutter run -d windows` (ou `flutter build windows`) échoue avec :

```
CMake Error: Problem with archive_write_header(): Cannot extract through symlink
\\?\...\windows\flutter\ephemeral\.plugin_symlinks\agora_rtc_engine
CMake Error: Current file:
  iris_4.6.2-build.1_DCG_Windows/
CMake Error: Problem extracting tar:
  .../third_party/iris/iris_4.6.2-build.1_DCG_Windows_Video_Standalone_....zip
CMake Warning ... IRIS_INCLUDE_DIR:
CMake Warning ... IRIS_LIB_DIR:
CMake Error ... Failed to find include directory and library directory of Iris SDK
```

Ou en amont :

```
Error: Building with plugins requires symlink support.
Please enable Developer Mode in your system settings.
```

## Cause

1. **Symlink support requis** : Flutter place les plugins Windows dans `windows/flutter/ephemeral/.plugin_symlinks/` via de vrais symlinks NTFS. Ça nécessite le **Mode développeur Windows activé**.

2. **Extraction bloquée par CMake** : `agora_rtc_engine` télécharge automatiquement le SDK Iris (rendu vidéo) et le SDK natif Agora pendant la génération CMake, via le script `windows/cmake/DownloadSDK.cmake`. Ce script extrait les zips avec `cmake -E tar xzf` **à travers le chemin symlinké**. Or CMake/libarchive refuse par sécurité d'extraire une archive quand le chemin de destination traverse un symlink → échec systématique, peu importe la machine.

3. **Chemins trop longs (bonus)** : le SDK natif Agora contient un dossier `doc/cpp/html/` avec des noms de fichiers Doxygen très longs. Combiné au chemin du pub cache Windows, ça dépasse la limite `MAX_PATH` (260 caractères) si le support des chemins longs n'est pas activé.

## Solution

Le plugin prévoit un mécanisme officiel pour ce cas : un fichier `.plugin_dev` qui désactive le téléchargement/extraction automatique, à condition d'avoir pré-extrait soi-même le SDK au bon endroit.

### Étape 0 — Activer le Mode développeur Windows

```powershell
start ms-settings:developers
```

→ Activer "Mode développeur".

### Étape 1 — Activer le support des chemins longs (PowerShell en Administrateur)

```powershell
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
```

Redémarrer la session Windows (ou fermer/rouvrir PowerShell) après cette commande.

### Étape 2 — Extraire manuellement le SDK Iris et le SDK Native

> ⚠️ Vérifier au préalable le numéro de version du package installé (ici `6.6.3`) et adapter le chemin si différent. Les URLs de téléchargement viennent de `%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\agora_rtc_engine-<version>\windows\cmake\DownloadSDK.cmake` — les recopier si elles diffèrent.

```powershell
$base = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\agora_rtc_engine-6.6.3\windows"

# --- SDK Iris ---
Remove-Item -Recurse -Force "$base\third_party\iris" -ErrorAction SilentlyContinue
mkdir "$base\third_party\iris\lib" -Force
Invoke-WebRequest -Uri "https://download.agora.io/sdk/release/iris_4.6.2-build.1_DCG_Windows_Video_Standalone_20260212_0947_31926.zip" -OutFile "$base\third_party\iris\iris.zip"
cd "$base\third_party\iris\lib"
tar -xf "$base\third_party\iris\iris.zip"

# --- SDK Native ---
Remove-Item -Recurse -Force "$base\third_party\native" -ErrorAction SilentlyContinue
mkdir "$base\third_party\native\lib" -Force
Invoke-WebRequest -Uri "https://download.agora.io/sdk/release/Agora_Native_SDK_for_Windows_rel.v4.6.2.70_31618_FULL_20260211_1724_1009714.zip" -OutFile "$base\third_party\native\native.zip"
cd "$base\third_party\native\lib"
tar -xf "$base\third_party\native\native.zip" --exclude="*/doc/*"
```

`tar.exe` (intégré à Windows 10/11) est utilisé à la place de `Expand-Archive`, qui gère mal les chemins longs. Le dossier `doc/` (documentation, non nécessaire à la compilation) est exclu pour éviter tout souci de longueur de chemin résiduel.

### Étape 3 — Vérifier que la structure extraite est correcte

```powershell
Get-ChildItem -Recurse -Directory "$base\third_party\iris\lib" | Where-Object { $_.Name -eq "include" -or $_.Name -eq "Release" } | Select-Object -ExpandProperty FullName

Get-ChildItem -Recurse -Directory "$base\third_party\native\lib" | Where-Object { $_.Name -eq "sdk" } | Select-Object -ExpandProperty FullName
```

Résultat attendu (exemple) :

```
...\third_party\iris\lib\iris_4.6.2-build.1_DCG_Windows\x64\include
...\third_party\iris\lib\iris_4.6.2-build.1_DCG_Windows\x64\Release
...\third_party\native\lib\Agora_Native_SDK_for_Windows_FULL\sdk
```

Si rien ne s'affiche, la structure interne du zip a changé de nom : demander de l'aide plutôt que de continuer, car les étapes suivantes en dépendent.

### Étape 4 — Créer le flag qui désactive le téléchargement/extraction automatique

```powershell
New-Item -ItemType File -Path "$base\.plugin_dev" -Force
```

### Étape 5 — Rebuild

```powershell
cd <chemin_du_projet>\mobile
flutter clean
flutter pub get
flutter run -d windows
```

Le build doit maintenant afficher `IRIS_INCLUDE_DIR:`, `IRIS_LIB_DIR:`, `NATIVE_INCLUDE_DIR:`, `NATIVE_LIB_DIR:` correctement résolus, puis les `Add bundled library: ...dll` sans erreur CMake.

## À savoir pour toute l'équipe

- Cette procédure est **par machine et par version de `agora_rtc_engine`** : elle agit sur le cache pub local (`%LOCALAPPDATA%\Pub\Cache\...`), pas sur le dépôt Git du projet. Chaque développeur qui build en Windows doit la refaire une fois sur sa machine.
- `flutter clean` ne supprime pas le pub cache : une fois fait, pas besoin de recommencer à chaque `flutter clean`.
- Un `flutter pub cache repair --all` ou une mise à jour de version d'`agora_rtc_engine` supprime `.plugin_dev` et le dossier `third_party` → il faudra refaire cette procédure.
- Si l'objectif de build est uniquement **Android**, ce problème n'a aucun impact : ne pas cibler `flutter run -d windows`.
