import sys
import base64
import hashlib
import re

try:
    from ecdsa import VerifyingKey, BadSignatureError
    from ecdsa.util import sigdecode_der
except ImportError:
    print("Por favor, instale a biblioteca ecdsa: pip install ecdsa")
    sys.exit(1)

def verify_pdf(pdf_path):
    print(f"Analisando PDF: {pdf_path}\n")
    
    try:
        with open(pdf_path, 'rb') as f:
            content = f.read()
    except Exception as e:
        print(f"Erro ao ler arquivo: {e}")
        return

    # Busca rudimentar pelas tags XMP (no Flutter printing/pdf o XMP não fica criptografado)
    start_tag = b'<x:xmpmeta'
    end_tag = b'</x:xmpmeta>'
    
    start_idx = content.find(start_tag)
    end_idx = content.find(end_tag)
    
    if start_idx == -1 or end_idx == -1:
        print("ERRO: Metadados XMP não encontrados no PDF.")
        return
        
    xmp_data = content[start_idx:end_idx + len(end_tag)].decode('utf-8', errors='ignore')
    
    print("XMP Encontrado. Extraindo informações criptográficas...\n")
    
    # A extração via Regex é direta e evita complexidade com namespaces XML do RDF
    protobuf_b64 = re.search(r'fixalog:protobuf="([^"]+)"', xmp_data)
    signature_b64 = re.search(r'fixalog:signature="([^"]+)"', xmp_data)
    pubkey_b64 = re.search(r'fixalog:publicKey="([^"]+)"', xmp_data)
    
    if not (protobuf_b64 and signature_b64 and pubkey_b64):
        print("ERRO: Atributos 'fixalog' não encontrados no XMP.")
        return
        
    try:
        protobuf_bytes = base64.b64decode(protobuf_b64.group(1))
        signature_bytes = base64.b64decode(signature_b64.group(1))
        pubkey_pem = base64.b64decode(pubkey_b64.group(1)).decode('utf-8')
    except Exception as e:
        print(f"ERRO: Falha ao decodificar dados em Base64: {e}")
        return
    
    print("--- Chave Pública Extraída ---")
    print(pubkey_pem.strip())
    print("------------------------------\n")
    
    # 1. Verificar Hash do Protobuf
    computed_hash = hashlib.sha256(protobuf_bytes).hexdigest()
    print(f"Hash do Binário Protobuf (SHA-256): {computed_hash}")
    
    # 2. Validar Assinatura ECDSA
    try:
        # Carrega a chave pública (secp256r1 é padrão e suportado pelo ecdsa)
        vk = VerifyingKey.from_pem(pubkey_pem, hashfunc=hashlib.sha256)
        
        # A assinatura do basic_utils vem em formato ASN.1 DER padrão
        is_valid = vk.verify(signature_bytes, protobuf_bytes, hashfunc=hashlib.sha256, sigdecode=sigdecode_der)
        
        if is_valid:
            print("\n✅ [SUCESSO] A assinatura criptográfica é VÁLIDA!")
            print("Isso prova matematicamente que o PDF foi gerado pelo proprietário desta chave e os metadados (Protobuf) não foram adulterados.")
    except BadSignatureError:
        print("\n❌ [FALHA] A assinatura criptográfica é INVÁLIDA!")
        print("O documento pode ter sido adulterado.")
    except Exception as e:
        print(f"\n⚠️ [ERRO] Falha durante o processamento da validação ECDSA: {e}")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Uso: python verify_signature.py <caminho_do_pdf>")
    else:
        verify_pdf(sys.argv[1])
