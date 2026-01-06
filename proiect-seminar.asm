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

    ; === CERINTA 2 (adaugat fara a modifica partea colegului) ===
    nr_octeti db 0   ; numarul de octeti din sir
    C dw 0           ; cuvantul C (16 biti)
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

            ; === CERINTA 2: calcul cuvant C ===
            call calculeaza_C

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

            ; =========================================================
            ; CERINTA 2: OPERATII PE BITI SI ARITMETICE – CUVANTUL C
            ; C (16 biti) se calculeaza astfel:
            ;  - biti 0..3 : XOR(primii 4 biti ai primului octet, ultimii 4 biti ai ultimului octet)
            ;  - biti 4..7 : OR peste toti octetii a ((octet >> 2) & 0Fh)
            ;  - biti 8..15: suma tuturor octetilor modulo 256
            ; Rezultat in variabila C (word).
            ; =========================================================
            calculeaza_C:
                ; nr_octeti = (buffer+1)/2
                mov al, [buffer + 1]
                shr al, 1
                mov [nr_octeti], al

                ; -------------------------
                ; PAS 1: C[0..3]
                ; -------------------------
                mov si, offset sir
                mov al, [si]          ; primul octet
                mov cl, 4
                shr al, cl            ; high nibble -> low nibble
                and al, 0Fh
                mov dl, al            ; DL = highNib(first)

                mov al, [nr_octeti]
                xor ah, ah
                mov di, offset sir
                add di, ax
                dec di                ; DI = &sir[n-1]
                mov al, [di]          ; ultimul octet
                and al, 0Fh           ; AL = lowNib(last)

                xor al, dl            ; nibble pentru C[0..3]
                and al, 0Fh
                mov dh, al            ; DH = nibble_low (biti 0..3)

                ; -------------------------
                ; PAS 2 (CORECT): C[4..7]
                ; OR peste i: ((sir[i] >> 2) & 0Fh)
                ; -------------------------
                xor dl, dl            ; DL = acumulare OR (0..15)
                mov bl, [nr_octeti]   ; BL = contor
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

                and dl, 0Fh           ; DL = nibble_high (biti 4..7)

                ; lowByte = (nibble_high<<4) | nibble_low
                mov al, dl
                mov cl, 4
                shl al, cl
                or  al, dh
                mov bl, al            ; BL = lowByte

                ; -------------------------
                ; PAS 3: C[8..15]
                ; suma octetilor modulo 256
                ; -------------------------
                xor al, al            ; AL = suma (mod 256)
                mov dl, [nr_octeti]   ; DL = contor
                mov si, offset sir

            sum_loop:
                add al, [si]
                inc si
                dec dl
                jnz sum_loop

                ; AX = [highByte:lowByte]
                ; highByte = suma (AL), lowByte = BL
                mov ah, al
                mov al, bl

                mov [C], ax
                ret
                
        sfarsit:
            mov ax, 4C00h
            int 21h

            code ends
            end start
