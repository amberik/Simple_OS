use16
org 0x700

;  Обнулим регистры, установим стек
cli 
mov ax, 0
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x700
sti

;  Сообщение о приветствии
mov si, msg_start
call ps

;  Сообщение о переходе в защищенный режим
mov si, msg_epm
call ps

;  Отключение курсора (просто так)
mov ah, 1
mov ch, 0x20
int 0x10

;  Установим базовый вектор контроллера прерываний в 0x20
mov al,00010001b 
out 0x20,al 
mov al,0x20 
out 0x21,al 
mov al,00000100b 
out 0x21,al
mov al,00000001b 
out 0x21,al 

;  Отключим прерывания
cli

;  Загрузка регистра GDTR: 
lgdt [gd_reg]

;  Включение A20: 
in al, 0x92
or al, 2
out 0x92, al

;  Установка бита PE регистра CR0
mov eax, cr0 
or al, 1 
mov cr0, eax 

;  С помощью длинного прыжка мы загружаем селектор нужного сегмента в регистр CS
jmp 0x8: _protect



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


;  Следующий код — 32-битный
[BITS 32]

;  При переходе в защищенный режим, сюда будет отдано управление
_protect: 

;  Загрузим регистры DS и SS селектором сегмента данных
mov ax, 0x10
mov ds, ax
mov es, ax
mov ss, ax

;  Наше ядро слинковано по адресу 2мб, переносим его туда. ker_bin — метка, после которой вставлено ядро
mov esi, 0x200000 ; ker_bin

;  Адрес, по которому копируем
mov edi, 0x200000

;  Размер ядра в двойных словах (65536 байт)
mov ecx, 0x4000
rep movsd

;  Ядро скопировано, передаем управление ему
jmp 0x200000

gdt:
dw 0, 0, 0, 0 

;  Нулевой дескриптор
db 0xFF 

;  Сегмент кода с DPL=0 Базой=0 и Лимитом=4 Гб 
db 0xFF 
db 0x00
db 0x00
db 0x00
db 10011010b
db 0xCF
db 0x00
db 0xFF 

;  Сегмент данных с DPL=0 Базой=0 и Лимитом=4Гб 
db 0xFF 
db 0x00 
db 0x00
db 0x00
db 10010010b
db 0xCF
db 0x00

;  Значение, которое мы загрузим в GDTR: 
gd_reg:
dw 8192
dd gdt
msg_start:  db 'Get fun! New loader is on', 0x0A, 0x0D, 0
msg_epm:    db 'Protected mode is greeting you', 0x0A, 0x0D, 0
