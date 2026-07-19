pub struct GenerationProgress {
    pub percent: f64,
    pub status: String,
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

pub fn generate_sealed_report(
    draft_path: String,
    media_paths: Vec<String>,
    manifest_path: String,
    output_path: String,
    // progress_sink: crate::frb_generated::StreamSink<GenerationProgress>, // Descomentar quando o FRB estiver ajustado para Streams
) -> Result<(), String> {
    // 1. Carregar Draft
    // 2. Injetar EmbeddedFiles
    // 3. Criar Placeholder Sig
    // 4. Salvar output parcial
    // 5. Ler streaming pulando o placeholder, gerar hash
    // 6. Criar CMS e injetar na posição final do disco
    
    // progress_sink.add(GenerationProgress { percent: 1.0, status: "Done".to_string() });
    
    Ok(())
}
