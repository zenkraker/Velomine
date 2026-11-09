# WorkManager opens its Room database by reflection. Room's consumer rule keeps the class, but R8 can still
# remove the generated no-arg constructor, which crashes the release build during startup with:
#   NoSuchMethodException: androidx.work.impl.WorkDatabase_Impl.<init> []
# Keep that class and its constructor explicitly.
-keep class androidx.work.impl.WorkDatabase_Impl {
    <init>();
}
