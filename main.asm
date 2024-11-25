; Definindo registradores e posi��o inicial
.DEF posicao = r30      ; Registrador para a posi��o de mem�ria (usaremos r30 e r31 como ponteiro de 16 bits)
.DEF termo = r16        ; Registrador para armazenar o caractere a ser gravado

inicio:
	; Inicializa��o da posi��o
	ldi r30, 0x00           ; Carrega a parte baixa de posicao (endere�o 0x200)
	ldi r31, 0x02           ; Carrega a parte alta de posicao (endere�o 0x200)
    ; Armazenar mai�sculas (A-Z)
    ldi r16, 0x41        ; Carrega o c�digo ASCII de 'A' (0x41)
armazenar_maiusculas:
    st Z, r16           ; Armazena o caractere na posi��o apontada por Z (r30:r31)
    inc r30              ; Incrementa a parte baixa da posi��o (r30)
    cpi r16, 0x5A        ; Compara com 'Z' (0x5A)
    breq armazenar_minusculas ; Se for 'Z', vai para armazenar as min�sculas
    inc r16              ; Incrementa o c�digo ASCII para o pr�ximo caractere
    rjmp armazenar_maiusculas ; Volta para armazenar o pr�ximo caractere

armazenar_minusculas:
    ldi r16, 0x61        ; Carrega o c�digo ASCII de 'a' (0x61)

armazenar_minusculas_loop:
    st Z, r16           ; Armazena o caractere na posi��o apontada por Z (r30:r31)
    inc r30              ; Incrementa a parte baixa da posi��o
    cpi r16, 0x7A        ; Compara com 'z' (0x7A)
    breq armazenar_digitos ; Se for 'z', vai para armazenar os d�gitos
    inc r16              ; Incrementa o c�digo ASCII para o pr�ximo caractere
    rjmp armazenar_minusculas_loop ; Volta para armazenar o pr�ximo caractere

armazenar_digitos:
    ldi r16, 0x30        ; Carrega o c�digo ASCII de '0' (0x30)

armazenar_digitos_loop:
    st Z, r16           ; Armazena o caractere na posi��o apontada por Z (r30:r31)
    inc r30              ; Incrementa a parte baixa da posi��o
    cpi r16, 0x39        ; Compara com '9' (0x39)
    breq armazenar_espaco ; Se for '9', vai para armazenar o espa�o
    inc r16              ; Incrementa o c�digo ASCII para o pr�ximo caractere
    rjmp armazenar_digitos_loop ; Volta para armazenar o pr�ximo caractere

armazenar_espaco:
    ldi r16, 0x20        ; Carrega o c�digo ASCII do espa�o (0x20)
    st Z, r16           ; Armazena o espa�o na posi��o
    inc r30              ; Incrementa a parte baixa da posi��o

armazenar_esc:
    ldi r16, 0x1B        ; Carrega o c�digo ASCII do comando <ESC> (0x1B)
    st Z, r16           ; Armazena o comando <ESC> na posi��o

inicio_parte2:
	clr r16          ; R16 como 0 para configurar os pinos como entrada
	out DDRD, r16    ; Configura todos os pinos de PORTD como entrada
	ldi r18,0xFF     ; R16 como FF para configurar os pinos como sa�da
	out DDRC, r18    ; Configura todos os pinos de PORTC como sa�da
	out DDRB, r18    ; Configura todos os pinos de PORTB como sa�da
    rjmp init               ; Pular para a inicializa��o



; Inicia a parte onde se espera um input para executar uma fun��o

loop_funcao:
    ; Inicializa��o
    in r17, PIND           ; Ler a entrada da porta de dados (exemplo de PIND)
    cpi r17, 0x1C          ; Comparar a entrada com 0x1C
    breq start_read         ; Se n�o for 0x1C, continua esperando
	cpi r17, 0x1D
	breq start_count
	cpi r17, 0x1E
	breq start_same
	rjmp loop_funcao


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
	rjmp loop_funcao

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
	rjmp loop_funcao

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
	out PORTC, r18
	rjmp loop_funcao

