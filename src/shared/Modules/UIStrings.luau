local UIStrings = {
	TextSize = {
		Header = 16,
		Title = 14,
		Button = 13,
		Body = 12,
		Caption = 11,
	},

	HeaderSize = 16,
	TitleSize = 14,
	ButtonSize = 13,
	BodySize = 12,
	CaptionSize = 11,


	Fonts = {
		Header = Enum.Font.GothamBold,
		Title = Enum.Font.GothamBold,
		Button = Enum.Font.GothamBold,
		Body = Enum.Font.GothamMedium,
		Caption = Enum.Font.Gotham,
	},

	VIP = {
		Title = "Perintah VIP",
		GlowstickTitle = "Tongkat Cahaya – Warna",
		SizeStatus = "📏 Ukuran: %.2f×",
		HatsStatus = "🎩 Aksesori: %d",
		GlowstickSubtitle = "Pilih warna  |  tekan R untuk siklus:",
		GlowstickHint = "Klik / tap untuk toggle lampu",
		InputPlaceholder = "/re  /hat id1 id2  /size 0.5",
		ResetAvatar = "Atur Ulang",
		TryHats = "Coba Aksesori",
		ChangeSize = "Ubah Ukuran",
		SuccessHat = "Aksesori berhasil dipasang",
		FailedHat = "Gagal memasang aksesori",
		InvalidSize = "Ukuran harus antara 0.3 dan 1.0",
		SizeUpdated = "Ukuran avatar diperbarui",
		PrefixV = "[V]",
		PrefixG = "[G]",
	},
	Emote = {
		Title = "Menu Animasi",
		SearchPlaceholder = "Cari animasi...",
		TabDance = "Tarian",
		TabPose = "Pose",
		TabFavorite = "Favorit",
		SpeedLabel = "Kecepatan",
		SyncPrompt = "Ajak Sinkronisasi",
		SyncAccepted = "Sinkronisasi dimulai",
		SyncDeclined = "Sinkronisasi ditolak",
		Playing = "Sedang diputar: %s",
		Stopped = "Animasi dihentikan",
		EmptyList = "Tidak ada animasi ditemukan",
	},
	Donate = {
		Title = "Donasi ke Server",
		Subtitle = "Pilih jumlah donasi kamu",
		MessageTitle = "Tulis Pesan Donasi",
		MessageInfo = "Pesan akan dikirim ke semua pemain",
		MessagePlaceholder = "Tulis pesan kamu di sini... (maks 200 karakter)",
		SendButton = "Kirim Pesan",
		CancelButton = "Batal",
		SuccessNotification = "Terima kasih atas donasi sebesar R$ %s!",
		Processing = "Memproses transaksi...",
		ErrorGeneral = "Terjadi kesalahan saat memproses donasi.",
	},
	Admin = {
		Title = "Panel Admin",
		Subtitle = "Kontrol & Manajemen Server",
		PermissionDenied = "Anda tidak memiliki izin untuk mengakses fitur ini.",
		Tabs = {
			RoleGive = "Bagi Role",
			Broadcast = "Siaran",
			CustomTitle = "Gelar Khusus",
			ManageTitle = "Kelola Gelar",
			Logs = "Catatan Log",
			Players = "Daftar Pemain",
			Settings = "Pengaturan",
		},
		RoleGive = {
			Header = "Manajemen Role",
			Subtitle = "Pilih pemain dan role untuk diberikan",
			PlayerList = "Daftar Pemain",
			SelectRole = "Pilih Role",
			SelectedPlayer = "Pemain Terpilih:",
			SelectedRole = "Role Terpilih:",
			NoneSelected = "Belum ada yang dipilih",
			ConfirmGive = "Berikan Role",
			Cancel = "Batalkan",
			FreeBadge = "GRATIS",
			Success = "Role berhasil diberikan",
			Failed = "Gagal memberikan role",
		},
		Broadcast = {
			Title = "Siaran Pesan",
			Subtitle = "Kirim pesan ke seluruh pemain di dalam server",
			ContentLabel = "Isi Pesan",
			Placeholder = "Ketik pesan siaran di sini...",
			SendButton = "Kirim Siaran",
			Success = "Siaran pesan berhasil dikirim",
		},
		CustomTitle = {
			Title = "Gelar Khusus",
			GiveTitle = "Berikan Gelar",
			UpdateTitle = "Perbarui",
			Preview = "Teks Pratinjau",
			PlayerNotFound = "Pemain tidak ditemukan",
			TypePlayerName = "Ketik nama pemain untuk memberikan gelar",
		},
	},
	Menu = {
		Title = "Menu Utama",
		Tabs = {
			Music = "Musik",
			Settings = "Pengaturan",
			Players = "Pemain",
			Shop = "Toko",
			Report = "Lapor",
		},
		Music = {
			Title = "Pemutar Musik",
			NowPlaying = "Sedang Memutar: %s",
			Paused = "Musik Dijeda",
			EmptyPlaylist = "Daftar lagu kosong",
			Volume = "Volume Lokal: %d%%",
			LoadFailed = "Gagal memuat lagu. Silakan coba lagi.",
			QueueAdded = "Lagu ditambahkan ke antrean",
		},
		Settings = {
			Title = "Pengaturan Game",
			SaveSuccess = "Pengaturan berhasil disimpan",
			ResetDefault = "Kembalikan ke Awal",
		},
		Report = {
			Title = "Laporkan Masalah",
			Placeholder = "Jelaskan masalah atau bug yang kamu temukan...",
			SendButton = "Kirim Laporan",
			SentSuccess = "Laporan berhasil dikirim. Terima kasih!",
			SentFailed = "Gagal mengirim laporan. Coba beberapa saat lagi.",
		},
	},
	Carry = {
		Title = "Menu Gendong",
		RequestSent = "Permintaan gendong telah dikirim ke %s",
		RequestReceived = "%s mengajak kamu untuk digendong (%s)",
		Accept = "Terima",
		Reject = "Tolak",
		Ended = "Gendongan selesai",
		Busy = "Pemain sedang sibuk",
		TooFar = "Jarak terlalu jauh",
		InvalidTarget = "Target pemain tidak valid",
		Styles = {
			Bridal = "Gaya Pengantin",
			CoupleHug = "Pelukan Pasangan",
			Pasakal = "Gendong Punggung",
			Piggyback = "Gendong Belakang",
			Shoulder = "Gendong Pundak",
		},
	},
	Status = {
		Closed = "Tertutup",
		Opening = "Membuka...",
		Open = "Terbuka",
		Closing = "Menutup...",
		Loading = "Memuat...",
		Success = "Berhasil",
		Failed = "Gagal",
		Error = "Kesalahan",
	},
	Common = {
		Close = "Tutup",
		Back = "Kembali",
		Confirm = "Konfirmasi",
		Search = "Cari...",
		Empty = "Kosong",
	},
}

local GuiService = game:GetService("GuiService")

-- Mendapatkan preferensi text size Roblox saat ini secara aman
function UIStrings.GetPreferredTextSize(): Enum.PreferredTextSize
	local ok, val = pcall(function()
		return GuiService.PreferredTextSize
	end)
	return (ok and val) or Enum.PreferredTextSize.Medium
end

-- Mengecek apakah player menggunakan ukuran teks di atas default
function UIStrings.IsHighTextSize(): boolean
	local pref = UIStrings.GetPreferredTextSize()
	return pref == Enum.PreferredTextSize.Large
		or pref == Enum.PreferredTextSize.Larger
		or pref == Enum.PreferredTextSize.Largest
end

-- Mengunci mati ukuran teks menggunakan UITextSizeConstraint (MinTextSize == MaxTextSize)
function UIStrings.LockTextSize(textElement: Instance, normalSize: number?): UITextSizeConstraint?
	if not (textElement:IsA("TextLabel") or textElement:IsA("TextButton") or textElement:IsA("TextBox")) then
		return nil
	end
	local textObj = textElement :: any

	if textObj.TextScaled then
		local existing = textObj:FindFirstChild("TextSizeLock")
		if existing then existing:Destroy() end
		return nil
	end

	if normalSize then
		textObj.TextSize = normalSize
	end

	local function syncLock()
		if not textObj.Parent or textObj.TextScaled then
			local existing = textObj:FindFirstChild("TextSizeLock")
			if existing and textObj.TextScaled then existing:Destroy() end
			return
		end

		local size = textObj.TextSize
		if size and size > 0 then
			local constraint = textObj:FindFirstChild("TextSizeLock")
				or textObj:FindFirstChildOfClass("UITextSizeConstraint")
			if not constraint then
				constraint = Instance.new("UITextSizeConstraint")
				constraint.Name = "TextSizeLock"
				constraint.Parent = textObj
			end
			constraint.MinTextSize = size
			constraint.MaxTextSize = size
		end
	end

	syncLock()

	if not textObj:GetAttribute("TextSizeLockBound") then
		textObj:SetAttribute("TextSizeLockBound", true)
		textObj:GetPropertyChangedSignal("TextSize"):Connect(syncLock)
		textObj:GetPropertyChangedSignal("TextScaled"):Connect(syncLock)
	end

	return textObj:FindFirstChild("TextSizeLock") or textObj:FindFirstChildOfClass("UITextSizeConstraint")
end

-- Alias untuk kemudahan pemanggilan
UIStrings.LockText = UIStrings.LockTextSize

-- Mengunci seluruh teks di dalam container secara rekursif dan berkelanjutan
function UIStrings.EnforceContainer(container: Instance): RBXScriptConnection
	local function checkAndLock(item: Instance)
		if (item:IsA("TextLabel") or item:IsA("TextButton") or item:IsA("TextBox")) and not (item :: any).TextScaled then
			UIStrings.LockTextSize(item)
		end
	end

	for _, desc in ipairs(container:GetDescendants()) do
		checkAndLock(desc)
	end

	return container.DescendantAdded:Connect(checkAndLock)
end

return UIStrings
