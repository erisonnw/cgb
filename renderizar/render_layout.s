    section "Renderizar Layout do Menu", rom0
renderizar_layout::
    call vblank                             ; Invocamos o LY (V-Blank) para que tudo rode conforme o esperado.
    ;; ┌───────────┬────────────┬─────────┬─────────┬───────────────┬─────────────────┬─────────┬─────────┬────────────────┐
    ;; │ Bit       │     7      │    6    │    5    │       4       │       3         │    2    │   1     │       0        │
    ;; ├───────────┼────────────┼─────────┼─────────┼───────────────┼─────────────────┼─────────┼─────────┼────────────────┤
    ;; │ Controle  │   Ativar   │ Janela  │ Ativar  │ Background e  │ Background      │   OBJ   │ Ativar  │      OBJ       │
    ;; │   LCD     │ LCD e PPU  │ Tilemap │ Janela  │ Janela Tiles  │ Janela Tilemap  │   Size  │  OBJ    │ Ativar Janela  │
    ;; └───────────┴────────────┴─────────┴─────────┴───────────────┴─────────────────┴─────────┴─────────┴────────────────┘
    ;;                            Veja mais sobre: https://gbdev.io/pandocs/LCDC.html
    xor a                                   ; Zeramos A para apagar todos os bits
                                            ; Precisamos da tela desligada para usar a VRAM sem danificar
    ld [$ff40], a                           ; Mandamos esse valor de A para o registrador $FF40 (LCDC)

    ;; VRAM BANKS
    xor a                                   ; Zeramos A novamente
    ld [$ff4f], a                           ; Abrimos o Banco 0 da VRAM através do registrador $FF4F (VBK)
    ;; ┌────────────────────────────────────┬─────────────┬─────────────┬─────────────┐
    ;; │ Identificações de tiles para...    │   Bloco 0   │   Bloco 1   │   Bloco 2   │
    ;; │                                    │ $8000–87FF  │ $8800–8FFF  │ $9000–97FF  │
    ;; ├────────────────────────────────────┼─────────────┼─────────────┼─────────────┤
    ;; │ Objetos                            │    0–127    │   128–255   │      —      │
    ;; │ BG/Win, se LCDC.4=1                │    0–127    │   128–255   │      —      │
    ;; │ BG/Win, se LCDC.4=0                │      —      │   128–255   │    0–127    │
    ;; └────────────────────────────────────┴─────────────┴─────────────┴─────────────┘
    ;;             Veja mais sobre: https://gbdev.io/pandocs/Tile_Data.html
    ld de, layout.tiles                     ; Apontamos DE para onde nossos tiles começam na ROM
    ld hl, $8000                            ; Agora apontamos HL para o início da VRAM ($8000-$97FFF)
                                            ; NOTA: Estamos ocupando a VRAM desde o início ($8000)
                                            ; AUTOR: Tentaremos reaproveitar essas áreas de memória assim que o código avançar :*
    ld bc, layout.ftiles - layout.tiles     ; Calculamos o tamanho total (em bytes) dos tiles para servir de contador em BC

    .copiar_meu_tiles:
    ld a, [de]                              ; Pegamos o byte atual do tile na ROM e guardmaos em A
    ld [hl+], a                             ; Jogamos esses byte na VRAM e avançamos HL para o próximo espaço
    inc de                                  ; Avançamos DE para ler o próximo byte na ROM
    dec bc                                  ; Decrementamos 1 do nosso contador total
    ld a, b                                 ; Trazemos o byte alto (High Byte) para A
    or a, c                                 ; O resultado só zera quando BC chegar em 0
    jp nz, .copiar_meu_tiles                ; Enquanto não zerar, voltamos para copiar o próximo byte


    ld de, layout.maps                      ; Agora apontamos DE para onde nosso tilemaps começam na ROM
    ld hl, $9800                            ; Também apontamos HL para o início do tilemap BG ($9800).
                                            ; AUTOR: Usamos $9800 para tilemaps, porque o Bloco 0 e Bloco 1 já foram ocupados por tiles
                                            ;        Você deve estar se perguntando: "Por que não usamos $9000 em vez de $9800?"
                                            ;
                                            ;        A resposta para essa pergunta é que o tiles ocuparam uma boa parte do Bloco 2 também:
                                            ;        No Game Boy Color (CGB), nós temos um limite de 768 tiles, mas eles são divididos
                                            ;        em dois bancos de memória da VRAM (384 tiles no Bank 0 e 384 tiles no Bank 1).
                                            ;
                                            ;        O tamanho de 1 único tiles é de 16 bytes
                                            ;        A capacidade de 1 banco é: 384 tiles · 16 bytes = 6.144 bytes, convertendo o valor para hex é 0x1800.
                                            ;        Agora, o endereçamento final dos tiles em cada banco: $8000 + $1800 = $9800
                                            ;
                                            ;        Em suma, os tiles ocupam exatamente de $8000 e $97FF, onde começa o nosso tilemap em $9800 ^^
    ld bc, layout.fmaps - layout.maps       ; Calculamos o tamanho totla (em bytes) do tilemap em BC

    .copiar_meu_tilemaps:
    ld a, [de]                              ; Pegamos o byte atual do tilemap na ROM e guardamos em A
    ld [hl+], a                             ; Jogamos esse byte na VRAM e avançamos HL para o próximo espaço.
    inc de                                  ; Avançamos DE para ler o próxmio byte na ROM
    dec bc                                  ; Decrementamos 1 do nosso contador total
    ld a, b                                 ; Trazemos o byte alto (high byte) para A
    or a, c                                 ; O resultado só zera quando o BC chegar a 0
    jp nz, .copiar_meu_tilemaps             ; Enquanto não zerar, voltamos para copiar o próximo byte

    ld a, 1                                 ; Selecionamos o Banco 1 da VRAM
    ldh [$ff4f], a                          ; Então, abrimos o Bank 1 :)
    ;; ┌───────────┬────────────┬──────────┬──────────┬───────┬─────────────────┐
    ;; │ Bit       │     7      │     6    │     5    │   4   │        3        │
    ;; ├───────────┼────────────┼──────────┼──────────┼───────┼─────────────────┤
    ;; │ Atributos │ Prioridade │ Inversão │ Inversão │ Banco │ Paleta de Cores │
    ;; │    BG     │            │     Y    │     X    │       │                 │
    ;; └───────────┴────────────┴──────────┴──────────┴───────┴─────────────────┘
    ;;                 Veja mais: gbdev.io/pandocs/Tile_Maps.html
    ld hl, $9800                            ; Definimos o endereço inicial $9800
    ld bc, $0400                            ; Total de tiles no mapa: 32 · 32 = 1.024 bytes

    .copiar_meu_atributo:
    xor a                                   ; Zeramos A para limpar os atributos do tile
    ld [hl+], a                             ; Gravamos o atributo no Banco 1 e avançamos HL
    dec bc                                  ; Decrementamos 1 do nosso contador total
    ld a, b                                 ; Trazemos o byte alto (high byte) para A
    or a, c                                 ; O resultado só zera quand BC chegar a 0
    jp nz, .copiar_meu_atributo             ; Enquanto não zerar, voltamos para limpar o próximo atributo

    xor a                                   ; Zeramos A
    ldh [$ff4f], a                          ; Abrimos o Banco 0 da VRAM (de novo)
    ;; ┌───────────┬────────────┬──────────┬──────────────────────────────────────────────┐
    ;; │ Bit       │     7      │     6    │     5       4       3      2      1       0  │
    ;; ├───────────┼────────────┼──────────┼──────────────────────────────────────────────┤
    ;; │    BGPI   │    Auto    │          │                     ENDEREÇO                 │
    ;; │           │ Icnremento │          │                                              │
    ;; └───────────┴────────────┴──────────┴──────────────────────────────────────────────┘
    ;;                 Veja mais: gbdev.io/pandocs/Palettes.html
    ld a, (1 << 7) | 0                      ; Utilizamos o bit 7 (Auto-Incremento) e apontamos para o índice 0 da paleta
    ldh [$ff68], a                          ; Repassamos o valor de A para o registrador $FF68 (BCPS).

    ld hl, layout.rgb                       ; Apontamos HL para onde as cores RGB da nossa paleta  começam na ROM
    ld b,  8                                ; Definimos o contador com 8 bytes (4 cores x 2 bytes)

    .copiar_minha_paleta:
    ld a, [hl+]                             ; Pegamos o byte atual da cor RGB na ROM e avançamos HL para o próximo
    ldh [$ff69], a                          ; Gravamos esse byte no registrador $FF69
    dec b                                   ; Decrementamos 1 do nosso contador de 8 bytes
    jp nz, .copiar_minha_paleta             ; Equnato B não zerar, voltamos para carregar o restante

    ld a, (1 << 7) | (1 << 4) | (1 << 0)    ; Ativamos o LCDC
    ldh [$ff40], a                          ; Repassamos o valor de A no registrador $FF40 (LCDC)
    ret


    section "Layout - Tile(map)s e Paleta", rom0
layout:
    .tiles:
    include "renderizar/tiles/layout.2bpp"
    .ftiles:

    .maps:
    include "renderizar/tiles/layout.tilemap"
    .fmaps:

    .rgb:
    include "renderizar/tiles/layout.rgb"
    .frgb:
