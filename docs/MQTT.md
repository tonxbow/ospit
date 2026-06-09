# Dokumentasi MQTT OSPIT

## Status implementasi

OSPIT saat ini memakai MQTT untuk **telemetry publish**, bukan untuk remote control.

Yang sudah ada:

- koneksi ke broker MQTT
- publish payload JSON atau CSV
- subscribe topic kontrol output
- dukungan broker 1 dan broker 2

Yang **belum** ada:

- balasan status/ack ke topic khusus

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

- Subscribe kontrol:

  ```text
  subs/<nodeid>
  ```

Contoh:

- `mqttbrkr1_channel="ospit/001/"`
- `nodeid="ospit-demo"`

Hasil topic JSON:

```text
ospit/001/ospit-demo/data.json
```

Hasil topic subscribe:

```text
subs/ospit-demo
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

Kontrol output sekarang tersedia lewat topic:

```text
subs/<nodeid>
```

Contoh untuk `nodeid="ospit-demo"`:

```text
subs/ospit-demo
```

Output yang didukung:

- `valve_1`
- `valve_2`
- `valve_3`
- `load`
- `mpptracker`
- `web`
- `telnet`
- `ftp`

Format payload yang didukung:

1. Teks dengan spasi

   ```text
   turn_ON valve_1
   turn_OFF load
   status web
   ```

2. Teks dengan slash

   ```text
   turn_ON/valve_1
   turn_OFF/load
   status/web
   ```

3. JSON

   ```json
   {"command":"turn_ON","item":"valve_1"}
   ```

Contoh publish command:

```bash
mosquitto_pub -h broker.example.com -p 1883 -t 'subs/ospit-demo' -m 'turn_ON/valve_1'
```

## Troubleshooting singkat

| Gejala | Penyebab umum |
| --- | --- |
| Tidak ada data masuk | `mqtt_enabled=false` |
| Topic tidak sesuai harapan | `mqttbrkr1_channel` tidak diakhiri `/` |
| Broker kedua tidak aktif | `mqttbrkr2_host` kosong |
| Data CSV tidak berubah | `mqttbrkr1_json=true`, jadi mode CSV tidak dipakai |
| Kontrol MQTT tidak bekerja | Broker tidak mengirim ke topic `subs/<nodeid>` |
