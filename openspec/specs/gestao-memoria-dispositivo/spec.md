# Gestão Adaptativa de Memória do Dispositivo

## Purpose

Classifica a capacidade de memória RAM do aparelho e aplica limites dinâmicos ao cache de decodificação de imagens para evitar falhas nativas de esgotamento de memória (OOM).

## Requirements

### Requirement: Classificação de Memória do Hardware
O sistema DEVE (MUST) detectar a quantidade total de memória RAM disponível no dispositivo móvel e categorizar o aparelho em faixas de porte de hardware (baixo, médio ou alto).

#### Scenario: Detecção em dispositivo móvel
- **WHEN** a aplicação é inicializada no dispositivo
- **THEN** o classificador de memória lê os dados de hardware e define a faixa de capacidade operacional correspondente

### Requirement: Limitação Adaptativa do Cache de Imagens
O sistema DEVE (MUST) ajustar o teto máximo de memória permitido para o cache de decodificação de imagens do Flutter (`imageCache`) de acordo com o porte de hardware detectado, prevenindo estouro de memória durante a manipulação de múltiplas fotos de vias.

#### Scenario: Ajuste dinâmico de teto de imagem
- **WHEN** a inicialização do aplicativo é executada
- **THEN** o sistema aplica limite estrito de memória ao `PaintingBinding.instance.imageCache` (entre 50 MB e 150 MB conforme o porte do dispositivo)
