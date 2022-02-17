PROCESSOR 16F887
    ;configuración word 1
    CONFIG  FOSC = INTRC_NOCLKOUT // Oscillador interno sin salida
    CONFIG  WDTE = OFF            // WDT disabled (reinicio repetitivo del pic)
    CONFIG  PWRTE = ON            // PWRT enabled (espera de 72ms al iniciar)   
    CONFIG  MCLRE = OFF           // EL pin de MCLR se utilizo como I/O   
    CONFIG  CP = OFF              // Sin protección de código            
    CONFIG  CPD = OFF             // Sin protección de datos             
    
    CONFIG  BOREN = OFF           // Sin reinicio cuándo el voltaje de alimentación baja de 4V                    
    CONFIG  IESO = OFF            // Reinicio sin cambio de reloj de interno a externo           
    CONFIG  FCMEN = OFF           // Cambio de reloj externo a interno en caso de fallo 
    CONFIG  LVP = ON              // Programación en bajo voltaje permitida
    
  ; configuración word 2
  CONFIG  WRT = OFF               // Protección de autoescritura por el programa desactivada 
  CONFIG  BOR4V = BOR40V          // Reinicio abajo de 4V, (BOR21V = 2.1V)
  
  
  #include <xc.inc>
  
  PSECT udata_shr            ; memoria compartida
    W_TEMP:        DS 1
    STATUS_TEMP:   DS 1 
    CONT:          DS 1
  
  
  
  PSECT resVect, class = CODE, abs, delta = 2
 
 ;--------------vector reset-------------------
 
 ORG 00h                 ;posición 0000h para el reset 
 resetVEC: 
    PAGESEL main 
    goto main 
 
 PSECT code, delta = 2, abs
 
 ;------------interrucpciones-----------------
 ORG 04h
 
 PUSH:
    MOVWF   W_TEMP         ; guardamos W
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP    ; guardamos nuestro registro status
    
 ISR:
    CALL RESET_TMR0
    CALL CONTADOR_PARA_TMR0
    
    BTFSC   RBIF 
    CALL    antirebote_iocb
    
    
    
 POP:
    SWAPF   STATUS_TEMP, W
    MOVWF   STATUS 
    SWAPF   W_TEMP, F
    SWAPF   W_TEMP,  W
    retfie
    
;------------subrutinas_interrupciones-----------
    
 antirebote_iocb:
    BANKSEL PORTB 
    BTFSS   PORTB, 0
    INCF    PORTA
    
    BTFSS   PORTB, 1
    DECF    PORTA
    BCF     RBIF        ;limpiar la bandera RBIF 
    
    return
 
 ORG 100h               ;posición para el código 
 
 main:
    CALL CONFIG_IO 
    CALL CONFIG_RELOJ
    CALL CONFIG_IOCB
    CALL CONFIG_INT
    CALL CONFIG_TMR0
    
 loop:
    
    GOTO loop
 

;--------subrutinas---------
    
CONFIG_IO:
    BANKSEL ANSEL 
    CLRF    ANSEL 
    CLRF    ANSELH               ; I/O digitales 
    
    BANKSEL TRISA 
    BCF     TRISA, 0             ; OUTPUT contador 1
    BCF     TRISA, 1             ; OUTPUT contador 1
    BCF     TRISA, 2             ; OUTPUT contador 1
    BCF     TRISA, 3             ; OUTPUT contador 1
    BANKSEL PORTA
    CLRF    PORTA                ; Apagamos PORTA
    
    BANKSEL TRISB
    BSF     TRISB, 0             ; PB contador 1
    BSF     TRISB, 1             ; PB contador 1
    BANKSEL PORTB
    CLRF    PORTB
    
    BANKSEL TRISC 
    BCF     TRISC, 0             ; Contador TMR0
    BCF     TRISC, 1             ; Contador TMR0
    BCF     TRISC, 2             ; Contador TMR0
    BCF     TRISC, 3             ; Contador TMR0
    BANKSEL PORTC 
    CLRF    PORTC
    
    BANKSEL OPTION_REG
    BCF     OPTION_REG, 7        ; RBPU (port B pull up enable bit)
    BSF     WPUB, 0              ; Weak pull up register bit portb 1
    BSF     WPUB, 1              ; Weak pull up register bit portb 2
    
    return 
    
 CONFIG_RELOJ:
    BANKSEL OSCCON           ; cambiamos a banco 01
    BSF OSCCON, 0            ; SCS --> 1, Usamos reloj interno
    BSF OSCCON, 6
    BSF OSCCON, 5
    BCF OSCCON, 4            ; IRCF <2:0> 110 4 MHz
    
    return
    
 CONFIG_IOCB:
    BANKSEL TRISA
    BSF     IOCB, 0
    BSF     IOCB, 1
    
    BANKSEL PORTB
    MOVF    PORTB, W
    BCF     RBIF 
    
    return 
    
 CONFIG_INT:
    BANKSEL INTCON 
    BSF     GIE               ; Habilitamos interrupciones 
    BSF     RBIE 
    BCF     RBIF
    BSF     T0IE              ; Habilitamos interrupción de TMR0
    BCF     T0IF              ; Limpiamos la bandera del TMR0
  
    return 
    
 CONFIG_TMR0:
    BANKSEL OPTION_REG        ; cambiamos de banco 
    BCF T0CS                  ; TMR0 como temporizador 
    BCF PSA                   ; prescaleer a TM0
    BSF PS2
    BSF PS1
    BCF PS0                   ; PS <2:0> --> 110 prescaler 128
    
    BANKSEL TMR0              ; cambiamos de banco
    MOVLW 100
    MOVWF TMR0                ; 20 ms de retardo
    BCF   T0IF                ; limpiamos bandera de interrupción
    return
 
 RESET_TMR0:
    BANKSEL TMR0              ; cambiamos de banco
    MOVLW 100
    MOVWF TMR0                ; 20 ms de retardo
    BCF   T0IF                ; limpiamos bandera de interrupción
    return
    
 CONTADOR_PARA_TMR0:
    INCF  CONT
    MOVLW 50
    XORWF CONT, W
    BTFSS STATUS, 2
    RETURN
    
    INCF PORTC
    CLRF CONT
    CLRF STATUS
    
    RETURN
    
    
    
    
 END 
  

    
 