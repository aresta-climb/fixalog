// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 FixLog Contributors

use lopdf::{Document, Object, Dictionary, Stream};
use std::fs;
use std::path::Path;

/// Injeta arquivos como EmbeddedFiles dentro do dicionário /Names do PDF
pub fn inject_embedded_files(doc: &mut Document, media_paths: Vec<String>) -> Result<(), String> {
    // 1. Criar array para a árvore de nomes (NameTree)
    let mut names_array = vec![];

    for path_str in media_paths {
        let path = Path::new(&path_str);
        let file_name = path.file_name().unwrap().to_string_lossy().to_string();
        
        let content = fs::read(path).map_err(|e| format!("Erro lendo arquivo: {}", e))?;
        
        // Dicionário do arquivo embedded (EF)
        let mut ef_dict = Dictionary::new();
        ef_dict.set("Type", Object::Name(b"EmbeddedFile".to_vec()));
        // Tamanho do arquivo não compactado (simplificado aqui)
        
        let stream = Stream::new(ef_dict, content);
        let stream_id = doc.add_object(Object::Stream(stream));

        // Dicionário Filespec (F)
        let mut fs_dict = Dictionary::new();
        fs_dict.set("Type", Object::Name(b"Filespec".to_vec()));
        fs_dict.set("F", Object::String(file_name.as_bytes().to_vec(), lopdf::StringFormat::Literal));
        fs_dict.set("UF", Object::String(file_name.as_bytes().to_vec(), lopdf::StringFormat::Literal));
        
        let mut ef_ref_dict = Dictionary::new();
        ef_ref_dict.set("F", Object::Reference(stream_id));
        fs_dict.set("EF", Object::Dictionary(ef_ref_dict));

        let fs_id = doc.add_object(Object::Dictionary(fs_dict));

        // Adiciona à árvore de nomes: [String (chave), Reference (Filespec)]
        names_array.push(Object::String(file_name.as_bytes().to_vec(), lopdf::StringFormat::Literal));
        names_array.push(Object::Reference(fs_id));
    }

    if !names_array.is_empty() {
        let mut embedded_files_dict = Dictionary::new();
        embedded_files_dict.set("Names", Object::Array(names_array));
        let embedded_files_id = doc.add_object(Object::Dictionary(embedded_files_dict));

        let mut names_dict = Dictionary::new();
        names_dict.set("EmbeddedFiles", Object::Reference(embedded_files_id));
        let names_id = doc.add_object(Object::Dictionary(names_dict));

        if let Ok(catalog) = doc.catalog_mut() {
            catalog.set("Names", Object::Reference(names_id));
        }
    }

    Ok(())
}

/// Cria o placeholder AcroForm e Sig (Assinatura)
pub fn create_byterange_placeholder(doc: &mut Document, _placeholder_size: usize) -> Result<(), String> {
    // 1. Criar dicionário de Assinatura (Sig)
    let mut sig_dict = Dictionary::new();
    sig_dict.set("Type", Object::Name(b"Sig".to_vec()));
    sig_dict.set("Filter", Object::Name(b"Adobe.PPKLite".to_vec()));
    sig_dict.set("SubFilter", Object::Name(b"adbe.pkcs7.detached".to_vec()));
    
    // O array de ByteRange será injetado depois (ou definido com zeros)
    sig_dict.set("ByteRange", Object::Array(vec![
        Object::Integer(0), Object::Integer(1000000000), 
        Object::Integer(1000000000), Object::Integer(1000000000)
    ]));
    
    // Placeholder para os conteúdos da assinatura (hexadecimal string)
    let contents = vec![b'0'; 8192];
    sig_dict.set("Contents", Object::String(contents, lopdf::StringFormat::Hexadecimal));

    let sig_id = doc.add_object(Object::Dictionary(sig_dict));

    // 2. AcroForm Widget para a Assinatura (Opcional, dependendo de visibilidade)
    let mut field_dict = Dictionary::new();
    field_dict.set("FT", Object::Name(b"Sig".to_vec()));
    field_dict.set("T", Object::String(b"Signature1".to_vec(), lopdf::StringFormat::Literal));
    field_dict.set("V", Object::Reference(sig_id));

    let field_id = doc.add_object(Object::Dictionary(field_dict));

    // 3. Adicionar no Catalog (AcroForm)
    let mut acroform = Dictionary::new();
    acroform.set("Fields", Object::Array(vec![Object::Reference(field_id)]));
    acroform.set("SigFlags", Object::Integer(3)); // Signatures exist and append only
        
    let acroform_id = doc.add_object(Object::Dictionary(acroform));

    if let Ok(catalog) = doc.catalog_mut() {
        catalog.set("AcroForm", Object::Reference(acroform_id));
    }

    Ok(())
}
