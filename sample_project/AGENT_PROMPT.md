# AI AGENT GÖREVİ — Pocket Empires Godot 4 Faction Art Entegrasyonu

Mevcut Godot tabanlı mobil RTS oyunumun grafiklerini bu ZIP içindeki assetlerle güncelle. Var olan 10 krallığın isimlerini, kimliklerini, güçlerini, oyun içi veri modellerini ve oynanış mantığını koru. Bu işin kapsamı **görsel entegrasyon**, yeni oyun mekanikleri oluşturmak değil.

## Önce incele

- Projedeki Godot sürümünü, 2D/3D entity/scene yapısını, mevcut sprite/render sistemini ve animasyon akışını incele.
- Halihazırdaki birim/köylü/ordu veri kimliklerini, üretim sistemlerini ve fraksiyon configlerini haritalandır.
- Bunlar birleştirilirken hiçbir üretim maliyeti, hasar, hız, bonus veya AI kuralı sessizce değişmemeli.

## Paketin gerçek durumu

- `art/concept_sheets/` tam çözünürlüklü 10 görsel konsept sheet içerir.
- `data/faction_art_manifest.json` 10 krallık ve 50 birim için asset yollarını içerir.
- `art/units/<faction>/<role>/pose_01.png` birim başına şeffaf statik sprite.
- `pose_02`, `rear_reference`, `action_reference` farklı görsel referanslardır. Bunları yürüme/saldırı animasyonunun zaman dizisiymiş gibi kullanma.
- Bunlar **nihai temiz sprite atlası değildir**. Maskelenmiş bazı kenarlar manuel temizlenmelidir.

## Uygulama

1. Manifesti mevcut fraksiyon ve birim veri modeliyle eşleştir. ID'leri oyunda halihazırda kullanılan isimlerle eşleştir, gerekirse açıkça belgelenmiş mapping tablosu kullan.
2. Yeni sprite dosyalarını mevcut entity görsel sahnelerine, sahne davranışını bozmadan bağla. Godot `Sprite2D`, `AnimatedSprite2D` veya `Sprite3D` seçimi mevcut sahne mimarisine uygun olmalı.
3. 3D HD-2D diorama dünyasında 2D sprite gerekiyorsa uygun `Sprite3D`/billboard kullanımını değerlendirmeli, sabit RTS kamera açısını ve birimin ayak noktasını korumalısın. Gereksiz yere tüm projeyi 3D'ye taşıma.
4. Uygun nearest-neighbor sampling, doğru dünya ölçeği, z-index/y-sort, ayak pivotu, seçim halkası ve gölge düzenini kur.
5. Farklı faction birimleri yakınlaştırma/uzaklaştırmada ayırt edilebilir olmalı. Köylü, piyade, mızrakçı, okçu, elitler okunmalı.
6. Var olan animasyonları, sırf bu pakette kareler eksik diye silme. Yeni sprite'ları şimdilik portrait/ikon/statik idle yerine kullanabilir, çalışan yürüyüş-savaş animasyonlarını koruyabilirsin. Eksik animasyonların gerçek yönlü sprite frame'lerini ayrı üretim işi olarak raporla.
7. Ayrı bir preview scene ya da geliştirici menüsü ile tüm 10 faction / 50 rol görsellerini gözden geçir.
8. Bazı posterlerdeki bayrak/arma tasarımlarını oyunda birebir sürdürmek istiyorsan source sheet'ten temiz ayrı dosyalara çıkartıp kontrol et; resmi/historik kesinlik iddiasında bulunma.

## Negatif talimatlar

- Statik görselleri gerçek animasyon varmış gibi sunma.
- Eksik yön animasyonunu sprite'ı rastgele çevirerek tamamen çözülmüş kabul etme.
- Poster içindeki metinleri karakter sprite'ına dahil etme.
- Görsel amaçlı değişiklik için savaş, kaynak, kazanma ve AI sistemlerini yeniden yazma.
- Asset isimlerini rastgele üretme veya veri ID'sini varsayımla eşleştirme.
- Yürüyüş sırasında sprite'ları kameraya yanlış yönlendirip sırtını göstermesini sağlama.
- Sprite'ların bir kısmını 3D gerçekçi, bir kısmını HD-2D bırakma.
- Pixel art'a lineer filtre ile bulanıklık uygulama (gerekli özel ölçek durumları dışında).
- Görsel FPS sorunu çıkartacak ağır shader'lar ekleme.
- Mevcut testleri atlama/silme; başarı uydurma.

## Zorunlu testler

- `python tools/verify_pack.py` çalıştır ve sonuçları kontrol et.
- Godot editor import ve headless çalıştırma (mevcut ortam destekliyorsa) ile resource path ve script syntax hatalarını tespit et.
- 10 krallığın tümü için 5 rolün render edildiğini doğrula.
- Savaşta en az 20 birimin aynı anda görünmesini ve seçim halkası/HP bar'larının doğru hizalandığını doğrula.
- Mobil landscape viewport, zoom-in/out, hareket, saldırı ve animasyon regresyonlarını test et.
- Birim silahları ve sprite kenarları için görsel QA yap; sorunlu sprite'ları raporla.
- Kaynak toplama, asker üretme, ordu hareketi, AI savaşı ve maç sonu testlerini tekrar çalıştır; değişiklikler gameplay'yi bozmamalı.
- Tamamlanmamış animasyonları veya gerçek cihazda doğrulanmamış performansı tamamlandı diye raporlama.

**Çıktı**: uygulanan dosyalar, ID mapping, doğrulanan 50 sprite, eksik animasyonlar, test logları, ölçülen performans ve bilinen görsel kusurları içeren ayrıntılı rapor.
