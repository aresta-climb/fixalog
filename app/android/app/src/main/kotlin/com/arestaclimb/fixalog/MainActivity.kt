// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

package com.arestaclimb.fixalog

import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.lifecycle.lifecycleScope
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val CANAL_AUTENTICACAO_NATIVA = "com.arestaclimb.fixalog/autenticacao_nativa"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        if (BuildConfig.ARESTA_SMOKE_CI && ehEmuladorAndroid()) {
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                "com.arestaclimb.fixalog/" + "smoke_ci"
            ).setMethodCallHandler { call, result ->
                if (call.method == "obterConfiguracaoSmoke") {
                    result.success(lerConfiguracaoSmokeDaIntent(intent))
                } else {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CANAL_AUTENTICACAO_NATIVA
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "solicitarIdTokenGoogle" -> {
                    val webClientId = call.argument<String>("webClientId")?.trim().orEmpty()
                    val rawNonce = call.argument<String>("rawNonce")?.trim().orEmpty()
                    if (webClientId.isEmpty()) {
                        result.success(null)
                        return@setMethodCallHandler
                    }
                    if (BuildConfig.ARESTA_SMOKE_CI && ehEmuladorAndroid()) {
                        val configSmoke = lerConfiguracaoSmokeDaIntent(intent)
                        if (configSmoke["ativo"] == true) {
                            solicitarIdTokenSmokeLoopback(
                                servidorUrl = configSmoke["servidorUrl"] as String,
                                webClientId = webClientId,
                                rawNonce = rawNonce,
                                result = result
                            )
                            return@setMethodCallHandler
                        }
                    }
                    iniciarLoginNativoGoogle(webClientId, rawNonce, result)
                }
                "solicitarIdTokenApple" -> {
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    private fun iniciarLoginNativoGoogle(
        webClientId: String,
        rawNonce: String,
        result: MethodChannel.Result
    ) {
        val contexto = this
        lifecycleScope.launch {
            try {
                val nonceHash = if (rawNonce.isNotEmpty()) sha256Hex(rawNonce) else null
                val ConstrutorOpcao = GetGoogleIdOption.Builder()
                    .setFilterByAuthorizedAccounts(false)
                    .setServerClientId(webClientId)
                    .setAutoSelectEnabled(false)
                if (nonceHash != null) {
                    ConstrutorOpcao.setNonce(nonceHash)
                }
                val googleIdOption = ConstrutorOpcao.build()
                val requisicao = GetCredentialRequest.Builder()
                    .addCredentialOption(googleIdOption)
                    .build()

                val gerenciador = CredentialManager.create(contexto)
                val resposta = gerenciador.getCredential(
                    request = requisicao,
                    context = contexto
                )

                val credencial = resposta.credential
                if (credencial is CustomCredential &&
                    credencial.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL
                ) {
                    val tokenGoogle = GoogleIdTokenCredential.createFrom(credencial.data)
                    result.success(
                        mapOf(
                            "idToken" to tokenGoogle.idToken,
                            "nonce" to rawNonce,
                            "email" to tokenGoogle.id,
                            "nomeExibicao" to tokenGoogle.displayName,
                            "fotoUrl" to tokenGoogle.profilePictureUri?.toString(),
                            "cancelado" to false
                        )
                    )
                } else {
                    result.success(null)
                }
            } catch (_: GetCredentialCancellationException) {
                result.success(mapOf("cancelado" to true))
            } catch (_: Exception) {
                result.success(null)
            }
        }
    }

    private fun ehEmuladorAndroid(): Boolean {
        val fingerprint = Build.FINGERPRINT.lowercase()
        val hardware = Build.HARDWARE.lowercase()
        val modelo = Build.MODEL.lowercase()
        val produto = Build.PRODUCT.lowercase()
        return fingerprint.startsWith("generic") ||
            fingerprint.contains("emulator") ||
            hardware.contains("ranchu") ||
            hardware.contains("goldfish") ||
            modelo.contains("sdk_gphone") ||
            modelo.contains("emulator") ||
            modelo.contains("android sdk built for") ||
            produto.contains("sdk")
    }

    private fun lerConfiguracaoSmokeDaIntent(intentAtual: Intent?): Map<String, Any> {
        val servidorBruto = intentAtual?.getStringExtra("smoke_server")?.trim().orEmpty()
        val token = intentAtual?.getStringExtra("smoke_token")?.trim().orEmpty()
        if (servidorBruto.isEmpty() || token.isEmpty()) {
            return mapOf("ativo" to false)
        }
        val uri = Uri.parse(servidorBruto)
        val host = uri.host?.lowercase().orEmpty()
        val porta = uri.port
        val hostsPermitidos = setOf("10.0.2.2", "127.0.0.1", "localhost")
        if (uri.scheme != "http" || porta <= 0 || !hostsPermitidos.contains(host)) {
            return mapOf("ativo" to false)
        }
        return mapOf(
            "ativo" to true,
            "servidorUrl" to "http://$host:$porta",
            "token" to token
        )
    }

    private fun solicitarIdTokenSmokeLoopback(
        servidorUrl: String,
        webClientId: String,
        rawNonce: String,
        result: MethodChannel.Result
    ) {
        lifecycleScope.launch {
            try {
                val nonceHash = if (rawNonce.isNotEmpty()) sha256Hex(rawNonce) else ""
                val resposta = withContext(Dispatchers.IO) {
                    val endpoint = "$servidorUrl/" + "__smoke__/oidc-token"
                    val conexao = (URL(endpoint).openConnection() as HttpURLConnection).apply {
                        requestMethod = "POST"
                        connectTimeout = 10000
                        readTimeout = 10000
                        doOutput = true
                        setRequestProperty("Content-Type", "application/json")
                    }
                    try {
                        val payload = JSONObject().apply {
                            put("nonceHash", nonceHash)
                            put("webClientId", webClientId)
                            put("provedor", "google")
                        }
                        conexao.outputStream.use { os ->
                            os.write(payload.toString().toByteArray(Charsets.UTF_8))
                        }
                        if (conexao.responseCode !in 200..299) {
                            null
                        } else {
                            val texto = conexao.inputStream.bufferedReader(Charsets.UTF_8).use { it.readText() }
                            val json = JSONObject(texto)
                            mapOf(
                                "idToken" to json.optString("idToken", ""),
                                "nonce" to rawNonce,
                                "email" to json.optString("email", ""),
                                "nomeExibicao" to json.optString("nomeExibicao", ""),
                                "cancelado" to false
                            )
                        }
                    } finally {
                        conexao.disconnect()
                    }
                }
                result.success(resposta)
            } catch (_: Exception) {
                result.success(null)
            }
        }
    }

    private fun sha256Hex(texto: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val bytes = digest.digest(texto.toByteArray(Charsets.UTF_8))
        return bytes.joinToString("") { "%02x".format(it) }
    }
}
