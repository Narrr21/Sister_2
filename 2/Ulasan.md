### **Dokumen Ulasan Spesifikasi Tugas Besar III IF2211**

---

### **Bagian 1: Analisis Kualitas Dokumen**

Pada bagian ini, analisis kualitas penulisan dokumen spesifikasi dilakukan dari sudut pandang seorang penyunting. Fokus analisis adalah pada aspek-aspek seperti koherensi, kejelasan, kerapian, dan keterbacaan, tanpa menyinggung konten atau materi itu sendiri.

#### **1.1. Kejelasan dan Koherensi**

Secara umum, alur dokumen sudah baik, dimulai dari latar belakang, deskripsi tugas, fitur, spesifikasi teknis, hingga penilaian. Namun, beberapa bagian masih bisa ditingkatkan untuk kejelasan dan koherensi yang lebih baik.

* **Pencampuran Bahasa**: Terdapat banyak penggunaan istilah bahasa Inggris yang tidak dicetak miring dan dicampur langsung dalam kalimat berbahasa Indonesia (contoh: *command*, *user*, *soft copy*, *hardcoded*). Walaupun umum dalam bidang informatika, konsistensi dalam format (misalnya, selalu mencetak miring istilah asing) akan meningkatkan formalitas dan keterbacaan dokumen.
* **Struktur Kalimat Bertele-tele**: Beberapa kalimat dapat disederhanakan agar lebih mudah dipahami.
    * **Contoh**: "Bukan sesuatu yang janggal lagi jika semakin hari tugas-tugas di Teknik Informatika Semester 4 semakin bertambah banyak."
    * **Saran Perbaikan**: "Tugas mahasiswa Teknik Informatika Semester 4 yang semakin banyak adalah hal biasa."
* **Penamaan Bagian yang Kurang Tepat**: Bagian "Lain-lain" memuat informasi krusial seperti aturan pengerjaan kelompok, larangan plagiasi, dan tanggal pengumpulan. Sebaiknya, bagian ini diberi nama yang lebih deskriptif seperti "Ketentuan Pengerjaan Tugas" atau "Aturan Spesifikasi".

#### **1.2. Kerapian dan Keterbacaan (*Readability*)**

Keterbacaan dokumen terganggu oleh beberapa isu format dan presentasi yang signifikan.

* **Struktur Daftar (*List*) yang Kurang Rapi**: Pada beberapa bagian, penomoran dan indentasi daftar tidak konsisten.
    * **Contoh**: Pada fitur "Melihat daftar task yang harus dikerjakan", terdapat tiga level daftar (poin 2, lalu a/b/c, lalu i/ii/iii/iv). Namun, pada poin `c.ii`, kalimatnya berbunyi "User dapat melihat daftar task dengan jenis task tertentu" yang seharusnya menjadi judul untuk poin `c`, bukan bagian dari poin tersebut. Ini menciptakan kerancuan hierarki informasi.

* **Tidak Ada *Semantic Markup***: Dokumen ini tampaknya dibuat tanpa memperhatikan penandaan semantik. Judul, subjudul, dan isi utama memiliki gaya yang sering kali serupa. Penggunaan gaya (misalnya, Heading 1, Heading 2) secara konsisten akan menghasilkan daftar isi otomatis dan mempermudah navigasi dokumen.

* **Inkonsistensi Visual**: Terdapat beberapa inkonsistensi kecil, seperti penggunaan baris kosong yang tidak seragam antar paragraf dan format penulisan tanggal yang berbeda-beda dalam contoh ("14/04/2021" vs "22/04/21"). Konsistensi visual membantu pembaca memproses informasi lebih cepat.

Secara keseluruhan, dokumen ini fungsional namun memiliki ruang besar untuk perbaikan dari segi profesionalisme dan kemudahan baca.

---

### **Bagian 2: Analisis Relevansi dan Beban Tugas**

Bagian ini membahas konten tugas besar, mengevaluasi relevansinya dengan capaian pembelajaran mata kuliah, kesesuaian beban kerja dengan SKS, dan potensi pembagian kerja dalam kelompok.

#### **2.1. Relevansi dengan Capaian Mata Kuliah**

Relevansi tugas ini terhadap mata kuliah IF2211 Strategi Algoritma **sangat tinggi**.

* **Kesesuaian Materi**: Silabus mata kuliah secara eksplisit mencantumkan "String matching + regular expression (Regex)" sebagai salah satu lingkup bahasan.Tugas ini secara langsung meminta mahasiswa untuk menerapkan kedua konsep tersebut dalam sebuah proyek terintegrasi. Ini memastikan mahasiswa tidak hanya memahami teori, tetapi juga mampu mengaplikasikannya untuk menyelesaikan masalah nyata.

* **Pencapaian *Student Outcome***: Tugas ini berkontribusi pada beberapa capaian kuliah (berdasarkan ABET) yang tercantum dalam dokumen capaian:
    1.  ***Analyze a complex computing problem...***  Mahasiswa ditantang untuk menganalisis bagaimana perintah dalam bahasa natural dapat diurai dan dipahami oleh mesin, lalu mengidentifikasi solusi menggunakan *string matching* dan *regex*.
    2.  ***Design, implement, and evaluate a computing-based solution...*** : Ini adalah inti dari tugas besar—mahasiswa harus merancang arsitektur *chatbot*, mengimplementasikan fitur-fiturnya , dan (melalui laporan) mengevaluasi hasilnya.
    3.  ***Apply computer science theory and software development fundamentals...*** : Mahasiswa menerapkan teori (algoritma KMP/Boyer-Moore) dan fundamental pengembangan perangkat lunak (aplikasi web, manajemen data) untuk menghasilkan solusi komputasi.

#### **2.2. Analisis Beban Tugas terhadap Bobot SKS**

Mata kuliah IF2211 memiliki bobot 3 SKS. Menurut dokumen capaian, terdapat 3 Tugas Besar (Tubes), 3 Tugas Kecil (Tucil), dan 1 Makalah. Dengan demikian, Tubes ini adalah salah satu dari tiga proyek besar.

Melihat cakupan tugas, beban kerjanya **tergolong sangat berat** untuk satu dari tiga tugas besar dalam satu semester. Berikut rinciannya:
1.  **Implementasi Algoritma Inti**: Mengimplementasikan algoritma *string matching* (KMP atau Boyer-Moore) dari dasar.
2.  **Penguasaan Regex Lanjutan**: Merancang ekspresi reguler yang kompleks untuk mem-parsing berbagai format kalimat bahasa natural.
3.  **Pengembangan Aplikasi Web**: Membangun aplikasi berbasis web (wajib) yang mencakup *backend* (misalnya Flask, Django, PHP) dan, secara implisit, *frontend* untuk antarmuka *chat*.
4.  **Manajemen Data**: Merancang dan mengimplementasikan mekanisme penyimpanan data, baik melalui basis data sederhana atau sistem *file*.
5.  **Pengembangan Fitur Lengkap**: Mengimplementasikan 8 fitur utama (menambah, melihat, memperbarui, menyelesaikan *task*, dsb.) dan 1 fitur bonus.
6.  **Dokumentasi Komprehensif**: Membuat laporan terstruktur sebanyak 5 bab.
7.  **Bonus Tambahan**: Mengerjakan fitur bonus, melakukan *deployment*, dan membuat video presentasi.

Jika satu SKS setara dengan sekitar 3-4 jam usaha per minggu, maka 3 SKS berarti 9-12 jam per minggu untuk *seluruh* kegiatan perkuliahan (kuliah, belajar, tugas). Dengan adanya 2 Tubes lain, 3 Tucil, UTS, dan UAS, alokasi waktu untuk menyelesaikan proyek ini menjadi sangat ketat.

**Perspektif Prasyarat dan AI**: Mahasiswa yang mengambil mata kuliah ini memiliki prasyarat Algoritma dan Struktur Data. Namun, prasyarat pengembangan web tidak disebutkan. Mahasiswa mungkin harus mempelajari teknologi web (misalnya Flask) secara mandiri, yang menambah beban kerja secara **signifikan**. Namun di era AI generatif saat ini, yang relatif mudah untuk pengembangan perangkat lunak sederhana. Selain itu, tugas seperti ini tetap relevan untuk memahami "apa yang terjadi di balik layar" sebuah sistem pemrosesan bahasa. Namun, ekspektasi harus dikelola; tujuannya adalah memahami algoritma, bukan membuat *chatbot* yang untuk umum.

#### **2.3. Pembagian Tugas Kelompok**

Tugas ini dapat dibagi di antara anggota kelompok (2-3 orang). Potensi pembagian perannya adalah sebagai berikut:
* **Algoritma**: Fokus pada implementasi *string matching* (KMP/Boyer-Moore) dan logika fitur bonus deteksi *typo*.
* **Backend & Regex**: Merancang logika aplikasi, membangun *endpoint* API, dan merumuskan ekspresi reguler untuk setiap perintah.
* **Frontend & Data**: Mendesain antarmuka *chat* dan menangani logika penyimpanan/pengambilan data (ke *database* atau *file*).
* **Dokumentasi dan Pengujian**: Peran ini dapat diemban bersama-sama oleh seluruh anggota.

Meskipun dapat dibagi, **potensi ketidakseimbangan beban kerja cukup tinggi**. Porsi "Strategi Algoritma" yang sesungguhnya (implementasi KMP/BM) relatif **kecil** dibandingkan dengan total pekerjaan rekayasa perangkat lunak (membangun aplikasi web). Ada risiko satu anggota mengerjakan bagian algoritma, sementara yang lain mengerjakan tugas pengembangan web generik, sehingga esensi mata kuliah tidak tersampaikan secara merata. Dosen atau asisten perlu menekankan pentingnya pemahaman kolektif terhadap seluruh bagian program.