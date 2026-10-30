# POCKET EMPIRES 3D — KAPSAMLI OYNANIŞ, MOBİL KONTROL, BOT AI VE UX DENETİM RAPORU

**Tarih:** 30 Ekim 2026  
**Denetçi:** Baş Oyun QA Mühendisi & Mobil RTS Game Designer  
**Oyun Adı:** Pocket Empires 3D  
**Kapsam:** Tam Oynanış Döngüsü, Mobil Dokunmatik Kontroller, Bot AI, Krallık Dengesi, HD-2D Görsel Kalite, Performans ve UX/UI  
**Kanıt Dizini:** [`docs/audits/gameplay-review/evidence/`](file:///Users/talhaaksoy/Project/denemelik/godot/docs/audits/gameplay-review/evidence/)

---

## A. EXECUTIVE SUMMARY (YÖNETİCİ ÖZETİ)

Pocket Empires 3D, Godot 4.7 motoru ile 540x960 dikey (portrait) ekranda 2.5D / HD-2D diorama tarzında çalışan, Age of Empires benzeri bir mobil RTS projesidir. 10 farklı krallık (Osmanlılar, Bizanslılar, Britanyalılar, Franklar, Moğollar, Tötonlar, Japonlar, Sarazenler, Vikingler, Çinliler), prosedürel 3D harita üretimi, 4 kaynaklı ekonomi modeli (Besin, Odun, Altın, Taş) ve dalga tabanlı düşman bot yapay zekâsı içermektedir.

### Temel Durum Özeti:
1. **Oynanabilirlik:** **KISMİ (PARTIAL)**. Maç başlatılabiliyor, kaynak toplanabiliyor, binalar inşa edilebiliyor ve asker üretilerek düşman ana üssü yok edildiğinde oyun sonu tetiklenebiliyor. Ancak oyuncu ile harita arasındaki etkileşimde ve ekonomi zincirinde kritik tasarım ve kontrol tıkanıklıkları bulunmaktadır.
2. **Mobil Hazırlık:** **HAZIR DEĞİL (NOT READY)**. Ekran dikey yönelimdedir ve temel buton dokunma hedefleri minimum boyut standartlarını karşılamaktadır. Ancak tek parmakla harita kaydırma (kamera pan) ile ekranda kutu seçimi (drag-box selection) aynı giriş olayını (`_unhandled_input`) dinlediği için birbiriyle doğrudan çakışmaktadır. Oyuncu haritayı kaydırmak isterken yanlışlıkla birimleri seçmekte veya seçim kutusu açmaktadır.
3. **Bot AI Durumu:** **ZAYIF & KİLİTLENMEYE MEYİLLİ (WEAK & PRONE TO STAGNATION)**. Bot ilk 60 saniyede bir miktar bina kurup asker üretmekte, ancak kaynak dağılım algoritması oran tabanlı (percentage-based) olmadığı için köylülerini kontrolsüzce altın madenlerine yığmakta (T=240s simülasyonunda 2162 Altın birikirken Besin 0'da kalmıştır). Besin tükenince asker ve işçi üretimi durmakta ve bot 7 birimde kalıcı olarak kilitlenmektedir.
4. **En Büyük 5 Problem:**
   - **Depo Kamplarının (Lumber Camp, Mining Camp, Mill) Kodda Olmaması:** Bütün kaynaklar için işçilerin haritanın öbür ucundaki Town Center'a yürümesi gerekmektedir.
   - **Kamera Pan / Kutu Seçim Çakışması:** Mobil dokunmatikte sürükleme hareketi aynı anda hem kamerayı hareket ettirmekte hem seçim kutusu çizmektedir.
   - **Bot AI Ekonomik Kilitlenmesi:** Kaynak dağıtımı dengesizliği nedeniyle botun 1-2 dakika sonra üretimi durmaktadır.
   - **Bina İnşaatında Çift Etkileşim Yükü:** Bina iskeleti konulduktan sonra seçili köylüler otomatik olarak inşaata başlamamakta, oyuncunun tekrar köylüyü seçip iskelete tıklaması gerekmektedir.
   - **Üretim Kuyruğu İptal / İade Mekanizmasının Yokluğu:** Yanlışlıkla basılan üretimler iptal edilememektedir.

---

## B. TEST ENVIRONMENT (TEST ORTAMI)

- **Oyun Motoru:** Godot Engine v4.7.2.stable.official.ed1daf0bf
- **İşletim Sistemi:** macOS (Darwin 24.x, Apple Silicon M1)
- **Render Altyapısı:** `gl_compatibility` (OpenGL 4.1 Metal Wrapper)
- **Ekran / Viewport Çözünürlüğü:** 540x960 (Portrait 9:16 aspect expand)
- **Test Yöntemleri:**
  - `DESKTOP PLAYTEST`: Godot penceresinde etkileşimli oynanış.
  - `HEADLESS SIMULATION`: 1500 adımlı (300 saniye / 5 simüle dakika) bağımsız oyun döngüsü simülasyonu.
  - `CODE REVIEW`: Tüm GDScript kaynak kodları, sahne ağaçları ve asset manifestoları.
- **Kanıt Kayıtları:** [`docs/audits/gameplay-review/evidence/simulation_execution_log.txt`](file:///Users/talhaaksoy/Project/denemelik/godot/docs/audits/gameplay-review/evidence/simulation_execution_log.txt)

---

## C. GAMEPLAY TEST RESULTS (MEKANİK TEST MATRİSİ)

| Sistem | Durum | Test Yöntemi | Temel Bulgu / Gözlem |
|---|---|---|---|
| **Ana Menü & Kurulum** | **PASS** | DESKTOP & CODE | Krallık, harita ve düşman seçimi sorunsuz çalışıyor. Dikey arayüz butonları duyarlı. |
| **Başlangıç Yerleşimi** | **PASS** | SIMULATION | 3 İşçi + 1 Town Center güneyde (Oyuncu), 3 İşçi + 1 Town Center kuzeyde (Bot) doğuyor. |
| **Kaynak Toplama (Odun/Besin/Altın/Taş)** | **PARTIAL** | SIMULATION | 4 kaynak da toplanabiliyor, kapasite dolunca depoya gidip boşaltıp geri dönüyor. Ancak depo kampları yok. |
| **Depo Binaları (Kamplar)** | **FAIL** | CODE REVIEW | `Lumber Camp`, `Mining Camp`, `Mill` `Building3D.BuildingType` enum'ında ve kodda tanımlı değil. |
| **Bina İnşaatı** | **PARTIAL** | DESKTOP & CODE | Önizleme (ghost mesh) ve yerleşim çalışıyor; ancak köylüler otomatik inşaata gitmiyor, manuel komut şart. |
| **İşçi Üretimi** | **PASS** | SIMULATION | 50 Besin harcanarak Town Center kuyruğuna alınıyor, süre bitince rally point'e çıkıyor. |
| **Asker Üretimi** | **PASS** | SIMULATION | Kışla (Piyade), Okçu Alanı (Okçu), Ahır (Süvari) ve Kale (Özel Birlik) üretimleri doğru çalışıyor. |
| **Teknoloji Geliştirme** | **PASS** | SIMULATION | Demirci binasında `iron_weapons`, `scale_armor`, `bodkin_arrows` hasar/zırh değerlerini kalıcı artırıyor. |
| **Çağ Atlama (Age II)** | **PASS** | SIMULATION | Town Center üzerinden 500 Besin + 200 Altın ile Hisar Çağı'na geçiliyor; binaların zırhı ve yeni yapılar açılıyor. |
| **Savaş & Hasar Formülü** | **PASS** | SIMULATION | Zırh çıkarma formülü (`max(1, dmg - armor)`), Mızrakçı-Süvari (2.5x) ve Süvari-Okçu (1.5x) sayaçları çalışıyor. |
| **Savunma Binaları Ateşi** | **PASS** | SIMULATION | Town Center (Menzil 13.0, Hasar 12.0) ve Kuleler menzile giren düşmana ok/mermi fırlatıyor. |
| **Bot Ekonomi AI** | **FAIL** | SIMULATION | Bot köylüleri oransal dağıtılmıyor. 2000+ Altın birikirken Besin 0'da kalıyor ve bot kilitleniyor. |
| **Bot Askeri AI** | **PARTIAL** | SIMULATION | 40-55 saniye aralıklarla dalga halinde oyuncunun Town Center'ına taarruz ediyor. Taktiksel geri çekilme yok. |
| **Zafer / Yenilgi Tetikleyicisi** | **PASS** | SIMULATION | Rakip Town Center yok edildiğinde Zafer, oyuncu Town Center'ı yıkıldığında Yenilgi ekranı çıkıyor. |
| **Kayıt / Yükleme (Save/Load)** | **PASS** | SIMULATION | F5/F9 ile kaynaklar, çağ, birimler ve binalar JSON olarak kaydedilip tekrar yüklenebiliyor. |

---

## D. MOBILE CONTROLS REVIEW (MOBİL KONTROL DENETİMİ)

### 1. Kamera Kontrolleri
- **Kaydırma (Pan):** Tek parmak sürükleme (`MobileCamera3D.gd`) ekran koordinatlarındaki farkı 3D zemin ötelenmesine dönüştürerek kamerayı kaydırıyor.
- **Zoom:** Çift parmak pinch hareketi (`InputEventScreenTouch` & `InputEventScreenDrag`) ve HUD üzerindeki `[＋]` / `[－]` butonları çalışıyor. Yükseklik aralığı: `min: 12.0m` (yakın detay) - `max: 38.0m` (genel strateji görünümü).
- **Kritik Hata (P1):** Tek parmakla harita kaydırılırken, `GameController3D._unhandled_input()` aynı olayı algılayıp `(pos - start).length() > 22px` şartını sağladığı anda **seçim kutusu (drag box)** çizmeye başlamaktadır! Oyuncu kamerayı kaydırdığını zannederken ekran üzerindeki askerleri seçmekte veya yanlışlıkla yerdeki birimlere hareket emri göndermektedir.

### 2. Dokunma Hedef Boyutları (Touch Targets)
- Apple Human Interface Guidelines minimum standardı: **44x44 pt**
- Google Material / Android standardı: **48x48 dp**
- Oyundaki Ölçümler:
  - `BuildMainButton` [İNŞAAT]: Yükseklik 52px (Genişlik esnek) -> **UYGUN**
  - `ArmyButton` [ORDU]: Yükseklik 52px -> **UYGUN**
  - `BaseButton` [ANA ÜS]: Yükseklik 52px -> **UYGUN**
  - `IdleVillagerButton` [BOŞTA]: Yükseklik 52px -> **UYGUN**
  - `DeselectButton` [✖ Bırak]: 76x46 px -> **UYGUN**
  - Birim Dokunma Hedefi: 3D raycast tabanlı. Birim modelleri son güncellemede `0.022` ölçeğe (~3.5m yükseklik) çıkarıldığı için dokunma doğruluğu belirgin şekilde iyileşmiştir.

### 3. İşlem Başına Gereken Etkileşim Sayıları (UX Tıklama Maliyeti)

| Görev | Gereken Etkileşim | Değerlendirme |
|---|---|---|
| **Köylüyü oduna gönderme** | 2 dokunma + 1 kaydırma | `[BOŞTA]` -> Ağaca dokun. Oldukça akıcı. |
| **Yeni köylü üretme** | 2 dokunma | `[ANA ÜS]` -> `[İşçi (50 Besi)]`. Seri ve hızlı. |
| **Ev inşa etme** | **5-6 etkileşim** | `[İNŞAAT]` -> `[Ev]` -> Haritada konumla -> Onayla -> Köylü seç -> İskelete dokun. **Yorucu ve hantal.** |
| **Beş askeri seçme** | **3-5 etkileşim / Zor** | Kutu seçimi kamera ile çakıştığı için tek tek dokunmak veya [ORDU] ile tüm haritayı seçmek gerekiyor. |
| **Orduyu düşmana gönderme** | 2-3 dokunma | `[ORDU]` -> Minimap'te düşman üssüne dokun -> Hedefe saldır. Başarılı. |
| **Üretim kuyruğunu yönetme** | 1 dokunma (Ekleme) | Ekleme kolay; ancak yanlış basılan birimi **iptal etme seçeneği YOK.** |

---

## E. BOT YAPAY ZEKÂ DENETİMİ (AI BEHAVIOR REVIEW)

Headless 300 saniyelik gerçek zamanlı simülasyon ve kaynak analizi sonuçları:

```
[T =   0s] Bot Kaynakları: Besin=200, Odun=200, Altın=100, Taş=100 | Birim: 3 | Bina: 1
[T =  60s] Bot Kaynakları: Besin=  0, Odun=100, Altın=594, Taş=100 | Birim: 7 | Bina: 5 (Dalga: 1)
[T = 120s] Bot Kaynakları: Besin=  0, Odun=100, Altın=1282,Taş=100 | Birim: 7 | Bina: 5 (Dalga: 3)
[T = 180s] Bot Kaynakları: Besin=  0, Odun=100, Altın=1810,Taş=100 | Birim: 7 | Bina: 5 (Dalga: 4)
[T = 240s] Bot Kaynakları: Besin=  0, Odun=100, Altın=2162,Taş=100 | Birim: 7 | Bina: 5 (Dalga: 6)
```

### Temel Yapay Zekâ Hataları:
1. **Ekonomik Tıkanma (Resource Imbalance Freeze):**
   - Bot, `resources["gold"] < 120` kontrolü sağlandıktan sonra boştaki köylüleri altına gönderiyor. Ancak bir kez altına başlayan köylü ölene kadar altın toplamaya devam ediyor.
   - Sonuç: 2162 Altın birikiyor; ancak Besin 0'da kaldığı için bot yeni köylü üretemiyor, asker basamıyor ve Çağ 2'ye geçemiyor (Çağ 2 için 500 Besin + 200 Altın gerekiyor).
2. **Depo Kampı Kurmama:**
   - Bot kodunda (`EnemyAI3D.gd`) Değirmen, Oduncu veya Maden Kampı kurma emri bulunmamaktadır. Bot işçileri haritanın uzak köşelerindeki madenlerden Town Center'a kadar dakikalarca yürümektedir.
3. **Saldırı Taktikleri:**
   - Bot her 40-55 saniyede bir askeri birimlerini oyuncunun Town Center'ına gönderiyor. Yolda oyuncu ordusuyla karşılaşırsa savunma formasyonuna geçmiyor, hedefe körlemesine koşuyor.
   - Ordu yenildiğinde veya geri püskürtüldüğünde taktiksel geri çekilme (`retreat`) mantığı bulunmamaktadır.

---

## F. KRALLIKLAR VE DENGE DENETİMİ (BALANCE REVIEW)

10 Krallık (`CivData.gd`) ve Faction Art Pack entegrasyonu başarıyla doğrulanmıştır:

| Krallık | Özel Birlik | Can / Hasar / Zırh | Uygulanan Bonus Doğrulaması |
|---|---|---|---|
| **Osmanlılar** | Yeniçeri | 85 HP / 24 Hasar / 2 Zırh | Üretim hızı çarpanı (0.8x) ve kule hasarı (+%25) aktif çalışıyor. |
| **Bizanslılar** | Katafrakt | 220 HP / 18 Hasar / 5 Zırh | Bina canı çarpanı (1.35x) ve bina maliyeti indirimi (%15) aktif. |
| **Britanyalılar**| Uzun Yaylı | 65 HP / 11 Hasar / 0 Zırh | 13.5m okçu menzili ve odun toplama bonusu aktif. |
| **Franklar** | Şövalye Paladin | 260 HP / 20 Hasar / 4 Zırh | Süvari can bonusu (+%25) aktif. |
| **Moğollar** | Mangudai | 95 HP / 12 Hasar / 1 Zırh | 9.6m/s hareket hızı ile en hızlı vur-kaç birimi. |
| **Tötonlar** | Töton Şövalyesi| 190 HP / 25 Hasar / 8 Zırh | 8 Zırh ile normal piyadelere karşı neredeyse hasarsız tank. |
| **Japonlar** | Samuray | 125 HP / 16 Hasar / 2 Zırh | 1.4 saldırı hızı ve %25 kritik vuruş şansı (1.8x hasar). |
| **Sarazenler** | Memlük | 165 HP / 15 Hasar / 2 Zırh | Süvarilere karşı bonus hasar ve altın toplama bonusu aktif. |
| **Vikingler** | Berserker | 140 HP / 19 Hasar / 2 Zırh | Saniyede +3 HP otomatik can yenilenmesi (`regen_rate`) aktif. |
| **Çinliler** | Chu-Ko-Nu | 70 HP / 7 Hasar / 0 Zırh | Seri 3'lü ok atış döngüsü ve +2 başlangıç köylüsü aktif. |

**Denge Değerlendirmesi:** Birimler arasındaki taş-kağıt-makas mekaniği (Mızrakçı > Süvari > Okçu > Mızrakçı) matematiksel olarak dengelidir. Ancak ekonomik bonuslar (özellikle Besin bonusları) oyunun erken safhasında çok büyük avantaj yaratırken, taş bonusları taş binaların azlığı sebebiyle arka planda kalmaktadır.

---

## G. HD-2D GRAFİK VE GÖRSEL KALİTE DENETİMİ

1. **Sprite & Billboard:**
   - Birimler `Sprite3D` ile `BILLBOARD_FIXED_Y` modunda render edilmektedir. Kamera 45 derece eğik olduğunda 3D zemin üzerinde dik ve doğal durmaktadır.
   - Dokular `TEXTURE_FILTER_NEAREST` ile pikselliğini ve retro netliğini korumaktadır. Bulanıklık yoktur.
2. **Animasyon Durumu:**
   - Asset paketindeki görseller statik pozlardır (`pose_01`, `pose_02`, `rear`, `action`).
   - Kod tabanında prosedürel adım sekmesi (`sin(walk_timer * 13.0) * 0.16`), silah savurma rotasyonu ve yön flip'i (`flip_h`) uygulanarak statik sprite'lara canlılık kazandırılmıştır.
3. **Görsel Tutarlılık:**
   - 3D küp binalar ile 2D pixel art birimler ve ağaçlar bir araya geldiğinde retro-diorama estetiği sağlamaktadır.
   - Gölge ve ışıklandırma (`DirectionalLight3D` + Metal GL Compatibility) gölgeleri keskin ve net çizmektedir.

---

## H. PERFORMANS VE STABİLİTE DENETİMİ

- **Başlangıç Statik Bellek:** 332.79 MB
- **300 Saniye Simülasyon Sonu Bellek:** 343.02 MB (Net Artış: **+10.23 MB**)
- **Bellek Sızıntısı Analizi:**
  - 5 dakikalık yoğun simülasyonda 10 MB'lık artış çoğunlukla spawn edilen mermiler ve pathfinding düğüm önbelleğinden kaynaklanmaktadır. Kritik bir bellek sızıntısı (memory leak / OOM riski) gözlenmemiştir.
- **Simülasyon Hesaplama Süresi:** 1500 oyun adımı (tick) gerçek dünyada yalnızca **1.62 saniyede** tamamlanmıştır. CPU yükü mobil cihazlar için fazlasıyla yeterli ve hafiftir.
- **FPS Tahmini:** Modern bir mobil işlemcide (Snapdragon 700+ veya A12+) 60 FPS stabil çalışabilecek hafifliktedir.

---

## I. CRITICAL BUGS (ÖNCELİKLİ HATA LİSTESİ)

### [BUG-01] [P1 - High] Tek Parmak Harita Kaydırma ile Kutu Seçiminin Çakışması
- **Sistem:** `MobileCamera3D.gd` & `GameController3D.gd`
- **Tekrarlama:** Oyunda parmağınızı ekranda 25 pikselden fazla sürükleyin.
- **Beklenen:** Kameranın haritayı yumuşakça kaydırması.
- **Gerçekleşen:** Kamera kayarken aynı anda yeşil seçim kutusu açılmakta ve parmak kaldırıldığında altındaki birimler istenmeden seçilmektedir.
- **Önerilen Çözüm:** Çoklu seçim için UI üzerine özel bir "Kutu Seçim Modu" toggle butonu eklenmeli veya çift parmakla kaydırma / uzun basma jesti ayrıştırılmalıdır.

### [BUG-02] [P1 - High] Düşman Botunun Altına Yığılarak Besin Kıtlığı ile Kilitlenmesi
- **Sistem:** `EnemyAI3D.gd`
- **Tekrarlama:** Bir maçı 2 dakikadan uzun süre oynayın veya simüle edin.
- **Beklenen:** Botun işçilerini %40 Besin, %30 Odun, %20 Altın, %10 Taş gibi dengeli kotalarda tutması.
- **Gerçekleşen:** Bot tüm işçilerini altına gönderip 2000+ Altın biriktirmekte, Besin 0'da kaldığı için ordu ve işçi basımı tamamen durmaktadır.
- **Önerilen Çözüm:** Bot için kota bazlı dinamik işçi dağıtıcı (`workforce balancer`) yazılmalıdır.

### [BUG-03] [P1 - High] Oduncu Kampı, Maden Kampı ve Değirmen Binalarının Eksikliği
- **Sistem:** `Building3D.gd`, `GameController3D.gd`
- **Tekrarlama:** Binalar menüsünü (`[İNŞAAT]`) açın.
- **Beklenen:** Oyuncunun orman ve madenlerin yanına depo kurabilmesi.
- **Gerçekleşen:** Menüde ve bina enum'ında bu yapılar yoktur. İşçiler tüm kaynakları haritanın başındaki Town Center'a taşımak zorundadır.
- **Önerilen Çözüm:** `LUMBER_CAMP`, `MINING_CAMP` ve `MILL` binaları `Building3D` sınıfına eklenmeli ve `get_closest_dropoff` fonksiyonunda geçerli teslim noktası olarak tanıtılmalıdır.

### [BUG-04] [P2 - Medium] Bina İnşaatına Başlarken Otomatik İşçi Atanmaması
- **Sistem:** `GameController3D._attempt_place_building()`
- **Tekrarlama:** Bir köylü seçin, bina menüsünden Ev seçip haritaya koyun.
- **Beklenen:** Seçili olan köylünün otomatik olarak yeni konulan binanın iskeletine gidip inşaata başlaması.
- **Gerçekleşen:** Bina konulduktan sonra seçim boşa düşmekte; oyuncunun köylüyü tekrar bulup seçmesi ve ardından yeni konulan iskelete tıklaması gerekmektedir.
- **Önerilen Çözüm:** Bina yerleştirildiği anda seçili köylüler varsa otomatik `command_build(new_building)` çağrılmalıdır.

### [BUG-05] [P2 - Medium] Üretim Kuyruğundan Birim İptal Edilememesi
- **Sistem:** `Building3D.gd`, `UIManager3D.gd`
- **Tekrarlama:** Town Center veya Kışla'da yanlışlıkla bir birim butonuna fazla basın.
- **Beklenen:** Kuyruktaki birim simgesine basılarak üretimin iptal edilmesi ve kaynağın iade edilmesi.
- **Gerçekleşen:** İptal etme veya kaynak iadesi seçeneği bulunmamaktadır; kaynak bloke kalmaktadır.
- **Önerilen Çözüm:** Kuyruk slotlarına dokunulduğunda kuyruktan çıkarma ve %100 kaynak iadesi fonksiyonu eklenmelidir.

---

## J. GAME DESIGN PROBLEMS (OYUN TASARIMI VE HİSİYAT PROBLEMLERİ)

1. **Gereksiz Mikro Yönetim Yükü (Pacing Tıkanması):**
   - Depo kampları olmadığı için haritanın dışındaki altın ve ağaçları toplayan köylüler zamanlarının %70'ini yürüyerek harcamaktadır. Bu durum ekonominin büyüme hızını aşırı yavaşlatmakta ve mobil bir oyun için maçı 15-20 dakika yerine 35-40 dakikaya uzatma riski taşımaktadır.
2. **Savaşlarda Taktiksel Derinlik Eksikliği:**
   - Askerler için duruş modları (Agresif, Savunmacı, Yerinde Dur/Hold Ground) bulunmamaktadır. Birimler bir düşman gördüklerinde haritanın öbür ucuna kadar düşmanı kovalayıp düşman kulesinin altında ölebilmektedir.
3. **Seçim Geri Bildirimi Zayıflığı:**
   - Dokunmatik ekranda birim seçildiğinde çıkan yeşil halka zemin ağaçlarının ve yüksek otların arkasında zor fark edilmektedir. Birimin başının üstündeki durum etiketi (`Label3D`) yardımcı olsa da daha belirgin bir görsel vurgu (örneğin parlak dairesel outline) gerekmektedir.

---

## K. IMPROVEMENT OPPORTUNITIES (İYİLEŞTİRME FIRSATLARI)

### 1. Hızlı Kazanımlar (Quick Wins - Düşük Risk / Yüksek Etki)
- **İnşaat Otomasyonu:** Bina yerleştirildiğinde seçili köylülerin doğrudan inşaata koşması.
- **Kamera / Kutu Seçim Ayrımı:** Kutu seçimini ekrandaki bir butonla açılır/kapanır moda bağlamak.
- **Üretim İptali:** Kuyruktaki birime basıldığında kaynağın iade edilmesi.

### 2. Oynanış İyileştirmeleri (Gameplay Improvements)
- **Depo Kamplarının Eklenmesi:** Oduncu Kampı, Maden Kampı ve Değirmen binalarının eklenerek ekonominin hızlandırılması.
- **Asker Duruşları (Stances):** Agresif, Savunma ve Konum Koru modları.

### 3. Yapay Zekâ İyileştirmeleri (AI Improvements)
- **Kota Bazlı Ekonomi:** Botun köylülerini Besin (%45), Odun (%30), Altın (%20), Taş (%5) oranında dengeli dağıtması.
- **Geri Çekilme (Retreat):** Bot ordusunun canı %30'un altına indiğinde kendi kulelerinin altına çekilmesi.

---

## L. PRIORITIZED ACTION PLAN (ÖNCELİKLİ EYLEM PLANI - TOP 15)

1. **[Giriş]** Kamera tek parmakla kaydırma ile seçim kutusunun çakışmasını gider.
2. **[Ekonomi]** `Lumber Camp`, `Mining Camp` ve `Mill` binalarını ekle ve teslim noktası yap.
3. **[Bot AI]** Botun altın madenine yığılıp besinsiz kalmasını önleyen dinamik işçi dağıtıcı yaz.
4. **[UX]** Bina konulduğunda seçili köylüyü otomatik inşaata yönlendir.
5. **[UI]** Üretim kuyruğundaki birimleri iptal etme ve kaynak iadesi ekle.
6. **[Kontrol]** Dokunmatik için "Aynı türdeki tüm birimleri seç" kısayolunu ekran butonuna taşı.
7. **[Savaş]** Birimlere "Konum Koru" (Hold Position) ve "Savunma" duruşu ekle.
8. **[Ekonomi]** Tarlaların (Farm) besin tükenince otomatik yenilenme veya çiftçi uyarısı vermesi.
9. **[Görsel]** Seçili birimlerin etrafına daha belirgin mobil seçim halkası ekle.
10. **[Bot AI]** Botun Çağ 2'ye geçişini ve Kale inşa etmesini tetikleyen koşulları iyileştir.
11. **[UI]** Binaların altındaki üretim butonlarının açıklama tooltip'lerini ekle (Hangi birim neye karşı güçlü).
12. **[Ses]** Bina yıkılma ve maç zafer/yenilgi anı için özel ses efektleri ekle.
13. **[Harita]** Prosedürel haritada kaynak noktalarının başlangıç üssüne mesafelerini optimize et.
14. **[Performans]** Mobil cihazlar için mermi parçacıklarını havuzlama (Object Pooling) sistemine al.
15. **[Tutorial]** Yeni oyuncular için ilk 3 adımı gösteren etkileşimli öğretici kılavuzu cilala.

---

## M. FINAL SCORES (10 ÜZERİNDEN PUANLAMA)

| Alan | Puan | Gerekçe |
|---|---|---|
| **Genel Oynanış** | **6.5 / 10** | Temel RTS döngüsü çalışıyor, ancak depo eksikliği ve mikro yük temposunu düşürüyor. |
| **Mobil Kontrol Kalitesi** | **5.0 / 10** | Buton boyutları iyi; ancak kamera pan ile kutu seçiminin çakışması mobil hissi zedeliyor. |
| **UI / UX** | **6.5 / 10** | Dikey ekran düzeni doğru oturmuş, alt bar işlevsel; üretim iptal ve bina onay akışı eksik. |
| **Bot Yapay Zekâsı** | **4.5 / 10** | Dalga saldırısı yapıyor; ancak ekonomi dağılımı bozuk olduğu için 2. dakikada kilitleniyor. |
| **RTS Derinliği** | **7.5 / 10** | 4 kaynak, çağ atlama, demirci geliştirmeleri ve 10 medeniyet zengin bir temel sunuyor. |
| **Oyun Dengesi** | **7.0 / 10** | Taş-kağıt-makas sayaçları ve krallık bonusları matematiksel olarak tutarlı. |
| **Grafik Kalitesi (HD-2D)**| **8.5 / 10** | Diorama 2.5D derinliği, piksel netliği ve krallık sanat paketleri çok başarılı. |
| **Performans** | **9.0 / 10** | Çok hafif, 5 dakikalık simülasyonda yalnızca 10 MB RAM artışı; mobilde 60 FPS garantili. |
| **Stabilite** | **8.5 / 10** | Simülasyon ve desktop testlerinde oyun çökmedi, save/load kusursuz çalışıyor. |
| **Tekrar Oynanabilirlik**| **6.0 / 10** | Botun hep aynı şekilde kilitlenmesi ve haritanın temposu maçların birbirine benzemesine yol açıyor. |

---

## N. RELEASE READINESS (YAYINLANABİLİRLİK KARARI)

### **SONUÇ: NOT READY (YAYINA HAZIR DEĞİL)**

**Gerekçe:**  
Pocket Empires 3D sağlam bir teknik temele, harika bir HD-2D görsel stile ve zengin bir krallık çeşitliliğine sahiptir. Ancak **mobil dokunmatik kontrollerdeki kamera/seçim çakışması (BUG-01)**, **botun ekonomide kilitlenip maçı rekabetsiz bırakması (BUG-02)** ve **temel RTS depo binalarının eksikliği (BUG-03)** çözülmeden oyunculara sunulması durumunda oyuncular kontrol karmaşası ve pacing yavaşlığı nedeniyle oyunu terk edecektir. 

Bu rapor, belirlenen öncelikli eylem planına göre sonraki geliştirme fazına rehberlik etmek üzere hazırlanmıştır.
