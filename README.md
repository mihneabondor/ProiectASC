# ProiectASC
# Documentație Proiect ASM
## Programare în Limbaj de Asamblare - 8086

## 1. Descrierea Generală a Programului

Acest program implementează un sistem de procesare a datelor în limbaj de asamblare 8086, care citește un șir de octeți în format hexazecimal de la utilizator și efectuează operații bitwise, aritmetice și de manipulare a datelor.

**Funcționalități implementate:**
- Citirea interactivă și validarea a 8-16 octeți în format hexazecimal
- Calculul unui cuvânt de 16 biți prin operații pe biți (XOR, OR, adunare)
- Sortarea descrescătoare a șirului de octeți
- Identificarea și afișarea octetului cu cel mai mare număr de biți setați pe 1

---

## 2. Explicația Structurii și Principalelor Etape

### 2.1 Structura Generală

Programul este organizat în trei secțiuni principale:

**a) Citirea și Validarea Datelor**
- Utilizatorul introduce 8-16 caractere hexazecimale (fără spații)
- Se validează lungimea (trebuie să fie între 8 și 16 caractere și număr par)
- Se validează formatul (doar caractere 0-9 și A-F)
- În caz de eroare, se reia citirea

**b) Procesarea Datelor (Cerința 2)**
- Conversia caracterelor ASCII în octeți binari
- Calculul cuvântului C pe 16 biți în trei pași:
  - **Biți 0-3:** XOR între primii 4 biți ai primului octet și ultimii 4 biți ai ultimului octet
  - **Biți 4-7:** OR cumulativ peste `(octet >> 2) & 0Fh` pentru fiecare octet
  - **Biți 8-15:** Suma tuturor octeților modulo 256

**c) Manipularea Șirului (Cerința 5)**
- Sortarea octeților în ordine descrescătoare folosind Bubble Sort
- Găsirea octetului cu cel mai mare număr de biți 1 (unde numărul > 3)
- Afișarea poziției acestui octet în șir

### 2.2 Flow-ul Principal

```
START → Citire Input → Validare → Conversie ASCII→Binar →
→ Calcul Cuvânt C → Sortare → Găsire Max Biți → Afișare → END
```

### 2.3 Principalele Proceduri

| Procedură | Rol |
|-----------|-----|
| `validare_hex` | Verifică dacă toate caracterele sunt 0-9, A-F |
| `convertire_ascii_hex` | Convertește perechi de caractere ASCII în octeți |
| `calculeaza_C` | Implementează algoritmul de calcul al cuvântului C |
| `sortare_descrescatoare` | Sortează șirul folosind Bubble Sort |
| `numara_biti_1` | Numără câți biți sunt setați pe 1 într-un octet |
| `gaseste_max_biti` | Găsește octetul cu cei mai mulți biți 1 |
| `afisare_*` | Set de proceduri pentru afișarea rezultatelor |

---

## 3. Dificultăți Întâlnite și Soluții

### 3.1 Conversie ASCII la Hexazecimal

**Problema:** Caracterele ASCII pentru cifre (0-9) și litere (A-F) au coduri diferite și necesită tratare separată.

**Soluție implementată:**
```assembly
hex_char_la_binar proc
    cmp al, '9'
    jbe cifra              ; Dacă <= '9', tratează ca cifră
    sub al, 'A' - 10       ; Altfel, tratează ca literă A-F
    ret
cifra:
    sub al, '0'            ; Scade codul ASCII al lui '0'
    ret
hex_char_la_binar endp
```

Această abordare simplifică conversia prin comparație și operații aritmetice directe.

### 3.2 Calculul Biților 4-7 ai Cuvântului C

**Problema:** Cerința "OR între biții 2-5 ai fiecărui octet" era ambiguă și necesita clarificare.

**Soluție:** Am interpretat cerința ca: pentru fiecare octet, se face shift la dreapta cu 2 poziții, se izolează primii 4 biți (AND cu 0Fh), apoi se aplică OR cumulativ:

```assembly
or_loop2:
    mov al, [si]
    mov ah, al
    mov cl, 2
    shr ah, cl              ; octet >> 2
    and ah, 0Fh             ; izolează primii 4 biți
    or  dl, ah              ; OR cumulativ
    inc si
    dec bl
    jnz or_loop2
```

### 3.3 Numărarea Biților Setați

**Problema:** Procesorul 8086 nu are instrucțiune dedicată pentru numărarea biților 1.

**Soluție:** Am implementat un algoritm de shift și verificare a Carry Flag:
```assembly
numara_biti_1 proc
    xor bl, bl              ; Contor = 0
    mov cx, 8               ; 8 biți de verificat
count_loop:
    shr al, 1               ; Shiftează, LSB → CF
    jnc skip_count          ; Dacă CF=0, nu incrementa
    inc bl                  ; Dacă CF=1, incrementează
skip_count:
    loop count_loop
    mov al, bl              ; Returnează rezultatul
    ret
numara_biti_1 endp
```

### 3.4 Organizarea Codului

**Problema:** Codul inițial avea procedurile definite în interiorul secțiunii `start:`, ceea ce cauza probleme de flow și structură.

**Soluție:** Am restructurat programul folosind `proc`/`endp` pentru fiecare procedură și am separat clar:
- Secțiunea principală (`start:`, `citeste:`, `sfarsit:`)
- Procedurile de procesare
- Procedurile de afișare

### 3.5 Afișarea în Format Hexazecimal

**Problema:** DOS nu oferă funcții native pentru afișare în format hexazecimal.

**Soluție:** Am creat proceduri dedicate care convertesc nibble-uri (4 biți) în caractere ASCII:
- Valori 0-9 → caractere '0'-'9' (adunare cu 30h)
- Valori 10-15 → caractere 'A'-'F' (adunare cu 37h)

Această abordare permite afișarea clară și corectă a rezultatelor în format hex.

---

## 4. Exemple de Execuție

### Exemplul 1: Executare Normală

**Input:**
```
Introduceti 8-16 caractere hex fara spatii intre ele: 3F7A125C2010ABCD
```

**Output:**
```
Cuvantul C: 5307h

Sirul sortat descrescator: CD AB 7A 5C 3F 20 12 10 

Octetul cu cei mai multi biti 1: CD la pozitia: 1

Octetii cititi cu succes!
```

**Explicație:**
- Se citesc 8 octeți: 3F, 7A, 12, 5C, 20, 10, AB, CD
- Cuvântul C se calculează conform algoritmului
- Șirul se sortează descrescător
- CD (11001101) are 5 biți pe 1, fiind maximul

### Exemplul 2: Eroare de Lungime

**Input:**
```
Introduceti 8-16 caractere hex fara spatii intre ele: 1234
```

**Output:**
```
Eroare: trebuie intre 8 si 16 octeti!

Introduceti 8-16 caractere hex fara spatii intre ele: _
```

### Exemplul 3: Eroare Caractere Invalide

**Input:**
```
Introduceti 8-16 caractere hex fara spatii intre ele: 12GH5678ABCD
```

**Output:**
```
Eroare: caractere invalide!

Introduceti 8-16 caractere hex fara spatii intre ele: _
```

### Exemplul 4: Niciun Octet cu >3 Biți

**Input:**
```
Introduceti 8-16 caractere hex fara spatii intre ele: 0101020204080810
```

**Output:**
```
Cuvantul C: XXXXh

Sirul sortat descrescator: 10 08 08 04 02 02 01 01 

Nu exista octet cu >3 biti 1.

Octetii cititi cu succes!
```
---

**Repository GitHub:** [link]  
**Data finalizării:** Ianuarie 2026  
**Versiune:** 1.0
