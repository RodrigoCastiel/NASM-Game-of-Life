org 0x7e00
jmp 0x0000:start
so db 'Bem vindo ao Sistema de Lancamento',13,10,'.                 o__ __o          o__ __o   .',13,10,'.                /v     v\        /v     v\  .',13,10,'.               />       <\      />       <\ .',13,10,'.     __o__   o/           \o   _\o____      .',13,10,'.    />  \   <|             |>       \_\__o__.',13,10,'.    \o       \\           //              \ .',13,10,'.     v\        \         /      \         / .',13,10,'.      <\        o       o        o       o  .',13,10,'. _\o__</        <\__ __/>        <\__ __/>  .',13,10, 0
missl1 db 'Misseis preparados...',13,10,' ',13,10,'Misseis restantes: 3',13,10,'Digite o endereco do alvo:',13,10,0
missl2 db 'Missil 1 lancado. tempo de impacto: 10 min',13,10,'Misseis restantes: 2',13,10,'Digite o endereco do alvo:',13,10,0
missl3 db 'Missil 2 lancado. Tempo de impacto: 15 min',13,10,'Misseis restantes: 1',13,10,'Digite o endereco do alvo:',13,10,0
calcRoute db 13,10,'Calculando rota...',13,10,13,10,0
smtWrong db 'O endereco nao foi encontrado, endereco padrao foi escolhido:',13,10,'Av, Jorn. Anibal Fernades, Cin - UFPE - S/N, Grad 3',13,10,'Missil 3 lancado. Tempo de impacto: 1 min',13,10,'',13,10,'Para alterar a rota do lancamento, digite a nota deste trabalho, de 00 a 10... Voce tem 3 chances',13,10,0
thanks db 13,10, 'Voce desarmou o missil suicida. Ele ira se autodestruir na nossa atmosfera',13,10,'Obrigado por Salvar nossas vidas',13,10,0
errou1 db 13,10,'Aaf, nao chegou nem pertoo, voce esta ao menos tentando?? 2 chances faltam',13,10,'Digite a nota deste trabalho, de 00 a 10:',13,10,0
errou2 db 13,10,'Errou outra vez, pense melhor, você ainda tem 1 chance...',13,10,'Digite a nota deste trabalho, de 00 a 10...',13,10,0
errou3 db 13,10,'Que tu ta fazendo aqui ainda? Corraa! Tempo de impacto: 4s',13,10,0
dead db 13,10,'.     )             (                    .',13,10,'.  ( /(             )\ )            (    .',13,10,'.  )\())       (   (()/(  (     (   )\ ) .',13,10,'. ((_)\  (    ))\   /(_)) )\   ))\ (()/( .',13,10,'.__ ((_) )\  /((_) (_))_ ((_) /((_) ((_)).',13,10,'.\ \ / /((_)(_))(   |   \ (_)(_))   _| | .',13,10,'. \ V // _ \| || |  | |) || |/ -_)/ _` | .',13,10,'.  |_| \___/ \_,_|  |___/ |_|\___|\__,_| .',13,10,0
quebra db 13,10,0
tempo db 0

start: 
	xor si, si
	mov si, so
	call imprimir_string

	mov si, missl1
	call imprimir_string

	call pegarEndereco

	call calculandoRota	
	
	mov si, missl2
	call imprimir_string

	call pegarEndereco

	call calculandoRota



	mov si, missl3
	call imprimir_string

	call pegarEndereco

	call calculandoRota	

	mov si, smtWrong
	call imprimir_string

	call pegarNota

err1:
	mov si, errou1
	call imprimir_string
	
	call pegarNota


err2:
	mov si, errou2
	call imprimir_string
	call pegarNota


err3:
	mov si, errou3
	call imprimir_string
	
	call wait2
	call wait2

	call morreu

	jmp $


morreu:	

	mov si, dead
	call imprimir_string

	jmp $


salvo:
	mov si, thanks
	call imprimir_string

	jmp $


pegarNota:

pegarNum1:
	mov ah, 0h;
	int 16h; le a tecla

	mov ah, 0Eh
	int 10h; mostra a letra

	cmp al, 8; apaga
	je backspace1
	
	cmp al, 49; digitou 1
	je pegarNum0

	cmp al, 13;
	je retorne; apertou enter

	jmp pegar2Num


pegarNum0:
	mov ah, 0h;
	int 16h; le a tecla

	mov ah, 0Eh
	int 10h; mostra a letra

	cmp al, 8;
	je backspace1
	
	cmp al, 48
	je pegarEnter

	cmp al, 13;
	je retorne; terminou de digitar o endereco

faznada0:
	mov ah, 0h;
	int 16h; le a tecla
	
	cmp al, 8;
	je backspace0
	
	cmp al, 13
	je retorne
	
	jmp faznada0

pegar2Num:
	mov ah, 0h;
	int 16h; le a tecla

	mov ah, 0Eh
	int 10h; mostra a letra
	
	cmp al, 8;
	je backspace1
		

	cmp al, 13;
	je retorne; apertou enter
	

faznada:
	mov ah, 0h;
	int 16h; le a tecla

	cmp al, 8;
	je backspace2
	
	cmp al, 13
	je retorne
	
	jmp faznada




pegarEnter:
	mov ah, 0h;
	int 16h; le a tecla

	cmp al, 8;
	je backspace0

	cmp al, 13
	je salvo
	jmp pegarEnter

ret




backspace:
	mov al, 32 ; imprimindo um espaco p apgar a letra q quer apagar
	mov ah, 0Eh
	int 10h

	mov al, 8 ; voltando o cursor para ficar onde apagou
	mov ah, 0Eh
	int 10h
	jmp pegarEndereco

backspace1:
	mov al, 32 ; imprimindo um espaco p apgar a letra q quer apagar
	mov ah, 0Eh
	int 10h

	mov al, 8 ; voltando o cursor para ficar onde apagou
	mov ah, 0Eh
	int 10h
	jmp pegarNum1

backspace2:
	mov al, 32 ; imprimindo um espaco p apgar a letra q quer apagar
	mov ah, 0Eh
	int 10h

	mov al, 8 ; voltando o cursor para ficar onde apagou
	mov ah, 0Eh
	int 10h
	jmp pegar2Num

backspace0:
	mov al, 32 ;
	mov ah, 0Eh
	int 10h; imprime um espaço

	mov al, 8 ;
	mov ah, 0Eh
	int 10h; volta o cursor
	jmp pegarNum0

pegarEndereco:
	mov ah, 0h;
	int 16h; le a tecla

	mov ah, 0Eh
	int 10h; mostra a letra

	cmp al, 8;
	je backspace

	cmp al, 13;
	je retorne; terminou de digitar o endereco

jmp pegarEndereco

retorne:
	ret

wait2:
	mov ah, 86h
	mov cx,30    
	int 15h; congela a tela pelos ms definidos no cx
	ret

calculandoRota:
	mov si, quebra; quebra de linha
	call imprimir_string
	mov si, calcRoute
	call imprimir_string
	call wait2
	ret

imprimir_letra:
	mov ah, 0x0E
	mov bl, 0x07
	mov bh, 0x00;
	int 10h
	ret

imprimir_string:
	.next:
		mov al, [si];
		inc si;
		or al, al
		jz .done
		call imprimir_letra
		jmp .next
	.done:
		ret
