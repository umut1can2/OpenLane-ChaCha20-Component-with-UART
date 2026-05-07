# OpenLane-ChaCha20-Component-with-UART

ChaCha 20 sifreleme algoritmasinin OpenLane ve Skywater 130nm PDK'lari ile uretilmis(hardened module) hali.


## Ana Mimari
Proje de paralellik anlaminda 4 Adet `QuarterRound` modulu kullaniliyor(Bu sayede normalde 80cycle surecek Round islemleri 20 cycle a dusmus oluyor).
Giris ve cikislarin yonetilmesiyle ilgili olarak `UART` modulleri kullanilmakta. Bu verimi dusurse de projenin uygulanabilirligi noktasinda ilk ve en basit buldugum cozum oldu.


## Sentez Sonuclari
Sentez sonucunda her hangi bir negative setup veya hold slack durumuyla karsilasmadim. `manufacturability.rpt` dosyasinda da her hangi bir error mevcut degil. Log dosyalarindan aldigim bazi veriler altta mevcut.

| Metric | Value | Result |
| :--- | :--- | :--- |
| **WNS (Setup)** | 14.23 ns | +> 7Mhz eklenebilir |
| **WNS (Hold)** | 0.17 ns | |
| **Total Cells** | 18,934 | |
| **Sequential (FF)** | 3,307 (17.4%) | |
| **DRC / LVS** | 0 Violations | |
| **Chip Area** | ~0.217 mm² | |


---
### 📊 Verim (Throughput) Analizi

Bu bölümde, tasarlanan **ChaCha20 Core** ünitesinin ham işlem gücü ile **UART** arayüzünden kaynaklanan darboğazın (bottleneck) teknik karşılaştırması yer almaktadır.

#### 1. Donanım Kapasitesi (Core Performance)
Sistem `UART` sinirlamasi olmadan assagi daki gibi calismakta.

* **Islem icin Harcanan Clock Cycle:** 64 Byte blok başına **~24 clock cycle**.
* **Varsayilan Calisma Frekansi:** 20 MHz.
* **Islenen Blok Sayisi:** $20.000.000 / 24 \approx \mathbf{833.333 \text{ blok/saniye}}$
* **Teorik Hiz (Throughput):** $833.333 \times 512 \text{ bit} \approx \mathbf{426,6 \text{ Mbps}}$ (~53,3 MB/s).

#### 2. UART Darbogazi
`UART` sistemi varsayilan olarak 115_200 Baud'da calismakta. Buna bagli olarak alinan ve gonderilen veriler sistemi bir darbogaza sokuyor ve verimi ciddi olcude dusuruyor.

* **UART Gecikmesi:** 20MHz ile 1 byte transferi yaklasik olarak **~1730 cycle** suruyor.
* **Islenen Blok Sayisi:** ~180
* **Teorik Hiz (Throughput):** Yaklaşık **0,011 Mbps** (~11,5 KB/s).

---

### Performans Tablosu

| Metrik |  CORE | UART+CORE | FARK Oranı |
| :--- | :--- | :--- | :--- |
| **Blok/saniye** | 833.333 Blok | ~180 Blok | **~4600x yavaslama** |
| **Veri Yolu Genişliği** | **426,6 Mbps** | **0,011 Mbps** | **~38.000x Kayıp** |
| **Verimlilik** | %100 Kapasite | < %0,02 Kapasite | **I/O Sınırlı** |


### State Machine Diyagrami
---
![FSM Diagram](img/StateMachineDiagram.png)



## GDSII Ciktisi
![GDS Layout View](img/gdsii)
