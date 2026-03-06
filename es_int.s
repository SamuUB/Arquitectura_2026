**************************************************************************
*   PROYECTO: Proyecto E/S por interrupciones
*   ARCHIVO: es_int.s
*   FECHA CREACIÓN: 24/02/2026
*   AUTORES: Samuel Muñoz-Guerra Gómez y Zhou Chengjian 
*   CONTACTO: s.munoz-guerra@alumnos.upm.es y chengjian.zhou@alumnos.upm.es
*
*  OBJETIVO DEL ARCHIVO:
*    Breve descripción de la función de este archivo
*
*  HISTORIAL DE CAMBIOS:
*    DD/MM - Autor - Descripción del cambio
*    24/02 - Samuel - Inicio del archivo y organización general del proyecto
*    25/02 - Samuel - Desarrollo de la subrutina INIT
*    26/02 - Samuel - Terminado INIT
*    02/03 - Samuel - Inicio RTI
*
*  COMENTARIOS INTERNOS:
*    - NO ESTOY MUY SEGURO DE LO DEL RTI, COMPRUEBALO PQ NS
*
*  SESIONES DE TRABAJO:
*    Nombre {Inicio: DD/MM/AAAA HH:MM  , Fin:    DD/MM/AAAA HH:MM}
*    Samuel {24/02 15:00, 24/02 16:30}
*    Samuel {25/02 15:00, 25/02 18:00}
*    Samuel {26/02 17:00, 26/02 19:00}
*    Samuel {02/03 15:00, 02/03 17:00}
*
*  NOTAS DE DEPURACIÓN:
*    - Bug 1: Descripción
*    - Bug 2: Descripción
**************************************************************************

* Inicializacion del SP y del PC

        ORG     $0
        DC.L    $8000           * Dirección de la pila (SP)
        DC.L    PPAL            * Dirección del programa (PC)

        ORG     $400
***************************************** EQUIVALENCIAS **************************************************
MR1A    EQU     $effc01         * Modo A 
MR2A    EQU     $effc01         * Modo A, registro 2 
SRA     EQU     $effc03         * Estado A (lectura)
CSRA    EQU     $effc03         * Selección de reloj A (escritura)
CRA     EQU     $effc05         * Control A (escritura)
TBA     EQU     $effc07         * Buffer de transmisión A (escritura)
RBA     EQU     $effc07         * Buffer de recepción A (lectura)

ACR     EQU     $effc09         * Control auxiliar
IMR     EQU     $effc0B         * Máscara de interrupción (escritura)
ISR     EQU     $effc0B         * Estado de interrupción (lectura)

MR1B    EQU     $effc11         * Modo B (escritura)
MR2B    EQU     $effc11         * de modo B, registro 2 (escritura)
SRB     EQU     $effc13         * Estado B (lectura)
CSRB    EQU     $effc13         * Selección de reloj B (escritura)
CRB     EQU     $effc15         * Control B (escritura)
TBB     EQU     $effc17         * Buffer de transmisión B (escritura)
RBB     EQU     $effc17         * Buffer de recepción B (lectura)

IVR     EQU     $effc19         * Vector de interrupción

CR      EQU     $0D             * Carriage Return
LF      EQU     $0A             * Line Feed


***************************************** INIT **************************************************
* Las lineas A y B deben quedar preparadas para la recepcion y transmision de caracteres        *
* mediante E/S por interrupciones. Al finalizar la ejecucion de la instruccion RTS, el puntero  *
* de pila (SP) debe apuntar a la misma direccion a la que apuntaba antes de ejecutar la         *
* instruccion BSR. Debido a la particular configuracion del emulador, esta subrutina no puede   *
* devolver ningun error y, por tanto, no se devuelve ningun valor de retorno. Se supondra que   *
* el programa que invoca a esta subrutina no deja ningun valor representativo en los registros  *
* del computador salvo el puntero de marco de pila (A6)                                         *
*************************************************************************************************
INIT:
        MOVE.B          #%00010000,CRA      * Reinicia el puntero MR1
        MOVE.B          #%00000011,MR1A     * 8 bits por caracter.
        MOVE.B          #%00000000,MR2A     * Eco desactivado.
        MOVE.B          #%11001100,CSRA     * Velocidad = 38400 bps.
        MOVE.B          #%00000000,ACR      * Velocidad = 38400 bps.
        MOVE.B          #%00000101,CRA      * Transmision y recepcion activados.
        RTS
**************************** FIN INIT *********************************************************


***************************************** RTI **************************************************
* La invocacion de la rutina de tratamiento de interrupcion es el resultado de la ejecucion
* de la secuencia de reconocimiento de interrupciones expuesta en la pagina 8. Entre otras
* acciones esta subrutina debe realizar las siguientes acciones:
* 1. Identificacion de la fuente de interrupcion.
* 2. Tratamiento de la interrupcion
* 3. Situaciones “especiales”

RTI:    MOVEM.L D0-D3/A0-A2, -(A7)

    ***************************************************
    ***** COMPROBAR RECEPCION LINEA A *****************
    ***************************************************
        MOVE.B  SRA, D0          * Leemos RE de la linea A
        BTST    #0, D0           * RxRDYA?
        BEQ     RX_B             * Si no, mirar Recepcion línea B

        MOVE.B  RBA, D1          * Leer caracter recibido en el buffer A
        MOVE.W  #0, D0
        * Parametro: caracter para ESCCAR       (D1)
        * Parametro: descriptor 0 = línea A     (D0)
        BSR     ESCCAR

    * Si buffer lleno (D0 = 0xFFFFFFFF), como el carácter ya se ha leido,
    * se descarta automáticamente

RX_B:
    ***************************************************
    ***** COMPROBAR RECEPCION LINEA A *****************
    ***************************************************
    MOVE.B  SRB, D0
    BTST    #0, D0           ; RxRDYB?
    BEQ     TX_A

    MOVE.B  RBB, D1
    MOVE.W  #1, D0        ; Descriptor 1 = línea B
    BSR     ESCCAR
    ADDQ.L  #6, A7

    ; ------------------------------------------------
TX_A:
    ; --- COMPROBAR TRANSMISIÓN LÍNEA A ---------------
    ; ------------------------------------------------
    MOVE.B  SRA, D0
    BTST    #2, D0           ; TxRDYA?
    BEQ     TX_B

    MOVE.W  #0, -(A7)        ; Descriptor línea A
    BSR     LEECAR
    ADDQ.L  #2, A7

    CMP.L   #-1, D0
    BEQ     DESH_TX_A        ; Buffer vacío → deshabilitar int TX

    MOVE.B  D0, TBA          ; Enviar carácter
    BRA     TX_B

DESH_TX_A:
    MOVE.B  IMR, D1
    BCLR    #0, D1           ; Deshabilitar TxRDYA
    MOVE.B  D1, IMR

    ; ------------------------------------------------
TX_B:
    ; --- COMPROBAR TRANSMISIÓN LÍNEA B ---------------
    ; ------------------------------------------------
    MOVE.B  SRB, D0
    BTST    #2, D0           ; TxRDYB?
    BEQ     FIN_RTI

    MOVE.W  #1, -(A7)        ; Descriptor línea B
    BSR     LEECAR
    ADDQ.L  #2, A7

    CMP.L   #-1, D0
    BEQ     DESH_TX_B

    MOVE.B  D0, TBB
    BRA     FIN_RTI

DESH_TX_B:
    MOVE.B  IMR, D1
    BCLR    #4, D1           ; Deshabilitar TxRDYB
    MOVE.B  D1, IMR

    ; ------------------------------------------------
FIN_RTI:
    ; Restaurar registros y salir
    ; ------------------------------------------------
    MOVEM.L (A7)+, D0-D3/A0-A2
    RTE
***************************************** PROGRAMA PRINCIPAL *******************************************
BUFFER: DS.B 2100                                       * Buffer para lectura y escritura de caracteres
PARDIR: DC.L 0                                          * Direcci´on que se pasa como par´ametro
PARTAM: DC.W 0                                          * Tama~no que se pasa como par´ametro
CONTC: DC.W 0                                           * Contador de caracteres a imprimir
DESA: EQU 0                                             * Descriptor l´ınea A
DESB: EQU 1                                             * Descriptor l´ınea B
TAMBS: EQU 30                                           * Tama~no de bloque para SCAN
TAMBP: EQU 7                                            * Tama~no de bloque para PRINT
                                                        * Manejadores de excepciones
INICIO: MOVE.L #BUS_ERROR,8                             * Bus error handler
        MOVE.L #ADDRESS_ER,12                               * Address error handler
        MOVE.L #ILLEGAL_IN,16                               * Illegal instruction handler
        MOVE.L #PRIV_VIOLT,32                               * Privilege violation handler
        MOVE.L #ILLEGAL_IN,40                               * Illegal instruction handler
        MOVE.L #ILLEGAL_IN,44                               * Illegal instruction handler
        BSR INIT
        MOVE.W #$2000,SR                                    * Permite interrupciones
    BUCPR:      MOVE.W #TAMBS,PARTAM                    * Inicializa par´ametro de tama~no
                MOVE.L #BUFFER,PARDIR                   * Par´ametro BUFFER = comienzo del buffer
    OTRAL:      MOVE.W PARTAM,-(A7)                     * Tama~no de bloque
                MOVE.W #DESA,-(A7)                      * Puerto A
                MOVE.L PARDIR,-(A7)                     * Direcci´on de lectura
    ESPL:       BSR SCAN
                ADD.L #8,A7                             * Restablece la pila
                ADD.L D0,PARDIR                         * Calcula la nueva direcci´on de lectura
                SUB.W D0,PARTAM                         * Actualiza el n´umero de caracteres le´ıdos
                BNE OTRAL                               * Si no se han le´ıdo todas los caracteres
                                                        * del bloque se vuelve a leer
                MOVE.W #TAMBS,CONTC                     * Inicializa contador de caracteres a imprimir
                MOVE.L #BUFFER,PARDIR                   * Par´ametro BUFFER = comienzo del buffer
    OTRAE:      MOVE.W #TAMBP,PARTAM                    * Tama~no de escritura = Tama~no de bloque
    ESPE:       MOVE.W PARTAM,-(A7)                     * Tama~no de escritura
                MOVE.W #DESB,-(A7)                      * Puerto B
                MOVE.L PARDIR,-(A7)                     * Direcci´on de escritura
                BSR PRINT
                ADD.L #8,A7                             * Restablece la pila
                ADD.L D0,PARDIR                         * Calcula la nueva direcci´on del buffer
                SUB.W D0,CONTC                          * Actualiza el contador de caracteres
                BEQ SALIR                               * Si no quedan caracteres se acaba
                SUB.W D0,PARTAM                         * Actualiza el tama~no de escritura
                BNE ESPE                                * Si no se ha escrito todo el bloque se insiste
                CMP.W #TAMBP,CONTC                      * Si el no de caracteres que quedan es menor que
                                                        * el tama~no establecido se imprime ese n´umero
                BHI OTRAE                               * Siguiente bloque
                MOVE.W CONTC,PARTAM
                BRA ESPE                                * Siguiente bloque
    SALIR:      BRA BUCPR
    BUS_ERROR:  BREAK                                   * Bus error handler
                NOP
    ADDRESS_ER: BREAK                                   * Address error handler
                NOP
    ILLEGAL_IN: BREAK                                   * Illegal instruction handler
                NOP
    PRIV_VIOLT: BREAK                                   * Privilege violation handler
    NOP

INCLUDE bib_aux.s
