import Flutter
import UIKit
import UserNotifications
import AuthenticationServices
import CryptoKit
import Security

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding, ASWebAuthenticationPresentationContextProviding {
  private var resultadoPendenteApple: FlutterResult?
  private var nonceBrutoAppleAtual: String?
  private var sessaoWebAuthGoogle: ASWebAuthenticationSession?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    #if targetEnvironment(simulator)
    let canalSmoke = FlutterMethodChannel(
      name: "com.arestaclimb.fixalog/smoke_ci",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    canalSmoke.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(nil)
        return
      }
      if call.method == "obterConfiguracaoSmoke" {
        result(self.lerConfiguracaoSmokeDoAmbiente())
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    #endif

    let canalAutenticacao = FlutterMethodChannel(
      name: "com.arestaclimb.fixalog/autenticacao_nativa",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    canalAutenticacao.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(nil)
        return
      }
      let args = call.arguments as? [String: Any]
      let rawNonce = (args?["rawNonce"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

      #if targetEnvironment(simulator)
      let configSmoke = self.lerConfiguracaoSmokeDoAmbiente()
      if (configSmoke["ativo"] as? Bool) == true,
         let servidorUrl = configSmoke["servidorUrl"] as? String {
        switch call.method {
        case "solicitarIdTokenApple":
          self.solicitarIdTokenSmokeLoopback(
            servidorUrl: servidorUrl,
            provedor: "apple",
            rawNonce: rawNonce,
            result: result
          )
          return
        case "solicitarIdTokenGoogle":
          self.solicitarIdTokenSmokeLoopback(
            servidorUrl: servidorUrl,
            provedor: "google",
            rawNonce: rawNonce,
            result: result
          )
          return
        default:
          break
        }
      }
      #endif

      switch call.method {
      case "solicitarIdTokenApple":
        self.iniciarLoginNativoApple(rawNonce: rawNonce, result: result)
      case "solicitarIdTokenGoogle":
        let iosClientId = (args?["iosClientId"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
          ?? (Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String)
          ?? "1025411452942-eimt7ppo50n2ctur5r8ag4trk1mlo999.apps.googleusercontent.com"
        self.iniciarLoginNativoGoogle(rawNonce: rawNonce, iosClientId: iosClientId, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  #if targetEnvironment(simulator)
  private func lerConfiguracaoSmokeDoAmbiente() -> [String: Any] {
    let env = ProcessInfo.processInfo.environment
    let servidorBruto = (env["ARESTA_SMOKE_SERVER"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let token = (env["ARESTA_SMOKE_TOKEN"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    guard !servidorBruto.isEmpty,
          !token.isEmpty,
          let comp = URLComponents(string: servidorBruto),
          comp.scheme == "http",
          let host = comp.host?.lowercased(),
          let porta = comp.port,
          porta > 0,
          (host == "127.0.0.1" || host == "localhost") else {
      return ["ativo": false]
    }
    return [
      "ativo": true,
      "servidorUrl": "http://\(host):\(porta)",
      "token": token
    ]
  }

  private func solicitarIdTokenSmokeLoopback(
    servidorUrl: String,
    provedor: String,
    rawNonce: String?,
    result: @escaping FlutterResult
  ) {
    let nonceBruto = (rawNonce != nil && !rawNonce!.isEmpty) ? rawNonce! : self.gerarNonceAleatorio()
    let nonceHash = self.sha256Hex(nonceBruto)
    guard let url = URL(string: "\(servidorUrl)/__smoke__/oidc-token") else {
      result(nil)
      return
    }
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.timeoutInterval = 10
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let payload: [String: Any] = [
      "nonceHash": nonceHash,
      "provedor": provedor
    ]
    req.httpBody = try? JSONSerialization.data(withJSONObject: payload)

    URLSession.shared.dataTask(with: req) { data, response, error in
      guard error == nil,
            let httpRes = response as? HTTPURLResponse,
            (200...299).contains(httpRes.statusCode),
            let data = data,
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let idToken = json["idToken"] as? String,
            !idToken.isEmpty else {
        DispatchQueue.main.async { result(nil) }
        return
      }
      let nome = (json["nomeCompleto"] as? String) ?? (json["nomeExibicao"] as? String) ?? ""
      let email = (json["email"] as? String) ?? ""
      DispatchQueue.main.async {
        result([
          "idToken": idToken,
          "nonce": nonceBruto,
          "nomeCompleto": nome,
          "nomeExibicao": nome,
          "email": email,
          "cancelado": false
        ])
      }
    }.resume()
  }
  #endif

  private func iniciarLoginNativoApple(rawNonce: String?, result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      self.resultadoPendenteApple?(nil)
      self.resultadoPendenteApple = result
      let nonceBruto = (rawNonce != nil && !rawNonce!.isEmpty) ? rawNonce! : self.gerarNonceAleatorio()
      self.nonceBrutoAppleAtual = nonceBruto

      let provedor = ASAuthorizationAppleIDProvider()
      let requisicao = provedor.createRequest()
      requisicao.requestedScopes = [.fullName, .email]
      requisicao.nonce = self.sha256Hex(nonceBruto)

      let controlador = ASAuthorizationController(authorizationRequests: [requisicao])
      controlador.delegate = self
      controlador.presentationContextProvider = self
      controlador.performRequests()
    }
  }

  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    return self.window ?? UIWindow()
  }

  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return self.window ?? UIWindow()
  }

  private func iniciarLoginNativoGoogle(rawNonce: String?, iosClientId: String, result: @escaping FlutterResult) {
    let prefixoId = iosClientId.replacingOccurrences(of: ".apps.googleusercontent.com", with: "")
    let esquemaCallback = "com.googleusercontent.apps.\(prefixoId)"
    let redirectUri = "\(esquemaCallback):/oauth2redirect"
    let nonceBruto = (rawNonce != nil && !rawNonce!.isEmpty) ? rawNonce! : self.gerarNonceAleatorio()
    let nonceHash = self.sha256Hex(nonceBruto)
    let codeVerifier = self.gerarNonceAleatorio(tamanho: 64)
    let codeChallenge = Data(SHA256.hash(data: Data(codeVerifier.utf8)))
      .base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")

    var componentes = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
    componentes.queryItems = [
      URLQueryItem(name: "client_id", value: iosClientId),
      URLQueryItem(name: "redirect_uri", value: redirectUri),
      URLQueryItem(name: "response_type", value: "code"),
      URLQueryItem(name: "scope", value: "openid email profile"),
      URLQueryItem(name: "nonce", value: nonceHash),
      URLQueryItem(name: "code_challenge", value: codeChallenge),
      URLQueryItem(name: "code_challenge_method", value: "S256")
    ]

    guard let urlAuth = componentes.url else {
      result(nil)
      return
    }

    DispatchQueue.main.async {
      let sessao = ASWebAuthenticationSession(
        url: urlAuth,
        callbackURLScheme: esquemaCallback
      ) { [weak self] callbackURL, error in
        self?.sessaoWebAuthGoogle = nil
        if let erroWeb = error as? ASWebAuthenticationSessionError, erroWeb.code == .canceledLogin {
          result(["cancelado": true])
          return
        }
        if let error = error {
          let nsError = error as NSError
          result([
            "erroCodigo": "\(nsError.domain):\(nsError.code)",
            "erroMensagem": nsError.localizedDescription
          ])
          return
        }
        guard let callbackURL = callbackURL,
              let itens = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems,
              let codigo = itens.first(where: { $0.name == "code" })?.value else {
          result([
            "erroCodigo": "callback_invalido",
            "erroMensagem": "URL de retorno OAuth sem código de autorização."
          ])
          return
        }
        self?.trocarCodigoGooglePorIdToken(
          codigo: codigo,
          iosClientId: iosClientId,
          redirectUri: redirectUri,
          codeVerifier: codeVerifier,
          result: result
        )
      }
      sessao.presentationContextProvider = self
      sessao.prefersEphemeralWebBrowserSession = false
      self.sessaoWebAuthGoogle = sessao
      sessao.start()
    }
  }

  private func trocarCodigoGooglePorIdToken(
    codigo: String,
    iosClientId: String,
    redirectUri: String,
    codeVerifier: String,
    result: @escaping FlutterResult
  ) {
    guard let urlToken = URL(string: "https://oauth2.googleapis.com/token") else {
      result(nil)
      return
    }
    var req = URLRequest(url: urlToken)
    req.httpMethod = "POST"
    req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    var form = URLComponents()
    form.queryItems = [
      URLQueryItem(name: "client_id", value: iosClientId),
      URLQueryItem(name: "code", value: codigo),
      URLQueryItem(name: "code_verifier", value: codeVerifier),
      URLQueryItem(name: "grant_type", value: "authorization_code"),
      URLQueryItem(name: "redirect_uri", value: redirectUri)
    ]
    req.httpBody = form.percentEncodedQuery?.data(using: .utf8)

    URLSession.shared.dataTask(with: req) { data, _, error in
      if let error = error {
        let nsError = error as NSError
        DispatchQueue.main.async {
          result([
            "erroCodigo": "\(nsError.domain):\(nsError.code)",
            "erroMensagem": nsError.localizedDescription
          ])
        }
        return
      }
      guard let data = data,
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let idToken = json["id_token"] as? String else {
        DispatchQueue.main.async {
          result([
            "erroCodigo": "troca_token_invalida",
            "erroMensagem": "Resposta sem id_token ao trocar código Google OAuth."
          ])
        }
        return
      }
      DispatchQueue.main.async {
        result([
          "idToken": idToken,
          "nomeCompleto": "",
          "email": ""
        ])
      }
    }.resume()
  }

  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithAuthorization authorization: ASAuthorization
  ) {
    let callback = resultadoPendenteApple
    let nonce = nonceBrutoAppleAtual
    resultadoPendenteApple = nil
    nonceBrutoAppleAtual = nil

    guard let credencial = authorization.credential as? ASAuthorizationAppleIDCredential,
          let dadosToken = credencial.identityToken,
          let idToken = String(data: dadosToken, encoding: .utf8) else {
      callback?(nil)
      return
    }

    var partesNome: [String] = []
    if let nome = credencial.fullName?.givenName, !nome.isEmpty {
      partesNome.append(nome)
    }
    if let sobrenome = credencial.fullName?.familyName, !sobrenome.isEmpty {
      partesNome.append(sobrenome)
    }
    let nomeCompleto = partesNome.isEmpty ? "" : partesNome.joined(separator: " ")

    callback?([
      "idToken": idToken,
      "nonce": nonce as Any,
      "email": (credencial.email ?? "") as Any,
      "nomeCompleto": nomeCompleto,
      "nomeExibicao": nomeCompleto,
      "cancelado": false
    ])
  }

  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithError error: Error
  ) {
    let callback = resultadoPendenteApple
    resultadoPendenteApple = nil
    nonceBrutoAppleAtual = nil

    if let erroAuth = error as? ASAuthorizationError, erroAuth.code == .canceled {
      callback?(["cancelado": true])
    } else {
      let nsError = error as NSError
      callback?([
        "erroCodigo": "\(nsError.domain):\(nsError.code)",
        "erroMensagem": nsError.localizedDescription
      ])
    }
  }

  private func gerarNonceAleatorio(tamanho: Int = 32) -> String {
    let caracteres = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var resultado = ""
    var bytesRestantes = tamanho
    while bytesRestantes > 0 {
      var aleatorios = [UInt8](repeating: 0, count: 16)
      let status = SecRandomCopyBytes(kSecRandomDefault, aleatorios.count, &aleatorios)
      if status != errSecSuccess {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "")
      }
      for byte in aleatorios where bytesRestantes > 0 {
        if Int(byte) < caracteres.count {
          resultado.append(caracteres[Int(byte)])
          bytesRestantes -= 1
        }
      }
    }
    return resultado
  }

  private func sha256Hex(_ texto: String) -> String {
    let dados = Data(texto.utf8)
    let resumo = SHA256.hash(data: dados)
    return resumo.compactMap { String(format: "%02x", $0) }.joined()
  }
}
