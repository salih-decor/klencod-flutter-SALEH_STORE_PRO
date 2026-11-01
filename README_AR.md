# SALEH STORE PRO — المرحلة الأولى

مشروع Flutter مبدئي لإدارة محل صالح للهدايا والتحف، مع تسجيل دخول Google للمدير والبريد/كلمة المرور للعامل، ومبيعات ومنتجات وطلبات وناقلين ولوحة إحصاءات.

## تجهيز بيئة التطوير
1. ثبّت Flutter SDK وAndroid Studio وJDK المتوافق، ثم نفّذ `flutter doctor`.
2. أنشئ مشروع Flutter أصليًا على جهازك: `flutter create --platforms android saleh_store_pro`.
3. انسخ ملفات `lib/` و`pubspec.yaml` من هذه الحزمة إلى المشروع الأصلي (واحتفظ بملفات android/ التي أنشأها Flutter).
4. داخل المشروع: `flutter pub get`.
5. أنشئ مشروع Firebase واربط تطبيق Android بحزمة Android التي تختارها.
6. ثبّت FlutterFire CLI وشغّل `flutterfire configure` داخل المشروع، ثم راجع إعدادات Android الخاصة بـ Google Sign-In (SHA-1/SHA-256) وفعّل Google وEmail/Password من Firebase Authentication.
7. أنشئ Cloud Firestore وانشر قواعد `firebase/firestore.rules` من Firebase Console. لا تنشر قواعد تسمح للجميع بالقراءة/الكتابة.
8. **تهيئة المدير أول مرة:** سجّل الدخول بحساب Google، ثم من Firebase Authentication انسخ UID لهذا الحساب. من Firebase Console أنشئ وثيقة `users/{UID}` بالقيم: `role: 'owner'` (string) و`active: true` (boolean). لا تُنشئ وثيقة مدير لأي حساب غير موثوق. قواعد Firestore لا تسمح للمستخدم بترقية نفسه.
9. **تهيئة العامل:** أنشئ حساب Email/Password له من Firebase Authentication (بواسطة المدير في Firebase Console)، ثم أنشئ `users/{UID}` بالقيم `role: 'worker'`, `active: true`. لا تضع كلمة المرور في قاعدة البيانات.
10. أضف منتجين من داخل التطبيق بحساب المدير: `صور الهوية — Hiti P510` بسعر `400`، و`صور الهوية — EPSON L3210` بسعر `400`. الأسعار قابلة للتعديل في Firebase Console في المرحلة الأولى؛ واجهة تعديل السعر لاحقًا.
11. للتجربة: `flutter run`. لإنشاء APK: `flutter build apk --release`. قبل التوزيع الحقيقي، اضبط توقيع إصدار Android وراجع الأذونات وسياسة حماية البيانات.

## ما يعمل في هذه النسخة
- دخول Google أو Email/Password بعد إعداد Firebase، مع حظر المستخدم غير المفعّل.
- عرض مبيعات اليوم والأسبوع، وسجل منتجات، وسلة متعددة الكميات وتسجيل بيع نقدي كامل.
- إضافة منتجات (المدير فقط)، وإضافة طلبات مع تسبيق ومبلغ متبقٍّ، واختيار منطقة، ودليل الناقلين.
- المزامنة المباشرة عبر Firestore، وفق اتصال الإنترنت وإعدادات SDK.

## ما لم يكتمل بعد
- لا تحتوي الحزمة على ملفات Android المولّدة أو إعدادات Firebase الخاصة بك؛ ليست APK جاهزًا.
- لا توجد بعد واجهة رفع صور المنتجات أو معرض خزائن/طاولات من ملف، أو ربط منتج محدد بالطلب.
- لا توجد بعد مكالمات مباشرة للناقلين، أو حالات تسليم قابلة للتغيير من الواجهة، أو إشعارات.
- لا توجد بعد إدارة مخزون وخصومات ومرتجعات وتقارير PDF/Excel وصافي ربح أو معالجة دفعات الطلبات في السجلات المالية.
- قواعد البيع الحالية **ليست حماية مالية نهائية**: يتحقق العميل من الإجمالي، ولا تتحقق القواعد من مطابقة كل سعر للسعر المسجل على الخادم. قبل استخدامه في محل حقيقي، يجب نقل تسجيل البيع إلى Cloud Function/خادم موثوق يعيد حساب الأسعار ويمنع التكرار ويسجل المعاملات بصورة ذرية.
- لوحة الإحصاءات الحالية تقرأ سجل المبيعات بالكامل؛ في المرحلة التالية ستستخدم استعلامات مؤرخة وتجميعات لتحسين الأداء والتكلفة.
- لا توجد اختبارات آلية مُنفّذة في هذه البيئة، ولا تم التحقق من البناء محليًا لغياب Flutter SDK.

## تصميم البيانات
`users/{uid}`: role, active
`products/{id}`: name, price, category, imageUrl, active, createdAt
`sales/{id}`: items, total, received, paymentMethod, createdBy, createdAt, status
`orders/{id}`: customerName, phone, productName, city, price, advance, status, createdBy, createdAt
`transporters/{id}`: name, phone, createdAt

## المرحلة الثانية
صور المنتجات والتخزين، ربط الطلبات بالكتالوج، الاتصال بالناقل، إدارة حالات الطلب، سجل التسبيقات، Cloud Functions آمنة لتسجيل البيع، تقارير ومدخول نقدي وربح ومخزون، واختبارات Flutter وFirebase Emulator.
