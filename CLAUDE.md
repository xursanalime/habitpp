# Habitpp — IELTS bosim ilovasi

Faqat bitta foydalanuvchi (Xursanali) uchun shaxsiy ilova: imtihongacha (2026-12-30) har kuni IELTS o'qishga majburlaydi.

## Stack
- Flutter: Ubuntu (linux) va Android, bitta kod bazasi
- Lokal: SQLite (offline-first)
- Sinxron: Cloudflare Workers + D1 (2-bosqich)
- Login yo'q, maxfiy kalit bilan

## Muhit
- Flutter SDK: `~/development/flutter/bin` (PATH'da bo'lmasa to'liq yo'l bilan chaqiring)
- Android SDK: `~/Android/Sdk` (`ANDROID_HOME`)
- Kompyuterda ~7 GB RAM bor: Android emulyator ishlatilmaydi, USB orqali Samsung telefonda sinaladi

## Bosqichlar
0. O'rnatish va "Salom" ilovasi
1. Lokal MVP: bugungi reja, dalil bilan belgilash, sanoq, qarz
2. Sinxron: Worker + D1
3. Bosim funksiyalari: Telegram hisobot 20:59, Ubuntu avtostart, 2 kun qoidasi, yakshanba auditi, grafiklar
4. Ishga tushirish: imzolangan APK, .deb + avtostart, keystore zaxirasi
5. Imtihongacha funksiyalar muzlatiladi, faqat xatolar tuziladi

## Qoidalar
- Faqat 18:00–22:00 dasturlash vaqtida ishlanadi; bosqich 1 kechadan ortiq cho'zilsa, funksiya qisqartiriladi
- Har mantiqiy qadamdan keyin commit + push
- Maxfiy kalitlar (Telegram token, sinxron kaliti, keystore) hech qachon repoga tushmaydi
- Bildirishnoma kuniga faqat bitta (20:45)
- UI tili: o'zbekcha
