# Blokowanie Pasm (Band Locking) - Fibocom FM350-GL

## ⚠️ WAŻNE: Tylko dla Fibocom FM350-GL

Ta funkcjonalność jest **dedykowana wyłącznie dla modemu Fibocom FM350-GL**. Używa specyficznych komend AT tego modemu (AT+QNWPREFCFG).

## Co to jest blokowanie pasm?

Blokowanie pasm (band locking) pozwala na ograniczenie modemu do używania tylko wybranych częstotliwości (pasm). To może:
- ✅ Zwiększyć stabilność połączenia
- ✅ Przyspieszyć łączenie z siecią
- ✅ Zapobiec przełączaniu na wolniejsze pasma
- ✅ Zoptymalizować zasięg w danej lokalizacji
- ❌ Może ograniczyć zasięg jeśli zablokujesz złe pasma

## Pasma operatorów w Polsce

### Play
- **LTE:** B3 (1800 MHz), B7 (2600 MHz), B20 (800 MHz)
- **5G:** n78 (3500 MHz)

### Orange
- **LTE:** B3 (1800 MHz), B7 (2600 MHz), B20 (800 MHz)
- **5G:** n78 (3500 MHz)

### Plus
- **LTE:** B1 (2100 MHz), B3 (1800 MHz), B7 (2600 MHz), B20 (800 MHz)
- **5G:** n78 (3500 MHz)

### T-Mobile
- **LTE:** B3 (1800 MHz), B7 (2600 MHz), B20 (800 MHz)
- **5G:** n78 (3500 MHz)

## Konfiguracja przez LuCI (interfejs WWW)

1. Przejdź do **Sieć** → **Enhanced ATC**
2. Przewiń do sekcji **"Band Locking (Fibocom FM350-GL)"**
3. Zaznacz **"Enable Band Locking"**
4. **Opcja 1: Użyj presetu**
   - Wybierz swojego operatora z listy "Quick Presets"
   - Kliknij "Save & Apply"
5. **Opcja 2: Ręcznie**
   - Wpisz pasma LTE (np. `3,7,20`)
   - Wpisz pasma 5G SA (np. `78`)
   - Wpisz pasma 5G NSA (np. `78`)
   - Kliknij "Save & Apply"

## Konfiguracja przez wiersz poleceń

### Zobacz aktualne pasma

```bash
enhanced-atc-cli bands
```

Wyświetli:
```
=== Current Band Configuration (Fibocom FM350-GL) ===

LTE Bands:
  Locked to: B3, B7, B20

5G SA Bands:
  Locked to: n78

5G NSA Bands:
  Locked to: n78

=== Current Active Band ===
+QENG: "servingcell","NOCONN","LTE","FDD",260,01,2E4,3,1800...
```

### Zablokuj pasma

```bash
# Play/Orange/T-Mobile
enhanced-atc-cli band-lock --lte 3,7,20 --5g 78

# Plus (ma dodatkowo B1)
enhanced-atc-cli band-lock --lte 1,3,7,20 --5g 78

# Tylko LTE
enhanced-atc-cli band-lock --lte 3,7,20

# Tylko 5G
enhanced-atc-cli band-lock --5g 78
```

### Odblokuj wszystkie pasma (automatyczny wybór)

```bash
enhanced-atc-cli band-unlock
```

## Konfiguracja przez plik UCI

Edytuj `/etc/config/enhanced_atc`:

```bash
config interface 'wan'
    option enabled '1'
    option device '/dev/ttyUSB3'
    option apn 'internet'

    # Band locking
    option band_locking '1'
    option lte_bands '3,7,20'        # B3, B7, B20
    option nr5g_sa_bands '78'        # n78 (5G SA)
    option nr5g_nsa_bands '78'       # n78 (5G NSA)
```

Przeładuj sieć:
```bash
/etc/init.d/network reload
```

## Gotowe przykłady

W katalogu `examples/` znajdziesz:
- `play-polska-band-lock.conf` - Play
- `orange-polska-band-lock.conf` - Orange
- `plus-polska-band-lock.conf` - Plus

Skopiuj na router:
```bash
scp examples/play-polska-band-lock.conf root@192.168.1.1:/etc/config/enhanced_atc
ssh root@192.168.1.1
/etc/init.d/network reload
```

## Diagnostyka

### Sprawdź logi

```bash
# Zobacz czy band locking został zastosowany
tail -f /tmp/atc_logs/INFO.log | grep -i band

# Przykładowy output:
[2025-11-04 15:30:48] [INFO] Band locking enabled, applying configuration...
[2025-11-04 15:30:49] [INFO] Setting LTE bands: 3,7,20
[2025-11-04 15:30:50] [INFO] LTE bands configured: 3:7:20
[2025-11-04 15:30:51] [INFO] Setting 5G SA bands: 78
[2025-11-04 15:30:52] [INFO] 5G SA bands configured: 78
```

### Problemy z połączeniem po zablokowaniu pasm

Jeśli po zablokowaniu pasm nie możesz się połączyć:

1. **Sprawdź czy operator używa tych pasm w twojej lokalizacji**
   ```bash
   enhanced-atc-cli bands
   ```

2. **Odblokuj wszystkie pasma tymczasowo**
   ```bash
   enhanced-atc-cli band-unlock
   /etc/init.d/network reload
   ```

3. **Testuj pasma pojedynczo**
   ```bash
   # Najpierw tylko B3
   enhanced-atc-cli band-lock --lte 3

   # Potem dodaj B7
   enhanced-atc-cli band-lock --lte 3,7

   # Potem dodaj B20
   enhanced-atc-cli band-lock --lte 3,7,20
   ```

4. **Sprawdź dostępne pasma w okolicy**
   - Użyj aplikacji mobilnej (np. Network Cell Info)
   - Sprawdź z kartą SIM w telefonie jakie pasma widzisz

## Zaawansowane

### Wszystkie wspierane pasma FM350-GL

**LTE FDD:**
1, 2, 3, 4, 5, 7, 8, 12, 13, 14, 17, 18, 19, 20, 25, 26, 28, 29, 30, 32, 66, 71

**LTE TDD:**
34, 38, 39, 40, 41, 42, 43, 48

**5G NR:**
n1, n2, n3, n5, n7, n8, n12, n13, n14, n18, n20, n25, n26, n28, n29, n30,
n38, n40, n41, n48, n66, n70, n71, n77, n78, n79

### Bezpośrednie komendy AT

Możesz też użyć bezpośrednio komend AT (zaawansowane):

```bash
# Podłącz się do portu AT
screen /dev/ttyUSB3 115200

# Zobacz aktualne pasma LTE
AT+QNWPREFCFG="lte_band"

# Zablokuj do B3, B7, B20
AT+QNWPREFCFG="lte_band",3:7:20

# Zablokuj 5G do n78
AT+QNWPREFCFG="nr5g_band",78
AT+QNWPREFCFG="nsa_nr5g_band",78

# Odblokuj wszystko (automatic)
AT+QNWPREFCFG="lte_band",0
AT+QNWPREFCFG="nr5g_band",0
AT+QNWPREFCFG="nsa_nr5g_band",0
```

Wyjdź z screen: `Ctrl+A`, potem `K`, potem `Y`

## FAQ

**Q: Czy mogę zablokować pasma których operator nie używa?**
A: Nie zalecane. Modem się nie połączy jeśli zablokujesz do niedostępnych pasm.

**Q: Czy band locking zużywa więcej baterii?**
A: Nie, wręcz przeciwnie - modem nie marnuje czasu na skanowanie innych pasm.

**Q: Czy muszę restartować modem po zmianie pasm?**
A: Nie, wystarczy `/etc/init.d/network reload`. Modem zastosuje nowe ustawienia.

**Q: Co jeśli chcę używać tylko 5G?**
A: Ustaw `preferred_mode` na `5g` i zablokuj tylko pasma 5G. Ale lepiej zostawić `auto` z blokowaniem pasm.

**Q: Czy to zadziała z innymi modemami?**
A: **NIE!** To rozwiązanie jest dedykowane **tylko dla Fibocom FM350-GL**. Inne modemy używają innych komend AT.

## Bezpieczeństwo

- ⚠️ Niewłaściwa konfiguracja może zablokować połączenie
- ⚠️ Zawsze testuj najpierw na jednym paśmie
- ⚠️ Zachowaj działającą konfigurację jako backup
- ✅ Możesz zawsze wrócić do auto: `enhanced-atc-cli band-unlock`

## Wsparcie

- Problemy? Zgłoś na: https://github.com/Hexrox/enhanced-atc-fm350/issues
- Dołącz logi: `/tmp/atc_logs/INFO.log`
- Podaj output: `enhanced-atc-cli bands`
