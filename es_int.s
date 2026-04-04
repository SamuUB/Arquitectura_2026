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
        DC.L    INICIO          * Dirección del programa (PC)

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

;***************************************** VARIABLES **************************************************
COPIA_IMR   DC.B    0           * Copia del IMR para manipularlo en RTI

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
        MOVE.B          #%00010000,CRA          * Reinicia el puntero MR1 de linea A
        MOVE.B          #%00000011,MR1A         * 8 bits por caracter, linea A
        MOVE.B          #%00000000,MR2A         * Eco desactivado, linea A
        MOVE.B          #%11001100,CSRA         * Velocidad = 38400 bps, linea A
        MOVE.B          #%00000101,CRA          * Transmision y recepcion activados, linea A

        MOVE.B          #%00000000,ACR          * Conjunto de velocidades 1
        MOVE.B          #$40,IVR                * Vector de interrupcion en $100  [AÑADIDO]
        MOVE.L          #RTI,$100               * Poner RTI en la tabla de vectores  
        MOVE.B          #%00100010,IMR          * Habilitar RxRDY linea A (bit1) y B (bit5)
        MOVE.B          #%00100010,COPIA_IMR    * Guardar copia del IMR

        MOVE.B          #%00010000,CRB          * Reinicia el puntero MR1 de linea B
        MOVE.B          #%00000011,MR1B         * 8 bits por caracter, linea B
        MOVE.B          #%00000000,MR2B         * Eco desactivado, linea B
        MOVE.B          #%11001100,CSRB         * Velocidad = 38400 bps, linea B
        MOVE.B          #%00000101,CRB          * Transmision y recepcion activados, linea B

        BSR             INI_BUFS                * Inicializar buffers internos  
        RTS
**************************** FIN INIT *********************************************************


***************************************** RTI ***********************************************************        
* La invocacion de la rutina de tratamiento de interrupcion es el resultado de la ejecucion             *
* de la secuencia de reconocimiento de interrupciones expuesta en la pagina 8. Entre otras              *
* acciones esta subrutina debe realizar las siguientes acciones:                                        *
* 1. Identificacion de la fuente de interrupcion.                                                       *
* 2. Tratamiento de la interrupcion                                                                     *
* 3. Situaciones "especiales"                                                                           *
*********************************************************************************************************

RTI:    
        MOVEM.L D0-D2, -(A7)            * Guardar registros que vamos a usar
        MOVE.B  ISR, D2                 * Leer el ISR para identificar la fuente de interrupcion
        AND.B   COPIA_IMR, D2           * Filtrar solo las interrupciones habilitadas (aplicar mascara)

        ***************************************************
        ***** COMPROBAMOS RECEPCION LINEA A ***************
        ***************************************************
        BTST    #0, D0                  * Bit 0 = RxRDYA?
        BEQ     TX_A                    * Si no, mirar Transmision linea A
        MOVE.B  RBA, D1                 * Leer caracter recibido en el buffer A
        CLR.L   D2                      * D2 = 0 para indicar linea A
        MOVE.L  D2,D0                   * Descriptor 0 = linea A
        BSR     ESCCAR                  * Guardar en buffer interno

        * Si buffer lleno (D0 = 0xFFFFFFFF), el caracter ya se leyo del hardware
        * y se descarta automaticamente, no hay que hacer nada mas

RX_B:
    ***************************************************
    ***** COMPROBAR RECEPCION LINEA B *****************  
    ***************************************************
        BTST    #5, D2                  * Bit 5 = RxRDYB?  
        BEQ     TX_A                    * Si no, mirar Transmision linea A

        MOVE.B  RBB, D1                 * Leer caracter recibido en el buffer B
        MOVE.L  #1, D0                  * Descriptor 1 = linea B
        BSR     ESCCAR                  * Guardar en buffer interno
        * [ELIMINADO: ADDQ.L #6, A7 incorrecto, ESCCAR no usa pila]

TX_A:
    ***************************************************
    ***** COMPROBAR TRANSMISION LINEA A ***************
    ***************************************************
        BTST    #0, D2                  * Bit 0 = TxRDYA?  [CORREGIDO: usamos D2 ya filtrado del ISR]
        BEQ     TX_B                    * Si no, mirar Transmision linea B

        MOVE.L  #2, D0                  * Descriptor 2 = transmision linea A  [CORREGIDO: LEECAR recibe desc en D0, no en pila]
        BSR     LEECAR                  * Intentar leer del buffer interno
        * [ELIMINADO: ADDQ.L #2, A7 incorrecto, LEECAR no usa pila]

        CMP.L   #-1, D0                 * Buffer vacio?
        BEQ     DESH_TX_A               * Si vacio, deshabilitar interrupcion TX

        MOVE.B  D0, TBA                 * Enviar caracter por linea A
        BRA     TX_B

DESH_TX_A:
        BCLR    #0, COPIA_IMR           * Deshabilitar TxRDYA en la copia  [CORREGIDO: operar sobre COPIA_IMR, no leer IMR]
        MOVE.B  COPIA_IMR, IMR          * Actualizar el IMR real

TX_B:
    ***************************************************
    ***** COMPROBAR TRANSMISION LINEA B ***************
    ***************************************************
        BTST    #4, D2                  * Bit 4 = TxRDYB?  [CORREGIDO: usamos D2 ya filtrado del ISR]
        BEQ     FIN_RTI                 * Si no, terminar

        MOVE.L  #3, D0                  * Descriptor 3 = transmision linea B  [CORREGIDO: desc en D0, no en pila]
        BSR     LEECAR                  * Intentar leer del buffer interno
        * [ELIMINADO: ADDQ.L #2, A7 incorrecto]

        CMP.L   #-1, D0                 * Buffer vacio?
        BEQ     DESH_TX_B               * Si vacio, deshabilitar interrupcion TX

        MOVE.B  D0, TBB                 * Enviar caracter por linea B
        BRA     FIN_RTI

DESH_TX_B:
        BCLR    #4, COPIA_IMR           * Deshabilitar TxRDYB en la copia  [CORREGIDO: operar sobre COPIA_IMR]
        MOVE.B  COPIA_IMR, IMR          * Actualizar el IMR real

FIN_RTI:
        MOVEM.L (A7)+, D0-D3/A0-A2     * Restaurar registros
        RTE
*************************************************************** FIN RTI ***********************************************************

***************************************** SCAN **************************************************
* Lee caracteres del buffer interno de recepcion y los copia al buffer del usuario.            *
* Comportamiento no bloqueante: devuelve inmediatamente lo que haya disponible.                *
* Al finalizar la ejecucion de la instruccion RTS, el puntero de pila (SP) debe apuntar a la  *
* misma direccion a la que apuntaba antes de ejecutar la instruccion BSR.                      *
*                                                                                               *
* Entrada (parametros en pila):                                                                 *
*    8(A6)  -> puntero al buffer destino donde se copian los caracteres leidos                  *
*    12(A6) -> descriptor de linea (0 = linea A, 1 = linea B)                                  *
*    14(A6) -> numero maximo de caracteres a leer                                               *
*                                                                                               *
* Salida:                                                                                       *
*    D0 -> numero de caracteres leidos (0 si buffer vacio, -1 si descriptor invalido)          *
*************************************************************************************************
SCAN:
        LINK    A6,#0
        MOVEM.L D2-D4/A2,-(A7)    * Salvaguarda de registros

        MOVE.L  8(A6),A2          * A2 = puntero al buffer destino
        MOVE.W  12(A6),D2         * D2 = descriptor (0=A, 1=B)
        MOVE.W  14(A6),D3         * D3 = tamaño maximo
        CLR.L   D4                * D4 = contador de caracteres leidos

*----------- Validacion de parametros -----------*
        CMP.W   #1,D2
        BHI     SC_ERR            * Descriptor fuera de rango

        TST.W   D3
        BEQ     SC_FIN             * Tamaño nulo, devolver 0

*----------- Seleccion de canal -----------*
        TST.W   D2
        BEQ     SC_LA

*=========== LECTURA LINEA B ===========*
SC_LB:
        MOVEQ   #1,D0             * ID buffer recepcion B
        BSR     LEECAR            * Intentar leer del buffer interno
        CMP.L   #-1,D0            * Buffer vacio?
        BEQ     SC_FIN              * Si vacio, terminar

        MOVE.B  D0,(A2)+          * Copiar caracter al buffer destino y avanzar puntero
        ADDQ.L  #1,D4             * Incrementar contador
        SUBQ.W  #1,D3             * Decrementar tamaño restante
        BNE     SC_LB
        BRA     SC_FIN

*=========== LECTURA LINEA A ===========*
SC_LA:
        MOVEQ   #0,D0             * ID buffer recepcion A
        BSR     LEECAR            * Intentar leer del buffer interno
        CMP.L   #-1,D0            * Buffer vacio?
        BEQ     SC_FIN              * Si vacio, terminar

        MOVE.B  D0,(A2)+          * Copiar caracter al buffer destino y avanzar puntero
        ADDQ.L  #1,D4             * Incrementar contador
        SUBQ.W  #1,D3             * Decrementar tamaño restante
        BNE     SC_LA

*----------- Finalizacion -----------*
SC_FIN:
        MOVE.L  D4,D0             * Devolver en D0 el numero de caracteres leidos
        BRA     SC_RESTORE

SC_ERR:
        MOVEQ   #-1,D0            * Codigo de error por descriptor invalido

SC_RESTORE:
        MOVEM.L (A7)+,D2-D4/A2   * Restaurar registros
        UNLK    A6
        RTS
**************************** FIN SCAN ********************************************************

*==============================================
*  PRINT (buffer, descriptor, tamaño)
*---------------------------------------------- COMPROBAR
*  Entrada:
*    8(A6)  -> puntero a buffer
*    12(A6) -> descriptor (0=A, 1=B)
*    14(A6) -> número de caracteres
*
*  Salida:
*    D0 -> número de caracteres aceptados
*           (-1 si descriptor inválido)
*==============================================

PRINT:
        LINK    A6,#-12
        MOVEM.L D2-D3/A1,-(A7)     * Salvaguarda de registros

        MOVE.L  8(A6),A1           * A1 = puntero a buffer origen
        MOVE.W 12(A6),D2           * D2 = descriptor (línea)
        MOVE.W 14(A6),D3           * D3 = tamaño restante
        CLR.L   D5                 * D5 = contador de caracteres insertados

*----------- Validación de parámetros -----------*
        CMP.W   #1,D2
        BHI     .ERROR             * Descriptor fuera de rango

        TST.W   D3
        BEQ     FIN               * Tamaño nulo

*----------- Selección de canal -----------*
        TST.W   D2
        BEQ     LINEA_A

*=========== TRANSMISIÓN LÍNEA B ===========*
LINEA_B:
        MOVE.B  (A1)+,D1           * Leer carácter y avanzar puntero
        MOVEQ   #3,D0              * ID buffer transmisión B
        BSR     ESCCAR
        CMP.L   #-1,D0
        BEQ     .ACTIVA_B          * Buffer interno lleno

        ADDQ.L  #1,D5              * Incrementar contador
        SUBQ.W  #1,D3              * Decrementar tamaño
        BNE     .LINEA_B

ACTIVA_B:
        TST.L   D5
        BEQ     FIN               * No se insertaron datos

        BSET    #4,COPIA_IMR       * Habilitar interrupción Tx B
        MOVE.B  COPIA_IMR,IMR
        BRA     FIN

*=========== TRANSMISIÓN LÍNEA A ===========*
LINEA_A:
        MOVE.B  (A1)+,D1
        MOVEQ   #2,D0              * ID buffer transmisión A
        BSR     ESCCAR
        CMP.L   #-1,D0
        BEQ     ACTIVA_A

        ADDQ.L  #1,D5
        SUBQ.W  #1,D3
        BNE     .LINEA_A

ACTIVA_A:
        TST.L   D5
        BEQ     FIN

        BSET    #0,COPIA_IMR       * Habilitar interrupción Tx A
        MOVE.B  COPIA_IMR,IMR

*----------- Finalización -----------*
FIN:
        MOVE.L  D5,D0              * Número de caracteres aceptados
        BRA     RESTORE

ERROR:
        MOVEQ   #-1,D0             * Código de error

RESTORE:
        MOVEM.L (A7)+,D2-D3/A1     * Restaurar registros
        UNLK    A6
        RTS

*==============================================


*==============================================
* Programa Principal:
*==============================================

INICIO:     MOVE.L  #$7000,A7
            MOVE.L  #BUS_ERROR,8
            MOVE.L  #ADDRESS_ER,12
            MOVE.L  #ILLEGAL_IN,16
            MOVE.L  #PRIV_VIOLT,32
            MOVE.L  #ILLEGAL_IN,40
            MOVE.L  #ILLEGAL_IN,44
            BSR     INIT
            MOVE.W  #$2000,SR

BUCLE:
            * --- SCAN por línea A ---
            MOVE.W  #100,-(A7)         * Tamaño máximo a leer
            MOVE.W  #0,-(A7)           * Descriptor = 0 → línea A
            MOVE.L  #BUFFER,-(A7)      * Buffer donde guardar lo leído
            BSR     SCAN
            ADD.L   #8,A7              * Limpiar pila

            * --- Si no se leyó nada, volver a intentar ---
            CMP.L   #0,D0
            BEQ     BUCLE

            * --- PRINT por línea A con lo que se leyó ---
            MOVE.W  D0,-(A7)           * Tamaño = lo que se leyó
            MOVE.W  #1,-(A7)           * Descriptor = 0 → línea A
            MOVE.L  #BUFFER,-(A7)      * Buffer con los caracteres
            BSR     PRINT
            ADD.L   #8,A7              * Limpiar pila

            BRA     BUCLE

BUFFER:     DS.B    200                * Espacio para los caracteres
INCLUDE bib_aux.s
