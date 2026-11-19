-- Telekom Müşteri Kaybı Analizi | MySQL sorguları
-- Şema: telekom_analizi | Tablo: telco_customer_churn_duzeltme
-- TotalCharges içindeki 11 eksik kayıt içe aktarıma göre NULL, boş metin veya 'EKSİK' olabilir.
-- CSV'yi MySQL'e ilk aktarırken customerID sütun adı BOM nedeniyle bozulmuşsa,
-- önce SHOW COLUMNS FROM telco_customer_churn_duzeltme ile ilk alanı kontrol edin.
-- Sütun gerçekten `ï»¿customerID` ise bir kez şu düzeltmeyi uygulayın:
-- ALTER TABLE telco_customer_churn_duzeltme
-- CHANGE COLUMN `ï»¿customerID` customerID VARCHAR(10) NOT NULL;

USE telekom_analizi;

-- 1) Kayıt sayısı (beklenen: 7043)
SELECT COUNT(*) AS toplam_musteri
FROM telco_customer_churn_duzeltme;

-- 2) Eksik TotalCharges etiketi sayısı (beklenen: 11)
SELECT COUNT(*) AS eksik_total_charges
FROM telco_customer_churn_duzeltme
WHERE TotalCharges IS NULL
   OR TRIM(CAST(TotalCharges AS CHAR)) IN ('', 'EKSİK');

-- 3) Churn dağılımı: müşteri sayısı ve tüm müşteriler içindeki pay
SELECT Churn, COUNT(*) AS musteri_sayisi,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM telco_customer_churn_duzeltme), 2) AS toplam_icindeki_yuzde
FROM telco_customer_churn_duzeltme
GROUP BY Churn;

-- 4) Yinelenen customerID sayısı (beklenen: 0)
SELECT COUNT(*) AS yinelenen_musteri_kimligi
FROM (
    SELECT customerID FROM telco_customer_churn_duzeltme
    GROUP BY customerID HAVING COUNT(*) > 1
) AS tekrarlar;

-- 5) Cinsiyete göre hem grup içi churn oranı hem de ayrılanlardaki cinsiyet payı
SELECT gender, COUNT(*) AS toplam_musteri,
       SUM(Churn = 'Yes') AS ayrilan_musteri,
       ROUND(100.0 * SUM(Churn = 'Yes') / COUNT(*), 2) AS grup_icindeki_churn_yuzdesi,
       ROUND(100.0 * SUM(Churn = 'Yes') /
           (SELECT COUNT(*) FROM telco_customer_churn_duzeltme WHERE Churn = 'Yes'), 2) AS ayrilanlardaki_cinsiyet_yuzdesi
FROM telco_customer_churn_duzeltme
GROUP BY gender;

-- 6) Sözleşme türü
SELECT Contract, COUNT(*) AS toplam_musteri,
       SUM(Churn = 'Yes') AS ayrilan_musteri,
       ROUND(100.0 * SUM(Churn = 'Yes') / COUNT(*), 2) AS churn_orani_yuzde
FROM telco_customer_churn_duzeltme
GROUP BY Contract ORDER BY churn_orani_yuzde DESC;

-- 7) Müşteri kıdemi: 0-12, 13-24, 25-48 ve 49-72 ay
SELECT CASE WHEN tenure <= 12 THEN '0-12 ay'
            WHEN tenure <= 24 THEN '13-24 ay'
            WHEN tenure <= 48 THEN '25-48 ay'
            ELSE '49-72 ay' END AS tenure_grubu,
       COUNT(*) AS toplam_musteri, SUM(Churn = 'Yes') AS ayrilan_musteri,
       ROUND(100.0 * SUM(Churn = 'Yes') / COUNT(*), 2) AS churn_orani_yuzde
FROM telco_customer_churn_duzeltme
GROUP BY tenure_grubu ORDER BY MIN(tenure);

-- 8) SeniorCitizen (yaş aralığı değil, 0/1 göstergesi) ve Dependents
SELECT SeniorCitizen, Dependents, COUNT(*) AS toplam_musteri,
       SUM(Churn = 'Yes') AS ayrilan_musteri,
       ROUND(100.0 * SUM(Churn = 'Yes') / COUNT(*), 2) AS churn_orani_yuzde
FROM telco_customer_churn_duzeltme
GROUP BY SeniorCitizen, Dependents ORDER BY churn_orani_yuzde DESC;

-- 9) Teknik destek hizmeti
SELECT TechSupport, COUNT(*) AS toplam_musteri,
       SUM(Churn = 'Yes') AS ayrilan_musteri,
       ROUND(100.0 * SUM(Churn = 'Yes') / COUNT(*), 2) AS churn_orani_yuzde
FROM telco_customer_churn_duzeltme
GROUP BY TechSupport ORDER BY churn_orani_yuzde DESC;

-- 10) İnternet hizmeti
SELECT InternetService, COUNT(*) AS toplam_musteri,
       SUM(Churn = 'Yes') AS ayrilan_musteri,
       ROUND(100.0 * SUM(Churn = 'Yes') / COUNT(*), 2) AS churn_orani_yuzde
FROM telco_customer_churn_duzeltme
GROUP BY InternetService ORDER BY churn_orani_yuzde DESC;

-- 11) Ödeme yöntemi
SELECT PaymentMethod, COUNT(*) AS toplam_musteri,
       SUM(Churn = 'Yes') AS ayrilan_musteri,
       ROUND(100.0 * SUM(Churn = 'Yes') / COUNT(*), 2) AS churn_orani_yuzde
FROM telco_customer_churn_duzeltme
GROUP BY PaymentMethod ORDER BY churn_orani_yuzde DESC;

-- Bunlar betimleyici grup karşılaştırmalarıdır; nedensellik kanıtlamaz.
