    section "VBlank - LY", rom0
vblank::
    .aguarde:
    ldh a, [$ff44]                                  ;   LY
    cp a, 144                                       ;   Compare se A for '0' (A != 0), continue rodando
    jr nz, .aguarde                                 ;   Aguarde vblank
    ret
