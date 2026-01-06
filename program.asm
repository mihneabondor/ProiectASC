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

data ends

code segment
    start:
        mov ax, data
        mov ds, ax

        citeste:
            ; afisam mesajul
            mov Ah, 09h
            mov dx, offset mesaj_citire
            int 21h

            ; citesc sirul
            mov Ah, 0Ah
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

            ; succes
            mov Ah, 09h
            mov dx, offset mesaj_succes
            int 21h
            call afisare_enter
            jmp sfarsit

            convertire_ascii_hex:
                mov cl, [buffer + 1] ; numarul de caractere ascii
                shr cl, 1 ; numarul de octeti = caractere / 2
                xor ch, ch ; extindere la word

                mov si, offset buffer + 2
                mov di, offset sir

                conv_loop:
                    lodsb
                    call hex_char_la_binar
                    shl al, 4 ; muta in bitii superiori (face loc in bitii inferiori pentru al doilea caracter)
                    mov bl, al

                    lodsb
                    call hex_char_la_binar
                    or bl, al ; combina rezultatele

                    mov [di], bl ; scrie rezultatul
                    inc di ; creste indexul sirului destinatie

                    loop conv_loop
                    ret

            hex_char_la_binar:
                cmp al, '9'
                jbe cifra
                sub al, 'A' - 10
                ret

            cifra:
                sub al, '0'
                ret

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

            validare_hex:
                mov cl, [buffer + 1] ; numarul de caractere
                xor ch, ch ; extindere la 16 biti
                mov si, offset buffer + 2 ; primul caracter

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

                    ;seteaza carry flag la 1 sau 0 in functie de rezultatul validarii
                    hex_invalid:
                        stc
                        ret

                    hex_ok:
                        loop verificare_caracter
                        clc
                        ret

            afisare_enter:
                ; enter dupa
                mov ah, 09h
                mov dx, offset newline
                int 21h
                ret
                
        sfarsit:
            mov ax, 4C00h
            int 21h

            code ends
            end start