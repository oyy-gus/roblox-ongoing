<div align="center">

# 🎮 Roblox Ongoing

<p>
  <img src="https://img.shields.io/badge/ROBLOX-ONGOING-111827?style=for-the-badge&logo=roblox&logoColor=white" alt="Roblox Ongoing">
  <img src="https://img.shields.io/badge/LANGUAGE-Luau-2563EB?style=for-the-badge" alt="Language: Luau">
  <img src="https://img.shields.io/badge/WORKFLOW-Rojo-7C3AED?style=for-the-badge" alt="Workflow: Rojo">
</p>

<p><em>Proyek map Roblox dengan sistem musik global dan berbagai fitur terintegrasi.</em></p>

</div>

<div align="center">

<img src="https://img.shields.io/badge/⚠️%20PERINGATAN-MASIH%20DALAM%20PENGEMBANGAN-DC2626?style=for-the-badge" alt="Peringatan: masih dalam pengembangan">

</div>

> [!WARNING]
> 🚨 **PERINGATAN — PROYEK MASIH DALAM TAHAP PENGEMBANGAN**
>
> 🔴 Proyek ini masih aktif dikembangkan (*Work in Progress*). Beberapa fitur mungkin belum selesai, belum stabil, atau masih mengalami perubahan. Bug, error, masalah performa, maupun perilaku yang tidak terduga dapat terjadi sewaktu-waktu.
>
> ⚠️ **Gunakan dengan risiko sendiri.** Belum semua sistem dijamin berfungsi dengan sempurna. Perbaikan, pengujian, dan penyempurnaan akan dilakukan secara bertahap seiring perkembangan proyek.

Proyek Roblox berbasis **Rojo** untuk map lagu dengan berbagai sistem terintegrasi. Semua skrip dikelola via Rojo, ditulis dalam **Luau**, dan dipetakan ke Roblox Studio secara langsung.

---

## 📁 Struktur Proyek

![Struktur Proyek](https://img.shields.io/badge/PROJECT-STRUCTURE-0F766E?style=flat-square)

```text
src/
├── client/                          # StarterPlayerScripts
│   ├── ChatTagClient.client.luau
│   ├── DeviceDetectorClient.client.luau
│   └── UnifiedToolbarUI.client.luau
│
├── server/                          # ServerScriptService
│   ├── CarryServer.server.luau
│   ├── FriendServer.server.luau
│   ├── MusicFetcher.server.luau
│   ├── DonationBroadcastHandler/
│   ├── DonationServerHandler/
│   ├── GamePass/GamePassHandler/
│   ├── GiveSystem/
│   ├── MessageSystem/MessageServer/
│   ├── MusicServer/MusicSystem/
│   ├── OverheadSystem/
│   ├── Setting/
│   ├── VIPBanefit/
│   └── VIPZoneServer/
│
├── server_storage/                  # ServerStorage
│   └── Modules/
│       ├── MusicPlaylistBridge.luau
│       ├── RoleSystem.luau
│       └── VIPZoneModule.luau
│
├── shared/                          # ReplicatedStorage
│   ├── AutoScaleSystem/
│   ├── BridgeNet/
│   ├── ContextModule/
│   ├── GiveModule/
│   ├── Icon/                        # TopbarPlus v3
│   ├── Modules/
│   │   ├── AdminConfig.luau
│   │   ├── BugReportConfig.luau
│   │   ├── CarryConfig.luau
│   │   ├── FriendConfig.luau
│   │   ├── MenuConfig.luau
│   │   ├── MusicModule.luau
│   │   ├── MusicStorageHandler.luau
│   │   ├── NotifModule.luau
│   │   ├── ThemeModule.luau
│   │   └── CountryService/
│
└── starter_gui/                     # StarterGui
    ├── AdminGUI/
    ├── CarryGui/
    ├── CustomInventory/
    ├── DonationDisplayGUI/
    ├── DonationGUI/
    ├── EmoteGui/
    ├── LoadingScreen/
    └── MenuGUI/
```

---

## 🎵 Sistem Musik

![Global Music](https://img.shields.io/badge/GLOBAL-MUSIC-7C3AED?style=flat-square)

Sistem musik sinkronisasi global — semua pemain mendengarkan **lagu yang sama pada waktu pemutaran yang sama**.

### Cara Kerja

1. **Server** mengambil (*fetch*) playlist dari API menggunakan `HttpService:GetAsync()`.
2. `MusicPlaylistBridge` di `ServerStorage` menyediakan data playlist untuk server.
3. `MusicServer/MusicSystem` mengelola pemutaran, antrean, voting skip, dan validasi.
4. Status musik (*music state*) dikirim ke semua klien secara berkala.
5. **Klien** menerima status musik, mengompensasi latensi, dan memperbarui GUI musik.

### Komponen Musik

| File | Lokasi | Fungsi |
|---|---|---|
| `MusicFetcher.server.luau` | `ServerScriptService` | Mengambil dan menginisialisasi playlist dari API |
| `MusicSystem/init.server.luau` | `ServerScriptService` | Orkestrasi sistem musik server |
| `MusicPlaybackManager.luau` | `ServerScriptService` | Mengelola logika pemutaran lagu |
| `MusicQueueManager.luau` | `ServerScriptService` | Mengelola antrean lagu |
| `MusicSkipVoteManager.luau` | `ServerScriptService` | Mengelola voting skip |
| `MusicPlaylistBridge.luau` | `ServerStorage` | Penghubung pengambilan playlist |
| `MusicModule.luau` | `ReplicatedStorage` | Konfigurasi dan konstanta bersama |
| `MusicClient.client.luau` | `StarterGui/MenuGUI` | GUI musik di sisi klien |

---

## 🛠️ Sistem Lainnya

![Features](https://img.shields.io/badge/FEATURES-INTEGRATED-2563EB?style=flat-square)

| Sistem | Lokasi | Keterangan |
|---|---|---|
| **Admin GUI** | `StarterGui/AdminGUI` | Panel admin, broadcast, dan pengelolaan title |
| **Carry System** | `StarterGui/CarryGui` + server | Sistem mengangkat pemain |
| **Donation** | `StarterGui/DonationGUI` + server | Tampilan dan handler donasi |
| **Emote** | `StarterGui/EmoteGui` | Sistem emote karakter |
| **GamePass** | `ServerScriptService/GamePass` | Handler Game Pass dan manfaatnya |
| **Give System** | `ServerScriptService/GiveSystem` | Pemberian role dan title |
| **Loading Screen** | `StarterGui/LoadingScreen` | Layar loading kustom |
| **Menu GUI** | `StarterGui/MenuGUI` | Menu utama menggunakan TopbarPlus |
| **Message System** | `ServerScriptService/MessageSystem` | Sistem pesan server kustom |
| **Overhead System** | `ServerScriptService/OverheadSystem` | Tag nama dan UI overhead |
| **Role System** | `ServerStorage/Modules` | Manajemen role pemain |
| **Setting** | `ServerScriptService/Setting` | Konfigurasi dan animasi server |
| **VIP Zone** | Server dan `server_storage` | Zona khusus VIP |

---

## 🌐 Topbar & UI

![Interface](https://img.shields.io/badge/INTERFACE-RESPONSIVE-DB2777?style=flat-square)

- Menggunakan **TopbarPlus v3** yang tersedia di `ReplicatedStorage > Icon`.
- Satu ikon topbar digunakan untuk membuka menu utama.
- Menu utama menyediakan navigasi ke Musik, Profil, Pengaturan, Game Pass, dan fitur lainnya.
- UI dirancang responsif menggunakan `AutoScaleSystem` untuk berbagai ukuran layar.

---

## ⚙️ Konfigurasi & Setup

![Setup](https://img.shields.io/badge/SETUP-GUIDE-0D9488?style=flat-square)

### Prasyarat

- [Rojo](https://rojo.space/) — untuk sinkronisasi file dengan Roblox Studio.
- Roblox Studio dengan **Allow HTTP Requests** diaktifkan.

### Menjalankan Rojo

Jalankan perintah berikut dari direktori proyek:

```bash
rojo serve
```

Kemudian, di Roblox Studio, gunakan plugin Rojo untuk memilih **Connect**.

### Pengaturan Game yang Diperlukan

- `HttpService` → **Allow HTTP Requests**: aktif.
- `SoundService` → `RespectFilteringEnabled`: `true`.
- `Workspace` → `FilteringEnabled`: catatan: pengaturan ini sudah diterapkan secara otomatis oleh Roblox pada pengalaman modern dan mungkin tidak tersedia sebagai opsi yang dapat diubah.

---

## 🔧 Tooling

![Toolchain](https://img.shields.io/badge/TOOLCHAIN-READY-4F46E5?style=flat-square)

| Tool | Versi | Fungsi |
|---|---|---|
| [Rojo](https://rojo.space/) | Lihat `aftman.toml` | Sinkronisasi berkas proyek dengan Roblox Studio |
| [Aftman](https://github.com/LPGhatguy/aftman) | — | Pengelola toolchain |

Instal toolchain dengan perintah:

```bash
aftman install
```

---

## 📡 API Musik

![API](https://img.shields.io/badge/PLAYLIST-API-F59E0B?style=flat-square)

Playlist diambil dari endpoint berikut:

```text
https://oyy-gus.github.io/api/v2/roblox/music/playlist.json
```

---

## 📝 Lisensi

![License](https://img.shields.io/badge/LICENSE-PERSONAL-6B7280?style=flat-square)

Proyek pribadi — tidak untuk didistribusikan.

---

<div align="center">

**Dibangun dengan**  
![Roblox](https://img.shields.io/badge/Roblox-111827?style=flat-square&logo=roblox&logoColor=white)
![Luau](https://img.shields.io/badge/Luau-2563EB?style=flat-square)
![Rojo](https://img.shields.io/badge/Rojo-7C3AED?style=flat-square)

<sub>Roblox Ongoing · Proyek dalam pengembangan aktif</sub>

</div>
