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

            ; succes
            mov Ah, 09h
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