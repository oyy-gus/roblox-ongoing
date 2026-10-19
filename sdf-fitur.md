# 📋 Dokumentasi Fitur Sistem (sdf.md)

Dokumen ini merangkum seluruh fitur, arsitektur modul, dan fungsionalitas sistem yang diimplementasikan dalam skrip [sdf.md](file:///c:/Users/RDP/Desktop/roblox-ongoing/sdf.md) (~191 modul Luau hasil dekompilasi klien).

---

## 📑 Daftar Isi
1. [Sistem Command Bar & Smart Suggestion](#1-sistem-command-bar--smart-suggestion)
2. [Sistem Musik Global & Visualizer Reaktif](#2-sistem-musik-global--visualizer-reaktif)
3. [Sistem Tarian & Emote](#3-sistem-tarian--emote)
4. [Sistem Interaksi Pemain & Inspeksi Outfit](#4-sistem-interaksi-pemain--inspeksi-outfit)
5. [Fasilitas VIP & Efek Visual Karakter](#5-fasilitas-vip--efek-visual-karakter)
6. [Sistem Toolbar & Inventaris Kustom](#6-sistem-toolbar--inventaris-kustom)
7. [Sistem Pergerakan Karakter & Multi-Platform Controller](#7-sistem-pergerakan-karakter--multi-platform-controller)
8. [Panel Pengaturan Komprehensif (Settings & Preferences)](#8-panel-pengaturan-komprehensif-settings--preferences)
9. [Sistem Kamera Sinematik & Integrasi Virtual Reality (VR)](#9-sistem-kamera-sinematik--integrasi-virtual-reality-vr)
10. [Sistem Overhead Rank & Display Names](#10-sistem-overhead-rank--display-names)
11. [Sistem Kendaraan & Kemudi Otomatis (Vehicle & AutoPilot)](#11-sistem-kendaraan--kemudi-otomatis-vehicle--autopilot)
12. [Sistem Zona Wilayah & Pencahayaan Atmosferik](#12-sistem-zona-wilayah--pencahayaan-atmosferik)
13. [Sistem Notifikasi & Dialog Modal (UI Feedback)](#13-sistem-notifikasi--dialog-modal-ui-feedback)
14. [Arsitektur Komunikasi Remote (callProvider)](#14-arsitektur-komunikasi-remote-callprovider)

---

## 1. Sistem Command Bar & Smart Suggestion
Sistem eksekusi perintah modern dengan antarmuka interaktif dan rekomendasi parameter pintar:
- **Interactive Draggable Command Bar**:
  - UI command bar mengambang yang dapat digeser di layar (`DragBar`).
  - Animasi transisi buka/tutup halus menggunakan `TweenService` pada properti `UIScale`.
  - Aksesibilitas controller/gamepad melalui penekanan tombol `ButtonR2`.
  - Input fokus otomatis (`CaptureFocus`) dengan awalan `/`.
- **Command Tokenizer & Lexer**:
  - Memecah teks masukan menjadi token: `PREFIX` (`/`, `!`, `;`, `:`), `COMMAND`, `NUMBER`, `STRING`, dan `SEPARATOR`.
- **Sistem Rekomendasi Pintar (Auto-suggestion)**:
  - **Penyorotan Parameter Aktif**: Menyorot parameter yang sedang diketik (`<param>` highlighting) lengkap dengan deskripsi bantuannya.
  - **Pencarian Warna (Color Finder)**: Menampilkan rekomendasi daftar warna Roblox (`BrickColor` 1 s.d. 1032) dengan nama, nomor ID, dan kotak sampel warna asli.
  - **Pencarian Pemain (Player Finder)**: Algoritma pencocokan kemiripan string (*fuzzy string similarity*) terhadap `Name` dan `DisplayName` pemain aktif.
  - **Pencarian Game Pass**: Menampilkan rekomendasi Game Pass berdasarkan nama atau ID.
- **Integrasi TextChatService**:
  - Terkoneksi langsung dengan sistem obrolan modern Roblox menggunakan instans `TextChatCommand`.

---

## 2. Sistem Musik Global & Visualizer Reaktif
Sistem audio terpusat yang memastikan semua pemain mendengarkan lagu secara tersinkronisasi:
- **HUD Now Playing (PlayingBar)**:
  - Menampilkan judul lagu, artis pembuat, kode audio Roblox (`AssetId`), serta progres durasi berjalan.
  - Mendukung transisi warna latar belakang dinamis mengikuti tema aktif.
- **Streaming Audio Real-time**:
  - Memantau posisi pemutaran lagu setiap detik menggunakan koneksi `RunService` dan sinkronisasi server (`musicSystem`).
- **Saved Songs Library (Pustaka Lagu Tersimpan)**:
  - Pemain dapat menyimpan (*bookmark*) daftar audio favorit ke penyimpanan data pribadi (`saveData`).
  - Fitur tambah lagu manual menggunakan kode ID audio (`_renderSaveCodes`), verifikasi hak cipta/ketersediaan audio Roblox (`_verifyAudios` / `checkIdAsync`), dan opsi hapus lagu.
- **Antrean & Request Lagu**:
  - Pengajuan lagu baru ke antrean putar publik server (`_requestSong`).
  - Menampilkan total antrean (`_getQueueSize`).
- **Voting Skip Lagu**:
  - Tombol lewati lagu dengan mekanisme pemungutan suara antar pemain aktif di server.
- **Music Reactive Lighting / Bar Visualizer**:
  - Animasi bilah GUI dan pencahayaan neon/mesh part (`BarVisualizer`) yang berkedip dan memanjang reaktif mengikuti level kekuatan suara (`PlaybackLoudness`).
- **Audio Region Transition**:
  - Equalizer dan efek reverb suara yang bertransisi dinamis saat pemain berpindah dari dalam ruangan (*Inside*) ke luar ruangan (*Outside*).

---

## 3. Sistem Tarian & Emote
Katalog gerakan dansa dan animasi karakter dengan sinkronisasi multiplayer:
- **Menu Tarian & Pencarian Cepat**:
  - Tampilan grid tarian dengan pencarian teks instan berdasarkan nama gerakan.
- **Sistem Favorit**:
  - Fitur menandai tarian favorit dengan animasi ikon hati (*HeartPopup*).
- **Sinkronisasi Tarian (Dance Sync)**:
  - Menyelaraskan animasi karakter dengan karakter pemain lain yang sedang menari (`sync <UserId>`).
  - Opsi keluar dari sinkronisasi tarian (`leaveSync`).
- **Seated Emotes (Duduk Kustom)**:
  - Deteksi otomatis saat karakter duduk di kursi/sofa (`Seat` / `Chair`) dan mengganti animasi duduk standar Roblox dengan pose duduk kustom yang estetik.

---

## 4. Sistem Interaksi Pemain & Inspeksi Outfit
Interaksi kontekstual saat pemain mengklik karakter lain di dunia 3D:
- **Player Highlight Visual**:
  - Garis batas cahaya (*glow/highlight outline*) yang muncul di sekeliling karakter target dengan warna yang menyesuaikan tema antarmuka.
- **Menu Aksi Cepat**:
  - **Add Friend**: Mengirimkan permintaan pertemanan Roblox.
  - **Sync**: Menyinkronkan tarian secara instan dengan pemain tersebut.
  - **Chat**: Membuka obrolan pribadi/bisikan (*whisper*).
  - **Hide/Show Avatar**: Menyembunyikan atau memunculkan kembali avatar pemain target secara lokal untuk menghemat memori atau kenyamanan visual.
  - **Gift**: Mengirimkan hadiah gamepass atau barang ke pemain lain.
- **Accessory & Outfit Inspector**:
  - Membaca dan menampilkan seluruh daftar aksesoris, topi, kemeja, celana, dan item Limited yang sedang dipakai pemain lain.
  - Fitur pratinjau item dan tombol pembelian langsung item Roblox (*Buy* / *Buy All*).

---

## 5. Fasilitas VIP & Efek Visual Karakter
Fitur eksklusif bagi pemegang Game Pass atau status VIP:
- **Freecam Sinematik**:
  - Mode kamera bebas noclip (`freecam`) dengan akselerasi halus menggunakan mouse, keyboard, dan controller untuk perekaman konten.
- **Perintah Efek & Partikel Karakter**:
  - `/light [color]` & `/unlight`: Menambahkan sumber cahaya *PointLight* di torso karakter dengan opsi warna.
  - `/sparkles [color]` & `/unsparkles`: Menambahkan partikel kerlap-kerlip *Sparkles*.
  - `/particles [color, texture]` & `/unparticles`: Menambahkan semburan partikel *ParticleEmitter*.
  - `/fire [color]` & `/unfire`: Menambahkan kobaran api *Fire* di tubuh karakter.
  - `/characterInvisible`: Mengaktifkan mode transparansi penuh pada karakter.
- **VIP Chat Tag**:
  - Tag khusus `[VIP]` dengan warna cerah pada setiap pesan yang dikirimkan di chat publik.
- **VIP Zone Protection**:
  - Pintu dan zona pembatas khusus yang memvalidasi kepemilikan Game Pass VIP (`VipDoor`).

---

## 6. Sistem Toolbar & Inventaris Kustom
Pengganti backpack standar Roblox dengan antarmuka modern:
- **Custom Hotbar UI**:
  - Menampilkan daftar alat (*tools*) di bagian bawah layar dengan animasi pemilihan slot yang halus.
  - Efek rotasi gradasi aktif pada slot alat yang sedang digunakan (*gradient rotation*).
- **Pengaturan Warna Tool (`Tool.Colors`)**:
  - Palet warna kustom untuk mengubah warna tampilan alat.
- **Tool Hitbox & Handling**:
  - Sistem hitbox klik (`PlayerHitbox`, `Weld`), pengelolaan animasi saat alat dipegang, dan penonaktifan aksesoris tertentu saat alat aktif.

---

## 7. Sistem Pergerakan Karakter & Multi-Platform Controller
Mekanik pergerakan karakter yang dioptimalkan untuk PC, Ponsel, dan Gamepad/Konsol:
- **Pengaturan Kecepatan Berjalan**:
  - **Sprint / Lari Cepat** (`WalkSpeed = 24`): Tombol `R` pada keyboard, tombol layar sentuh `Run` pada mobile, atau `L3` pada controller.
  - **Slow Walk / Jalan Perlahan** (`WalkSpeed = 4`): Tombol `LeftShift`.
  - **Kecepatan Normal** (`WalkSpeed = 16`): Transisi tween mulus via `TweenService`.
  - **Dance Speed Lock**: Karakter yang sedang menari dikunci agar tidak dapat bergerak mendadak yang merusak animasi.
- **Gamepad / Console Cross-Navigation**:
  - Sistem navigasi berbasis fokus controller (`ControllerNavigationManager`) untuk berpindah antar tombol UI secara mulus.
- **Mobile Touch Controls**:
  - Bilah tombol sentuh virtual di layar dengan pengaturan tingkat transparansi (*opacity*) dan opsi kontrol eksperimental.

---

## 8. Panel Pengaturan Komprehensif (Settings & Preferences)
Seluruh preferensi pemain disimpan secara persisten di server (`saveData`):

| Kategori | Opsi Pengaturan | Tipe Input | Nilai / Rentang | Keterangan |
| :--- | :--- | :--- | :--- | :--- |
| **General** | `interface` | Switch | `true / false` | Menampilkan atau menyembunyikan menu game |
| | `bubble_chats` | Switch | `true / false` | Toggle balon obrolan di atas kepala |
| | `player_names` | Switch | `true / false` | Toggle nama pemain di atas kepala |
| | `music` | Slider | `0 - 100` | Pengatur volume musik lokal |
| **Screen** | `eye_comfort` | Switch | `true / false` | Filter pencahayaan nyaman untuk mata |
| | `camera_focus` | Button | - | Memusatkan fokus kamera |
| | `camera_fov` | Slider | `10 - 110` | Mengatur luas sudut pandang kamera (FOV) |
| | `camera_smooth`| Slider | `0 - 100` | Kehalusan pergerakan kamera (*drone smoothing*) |
| | `themes` | Button | Modal Gamepass | Mengubah tema warna antarmuka |
| **On-screen**| `buttons_opacity`| Slider | `0 - 100` | Transparansi tombol sentuh virtual di layar |
| | `experimental_controls`| Switch | `true / false` | Mengaktifkan skema kontrol sentuh baru |
| **Graphics**| `player_effects` | Switch | `true / false` | Toggle efek partikel pemain lain |
| | `textures` | Switch | `true / false` | Toggle tekstur material dunia |
| | `visible_accessory` | Switch | `true / false` | Toggle tampilan aksesoris pemain lain (FPS Boost) |
| **Reset** | `reset_settings` | Button | Modal Dialog | Mengembalikan seluruh pengaturan ke default |

---

## 9. Sistem Kamera Sinematik & Integrasi Virtual Reality (VR)
- **Drone Camera & Smooth First Person**:
  - Sistem kamera orang pertama yang halus dengan pelacakan rotasi kepala karakter (`rotateCharacterWithCamera`), titik fokus kepala (`createHeadFocus`), dan penyesuaian transparansi bagian tubuh saat sudut pandang dekat.
- **Integrasi Penuh Virtual Reality (`VRService`)**:
  - Deteksi perangkat VR aktif (`isVR`).
  - Pelacakan dan replikasi CFrame tangan kanan (`TrackedRightHand`) dan tangan kiri (`LeftLowerArm`) secara real-time.
  - Penyesuaian visibilitas tubuh pemain VR di lingkungan multiplayer.

---

## 10. Sistem Overhead Rank & Display Names
- **BillboardGui Overhead Kustom**:
  - Menampilkan nama tampilan pemain, ikon negara/bendera, dan rank status di atas kepala.
  - **Distance Culling**: Otomatis menyembunyikan nama pemain yang berada di luar jarak jangkau penglihatan (`MaxDistance`) untuk menghemat performa.
  - **First Person Auto-Hide**: Otomatis menyembunyikan teks overhead ketika pemain beralih ke mode kamera orang pertama.

---

## 11. Sistem Kendaraan & Kemudi Otomatis (Vehicle & AutoPilot)
Sistem pengendalian kendaraan yang terletak pada modul akhir [sdf.md](file:///c:/Users/RDP/Desktop/roblox-ongoing/sdf.md):
- **Kalkulasi Throttle (`ComputeThrottle`)**:
  - Menghitung akselerasi maju/mundur kendaraan berdasarkan vektor input.
- **Kalkulasi Steer (`ComputeSteer`)**:
  - Menghitung sudut belok roda kendaraan secara dinamis menggunakan perhitungan trigonometri `atan2`:
    $$\text{Steer Angle} = -\text{atan2}(-v.x, -v.z) \times \frac{180^\circ}{\pi} \div \text{MaxSteeringAngle}$$
- **AutoPilot Setup (`SetupAutoPilot`)**:
  - Mengonfigurasi kecepatan maksimum berdasarkan `VehicleSeat.MaxSpeed`.
  - Mengatur batas sudut kemudi otomatis maksimum (`MaxSteeringAngle = 35°`).

---

## 12. Sistem Zona Wilayah & Pencahayaan Atmosferik
- **ZonePlus Integration**:
  - Modul deteksi keberadaan pemain dalam area geometris tertentu (`GetPartBoundsInBox`, `GetPartBoundsInRadius`).
  - Memvalidasi pemain yang masuk/keluar zona (lantai dansa, area lounge, zona VIP).
- **Realistic Illumination & Ambient Lighting**:
  - Pengendali pencahayaan atmosferik dinamis (`Realistic Illumination`) yang menyesuaikan bayangan, kabut (*Atmosphere*), dan pencahayaan interior ruangan.

---

## 13. Sistem Notifikasi & Dialog Modal (UI Feedback)
- **Centralized Notification Manager**:
  - Sistem notifikasi toast terpusat dengan antrean vertikal, animasi tween kemunculan, dan ikon penanda status.
  - Deteksi dan peringatan otomatis jika FPS pemain turun drastis (*Low FPS Warning / 0FPS Check*).
- **Prompt & Warning Modals**:
  - Kotak dialog konfirmasi modal (`WarningFrame`) dengan tombol konfirmasi/batal untuk tindakan penting (misal: reset pengaturan, pembelian Game Pass, atau log peringatan/sanksi).

---

## 14. Arsitektur Komunikasi Remote (`callProvider`)
Seluruh modul klien berkomunikasi ke server melalui satu gerbang komunikasi terpusat `ConnectionManager.callProvider`:

| Nama Provider | Fungsi Utama |
| :--- | :--- |
| `commandHandler` | Memproses eksekusi perintah teks, sinkronisasi tarian, dan fetch daftar perintah |
| `musicInfo` / `musicSystem` | Mengambil status lagu aktif, manipulasi antrean, dan streaming musik |
| `animationHandler` | Memutar tarian, mengatur tarian kursi, dan sinkronisasi gerakan |
| `playerData` | Mengambil data level, status, dan riwayat pemain |
| `saveData` | Menyimpan preferensi pengaturan lokal dan daftar lagu tersimpan |
| `gamepassInfo` | Memverifikasi kepemilikan gamepass dan inisiasi prompt pembelian |
| `themeProvider` | Mengambil dan menerapkan palet warna antarmuka |
| `toolUtils` | Menangani aksi penggunaan dan equipping peralatan |
| `vrManager` | Menyinkronkan orientasi tangan dan headset pemain VR ke server |
| `playerReplication` | Mengelola sinkronisasi status visibilitas dan kustomisasi avatar antar klien |
