#[cfg(test)]
mod tests {
    use crate::pdf_engine::*;
    use lopdf::Document;
    use std::fs;
    use std::io::Write;

    #[test]
    fn test_inject_embedded_files_adds_attachments() {
        let mut doc = Document::with_version("1.4");
        // Inject Catalog so doc.catalog() doesn't panic
        let mut catalog = lopdf::Dictionary::new();
        catalog.set("Type", lopdf::Object::Name(b"Catalog".to_vec()));
        let catalog_id = doc.add_object(lopdf::Object::Dictionary(catalog));
        doc.trailer.set("Root", lopdf::Object::Reference(catalog_id));

        // Setup: Create a temporary file to inject
        let temp_file_path = "test_media.txt";
        let mut file = fs::File::create(temp_file_path).unwrap();
        file.write_all(b"dummy media content").unwrap();

        let media_paths = vec![temp_file_path.to_string()];
        
        // Act: Inject the file
        let result = inject_embedded_files(&mut doc, media_paths);
        
        // Assert
        assert!(result.is_ok(), "A injeção de arquivos falhou");
        
        // The catalog should now have a "Names" dictionary
        let catalog = doc.catalog().unwrap();
        assert!(catalog.has(b"Names"), "O dicionário Names não foi criado no Catalog");
        
        // Cleanup
        fs::remove_file(temp_file_path).unwrap();
    }

    #[test]
    fn test_create_byterange_placeholder() {
        let mut doc = Document::with_version("1.4");
        // Inject Catalog so doc.catalog() doesn't panic
        let mut catalog = lopdf::Dictionary::new();
        catalog.set("Type", lopdf::Object::Name(b"Catalog".to_vec()));
        let catalog_id = doc.add_object(lopdf::Object::Dictionary(catalog));
        doc.trailer.set("Root", lopdf::Object::Reference(catalog_id));
        
        // Act
        let result = create_byterange_placeholder(&mut doc, 8192);
        
        // Assert
        assert!(result.is_ok(), "A criação do placeholder falhou");
        
        // The catalog should now have an "AcroForm" dictionary
        let catalog = doc.catalog().unwrap();
        assert!(catalog.has(b"AcroForm"), "AcroForm não foi criado no Catalog");
    }
}
