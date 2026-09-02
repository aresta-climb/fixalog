// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

#[cfg(test)]
mod tests {
    use crate::crypto_signer::*;
    use std::fs;
    use std::io::Write;

    #[test]
    fn test_calculate_stream_hash_skipping_byterange() {
        // Setup: create a file with known content
        let temp_file_path = "test_hash.txt";
        let mut file = fs::File::create(temp_file_path).unwrap();
        // content length = 20
        file.write_all(b"01234567890123456789").unwrap();

        // Let's skip the middle 10 bytes: "5678901234"
        // Read: [0..5] ("01234") + [15..20] ("56789")
        // The hashed string should be "0123456789"
        let byte_range = vec![0, 5, 15, 5];
        
        // Act
        let hash = calculate_stream_hash_skipping_byterange(temp_file_path, &byte_range);
        
        // Assert
        assert!(hash.is_ok(), "Falha ao calcular hash do arquivo");
        let hash_val = hash.unwrap();
        assert_eq!(hash_val.len(), 32); // SHA-256 is 32 bytes
        
        // Cleanup
        fs::remove_file(temp_file_path).unwrap();
    }

    #[test]
    fn test_generate_self_signed_cms() {
        let hash_bytes = vec![0u8; 32];
        
        // Act
        let cms = generate_self_signed_cms(&hash_bytes);
        
        // Assert
        assert!(cms.is_ok(), "Falha ao gerar CMS");
        let cms_val = cms.unwrap();
        assert!(cms_val.len() > 0, "CMS gerado está vazio");
    }
}
