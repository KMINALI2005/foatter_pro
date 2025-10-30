# Flutter ProGuard Rules للحفاظ على التطبيق يعمل في release mode
# تم إنشاؤها لحل مشكلة التطبيق الفارغ بعد البناء

# ====== قواعد Flutter الأساسية ======
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ====== قواعد Dart ======
-keep class com.google.** { *; }
-dontwarn com.google.**

# الحفاظ على جميع annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# ====== قواعد SQLite و sqflite (مهم جداً!) ======
# الحفاظ على جميع classes المتعلقة بـ SQLite
-keep class com.tekartik.sqflite.** { *; }
-keep class android.database.** { *; }
-keep class android.database.sqlite.** { *; }
-keep class androidx.sqlite.** { *; }

# عدم تحذير من SQLite
-dontwarn android.database.**
-dontwarn com.tekartik.sqflite.**

# ====== قواعد path_provider ======
-keep class io.flutter.plugins.pathprovider.** { *; }

# ====== قواعد share_plus ======
-keep class dev.fluttercommunity.plus.share.** { *; }
-keep class androidx.core.content.FileProvider { *; }

# ====== قواعد file_picker ======
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# ====== قواعد intl و localization ======
-keep class com.ibm.icu.** { *; }
-dontwarn com.ibm.icu.**

# ====== الحفاظ على Native methods ======
-keepclasseswithmembernames class * {
    native <methods>;
}

# ====== الحفاظ على Enums ======
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ====== الحفاظ على Serializable classes ======
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ====== الحفاظ على Parcelable classes ======
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# ====== تحسينات الأداء ======
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# ====== تجاهل التحذيرات غير المهمة ======
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
