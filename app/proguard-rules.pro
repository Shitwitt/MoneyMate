# GlassChat R8 rules

# Kotlin serialization: keep generated serializers for backup DTOs.
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.**
-keepclassmembers class com.glasschat.app.data.backup.** {
    *** Companion;
}
-keepclasseswithmembers class com.glasschat.app.data.backup.** {
    kotlinx.serialization.KSerializer serializer(...);
}
-keep,includedescriptorclasses class com.glasschat.app.data.backup.**$$serializer { *; }

# Room generates implementations reflectively referenced by name in tests only.
-keep class androidx.room.RoomDatabase { *; }
-dontwarn androidx.room.paging.**

# Hilt / Dagger
-keep class dagger.hilt.** { *; }
-keep class javax.inject.** { *; }

# Coil video decoder
-dontwarn coil.**
