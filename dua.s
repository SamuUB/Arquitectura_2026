*Proyecto de Arquitectura de computadores:
*Participantes:
*Laura Maria Perez Nunez,240294,DNI: 02308976Y
*Douae Imaalitan,240053,NIE: X8083278C
*==============================================
*Iniciamos SP y PC
*--------------
	ORG $0
	DC.L $7000 *Pila
	DC.L INICIO *PC
	ORG $400

*==============================================
* Equivalencias:
*==============================================
MR1A    EQU     $effc01  *modo A
MR2A    EQU     $effc01
MR1B    EQU     $effc11 *modo B
MR2B    EQU     $effc11
SRA     EQU     $effc03 *estado A
CSRA    EQU     $effc03 *seleccion reloj A
CRA     EQU     $effc05 *control A
SRB     EQU     $effc13 *estado de B
CSRB    EQU     $effc13 * seleccion reloj B
CRB     EQU     $effc15 * control B
TBA     EQU     $effc07 *buffer transmision de A
RBA     EQU     $effc07 * buffer recepcion de A
TBB     EQU     $effc17 *buffer transmision B
RBB     EQU     $effc17 *buffer recepcion de B
ACR     EQU     $effc09 *control auxiliar A y B
IMR     EQU     $effc0B *mascara de interrupcion A y B
ISR     EQU     $effc0B *estado de interrupcion A y B
IVR     EQU     $effc19 *vector de interrupcion A y B

*==============================================
* Variables
*==============================================
COPIA_IMR      DC.B    0

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
MENSAJE:    DC.B    'Hola desde A!'
            DC.B    13,10,0
*==============================================
* INIT
*==============================================
INIT:   MOVE.B  #%00010000,CRA  * Reiniciar el puntero a MR1 
        MOVE.B  #%00010000,CRB  * linea B
        MOVE.B  #%00000011,MR1A * configurar 8 bits por car en A 11= 8bits 
        MOVE.B  #%00000011,MR1B * en linea B
        MOVE.B  #%00000000,MR2A * 00= normal sin eco en linra a
        MOVE.B  #%00000000,MR2B * en linea b
        MOVE.B  #%00000000,ACR  * conjunto de vel 1
        MOVE.B  #%11001100,CSRA * vel 38400bps linea A
        MOVE.B  #%11001100,CSRB * la misma vel linea B
        MOVE.B  #%00000101,CRA  * habilitar TX y Rx con 01 en linea A 
        MOVE.B  #%00000101,CRB  * en linea B
        MOVE.B  #$40,IVR        * vector de interr
        MOVE.L  #RTI,$100      * poner RTI en tabla de vect
        MOVE.B  #%00100010,IMR  * Habilitar RxRDY linea a y b
        MOVE.B  #%00100010,COPIA_IMR * guardar copia del IMR
        BSR INI_BUFS
        RTS

*==============================================
*SCAN (Buffer, Descriptor, Tamano)
*==============================================
SCAN:           LINK   A6,#-24  * creamos marco de pila
			    MOVE.L   A2,-4(A6)  
			    MOVE.L   D2,-8(A6)        
			    MOVE.L   D3,-12(A6)       
			    MOVE.L   A1,-16(A6)      
			    MOVE.L   A3,-20(A6)       
			    MOVE.L   D4,-24(A6)       
			    MOVE.L   8(A6),A2       * guardamos buffer en A2
			    MOVE.W   12(A6),D2     *guardamos Descriptor en D2
			    MOVE.W   14(A6),D3     *guardamos Tamano en D3
			    EOR.L    D5,D5
			    ADD.L    #$ffffffff,D5	 *variable error
			    EOR.L    D4,D4           * usaremos D4 como contador auxiliar
			    CMP.W 	 #0,D3		* Si el tamano es 0, terminamos scan
			    BEQ 	 Es_vacio_SCAN
			    CMP.W    #0,D2      *Si D2 termina en 0 saltamos a linea A
			    BEQ      SCAN_lA           
			    CMP.W    #1,D2     *Si D2 termina en 1 saltamos a linea B
			    BEQ      SCAN_lB           
                EOR.L	 D0,D0	*si no es ninguna, es un error																
			    MOVE.L    D5,D0		* le damos el valor de error (D5) a D0
			    JMP 	 Fin_de_SCAN 
SCAN_lA:        EOR.L    D0,D0 		  
			    BSR 	 LEECAR		 * Llamamos a LEECAR, devuelve el resultado en D0
			    CMP.L 	 D0,D5		* comprobamos si devolvio un error
			    BEQ      terminar_SCAN			
			    ADD.L 	 #1,D4        * incrementamos contador
			    MOVE.B 	 D0,(A2)+       
			    CMP.L 	 D4,D3      * miramos si quedan datos por leer (comparamos datos leidos con datos por leer)
			    BNE 	 SCAN_lA	        														 		    														
			    EOR.L 	 D0,D0	     * devolvemos en D0 el total leido
			    MOVE.L    D4,D0
			    JMP 	 Fin_de_SCAN    
SCAN_lB:     	EOR.L    D0,D0 		    * ponemos D0 a 0
			    MOVE.L 	 #1,D0			* Al ser linea B ponemos D0 a 1 antes de llamar 
			    BSR 	 LEECAR		    * llamamos a LEECAR, resultado en D0
			    CMP.L 	 D0,D5			* comprobamos si devolvio un error
			    BEQ      terminar_SCAN		
			    ADD.L 	 #1,D4         * incrementamos contador
			    MOVE.B 	 D0,(A2)+       
			    CMP.L 	 D4,D3          * miramos si quedan datos por leer (comparamos datos leidos con datos por leer)
			    BNE 	 SCAN_lB	        														 		    														
			    EOR.L 	 D0,D0			* devolvemos en D0 el total leido
			    MOVE.L    D4,D0
			    JMP 	 Fin_de_SCAN
Es_vacio_SCAN:  EOR.L    D0,D0		* pongo D0 a 0
			    JMP 	 Fin_de_SCAN
terminar_SCAN:  EOR.L 	 D0,D0			* devolvemos en D0 el total leido
			    MOVE.L    D4,D0			
Fin_de_SCAN:    MOVE.L   -4(A6),A2    *restauramos registros
			    MOVE.L   -8(A6),D2       
			    MOVE.L   -12(A6),D3       
			    MOVE.L   -16(A6),A1       
			    MOVE.L   -20(A6),A3       
			    MOVE.L   -24(A6),D4       
			    UNLK     A6           * destruimos marco de pila
			    RTS
*==============================================
*  PRINT (Buffer, Descriptor, Tamano)
*==============================================
PRINT:  LINK A6,#-12      * crear marco de pila con 12 bytes
        MOVE.L D2,-4(A6)  * salvar D2 en var loc
        MOVE.L D3,-8(A6)  * salvar D3
        MOVE.L A1,-12(A6) * salvar A1
        MOVE.L 8(A6),A1   * cargar dir del buffer en A1 
        MOVE.W 12(A6),D2  * cargar Descriptor en d2 
        MOVE.W 14(A6),D3  * cargar tam en D3
        CLR.L  D5         * D5 sera el contador de car enviado
        CMP.W  #1,D2      * compruebo si Descriptor es > 1
        BHI   PRINT_Error * si es >1 saltar a error 
        CMP.W  #0,D3      * comprobar si tam es 0
        BEQ  FIN_DE_PRINT * si tam es 0 devolver 0
        CMP.W #0,D2       * comparar d2 Descriptor 
        BEQ   Linea_A     * si es 0 voy al bucle de lin A
        BRA   Linea_B     * si es 1 voy al bucle de lin B
PRINT_Error:   
        MOVE.L #$ffffffff,D0 * Descriptor invalido poner el error en D0
        BRA PRINT_REST       * saltar al final pa restaurar reg
Linea_A:  
        MOVE.B (A1),D1      * coger un car del buffer y avanzar el puntero
        MOVE.L #2,D0         * D0=2 transm linea A
        BSR    ESCCAR        
        CMP.L  #-1,D0        * comprobar si ESCCAR devolvio error
        BEQ    Activa_A      * si si entonces el buffer interno esta lleno
        ADD.L  #1,D5         * incrementar cont de car
        ADDQ.L #1,A1
        SUB.W  #1,D3         * descrementar tam restante
        BNE    Linea_A       * reptir el bucle
Activa_A:        
        CMP.L  #0,D5         * comprobar si entre algun car
        BEQ    FIN_DE_PRINT  * si no no activo interrupcion
        BSET   #0,COPIA_IMR  * poner a 1 el bit 0 
        MOVE.B COPIA_IMR,IMR * escribir la nueva en IMR
        BRA    FIN_DE_PRINT  * ir al final
Linea_B:
        MOVE.B (A1),D1      * coger un car del buffer y avanzar el puntero
        MOVE.L #3,D0        * D0=3 transm b
        BSR    ESCCAR        
        CMP.L  #-1,D0        * comprobar si ESCCAR devolvio error
        BEQ    Activa_B      * si si entonces el buffer interno esta lleno
        ADD.L  #1,D5         * incrementar cont de car
        ADDQ.L #1,A1
        SUB.W  #1,D3         * descrementar tam restante
        BNE    Linea_B       * reptir el bucle
Activa_B:
        CMP.L  #0,D5         * comprobar si entro algun car 
        BEQ    FIN_DE_PRINT  * si no no activo interrupcion
        BSET   #4,COPIA_IMR  * poner a 1 el bit 4 
        MOVE.B COPIA_IMR,IMR * escribir la nueva en IMR
        BRA    FIN_DE_PRINT
FIN_DE_PRINT:   
        MOVE.L D5,D0         * devolver en d0 el num de car acept
PRINT_REST:
        MOVE.L  -4(A6),D2        * restauro D2
        MOVE.L  -8(A6),D3        * restauro D3
        MOVE.L  -12(A6),A1       * restauro A1
        UNLK    A6               * destruyo marco de pila
        RTS                      * retorno
*==============================================
* RTI:
*==============================================
RTI:      MOVEM.L A1/D0-D4,-(A7)    * guardar los registros q vamos a usar
          MOVE.B  ISR,D2            * leer el ISR
          AND.B   COPIA_IMR,D2      * filtrar solo las interrupciones habilitadas
          BTST    #1,D2             * bit 1 es recibido por A
          BEQ     Transm_A           * no pues saltar a transm A
          MOVE.B  RBA,D1            * leer el car recibido
          MOVE.L  #0,D0             * D0=0 buffer rec por A
          BSR     ESCCAR            * guardar car en buffer interno

Transm_A: BTST    #0,D2             * bit 0 es transm por A
          BEQ     Rec_B           * no pues saltar a recepcion B
          MOVE.L  #2,D0             * D0=2 
          BSR     LEECAR            * intentar leer del buffer interno
          CMP.L   #-1,D0            * es el buffer vacio??
          BEQ     DES_TA           * si si, desactivar inter
          MOVE.B  D0,TBA            * transm car por A
          BRA     Rec_B
DES_TA:   BCLR    #0,COPIA_IMR      * desactivar transm por A en la copia del IMR
          MOVE.B  COPIA_IMR,IMR     * actualizar el IMR real

Rec_B:    BTST    #5,D2             * es el bit 5 recibido por B
          BEQ     Transm_B          * no pues saltar a Transmision B
          MOVE.B  RBB,D1            * leer el car recibido por B
          MOVE.L  #1,D0             * D0= 1 
          BSR     ESCCAR            * guardar en el buffer interno

Transm_B: BTST    #4,D2             * es el bit 4 transmitido por B
          BEQ     FIN_DE_RTI           * no pues terminar
          MOVE.L  #3,D0             * D0= 3 
          BSR     LEECAR            * intentar leer del buffer interno
          CMP.L   #-1,D0            * es el buffer vacio
          BEQ     DES_TB            * si si, desactivar interr
          MOVE.B  D0,TBB            * escribir el car transm por B
          BRA     FIN_DE_RTI
DES_TB:   BCLR    #4,COPIA_IMR      * desactivar transm por B en la copia del IMR
          MOVE.B  COPIA_IMR,IMR     * actualizar el IMR real

FIN_DE_RTI:  
          MOVEM.L (A7)+,A1/D0-D4    * restaurar todos los registros
          RTE                      
         
*-----------------
* ERRORES:
*-----------------
BUS_ERROR:  BREAK
            NOP
ADDRESS_ER: BREAK
            NOP
ILLEGAL_IN: BREAK
            NOP
PRIV_VIOLT: BREAK
            NOP


INCLUDE bib_aux.s
