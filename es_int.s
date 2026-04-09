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
*    30/03 - ChengJian - Correcciones de sintaxis y correccion de errores en el programa Principal
*    31/03 - ChengJian - Desarrollo de la subrutina SCAN
*    01/04 - ChengJian - Correcciones en SCAN
*    04/04 - ChengJian - Corrección de la subrutinas PRINT, SCAN y RTI,
*            arreglo de errores de compilación y ejecución de pruebas de funcionamiento
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
*    ChengJian {30/03 15:00, 30/03 17:00}
*    ChengJian {31/03 12:00, 31/03 14:00}
*    ChengJian {01/04 17:00, 01/04 18:30}
*    ChengJian {04/04 17:00, 04/04 20:00}
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
**************** MODO A ****************************************************************
MR1A    EQU     $effc01         * Modo A        
MR2A    EQU     $effc01         * Modo A, registro 2 
SRA     EQU     $effc03         * Estado A (lectura)
CSRA    EQU     $effc03         * Selección de reloj A (escritura)
CRA     EQU     $effc05         * Control A (escritura)
TBA     EQU     $effc07         * Buffer de transmisión A (escritura)
RBA     EQU     $effc07         * Buffer de recepción A (lectura)

**************** GENERAL ****************************************************************
ACR     EQU     $effc09         * Control auxiliar
IMR     EQU     $effc0B         * Máscara de interrupción (escritura)
ISR     EQU     $effc0B         * Estado de interrupción (lectura)

**************** MODO B ****************************************************************
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

***************************************** VARIABLES **************************************************
COPIA_IMR   DC.B    0           * Copia del IMR para manipularlo en RTI
            DS.B    1           * Relleno para alinear a palabra
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
        **************** LINEA A ****************************************************************
        MOVE.B          #%00010000,CRA          * Reinicia el puntero MR1                       *
        MOVE.B          #%00000011,MR1A         * 8 bits por caracter                           *
        MOVE.B          #%00000000,MR2A         * Eco desactivado                               *
        MOVE.B          #%11001100,CSRA         * Velocidad = 38400 bps                         *
        MOVE.B          #%00000101,CRA          * Transmision y recepcion activados             *
        *****************************************************************************************

        **************** GENERAL ****************************************************************
        MOVE.B          #%00000000,ACR          * Conjunto de velocidades 1                     *
        MOVE.B          #$40,IVR                * Vector de interrupcion en $100                *
        MOVE.L          #RTI,$100               * Poner RTI en la tabla de vectores             *
        MOVE.B          #%00100010,IMR          * Habilitar RxRDY linea A (bit1) y B (bit5)     *
        MOVE.B          #%00100010,COPIA_IMR    * Guardar copia del IMR                         *
        *****************************************************************************************

        **************** LINEA B ****************************************************************
        MOVE.B          #%00010000,CRB          * Reinicia el puntero MR1                       *
        MOVE.B          #%00000011,MR1B         * 8 bits por caracter                           *
        MOVE.B          #%00000000,MR2B         * Eco desactivado                               *
        MOVE.B          #%11001100,CSRB         * Velocidad = 38400 bps                         *
        MOVE.B          #%00000101,CRB          * Transmision y recepcion activados             *
        *****************************************************************************************

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
        MOVEM.L A1/D0-D2,-(A7)          * Salvaguarda de registros

        MOVE.B  ISR,D2                  * Leer el ISR para identificar la fuente de interrupcion
        AND.B   COPIA_IMR,D2            * Filtrar solo las interrupciones habilitadas

        **************** LINEA A - RECEPCION ************************************************************
        BTST    #1,D2                   * Bit 1 = RxRDYA (Recepcion lista linea A)                      *
        BEQ     TX_A                    * Si no, pasar a transmision linea A                            *
        MOVE.B  RBA,D1                  * Leer caracter recibido del buffer A                           *
        MOVE.L  #0,D0                   * Descriptor 0 = linea A (recepcion)                            *
        BSR     ESCCAR                  * Guardar en buffer interno                                     *
        *************************************************************************************************

        **************** LINEA A - TRANSMISION **********************************************************
TX_A:
        BTST    #0,D2                   * Bit 0 = TxRDYA (Transmision linea A)                    
        BEQ     RX_B                    * Si != 0, pasar a recepcion linea B                              
        MOVE.L  #2,D0                   * Descriptor 2 = transmision linea A                            
        BSR     LEECAR                  * Intentar leer del buffer interno                              
        CMP.L   #-1,D0                  * Buffer vacio?                                                 
        BNE     ENVIA_A                 * Si no vacio, enviar caracter                                  
        BCLR    #0,COPIA_IMR            * Deshabilitar TxRDYA en la copia del IMR                       
        MOVE.B  COPIA_IMR,IMR           * Actualizar el IMR real                                        
        BRA     RX_B                                                                                    

ENVIA_A:
        MOVE.B  D0,TBA                  * Enviar caracter por linea A

        **************** LINEA B - RECEPCION ************************************************************
RX_B:
        BTST    #5,D2                   * Bit 5 = RxRDYB (Recepcion lista linea B)
        BEQ     TX_B                    * Si no, pasar a transmision linea B
        MOVE.B  RBB,D1                  * Leer caracter recibido del buffer B
        MOVE.L  #1,D0                   * Descriptor 1 = linea B (recepcion)
        BSR     ESCCAR                  * Guardar en buffer interno


        **************** LINEA B - TRANSMISION **********************************************************
TX_B:
        BTST    #4,D2                   * Bit 4 = TxRDYB (Transmision lista linea B)
        BEQ     FIN_RTI                 * Si no, finalizar la rutina
        MOVE.L  #3,D0                   * Descriptor 3 = transmision linea B
        BSR     LEECAR                  * Intentar leer del buffer interno
        CMP.L   #-1,D0                  * Buffer vacio?
        BNE     ENVIA_B                 * Si no vacio, enviar caracter
        BCLR    #4,COPIA_IMR            * Deshabilitar TxRDYB en la copia del IMR
        MOVE.B  COPIA_IMR,IMR           * Actualizar el IMR real
        BRA     FIN_RTI

ENVIA_B:
        MOVE.B  D0,TBB                  * Enviar caracter por linea B

        **************** FINALIZACION *******************************************************************
FIN_RTI:
        MOVEM.L (A7)+,A1/D0-D2          * Restaurar registros
        RTE
**************************** FIN RTI *********************************************************

***************************************** SCAN **************************************************
* Lee caracteres del buffer interno de recepcion y los copia al buffer del usuario.             *
* Comportamiento no bloqueante: devuelve inmediatamente lo que haya disponible.                 *
* Al finalizar la ejecucion de la instruccion RTS, el puntero de pila (SP) debe apuntar a la    *
* misma direccion a la que apuntaba antes de ejecutar la instruccion BSR.                       *
*                                                                                               *
* Entrada (parametros en pila):                                                                 *
*    8(A6)  -> puntero al buffer destino donde se copian los caracteres leidos                  *
*    12(A6) -> descriptor de linea (0 = linea A, 1 = linea B)                                   *
*    14(A6) -> numero maximo de caracteres a leer                                               *
*                                                                                               *
* Salida:                                                                                       *
*    D0 -> numero de caracteres leidos (0 si buffer vacio, -1 si descriptor invalido)           *
*************************************************************************************************
SCAN:
        LINK    A6,#0
        MOVEM.L D2-D4/A2,-(A7)    * Guardado de registros en la pila

        MOVE.L  8(A6),A2          * A2 = puntero al buffer destino donde copiar caracteres leidos
        MOVE.W  12(A6),D2         * D2 = descriptor de linea (0 = linea A, 1 = linea B)
        MOVE.W  14(A6),D3         * D3 = tamaño maximo de caracteres a leer
        CLR.L   D4                * D4 = contador de caracteres leidos del buffer interno

        ****************** Validacion de parametros *********************************************
        CMP.W   #1,D2                                                                           *
        BHI     SC_ERR            * Descriptor fuera de rango (mayor que 1), saltar a error     *
                                                                                                *
        TST.W   D3                                                                              *       
        BEQ     SC_FIN            * Tamaño nulo, devolver 0 caracteres leidos                   *
                                                                                                *
        *****************************************************************************************

        ****************** Seleccion de canal ***************************************************
        TST.W   D2                                                                              *
        BEQ     SC_LA             * Si descriptor = 0, leer de linea A                          *
        *****************************************************************************************
        
        ****************** LECTURA LINEA B ******************************************************
SC_LB:                                                                                          *
        MOVEQ   #1,D0             * ID descriptor para buffer interno recepcion linea B         *
        BSR     LEECAR            * Intentar leer caracter del buffer interno                   *
        CMP.L   #-1,D0            * Comprobar si buffer interno vacio (retorna -1)              *
        BEQ     SC_FIN            * Si buffer vacio, terminar lectura inmediatamente            *
                                                                                                *
        MOVE.B  D0,(A2)+          * Copiar caracter leido al buffer destino y avanzar puntero   *
        ADDQ.L  #1,D4             * Incrementar contador de caracteres leidos                   *
        SUBQ.W  #1,D3             * Decrementar tamaño restante por leer                        *
        BNE     SC_LB             * Si quedan caracteres por leer, continuar con linea B        *
        BRA     SC_FIN            * Sino, finalizar                                             *       
        *****************************************************************************************

        ****************** LECTURA LINEA A ******************************************************
SC_LA:                                                                                          *
        MOVEQ   #0,D0             * ID descriptor para buffer interno recepcion linea A         *
        BSR     LEECAR            * Intentar leer caracter del buffer interno                   *       
        CMP.L   #-1,D0            * Comprobar si buffer interno vacio (retorna -1)              *
        BEQ     SC_FIN            * Si buffer vacio, terminar lectura inmediatamente            *
                                                                                                *
        MOVE.B  D0,(A2)+          * Copiar caracter leido al buffer destino y avanzar puntero   *
        ADDQ.L  #1,D4             * Incrementar contador de caracteres leidos                   *                           
        SUBQ.W  #1,D3             * Decrementar tamaño restante por leer                        *
        BNE     SC_LA             * Si quedan caracteres por leer, continuar con linea A        *
        *****************************************************************************************

        ****************** FINALIZACION *********************************************************
SC_FIN:                                                                                         *
        MOVE.L  D4,D0             * Devolver en D0 el numero total de caracteres leidos         *
        BRA     SC_RESTORE        * Saltar a restauracion de registros                          *
                                                                                                *
SC_ERR:                                                                                         *
        MOVEQ   #-1,D0            * Codigo de error por descriptor invalido                     *
                                                                                                *                   
SC_RESTORE:                                                                                     *
        MOVEM.L (A7)+,D2-D4/A2    * Restaurar registros desde la pila                           *
        UNLK    A6                * Desmontar marco de pila                                     *
        RTS                       * Retornar a la direccion de llamada                          *
**************************** FIN SCAN ***********************************************************

**************************** PRINT **************************************************************

PRINT:
        ****************** DATOS ****************************************************************
        LINK    A6,#0                                                                           *
        MOVEM.L D2-D3/D5/A1,-(A7)     * Salvaguarda de registros                                *
                                                                                                *
        MOVE.L  8(A6),A1           * A1 = puntero a buffer origen                               *
        MOVE.W 12(A6),D2           * D2 = descriptor (línea)                                    *
        MOVE.W 14(A6),D3           * D3 = tamaño restante                                       *
        CLR.L   D5                 * D5 = contador de caracteres insertados                     *
        *****************************************************************************************

        ****************** VALIDACIÓN DE PARÁMETROS *********************************************
        CMP.W   #1,D2                                                                           *
        BHI     ERROR             * Descriptor fuera de rango                                   *
                                                                                                *
        TST.W   D3                                                                              *
        BEQ     FIN               * Tamaño nulo                                                 *
        *****************************************************************************************

        ****************** SELECCIÓN DE CANAL ***************************************************                
        TST.W   D2                                                                              *
        BEQ     LINEA_A                                                                         *
        *****************************************************************************************

        ****************** TRANSMISIÓN LÍNEA B **************************************************
LINEA_B:                                                                                        *       
        MOVE.B  (A1)+,D1           * Leer carácter y avanzar puntero                            *
        MOVEQ   #3,D0              * ID buffer transmisión B                                    *
        BSR     ESCCAR                                                                          *
        CMP.L   #-1,D0                                                                          *
        BEQ     ACTIVA_B          * Buffer interno lleno                                        *
                                                                                                *
        ADDQ.L  #1,D5              * Incrementar contador                                       *
        SUBQ.W  #1,D3              * Decrementar tamaño                                         *
        BNE     LINEA_B                                                                         *
                                                                                                *
ACTIVA_B:                                                                                       *
        TST.L   D5                                                                              *
        BEQ     FIN               * No se insertaron datos                                      *
                                                                                                *
                                                                                                *
        BSET    #4,COPIA_IMR       * Habilitar interrupción Tx B                                *
        MOVE.B  COPIA_IMR,IMR                                                                   *
        BRA     FIN                                                                             *
        *****************************************************************************************

        ****************** TRANSMISIÓN LÍNEA A **************************************************
LINEA_A:                                                                                        *
        MOVE.B  (A1)+,D1                                                                        *
        MOVEQ   #2,D0              * ID buffer transmisión A                                    *
        BSR     ESCCAR                                                                          *         
        CMP.L   #-1,D0                                                                          *
        BEQ     ACTIVA_A                                                                        *
                                                                                                *
        ADDQ.L  #1,D5                                                                           *
        SUBQ.W  #1,D3                                                                           *
        BNE     LINEA_A                                                                         *
                                                                                                *
ACTIVA_A:                                                                                       *
        TST.L   D5                                                                              *
        BEQ     FIN                                                                             *
                                                                                                *
        BSET    #0,COPIA_IMR       * Habilitar interrupción Tx A                                *       
        MOVE.B  COPIA_IMR,IMR                                                                   *
        *****************************************************************************************

        ****************** FINALIZACIÓN *********************************************************
FIN:                                                                                            *
        MOVE.L  D5,D0              * Número de caracteres aceptados                             *
        BRA     RESTORE                                                                         *
                                                                                                *
ERROR:                                                                                          *
        MOVEQ   #-1,D0             * Código de error                                            *
                                                                                                *
RESTORE:                                                                                        *
        MOVEM.L (A7)+,D2-D3/D5/A1     * Restaurar registros                                     *
        UNLK    A6                                                                              *
        RTS                                                                                     *
**************************** FIN PRINT **********************************************************

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
            MOVE.W  #1,-(A7)           * Descriptor = 0 → línea B
            MOVE.L  #BUFFER,-(A7)      * Buffer con los caracteres
            BSR     PRINT
            ADD.L   #8,A7              * Limpiar pila

            BRA     BUCLE

BUFFER:     DS.B    200                * Espacio para los caracteres

BUS_ERROR:  BREAK
            NOP
ADDRESS_ER: BREAK
            NOP
ILLEGAL_IN: BREAK
            NOP
PRIV_VIOLT: BREAK
            NOP
INCLUDE bib_aux.s
