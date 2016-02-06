org 0x7c00
jmp 0x0000:start

; -----------------------------------------
start:
	; Inicializar registrador de segmento de dado
	mov AX, 0
	mov DS, AX

	; Resetar sistema de disco, escolhendo o dispositivo de disco e setando a trilha como 0
	resetDisk:
		mov AH, 0x0
		mov DH, 0
		int 0x13	
	jc reset ; Se houver erro, tentar de novo resetar
	
	; Definir um endereco para colocar o programa do segundo estagio
	mov ES, 0x50
	mov BX, 0x00
	
	; Carregar na memoria o segundo estagio do disco (utilizando a interrupcao de leitura)
	loadSecondStage:
		mov AH, 0x02	; Interrupcao de leitura de disco
		mov AL, 0x01	; Quantidade de setores para ler
		mov CH, 0x00	; Trilha
		mov CL,	0x02	; Setor
		mov DH, 0x00	; Cabeca (alguma coisa que nao sei o que eh)
		mov DL, 0x00	; Drive
		int 0x13
	jc loadSecondStage 	; Tentar ate conseguir 
	
	jmp 0x50:0x00	; Pular para o endereco de memoria onde esta o segundo estagio
	
; -----------------------------------------

times 510 - ($-$$) db 0	; Zerar o resto do setor com 0
dw 0xAA55 				; Assinatura de setor bootavel

