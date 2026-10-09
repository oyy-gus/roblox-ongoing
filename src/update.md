PENGEMBANGAN SISTEM MUSIK DANGDUT GLOBAL ROBLOX

Platform: Google Antigravity + Rojo + Roblox Studio
Bahasa pemrograman: Luau
Jenis proyek: Pengembangan dan refaktor proyek yang sudah ada

---

1. TUJUAN PROYEK

Saya memiliki map Roblox yang sudah mempunyai:

- Sistem musik dangdut global dalam setiap server.
- Integrasi API daftar putar.
- GUI musik lama yang masih menggunakan banyak kode hardcode.
- Proyek berbasis Rojo.
- Modul TopbarPlus yang sudah tersedia di "ReplicatedStorage > Icon".

Tugasmu adalah mengembangkan sistem yang sudah ada menjadi sistem musik yang lebih profesional, modern, stabil, modular, dan mudah dikembangkan.

Jangan membangun ulang proyek dari nol. Audit seluruh implementasi terlebih dahulu, pertahankan fitur yang bekerja, dan lakukan perubahan secara bertahap.

Prioritas utama:

1. Memperbaiki sistem musik yang sudah ada.
2. Mempertahankan dan meningkatkan integrasi API daftar putar.
3. Mengganti GUI hardcode dengan arsitektur modular.
4. Menggunakan TopbarPlus untuk membuka satu menu utama.
5. Mengimplementasikan hanya satu halaman, yaitu Musik.
6. Memastikan volume dikontrol secara lokal oleh setiap pemain.
7. Menggunakan Bahasa Indonesia untuk seluruh antarmuka pemain.
8. Menetapkan standar penamaan file, folder, modul, dan instance yang konsisten.
9. Menjaga kompatibilitas Rojo, keamanan, kinerja, dan kestabilan.

Jangan menghilangkan fitur lama yang masih digunakan tanpa alasan teknis yang jelas dan persetujuan saya.

---

2. LOKASI TOPBARPLUS — WAJIB DIIKUTI

Modul TopbarPlus sudah tersedia di:

"ReplicatedStorage > Icon"

Akses modul menggunakan pola berikut jika sesuai dengan struktur yang ditemukan:

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Icon = require(ReplicatedStorage:WaitForChild("Icon"))

Aturan wajib

- Gunakan modul "Icon" yang sudah tersedia.
- Jangan membuat ulang, memindahkan, atau menggandakan modul TopbarPlus.
- Jangan mengunduh atau memasang salinan lain tanpa alasan teknis yang jelas dan persetujuan saya.
- Hanya buat satu ikon TopbarPlus, yaitu Menu.
- Jangan membuat ikon TopbarPlus khusus Musik.
- Tombol Musik harus berada di dalam menu utama.
- Periksa kode modul "Icon" dan versi API yang benar-benar tersedia sebelum menggunakannya.
- Jangan mengasumsikan metode, parameter, atau perilaku TopbarPlus tanpa verifikasi.
- Hindari ikon ganda ketika karakter muncul kembali, GUI diinisialisasi ulang, atau skrip dijalankan ulang.
- Jangan mengubah lokasi modul "ReplicatedStorage > Icon".
- Pertahankan kompatibilitas dengan konfigurasi dan pemetaan Rojo yang ada.

Jika modul tidak dapat diakses atau API-nya tidak sesuai dengan perkiraan, laporkan masalah tersebut sebelum mempertimbangkan perubahan dependensi.

---

3. TAHAP PERTAMA: AUDIT BACA-SAJA

Sebelum mengubah berkas apa pun, lakukan audit menyeluruh terhadap proyek.

Periksa

- Konfigurasi Rojo, termasuk "default.project.json" jika tersedia.
- Struktur direktori dan pemetaan instance Roblox.
- Seluruh Script, LocalScript, dan ModuleScript terkait musik.
- GUI musik lama dan cara pembuatannya.
- Integrasi API daftar putar.
- Sistem pemilihan lagu, pemutaran, antrean, dan sinkronisasi.
- Seluruh RemoteEvent dan RemoteFunction terkait musik.
- Sistem hak akses DJ dan admin.
- Modul "ReplicatedStorage > Icon".
- Seluruh referensi TopbarPlus.
- Pengelolaan volume dan objek Sound.
- Seluruh teks yang ditampilkan kepada pemain.
- Dependensi eksternal dan penanganan error.
- Potensi konflik antara instance hasil pemetaan Rojo dan instance yang dibuat saat runtime.

Telusuri alur sistem

Telusuri proses dari awal hingga akhir:

1. Pemain membuka menu.
2. Pemain membuka halaman Musik.
3. Pemain mencari lagu atau memilih daftar putar.
4. Permintaan diproses dan divalidasi.
5. Lagu dimasukkan ke antrean.
6. Server menentukan lagu yang diputar.
7. Status pemutaran disinkronkan kepada pemain.
8. GUI diperbarui berdasarkan status terbaru.
9. Pemutaran berlanjut ketika lagu selesai atau mengalami kegagalan.

Hasil audit

Sajikan laporan yang memuat:

- Fitur yang sudah berfungsi.
- Bug dan masalah sinkronisasi.
- Masalah keamanan.
- Kode yang berulang.
- Permintaan API yang berlebihan.
- Masalah struktur atau pemetaan Rojo.
- Masalah penamaan file.
- Modul yang dapat digunakan kembali.
- File yang perlu dipertahankan, dibuat, diubah, atau dipindahkan.
- Rencana migrasi beserta risiko dan langkah validasinya.

Tahap audit harus benar-benar baca-saja. Jangan mengedit, membuat, menghapus, memindahkan, atau mengganti nama file selama audit.

Setelah laporan selesai, berhenti dan tunggu persetujuan saya sebelum memulai perubahan file.

---

4. STRUKTUR MENU DAN NAVIGASI

Hierarki antarmuka yang diwajibkan:

TopbarPlus (ReplicatedStorage > Icon)
└── Menu
    └── Menu Utama
        ├── Judul Menu
        ├── Navigasi Halaman
        │   └── Musik
        └── Area Konten
            └── Halaman Musik

Tombol Menu

- Satu ikon TopbarPlus untuk membuka dan menutup menu utama.
- Gunakan ikon yang sesuai dengan fungsi menu.
- Status ikon dan status menu harus selalu konsisten.
- Tombol tutup di dalam menu harus bekerja.
- Hindari pembuatan ikon dan koneksi peristiwa ganda.

Menu utama

Menu utama harus memiliki:

- Judul menu.
- Tombol tutup.
- Area navigasi.
- Area konten.
- Sistem perpindahan halaman yang modular.

Untuk tahap ini, hanya implementasikan tombol navigasi Musik.

Jangan membuat halaman Pengaturan, Profil, Toko, Papan Peringkat, atau halaman lain. Jangan membuat placeholder untuk halaman yang belum diminta.

Arsitektur navigasi harus memungkinkan halaman baru ditambahkan pada masa mendatang tanpa membangun ulang menu.

Ketika menu ditutup

- Seluruh antarmuka menu disembunyikan.
- Navigasi dan konten halaman ikut disembunyikan.
- Musik tetap berjalan.
- Antrean tidak dihapus.
- Status pemutaran tidak diatur ulang.
- Volume lokal tidak berubah.
- Membuka menu kembali tidak menghasilkan GUI atau koneksi peristiwa duplikat.

---

5. HALAMAN MUSIK

Implementasikan satu halaman Musik di dalam area konten menu utama.

Gunakan sistem musik dan API yang sudah ada. Jangan membuat sistem pemutaran kedua yang berjalan secara terpisah.

A. Sedang Diputar

Tampilkan:

- Judul lagu.
- Nama artis jika tersedia.
- Sampul lagu jika tersedia.
- Status pemutaran.
- Bilah progres jika didukung.
- Waktu berjalan dan durasi jika tersedia.

Tangani judul panjang, metadata kosong, gambar yang gagal dimuat, dan kegagalan pemutaran.

B. Kontrol Musik

Sediakan kontrol berikut jika didukung oleh sistem yang sudah ada:

- Putar.
- Jeda.
- Lanjutkan.
- Lagu Berikutnya.
- Lagu Sebelumnya jika riwayat lagu tersedia.
- Bisukan.
- Aktifkan suara kembali.
- Penggeser volume lokal.

Semua tombol harus mempunyai fungsi nyata. Jangan membuat tombol yang hanya terlihat aktif tetapi tidak melakukan tindakan.

Kontrol yang mengubah pemutaran bersama harus divalidasi oleh server dan mengikuti hak akses yang berlaku.

C. Antrean Lagu

Tampilkan:

- Posisi lagu.
- Judul lagu.
- Nama peminta jika tersedia.
- Penanda lagu yang sedang diputar.

Sediakan permintaan lagu, penambahan lagu ke antrean, dan voting lewati lagu jika sesuai dengan arsitektur serta izin yang tersedia.

Antrean harus tetap konsisten ketika beberapa pemain mengirim permintaan secara bersamaan.

D. Daftar Putar

Pertahankan integrasi API yang sudah digunakan.

Kategori seperti Dangdut Koplo, DJ Jawa, Dangdut Lawas, Campursari, dan Dangdut Trending hanya ditampilkan jika benar-benar tersedia dari API atau data lokal yang sudah ada.

Jangan mengarang hasil API, kategori, metadata, maupun jumlah lagu.

Sediakan indikator pemuatan, tampilan kosong, penanganan error, dan tindakan untuk mencoba kembali.

E. Pencarian Lagu

Sediakan:

- Kolom pencarian.
- Hasil pencarian.
- Indikator pemuatan.
- Pesan jika lagu tidak ditemukan.
- Pesan kesalahan yang mudah dipahami.
- Tindakan untuk meminta lagu atau menambahkannya ke antrean.

Gunakan debounce, validasi input, cache yang sesuai, dan pencegahan permintaan API berulang.

---

6. SELURUH ANTARMUKA WAJIB BERBAHASA INDONESIA

Seluruh teks yang terlihat oleh pemain wajib menggunakan Bahasa Indonesia.

Cakupan:

- Judul menu dan halaman.
- Label tombol.
- Petunjuk.
- Kolom pencarian.
- Tooltip.
- Notifikasi.
- Pesan berhasil dan gagal.
- Konfirmasi tindakan.
- Informasi antrean.
- Tampilan pemuatan dan kosong.
- Pesan kesalahan API.
- Informasi volume.
- Pesan izin dan akses.

Contoh terjemahan:

Bahasa Inggris| Bahasa Indonesia
Menu| Menu
Music| Musik
Now Playing| Sedang Diputar
Search Music| Cari Lagu
Queue| Antrean Lagu
Playlist| Daftar Putar
Play| Putar
Pause| Jeda
Resume| Lanjutkan
Next| Lagu Berikutnya
Previous| Lagu Sebelumnya
Loading...| Memuat...
No Results Found| Lagu tidak ditemukan
Try Again| Coba Lagi
Close| Tutup
Request Failed| Permintaan gagal
Volume| Volume
Muted| Dibisukan

Pengelolaan teks

Buat satu sumber utama teks antarmuka, misalnya "UIStrings.lua".

Contoh struktur:

local UIStrings = {
    Menu = {
        Title = "Menu",
        Close = "Tutup",
    },

    Music = {
        Title = "Musik",
        NowPlaying = "Sedang Diputar",
        SearchPlaceholder = "Cari lagu...",
        Queue = "Antrean Lagu",
        Play = "Putar",
        Pause = "Jeda",
        Resume = "Lanjutkan",
        Next = "Lagu Berikutnya",
        Previous = "Lagu Sebelumnya",
        Volume = "Volume",
        EmptyQueue = "Belum ada lagu dalam antrean.",
        NoResults = "Lagu tidak ditemukan.",
    },

    Errors = {
        RequestFailed = "Permintaan gagal. Silakan coba lagi.",
        PlaylistUnavailable = "Daftar putar tidak tersedia saat ini.",
        PlaybackFailed = "Lagu tidak dapat diputar.",
    },
}

return UIStrings

Contoh di atas dapat disesuaikan dengan pola proyek yang sudah ada.

Ketentuan:

- Jangan menulis teks UI berulang di banyak file.
- Jangan menampilkan pesan error teknis mentah dari API kepada pemain.
- Jangan menerjemahkan judul lagu dan nama artis asli secara otomatis.
- Nama variabel, modul, dan fungsi internal boleh menggunakan konvensi teknis.
- Seluruh teks yang benar-benar dilihat pemain harus menggunakan Bahasa Indonesia.
- Lakukan pencarian terhadap seluruh label dan notifikasi sebelum menyelesaikan pekerjaan.

---

7. ARSITEKTUR MODULAR DAN PEMBUATAN UI MELALUI KODE

Seluruh UI harus dibuat dan dikelola melalui kode Luau yang dipetakan dengan Rojo. Saya tidak ingin mengedit tampilan secara manual di Roblox Studio.

Audit dahulu sistem yang sudah ada, lalu refaktor secara bertahap.

Referensi struktur folder

src/
├── client/
│   ├── Controllers/
│   │   ├── TopbarController.client.lua
│   │   ├── MenuController.lua
│   │   └── MusicController.lua
│   │
│   └── UI/
│       ├── Menu/
│       │   ├── MenuRoot.lua
│       │   ├── MenuNavigation.lua
│       │   ├── PageRegistry.lua
│       │   └── MusicPage.lua
│       │
│       └── Components/
│           ├── NowPlayingCard.lua
│           ├── SongCard.lua
│           ├── PlaylistCard.lua
│           ├── QueueList.lua
│           ├── MusicControls.lua
│           ├── VolumeSlider.lua
│           ├── SearchBar.lua
│           └── NotificationUI.lua
│
├── server/
│   ├── MusicService.server.lua
│   └── Services/
│       ├── QueueService.lua
│       ├── PlaylistService.lua
│       ├── PermissionService.lua
│       └── AudioService.lua
│
└── shared/
    ├── Config.lua
    ├── Theme.lua
    ├── UIStrings.lua
    └── Remotes.lua

Struktur ini hanya referensi, bukan daftar file yang wajib dibuat semuanya.

Jangan membuat file baru jika fungsi yang sama sudah ditangani oleh modul yang layak dipertahankan. Sesuaikan seluruh struktur dengan konfigurasi Rojo dan pola proyek yang ditemukan saat audit.

Aturan UI berbasis kode

- Setiap komponen mengambil warna, font, ukuran visual, jarak, radius, transparansi, dan durasi animasi dari "Theme.lua".
- Semua teks pemain berasal dari "UIStrings.lua".
- Konfigurasi perilaku berasal dari "Config.lua" atau modul konfigurasi fitur yang sesuai.
- Jangan menaruh semua angka ke "Theme.lua". Indeks antrean, jumlah percobaan, perhitungan progres, dan nilai algoritma bukan konfigurasi visual.
- Setiap komponen UI harus memiliki "Name" yang eksplisit dan deskriptif.
- Hindari nama bawaan seperti "Frame", "TextLabel", dan "TextButton" untuk instance yang dikelola langsung oleh sistem.
- Komponen menerima data melalui parameter atau metode pembaruan, bukan mengambil data server sendiri.
- Perubahan lagu hanya memperbarui bagian UI yang berubah.
- Jangan membuat ulang seluruh GUI setiap kali status lagu berubah.
- Jangan membuat koneksi peristiwa yang sama berkali-kali.

Siklus hidup komponen

Gunakan pola berikut jika sesuai dengan kebutuhan komponen:

- "new()" untuk membuat komponen.
- "Update(data)" untuk memperbarui tampilannya.
- "Destroy()" untuk membersihkan instance dan koneksi peristiwa yang dimilikinya.

Pastikan:

- "Destroy()" membersihkan koneksi dan instance yang benar-benar dimiliki komponen tersebut.
- Tidak menghapus instance milik komponen lain.
- Tidak ada koneksi event yang terus bertambah saat lagu berganti.
- Metode yang tidak diperlukan tidak dibuat hanya demi mengikuti pola.

Tanggung jawab modul

- "TopbarController": mengelola satu ikon Menu dari TopbarPlus.
- "MenuController": mengatur pembukaan, penutupan, dan status menu.
- "MusicController": menghubungkan interaksi UI dengan komunikasi server.
- "MenuRoot": membuat kerangka GUI dan area konten.
- "MenuNavigation": mengatur navigasi halaman.
- "PageRegistry": mendaftarkan halaman yang benar-benar tersedia. Untuk sekarang hanya Musik.
- "MusicPage": menyusun tampilan halaman Musik.
- Komponen UI: menangani bagian tampilan yang terpisah dan dapat digunakan kembali.
- "MusicService": menghubungkan sistem musik server dan layanan terkait.
- "QueueService": mengelola antrean bersama.
- "PlaylistService": menangani API daftar putar dan metadata.
- "AudioService": mengelola pemutaran audio serta kegagalannya.
- "PermissionService": memvalidasi izin tindakan musik.
- "Config": menyimpan konfigurasi perilaku.
- "Theme": menyimpan token desain UI.
- "UIStrings": menyimpan teks antarmuka.
- "Remotes": menjadi sumber definisi atau referensi Remote jika sesuai dengan arsitektur yang sudah ada.

Satu modul harus memiliki satu tanggung jawab utama. Namun, jangan memecah kode menjadi terlalu banyak file jika pemisahan tersebut tidak meningkatkan keterbacaan, pengujian, atau penggunaan ulang.

---

8. STANDAR PENAMAAN FILE, FOLDER, DAN INSTANCE

Kemudahan maintenance merupakan persyaratan wajib untuk seluruh perubahan dan pengembangan selanjutnya.

A. Penamaan file

Gunakan nama deskriptif dengan "PascalCase" untuk ModuleScript dan komponen.

Contoh:

- "MusicPage.lua"
- "MusicController.lua"
- "QueueService.lua"
- "PlaylistService.lua"
- "VolumeSlider.lua"
- "NowPlayingCard.lua"
- "UIStrings.lua"

Gunakan akhiran berdasarkan peran:

Jenis| Pola
ModuleScript| "PascalCase.lua"
Script server| "PascalCase.server.lua"
LocalScript| "PascalCase.client.lua"
Pengendali klien| "*Controller.lua"
Layanan| "*Service.lua"
Halaman| "*Page.lua"
Komponen kartu| "*Card.lua"
Komponen daftar| "*List.lua"

Ikuti format ekstensi dan pemetaan yang didukung konfigurasi Rojo proyek.

B. Hindari nama yang tidak jelas

Jangan membuat file baru dengan nama generik seperti:

- "Script.lua"
- "Script1.lua"
- "Main.lua"
- "Utils.lua"
- "Helper.lua"
- "New.lua"
- "Old.lua"
- "Copy.lua"
- "Final.lua"
- "Backup.lua"
- "MusicV2.lua"

Gunakan nama yang menjelaskan tujuan file secara spesifik.

Jangan menambahkan nomor versi ke nama file untuk membedakan revisi. Gunakan riwayat perubahan Git atau dokumentasi yang sesuai.

C. Penamaan folder

Kelompokkan file berdasarkan peran dan lapisan arsitektur, misalnya:

- "Controllers"
- "Services"
- "UI/Menu"
- "UI/Components"
- "shared"

Gunakan struktur yang benar-benar diperlukan. Jangan membuat folder kosong atau struktur bersarang berlebihan hanya untuk mengikuti contoh.

D. Penamaan instance Roblox

- Tetapkan properti "Name" secara eksplisit untuk instance yang dibuat melalui kode.
- Gunakan nama yang deskriptif dan konsisten dengan tanggung jawab instance.
- Hindari beberapa instance dengan nama yang sama dalam wadah yang sama jika dapat membingungkan pencarian atau pengelolaan.
- Nama file yang sama dalam folder berbeda diperbolehkan jika tidak menyebabkan konflik pemetaan, impor, atau identitas instance.

E. Penamaan identifier

- Nama modul dan komponen menggunakan "PascalCase".
- Variabel dan fungsi lokal menggunakan "camelCase".
- Konstanta konfigurasi menggunakan "UPPER_SNAKE_CASE".
- Variabel boolean diawali "is", "has", atau pola yang menjelaskan status.
- Nama Remote harus menjelaskan tindakan atau peristiwa.
- Gunakan hanya karakter ASCII untuk nama file, folder, modul, dan instance yang dikelola sistem.

F. Kontrak nama Remote

Nama Remote harus konsisten, spesifik, dan dikelola melalui satu sumber definisi, misalnya "Remotes.lua", atau sistem registrasi Remote yang sudah ada.

Contoh nama:

- "RequestSong"
- "VoteSkipSong"
- "GetPlaylist"
- "QueueUpdated"
- "PlaybackUpdated"

Contoh tersebut bukan perintah untuk membuat semua Remote. Audit terlebih dahulu Remote yang sudah ada dan gunakan kembali yang sesuai.

Jangan membuat Remote duplikat atau mengubah namanya tanpa memperbarui seluruh referensinya.

G. Dokumentasi berkas

Setiap modul penting harus memiliki komentar singkat di bagian awal yang menjelaskan:

- Tujuan file.
- Tanggung jawab utama.
- Dependensi penting jika ada.

Hindari komentar yang hanya mengulang kode atau dokumentasi yang tidak lagi sesuai dengan implementasi.

H. Migrasi nama lama

Jika audit menemukan nama file lama yang buruk:

1. Jangan mengubahnya selama audit.
2. Catat nama lama dan nama baru yang diusulkan.
3. Jelaskan alasan perubahan.
4. Periksa semua "require()", referensi instance, dan pemetaan Rojo.
5. Lakukan rename hanya pada tahap perbaikan setelah disetujui.
6. Perbarui seluruh referensi terkait.
7. Verifikasi bahwa tidak ada dependensi yang rusak.

Jangan menganggap nama file yang sama sebagai duplikasi otomatis. Periksa isi dan tanggung jawab masing-masing file terlebih dahulu.

---

9. PEMISAHAN STATUS DAN KETANGGUNGJAWABAN

Tetapkan satu sumber kebenaran untuk setiap jenis status.

Status server

Server menjadi sumber kebenaran untuk:

- Lagu yang sedang diputar.
- Antrean bersama.
- Status pemutaran bersama.
- Riwayat lagu jika didukung.
- Hak akses dan izin tindakan.
- Voting lewati lagu jika diterapkan.

Status klien

Setiap klien mengelola:

- Status terbuka atau tertutupnya menu.
- Volume lokal.
- Status bisu lokal.
- Interaksi UI milik pemain.
- Tampilan berdasarkan data musik yang diterima.

Metadata

API atau layanan daftar putar menyediakan metadata yang telah divalidasi, seperti judul, artis, kategori, dan identitas sumber lagu.

Jangan membuat salinan status antrean yang dapat berubah secara independen di banyak modul.

Hindari circular dependency, ketergantungan tersembunyi, dan akses langsung komponen UI ke logika internal server.

---

10. SISTEM MUSIK DAN INTEGRASI API

Pertahankan API daftar putar yang sudah digunakan.

Jangan mengganti API lama, format respons, atau sistem pemutaran tanpa audit dan alasan teknis yang jelas.

Sistem harus menangani:

- API tidak merespons.
- Data API tidak valid.
- Daftar putar kosong.
- Lagu tidak tersedia.
- Metadata tidak lengkap.
- Permintaan ganda.
- Kegagalan pemutaran.
- Antrean kosong.
- Pemain masuk atau keluar saat musik berlangsung.
- Permintaan beberapa pemain secara bersamaan.
- Koneksi atau dependensi yang gagal.

Terapkan jika sesuai:

- Validasi respons.
- Cache dengan masa berlaku yang sesuai.
- Timeout permintaan.
- Batas percobaan ulang.
- Debounce pencarian.
- Pencegahan permintaan ganda.
- Penanganan error yang jelas.
- Logging yang informatif.

Jangan menelan seluruh error menggunakan "pcall()" tanpa diagnostik yang memadai.

Sumber audio

Pisahkan metadata lagu dari aset audio yang benar-benar dapat dimainkan Roblox.

URL API, halaman playlist, dan tautan streaming eksternal tidak otomatis menjadi sumber audio yang valid untuk "Sound".

Gunakan aset audio yang kompatibel dengan Roblox dan memiliki izin penggunaan yang sesuai.

Jangan membuat bypass atau mekanisme yang melanggar pembatasan akses audio.

Keandalan pemutaran

- Pastikan hanya ada satu pengendali pemutaran utama untuk setiap server.
- Hindari loop pemutaran ganda.
- Tangani antrean kosong dengan aman.
- Tangani lagu gagal diputar tanpa membuat antrean macet.
- Pastikan status terbaru dapat dipulihkan ketika pemain masuk.
- Pertahankan musik ketika menu ditutup.
- Jangan menghapus antrean akibat perubahan GUI.

Sistem musik bersama berlaku untuk pemain dalam server Roblox yang sama. Jangan menambahkan sinkronisasi lintas-server tanpa persetujuan saya.

---

11. VOLUME LOKAL — TANPA VOLUME GLOBAL

Setiap pemain harus dapat mengatur volume musik secara independen.

Aturan mutlak:

- Tidak ada volume global.
- Admin tidak mempunyai kontrol volume global.
- DJ tidak mempunyai kontrol volume global.
- Owner tidak mempunyai kontrol volume global.
- Pemain tidak dapat mengubah volume pemain lain.
- Volume lokal tidak menjadi bagian dari status pemutaran bersama.
- Menutup atau membuka menu tidak mengubah volume.

Audit terlebih dahulu bagaimana sistem audio saat ini menggunakan objek "Sound" dan replikasi Roblox.

Jika properti volume pada objek suara yang direplikasi dapat memengaruhi semua pemain, jangan menganggap perubahan properti tersebut bersifat lokal.

Pilih implementasi yang sesuai dengan arsitektur audio Roblox dan sistem yang sudah ada sehingga setiap pemain mengontrol suara yang didengarnya sendiri.

Jangan mengubah volume pada server sebagai cara untuk mengimplementasikan penggeser lokal.

Pengujian wajib

Gunakan minimal dua klien dalam satu server:

1. Kedua pemain mendengarkan lagu yang sama.
2. Pemain A mengatur volume ke tingkat rendah.
3. Pemain B mempertahankan volume pada tingkat tinggi.
4. Pastikan volume B tidak berubah ketika A menggeser volumenya.
5. Ulangi pengujian dalam arah sebaliknya.
6. Uji tombol bisu dan aktifkan suara kembali.
7. Tutup dan buka kembali menu untuk memastikan volume tetap sama.

Jika arsitektur yang ada tidak memungkinkan volume independen dengan aman, jelaskan keterbatasannya dan usulkan perubahan terkecil yang diperlukan sebelum mengganti sistem pemutaran.

Jangan menyatakan fitur berhasil sebelum pengujian dilakukan.

---

12. KEAMANAN DAN HAK AKSES

Pertahankan sistem hak akses yang sudah ada jika masih sesuai.

Pemain dapat:

- Melihat lagu yang sedang diputar.
- Melihat antrean.
- Melihat daftar putar.
- Mencari lagu.
- Meminta lagu.
- Melakukan voting jika tersedia.
- Mengatur volume lokal.

DJ dan admin dapat melakukan tindakan pengelolaan musik sesuai izin yang telah ditentukan.

Tidak ada peran yang boleh mengubah volume pemain lain atau volume global.

Semua tindakan penting harus divalidasi di server, termasuk:

- Permintaan lagu.
- Pengubahan antrean.
- Voting.
- Kontrol pemutaran yang dibatasi.
- Tindakan DJ atau admin.

Jangan mengandalkan tombol tersembunyi di GUI sebagai perlindungan keamanan.

Validasi input, batasi permintaan yang berlebihan, dan jangan mempercayai data hak akses yang dikirim klien.

Jangan mengekspos rahasia API melalui LocalScript, modul bersama, atau respons Remote.

---

13. TEMA DAN PENGALAMAN PENGGUNA

Gunakan desain modern dengan tema gelap, aksen ungu, sian, atau biru yang konsisten.

Tampilan harus:

- Bersih dan profesional.
- Responsif di perangkat seluler dan desktop.
- Nyaman digunakan dengan layar sentuh.
- Memiliki hierarki visual yang jelas.
- Tidak terlalu ramai.
- Memiliki kontras teks yang baik.
- Menggunakan animasi ringan.
- Tidak mengganggu permainan.
- Tidak membangun ulang seluruh UI setiap kali lagu berubah.

Simpan token desain dalam "Theme.lua", misalnya:

local Theme = {
    Colors = {
        Background = Color3.fromRGB(18, 18, 24),
        Surface = Color3.fromRGB(28, 28, 38),
        Primary = Color3.fromRGB(145, 90, 255),
        Accent = Color3.fromRGB(65, 210, 225),
        Text = Color3.fromRGB(245, 245, 250),
        TextMuted = Color3.fromRGB(165, 165, 180),
    },

    Dimensions = {
        CornerRadius = 12,
        Spacing = 8,
        PanelPadding = 16,
    },
}

return Theme

Angka di atas hanya contoh awal. Sesuaikan dengan desain dan sistem yang ditemukan saat audit.

Komponen harus menggunakan token tema, bukan mendefinisikan warna, ukuran, radius, atau jarak sendiri-sendiri.

Jangan memindahkan seluruh nilai teknis algoritma ke "Theme.lua".

---

14. KOMPATIBILITAS ROJO

Sebelum mengubah struktur file:

- Baca konfigurasi Rojo yang sebenarnya.
- Pahami bagaimana setiap folder dipetakan ke layanan Roblox.
- Pertahankan lokasi "ReplicatedStorage > Icon".
- Pastikan semua "require()" menggunakan jalur yang benar.
- Pastikan Script server, LocalScript, dan ModuleScript berada di lokasi yang tepat.
- Hindari instance ganda antara hasil pemetaan Rojo dan pembuatan saat runtime.
- Periksa seluruh referensi setelah file dipindahkan atau diganti nama.
- Jangan mengubah bagian proyek yang tidak berhubungan tanpa alasan.
- Jangan membuat folder atau modul yang bertentangan dengan konfigurasi yang sudah ada.

Jika pemetaan saat ini mengharuskan struktur berbeda dari contoh prompt, prioritaskan kompatibilitas proyek yang sebenarnya dan dokumentasikan alasannya.

---

15. PENGUJIAN WAJIB

A. TopbarPlus dan menu

- Hanya satu ikon Menu yang tampil.
- Ikon berasal dari "ReplicatedStorage > Icon".
- Tidak ada modul TopbarPlus duplikat.
- Menu dapat dibuka dan ditutup.
- Tombol tutup berfungsi.
- Tombol Musik berada di dalam menu.
- Halaman Musik tampil dalam area konten.
- Tidak ada ikon TopbarPlus khusus Musik.
- Tidak ada halaman tambahan atau placeholder.
- Membuka menu berulang kali tidak menghasilkan GUI atau koneksi ganda.
- Musik tetap berjalan saat menu ditutup.

B. Sistem musik

- Pemutaran berfungsi.
- Antrean berfungsi.
- Pencarian dan daftar putar berfungsi.
- Data API divalidasi.
- Error API ditangani dengan baik.
- Permintaan ganda dikendalikan.
- Status musik tersinkron dalam satu server.
- Kegagalan pemutaran tidak membuat sistem macet.
- Pemain yang masuk dapat menerima status terbaru.

C. Volume

- Setiap pemain mempunyai volume independen.
- Tombol bisu dan aktifkan suara kembali berfungsi.
- Tidak ada kontrol volume global.
- Admin, DJ, dan owner tidak dapat mengubah volume pemain lain.
- Volume tetap sama setelah menu ditutup dan dibuka kembali.

D. Bahasa

- Seluruh label antarmuka menggunakan Bahasa Indonesia.
- Semua notifikasi dan pesan kesalahan menggunakan Bahasa Indonesia.
- Tooltip dan tampilan kosong menggunakan Bahasa Indonesia.
- Pesan error API mentah tidak ditampilkan langsung kepada pemain.
- Judul lagu dan nama artis asli tetap dipertahankan.

E. UI modular

- Komponen mengambil token visual dari "Theme.lua".
- Teks antarmuka berasal dari "UIStrings.lua".
- Pembaruan lagu tidak membangun ulang seluruh GUI.
- Siklus hidup komponen membersihkan koneksi miliknya.
- Tidak ada koneksi peristiwa yang menumpuk.
- Tidak ada ketergantungan melingkar yang tidak disengaja.

F. Penamaan dan maintenance

- Nama file deskriptif dan konsisten.
- Tidak ada nama generik baru seperti "Main", "Utils", "Helper", "Copy", atau "Final".
- File ditempatkan dalam folder sesuai tanggung jawabnya.
- Tidak ada pemisahan modul yang tidak diperlukan.
- Seluruh referensi setelah rename atau pemindahan sudah diperbarui.
- Perubahan nama lama dan baru tercatat dalam laporan migrasi.
- Nama Remote konsisten.
- Nama instance yang dikelola kode ditetapkan secara eksplisit.

G. Rojo dan kestabilan

- Konfigurasi pemetaan valid.
- Modul dapat ditemukan.
- Tidak ada GUI atau ikon duplikat.
- Tidak ada referensi yang rusak.
- Tidak ada error baru akibat perubahan.
- Tidak ada loop pemutaran ganda.
- Tidak ada perubahan tak disengaja pada fitur lain.

Bedakan pengujian yang benar-benar sudah dijalankan dari pengujian yang masih membutuhkan Roblox Studio atau beberapa klien.

---

16. URUTAN PELAKSANAAN

Tahap 1 — Audit

Audit baca-saja terhadap proyek, API, GUI, TopbarPlus, hak akses, dan konfigurasi Rojo.

Tahap 2 — Laporan

Sajikan laporan masalah dan rencana migrasi. Sertakan file yang akan dibuat, diubah, dipindahkan, atau diganti nama beserta alasannya.

Berhenti dan tunggu persetujuan saya.

Tahap 3 — Perbaikan sistem musik

Perbaiki bug yang ditemukan, pengelolaan antrean, integrasi API, penanganan error, dan sinkronisasi.

Tahap 4 — Integrasi TopbarPlus

Gunakan modul "ReplicatedStorage > Icon" yang sudah tersedia. Pastikan hanya ada satu ikon Menu.

Tahap 5 — Menu utama

Buat kerangka menu, tombol tutup, navigasi, dan area konten.

Tahap 6 — Halaman Musik

Implementasikan hanya halaman Musik beserta komponen yang benar-benar diperlukan.

Tahap 7 — Bahasa dan tema

Pastikan seluruh UI menggunakan Bahasa Indonesia dan seluruh token desain dikelola secara terpusat.

Tahap 8 — Volume lokal

Implementasikan dan uji volume independen menggunakan beberapa klien.

Tahap 9 — Validasi

Periksa Rojo, keamanan, kinerja, pemetaan, dependensi, dan pengalaman pengguna.

Tahap 10 — Laporan akhir

Sajikan ringkasan perubahan, file yang dibuat atau diubah, hasil pengujian aktual, masalah yang masih tersisa, dan langkah selanjutnya.

---

17. FORMAT LAPORAN PERUBAHAN

Setelah implementasi, berikan laporan yang mudah dipahami:

Ringkasan

Jelaskan perubahan utama dan hasil yang dicapai.

Daftar file

File| Status| Tanggung jawab atau perubahan
Nama file| Dibuat/Diubah/Dipindahkan/Dihapus| Alasan dan fungsi

Cantumkan hanya file yang benar-benar berubah.

Migrasi nama file

Nama lama| Nama baru| Alasan
Nama lama| Nama baru| Alasan perubahan

Jika tidak ada rename, nyatakan bahwa tidak ada file yang diganti nama.

Hasil pengujian

Pisahkan menjadi:

- Berhasil diuji.
- Gagal diuji.
- Belum diuji.
- Memerlukan Roblox Studio atau beberapa klien.

Jangan mengklaim hasil yang belum diverifikasi.

Risiko dan tindak lanjut

Jelaskan masalah yang tersisa dan rekomendasi untuk tahap berikutnya.

---

INSTRUKSI TERAKHIR

Mulai dengan audit baca-saja terhadap proyek yang sudah ada.

Jangan langsung membuat, mengubah, menghapus, memindahkan, atau mengganti nama file.

Setelah audit, berikan laporan dan rencana migrasi, kemudian tunggu persetujuan saya.

Gunakan TopbarPlus dari "ReplicatedStorage > Icon". Jangan membuat ikon khusus Musik atau modul TopbarPlus duplikat.

Buat satu menu utama dengan hanya satu halaman yang diimplementasikan, yaitu Musik. Seluruh UI dibuat melalui kode Luau yang dipetakan Rojo.

Semua teks antarmuka pemain wajib menggunakan Bahasa Indonesia. Semua nilai desain visual harus menggunakan token dari "Theme.lua", bukan nilai yang tersebar di komponen.

Terapkan penamaan file, folder, modul, Remote, dan instance yang deskriptif, konsisten, serta mudah dipelihara. Jangan memecah modul secara berlebihan dan jangan memaksakan struktur baru yang tidak sesuai dengan proyek.

Pertahankan fitur lama yang bekerja. Pastikan musik tetap berjalan ketika menu ditutup dan setiap pemain mengatur volume yang didengarnya secara independen.

Utamakan kestabilan, kompatibilitas, keamanan, dan kemudahan maintenance. Jangan menyatakan pekerjaan selesai sebelum perubahan dan pengujian yang relevan benar-benar diverifikasi.