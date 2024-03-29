.model small                  ; Встановлення малої моделі пам'яті
.stack 100h                   ; Виділення 256 байт під стек

.data                         ; Секція даних
    result db 6 dup('$')         ; Буфер для зберігання рядкового представлення чисел, ініціалізований символами '$'

    occurrences dw 100 dup(0)    ; Масив для зберігання кількості входжень підстрічки
    string_length db 0        ; Змінна для зберігання довжини поточної стрічки
    
    string db 255 dup(0)      ; Буфер для зберігання поточної стрічки, що читається з вводу
    substring db 255 dup(0)   ; Буфер для зберігання підстрічки, по якій ведеться пошук

    substring_length db 0     ; Змінна для зберігання довжини підстрічки
    occurrences_length db 0      ; Змінна для зберігання кількості записів в масиві ocuranse

.code                         
main PROC                     
   mov ax, ds
   mov es, ax
   mov ax, @data
   mov ds, ax
   call read_argument         


read_line_loop:
    call read_line
    push ax

    call count_substring_occurrences

    pop ax
    or ax, ax
    jnz read_line_loop

read_line_loop_end:

    call sort_occurrences
    call print_occurrences

end_program:
    mov ah, 4Ch
    int 21h

main ENDP

read_next PROC                    
       mov string_length, 0    ; Ініціалізація довжини стрічки до 0
next_char:
    mov ah, 3Fh                ; Встановлення функції DOS для читання з файлу/вводу
    mov bx, 0h                 ; Використання дескриптора стандартного вводу
    mov cx, 1                  ; Встановлення кількості байтів для читання (1 байт)
    mov dx, offset string      ; Встановлення вказівника на буфер стрічки
    add dl, string_length      ; Додавання довжини стрічки до вказівника, щоб читати в кінець буфера
    int 21h                    ; Виклик DOS-преривання для читання
    inc string_length          ; Збільшення лічильника довжини стрічки
    mov bx, dx
    cmp byte ptr [bx], 0Ah     ; Перевірка на символ нового рядка
    je read_line_end           ; Якщо знайдено символ нового рядка, завершуємо читання
    or ax, ax
    jnz next_char              ; Якщо було прочитано не нуль байтів, продовжуємо читання
read_line_end:
    mov byte ptr [bx], 0       ; Встановлення кінця стрічки нульовим символом
    ret                         ; Повернення з процедури
    
read_next ENDP

read_argument PROC
    xor ch, ch                           ; Очищення верхньої частини регістра CX
    mov cl, es:[80h]                     ; Завантаження довжини аргументів з офсету 80h
    dec cl                               ; Зменшення на 1, оскільки перший символ - це команда
    mov substring_length, cl             ; Збереження довжини підрядка
read_substring:
    test cl, cl                          ; Перевірка, чи не дійшли до кінця аргументів
    jz read_substring_end               ; Якщо так, завершуємо процедуру
    mov si, 81h                          ; Встановлення SI на початок аргументів (з офсету 81h)
    add si, cx                           ; Додавання зміщення до SI
    mov bx, offset substring             ; Встановлення BX на початок буфера підрядка
    add bx, cx                           ; Додавання зміщення до BX
    mov al, es:[si]                      ; Копіювання символу з аргументів
    mov byte ptr [bx-1], al              ; Збереження символу в підрядок
    dec cl                               ; Зменшення лічильника довжини
    jmp read_substring                   ; Повторення циклу для наступного символу
read_substring_end:
    ret                                  ; Повернення з процедури
read_argument ENDP


count_occurrences_substring PROC
 xor cx, cx                 
 mov bx, offset string      
er_loop:     
 mov si, bx                 
 mov di, offset substring   
 mov dh, substring_length   
er_loop:     
 mov al, [si]               
 mov ah, [di]               
 cmp al, ah                 
 jne not_matched            
 inc si                     
 inc di                     
 dec dh                     
 jnz inner_loop             
                            
 inc bx      
 inc cl                     
_matched:                   
 inc bx                     
 cmp byte ptr [bx], 0       
 jnz outer_loop             
                            
 mov si, offset occurrences
 xor bx, bx
 mov bl, occurrences_length
 shl bl, 1
 add si, bx
 mov al, occurrences_length
 mov ah, cl
 mov [si], ax
 inc occurrences_length
 ret
count_occurrences_substring ENDP

convert_to_string PROC
    push ax             ; Збереження регістра AX
    push bx             ; Збереження регістра BX
    push cx             ; Збереження регістра CX
    push si             ; Збереження регістра SI

    mov bx, 10          ; BX буде використовуватись як дільник

    mov di, offset result   ; DI вказує на буфер результату
    mov cx, 0           ; Лічильник кількості цифр

convert_loop:
    xor dx, dx          ; Очищення DX перед діленням
    div bx              ; Ділення AX на BX, частка у AX, залишок у DX

    add dl, '0'         ; Перетворення залишку у ASCII символ
    mov [di], dl        ; Збереження ASCII символу у буфері результату
    inc di              ; Перехід до наступної позиції у буфері результату

    inc cx              ; Інкрементування лічильника цифр

    cmp ax, 0           ; Перевірка, чи частка стала нулем
    jnz convert_loop    ; Якщо ні, продовження циклу

    ; Реверсування рядка
    mov si, offset result  ; SI вказує на початок рядка
    mov di, cx           ; DI містить кількість цифр
    dec di               ; Декрементування DI для отримання індексу останнього символу

reverse_loop:
    cmp si, di           ; Порівняння SI та DI
    jge end_reverse      ; Якщо SI >= DI, досягнення середини рядка
    mov al, [si]         ; Завантаження символу з початку
    mov ah, [di]         ; Завантаження символу з кінця
    mov [si], ah         ; Обмін символів
    mov [di], al         ; Обмін символів
    inc si               ; Переміщення SI вперед
    dec di               ; Переміщення DI назад
    jmp reverse_loop     ; Повторення циклу

end_reverse:
    mov si, offset result ; SI вказує на початок рядка
    add si, cx           ; Переміщення SI в кінець рядка
    mov byte ptr [si], '$'  ; Додавання '$' як термінатора рядка

    pop si               ; Відновлення регістра SI
    pop cx               ; Відновлення регістра CX
    pop bx               ; Відновлення регістра BX
    pop ax               ; Відновлення регістра AX
    ret
convert_to_string ENDP


end main




    mov ah, 4Ch               ; Функція DOS для завершення програми
    int 21h                   ; Виклик DOS-преривання для завершення


end main
