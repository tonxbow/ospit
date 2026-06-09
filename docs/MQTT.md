# Dokumentasi MQTT OSPIT

## Status implementasi

OSPIT saat ini memakai MQTT untuk **telemetry publish**, bukan untuk remote control.

Yang sudah ada:

- koneksi ke broker MQTT
- publish payload JSON atau CSV
- dukungan broker 1 dan broker 2

Yang **belum** ada:

- subscribe topic command
- parsing command MQTT
- aksi `turn_ON` / `turn_OFF` dari pesan MQTT

## Lokasi konfigurasi

Edit `config.lua` pada bagian:

```lua
---- MQTT-Telemetry configuration
mqtt_enabled=true
mqttbrkr1_host="broker.example.com"
mqttbrkr1_port=1883
mqttbrkr1_user=""
mqttbrkr1_password=""
mqttbrkr1_channel="ospit/001/"
mqttbrkr1_close=true
mqttbrkr1_short=true
mqttbrkr1_json=true

mqttbrkr2_host=""
mqttbrkr2_port=1883
mqttbrkr2_user=""
mqttbrkr2_password=""
mqttbrkr2_channel=""
mqttbrkr2_close=true
mqttbrkr2_short=true
mqttbrkr2_json=true
```

## Arti setiap field

| Field | Arti |
| --- | --- |
| `mqtt_enabled` | Mengaktifkan telemetry MQTT |
| `mqttbrkr1_host` | Hostname/IP broker pertama |
| `mqttbrkr1_port` | Port broker, biasanya `1883` |
| `mqttbrkr1_user` | Username broker MQTT |
| `mqttbrkr1_password` | Password broker MQTT |
| `mqttbrkr1_channel` | Prefix topic |
| `mqttbrkr1_close` | Putus koneksi setelah publish |
| `mqttbrkr1_short` | Ambil CSV terbaru saja; diabaikan jika JSON |
| `mqttbrkr1_json` | `true` untuk JSON, `false` untuk CSV |
| `mqttbrkr2_*` | Konfigurasi broker kedua |

## Cara setting MQTT

1. Buka `config.lua`.
2. Set `mqtt_enabled=true`.
3. Isi host dan port broker:

   ```lua
   mqttbrkr1_host="broker.example.com"
   mqttbrkr1_port=1883
   ```

4. Jika broker memakai autentikasi, isi user dan password:

   ```lua
   mqttbrkr1_user="myuser"
   mqttbrkr1_password="mypassword"
   ```

5. Isi `mqttbrkr1_channel` dengan **akhiran slash** agar topic rapi:

   ```lua
   mqttbrkr1_channel="ospit/001/"
   ```

6. Tentukan format payload:

   ```lua
   mqttbrkr1_json=true
   ```

7. Reboot perangkat.

## Bentuk topic

Kode membentuk topic seperti ini:

- JSON:

  ```text
  <channel><nodeid>/data.json
  ```

- CSV:

  ```text
  <channel><nodeid>/csvlog
  ```

Contoh:

- `mqttbrkr1_channel="ospit/001/"`
- `nodeid="ospit-demo"`

Hasil topic JSON:

```text
ospit/001/ospit-demo/data.json
```

Jika `channel` tidak diakhiri `/`, topic akan menempel langsung. Contoh:

- `mqttbrkr1_channel="ospit/001"`
- `nodeid="ospit-demo"`

Hasilnya:

```text
ospit/001ospit-demo/data.json
```

## Interval publish

Telemetry dipublish tiap **65000 ms** dari `is.lua`, jadi sekitar **65 detik** sekali.

## Format payload JSON

Field utama yang dikirim oleh `telemetry.lua`:

```json
{
  "timeToShutdown": 7200,
  "openCircuitVoltage": 20.1,
  "airTemperature": 29.5,
  "heatsink_temperature": 31.2,
  "tankGauge": 80,
  "mppVoltage": 18.4,
  "batteryVoltage": 13.1,
  "batteryChargeEstimate": 87,
  "batteryHealthEstimate": 100,
  "batteryTemperature": 27.0,
  "freeRAM": 123456
}
```

Field tambahan sensor tanah akan muncul hanya jika nilainya valid, misalnya:

- `SoilHumiditySection1`
- `SoilTemperatureSection1`
- sampai section 4

## Cara cek dari komputer

Contoh subscribe:

```bash
mosquitto_sub -h broker.example.com -p 1883 -t 'ospit/001/ospit-demo/data.json' -v
```

Jika memakai CSV:

```bash
mosquitto_sub -h broker.example.com -p 1883 -t 'ospit/001/ospit-demo/csvlog' -v
```

## Kontrol MQTT

Saat ini **tidak bisa** mengontrol:

- `valve_1`
- `valve_2`
- `valve_3`
- `load`
- `mpptracker`
- service `web`, `telnet`, `ftp`

melalui MQTT, karena kode belum melakukan subscribe command topic.

## Kontrol yang tersedia sekarang

Gunakan web endpoint berikut setelah login:

```text
/control/turn_ON/valve_1
/control/turn_OFF/valve_1
/control/turn_ON/load
/control/turn_OFF/load
```

Item lain yang didukung:

- `valve_2`
- `valve_3`
- `mpptracker`
- `web`
- `telnet`
- `ftp`

## Troubleshooting singkat

| Gejala | Penyebab umum |
| --- | --- |
| Tidak ada data masuk | `mqtt_enabled=false` |
| Topic tidak sesuai harapan | `mqttbrkr1_channel` tidak diakhiri `/` |
| Broker kedua tidak aktif | `mqttbrkr2_host` kosong |
| Data CSV tidak berubah | `mqttbrkr1_json=true`, jadi mode CSV tidak dipakai |
| Tidak bisa kontrol via MQTT | Memang belum diimplementasikan di kode |
