start:
	clr r16          ; R16 como 0 para configurar os pinos como entrada
	out DDRD, r16    ; Configura todos os pinos de PORTD como entrada
	ldi r18,0xFF     ; R16 como FF para configurar os pinos como sa�da
	out DDRC, r18    ; Configura todos os pinos de PORTC como sa�da
    rjmp init               ; Pular para a inicializa��o

; Inicia o programa
init:
    ; Inicializa��o
    in r17, PIND           ; Ler a entrada da porta de dados (exemplo de PIND)
    cpi r17, 0x1C          ; Comparar a entrada com 0x1C
    breq start_read         ; Se n�o for 0x1C, continua esperando
	cpi r17, 0x1D
	breq start_count
	cpi r17, 0x1E
	breq start_same
	rjmp init


start_read:
	ldi r30, 0x00        ; Endere�o de mem�ria inicial (0x300)
    ldi r31, 0x03        ; Ponteiro alto para o endere�o de mem�ria (0x300)

read_loop:
; Iniciar a leitura dos caracteres
    in r17, PIND           ; Ler o caractere da porta de entrada
    cpi r17, 0x1B          ; Comparar com o caractere ESC (0x1B)
    breq end_read            ; Se for ESC, finalizar a leitura

    cpi r17, 0x20          ; Comparar com o caractere de espa�o (0x20)
    brge valid_char        ; Se for um caractere v�lido (>= 0x20), processar

    rjmp read_loop         ; Caso contr�rio, ler novamente

valid_char:
    st Z, r17              ; Armazenar o caractere em mem�ria no endere�o apontado por Z
    adiw r30, 1            ; Avan�ar o ponteiro de mem�ria para o pr�ximo byte (r30:r31)
    cpi r31, 0x04          ; Comparar com o endere�o limite 0x400
    brge init            ; Se atingir o limite de 0x400, finalizar
    rjmp read_loop         ; Caso contr�rio, continuar a leitura

end_read:
	cpi r31, 0x04          ; Comparar com o endere�o limite 0x400
	breq init              ; Caso seja volta ao init
	st Z, r17	           ; Guarda o <ESC> na memoria
	rjmp init

start_count:               ; Inicializar o contador de caracteres
    ldi r18, 0x00          ; Limpar o registrador r18 (contador de caracteres)
    ldi r30, 0x00          ; Endere�o inicial da mem�ria
    ldi r31, 0x03          ; Ponteiro alto para o endere�o de mem�ria (0x300)

count_loop:
    ld r19, Z              ; Carregar o caractere de mem�ria
    cpi r19, 0x20          ; Comparar com o caractere de espa�o (0x20)
    breq invalid_char        ; Se for um espa�o, terminar a contagem

    cpi r19, 0x1B          ; Comparar com o caractere ESC (0x1B)
    breq end_count       ; Se for ESC, terminar a contagem

    inc r18                ; Incrementar o contador de caracteres
    adiw r30, 1            ; Avan�ar o ponteiro de mem�ria para o pr�ximo byte (r30:r31)
    cpi r31, 0x04          ; Comparar com o limite de mem�ria (0x400)
    breq end_count        ; Se atingiu o limite, parar a contagem
	rjmp count_loop

invalid_char:
	adiw r30, 1
	rjmp count_loop


end_count:
    ; Armazenar o n�mero de caracteres na mem�ria 0x401
    sts 0x401, r18         ; Armazenar o contador no endere�o 0x401

    ; Exibir o n�mero de caracteres na porta de sa�da
    out PORTC, r18         ; Supondo que PORTC seja a porta de sa�da
	rjmp init

start_same:                ;Inicializa a fun��o que conta quantas vezes um caracter aparece
	ldi r18, 0x00          ; Limpar o registrador r18 (contador de caracteres)
    ldi r30, 0x00          ; Endere�o inicial da mem�ria
    ldi r31, 0x03          ; Ponteiro alto para o endere�o de mem�ria (0x300)

same_loop:
	in r20, PIND           ; Ler o caractere da porta de entrada
	cpi r20, 0x20		   ; Checa se o input � um caracter valido
	brlt same_loop         ; Caso n�o seja l� denovo o input

	ld r21, Z

	cpi r21, 0x1B	           ; Comparar com o caractere ESC (0x1B)
	breq end_same

	cp r20, r21
	breq char_same
	adiw r30, 1
	rjmp same_loop

char_same:
	inc r18
	adiw r30, 1
	rjmp same_loop

end_same:
	sts 0x402, r18
	rjmp init

finish:
    ; Finaliza o programa ou entra em loop
    rjmp finish            ; Loop infinito ap�s a finaliza��o da leitura
