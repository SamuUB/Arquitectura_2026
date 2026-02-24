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
*
*  NOTAS DE DEPURACIÓN:
*    - Bug 1: Descripción
*    - Bug 2: Descripción
**************************************************************************

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