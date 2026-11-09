// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

package com.arestaclimb.fixalog

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
import kotlinx.coroutines.launch
import java.security.MessageDigest

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val CANAL_AUTENTICACAO_NATIVA = "com.arestaclimb.fixalog/autenticacao_nativa"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
                    iniciarLoginNativoGoogle(webClientId, rawNonce, result)
                }
                "solicitarIdTokenApple" -> {
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
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

    private fun sha256Hex(texto: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val bytes = digest.digest(texto.toByteArray(Charsets.UTF_8))
        return bytes.joinToString("") { "%02x".format(it) }
    }
}
