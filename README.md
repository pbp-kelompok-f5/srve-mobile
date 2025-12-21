Anggota Kelompok
 -Zhafira Cellonada D W (2406495842) 
 -Annisa Muthia Alfahira (2406437193) 
 -Khayru Rafamanda Prananta (2406495893) 
 -Abelyvia Tori Rebecca Silalahi (2406496391) 
 -Abid Dayyan Putra Rahardjo (2406356580) 
 -Auriel Erich Ibrahim Nst (2406428806)

Deskripsi 
Aplikasi SRVE merupakan aplikasi komunitas olahraga, dengan menggunakan SRVE pengguna dapat melakukan: Join Community dimana seseorang dapat bergabung kedalam suatu komunitas serta seseorang juga dapat membuat komunitas baru. Booking Fasilitas dimana untuk mempermudah, SRVE telah menyediakan fitur untuk menyewa fasilitas seperti lapang. Lapangan yang dapat di sewa bukan hanya yang berada di dalam UI melainkan mencakup lapangan lain di luar UI Matchmaking Olahraga dimana pengguna dapat memilih partner atau tim olahraga yang memiliki minat, kemampuan, serta jadwal match yang sama.

Daftar modul yang akan di implementasikan Profile Management mencakup login, register, verifikasi, role admin, role user, role guest, edit user profile Join community mencakup jenis-jenis olahraga, level permasing-masing community, chat dengan host, notifikasi Booking lapangan mencakup lapangan untuk jenis olahraga apa, lokasi lapangan, waktu booking lapangan, harga lapangan Match management mencakup membuat match dan atur tipe scoring masing masing cabang olahraga berdasarkan data yang diambil ketika user booking Review mencakup review mengenai komunitas yang di ikuti, review mengenai fasilitas lapangan, review mengenai tingkat responsif host Forum

Role
-Untuk di web pengguna terbagi menjadi dua bagian yaitu user yang sudah login dan belum, untuk user yang belum login tidak bisa join community, menulis thread, update profile, menulis review, serta join match. Sedangkan untuk pengguna yang sudah login dapat melakukan semua aktivitas di dalamnya
-Untuk di aplikasi semua pengguna akan di minta untuk regis ataupun login untuk menggunakan aplikasi tersebut

Sumber initial dataset https://www.ui.ac.id/sor-ui/ https://reclub.co/ https://ayo.co.id/ Cabang olahraga (3 dataset) => Tennis, Padel,Badminton

-Macam macam lapangan olahraga
 KONI Basketball Court Depok, BSS Arena Depok, Portal Basketball Club, Fortuna Sport center, MERBURGS sports Arena Sepak bola => Lapangan Sepak Bola Sparta, Futsal => Amole futsal Depok, F2 Futsal, Quadrant Futsal Padel =>Kindy Padel Court, Spin Padel Depok, De Padel Days Depok Lari =>

-Alur integrasi
Aplikasi web yang dibuat pada PTS digunakan sebagai backend yang menyediakan web service menggunakan Django, menyediakan endpoint API (URL) yang bisa diakses aplikasi lain, serta mengirim dan menerima data dalam format JSON. Di backend juga terdapat views untuk fetch data dengan api dari django yang telah ada, kemudian menggunakan base url dari link deployment yang telah digunakan.

Tautan deployment PWS https://khayru-rafamanda-srve.pbp.cs.ui.ac.id
Tautan untuk aplikasi https://app.bitrise.io/build/155309f6-0cdf-493f-9696-77e45e7b76b2


Tautan link design https://www.figma.com/design/liguRiQH1fhbWO6SAthFDE/srve?node-id=0-1&t=8E0oS1DxGWFgG4ch-
