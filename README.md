# LinguaGo — deployment gratis GitHub + Cloudflare Pages

LinguaGo adalah starter website belajar bahasa responsif: katalog 8 bahasa, frasa dasar, audio melalui Web Speech API, kuis XP/level, penyimpanan lokal, integrasi opsional Supabase Auth + progres, serta endpoint tutor AI untuk Cloudflare Workers AI.

## Isi project

- `index.html` — UI dan logika frontend.
- `functions/api/chat.js` — endpoint serverless `/api/chat` untuk tutor AI.
- `supabase/schema.sql` — profil, progres, riwayat kuis, leaderboard, dan kebijakan Row Level Security.
- `README.md` — panduan ini.

## 1. Buat repository GitHub

1. Login atau daftar di https://github.com
2. Buat repository baru bernama `linguago`, pilih Public (opsional), lalu Create repository.
3. Unggah semua file/folder project ini dengan **Add file → Upload files**. Pastikan `index.html` berada di root repository dan folder `functions/api/chat.js` tetap utuh.
4. Klik **Commit changes**.

Alternatif di komputer, setelah mengunduh dan mengekstrak ZIP:

```bash
git init
git add .
git commit -m "Build LinguaGo language learning website"
git branch -M main
git remote add origin https://github.com/USERNAME/linguago.git
git push -u origin main
```

Ganti `USERNAME` dengan username GitHub milikmu.

## 2. Deploy ke Cloudflare Pages

1. Daftar/login di https://dash.cloudflare.com/
2. Buka **Workers & Pages** → **Create** → **Pages** → **Connect to Git** (nama menu bisa sedikit berubah).
3. Hubungkan GitHub dan pilih repository `linguago`.
4. Untuk framework preset pilih **None**.
5. Build command: kosongkan atau gunakan `exit 0` jika dashboard mewajibkan perintah.
6. Build output directory: `/` atau `.` (folder root yang berisi `index.html`).
7. Klik **Save and Deploy**.
8. Cloudflare memberi URL seperti `https://linguago-xxxx.pages.dev`.

Cloudflare Pages Functions di folder `functions/` berjalan sebagai fungsi serverless saat deploy melalui integrasi Git. Uji URL `/api/chat` setelah menyiapkan AI binding di langkah 4.

## 3. Aktifkan login dan sinkronisasi progres (Supabase)

Hosting frontend dapat gratis pada kuota paket gratis yang berlaku. Supabase memiliki paket gratis dengan batas pemakaian dan kebijakan yang dapat berubah. Akun Supabase diperlukan untuk login online.

1. Buat project di https://supabase.com/
2. Buka **SQL Editor**, buat query baru, salin isi `supabase/schema.sql`, lalu Run.
3. Buka **Project Settings → API** (atau menu API Keys).
4. Salin Project URL dan anon/public key (publishable key juga dapat dipakai sesuai dukungan SDK).
5. Buka `index.html`, temukan:

```js
const CONFIG={supabaseUrl:"",supabaseAnonKey:""};
```

Isi URL dan key publik milik project-mu. Contoh format (jangan pakai contoh ini sebagai key sungguhan):

```js
const CONFIG={
  supabaseUrl:"https://PROJECT_ID.supabase.co",
  supabaseAnonKey:"SUPABASE_PUBLIC_ANON_KEY"
};
```

6. Commit dan push perubahan ke GitHub. Cloudflare Pages akan deploy ulang otomatis.
7. Di Supabase Authentication, atur **Site URL** ke URL Pages milikmu dan tambahkan URL itu ke **Redirect URLs**.
8. Sesuaikan pengaturan konfirmasi email sesuai kebutuhan. Untuk produksi, aktifkan konfirmasi email.
9. Buka website, pilih Akun, lalu daftar/masuk.

**Keamanan:** anon/publishable key memang untuk frontend dan dibatasi oleh RLS. Jangan pernah menaruh `service_role` key atau secret admin di `index.html`. Tabel progres memakai RLS supaya pengguna hanya dapat membaca/mengubah baris dengan `user_id` miliknya sendiri.

## 4. Aktifkan tutor AI

Endpoint `functions/api/chat.js` memakai binding AI dari Cloudflare. Ketersediaan model, binding, dan kuota gratis bergantung pada akun dan ketentuan Cloudflare yang berlaku; jangan anggap penggunaan tanpa batas.

1. Di Cloudflare Dashboard, buka aplikasi Pages LinguaGo.
2. Buka **Settings → Functions → AI bindings** (nama/lokasi menu dapat berubah).
3. Tambahkan binding bernama persis `AI` yang menunjuk ke Workers AI.
4. Jika dashboard memerlukan izin, aktifkan Workers AI untuk akun dan ikuti instruksi Cloudflare.
5. Deploy ulang dan buka menu Tutor AI. Jika binding belum tersedia, endpoint mengembalikan pesan bahwa AI belum dikonfigurasi.

Jika dashboard Pages akunmu tidak menampilkan AI binding, opsi lain adalah membuat Worker terpisah dengan binding Workers AI dan memanggil endpoint Worker itu dari frontend. Jangan menaruh API token rahasia di browser. Untuk production, ganti kebijakan CORS `*` di `functions/api/chat.js` dengan domain Pages milikmu.

## 5. Tes sebelum dibagikan

- Buka website di HP dan laptop.
- Tes navigasi, filter kursus, audio, kuis, XP, dan level.
- Tes daftar/masuk dan pastikan tabel `user_progress` berisi baris akun sendiri.
- Tes Tutor AI setelah binding AI aktif.
- Buka DevTools / Network jika ada error. Periksa Console untuk kesalahan JavaScript.
- Jangan menganggap leaderboard contoh sebagai papan peringkat global. Leaderboard global memerlukan tabel/view dan query server/database khusus.

## Batasan starter ini

- Materi yang tersedia berupa kumpulan frasa pemula, bukan kursus lengkap.
- Audio memakai suara yang dipasang pada perangkat/browser; bukan audio studio atau evaluasi pelafalan otomatis.
- XP/level frontend belum anti-cheat. Untuk aplikasi kompetitif, validasi XP di server.
- Login/progres Supabase bersifat opsional sampai konfigurasi dilakukan.
- Leaderboard membaca view `public.leaderboard` saat Supabase sudah terkonfigurasi; sebelum itu ia menampilkan data demo. Karena starter ini masih menerima XP dari frontend, skor belum anti-cheat.
- Tutor AI memerlukan AI binding, koneksi internet, dan tunduk pada batas pemakaian serta ketersediaan model.
- Gratis berarti memakai paket gratis sesuai kuota saat ini; layanan pihak ketiga dapat mengubah kuota, fitur, atau persyaratannya.

## Referensi resmi

- Cloudflare Pages: https://developers.cloudflare.com/pages/
- Pages Functions: https://developers.cloudflare.com/pages/functions/
- Workers AI: https://developers.cloudflare.com/workers-ai/
- Supabase Auth: https://supabase.com/docs/guides/auth
- Supabase Row Level Security: https://supabase.com/docs/guides/database/postgres/row-level-security
