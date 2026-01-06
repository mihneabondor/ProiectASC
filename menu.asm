assume cs:code, ds:data

data segment
    buffer db 17 ; maxim 16 caractere + enter
            db ?
            db 17 dup(?)

    mesaj_citire db 'Introduceti 8-16 caractere hex fara spatii intre ele: $'
    mesaj_eroare_len db 0Dh, 0Ah, 'Eroare: trebuie intre 8 si 16 octeti!$'
    mesaj_eroare_hex db 0Dh, 0Ah, 'Eroare: caractere invalide!$'
    mesaj_succes db 0Dh, 0Ah, 'Octetii cititi cu succes!$'
    newline db 0Dh, 0Ah, '$'

    sir db 16 dup(?) ; octetii convertiti

    ; === CERINTA 2 ===
    nr_octeti db 0   ; numarul de octeti din sir
    C dw 0           ; cuvantul C (16 biti)
    
    ; === CERINTA 5 ===
    mesaj_sortat db 0Dh, 0Ah, 'Sirul sortat descrescator: $'
    mesaj_max_biti db 0Dh, 0Ah, 'Octetul cu cei mai multi biti 1: $'
    mesaj_pozitie db ' la pozitia: $'
    mesaj_nu_gasit db 0Dh, 0Ah, 'Nu exista octet cu >3 biti 1.$'
    mesaj_cuvant_c db 0Dh, 0Ah, 'Cuvantul C: $'
    mesaj_h db 'h$'
data ends

code segment
start:
    mov ax, data
    mov ds, ax

citeste:
    ; afisam mesajul
    mov ah, 09h
    mov dx, offset mesaj_citire
    int 21h

    ; citesc sirul
    mov ah, 0Ah
    mov dx, offset buffer
    int 21h

    ; verific lungimea (intre 8 si 16 si numar par)
    mov al, [buffer + 1]
    cmp al, 8
    jb lungime_gresita
    cmp al, 16
    ja lungime_gresita
    test al, 1
    jnz lungime_gresita

    ; validare hex
    call validare_hex
    jc caractere_gresite

    call convertire_ascii_hex

    ; === CERINTA 2: calcul cuvant C ===
    call calculeaza_C
    call afisare_cuvant_C

    ; === CERINTA 5: manipularea sirului ===
    call sortare_descrescatoare
    call afisare_sir_sortat
    call afisare_rezultat_cautare

    ; succes
    mov ah, 09h
    mov dx, offset mesaj_succes
    int 21h
    call afisare_enter
    jmp sfarsit

caractere_gresite:
    mov ah, 09h
    mov dx, offset mesaj_eroare_hex
    int 21h
    call afisare_enter 
    call afisare_enter
    jmp citeste

lungime_gresita:
    mov ah, 09h
    mov dx, offset mesaj_eroare_len
    int 21h
    call afisare_enter
    call afisare_enter
    jmp citeste

sfarsit:
    mov ax, 4C00h
    int 21h

; ========================================
; PROCEDURI
; ========================================

convertire_ascii_hex proc
    mov cl, [buffer + 1]
    shr cl, 1
    xor ch, ch

    mov si, offset buffer + 2
    mov di, offset sir

conv_loop:
    lodsb
    call hex_char_la_binar
    shl al, 4
    mov bl, al

    lodsb
    call hex_char_la_binar
    or bl, al

    mov [di], bl
    inc di

    loop conv_loop
    ret
convertire_ascii_hex endp

hex_char_la_binar proc
    cmp al, '9'
    jbe cifra
    sub al, 'A' - 10
    ret

cifra:
    sub al, '0'
    ret
hex_char_la_binar endp

validare_hex proc
    mov cl, [buffer + 1]
    xor ch, ch
    mov si, offset buffer + 2

verificare_caracter:
    lodsb

    cmp al, '0'
    jb hex_invalid
    cmp al, '9'
    jbe hex_ok

    cmp al, 'A'
    jb hex_invalid
    cmp al, 'F'
    jbe hex_ok

hex_invalid:
    stc
    ret

hex_ok:
    loop verificare_caracter
    clc
    ret
validare_hex endp

afisare_enter proc
    mov ah, 09h
    mov dx, offset newline
    int 21h
    ret
afisare_enter endp

; =========================================================
; CERINTA 2: OPERATII PE BITI SI ARITMETICE – CUVANTUL C
; =========================================================
calculeaza_C proc
    ; nr_octeti = (buffer+1)/2
    mov al, [buffer + 1]
    shr al, 1
    mov [nr_octeti], al

    ; PAS 1: C[0..3]
    mov si, offset sir
    mov al, [si]
    mov cl, 4
    shr al, cl
    and al, 0Fh
    mov dl, al

    mov al, [nr_octeti]
    xor ah, ah
    mov di, offset sir
    add di, ax
    dec di
    mov al, [di]
    and al, 0Fh

    xor al, dl
    and al, 0Fh
    mov dh, al

    ; PAS 2: C[4..7]
    xor dl, dl
    mov bl, [nr_octeti]
    xor bh, bh
    mov si, offset sir

or_loop2:
    mov al, [si]
    inc si

    mov ah, al
    mov cl, 2
    shr ah, cl
    and ah, 0Fh
    or  dl, ah

    dec bl
    jnz or_loop2

    and dl, 0Fh

    mov al, dl
    mov cl, 4
    shl al, cl
    or  al, dh
    mov bl, al

    ; PAS 3: C[8..15]
    xor al, al
    mov dl, [nr_octeti]
    mov si, offset sir

sum_loop:
    add al, [si]
    inc si
    dec dl
    jnz sum_loop

    mov ah, al
    mov al, bl

    mov [C], ax
    ret
calculeaza_C endp

; =========================================================
; CERINTA 5: MANIPULAREA SIRULUI DE OCTETI
; =========================================================

sortare_descrescatoare proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov cl, [nr_octeti]
    dec cl
    xor ch, ch
    cmp cx, 0
    je sort_end
    
sort_outer:
    mov di, cx
    mov si, offset sir
    
sort_inner:
    mov al, [si]
    mov bl, [si+1]
    cmp al, bl
    jae no_swap
    
    mov [si], bl
    mov [si+1], al
    
no_swap:
    inc si
    dec di
    jnz sort_inner
    
    loop sort_outer
    
sort_end:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
sortare_descrescatoare endp

numara_biti_1 proc
    push cx
    push bx
    
    xor bl, bl
    mov cx, 8
    
count_loop:
    shr al, 1
    jnc skip_count
    inc bl
    
skip_count:
    loop count_loop
    
    mov al, bl
    pop bx
    pop cx
    ret
numara_biti_1 endp

gaseste_max_biti proc
    push cx
    push dx
    push si
    
    mov cl, [nr_octeti]
    xor ch, ch
    mov si, offset sir
    
    xor bl, bl
    xor dh, dh
    xor dl, dl
    
search_loop:
    push ax
    mov al, [si]
    push ax
    call numara_biti_1
    
    cmp al, dh
    jbe not_new_max
    
    mov dh, al
    mov bl, dl
    
not_new_max:
    pop ax
    pop ax
    inc si
    inc dl
    loop search_loop
    
    cmp dh, 3
    jbe not_found
    
    mov si, offset sir
    xor ah, ah
    mov al, bl
    add si, ax
    mov al, [si]
    clc
    jmp search_end
    
not_found:
    stc
    
search_end:
    pop si
    pop dx
    pop cx
    ret
gaseste_max_biti endp

afisare_octet_hex proc
    push ax
    push bx
    push cx
    push dx
    
    mov bl, al
    
    mov cl, 4
    shr al, cl
    call afisare_nibble_hex
    
    mov al, bl
    and al, 0Fh
    call afisare_nibble_hex
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
afisare_octet_hex endp

afisare_nibble_hex proc
    push ax
    push dx
    
    cmp al, 9
    jbe nibble_digit
    add al, 'A' - 10
    jmp print_nibble
    
nibble_digit:
    add al, '0'
    
print_nibble:
    mov dl, al
    mov ah, 02h
    int 21h
    
    pop dx
    pop ax
    ret
afisare_nibble_hex endp

afisare_cuvant_C proc
    push ax
    push dx
    
    mov ah, 09h
    mov dx, offset mesaj_cuvant_c
    int 21h
    
    mov ax, [C]
    mov al, ah
    call afisare_octet_hex
    
    mov ax, [C]
    call afisare_octet_hex
    
    mov ah, 09h
    mov dx, offset mesaj_h
    int 21h
    
    call afisare_enter
    
    pop dx
    pop ax
    ret
afisare_cuvant_C endp

afisare_sir_sortat proc
    push ax
    push cx
    push si
    
    mov ah, 09h
    mov dx, offset mesaj_sortat
    int 21h
    
    mov cl, [nr_octeti]
    xor ch, ch
    mov si, offset sir
    
print_array:
    mov al, [si]
    call afisare_octet_hex
    
    mov dl, ' '
    mov ah, 02h
    int 21h
    
    inc si
    loop print_array
    
    call afisare_enter
    
    pop si
    pop cx
    pop ax
    ret
afisare_sir_sortat endp

afisare_rezultat_cautare proc
    push ax
    push bx
    push dx
    
    call gaseste_max_biti
    jc nu_gasit_afisare
    
    mov ah, 09h
    mov dx, offset mesaj_max_biti
    int 21h
    
    call afisare_octet_hex
    
    mov ah, 09h
    mov dx, offset mesaj_pozitie
    int 21h
    
    mov al, bl
    inc al
    xor ah, ah
    
    call afisare_numar_decimal
    
    call afisare_enter
    jmp end_afisare_cautare
    
nu_gasit_afisare:
    mov ah, 09h
    mov dx, offset mesaj_nu_gasit
    int 21h
    call afisare_enter
    
end_afisare_cautare:
    pop dx
    pop bx
    pop ax
    ret
afisare_rezultat_cautare endp

afisare_numar_decimal proc
    push ax
    push bx
    push cx
    push dx
    
    xor cx, cx
    mov bx, 10
    
divide_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne divide_loop
    
print_digits:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop print_digits
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
afisare_numar_decimal endp

code ends
end start