# GÖREV — Pocket Empires 3D: Krallığa Özel Bina Görsellerini Godot 4'e Entegre Et

Mevcut mobil Godot 4 RTS oyununda, daha önce oluşturulmuş 10 krallık köylü/asker görselleri ile **uyumlu mimari görselleri** kullan. Bu paket içinde 140 şeffaf görsel ve daha ayrıntılı mimari referanslar var.

## Önce tam olarak oku

- `README.md`
- `data/building_art_manifest.json`
- `previews/ALL_FACTIONS_BUILDINGS.jpg`
- `art/concept_references/` içindeki 3 ayrıntılı konsept atlası.
- Mevcut oyunda `Building3D.gd`, fraksiyon verileri (`CivData.gd` gibi), building factory/creation, scene, construction, map, navigation, input, AI, production, save/load ve kamera kodları.

**Kural:** Bu prompt bir sanat/görsel entegrasyon görevidir; oyun mekaniklerini sessizce değiştirme. Daha önce belirlenen `PHASE1_FIX_VALIDATION` iyileştirmeleri devam ediyorsa değişikliklerle çakışma yaratma; kullanıcı değişikliklerini koru.

## Gerçek asset türlerini karıştırma

- `art/buildings/.../*.png`: **384×384, şeffaf, tek poz**. Godot 2.5D dünyasında kullanılabilecek sade sprite görselleri.
- `art/detailed_reference_crops/`: **KÜÇÜK, OPAK, referans**. Üstlerinde eski arka plan bulunur. Bunları oyun sprite'ı diye kullanma.
- `art/concept_references/`: AI tarafından çizilmiş **ayrıntılı konsept atlasları**. Sprite atlası/3D mesh değildir.

## Krallıklar ve bina türleri

Krallık ID'leri: ottomans, byzantines, britons, franks, mongols, teutons, japanese, saracens, vikings, chinese.
Bina ID'leri: town_center, house, barracks, archery_range, stable, blacksmith, castle, watch_tower, lumber_camp, mining_camp, mill, farm, market, stone_wall.

## Görevler

1. Mevcut kodda gerçek `faction_id` ve `building_type` değerlerini keşfet. ID'leri tahmin etme. `data/building_art_manifest.json` ile gerçek bir eşleme oluştur.
2. Mevcut `Building3D` entity'lerinin yalnızca görünüş katmanını güncelle. `Sprite3D` / `Node3D` impostor yaklaşımını kullanabilirsin. **Bina collider'ı, yürüme engeli, grid footprint, HP, maliyet, üretim kuyruğu, hasar, inşaat ve bot AI mantığı korunmalı.**
3. Krallık seçildiğinde o krallığın Ana Merkez, Ev, Kışla, Okçuluk Alanı, Ahır, Demirci, Kale, Kule, Oduncu Kampı, Maden Kampı, Değirmen, Çiftlik, Pazar ve Taş Duvar görsellerini doğru bağla. Yalnızca oyunda gerçekten bulunan tipleri oyun mekaniğine ekle; yeni bir tip sadece görselde var diye mekanik olarak oluşturulmasın.
4. Bina sahipliği/krallık değişimi ve yüklenen save'ler doğru görselleri göstermeli. Bot binaları botun krallığına ait görünmeli.
5. 2.5D kamera açısını, `Sprite3D` ayak pivotunu, pixel size/scale, depth sorting, z-fighting, gölge ve birimlere göre bina boyutlarını kontrol et. Çok yakınlaştırınca pixel-density aynı olmalı; yeterli zoom-out'ta da okunabilir kalmalı.
6. Mevcut `CollisionShape3D`'yi sprite'ın dekorasyonlarından (gölge, bayrak, çatı, minare, ağaç) türetme. Gameplay collision ile görsel sınırı ayır.
7. Bina seçim halkası, sağlığı, inşa önizlemesi (ghost), geçersiz konum rengi, tamamlama, hasar, yıkılma ve varsa animasyon sistemlerini koru. Yeni binaların görsel ölçeği collision/navigation footprint ile uyumlu olmalı.
8. Kaynak depoları: Lumber Camp, Mining Camp, Mill oyunda kodda eksikse bunların sprite entegrasyonunu hazır tut, fakat mekaniğin ayrı geliştirilmesi gerektiğini açıkça belirt. Eğer Phase 1 çalışmasıyla eklendilerse çalıştığını doğrula.
9. Eğer ayrıntılı konsept poster kalitesinin mevcut sade sprite'lardan daha yüksek olması gerekiyorsa, nihai üretim kalite farkını açıkça raporla. Opak referansları arka planıyla sahneye koyarak geçiştirme.
10. Menülerde uygun bina küçük resimleri gerekiyorsa PNG'leri tekrar kullan; farklı, tutarsız ikonlar üretme.

## NEGATİF TALİMATLAR

- Faction değişince tek tip bina gösterme; her krallık için kendi varyantını kullan.
- Opak atlas kesitlerini sanki transparan sprite'mış gibi sahneye koyma.
- Statik görselleri gerçek 3D model veya hareketli animasyon olarak gösterme.
- Existing `Building3D` collision/Navigation kodunu görsel katman uğruna bozmaya çalışma.
- Bina HP/maliyet/üretim parametrelerini değiştirme.
- Bina türlerinin enum ordinal değerlerini eski save'leri kıracak şekilde değiştirme.
- Bina sprite'larını alakasız şekilde büyütüp küçültme.
- Ağır shader, agresif bloom, gereksiz material instance veya sürekli resource reload oluşturma.
- Daha önce düzeltilmiş kamera, çoklu seçim, resource toplama veya AI davranışlarını bozma.
- Test silme/atlama, gerçek cihaz testi yapılmadan başarı rapor etme.
- Commit/push/merge yapma.

## ZORUNLU TEST MATRİSİ

- `python tools/verify_pack.py` sonucu PASS.
- Godot project import; hatasız `.png` ve `res://` asset yolları; parser/scene hatası yok.
- 10 krallığın her biri için mevcut tüm bina türlerinde doğru sprite yüklendi (manifest karşılaştırması ve görsel screenshot).
- Başlangıç üssü, bina inşaatı, ghost preview, kaynak binaları, askeri bina üretimi, kule saldırısı ve castle unique unit üretimi çalışıyor.
- Bina yıkımı sonrası collider/navigation/selection sorun yok.
- Save/load: faction, building type ve görünüm doğru.
- Bot ile tam maçta kendi krallık mimarisi doğru.
- Zoom-in/zoom-out, kamera kaydırma, mobil portrait sahne ve mümkünse Android emulator/real device.
- 20+ bina ve 50+ unit ile gerçek FPS ve frame-time ölçümleri. Ölçüm yoksa tahmin etme.
- Oyun mekaniklerine ait önceki otomatik regresyonlar yeşil.

## SON RAPOR

`docs/audits/BUILDING_ART_INTEGRATION_REPORT.md` oluştur:

- Uygulanan bina ID / faction ID eşleştirmesi
- Değiştirilen sahne/scriptler
- Görsel QA görüntüleri (mümkünse 10 krallık için en az 1 kare)
- Godot import ve build sonuçları
- Eski gameplay regresyonları
- Kalan eksik animasyonlar / çok yönlü sprite sorunları
- Mobil performans ölçümü veya test edilemedi açıklaması
- READY / NOT READY ve gerekçeleri

**Amaç:** Görsel olarak farklı 10 kültürün bina mimarisini mevcut Godot RTS oyununa entegre et, çalışan oyun döngüsünü kesinlikle bozma; ayrıntılı konsept ile sade şeffaf sprite'lar arasındaki farkı saklama.
