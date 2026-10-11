# 🎮 Roblox Ongoing — Map Dangdut

Proyek Roblox berbasis **Rojo** untuk map dangdut dengan berbagai sistem terintegrasi.  
Semua skrip dikelola via Rojo, ditulis dalam **Luau**, dan dipetakan ke Roblox Studio secara langsung.

---

## 📁 Struktur Proyek

```
src/
├── client/                          ← StarterPlayerScripts
│   ├── ChatTagClient.client.luau
│   ├── DeviceDetectorClient.client.luau
│   ├── GLightsClient.client.luau
│   └── UnifiedToolbarUI.client.luau
│
├── server/                          ← ServerScriptService
│   ├── CarryServer.server.luau
│   ├── FriendServer.server.luau
│   ├── GLightsServer.server.luau
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
├── server_storage/                  ← ServerStorage
│   └── Modules/
│       ├── MusicPlaylistBridge.luau
│       ├── RoleSystem.luau
│       └── VIPZoneModule.luau
│
├── shared/                          ← ReplicatedStorage
│   ├── Bridges.luau
│   ├── FreecamConfig.luau
│   ├── AutoScaleSystem/
│   ├── BridgeNet/
│   ├── ContextModule/
│   ├── GiveModule/
│   ├── Icon/                        ← TopbarPlus v3
│   └── Modules/
│       ├── AdminConfig.luau
│       ├── BugReportConfig.luau
│       ├── CarryConfig.luau
│       ├── FriendConfig.luau
│       ├── MenuConfig.luau
│       ├── MusicModule.luau
│       ├── MusicStorageHandler.luau
│       ├── NotifModule.luau
│       ├── ThemeModule.luau
│       └── CountryService/
│
└── starter_gui/                     ← StarterGui
    ├── AdminGUI/
    ├── CarryGui/
    ├── CustomInventory/
    ├── DonationDisplayGUI/
    ├── DonationGUI/
    ├── EmoteGui/
    ├── LoadingScreen/
    ├── MenuGUI/
    └── MobileFreecam/
```

---

## 🎵 Sistem Musik

Sistem musik sinkronisasi global — semua pemain mendengarkan **lagu yang sama di menit yang sama**.

### Cara Kerja
1. **Server** fetch playlist dari API via `HttpService:GetAsync()`
2. `MusicPlaylistBridge` (ServerStorage) menyediakan data playlist ke server
3. `MusicServer/MusicSystem` mengelola pemutaran, antrean, skip vote, dan validasi
4. Setiap beberapa detik, state musik di-broadcast ke semua client
5. **Client** menerima state, kompensasi latency, dan update GUI musik

### Komponen Musik
| File | Lokasi | Fungsi |
|------|--------|--------|
| `MusicFetcher.server.luau` | ServerScriptService | Fetch & init playlist dari API |
| `MusicSystem/init.server.luau` | ServerScriptService | Orkestrasi musik server |
| `MusicPlaybackManager.luau` | ServerScriptService | Logika pemutaran lagu |
| `MusicQueueManager.luau` | ServerScriptService | Manajemen antrean lagu |
| `MusicSkipVoteManager.luau` | ServerScriptService | Sistem voting skip |
| `MusicPlaylistBridge.luau` | ServerStorage | Bridge fetch playlist |
| `MusicModule.luau` | ReplicatedStorage | Shared config & constants |
| `MusicClient.client.luau` | StarterGui/MenuGUI | GUI musik client |

---

## 🛠️ Sistem Lainnya

| Sistem | Lokasi | Keterangan |
|--------|--------|------------|
| **Admin GUI** | StarterGui/AdminGUI | Panel admin, broadcast, title management |
| **Carry System** | StarterGui/CarryGui + server | Sistem angkat pemain |
| **Donation** | StarterGui/DonationGUI + server | Tampilan & handler donasi |
| **Emote** | StarterGui/EmoteGui | Sistem emote karakter |
| **GamePass** | ServerScriptService/GamePass | Handler game pass & manfaat |
| **Give System** | ServerScriptService/GiveSystem | Pemberian role & title |
| **GLights** | client + server | Sistem efek lampu dinamis |
| **Loading Screen** | StarterGui/LoadingScreen | Layar loading kustom |
| **Menu GUI** | StarterGui/MenuGUI | Menu utama (TopbarPlus) |
| **Message System** | ServerScriptService/MessageSystem | Pesan server custom |
| **Overhead System** | ServerScriptService/OverheadSystem | Tag nama & overhead UI |
| **Role System** | ServerStorage/Modules | Manajemen role pemain |
| **Setting** | ServerScriptService/Setting | Config & animasi server |
| **VIP Zone** | server + server_storage | Zona khusus VIP |

---

## 🌐 Topbar & UI

- Menggunakan **TopbarPlus v3** (`ReplicatedStorage > Icon`)
- Satu ikon topbar → Menu utama
- Menu berisi: Musik, Profil, Pengaturan, GamePass, dll.
- UI responsif dengan `AutoScaleSystem` untuk berbagai ukuran layar

---

## ⚙️ Konfigurasi & Setup

### Prasyarat
- [Rojo](https://rojo.space/) — untuk sync file ke Roblox Studio
- Roblox Studio dengan **Allow HTTP Requests** diaktifkan

### Menjalankan dengan Rojo
```bash
rojo serve
```
Lalu di Roblox Studio: **Rojo → Connect**

### Game Settings yang Diperlukan
- ✅ `HttpService` → Allow HTTP Requests: **ON**
- ✅ `SoundService` → RespectFilteringEnabled: **true**
- ✅ `Workspace` → FilteringEnabled: **true**

---

## 🔧 Tooling

| Tool | Versi | Fungsi |
|------|-------|--------|
| [Rojo](https://rojo.space/) | lihat `aftman.toml` | Sync file ↔ Roblox Studio |
| [Aftman](https://github.com/LPGhatguy/aftman) | — | Toolchain manager |

Instalasi toolchain:
```bash
aftman install
```

---

## 📡 API Musik

Playlist diambil dari:
```
https://oyy-gus.github.io/api/v2/roblox/music/playlist.json
```

---

## 📝 Lisensi

Proyek pribadi — tidak untuk didistribusikan.