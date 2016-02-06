org 0x500
jmp 0x0000:start

; Macros --------------------------------------------------	
	%define WRITE_CHAR		0XE
	%define READ_CHAR 		0X0
; ---------------------------------------------------------

; ---------------------------------------------------------
data:
	message0: db "Welcome to RAVE's Life OS!", 13, 10, 0
	message1: db "Loading structures for the kernel...", 13, 10, 0
	message2: db "Loading kernel...", 		  13, 10, 13, 10, 0
	message3: db "Press any key to continue... ", 13, 10, 0
	
; ---------------------------------------------------------

; ---------------------------------------------------------
; Print Procedure (SI: buffer) (BL: color)
print: ; (imprime a string cujo endereco esta no SI)
	pusha
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
		popa
		ret
; ---------------------------------------------------------


; ---------------------------------------------------------
start:
	; Inicializar registrador de segmento de dado
	mov AX, 0
	mov DS, AX

	; Iniciar Modo VGA
	mov AH, 0x00
	mov AL, 0x13
	int 0x10

	; Imprimir mensagens inuteis
	mov SI, message0
	mov BL, 32
	call print

	; Resetar sistema de disco, escolhendo o dispositivo de disco e setando a trilha como 0
	resetDisk:
		mov AH, 0x0
		mov DH, 0
		int 0x13
	jc resetDisk ; Se houver erro, tentar de novo resetar
	
	mov SI, message1
	mov BL, 41
	call print
	
	mov SI, message2
	mov BL, 48
	call print
	
	; Definir um endereco para colocar o programa do kernel
	mov AX, 0x7E0
	mov ES, AX
	mov BX, 0x00
	
	; Carregar na memoria o segundo estagio do disco (utilizando a interrupcao de leitura)
	loadKernel:
		mov AH, 0x02	; Interrupcao de leitura de disco
		mov AL, 20	; Quantidade de setores para ler
		mov CH, 0x00	; Trilha
		mov CL,	0x03	; Setor
		mov DH, 0x00	; Cabeca (alguma coisa que nao sei o que eh)
		mov DL, 0x00	; Drive
		int 0x13
	jc loadKernel 		; Tentar ate conseguir 
	
	; Imprimir ultima mensagem antes de rodar o kernel
	mov SI, message3
	mov BL, 0xb
	call print
	
	mov AH, READ_CHAR
	mov BX, 0
	int 0x16
		
	jmp 0x7e0:0x0 ; Pular para o endereco de memoria onde esta o kernel


; ---------------------------------------------------------



