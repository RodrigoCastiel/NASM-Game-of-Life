org 0x7e00
jmp 0x0000:start

; Macros --------------------------------------------------	
	%define WRITE_CHAR		0XE
	%define READ_CHAR 		0X0
; ---------------------------------------------------------

; ---------------------------------------------------------
data:
	game_of_life_data:
		; Selector
		sel_i:		dw	1
		sel_j: 		dw	1
		sel_color:	dw	44
		
		; Field
		matrix:		times 2560 db 0
	
	input_data:
		; Dados de entrada para as funcoes de desenho
		xo:		dw	0
		yo:		dw	0
		w:		dw	0
		h:		dw	0
		color:	db	0

; ---------------------------------------------------------
; Set Background Color Procedure - BL possui a cor de fundo
set_background_color:		
	pusha
	
	; Setar a cor de fundo em BL
	mov AH, 0xB
	mov BH, 0x0
	int 0x10 ; Interrupcao de video
	
	popa
	ret
; ---------------------------------------------------------
; Clear Screen Procedure - modo VGA
clear_screen:
	mov AL, 0x0
	cld	; Apagar flag de direcao

	mov BX, 0xA000
	mov ES, BX
	xor DI, DI
	mov CX, 32000
	rep stosw
	
	.end:
		ret
; ---------------------------------------------------------
; Draw pixel Procedure
; color -> AL, x -> CX, y -> DX
draw_pixel:	 ; Desenha pixel diretamente no buffer
	pusha
	
	push AX	; Salvar a cor
	cld	; Apagar flag de direcao
	
	; Calcular o endereco da coordenada (x, y) no buffer
	mov AX, 320
	mul DX 	; DX:AX = 320 * y (offset)
	add AX, CX		; AX = offset
	mov DI, AX
	
	; Colocando o segment do buffer em ES para usar o DI
	mov BX, 0xA000
	mov ES, BX
	pop AX
	stosb	; Escrever cor em DI
	
	.end:
		popa
		ret
; ---------------------------------------------------------

; Draw Vertical Line Procedure - os argumentos de entrada
; devem estar no xo
; INPUT: xo -> CX, yo -> DX, color -> AL, h -> BX
draw_vline:
	mov [yo], DX
	mov  [h], BX
	
	; Limpar contador e numero da pagina
	xor BX, BX
	xor DX, DX	; Contador = 0 (y)
	
	.loop: ; Desenhar cada pixel, variando o x
		push DX ; Salvar para adicionar x com xo
		
		; Desenhar pixel
		add DX, [yo]
		call draw_pixel
		
	
		pop DX	; Voltar a x
		inc DX
		cmp DX, [h]
	jl .loop
	
	.end:
		ret
; ---------------------------------------------------------


; Draw Horizontal Line Procedure - os argumentos de entrada
; devem estar no xo
; INPUT: xo -> CX, yo -> DX, color -> AL, w -> BX
draw_hline:
	mov [xo], CX
	mov  [w], BX
	
	; Limpar contador e numero da pagina
	xor BX, BX
	xor CX, CX	; Contador = 0 (x)
	
	.loop: ; Desenhar cada pixel, variando o x
		push CX
		
		; Desenhar pixel
		add CX, [xo]
		call draw_pixel
	
		pop cx
		inc CX
		cmp CX, [w]
	jl .loop
	
	.end:
		ret
; ---------------------------------------------------------

; Draw Cell Procedure
; INPUT: (color -> AL), (j -> CX), (i -> DX)
draw_cell:
	pusha
	; Converter as coordenadas (j, i) para (x, y)
	imul BX, DX, 5	; yo = i * 5
	imul CX, CX, 5	; xo = j * 5
	
	; Laco para desenhar cada linha
	mov DX, 0 ; yrel = 0
	.loop_line:
		pusha

		; Desenhar a linha para y = DX + yo
		add DX, BX		; y = yrel + yo
		mov BX, 5		; width eh constante
		call draw_hline
		
		popa
		inc DX	; yrel++;
		cmp DX, 5
	jl .loop_line
	
	.end:
		popa
		ret
; ---------------------------------------------------------

; Draw Field Grid
draw_grid:
	pusha

	; Primeiro, as linhas
	mov DX, 0
	.loop_lines:
		pusha
		
		; Desenhar linha
		mov AL, 25		; Cor
		mov BX, 320		; Largura
		mov CX, 0		; xo
		call draw_hline	
		
		popa
		
		add DX, 5	; y += 5
		cmp DX, 200	; se y <= 200, desenhar uma linha em y
	jl .loop_lines
	
	; Depois, as colunas
	mov CX, 0
	.loop_columns:
		pusha
		
		; Desenhar linha
		mov AL, 25		; Cor
		mov BX, 200		; Altura
		mov DX, 0		; yo
		call draw_vline	
		
		popa
		
		add CX, 5	; x += 5
		cmp CX, 320	; se x <= 320, desenhar uma linha em x
	jl .loop_columns
	
	.end:
		popa
		ret

; ---------------------------------------------------------

; Draw Selector Procedure - Desenha o seletor retangular controlado pelo teclado
draw_selector:
	; Colocar dados do seletor nos registradores
	mov AL, [sel_color]
	mov CX, [sel_j]
	mov DX, [sel_i]
	
	; Transformar (j, i) para (x, y)
	imul CX, CX, 5
	imul DX, DX, 5
	mov BX, 5
	
	; Desenhar as arestas: superior e esquerda
	pusha
	call draw_hline
	popa
	
	pusha
	call draw_vline
	popa
	
	; Desenhar as arestas: inferior e direita
	add CX, 4
	pusha
	call draw_vline
	popa
	
	sub CX, 4
	add DX, 4
	pusha
	call draw_hline
	popa
	
	.end:
		ret
; ---------------------------------------------------------
; Put Cell Procedure
; ; INPUT: (color -> AL), (j -> CX), (i -> DX)
put_cell:
	mov BL, AL
	
	; Calcular o offset em relacao a matrix
	mov AX, 64
	mul DX 	; DX:AX = 64 * i (offset1)
	add AX, CX		; AX = 64 * i + j = offset
	
	; matrix[i][j] = cor
	mov CL, BL
	mov BX, matrix
	add BX, AX	; address = base address + offset
	mov [BX], CL 

	.end:
		ret
		
; ---------------------------------------------------------
; Get Cell Procedure
; INPUT:  (j -> CX), (i -> DX)
; OUTPUT: (color -> AL)
get_cell:	
	; Calcular o offset em relacao a matrix
	mov AX, 64
	mul DX 	; DX:AX = 64 * i (offset1)
	add AX, CX		; AX = 64 * i + j = offset
	
	; cor = matrix[i][j] 
	mov BX, matrix
	add BX, AX	; address = base address + offset
	mov AL, [BX]

	.end:
		ret
; ---------------------------------------------------------
; Draw Cell Matrix Procedure
draw_cell_matrix: ; Desenha todas as celulas
	mov DX, 1
	.loop_lines:
		mov CX, 1
		.loop_columns:
			; Obter a cor da celula			
			push CX
			push DX
			call get_cell
			pop DX
			pop CX
			
			; Nao desenhar se a celula estiver morta
			cmp AL, 0x0
			je .next
			
			; Desenhar a celula
			call draw_cell

			.next:
				inc CX
				cmp CX, 63
		jl .loop_columns
		
		inc DX
		cmp DX, 39
	jl .loop_lines

; ---------------------------------------------------------

; Wait Command Procedure
; Se o comando for para atualizar algo, coloca DH == 1
; AX == 0, caso ao contrario
wait_cmd: ; Espera comando e executa tarefa correspondente
	; Le caractere
	mov AH, READ_CHAR
	mov BH, 0
	int 0x16	; Interrupcao de teclado
	
	; Analisar o comando
	cmp AL, 'w'
	je .up
	
	cmp AL, 's'
	je .down
	
	cmp AL, 'a'
	je .left
	
	cmp AL, 'd'
	je .right
	
	cmp AL, 'p'
	je .put_cell
	
	cmp AL, 'o'
	je .kill_cell
	
	jmp .dont_update ; Else
	
	; Comandos de movimento
	.up:
		mov AX, [sel_i]
		cmp AX, 1
		jle .dont_update
		
		dec AX
		mov [sel_i], AX
		jmp .end
	
	.down:
		mov AX, [sel_i]
		cmp AX, 38
		jge .dont_update
		
		inc AX
		mov [sel_i], AX
		jmp .end
	
	.left:
		mov AX, [sel_j]
		cmp AX, 1
		jle .dont_update
		
		dec AX
		mov [sel_j], AX
		jmp .end
	
	.right:
		mov AX, [sel_j]
		cmp AX, 62
		jge .dont_update
		
		inc AX
		mov [sel_j], AX
		jmp .end
	
	.put_cell:
		mov AL, 0xf
		mov CX, [sel_j]
		mov DX, [sel_i]
		call put_cell
		jmp .end
		
	.kill_cell:
		mov AL, 0x0
		mov CX, [sel_j]
		mov DX, [sel_i]
		call put_cell
		jmp .end
	
	.dont_update:
		mov DH, 0
		ret
	
	.end:
		mov DH, 1
		ret

; ---------------------------------------------------------
start:
	; Inicializar registrador de segmento de dado
	mov AX, 0
	mov DS, AX
	mov ES, AX
	
	instructions:
			
	main_loop:		
		update:
			call clear_screen
			
			;call draw_grid
			call draw_cell_matrix
			call draw_selector
		
		input:	; Loop para esperar pelo update
			call wait_cmd
			cmp DH, 0
		je input
		
	jmp main_loop
		

; ---------------------------------------------------------	
	
	