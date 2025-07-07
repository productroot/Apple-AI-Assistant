# Przejście na domyślny kontener iCloud

## Problem
Błąd "Field 'recordName' is not marked queryable" występował, ponieważ:
1. Używaliśmy custom kontenera CloudKit
2. Custom kontenery wymagają specjalnej konfiguracji w CloudKit Dashboard
3. Pola muszą być oznaczone jako "queryable" w schemacie

## Rozwiązanie

### Zmiana na domyślny kontener
```swift
// Zamiast:
container = CKContainer(identifier: "iCloud.io.productroot.assistant")

// Teraz:
container = CKContainer.default()
```

### Zalety domyślnego kontenera:
1. **Automatyczna konfiguracja** - nie wymaga ręcznej konfiguracji
2. **Wszystkie pola queryable** - domyślnie wszystkie pola można przeszukiwać
3. **Prostsze zarządzanie** - CloudKit automatycznie zarządza schematami
4. **Lepsza kompatybilność** - działa od razu bez dodatkowej konfiguracji

### Aktualizacja entitlements
```xml
<string>iCloud.$(CFBundleIdentifier)</string>
```
To automatycznie używa bundle ID aplikacji jako identyfikatora kontenera.

## Konfiguracja w Xcode

1. Otwórz projekt w Xcode
2. Wybierz target "Foundation Lab"
3. Przejdź do "Signing & Capabilities"
4. W sekcji iCloud:
   - ✅ CloudKit
   - ✅ Użyj domyślnego kontenera

## Migracja danych

Jeśli masz dane w starym kontenerze:
1. Eksportuj dane ze starego kontenera
2. Zmień na domyślny kontener
3. Importuj dane

## Testowanie

1. Usuń aplikację z urządzenia
2. Zainstaluj ponownie
3. Włącz iCloud sync
4. Dodaj zadanie - powinno zapisać się bez błędów
5. Sprawdź import z backupu

## Status
✅ Używamy domyślnego kontenera CloudKit
✅ Brak problemów z queryable fields
✅ Automatyczna konfiguracja schematów
✅ Import/export powinien działać poprawnie