#!/bin/bash

# Компилируем наш образ.
yasm -f bin -o loader.bin loader_2.asm
yasm -f bin -o kernel.bin loader_1.asm

# Создаём образ диска (disk.img file) и заполняем его нулями:
dd if=/dev/zero of=disk.img bs=1024 count=1440
# Записываем в самое начало образа нашу программу:
dd if=kernel.bin of=disk.img conv=notrunc
# Прибераем за собой
rm loader.bin kernel.bin
