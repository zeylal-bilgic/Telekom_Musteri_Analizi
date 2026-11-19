from pathlib import Path
import pandas as pd

# Ham veri klasörünün konumu
proje_klasoru = Path(__file__).resolve().parent.parent
ham_veri_klasoru = proje_klasoru / "02_Veri" / "Ham"

print("Ham veri klasörü:", ham_veri_klasoru)
print("Klasör mevcut mu?", ham_veri_klasoru.is_dir())

# CSV dosyasının bulunması
csv_dosyalari = list(ham_veri_klasoru.glob("*.csv"))
print("Bulunan CSV sayısı:", len(csv_dosyalari))

if len(csv_dosyalari) != 1:
    raise ValueError("Ham klasöründe tam olarak bir CSV dosyası olmalı.")

print("Dosya adı:", csv_dosyalari[0].name)

# CSV dosyasının okunması
veri = pd.read_csv(csv_dosyalari[0])

print("Satır sayısı:", veri.shape[0])
print("Sütun sayısı:", veri.shape[1])

# Sütun adlarının gösterilmesi
print("\nSütun adları:")

for sira, sutun in enumerate(veri.columns, start=1):
    print(f"{sira}. {sutun}")

# Veri yapısının gösterilmesi
print("\nVeri türleri ve dolu kayıt sayıları:")
veri.info()

# Toplam ücret alanının incelenmesi
print("\nToplam ücret alanındaki ilk 10 değer:")

for deger in veri["TotalCharges"].head(10):
    print(repr(deger))
bos_ucret_kontrolu = veri["TotalCharges"].astype("string").str.strip().eq("").fillna(False)

print("\nBoş veya yalnızca boşluk içeren toplam ücret sayısı:")
print(bos_ucret_kontrolu.sum())

print("\nBu koşula uyan kayıtlar:")
print(
    veri.loc[
        bos_ucret_kontrolu,
        ["customerID", "tenure", "MonthlyCharges", "TotalCharges"]
    ]
)
ucret_sayisal_kontrol = pd.to_numeric(
    veri["TotalCharges"],
    errors="coerce"
)

donusemeyenler = ucret_sayisal_kontrol.isna()

print("\nSayıya dönüştürülemeyen toplam ücret sayısı:")
print(donusemeyenler.sum())

print("\nBoş metin dışında dönüştürülemeyen değer sayısı:")
print((donusemeyenler & ~bos_ucret_kontrolu).sum())
temiz_veri = veri.copy()
temiz_veri["TotalCharges"] = pd.to_numeric(
    temiz_veri["TotalCharges"],
    errors="coerce"
)

print("\nTemiz veri kopyasının satır sayısı:")
print(temiz_veri.shape[0])

print("\nTotalCharges eksik değer sayısı:")
print(temiz_veri["TotalCharges"].isna().sum())

print("\nTotalCharges veri türü:")
print(temiz_veri["TotalCharges"].dtype)
print("\nSütunlara göre eksik değer sayıları:")
print(temiz_veri.isna().sum())

print("\nYinelenen müşteri numarası sayısı:")
print(temiz_veri["customerID"].duplicated().sum())
churn_sayilari = temiz_veri["Churn"].value_counts()
churn_oranlari = temiz_veri["Churn"].value_counts(normalize=True) * 100

churn_ozeti = pd.DataFrame({
    "Müşteri sayısı": churn_sayilari,
    "Oran (%)": churn_oranlari.round(2)
})

print("\nAyrılan ve ayrılmayan müşterilerin genel dağılımı:")
print(churn_ozeti)
temiz_veri_klasoru = proje_klasoru / "02_Veri" / "Temiz"
temiz_veri_klasoru.mkdir(parents=True, exist_ok=True)

cikti_dosyasi = temiz_veri_klasoru / "telco_customer_churn_temiz.csv"
temiz_veri.to_csv(cikti_dosyasi, index=False, encoding="utf-8-sig")

print("\nTemiz veri dosyası kaydedildi:")
print(cikti_dosyasi)
print("Satır sayısı:", temiz_veri.shape[0])
print("Sütun sayısı:", temiz_veri.shape[1])
sql_aktarim_verisi = temiz_veri.copy()
sql_aktarim_verisi["TotalCharges"] = (
    sql_aktarim_verisi["TotalCharges"].astype("object")
)
sql_aktarim_verisi["TotalCharges"] = sql_aktarim_verisi[
    "TotalCharges"
].where(
    sql_aktarim_verisi["TotalCharges"].notna(),
    "EKSİK"
)

sql_aktarim_dosyasi = (
    temiz_veri_klasoru / "telco_customer_churn_sql_aktarim.csv"
)
sql_aktarim_verisi.to_csv(
    sql_aktarim_dosyasi,
    index=False,
    encoding="utf-8"
)

print("\nSQL aktarımı için hazırlanan dosya:")
print(sql_aktarim_dosyasi)
print("Toplam satır:", sql_aktarim_verisi.shape[0])
print(
    "EKSİK etiketi verilen ücret sayısı:",
    (sql_aktarim_verisi["TotalCharges"] == "EKSİK").sum()
)
