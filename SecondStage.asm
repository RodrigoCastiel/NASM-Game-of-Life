org 0x500
jmp 0x0000:start

; ---------------------------------------------------------
data:
	message0: db "Ben vimdu ao MLKOS!"
	message1: db "Carregano as istrutura pros quernu...", 13, 10
	message2: db "Carregano quernu na memoria...", 		  13, 10
	message3: db "Rodanu os quernu, so na baratinaje! ", 13, 10
	
; ---------------------------------------------------------


; ---------------------------------------------------------
; Print Procedure 
print: ; (imprime a string cujo endereco esta no SI)
	.loop: ; Imprimir char por char
		mov CL, 0
		lodsb		; Carregar o byte do SI em AL e inc SI
		cmp AL, CL	; caractere == 0?
		je .end		; SE sim, terminar o procedimento
	
		.print_char:
			; Interrupcao para imprimir caractere em AL
			mov AH, WRITE_CHAR	; Escrita
			mov BH, 0			; Numero da pagina
			int 0x10			; Interrupcao de video
	jmp	.loop	; Continuar a imprimir
	
	.end:
		ret
; ---------------------------------------------------------


; ---------------------------------------------------------
start:
	; Inicializar registrador de segmento de dado
	mov AX, 0
	mov DS, AX

	; Imprimir mensagens inuteis
	mov SI, message0
	call print

	; Resetar sistema de disco, escolhendo o dispositivo de disco e setando a trilha como 0
	resetDisk:
		mov AH, 0x0
		mov DH, 0
		int 0x13	
	jc reset ; Se houver erro, tentar de novo resetar
	
	; Definir um endereco para colocar o programa do kernel
	mov ES, 0x7E00
	mov BX, 0x00
	
	mov SI, message1
	call print
	
	mov SI, message2
	call print
	
	; Carregar na memoria o segundo estagio do disco (utilizando a interrupcao de leitura)
	loadKernel:
		mov AH, 0x02	; Interrupcao de leitura de disco
		mov AL, 0x01	; Quantidade de setores para ler
		mov CH, 0x00	; Trilha
		mov CL,	0x02	; Setor
		mov DH, 0x00	; Cabeca (alguma coisa que nao sei o que eh)
		mov DL, 0x00	; Drive
		int 0x13
	jc loadSecondStage 	; Tentar ate conseguir 
	
	; Imprimir ultima mensagem antes de rodar o kernel
	mov SI, message3
	call print
	
	
	jmp 0x7E00:0x00	; Pular para o endereco de memoria onde esta o segundo estagio

; ---------------------------------------------------------
