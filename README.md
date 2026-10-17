<div align="center">

# 👑 Royal Dream

<p>
  <img src="https://img.shields.io/badge/ROBLOX-ROYAL%20DREAM-0A0D18?style=for-the-badge&logo=roblox&logoColor=white" alt="Roblox Royal Dream">
  <img src="https://img.shields.io/badge/THEME-MONOCHROME%20LUXURY-111827?style=for-the-badge" alt="Theme: Monochrome Luxury">
  <img src="https://img.shields.io/badge/LANGUAGE-Luau-2563EB?style=for-the-badge" alt="Language: Luau">
  <img src="https://img.shields.io/badge/WORKFLOW-Rojo-7C3AED?style=for-the-badge" alt="Workflow: Rojo">
</p>

<p><em>Pengalaman roleplay, musik global tersinkronisasi, dan nongkrong eksklusif di Roblox dengan antarmuka monokrom modern dan animasi gradasi reaktif terhadap musik.</em></p>

</div>

<div align="center">

<img src="https://img.shields.io/badge/STATUS-PENGEMBANGAN%20AKTIF-0D9488?style=for-the-badge" alt="Status: Pengembangan Aktif">

</div>

> [!NOTE]
> Proyek ini dikelola secara modern menggunakan **Rojo**, ditulis murni dalam bahasa **Luau**, dan dipetakan secara langsung ke Roblox Studio. Seluruh antarmuka grafis (GUI) mengikuti standar visual monokrom premium dengan sistem animasi gradasi terpusat.

---

## 📁 Struktur Direktori Proyek

```text
src/
├── client/                          # StarterPlayerScripts
│   ├── ChatTagClient.client.luau    # Tag chat kustom
│   ├── DeviceDetectorClient.client.luau # Deteksi perangkat input
│   └── UnifiedToolbarUI.client.luau # Bilah alat terpadu & GUI perintah VIP
│
├── server/                          # ServerScriptService
│   ├── CarryServer.server.luau      # Logika server sistem carry / gendong
│   ├── FriendServer.server.luau     # Integrasi sistem pertemanan
│   ├── MusicFetcher.server.luau     # Fetch playlist musik dari API eksternal
│   ├── DonationBroadcastHandler/    # Siaran pengumuman donasi ke seluruh server
│   ├── DonationServerHandler/       # Pemrosesan pembelian Developer Product donasi
│   ├── GamePass/GamePassHandler/    # Validasi & pemberian manfaat Game Pass
│   ├── GiveSystem/                  # Sistem pemberian role, title, dan item
│   ├── MessageSystem/MessageServer/ # Sistem broadcast pesan global
│   ├── MusicServer/MusicSystem/     # Orkestrasi pemutaran, antrean & voting skip lagu
│   ├── OverheadSystem/              # UI overhead rank, status, dan title di atas kepala
│   ├── Setting/                     # Konfigurasi server & animasi
│   ├── VIPBanefit/                  # Fasilitas dan benefit pemain VIP
│   └── VIPZoneServer/               # Pintu masuk dan pembatas area khusus VIP
│
├── server_storage/                  # ServerStorage
│   └── Modules/
│       ├── MusicPlaylistBridge.luau # Penghubung data playlist server
│       ├── RoleSystem.luau          # Manajemen peran & hierarki izin
│       └── VIPZoneModule.luau       # Logika proteksi zona VIP
│
├── shared/                          # ReplicatedStorage
│   ├── AutoScaleSystem/             # Sistem penskalaan UI responsif multi-resolusi
│   ├── BridgeNet/                   # Jaringan komunikasi remote berkinerja tinggi
│   ├── ContextModule/               # Modul manajemen konteks UI
│   ├── GiveModule/                  # Modul bersama transaksi give
│   ├── Icon/                        # TopbarPlus v3 terintegrasi
│   ├── Modules/
│   │   ├── AdminConfig.luau         # Konfigurasi panel admin
│   │   ├── BugReportConfig.luau     # Konfigurasi laporan bug
│   │   ├── CarryConfig.luau         # Konfigurasi jarak & animasi gendong
│   │   ├── FriendConfig.luau        # Konfigurasi interaksi pertemanan
│   │   ├── MenuConfig.luau          # Konfigurasi halaman menu utama
│   │   ├── MusicModule.luau         # Konstanta & struktur data sistem musik
│   │   ├── MusicStorageHandler.luau # Penyimpanan lokal status musik
│   │   ├── NotifModule.luau         # Sistem notifikasi toast terpusat
│   │   ├── PanelAnimationController.luau # Controller animasi buka/tutup panel
│   │   ├── ThemeModule.luau         # Sistem tema monokrom & beat-reactive gradient
│   │   └── CountryService/          # Deteksi bendera & negara pemain
│   └── Emotes/                      # Konfigurasi animasi dansa & emote
│
└── starter_gui/                     # StarterGui
    ├── AdminGUI/                    # Panel admin & pengelola title
    ├── CarryGui/                    # Prompt interaksi & indikator gendong
    ├── CustomInventory/             # Backpack & inventaris kustom
    ├── DonationDisplayGUI/          # Billboard peringkat donatur teratas
    ├── DonationGUI/                 # Antarmuka donasi & penulisan pesan siaran
    ├── EmoteGui/                    # Menu emote dengan pencarian & kontrol kecepatan
    ├── LoadingScreen/               # Layar pemuatan sinematik layar penuh
    └── MenuGUI/                     # Halaman menu (Musik, Profil, Pengaturan, Toko, Lapor)
```

---
## 🎵 Sistem Musik Sinkronisasi Global

Semua pemain dalam server mendengarkan **lagu yang sama pada detik yang sama secara sinkron**.

1. **Pengambilan Playlist**: `MusicFetcher` mengambil playlist terverifikasi dari endpoint API eksternal.
2. **Sinkronisasi Waktu Nyata**: `MusicPlaybackManager` mengontrol *time position* dan mengoreksi latensi jaringan setiap pemain.
3. **Voting Skip & Antrean**: Pemain dapat mengajukan lagu dan memberikan suara untuk melewati lagu yang sedang diputar.
4. **Visualizer & Kontrol**: Menu musik klien menyediakan kontrol volume lokal, bilah progres lagu, dan tampilan daftar putar.

---

## 💎 Fitur & Sistem Permainan Lainnya

- **VIP Commands & Unified Toolbar**: Bilah alat terintegrasi untuk mengakses fitur eksklusif VIP (terbang, tongkat cahaya, topi, kecepatan, dan efek visual).
- **Donation & Broadcast System**: Pembelian Developer Product dengan border bergradasi aktif serta pengumuman global nama dan pesan donatur ke seluruh server.
- **Emote & Synchronized Dance**: Menu ratusan gerakan tarian dengan pengaturan kecepatan (0.5x - 2.0x), pencarian instan, dan sinkronisasi gerakan antar pemain.
- **Carry System**: Fitur menggendong pemain lain dengan sistem izin (*permission prompt*) dan penyesuaian fisika ragdoll yang aman.
- **Custom Inventory**: Pengganti backpack bawaan Roblox dengan penataan slot modern bertema monokrom.

---

## ⚙️ Panduan Setup & Eksekusi

### Prasyarat
- [Aftman](https://github.com/LPGhatguy/aftman) — Pengelola toolchain.
- [Rojo](https://rojo.space/) — Alat sinkronisasi file sistem dengan Roblox Studio.
- Roblox Studio dengan pengaturan **Allow HTTP Requests** diaktifkan.

### Menjalankan Sinkronisasi (Rojo)
```bash
# Instalasi toolchain
aftman install

# Memulai server sinkronisasi
rojo serve default.project.json
```
Di Roblox Studio, buka plugin Rojo dan klik **Connect**.

### Membangun File Proyek (.rbxlx)
```bash
rojo build default.project.json --output RoyalDream.rbxlx
```

---

<div align="center">

<sub>Royal Dream · Dikembangkan dengan standar Luau modern & Rojo workflow</sub>

</div>
