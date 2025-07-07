# Naprawienie błędu CloudKit "Field 'recordName' is not marked queryable"

## Problem
CloudKit zgłaszał błąd przy próbie wykonania zapytań w custom zone. Pole 'recordName' nie jest domyślnie oznaczone jako queryable w custom zones.

## Rozwiązanie

### 1. **Zmiana na domyślną strefę**
- Zamiast `CKRecordZone.ID(zoneName: "TasksZone", ownerName: CKCurrentUserDefaultName)`
- Używamy teraz: `CKRecordZone.default().zoneID`

### 2. **Usunięcie tworzenia custom zone**
- Usunięta metoda `createCustomZone()`
- CloudKit automatycznie używa domyślnej strefy

### 3. **Uproszczenie tworzenia rekordów**
- Zamiast: `CKRecord.ID(recordName: id, zoneID: zoneID)`
- Teraz: `CKRecord.ID(recordName: id)`

### 4. **Zaktualizowana metoda zapytań**
- Używa `CKQueryOperation` z continuation dla async/await
- Obsługuje błędy na poziomie pojedynczych rekordów
- Limit wyników ustawiony na maksimum

## Korzyści
1. Brak problemów z queryable fields
2. Prostsze zarządzanie rekordami
3. Lepsza kompatybilność z CloudKit
4. Możliwość wykonywania standardowych zapytań

## Testowanie
1. Wyczyść dane lokalne i w iCloud
2. Dodaj nowe zadania
3. Sprawdź synchronizację
4. Wykonaj import/export

Problem z zapytaniami CloudKit powinien być rozwiązany.