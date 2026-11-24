    section "Ponto de Entrada", rom0[$0100]                     ;           Inicializador do programa
    nop
    jp main

    section "Cabeçalho", rom0[$0104]                            ;           Logo da Nintedo
    ds $0134 - @, 0                                             ;           Logo
    db "CHAINSAWMAN"                                            ;           Título do jogo
    ds $0143 - @, 0                                             ;           Flag do Game Boy Color (CGB)
    db $c0                                                      ;           Apenas o CGB
    ds $0150 - @, 0

    section "Código Principal", rom0[$0150]
main:
    di
    ld sp, $fffe                                                ;           High Ram (HRAM)

    call renderizar_layout
    call renderizar_menu

spin:
    jr spin
