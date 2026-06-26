# Dokumentasi OSPIT

OSPIT adalah firmware Lua untuk sistem irigasi bertenaga surya berbasis ESP32/NodeMCU. Program ini mengatur pembacaan sensor, MPPT, irigasi otomatis, web panel, Telnet, FTP, dan pengiriman telemetry ke MQTT.

## File penting

| File | Fungsi |
| --- | --- |
| `init.lua` | Entry point; menjalankan file `S*.lua`, lalu `is.lua` |
| `config.lua` | Konfigurasi aktif perangkat |
| `config_default.lua` | Template konfigurasi default |
| `S10config.lua` | Loader, parser, penyimpan, dan reset konfigurasi |
| `S50wifi.lua` | Setup Wi-Fi Station / AP |
| `is.lua` | Inisialisasi runtime utama, timer, sensor, MPPT, MQTT |
| `telemetry.lua` | Publish telemetry ke MQTT |
| `TCP_80_web.lua` | HTTP server dan Basic Auth |
| `WEB_config.lua` | Form konfigurasi lewat web |
| `WEB_control.lua` | Panel kontrol sistem |
| `WEB_icontrol.lua` | Panel kontrol irigasi |
| `TCP_23_telnet.lua` | Telnet login dan shell |

## Alur kerja singkat

1. `init.lua` menunggu 5 detik lalu menjalankan seluruh file `S*.lua`.
2. `S10config.lua` memastikan `config.lua` ada, memuat konfigurasi, dan bisa reset config dari `config_default.lua`.
3. `S50wifi.lua` mengaktifkan Wi-Fi sesuai `wlanmode`.
4. `is.lua` menjalankan timer untuk sensor, MPPT, irigasi, dan MQTT telemetry.

## Akses perangkat

### Web

HTTP server memakai Basic Auth.

- **Username**: `root` atau `lua`
- **Password**: nilai `webkey` di `config.lua`

Halaman utama yang tersedia:

- `/index` atau root: status sistem
- `/config`: ubah konfigurasi
- `/control`: kontrol output dan service
- `/icontrol`: kontrol irigasi
- `/time`: halaman waktu
- `/help.html`: manual lokal
- `/reboot`: reboot perangkat

### Telnet

Server Telnet ada di port `23`.

- Login `root` memberi shell internal
- Login `lua` memberi akses Lua console
- Password tetap memakai `webkey`

## Konfigurasi Wi-Fi

Konfigurasi ada di `config.lua`.

- `wlanmode=1`: Station
- `wlanmode=2`: Access Point
- `wlanmode=3`: Station + Access Point
- `wlanmode=4`: Wi-Fi off

Field penting:

- Station: `sta_ssid`, `sta_pwd`, `sta_hostname`
- Access Point: `ap_ssid`, `ap_pwd`, `ap_ip`, `ap_nmask`, `ap_gw`, `ap_dns`

## MQTT telemetry

OSPIT mengirim telemetry ke MQTT dan juga menerima command kontrol via subscribe topic.

Detail lengkap ada di [`docs/MQTT.md`](docs/MQTT.md).

Ringkasnya:

- Timer publish ada di `is.lua` setiap **65000 ms** (sekitar 65 detik)
- Konfigurasi broker ada di `config.lua`
- Bisa memakai hingga 2 broker
- Topic dibentuk dari:
  - JSON: `mqttbrkrX_channel .. nodeid .. "/data.json"`
  - CSV: `mqttbrkrX_channel .. nodeid .. "/csvlog"`
- Topic subscribe kontrol: `subs/<nodeid>`

> **Penting:** kode menggabungkan `channel` dan `nodeid` secara langsung. Jika ingin topic bertingkat normal, isi `mqttbrkr1_channel` dengan akhiran `/`, misalnya `ospit/001/`.

## Kontrol perangkat

### Kontrol yang tersedia

Kontrol tersedia lewat web, bukan lewat MQTT.

Route utama:

- `/control/turn_ON/<item>`
- `/control/turn_OFF/<item>`

`<item>` yang didukung oleh `WEB_control.lua`:

- `valve_1`
- `valve_2`
- `valve_3`
- `load`
- `mpptracker`
- `web`
- `telnet`
- `ftp`

Halaman `/icontrol` dipakai untuk kontrol irigasi yang lebih spesifik.

### Status kontrol MQTT

Kontrol via MQTT sekarang aktif melalui topic `subs/<nodeid>`.

Payload yang didukung:

- `turn_ON valve_1`
- `turn_OFF/load`
- `{"command":"turn_ON","item":"load"}`

## Irigasi dan sensor

Konfigurasi utama:

- `i_nbld`: aktif/nonaktif irigasi otomatis
- `i_lvl1` s.d. `i_lvl4`: target kelembaban tiap section
- `i_vlv_opn`: durasi maksimum irigasi per section
- `i_hr`: jam mulai irigasi
- `i_tanksens`: sensor level tangki

Pembacaan sensor tanah memakai Modbus RTU. Mapping default yang dipakai dokumentasi bawaan:

- Node ID 1 -> Valve 1
- Node ID 2 -> Valve 2
- Node ID 3 -> Valve 3
- Node ID 4 -> Pump / Valve 4

## Menyimpan konfigurasi

Ada dua cara:

1. Edit `config.lua` langsung.
2. Buka `/config`, ubah nilai, submit, lalu reboot.

Perilaku penyimpanan:

- `WEB_config.lua` memanggil `config.update()`
- file lama dipindah menjadi `config_old.lua`
- konfigurasi baru ditulis kembali ke `config.lua`

## Reset konfigurasi

`S10config.lua` punya fitur reset config:

- jika GPIO0 berada pada level HIGH saat boot
- `config.lua` dibackup menjadi `config_broken.lua`
- lalu `config_default.lua` disalin menjadi `config.lua`

## Catatan penting

- Password web dan Telnet memakai `webkey`
- Jika `encrypted_webkey` tidak aktif, password dipakai apa adanya
- `mqttbrkrX_short` hanya relevan untuk mode CSV
- jika `mqttbrkrX_json=true`, payload dikirim sebagai JSON
- field sensor tanah di JSON hanya muncul jika nilainya valid
# ospit
