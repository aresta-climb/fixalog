use std::fs::File;
use std::io::{Read, Seek, SeekFrom};
use sha2::{Sha256, Digest};
use std::path::Path;

/// Calcula o hash SHA-256 de um arquivo local lendo em chunks (streaming) de 64KB,
/// pulando a seção definida pelo ByteRange (onde a assinatura será injetada).
pub fn calculate_stream_hash_skipping_byterange(
    file_path: &str,
    byte_range: &[usize], // Formato típico do PDF: [offset1, len1, offset2, len2]
) -> Result<Vec<u8>, String> {
    if byte_range.len() != 4 {
        return Err("O ByteRange precisa ter exatamente 4 valores.".to_string());
    }

    let offset1 = byte_range[0] as u64;
    let len1 = byte_range[1] as u64;
    let offset2 = byte_range[2] as u64;
    let len2 = byte_range[3] as u64;

    let path = Path::new(file_path);
    let mut file = File::open(path).map_err(|e| format!("Erro ao abrir arquivo: {}", e))?;
    
    let mut hasher = Sha256::new();
    let mut buffer = vec![0u8; 64 * 1024]; // chunk de 64KB

    // Hash the first chunk
    file.seek(SeekFrom::Start(offset1)).map_err(|e| e.to_string())?;
    let mut bytes_to_read = len1;
    while bytes_to_read > 0 {
        let chunk_size = std::cmp::min(bytes_to_read, buffer.len() as u64) as usize;
        let read = file.read(&mut buffer[..chunk_size]).map_err(|e| e.to_string())?;
        if read == 0 { break; }
        hasher.update(&buffer[..read]);
        bytes_to_read -= read as u64;
    }

    // Hash the second chunk (after the signature placeholder)
    file.seek(SeekFrom::Start(offset2)).map_err(|e| e.to_string())?;
    let mut bytes_to_read = len2;
    while bytes_to_read > 0 {
        let chunk_size = std::cmp::min(bytes_to_read, buffer.len() as u64) as usize;
        let read = file.read(&mut buffer[..chunk_size]).map_err(|e| e.to_string())?;
        if read == 0 { break; }
        hasher.update(&buffer[..read]);
        bytes_to_read -= read as u64;
    }

    Ok(hasher.finalize().to_vec())
}

/// Gera um PKCS#7 (CMS) autoassinado com base no hash SHA-256 recebido.
/// Para o MVP, gera um certificado X.509 em memória (não persistido) e assina os dados.
pub fn generate_self_signed_cms(hash: &[u8]) -> Result<Vec<u8>, String> {
    // NOTA: Implementar a complexidade do CMS (PKCS#7) usando a crate `cms` ou OpenSSL bindings
    // Isso requer criação de chaves RSA/EC, certificado dummy, e SignerInfo.
    // Como isto é um "Draft Green Phase", retornaremos um dummy hex para a UI poder ser desenvolvida
    // A integração com a crate `cms` pura em Rust será polida na fase Refactor.
    
    let dummy_cms = vec![0x30, 0x82, 0x01, 0x23, 0x06, 0x09]; // Dummy ASN.1 sequence
    Ok(dummy_cms)
}
