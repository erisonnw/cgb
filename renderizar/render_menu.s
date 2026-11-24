    section "Renderizar Menu do Jogo", rom0
renderizar_menu::
    call vblank                   ; Invocamos o LY (V-Blank) para que tudo rode em conforme
    ;; ┌───────────┬────────────┬─────────┬─────────┬───────────────┬─────────────────┬─────────┬─────────┬────────────────┐
    ;; │ Bit       │     7      │    6    │    5    │       4       │       3         │    2    │   1     │       0        │
    ;; ├───────────┼────────────┼─────────┼─────────┼───────────────┼─────────────────┼─────────┼─────────┼────────────────┤
    ;; │ Controle  │   Ativar   │ Janela  │ Ativar  │ Background e  │ Background      │   OBJ   │ Ativar  │      OBJ       │
    ;; │   LCD     │ LCD e PPU  │ Tilemap │ Janela  │ Janela Tiles  │ Janela Tilemap  │   Size  │  OBJ    │ Ativar Janela  │
    ;; └───────────┴────────────┴─────────┴─────────┴───────────────┴─────────────────┴─────────┴─────────┴────────────────┘
    ;;                            Veja mais sobre: https://gbdev.io/pandocs/LCDC.html
    xor a                                   ; Zeramos a para apagar todos os bits
                                            ; Precisamos da tela desligada para usarmos a VRAM sem danificar
    ldh [$ff40], a                          ; Mandamos esse A para o registrador $FF40 (LCDC)

    xor a                                   ; Zeramos A novamente
    ldh [$ff4f], a                          ; Abrimos o Banco 0 da VRAM através do registrador $FF4F (VBK)
    ;; ┌────────────────────────────────────┬─────────────┬─────────────┬─────────────┐
    ;; │ Identificações de tiles para...    │   Bloco 0   │   Bloco 1   │   Bloco 2   │
    ;; │                                    │ $8000–87FF  │ $8800–8FFF  │ $9000–97FF  │
    ;; ├────────────────────────────────────┼─────────────┼─────────────┼─────────────┤
    ;; │ Objetos                            │    0–127    │   128–255   │      —      │
    ;; │ BG/Win, se LCDC.4=1                │    0–127    │   128–255   │      —      │
    ;; │ BG/Win, se LCDC.4=0                │      —      │   128–255   │    0–127    │
    ;; └────────────────────────────────────┴─────────────┴─────────────┴─────────────┘
    ;;             Veja mais sobre: https://gbdev.io/pandocs/Tile_Data.html
    ld de, menu.tiles                       ; Apontamos DE para onde nosso tiles do menu começam na ROM
    ld hl, $8800                            ; Agora apontamos HL para o Bloco 1 da VRAM ($8800)
                                            ; NOTA: Como o layout já ocupou o início ($8000), jogamos os tiles do menu aqui
                                            ;       para não foder o que já está na tela :)
    ld bc, menu.ftiles - menu.tiles         ; Calculando o tamanho (em bytes) dos tiles para servir de controlador em BC

    .copiar_meu_tiles:
    ld a, [de]                              ; Pegamos o byte do tile na ROM e guardamos em A
    ld [hl+], a                             ; Jogamos esse byte na VRAM e avançamos HL  para o próximo espaço
    inc de                                  ; Avançamos DE para ler o próximo byte na ROM
    dec bc                                  ; Decrementamos 1 do nosso contador total
    ld a, b                                 ; Trazemos o byte alto (high byte) para A
    or a, c                                 ; O resultaod só zera quando o BC chegar em 0
    jp nz, .copiar_meu_tiles                ; Enquanto não zerar, voltamos para copiar o próximo byte

    ld de, menu.maps                        ; Agora apontamos DE para onde o tilemap do menu começa na ROM
    ld hl, $9840                            ; Apontamos HL para o tilemap em $9840 (deslocado em relação ao $9800)
                                            ; AUTOR: Começamos em $9840 para posicionar o menu mais abaixo no mapa do BG,
                                            ;        sem foder o topo do layout :D
    ld bc, menu.fmaps - menu.maps           ; Calculamos o tamanho total (em byte) do tilemap em BC
    ;; ┌───────────┬────────────┬──────────┬──────────┬───────┬─────────────────┐
    ;; │ Bit       │     7      │     6    │     5    │   4   │        3        │
    ;; ├───────────┼────────────┼──────────┼──────────┼───────┼─────────────────┤
    ;; │ Atributos │ Prioridade │ Inversão │ Inversão │ Banco │ Paleta de Cores │
    ;; │    BG     │            │     Y    │     X    │       │                 │
    ;; └───────────┴────────────┴──────────┴──────────┴───────┴─────────────────┘
    ;;                 Veja mais: gbdev.io/pandocs/Tile_Maps.html
    .copiar_meu_tilemaps:
    ld a, [de]                              ; Pegamos o índice do tilemap da ROM
    cp $00                                  ; Comparamos com $00 para ver se é um tile vazio
    jr z, .transparente                     ; Se for $00, pulamos para não desenhar nada por cima

    add a, $80                              ; Somamos $80 porque os tiles do menu foram carregados em $8800
    ld [hl], a                              ; Gravamos o índice ajustado no tilemap (Banco 0 da VRAM)

    ld a, 1                                 ; Selecionamos o Banco 1 da VRAM
    ldh [$ff4f], a                          ; Abrimos o Banco 1 para mexer nos atributos desse tile
    ld [hl], a                              ; Setamos o bit 0 do atributo (Paleta de cor BG 1) na mesma posição de HL
    xor a                                   ; Zeramos A para voltar ao Banco 0
    ldh [$ff4f], a                          ; Voltamos para o Banco 0 da VRAM

    .transparente:
    inc hl                                  ; Avançamos para a próxima posição do tilemap
    inc de                                  ; Avançamos para a próxima byte do tilemap na ROm
    dec bc                                  ; Decrementamos 1 do nosso contador total
    ld a, b                                 ; Trazemos o byte alto (high byte) para A
    or a, c                                 ; O resultado só zera quando BC chegar em 0
    jp nz, .copiar_meu_tilemaps             ; Enquanto não zerar, voltamos para o próximo byte do tilemap
    ;; ┌───────────┬────────────┬──────────┬──────────────────────────────────────────────┐
    ;; │ Bit       │     7      │     6    │     5       4       3      2      1       0  │
    ;; ├───────────┼────────────┼──────────┼──────────────────────────────────────────────┤
    ;; │    BGPI   │    Auto    │          │                     ENDEREÇO                 │
    ;; │           │ Icnremento │          │                                              │
    ;; └───────────┴────────────┴──────────┴──────────────────────────────────────────────┘
    ;;                 Veja mais: gbdev.io/pandocs/Palettes.html
    ld a, (1 << 7) | 8                      ; Ativamos Auto-Incremento (bit 7) e apontamos para o byte 8 (Paleta 1, cor 0)
    ldh [$ff68], a                          ; Repassamos o valor de A para o registrador $FF68 (BCPS)

    ld hl, menu.rgb                         ; Apontamos HL para onde as cores RGB da paleta do menu começam na ROM
    ld b, 8                                 ; Definimos o contador com 8 bytes (4 cores x 2 bytes)

    .copiar_minha_paleta:
    ld a, [hl+]                             ; Pegamos o byte atual da cor RGB na ROM e avançamos HL para o próximo
    ldh [$ff69], a                          ; Gravamos esse byte no registrador $FF69 (BCPD)
    dec b                                   ; Decrementamos 1 do nosso contador de 8 bytes
    jp nz, .copiar_minha_paleta             ; Enquanto B não zerar, voltamos para carregar o restante

    ld a, (1 << 7) | (1 << 4) | (1 << 0)    ; Ativamos o LCDC (LCD ligado, tiles em $8000/$8800, BG ativo)
    ldh [$ff40], a                          ; Repassamos o valor de A para o registrador $FF40 (LCDC)
    ret

    section "Menu - Tile(map)s e RGB", rom0
menu:
    .tiles:
    include "renderizar/tiles/menu.2bpp"
    .ftiles:

    .maps:
    include "renderizar/tiles/menu.tilemap"
    .fmaps:

    .rgb:
    include "renderizar/tiles/menu.rgb"
    .frgb:
