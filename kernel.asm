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
		; Drawing data
		xo:		dw	0
		yo:		dw	0
		w:		dw	0
		h:		dw	0
		color:	db	0
		i_op:	dw	0
		j_op:	dw	0
		alive:	db	0

; ---------------------------------------------------------
; Clear Screen Procedure - VGA mode
clear_screen:
	mov AL, 0x0
	cld	; Clear direction flag

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
draw_pixel:	 ; Draws directly on buffer
	pusha
	
	push AX	; Save color
	cld	; clear direction flag
	
	; Compute address of (x, y) in the buffer
	mov AX, 320
	mul DX 	; DX:AX = 320 * y (offset)
	add AX, CX		; AX = offset
	mov DI, AX
	
	; Copying buffer segment to ES so we can use DI
	mov BX, 0xA000
	mov ES, BX
	pop AX
	stosb	; Write color in DI
	
	.end:
		popa
		ret
; ---------------------------------------------------------

; Draw Vertical Line Procedure - input arguments
; must be in xo
; INPUT: xo -> CX, yo -> DX, color -> AL, h -> BX
draw_vline:
	mov [yo], DX
	mov  [h], BX
	
	; clear counter and page number
	xor BX, BX
	xor DX, DX	; Contador = 0 (y)
	
	.loop: ; Draw pixel for each x
		push DX ; Save x to compute (x+xo)
		
		; Draw pixel
		add DX, [yo]
		call draw_pixel
		
	
		pop DX	; Restore x
		inc DX
		cmp DX, [h]
	jl .loop
	
	.end:
		ret
; ---------------------------------------------------------


; Draw Horizontal Line Procedure - input arguments
; must be at xo
; INPUT: xo -> CX, yo -> DX, color -> AL, w -> BX
draw_hline:
	mov [xo], CX
	mov  [w], BX
	
	; clear counter and page number
	xor BX, BX
	xor CX, CX	; Contador = 0 (x)
	
	.loop: ; Draw pixel for each x
		push CX
		
		; Draw pixel
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
	; Convert coordinates (j, i) para (x, y)
	imul BX, DX, 5	; yo = i * 5
	imul CX, CX, 5	; xo = j * 5
	
	; Loop for drawing lines
	mov DX, 0 ; yrel = 0
	.loop_line:
		pusha

		; Draw line at y = DX + yo
		add DX, BX		; y = yrel + yo
		mov BX, 5		; width is constant
		call draw_hline
		
		popa
		inc DX	; yrel++;
		cmp DX, 5
	jl .loop_line
	
	.end:
		popa
		ret
; ---------------------------------------------------------

; Draw Selector Procedure - Draws rectangle selector controled by keyboard
draw_selector:
	; Load selector data from memory to registers
	mov AL, [sel_color]
	mov CX, [sel_j]
	mov DX, [sel_i]
	
	; Convert (j, i) to (x, y)
	imul CX, CX, 5
	imul DX, DX, 5
	mov BX, 5
	
	; Draw edges: top and left
	pusha
	call draw_hline
	popa
	
	pusha
	call draw_vline
	popa
	
	; Draw edges: bottom and right
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
	
	; Compute offset to matrix origin 
	mov AX, 64
	mul DX 	; DX:AX = 64 * i (offset1)
	add AX, CX		; AX = 64 * i + j = offset
	
	; matrix[i][j] = color
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
	; Compute offset to matrix origin 
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
; Calculate Neighbour
; INPUT: (j -> CX), (i -> DX)
; OUTPUT: (number of neighbours -> BL)
calc_neighbours:
	xor BL, BL	; Number of neighbours alive, at the beginning, is 0
	
	; Save current position
	mov [j_op], CX
	mov [i_op], DX
	mov [alive], BL
	
	; Analyze neighbours (walking through the array)
	mov DX, -1	; i
	
	.loop_line:
		mov CX, -1	
		.loop_column:
			; Check if it is the current cell
			mov AX, CX
			or AX, DX
			cmp AX, 0	; i == j == 0 ? it is!
			je .next	
			
			; Get neighbour state
			push CX
			push DX
			add CX, [j_op]
			add DX, [i_op]
			call get_cell
			pop DX
			pop CX
			
			; Dead neighbour, do not increase counter
			cmp AL, 1
			jle .next
			
			; Alive, increase counter
			mov BL, [alive]
			inc BL
			mov [alive], BL
			
			.next:
				inc CX
				cmp CX, 1
		jle .loop_column
	
		inc DX
		cmp DX, 1
	jle .loop_line
	
	mov BL, [alive]
	
	.end:
		ret

; ---------------------------------------------------------
; Draw Cell Matrix Procedure
draw_cell_matrix: ; Draw all cells
	mov DX, 1
	.loop_lines:
		mov CX, 1
		.loop_columns:
			; Get color		
			push CX
			push DX
			call get_cell
			pop DX
			pop CX
			
			
			; Don't draw dead cells
			;cmp AL, 0x0
			;je .next
			
			; Draw alive ones
			call draw_cell

			.next:
				inc CX
				cmp CX, 63
		jl .loop_columns
		
		inc DX
		cmp DX, 39
	jl .loop_lines
	
	.end:
		ret
	
; ---------------------------------------------------------

; Update Cell Matrix Procedure
update_cell_matrix:
	
	mov DX, 1
	.loop_lines:
		mov CX, 1
		.loop_columns:
			push CX
			push DX
			call get_cell
			pop DX
			pop CX
			
			; Computer number of neighbours			
			push AX
			push CX
			push DX
			call calc_neighbours
			pop DX
			pop CX
			pop AX
			
			; Check whether the current cell is alive or not
			cmp AL, 1
			jg .live
			
			.dead:
				; Check reproduction birth
				cmp BL, 3
				jne .next
				
				; Birth
				mov AL, 1	; morto -> vivo
				pusha
				mov CX, [j_op]
				mov DX, [i_op]
				call put_cell
				popa
				jmp .next
			
			.live:
				; Check death by "under" population
				cmp BL, 2
				jl .go_die
				
				; Check death by "over" population
				cmp BL, 3
				jg .go_die
				
				; Still alive
				mov AL, BL
				add AL, 7
				pusha
				mov CX, [j_op]
				mov DX, [i_op]
				call put_cell
				popa
				jmp .next	
				
				.go_die: ; Transition (alive -> dead)
					mov AL, 2
					push CX
					push DX
					mov CX, [j_op]
					mov DX, [i_op]
					call put_cell
					pop DX
					pop CX
					jmp .next
			
			.next:
				inc CX
				cmp CX, 63
		jl .loop_columns
		
		inc DX
		cmp DX, 39
	jl .loop_lines
	
	; Second step update (transition states)
	mov DX, 1
	.loop_lines2:
		mov CX, 1
		.loop_columns2:
			; Get color		
			push CX
			push DX
			call get_cell
			pop DX
			pop CX
			
			; dead->alive
			cmp AL, 1
			je .go_live
			
			; alive->dead
			cmp AL, 2
			je .go_die2
			
			jmp .next2	; it is not a transition state
			
			.go_live:
				mov AL, 5
				jmp .update_color
			.go_die2:
				mov AL, 0x0
			
			.update_color:
				push CX
				push DX
				call put_cell
				pop DX
				pop CX
				
			.next2 :
				inc CX
				cmp CX, 63
		jl .loop_columns2
		
		inc DX
		cmp DX, 39
	jl .loop_lines2
	
	.end:
		ret

; ---------------------------------------------------------

; Wait Command Procedure
wait_cmd:  ; Keyboard command
	; Le caractere
	mov AH, READ_CHAR
	mov BH, 0
	int 0x16	; keyboard interrupt
	
	; Classify command
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
	
	cmp AL, 'y'
	je .operate
	
	jmp .dont_update ; Else
	
	; Move selector keys
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
		mov AL, 6
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
		
	.operate:
		call update_cell_matrix
		jmp .end
		
	.dont_update:
		mov DH, 0
		ret
	
	.end:
		mov DH, 1
		ret
; ---------------------------------------------------------
start:
	; Initialize data segment register
	mov AX, 0
	mov DS, AX
	mov ES, AX
	
	call clear_screen
	
	instructions:
			
	main_loop:		
		update:
			;
			call draw_cell_matrix
			call draw_selector
			
		input:	;
			
			call wait_cmd
			cmp DH, 0
		je input
		
	jmp main_loop
; ---------------------------------------------------------	
