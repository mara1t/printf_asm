section .data

                Mystr:           db "res=_%xilovethis_", 0
                str_for_itoa:    db "1111111111"
                ZeroStr:         db "1111"
                def_str:         db "GGG $"

section .text

global _start

_start:

;= = = = = = = = = = = = = = = = = = = = = = =
                mov rdx, 0AAh
                push rdx
                
                mov rdx, Mystr
                push rdx

                call printf

                pop rdx
                pop rdx
;= = = = = = = = = = = = = = = = = = = = = = =
CloseProg:
                mov rax, 60         ; system call for exit
                xor rdi, rdi                ; exit code 0
                syscall


;----------------------------------
; Entry: rdi - ptr of the string
; Destr: rdx, rbx
;----------------------------------         
strprint:
                xor rcx, rcx
                cmp [rdi], cl
                je .ret
                mov rax, 1
                mov rdx, 1
                sub rdi, 1
.while:
                inc rdi
                mov rsi, rdi
                push rdi
                mov rdi, 1
                syscall
                pop rdi
                cmp [rdi], cl
                jne .while

.ret:
                ret

section .data
                one_c: db "F"
section .text


;= = = = = = = = = = = = = = = = = = = = = = =
;
;arguments are in the stack(1:string, 2:first arg, 3:third arg ...)
;
;= = = = = = = = = = = = = = = = = = = = = = =
printf:  
                mov rbp, rsp
                add rbp, 16; bp указывает на первый аргумент стека

                mov rdi, [rbp-8]; в стеке адрес строки 
                                    ; теперь в di адрес строки из сегмента ds

.1:             mov dl, '%'
                cmp [rdi], dl
                je .is_argument
                
                mov dl, 0
                cmp [rdi], dl
                je .far_jmp
                jmp .not_jmp

.far_jmp:       
                jmp .end_printf

.not_jmp:
                mov rsi, rdi
                push rdi
                mov rax, 1
                mov rdi, 1 
                mov rdx, 1
                syscall

                pop rdi
                inc rdi
                jmp .is_not_argument

.is_argument:    call find_next_symb

.is_not_argument:
                
                jmp .1

.end_printf:
                ret



find_next_symb: 
                inc rdi
                mov dl, 'c'
                cmp [rdi], dl
                je .c_symb

                mov dl, 's'
                cmp [rdi], dl
                je .s_symb

                mov dl, 'd'
                cmp [rdi], dl
                je .d_symb

                mov dl, 'b'
                cmp [rdi], dl
                je .b_symb

                mov dl, 'o'
                cmp [rdi], dl
                je .o_symb

                mov dl, 'x'
                cmp [rdi], dl
                je .far_jmp_x

                jmp .end_func

.far_jmp_x:     jmp .x_symb

;-------------char--------------
.c_symb:         
                mov rax, 1
                mov rdi, 1
		        mov rsi, tmp_symb
                mov rdx, 1
                syscall

                add rbp, 8
                inc rdi
                jmp .end_func
;-------------str--------------
.s_symb:

                mov rdi, [rbp]
                call strprint

                add rbp, 8
                inc rdi
                jmp .end_func

;-------------10d--------------
.d_symb:         

                push rdi
                mov dl, [rbp]
                add bp, 8
                
                mov rdi, str_for_itoa
                mov al, 10d

                call Itoa

                jmp .end_func


;-------------2b--------------
.b_symb:         
                push rdi
                mov dl, [rbp]
                add rbp, 8
                
                mov rdi, str_for_itoa
                mov al, 2d

                call Itoa

                jmp .end_func

;-------------8o--------------
.o_symb:        push rdi
                mov rdx, [rbp]
                add rbp, 8
                
                mov rdi, str_for_itoa
                mov al, 8d

                call Itoa

                
                jmp .end_func
;-------------16x--------------
.x_symb:        push rdi
                mov rdx, [rbp]
                add rbp, 8
                
                mov rdi, str_for_itoa
                mov al, 16d

                call Itoa

                call strprint

                pop rdi
                inc rdi
                jmp .end_func


.end_func:
                ret









section .data
                tmp_symb:        db "A$"  

section .text
;= = = = = = = = = = = = = = = = = = = = = = =

;= = = = = = = = = = = = = = = = = = = = = = =
;ENTRY: rdx = enter number
;       rdi - ptr of a string
;       al - system
;= = = = = = = = = = = = = = = = = = = = = = =

Itoa:           

                call ItoaIn

                ret

ItoaIn:          
                
                cmp al, 16d
                je .16SYSTEM

                cmp al, 10d
                je .10SYSTEM

                cmp al, 8d
                je .8SYSTEM

                cmp al, 2d
                je .far_jmp

                jmp .end_func

.far_jmp:        
                jmp .2SYSTEM

;-------------16--------------
.16SYSTEM:
                mov rcx, 16d ;counter for symb from 4 to 1 (1234h) 0000|0000|0000|0000|0000|0000|0000|0000|0000|0000|0000|0000|0000|0000|0000|0000|
                mov rax, 4*15d ; 4byte * 3
                mov rsi, 0 ; not to put first zeroes

.label16:        
                mov rbx, 0Fh ;0000|0000|0000|1111
                push rcx 
                mov cl, al ;save al to cl
                sub al, 4d ;
                push rax                 
                shl rbx, cl ;
                mov rax, rdx ;
                and rax, rbx ;
                shr rax, cl ; now ax has one symb of dx
                
                cmp rax, 9h
                ja .symb16
                jbe .num16
.num16:
                add rax, 30h
                jmp .gonext16
.symb16:         
                add rax, 37h
                jmp .gonext16

.gonext16:       
                cmp rsi, 0
                jne .nozeroes
                cmp rax, 30h
                je .firstzeroes16


                mov rsi, 1
.nozeroes:
                mov [rdi], al
                inc rdi
.firstzeroes16:
                pop rax
                pop rcx
                loop .label16

                ;mov al, 0
                ;mov [rdi], al
                ;inc rdi
                jmp .end_func

;-------------10--------------

.10SYSTEM:
                mov rbx, 10d ; const 10d
                mov rax, rdx; now ax is our number
                mov rsi, 0

                xor rcx, rcx ; counter
.10:             
                xor rdx, rdx
                div bx; dx - остаток ax - частное
                push rdx
                inc rcx
                cmp rax, 0
                jne .10


.next_loop10:
                pop rax
                cmp rsi, 0h
                jne .nozeroes10
                cmp rax, 0h
                je .firstzeroes10

.nozeroes10:
                mov rsi, 1

                add rax, 30h
                mov [rdi], al 
                inc rdi
.firstzeroes10:   

                loop .next_loop10

                ;mov cl, '$'
                ;mov [rdi], cl
                
                jmp .end_func


;-------------8---------------

.8SYSTEM:
                mov rcx, 22d ;0|000|000|000|000|000
                mov rax, 3*21d
                mov rsi, 0

.label8:        
                mov rbx, 7h; 0|000|000|000|000|111
                push rcx
                mov rcx, rax
                sub al, 3
                push rax 
                               
                shl rbx, cl
                mov rax, rdx
                and rax, rbx
                shr rax, cl
                
                add rax, 30h
                ;jmp .gonext8

.gonext8:       
                cmp rsi, 0h
                jne .nozeroes8
                cmp rax, 30h
                je .firstzeroes8
                mov rsi, 1

.nozeroes8:                
                mov [rdi], al
                inc rdi

.firstzeroes8:     
                pop rax
                pop rcx
                loop .label8

                jmp .end_func

;-------------2---------------

.2SYSTEM:
                mov cx, 64d ;0000|0000|0000|1111
                mov AX, 63d
                mov rsi, 0
.label2:        
                
                mov rbx, 01h
                push rcx
                mov cl, al
                sub al, 1h
                push rax                
                shl rbx, cl
                mov rax, rdx
                and rax, rbx
                shr rax, cl
                
                add rax, 30h
                
                cmp rsi, 0h
                jne .nozeroes2
                cmp rax, 30h
                je .firstzeroes2
                mov rsi, 1

.nozeroes2:

                mov [rdi], al
                inc rdi
.firstzeroes2:
                pop rax
                pop rcx
                loop .label2

                ;mov al, 24h
                ;mov [rdi], al
                ;inc rdi


.end_func:      
                mov al, 0
                mov [rdi], al
                inc rdi
                ret

;= = = = = = = = = = = = = = = = = = = = = = =

