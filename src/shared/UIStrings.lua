--[[
	UIStrings.lua
	Tujuan: Sumber utama teks antarmuka pemain (100% Bahasa Indonesia terpusat).
	Seluruh label, judul tombol, placeholder, dan pesan status didefinisikan di sini agar mudah dirawat.
]]

local UIStrings = {
	Menu = {
		Title = "MENU UTAMA",
		Close = "Tutup",
		TabMusic = "🎵 Musik",
	},

	SubTabs = {
		NowPlaying = "🎧 Diputar",
		Playlist = "🎶 Daftar",
		Favorites = "⭐ Favorit",
		Queue = "📜 Antrean",
	},

	Music = {
		Title = "Musik Dangdut Global",
		GlobalPlaylistHeader = "Daftar Lagu Global",
		FavoritesHeader = "Favorit Saya",
		NowPlayingHeader = "SEDANG DIPUTAR",
		NowPlaying = "SEDANG DIPUTAR",
		SearchPlaceholder = "Cari lagu...",
		SearchFavoritesPlaceholder = "Cari lagu favorit...",
		SearchResults = "Hasil Pencarian",
		Queue = "Antrean Lagu",
		Playlist = "Daftar Putar",
		
		Play = "Putar",
		Pause = "Jeda",
		Resume = "Lanjutkan",
		Next = "Berikutnya",
		Previous = "Sebelumnya",
		Request = "Minta Lagu",
		
		VoteSkip = "⏩ Vote Skip (%d/%d)",
		FavoriteMy = "☆ Favorit Saya",
		FavoriteOn = "⭐ Favorit: ON",

		AddQueue = "+ Antre",
		Queued = "Dalam Antrean",
		RequestedBy = "Diminta oleh: %s",
		QueueHeader = "📜 Antrean Lagu (%d)",
		
		Volume = "🔊 Volume",
		Mute = "🔇 Mute",
		Unmute = "🔊 Unmute",
		
		EmptyQueue = "Belum ada lagu dalam antrean.",
		EmptyPlaylist = "Daftar putar tidak tersedia.",
		EmptyFavorites = "Belum ada lagu favorit.\nKlik ☆ pada lagu di tab Daftar untuk memfavoritkan!",
		NoResults = "Lagu tidak ditemukan.",
		Loading = "Memuat data...",
		UnknownArtist = "Artis Tidak Diketahui",
		UnknownTitle = "Judul Tidak Diketahui",
		ServerSource = "Dangdut Global Server",
	},

	Categories = {
		All = "Semua",
		DangdutKoplo = "Dangdut Koplo",
		DJJawa = "DJ Jawa",
		DangdutLawas = "Dangdut Lawas",
		Campursari = "Campursari",
		DangdutTrending = "Dangdut Trending",
	},

	Errors = {
		RequestFailed = "Permintaan gagal. Silakan coba lagi.",
		PlaylistUnavailable = "Daftar putar tidak dapat dimuat saat ini.",
		PlaybackFailed = "Lagu gagal diputar di server.",
		PermissionDenied = "Anda tidak memiliki izin untuk melakukan tindakan ini.",
		Cooldown = "Harap tunggu sejenak sebelum menekan kembali.",
	},
}

return UIStrings
