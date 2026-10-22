# Todo App

Aplikasi daftar tugas (to-do list) sederhana berbasis Ruby on Rails 8.1 dan SQLite.

Fitur:

- Menambah, melihat, mengubah, dan menghapus tugas (judul wajib diisi; deskripsi dan tenggat opsional)
- Menandai tugas selesai / belum selesai dengan satu klik
- Filter berdasarkan status: semua, aktif, selesai
- Pengurutan berdasarkan tanggal dibuat atau tenggat (tugas tanpa tenggat selalu di urutan terakhir)

## Prasyarat

| Kebutuhan | Versi | Catatan |
| --- | --- | --- |
| Ruby | 3.4.11 (lihat `.ruby-version`) | Disarankan memakai rbenv, asdf, atau mise |
| Bundler | 2.x | Sudah termasuk bersama Ruby |
| SQLite | 3.x | Library `libsqlite3` / `sqlite3-devel` untuk kompilasi gem `sqlite3` |
| Git | - | Untuk mengkloning repositori |
| Google Chrome / Chromium | Terbaru | **Hanya** untuk system test (browser headless) |

Tidak diperlukan Node.js: JavaScript dikelola lewat importmap.

Contoh instalasi paket sistem di Debian/Ubuntu:

```bash
sudo apt-get install -y build-essential git libsqlite3-dev libyaml-dev
# opsional, untuk system test:
sudo apt-get install -y chromium
```

## Instalasi

```bash
git clone https://github.com/Azrilardian05/Ruby-on-rails-TODO.git
cd Ruby-on-rails-TODO

bin/setup --skip-server
```

`bin/setup` bersifat idempoten dan menjalankan: `bundle install`, `bin/rails db:prepare`
(membuat database dan menjalankan migrasi), serta membersihkan log dan file sementara.
Tambahkan `--reset` untuk mengosongkan ulang database development.

Langkah manual yang setara:

```bash
bundle install
bin/rails db:prepare
```

Database SQLite disimpan di direktori `storage/` (di-ignore oleh Git).

## Menjalankan server

```bash
bin/dev        # atau: bin/rails server
```

Buka <http://localhost:3000>. Halaman utama memiliki tautan ke daftar tugas di `/tasks`.

Opsi yang sering dipakai:

```bash
bin/rails server -p 4000            # ganti port
bin/rails server -b 0.0.0.0         # dapat diakses dari jaringan
```

Endpoint pengecekan kesehatan tersedia di `/up` (HTTP 200 jika aplikasi berjalan).

## Menjalankan test

```bash
bin/rails test              # unit (model) dan controller test; tidak butuh browser
bin/rails test:system       # system test end-to-end; butuh Chrome/Chromium
bin/rails test:all          # keduanya (system test butuh Chrome/Chromium terpasang)
```

Menjalankan satu file atau satu test:

```bash
bin/rails test test/models/task_test.rb
bin/rails test test/controllers/tasks_controller_test.rb:8
bin/rails test test/system/tasks_test.rb
```

Cakupan test:

- `test/models` : validasi, scope filter status, dan pengurutan `Task`
- `test/controllers` : aksi CRUD, toggle, filter, dan sort pada `TasksController`
- `test/system` : alur end-to-end di browser (tambah, selesai, ubah, hapus, filter, sort)

System test memakai headless Chrome dengan opsi `--no-sandbox` dan `--disable-dev-shm-usage`
(lihat `test/application_system_test_case.rb`) agar dapat berjalan sebagai root atau di dalam
container. Selenium mengunduh driver yang sesuai secara otomatis (butuh koneksi internet pada
run pertama).

### Pemeriksaan kualitas (CI lokal)

```bash
bin/ci            # setup, rubocop, bundler-audit, importmap audit, brakeman, dan semua test
```

Atau satu per satu:

```bash
bin/rubocop
bin/brakeman --quiet --no-pager
bin/bundler-audit
```

## Deploy

Deploy bersifat opsional. Repositori ini belum dideploy ke target tertentu, tetapi sudah
menyertakan `Dockerfile` produksi dan konfigurasi [Kamal](https://kamal-deploy.org)
(`config/deploy.yml`). Aplikasi di mode production memakai SQLite (database utama, cache,
queue, dan cable, semuanya di `storage/`) sehingga **`storage/` harus berada di volume persisten**.

### Variabel lingkungan

| Variabel | Fungsi |
| --- | --- |
| `RAILS_MASTER_KEY` | Isi `config/master.key`, untuk mendekripsi `config/credentials.yml.enc`. File ini tidak ada di repositori. |
| `SECRET_KEY_BASE` | Alternatif jika tidak memakai credentials: nilai acak yang dibuat dengan `bin/rails secret`. |
| `RAILS_ENV` | `production` (sudah diset di `Dockerfile`). |
| `PORT` | Port Puma (default 3000; image Docker memakai Thruster di port 80). |
| `RAILS_MAX_THREADS` | Jumlah thread Puma dan koneksi database (default 5). |

Jika `config/master.key` tidak tersedia (mis. pada fork baru), buat kredensial baru:

```bash
rm config/credentials.yml.enc
EDITOR="true" bin/rails credentials:edit    # membuat master.key dan credentials.yml.enc baru
```

Simpan `config/master.key` di tempat aman; jangan di-commit (sudah di-ignore).

### Opsi 1: Docker

```bash
docker build -t todo_app .
docker run -d -p 80:80 \
  -v todo_app_storage:/rails/storage \
  -e RAILS_MASTER_KEY=<isi config/master.key> \
  --name todo_app todo_app
```

Buka <http://localhost> dan cek `curl -i http://localhost/up`. Skrip
`bin/docker-entrypoint` otomatis menjalankan `db:prepare` saat server dimulai.

> Catatan: `config.force_ssl` dan `config.assume_ssl` di
> `config/environments/production.rb` masih dikomentari. Aktifkan keduanya bila aplikasi
> berada di belakang proxy/load balancer yang melakukan terminasi SSL.

### Opsi 2: Kamal ke server sendiri

1. Edit `config/deploy.yml`: ganti IP server (`servers.web`), isi `registry` (Docker Hub / GHCR),
   dan tambahkan `proxy` dengan `host` serta `ssl: true` jika memakai domain.
2. Siapkan secret di `.kamal/secrets` (mis. `RAILS_MASTER_KEY=$(cat config/master.key)` dan
   `KAMAL_REGISTRY_PASSWORD`).
3. Jalankan:

```bash
bin/kamal setup      # pertama kali: install Docker di server, build, dan jalankan
bin/kamal deploy     # deploy berikutnya
bin/kamal logs       # lihat log
```

### Menjalankan production secara lokal (tanpa Docker)

```bash
export RAILS_ENV=production SECRET_KEY_BASE=$(bin/rails secret)
bin/rails db:prepare
bin/rails server -p 3000
curl -i http://localhost:3000/up
```

## Struktur singkat

```
app/models/task.rb                    # model Task, validasi, scope filter dan sort
app/controllers/tasks_controller.rb   # CRUD, toggle, filter, sort
app/views/tasks/                      # tampilan daftar, form, detail
config/routes.rb                      # root "home#index", resources :tasks (+ PATCH /tasks/:id/toggle)
test/                                 # model, controller, dan system test
```
