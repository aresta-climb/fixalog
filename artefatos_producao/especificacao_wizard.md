eu tenho a seguinte proposta de etapas:

# Bloco 1 - Materiais a serem instalados
Teremos uma seção inicial para o mantenedor listar os equipamentos utilizados durante a manutenção, especificar a composição, marca, lote, validade de cada um e tirar fotos de todos os materiais que serão instalados na rocha:
1. Parabolts
2. Chapeletas
3. Argolas
4. Ancoragens químicas
5. Colas químicas

Essa listagem inicial vai virar um menu que vai permitir que o mantenedor liste rapidamente quais, dos materiais listados acima, estão sendo usados na proteção atual sendo trocada.

# Bloco 2 - Identificação da via a ser manutenida
Aqui serão adicionados detalhes como pico, setor, nome da via, localização gps, anexar permissão do conquistador, etc, que serão um resumo usado para identificar toda a manutenção.

# Bloco 3 - Ações de manutenção
Aqui, vamos passar a ter um formulário que pode ir se modificando dinamicamente. O mantenedor vai subir na via, e realizar um monte de ações. O objetivo é que **cada** ação do mantenedor seja um novo card que pode ser adicionado. Tem várias ações que poderíamos dar opção para o mantenedor agir:

1. Inspeção de ancoragem (pode virar uma troca ou até remoção / reposicionamento dependendo de como o workflow seguir!)
2. Instalação de novo ponto de ancoragem (que não existia anteriormente)
3. Remoção de bloco solto
4. Limpeza de vegetação
5. Outro (para permitir o logging de ações customizadas que não estão pré-estabelecidas)

A ideia é que cada ação vai seguir um workflow próprio, e o mantenedor pode adicionar tantas ações quanto forem requeridas até a manutenção terminar.

## Bloco 3.1. - Definição de cada ação de manutenção

Cada ação seria responsável por coletar todas as evidências da ação, como quais equipamentos (dos listados no Bloco #1) foram instalados, foto de como estava antes, foto de como ficou depois, vídeo curto, notas, etc. Precisamos de uma sintaxe que permita a adição dinâmica ou remoção de cards para auxiliar nessas ações. Por enquanto, teríamos as seguintes ações:

### Bloco 3.1.1. Inspeção de ancoragem

Passo a passo:
1. Foto, material e tipo da ancoragem original, vídeo opcional
2. Instruções para inspecionar a ancoragem (talvez aqui oferecer algumas opções: decidir se já sabe que precisa substituir, ou se não está claro, seguir para um caminho alternativo. Primeiro checar se a rocha está sólida no local com martelo, depois seguir caminhos diferentes dependendo do tipo de ancoragem - para grampos P, identificar se tem palhetas de alumínio (alerta vermelho), ou se está pouco inserido, ou se ponta do grampo está pouco batido, ou o nível de corrosão etc. Para ancoragens de parabolt, desapertar a porta e inspecionar atrás do furo a situação - caso tiver corrosão visível, trocar. Se não, reapertar novamente com a chave de torque. Coletar fotos durante todo esse processo).
3. Caso precisar substituir, seguir para instruções de substituição. Caso não precisar, trabalho terminado para essa ancoragem.

Para substituição, devemos olhar se é possível remover a ancoragem para reusar o furo (e se o mantenedor sabe fazer isso), e tentar fazer isso primeiro. Caso conseguir, seguir para instruções de expandir o furo e instalar ancoragem química. Caso não for possível remover a ancoragem, seguir com instruções de ver se o local da ancoragem atual faz sentido ou se possui um local melhor (e se tem autorização para isso). Se fizer, instalar no novo local, tirar foto, etc. Se não tiver, sugerir achar local alternativo e instalar lá.

### 3.1.2. Instalação de novo ponto de ancoragem

Aqui teremos instruções do tipo encontrar local ideal, confirmar que pode fazer isso com permissão do conquistador, e aí passar pelas instruções de instalar um novo pont ode ancoragem.

### 3.1.3. Remoção de bloco solto

Aqui o principal é tirar fotos antes / depois e instruções para o mantenedor se manter seguro (ficar acima da ancoragem, etc).

### 3.1.4. Limpeza da vegetação

Aqui o principal é fotos antes / depois.

### 3.1.5. Outro

Aqui seriam opções abertas - adicionar texto livre, fotos, videos, etc.

# Bloco 4 - Avaliação final e assinatura
Será gerado um resumo para o conquistador revisar, campos para observações a mais, e então a assinatura. Assuma que assinaturas já são disponíveis.

O que acha desse plano? Será que consigo representar tudo isso em um protobuf? Ou será que, por mais que o resultado final gerado pelo mantenedor possa ser um protobuf, para representar todas as opções do wizard talvez eu precise de algo mais pdoeroso que um protobuf? Por exemplo um pequeno script em python? Ou em dart mesmo? Para controla todas as opções? Ou será que dá pra fazer só com protobuf mesmo? Seria mais legal.