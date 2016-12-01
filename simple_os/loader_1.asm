;  Принцип работы такой: читать можем только в первые 64к, поэтому сначала считывается цилиндр в 0x50:0 — 0x50:0x2400, а затем копируется туда, куда необходимо. При этом первый цилиндр считываем в конце.

section .text
use16
;  Ядро отправляем в 0x7c00
org 0x7c00

;  Определение переменных
%define CTR 10 
%define MRE 5 

start:
;  Поскольку мы не знаем значений различных регистров (за исключением CS, значение которого равно 0), то мы должны сами занести данные в данные регистры(а именно “занулить” SS, SP и DS). 
;  А так же отключить прерывания, чтобы в это время работу загрузчика ни что не сбивало.
;  Далее:
cli 
mov ax, cs
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7c00
sti
;  Мы собираемся перенести с дискеты данные, а попадут они на текущий код, поэтому необходимо перенести его в верхнюю часть доступной памяти. 
;  В DS — адрес исходного сегмента
xor ax, ax
mov ds, ax

;  В ES — адрес целевого сегмента
mov ax, 0x9000
mov es, ax

;  Копируем с 0
mov si, begin
mov di, begin

;  Копируем 128 двойных слов
mov cx, 128
rep movsd

;  Прыжок в новоиспеченный bootsector (0x9000: 0)
jmp 0x9000:begin

;  следующий код выполняется по адресу 0x9000:0
begin:

;  Заполним регистры новыми значениями (0)
mov ax, cs
mov ds, ax
mov ss, ax 

;  Сообщим пользователю о загрузке 
mov si, msg_startup
call ps

;  Читаем цилиндр начиная с указанного в DI плюс нулевой цилиндр (в самом конце) в AX (адрес, куда будут записаны данные)
mov di, 1
mov ax, 0x290
xor bx, bx
.loop:
mov cx, 0x50
mov es, cx
push di

;  Подсчет головки для использования
shr di, 1
setc dh
mov cx, di
xchg cl, ch
pop di

;  Считаны ли все цилиндры?
cmp di, CTR
je .quit
call r_cyl

;  Цилиндр считали в 0x50:0x0 — 0x50:0x2400 (в линейном варианте — 0x500 — 0x2900)
;  Скопируем этот блок в нужный адрес:
pusha
push ds 
mov cx, 0x50
mov ds, cx
mov es, ax
xor di, di
xor si, si
mov cx, 0x2400
rep movsb
pop ds
popa

;  Увеличим DI, AX и повторим все сначала
inc di
add ax, 0x240
jmp short .loop
.quit: 

;  Т.к. у нас часть памяти была занята, мы считывали с первого цилиндра, 
; не стоит забыть о нулевом и скачать еще и его
mov ax, 0x50
mov es, ax
mov bx, 0
mov ch, 0
mov dh, 0
call r_cyl

;  Прыжок на загруженный код
jmp 0x0000:0x0700


r_cyl:
;  Читаем заданный цилиндр, ES:BX – буфер, CH – цилиндр, DH — головка
;  Сбросим счетчик ошибок
mov [.err], byte 0
pusha

;  Сообщение о том, какая головку/цилиндр считывается
mov si, msg_cyl
call ps
mov ah, ch
call pe
mov si, msg_head
call ps
mov ah, dh
call pe
mov si, msg_crlf
call ps
popa
pusha

.start: 
mov ah, 0x02
mov al, 18
mov cl, 1

;  Прерывание BIOS
int 0x13
jc .r_err
popa
ret
.err:   db 0 
.r_err:

;  Об ошибках сообщаем и выводим их код
inc byte [.err]
mov si, msg_err
call ps
call pe
mov si, msg_crlf
call ps

;  Что делаем, если ошибок больше нормы:
cmp byte [.err], MRE
jl .start
mov si, msg_end
call ps
hlt
jmp short $

table:  db '0123456789ABCDEF'

;  ASCII-код преобразуем в его шестнадцатеричного представления и выводим
pe:
pusha
xor bx, bx
mov bl, ah
and bl, 11110000b
shr bl, 4
mov al, [table+bx]
call pc
mov bl, ah
and bl, 00001111b
mov al, [table+bx]
call pc
popa
ret

;  Из AL выводим символ на экран
pc:
pusha
mov ah, 0x0E
int 0x10
popa
ret

;  Строку из SI выводим на экран
ps:
pusha
.loop:
lodsb
test al, al
jz .quit
mov ah, 0x0e
int 0x10
jmp short .loop
.quit:
popa
ret


;  Служебные сообщения
msg_startup:    db 'OS loading...', 0x0A, 0x0D, 0
msg_cyl:    db 'Cylinder:', 0
msg_head:   db ', head:',0
msg_err: db 'Error! Code of it:',0
msg_end:    db 'Errors while reading',0x0A,0x0D, 'Reboot the computer, please', 0
msg_crlf:   db 0x0A, 0x0D,0 

;  Сигнатура бутсектора: 
TIMES 510 - ($-$$) db 0
db 0x55, 0xAA

incbin 'loader.bin'
