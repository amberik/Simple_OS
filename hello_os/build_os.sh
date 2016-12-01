#!/bin/bash

# Компилируем наш образ.
yasm -f bin -o hello.bin hello_os.asm 
# Создаём образ диска (disk.img file) и заполняем его нулями:
dd if=/dev/zero of=disk.img bs=1024 count=1440
# Записываем в самое начало образа нашу программу:
dd if=hello.bin of=disk.img conv=notrunc
# Прибераем за собой
rm hello.bin
