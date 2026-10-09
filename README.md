# 🎶 Dangdut Music System — Roblox

Sistem musik sinkronisasi global untuk map dangdut. Semua pemain mendengarkan **lagu yang sama di menit yang sama**, tanpa selisih sedikitpun.

---

## 📁 Struktur File

```
src/
├── server/
│   └── init.server.luau     ← Server controller (master clock)
├── client/
│   └── init.client.luau     ← Client player + GUI dangdut
└── shared/
    └── Hello.luau           ← Shared config / constants
```

---

## ⚙️ Cara Kerja Sinkronisasi

### Server (Master Clock)
1. Saat server start, fetch playlist dari API via `HttpService:GetAsync()`
2. Simpan `songStartTime = os.clock()` saat lagu mulai
3. Setiap **5 detik**, broadcast `SyncState` ke semua client:
   ```
   position = os.clock() - songStartTime
   serverClock = os.clock()
   ```

### Client (Latency Compensation)
1. Saat menerima `SyncState`, hitung posisi yang seharusnya:
   ```lua
   corrected = state.position + (os.clock() - state.serverClock)
   ```
2. Jika selisih posisi > 0.3 detik → langsung `TimePosition = corrected`
3. Saat join baru → request state via `RemoteFunction:InvokeServer()`

---

## 🎛️ Remote Events

| Remote | Arah | Fungsi |
|--------|------|--------|
| `SyncState` | Server → Client | Broadcast posisi + lagu |
| `NextSong` | Client → Server | Skip ke lagu berikutnya |
| `PrevSong` | Client → Server | Kembali ke lagu sebelumnya |
| `GetState` | Client → Server (RF) | Request state saat join |
| `GetPlaylist` | Client → Server (RF) | Request full playlist |

---

## 🎨 GUI Features

- **Header emas** bisa di-drag untuk pindahkan window
- **EQ Bars** animasi warna-warni (20 bar)
- **Marquee** scroll title lagu
- **Progress bar** gradient pink-gold
- **Tombol PREV / NEXT** dengan hover & click animation  
- **Scroll wheel** di atas GUI = ubah volume
- **Tombol –/+** untuk minimize/maximize

---

## 🔧 Konfigurasi

Edit `src/shared/Hello.luau`:

| Konstanta | Default | Keterangan |
|-----------|---------|------------|
| `SYNC_INTERVAL` | `5` detik | Seberapa sering server sync |
| `SEEK_THRESHOLD` | `0.3` detik | Toleransi drift sebelum re-seek |
| `DEFAULT_VOLUME` | `0.6` | Volume awal (0–1) |

---

## ✅ Checklist Enable

Pastikan di **Game Settings**:
- [x] `HttpService` → Allow HTTP Requests: **ON**
- [x] `SoundService` → RespectFilteringEnabled: **true**
- [x] `Workspace` → FilteringEnabled: **true**