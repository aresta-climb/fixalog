# Regras R8 / ProGuard - Fixalog (Otimizacao Maxima de Tamanho e Performance)

# Repackaging de classes ofuscadas em pacote unico para reduzir tamanho do DEX
-repackageclasses 'com.arestaclimb.fixalog.r8'
-allowaccessmodification

# Preservar metadados essenciais para stacktraces legiveis no Crashlytics/Sentry e Kotlin Coroutines
-keepattributes SourceFile,LineNumberTable,InnerClasses,EnclosingMethod,Signature,*Annotation*
-renamesourcefileattribute SourceFile

# Remover chamadas de log de debug/verbose do bytecode Android em producao
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
}

# Silenciar avisos de dependencias opcionais de bibliotecas de terceiros
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.animal_sniffer.**
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**
