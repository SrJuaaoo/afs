# Lendas do Anime

Protótipo original de um simulador de equipes de lutadores para Roblox, inteiramente em português. Inspirado no ciclo de progressão de simuladores de anime; não usa personagens, marcas, mapas ou assets de Anime Fighters Simulator. Cenário e personagens são gerados por código, sem plugins, modelos externos ou chaves de API.

## Abrir e jogar

1. Baixe e abra `dist/LendasDoAnime.rbxl` no **Roblox Studio** usando **File → Open from File**. Esta é a versão binária recomendada; não é necessário instalar Rojo para jogar.
2. Clique em **Play (F5)**. O mapa é criado quando a simulação inicia.
3. Você começa com 300 moedas e Haru equipado. Clique no corpo de um inimigo, ou aproxime-se e use a interação **Atacar**. A equipe ataca automaticamente enquanto você estiver perto.
4. Aproxime-se da esfera dourada para invocar. Use **Lutadores** para equipar, vender ou selecionar a melhor equipe.
5. Resgate missões a cada dez vitórias. Desbloqueie novas ilhas pelos portais ou pelo menu **Ilhas**.

Controles de movimento e câmera são os padrões do Roblox. Os botões e prompts aceitam toque. A venda pede confirmação e não pode ser desfeita.

## Conteúdo

- Três ilhas: Vila da Aurora, Deserto Celeste e Cidadela Lunar.
- Cinco lutadores originais; probabilidades públicas de 55%, 28%, 12%, 4% e 1%.
- Até três lutadores equipados; inventário de 120 unidades.
- Quinze inimigos, incluindo três chefes; renascimento em sete segundos.
- Poder escalonado por ilha, XP e evolução de nível.
- Missões repetíveis, seleção de alvo, números de dano, companheiros visíveis e viagens.
- Autoridade do servidor sobre moedas, invocações, inventário, desbloqueios e dano.
- Salvamento automático a cada 60 segundos, ao sair e no fechamento do servidor.

## Salvamento e publicação

Publique em uma experiência sua pelo Roblox Studio. Para testar DataStore no Studio, use uma experiência de teste separada e ative **Game Settings → Security → Enable Studio Access to API Services**. Sem acesso ao DataStore, o Studio usa progresso temporário e não tenta salvá-lo; em servidores publicados, falhas de carregamento impedem a entrada para evitar sobrescrever progresso.

Este é um protótipo: antes de lançar para jogadores, implemente bloqueio de sessão de dados e retentativas de gravação, teste reconexões e múltiplos servidores, balanceie a economia e faça testes reais de dispositivos e jogadores simultâneos. Não há compras com Robux, trocas, raids ou conteúdo licenciado. A lógica atual dá a recompensa ao jogador que causar o golpe final.

## Desenvolvimento

Edite os scripts em `src/`. `GameConfig.lua` centraliza preços, poderes e probabilidades. Para gerar os arquivos de Studio, instale o [Rojo 7.5.1](https://github.com/rojo-rbx/rojo/releases/tag/v7.5.1) e execute:

```sh
python3 tools/build_place.py
```

Se o executável não estiver no PATH, use `python3 tools/build_place.py --rojo /caminho/para/rojo`. O script usa `default.project.json` para gerar `dist/LendasDoAnime.rbxl` (binário) e `dist/LendasDoAnime.rbxlx` (XML). Ambos são produzidos pelo serializador Roblox do Rojo; não edite os arquivos gerados manualmente.

### Correção do arquivo XML anterior

A primeira versão foi escrita por um exportador XML genérico e foi rejeitada pelo Roblox Studio como `ill-formed XML`. Esse exportador foi removido. Os arquivos de distribuição foram regenerados com Rojo, e os dois formatos passaram pela desserialização Roblox no Lune, com conferência dos três scripts e sua compilação Luau. Use o novo `.rbxl` para evitar confusão com a cópia XML antiga já baixada.

Para repetir a validação de formato, instale [Lune 0.8.9](https://github.com/lune-org/lune/releases/tag/v0.8.9) e execute, na raiz do repositório:

```sh
lune run tests/place.luau
```

## Validação no Studio

O ambiente de criação deste repositório não inclui Roblox Studio. A geração do XML e a sintaxe dos scripts podem ser verificadas fora dele; física, UI, APIs Roblox e jogabilidade precisam ser verificadas no Studio.

- Em Play, confirme mapa, personagem inicial, HUD e lutador seguindo o jogador.
- Ataque um inimigo, confira dano, moedas, XP e renascimento; afaste-se e confirme a interrupção do ataque.
- Invoque junto à estrela e tente longe dela ou sem moedas; apenas a primeira condição válida deve descontar moedas.
- Equipe/desequipe, use a melhor equipe e tente vender um lutador equipado.
- Resgate uma missão e tente resgatá-la novamente sem novas vitórias.
- Teste o bloqueio de ilhas sem moedas e a viagem após desbloqueio.
- Em **Test → Start** com dois jogadores, confira inventários independentes e inimigos compartilhados.
- Em uma experiência de teste com DataStore habilitado, saia e entre novamente para conferir persistência.
- Use o emulador de dispositivos para conferir controles e leitura da interface em telas pequenas.
