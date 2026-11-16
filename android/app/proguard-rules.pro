# flutter_local_notifications persists scheduled notifications with Gson.
# R8 strips generic signatures / TypeToken subclasses by default, which causes
# "PlatformException: Missing type parameter" when loading or cancelling
# scheduled notifications in release builds.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

-keep class com.dexterous.** { *; }

# Gson
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-dontwarn com.google.gson.**

# Preserve native Kotlin classes (widgets, receivers, services) & Flutter engine bridges
-keep class com.talibilm.app.** { *; }
-keep class es.antonborri.home_widget.** { *; }
-keep class com.ryanheise.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview_android.** { *; }
-keep class com.syncfusion.flutter.pdfviewer.** { *; }
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
