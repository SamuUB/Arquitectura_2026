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
*
*  COMENTARIOS INTERNOS:
*    - Aquí podemos dejar notas entre compañeros
*
*  SESIONES DE TRABAJO:
*    Nombre {Inicio: DD/MM/AAAA HH:MM   Fin:    DD/MM/AAAA HH:MM}
*    Samuel {24/02 15:00, 24/02 16:30}
*    Samuel {25/02 15:00, 25/02 17:00}
*
*  NOTAS DE DEPURACIÓN:
*    - Bug 1: Descripción
*    - Bug 2: Descripción
**************************************************************************

***************************************** INIT **************************************************
* Las lineas A y B deben quedar preparadas para la recepcion y transmision de caracteres        *
* mediante E/S por interrupciones. Al finalizar la ejecucion de la instruccion RTS, el puntero  *
* de pila (SP) debe apuntar a la misma direccion a la que apuntaba antes de ejecutar la         *
* instruccion BSR. Debido a la particular configuracion del emulador, esta subrutina no puede   *
* devolver ningun error y, por tanto, no se devuelve ningun valor de retorno. Se supondra que   *
* el programa que invoca a esta subrutina no deja ningun valor representativo en los registros  *
* del computador salvo el puntero de marco de pila (A6)                                         *
*************************************************************************************************
INIT:   MOVEM.L D0-D1/A0-A1,-(A7) *Guardar registros en la pila (A7)
        **************************** MR1A Y MR1B ****************************
        *Bit: 7 6 5 4 3 2 1 0                                               *
        *     ─ ─ ─ ─ ─ ─ ─ ─                                               *
        *     P P P M C C C C                                               *
        * P = paridad                                                       *
        * M = modo (asíncrono)                                              *
        * C = longitud de caracter                                          *
        MOVE.B #$13,MR1A                                                    *
        MOVE.B #$13,MR1B                                                    *
        * $13 = 0001 0011                                                   *
        * bits 3-0: 0011 (8) -> Tamaño de caracter máximo = 8 bits          *
        * bit  4:   1        -> Modo asíncrono                              *
        * bits 7-5: 000  (0) -> Paridad desactivada                         *
        *********************************************************************

        **************************** MR2A Y MR2B ****************************
        * Bit: 7 6 5 4 3 2 1 0                                              *
        *      ─ ─ ─ ─ ─ ─ ─ ─                                              *
        *      M M M E S S S S                                              *
        * M = modo de operación                                             *
        * E = eco                                                           *
        * S = bits de parada (STOP)                                         *
        MOVE.B #$07, MR2A                                                   *
        MOVE.B #$07, MR2B                                                   *
        * $07 = 0000 0111                                                   *
        * bits 3-0: 0111 -> 1 bit de parada                                 *
        * bit  4  : 0    -> Eco desactivado                                 *
        * bits 7-5: 000  -> Modo normal                                     *
        *********************************************************************

        **************************** CSRA Y CSRB ****************************
        * Bit: 7 6 5 4 | 3 2 1 0                                            *
        *      ─ ─ ─ ─ | ─ ─ ─ ─                                            *
        *     RX CLOCK | TX CLOCK                                           *
        MOVE.B #$CC,CSRA                                                    *
        MOVE.B #$CC,CSRB                                                    *
        * $CC = 1100 1100                                                   *
        * bits 7-4: 1100 -> RX = 38400 bps                                  *
        * bits 3-0: 1100 -> TX = 38400 bps                                  *
        *********************************************************************

        **************************** CRA Y CRB ******************************
        * Bit: 7 6 5 4 | 3 2 1 0                                            *
        *      ─ ─ ─ ─ | ─ ─ ─ ─                                            *
        *        M M M   T T R R                                            *
        * M = miscelaneos                                                   *
        * T = transmisión                                                   *
        * R = recepción                                                     *
        MOVE.B #%00000101,CRA                                               *
        MOVE.B #%00000101,CRB                                               *
        * %00000101                                                         *
        * bits 6-4: 000 -> sin efecto                                       *
        * bits 3-2: 01  -> Transmisión habilitada                           *
        * bits 1-0: 01  -> Recepción habilitada                             *
        *********************************************************************

        ********************************** IVR ******************************
        MOVE.B #$40,IVR                                                     *
        *********************************************************************

        ********************************** IMR ******************************
        * Bit: 7 6 5  4  | 3 2 1  0                                         *
        *      ─ ─ ── ── | ─ ─ ── ──                                        *
        *          RB TB       RA TA                                        *
        * RB/RA = mascara de recepción del canal x                          *
        * TB/TA = mascara de transmisión del canal x                        *
        MOVE.B #%00100010,IMR                                               *
        * %00100010                                                         *
        * bit 5: 1 -> RxRDYB habilitada                                     *
        * bit 4: 0 -> TxRDYB inhabilitada                                   *
        * bit 1: 1 -> RxRDYA habilitada                                     *
        * bit 0: 0 -> TxRDYA inhabilitada                                   *
        *********************************************************************

        ********************************** RTI ******************************
        * Actualiza la posición de RTI a la de IVR*4                        *
        LEA RTI, A0                                                         *
        LOAD IVR, A5                                                        *
        MULU #$4, A5                                                        *
        MOVE.L A0, A5                                                       *
        *********************************************************************

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
