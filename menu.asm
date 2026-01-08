assume cs:code, ds:data

data segment
    ; Buffer pentru citirea datelor de la tastatura
    buffer db 17        ; maxim 16 caractere + enter
           db ?         ; numarul de caractere citite efectiv
           db 17 dup(?) ; spatiu pentru caractere

    ; Mesaje pentru utilizator
    mesaj_citire db 'Introduceti 8-16 caractere hex fara spatii intre ele: $'
    mesaj_eroare_len db 0Dh, 0Ah, 'Eroare: trebuie intre 8 si 16 octeti!$'
    mesaj_eroare_hex db 0Dh, 0Ah, 'Eroare: caractere invalide!$'
    mesaj_succes db 0Dh, 0Ah, 'Octetii cititi cu succes!$'
    newline db 0Dh, 0Ah, '$'

    ; Variabile pentru procesare
    sir db 16 dup(?)    ; sirul de octeti convertiti din hex
    nr_octeti db 0      ; numarul de octeti din sir
    C dw 0              ; cuvantul C calculat (16 biti)
    
    ; Mesaje pentru afisarea rezultatelor
    mesaj_sortat db 0Dh, 0Ah, 'Sirul sortat descrescator: $'
    mesaj_max_biti db 0Dh, 0Ah, 'Octetul cu cei mai multi biti 1: $'
    mesaj_pozitie db ' la pozitia: $'
    mesaj_nu_gasit db 0Dh, 0Ah, 'Nu exista octet cu >3 biti 1.$'
    mesaj_cuvant_c db 0Dh, 0Ah, 'Cuvantul C: $'
    mesaj_h db 'h$'
data ends

code segment
start:
    ; Initializare segment de date
    mov ax, data
    mov ds, ax

citeste:
    ; Afisam mesajul de solicitare
    mov ah, 09h
    mov dx, offset mesaj_citire
    int 21h

    ; Citim sirul de caractere de la tastatura
    mov ah, 0Ah
    mov dx, offset buffer
    int 21h

    ; Verificam lungimea (trebuie intre 8 si 16 si numar par)
    mov al, [buffer + 1]    ; AL = numarul de caractere citite
    cmp al, 8
    jb lungime_gresita      ; daca < 8, eroare
    cmp al, 16
    ja lungime_gresita      ; daca > 16, eroare
    test al, 1
    jnz lungime_gresita     ; daca impar, eroare

    ; Validare caractere hexazecimale
    call validare_hex
    jc caractere_gresite    ; daca CF=1, caractere invalide

    ; Convertire din ASCII la binar
    call convertire_ascii_hex

    call calculeaza_C
    call afisare_cuvant_C

    call sortare_descrescatoare
    call afisare_sir_sortat
    call afisare_rezultat_cautare

    ; Mesaj de succes
    mov ah, 09h
    mov dx, offset mesaj_succes
    int 21h
    call afisare_enter
    jmp sfarsit

caractere_gresite:
    ; Afisare mesaj de eroare pentru caractere invalide
    mov ah, 09h
    mov dx, offset mesaj_eroare_hex
    int 21h
    call afisare_enter 
    call afisare_enter
    jmp citeste             ; reluare citire

lungime_gresita:
    ; Afisare mesaj de eroare pentru lungime incorecta
    mov ah, 09h
    mov dx, offset mesaj_eroare_len
    int 21h
    call afisare_enter
    call afisare_enter
    jmp citeste             ; reluare citire

sfarsit:
    ; Terminare program
    mov ax, 4C00h
    int 21h

; Procedura: convertire_ascii_hex
; Descriere: Converteste caracterele ASCII citite in valori binare
; Input: buffer contine caracterele ASCII
; Output: sir[] contine octetii convertiti
convertire_ascii_hex proc
    mov cl, [buffer + 1]    ; CL = numarul de caractere ASCII
    shr cl, 1               ; CL = numarul de octeti (caractere / 2)
    xor ch, ch              ; extindere la word

    mov si, offset buffer + 2   ; SI = pointer la primul caracter
    mov di, offset sir          ; DI = pointer la sirul destinatie

conv_loop:
    lodsb                   ; AL = primul caracter hex
    call hex_char_la_binar  ; converteste in valoare 0-15
    shl al, 4               ; muta in nibble-ul superior
    mov bl, al              ; salveaza temporar

    lodsb                   ; AL = al doilea caracter hex
    call hex_char_la_binar  ; converteste in valoare 0-15
    or bl, al               ; combina cei doi nibble

    mov [di], bl            ; scrie octetul in sir
    inc di                  ; urmatoarea pozitie

    loop conv_loop          ; repeta pentru toate perechile
    ret
convertire_ascii_hex endp

; Procedura: hex_char_la_binar
; Descriere: Converteste un caracter hex ('0'-'9', 'A'-'F') in valoare binara
; Input: AL = caracterul ASCII
; Output: AL = valoarea binara (0-15)
hex_char_la_binar proc
    cmp al, '9'
    jbe cifra               ; daca <= '9', e cifra
    sub al, 'A' - 10        ; daca e litera, scade 'A' si adauga 10
    ret

cifra:
    sub al, '0'             ; daca e cifra, scade '0'
    ret
hex_char_la_binar endp

; Procedura: validare_hex
; Descriere: Verifica daca toate caracterele sunt hexazecimale valide
; Input: buffer contine caracterele
; Output: CF = 1 daca invalid, CF = 0 daca valid
validare_hex proc
    mov cl, [buffer + 1]        ; CL = numarul de caractere
    xor ch, ch                  ; extindere la 16 biti
    mov si, offset buffer + 2   ; SI = pointer la primul caracter

verificare_caracter:
    lodsb                   ; incarca caracterul in AL

    ; Verifica daca e cifra (0-9)
    cmp al, '0'
    jb hex_invalid          ; < '0' -> invalid
    cmp al, '9'
    jbe hex_ok              ; <= '9' -> valid

    ; Verifica daca e litera (A-F)
    cmp al, 'A'
    jb hex_invalid          ; < 'A' -> invalid
    cmp al, 'F'
    jbe hex_ok              ; <= 'F' -> valid

hex_invalid:
    stc                     ; seteaza CF = 1 (invalid)
    ret

hex_ok:
    loop verificare_caracter    ; verifica urmatorul caracter
    clc                         ; seteaza CF = 0 (valid)
    ret
validare_hex endp

; Procedura: afisare_enter
; Descriere: Afiseaza un newline (CR+LF)
afisare_enter proc
    mov ah, 09h
    mov dx, offset newline
    int 21h
    ret
afisare_enter endp

; Procedura: calculeaza_C
; Descriere: Calculeaza cuvantul C (16 biti) conform cerintelor:
;            - Biti 0-3: XOR(high nibble prim octet, low nibble ultim octet)
;            - Biti 4-7: OR peste ((octet >> 2) & 0Fh) pentru toti octetii
;            - Biti 8-15: Suma octeților modulo 256
; Output: variabila C contine rezultatul
calculeaza_C proc
    ; Calculeaza numarul de octeti
    mov al, [buffer + 1]
    shr al, 1               ; nr_octeti = caractere / 2
    mov [nr_octeti], al

    ; === PAS 1: Biti 0-3 (XOR intre nibble-uri) ===
    mov si, offset sir
    mov al, [si]            ; AL = primul octet
    mov cl, 4
    shr al, cl              ; extrage high nibble
    and al, 0Fh
    mov dl, al              ; DL = high nibble primul octet

    ; Obtine ultimul octet
    mov al, [nr_octeti]
    xor ah, ah
    mov di, offset sir
    add di, ax
    dec di                  ; DI = adresa ultimului octet
    mov al, [di]            ; AL = ultimul octet
    and al, 0Fh             ; AL = low nibble ultimul octet

    xor al, dl              ; XOR intre cele doua nibble-uri
    and al, 0Fh
    mov dh, al              ; DH = rezultat biti 0-3

    ; PAS 2: Biti 4-7 (OR peste shifted octeti) ===
    xor dl, dl              ; DL = acumulator OR
    mov bl, [nr_octeti]     ; BL = contor
    xor bh, bh
    mov si, offset sir

or_loop2:
    mov al, [si]
    inc si

    mov ah, al
    mov cl, 2
    shr ah, cl              ; AH = octet >> 2
    and ah, 0Fh             ; izoleaza primii 4 biti
    or  dl, ah              ; acumuleaza cu OR

    dec bl
    jnz or_loop2

    and dl, 0Fh             ; DL = rezultat biti 4-7

    ; Combina biti 0-3 si 4-7 in low byte
    mov al, dl
    mov cl, 4
    shl al, cl              ; muta biti 4-7 in pozitie
    or  al, dh              ; combina cu biti 0-3
    mov bl, al              ; BL = low byte al lui C

    ;PAS 3: Biti 8-15 (Suma octeti modulo 256) ===
    xor al, al              ; AL = acumulator suma
    mov dl, [nr_octeti]     ; DL = contor
    mov si, offset sir

sum_loop:
    add al, [si]            ; aduna octetul curent
    inc si
    dec dl
    jnz sum_loop

    ; Construieste cuvantul C: AH = suma, AL = biti 0-7
    mov ah, al              ; AH = high byte (suma mod 256)
    mov al, bl              ; AL = low byte

    mov [C], ax             ; salveaza rezultatul
    ret
calculeaza_C endp

; Procedura: sortare_descrescatoare
; Descriere: Sorteaza sirul de octeti in ordine descrescatoare (Bubble Sort)
; Input: sir[] contine octetii de sortat
; Output: sir[] sortat descrescator
sortare_descrescatoare proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov cl, [nr_octeti]
    dec cl                  ; CL = nr_octeti - 1
    xor ch, ch
    cmp cx, 0
    je sort_end             ; daca n <= 1, nu e nimic de sortat
    
sort_outer:
    mov di, cx              ; DI = numarul de comparatii in acest pas
    mov si, offset sir      ; SI = pointer la sir
    
sort_inner:
    mov al, [si]            ; AL = sir[i]
    mov bl, [si+1]          ; BL = sir[i+1]
    cmp al, bl              ; compara sir[i] cu sir[i+1]
    jae no_swap             ; daca sir[i] >= sir[i+1], nu schimba
    
    ; Schimba sir[i] cu sir[i+1]
    mov [si], bl
    mov [si+1], al
    
no_swap:
    inc si
    dec di
    jnz sort_inner          ; continua comparatiile
    
    loop sort_outer         ; urmatorul pas de sortare
    
sort_end:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
sortare_descrescatoare endp

; Procedura: numara_biti_1
; Descriere: Numara cati biti sunt setati pe 1 intr-un octet
; Input: AL = octetul
; Output: AL = numarul de biti 1
numara_biti_1 proc
    push cx
    push bx
    
    xor bl, bl              ; BL = contor biti 1
    mov cx, 8               ; 8 biti de verificat
    
count_loop:
    shr al, 1               ; muta LSB in CF
    jnc skip_count          ; daca CF = 0, nu incrementa
    inc bl                  ; daca CF = 1, incrementeaza contorul
    
skip_count:
    loop count_loop
    
    mov al, bl              ; returneaza rezultatul in AL
    pop bx
    pop cx
    ret
numara_biti_1 endp

; Procedura: gaseste_max_biti
; Descriere: Gaseste octetul cu cel mai mare numar de biti 1 (>3)
; Input: sir[] contine octetii
; Output: AL = octetul gasit, BL = pozitia (0-based), CF = 1 daca nu exista
gaseste_max_biti proc
    push cx
    push dx
    push si
    
    mov cl, [nr_octeti]
    xor ch, ch
    mov si, offset sir
    
    xor bl, bl              ; BL = pozitia maximului
    xor dh, dh              ; DH = numarul maxim de biti 1
    xor dl, dl              ; DL = pozitia curenta
    
search_loop:
    push ax
    mov al, [si]            ; AL = octetul curent
    push ax                 ; salveaza octetul
    call numara_biti_1      ; AL = numarul de biti 1
    
    cmp al, dh              ; compara cu maximul curent
    jbe not_new_max         ; daca <= max, nu actualiza
    
    mov dh, al              ; actualizeaza maximul
    mov bl, dl              ; actualizeaza pozitia
    
not_new_max:
    pop ax                  ; restaureaza octetul
    pop ax
    inc si
    inc dl                  ; urmatoarea pozitie
    loop search_loop
    
    ; Verifica daca maximul > 3
    cmp dh, 3
    jbe not_found
    
    ; Gasit: incarca octetul la pozitia BL
    mov si, offset sir
    xor ah, ah
    mov al, bl
    add si, ax
    mov al, [si]
    clc                     ; CF = 0 (succes)
    jmp search_end
    
not_found:
    stc                     ; CF = 1 (nu s-a gasit)
    
search_end:
    pop si
    pop dx
    pop cx
    ret
gaseste_max_biti endp

; Procedura: afisare_octet_hex
; Descriere: Afiseaza un octet in format hexazecimal (ex: 3F)
; Input: AL = octetul de afisat
afisare_octet_hex proc
    push ax
    push bx
    push cx
    push dx
    
    mov bl, al              ; salveaza octetul
    
    ; Afiseaza nibble-ul superior (biti 7-4)
    mov cl, 4
    shr al, cl
    call afisare_nibble_hex
    
    ; Afiseaza nibble-ul inferior (biti 3-0)
    mov al, bl
    and al, 0Fh
    call afisare_nibble_hex
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
afisare_octet_hex endp

; Procedura: afisare_nibble_hex
; Descriere: Afiseaza un nibble (4 biti) in format hex (0-9, A-F)
; Input: AL = nibble-ul (0-15)
afisare_nibble_hex proc
    push ax
    push dx
    
    cmp al, 9
    jbe nibble_digit        ; daca <= 9, e cifra
    add al, 'A' - 10        ; daca > 9, e litera A-F
    jmp print_nibble
    
nibble_digit:
    add al, '0'             ; converteste in cifra ASCII
    
print_nibble:
    mov dl, al
    mov ah, 02h             ; functia de afisare caracter
    int 21h
    
    pop dx
    pop ax
    ret
afisare_nibble_hex endp

; Procedura: afisare_cuvant_C
; Descriere: Afiseaza cuvantul C in format hexazecimal (ex: 5307h)
afisare_cuvant_C proc
    push ax
    push dx
    
    mov ah, 09h
    mov dx, offset mesaj_cuvant_c
    int 21h
    
    ; Afiseaza high byte
    mov ax, [C]
    mov al, ah
    call afisare_octet_hex
    
    ; Afiseaza low byte
    mov ax, [C]
    call afisare_octet_hex
    
    ; Afiseaza 'h'
    mov ah, 09h
    mov dx, offset mesaj_h
    int 21h
    
    call afisare_enter
    
    pop dx
    pop ax
    ret
afisare_cuvant_C endp

; Procedura: afisare_sir_sortat
; Descriere: Afiseaza sirul sortat in format hexazecimal
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
    
    ; Afiseaza spatiu intre octeti
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

; Procedura: afisare_rezultat_cautare
; Descriere: Afiseaza octetul cu cei mai multi biti 1 si pozitia sa
afisare_rezultat_cautare proc
    push ax
    push bx
    push dx
    
    call gaseste_max_biti
    jc nu_gasit_afisare     ; daca CF=1, nu s-a gasit
    
    ; Afiseaza octetul gasit
    mov ah, 09h
    mov dx, offset mesaj_max_biti
    int 21h
    
    call afisare_octet_hex
    
    ; Afiseaza pozitia
    mov ah, 09h
    mov dx, offset mesaj_pozitie
    int 21h
    
    mov al, bl
    inc al                  ; conversie la 1-based pentru utilizator
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

; Procedura: afisare_numar_decimal
; Descriere: Afiseaza un numar in baza 10
; Input: AX = numarul de afisat
afisare_numar_decimal proc
    push ax
    push bx
    push cx
    push dx
    
    xor cx, cx              ; CX = contor cifre
    mov bx, 10              ; BX = baza 10
    
divide_loop:
    xor dx, dx
    div bx                  ; DX:AX / 10 -> AX = cat, DX = rest
    push dx                 ; salveaza cifra pe stiva
    inc cx
    cmp ax, 0
    jne divide_loop
    
print_digits:
    pop dx                  ; recupereaza cifra
    add dl, '0'             ; converteste in ASCII
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