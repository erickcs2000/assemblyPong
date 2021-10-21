; This is a basic template file for writing 48K Spectrum code.

AppFilename             equ "NewFile"                   ; What we're called (for file generation)

AppFirst                equ $8000                       ; First byte of code (uncontended memory)

                        zeusemulate "48K","ULA+"        ; Set the model and enable ULA+


; Start planting code here. (When generating a tape file we start saving from here)

                        org AppFirst                    ; Start of application
CHANOPEN                equ 5633
PRINT                   equ 8252

AppEntry                nop
                        ld a,2
                        call CHANOPEN
Inicializacion          ld a, '0'

comienzaRonda           ld de, Pala
                        ld bc, 4
                        call PRINT

;===
;Bucle de Menu
;===
UpdateMenu              nop
                        call movPelota
                        JP UpdateMenu
;========
;teclado
;========
teclado                 LD A, 0DFH               ;Lectura de teclado
                        IN A, (0FEH)             ; Semifila YUIOP
                        LD B, A
                        bit 2, b                ;bit 2
                        call z,movIzq           ;Tecla pulsada i ---> bit 2 =0 --> salto a movizq
                        bit 0,b
                        call z,movDer           ;Tecla pulsada p salto a movder
                        ret
movIzq                  push de                 ; Guardo en el stack de y bc
                        push bc
                        ld a, (Pala + 2)        ;Choque movizq compara la pala con la columna 0
                        cp 0
                        jr z, volver            ;si topo con la columna 0 vuelvo a otra iteraccion

                        ld (Borrador + 2), a       ;sino he chocado con la columna
                        ld a, (Pala + 1)               ;captura Columna de Pala
                        ld (Borrador + 1), a            ; Borro la pala imprimiendo borrar
                        ld de, Borrador
                        ld bc, 4
                        call PRINT                     ; omprimo borrar
AhoraMuevoPalaIzq       ld a,(Pala +2)                 ; Ahora moevo la pala a la izq
                        dec a                          ; para ello decremento la posicion x de la pala
                        ld (Pala +2), a
                        ld de, Pala
                        ld bc, 4
                        call PRINT                      ; Imprimo pala nueva

volver                  pop bc                          ; Recupero los registros bc y de
                        pop de
                        ret

movDer                  push de                         ; mover pala a la derecha
                        push bc
                        ld a, (Pala +2)
                        cp 31                            ; tope derecho
                        jr z, volver
                        ld (Borrador + 2), a
                        ld a, (Pala+  1)
                        ld (Borrador + 1), a
                        ld de, Borrador
                        ld bc, 4
                        call PRINT
                        ld a, (Pala + 2)
                        inc a
                        ld (Pala + 2), a
                        ld de, Pala
                        ld bc, 4
                        call PRINT
                        pop bc
                        pop de
                        ret

;Retardo
Retardo                 NOP
                        halt
                        halt
                        ret


;===
;Buscle del juego
;===
;---Pelota Borrador
movPelota               ld a,(Pelota+1)
                        ld (Borrador+1), a
                        ld a,(Pelota+2)
                        ld (Borrador+2), a
                        ld de , Borrador
                        ld bc , 4
                        call PRINT

;---Mover la pelota
                        ld a, (dirX)
                        ld b, a
                        ld a, (Pelota+1)
                        add a, b
                        ld (Pelota+1), a
                        ld a, (dirY)
                        ld b, a
                        ld a, (Pelota+2)
                        add a, b
                        ld (Pelota+2), a
;---Dibujar la pelota
                        ld de, Pelota
                        ld bc, 4
                        call PRINT
                        call teclado

;---Colisiones
                        LD A, (dirX)
                        LD B, A
                        LD A, (Pelota+1)
                        ADD A,B
                        SUB 22
                        JP Z,RestarVida               ; Se pierde vida
                        SUB -22
                        JP Z,InvertirDirX               ; Colision superior
                        SUB 21                          ; Si esta el la fila 20...
                        JP Z, ColisionConPala           ; ... comprobar si colisiona con la pala

ColisionEnY             LD A, (dirY)
                        LD B, A
                        LD A, (Pelota+2)
                        ADD A,B
                        SUB -1                          ; Se resta -1 que seria la posicion 0 mas la direccion -1
                        JP Z,InvertirDirY               ; El flag Z es 0 si la resta no cambia de signo
                        SUB 33
                        JP Z,InvertirDirY

FinColisiones           LD A, (posY)
                        INC A
                        LD (posY), A
                        SUB A, 32
                        JP Z, RotarPosicion


Pausas                  halt
                        halt
                        halt
                        halt
                        halt
                        JP movPelota
;=============
;Funciones
;=============
;---Bola
InicializarBola         LD BC,00h
                        ld a,(Pelota+1)
                        ld (Borrador+1), a
                        ld a,(Pelota+2)
                        ld (Borrador+2), a
                        ld de , Borrador
                        ld bc , 4
                        call PRINT

                        LD A, (posY)
                        LD (Pelota+2), A
                        LD A, 10
                        LD (Pelota+1), A
                        call comienzaRonda
                        JP Pausas

RotarPosicion           LD A, 0
                        LD (posY), A
                        JP Pausas
;---Colisiones
InvertirDirX            LD A,(dirX)
                        NEG
                        LD (dirX), A
                        JP ColisionEnY

InvertirDirY            LD A, (dirY)
                        NEG
                        LD (dirY), A
                        JP FinColisiones

ColisionConPala         LD A, (Pelota+2)
                        LD B, A
                        LD A, (Pala+2)
                        SUB B
                        JP Z, SumarPunto
                        JP ColisionEnY

;---Puntuacion
SumarPunto              ld A, (Puntos)                           ;Asignamos a 'A' el valor de la variable Puntos
                        INC A                                    ;Incrementamos el valor de A en uno
                        ld (Puntos), A                           ;Asignamos a Puntos el valor de A incrementado anteriormente

                        ld A, (Puntos)                           ;Asiganmos el valor que vamos a comparar
                        cp 1                                     ;Comparamos si su valor es 1
                        jr z, Uni1                               ;Saltamos a la funcion Uni1 que imprime 1 en las unidades

                        cp 2                                     ;Comparamos si su valor es 2
                        jr z, Uni2                               ;Saltamos a la funcion Uni2 que imprime 2 en las unidades

                        cp 3                                     ;Comparamos si su valor es 3
                        jr z, Uni3                               ;Saltamos a la funcion Uni3 que imprime 3 en las unidades

                        cp 4                                     ;Comparamos si su valor es 4
                        jr z, Uni4                               ;Saltamos a la funcion Uni4 que imprime 4 en las unidades

                        cp 5                                     ;Comparamos si su valor es 5
                        jr z, Uni5                               ;Saltamos a la funcion Uni5 que imprime 5 en las unidades

                        cp 6                                     ;Comparamos si su valor es 6
                        jr z, Uni6                               ;Saltamos a la funcion Uni6 que imprime 6 en las unidades

                        cp 7                                     ;Comparamos si su valor es 7
                        jr z, Uni7                               ;Saltamos a la funcion Uni7 que imprime 7 en las unidades

                        cp 8                                     ;Comparamos si su valor es 8
                        jr z, Uni8                               ;Saltamos a la funcion Uni8 que imprime 8 en las unidades

                        cp 9                                     ;Comparamos si su valor es 9
                        jr z, Uni9                               ;Saltamos a la funcion Uni9 que imprime 9 en las unidades

                        cp 10                                    ;Comparamos si su valor es 10
                        ld a, 0                                  ;Damos a 'a' el valor de 0
                        ld (Puntos), a                           ;Damos a Puntos el valor de a(0)
                        ld de, PosPuntos0                        ;Asignamos a 'de' la variable de PosPuntos
                        ld bc, 4                                 ;Asignamos una cantidad de bits a 'de'
                        call PRINT                               ;Saltamos a la funcion Pos10 que imprime las decenas
                        jr z, Uni10




;---Vidas
RestarVida              JP InicializarBola              ; Se llama cuiando hay que restar una vida

;==========
;Posiciones
;==========

;================
;IMPRIME UNIDADES
;================

;IMPRIME 1
Uni1                    ld de, PosPuntos1
                        ld bc, 4
                        call PRINT

                        JP InvertirDirX                          ;Aplicamos el rebote a la bola
;IMPRIME 2
Uni2                    ld de, PosPuntos2
                        ld bc, 4
                        call PRINT
                        JP InvertirDirX                          ;Aplicamos el rebote a la bola
;IMPRIME 3
Uni3                    ld de, PosPuntos3
                        ld bc, 4
                        call PRINT
                        JP InvertirDirX                          ;Aplicamos el rebote a la bola
;IMPRIME 4
Uni4                    ld de, PosPuntos4
                        ld bc, 4
                        call PRINT
                        JP InvertirDirX                          ;Aplicamos el rebote a la bola
;IMPRIME 5
Uni5                    ld de, PosPuntos5
                        ld bc, 4
                        call PRINT
                        JP InvertirDirX                          ;Aplicamos el rebote a la bola
;IMPRIME 6
Uni6                    ld de, PosPuntos6
                        ld bc, 4
                        call PRINT
                        JP InvertirDirX                          ;Aplicamos el rebote a la bola
;IMPRIME 7
Uni7                    ld de, PosPuntos7
                        ld bc, 4
                        call PRINT
                        JP InvertirDirX                          ;Aplicamos el rebote a la bola
;IMPRIME 8
Uni8                    ld de, PosPuntos8
                        ld bc, 4
                        call PRINT
                        JP InvertirDirX                          ;Aplicamos el rebote a la bola
;IMPRIME 9
Uni9                    ld de, PosPuntos9
                        ld bc, 4
                        call PRINT
                        JP InvertirDirX                          ;Aplicamos el rebote a la bola
;===============
;IMPRIME DECENAS
;===============
Uni10                   ld a, (contDecenas)                      ;Asignamos a 'a' el valor de la variable contDecenas
                        inc a                                    ;Incrementamos el valor de 'a'
                        ld (contDecenas), a                      ;Asignamos el valor de 'a' a contDecenas
                        ld a, (contDecenas)                      ;Asignamos el valor que vamos a comparar para ver en que decena estamos
                        cp 1                                     ;Comparamos si su valor es 1
                        jp z, Dec10                              ;Saltamos a la funcion Dec10 que imprime 1 en las decenas

                        cp 2                                     ;Comparamos si su valor es 2
                        jp z, Dec20                              ;Saltamos a la funcion Dec20 que imprime 2 en las decenas

                        cp 3                                     ;Comparamos si su valor es 3
                        jp z, Dec30                              ;Saltamos a la funcion Dec30 que imprime 3 en las decenas

                        cp 4                                     ;Comparamos si su valor es 4
                        jp z, Dec40                              ;Saltamos a la funcion Dec40 que imprime 4 en las decenas

                        cp 5                                     ;Comparamos si su valor es 5
                        jp z, Dec50                              ;Saltamos a la funcion Dec50 que imprime 5 en las decenas

                        cp 6                                     ;Comparamos si su valor es 6
                        jp z, Dec60                              ;Saltamos a la funcion Dec60 que imprime 6 en las decenas

                        cp 7                                     ;Comparamos si su valor es 7
                        jp z, Dec70                              ;Saltamos a la funcion Dec70 que imprime 7 en las decenas

                        cp 8                                     ;Comparamos si su valor es 8
                        jp z, Dec80                              ;Saltamos a la funcion Dec80 que imprime 8 en las decenas

                        cp 9                                     ;Comparamos si su valor es 9
                        jp z, Dec90                              ;Saltamos a la funcion Dec90 que imprime 9 en las decenas

                        cp 10                                    ;Comparamos si su valor es 10
                        jp z, Cont0                              ;Saltamos a la funcion Cont0 que borra las decenas para tener un bucle
;IMPRIME 1
Dec10                   ld de, PosPuntos10;
                        ld bc, 4
                        call PRINT
                        JP InvertirDirX                          ;Aplicamos el rebote a la bola
;IMPRIME 2
Dec20                   ld de, PosPuntos20
                        ld bc, 4
                        call PRINT
                        JP InvertirDirX                          ;Aplicamos el rebote a la bola
;IMPRIME 3
Dec30                   ld de, PosPuntos30
                        ld bc, 4
                        call PRINT
                        JP InvertirDirX                          ;Aplicamos el rebote a la bola
;IMPRIME 4
Dec40                   ld de, PosPuntos40
                        ld bc, 4
                        call PRINT
                        JP InvertirDirX                          ;Aplicamos el rebote a la bola
;IMPRIME 5
Dec50                   ld de, PosPuntos50
                        ld bc, 4
                        call PRINT
                        JP InvertirDirX                          ;Aplicamos el rebote a la bola
;IMPRIME 6
Dec60                   ld de, PosPuntos60
                        ld bc, 4
                        call PRINT
                        JP InvertirDirX                          ;Aplicamos el rebote a la bola
;IMPRIME 7
Dec70                   ld de, PosPuntos70
                        ld bc, 4
                        call PRINT
                        JP InvertirDirX                          ;Aplicamos el rebote a la bola
;IMPRIME 8
Dec80                   ld de, PosPuntos80
                        ld bc, 4
                        call PRINT
                        JP InvertirDirX                          ;Aplicamos el rebote a la bola
;IMPRIME 9
Dec90                   ld de, PosPuntos90
                        ld bc, 4
                        call PRINT
                        JP InvertirDirX                          ;Aplicamos el rebote a la bola

;IMPRIME 0 EN LAS DECENAS PARA GENERAR UN BUCLE
Cont0                   ld A, 0                                  ;Asigna a 'A' el valor 0
                        ld (contDecenas), A                      ;Asigna el valor de 'A' a la variable contDecenas
                        ld de, BorradorDec                       ;Asignamos el char " " a de
                        ld bc, 4                                 ;Asiganamos bits
                        call PRINT                               ;Imprimimos el espacio en blanco
                        JP InvertirDirX                          ;Aplicamos el rebote a la bola

;=====
;Variables
;=====

dirX                    defb 1
dirY                    defb -1
Puntos                  defb 0
PuntosTotales           defb 0
posY                    defb 15
Pelota                  defb 22, 10,15, "O"
Borrador                defb 22 ,0,0, " "
Pala                    defb 22, 21,13, "="

contDecenas              defb 0
PosPuntos0               defb 22, 0,1, "0"
PosPuntos1               defb 22, 0,1, "1"
PosPuntos2               defb 22, 0,1, "2"
PosPuntos3               defb 22, 0,1, "3"
PosPuntos4               defb 22, 0,1, "4"
PosPuntos5               defb 22, 0,1, "5"
PosPuntos6               defb 22, 0,1, "6"
PosPuntos7               defb 22, 0,1, "7"
PosPuntos8               defb 22, 0,1, "8"
PosPuntos9               defb 22, 0,1, "9"

BorradorDec                defb 22 ,0,0, " "
PosPuntos10               defb 22, 0,0, "1"
PosPuntos20               defb 22, 0,0, "2"
PosPuntos30               defb 22, 0,0, "3"
PosPuntos40               defb 22, 0,0, "4"
PosPuntos50               defb 22, 0,0, "5"
PosPuntos60               defb 22, 0,0, "6"
PosPuntos70               defb 22, 0,0, "7"
PosPuntos80               defb 22, 0,0, "8"
PosPuntos90               defb 22, 0,0, "9"

; Stop planting code after this. (When generating a tape file we save bytes below here)
AppLast                 equ *-1                         ; The last used byte's address

; Generate some useful debugging commands

                        profile AppFirst,AppLast-AppFirst+1     ; Enable profiling for all the code

; Setup the emulation registers, so Zeus can emulate this code correctly

Zeus_PC                 equ AppEntry                            ; Tell the emulator where to start
Zeus_SP                 equ $FF40                               ; Tell the emulator where to put the stack

; These generate some output files

                        ; Generate a SZX file
                        output_szx AppFilename+".szx",$0000,AppEntry    ; The szx file

                        ; If we want a fancy loader we need to load a loading screen
;                        import_bin AppFilename+".scr",$4000            ; Load a loading screen

                        ; Now, also generate a tzx file using the loader
                        output_tzx AppFilename+".tzx",AppFilename,"",AppFirst,AppLast-AppFirst,1,AppEntry ; A tzx file using the loader

