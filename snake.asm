.MODEL SMALL
.STACK 100H

.DATA
    ; các chuỗi văn bản (tiếng việt không dấu)
    msgTitle        DB '=== GAME RAN SAN MOI ===', '$'
    msgHighScoreStr DB 'Ky luc hien tai: ', '$'
    msgDiff1        DB '1. De (Easy)', '$'
    msgDiff2        DB '2. Trung Binh (Medium)', '$'
    msgDiff3        DB '3. Kho (Hard)', '$'
    msgExitOpt      DB '4. Thoat game', '$'
    msgPrompt       DB 'Chon chuc nang (1/2/3/4): ', '$'
    msgConfirmExit  DB 'Nhan ENTER de xac nhan thoat...', '$'
    
    msgScore        DB 'Diem: ', '$'
    msgGameOver     DB 'GAME OVER!', '$'
    msgWin          DB 'BAN DA CHIEN THANG!', '$'
    msgPlayAgain    DB 'Ban co muon choi lai khong (Y/N)? ', '$'
    
    ; cấu hình game
    mapWidth    EQU 16
    mapHeight   EQU 16
    offsetX     DB 32   ; độ dời x để in bản đồ ra giữa màn hình
    offsetY     DB 4    ; độ dời y để in bản đồ ra giữa màn hình
    
    ; trạng thái rắn
    snakeX      DB 256 DUP(0) ; mảng lưu tọa độ x (tối đa 16x16 = 256)
    snakeY      DB 256 DUP(0) ; mảng lưu tọa độ y
    snakeLen    DW 3          ; chiều dài ban đầu
    dir         DB 1          ; hướng: 0=lên, 1=phải, 2=xuống, 3=trái
    
    ; biến game
    foodX       DB 0
    foodY       DB 0
    score       DW 0
    highScore   DW 0
    gameOver    DB 0
    gameWin     DB 0
    
    ; biến delay (microseconds) cho interrupt 15h ah=86h
    delayCX     DW 0
    delayDX     DW 0

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

MAIN_MENU_LOOP:
    CALL CLEAR_SCREEN
    
    ; in title
    MOV DL, 25
    MOV DH, 5
    CALL SET_CURSOR
    MOV AH, 09H
    LEA DX, msgTitle
    INT 21H
    
    ; in ky luc
    MOV DL, 25
    MOV DH, 7
    CALL SET_CURSOR
    MOV AH, 09H
    LEA DX, msgHighScoreStr
    INT 21H
    MOV AX, highScore
    CALL PRINT_NUMBER
    
    ; in menu (1, 2, 3, 4)
    MOV DL, 25
    MOV DH, 9
    CALL SET_CURSOR
    MOV AH, 09H
    LEA DX, msgDiff1
    INT 21H
    
    MOV DL, 25
    MOV DH, 10
    CALL SET_CURSOR
    MOV AH, 09H
    LEA DX, msgDiff2
    INT 21H
    
    MOV DL, 25
    MOV DH, 11
    CALL SET_CURSOR
    MOV AH, 09H
    LEA DX, msgDiff3
    INT 21H
    
    MOV DL, 25
    MOV DH, 12
    CALL SET_CURSOR
    MOV AH, 09H
    LEA DX, msgExitOpt
    INT 21H
    
    MOV DL, 25
    MOV DH, 14
    CALL SET_CURSOR
    MOV AH, 09H
    LEA DX, msgPrompt
    INT 21H

INPUT_MENU:
    MOV AH, 00H
    INT 16H
    
    CMP AL, '1'
    JE SET_EASY
    CMP AL, '2'
    JE SET_MED
    CMP AL, '3'
    JE SET_HARD
    CMP AL, '4'
    JE ASK_EXIT
    JMP INPUT_MENU

ASK_EXIT:
    MOV DL, 25
    MOV DH, 16
    CALL SET_CURSOR
    MOV AH, 09H
    LEA DX, msgConfirmExit
    INT 21H
WAIT_ENTER:
    MOV AH, 00H
    INT 16H
    CMP AL, 13      ; phím enter (carriage return)
    JNE NOT_ENTER
    JMP EXIT_DOS
NOT_ENTER:
    JMP MAIN_MENU_LOOP ; nhấn phím khác sẽ quay lại menu

SET_EASY:
    MOV delayCX, 03H
    MOV delayDX, 0D090H
    JMP PREPARE_GAME
SET_MED:
    MOV delayCX, 02H
    MOV delayDX, 49F0H
    JMP PREPARE_GAME
SET_HARD:
    MOV delayCX, 01H
    MOV delayDX, 24F8H
    
PREPARE_GAME:
    CALL CLEAR_SCREEN
    CALL RESET_GAME_VARS
    CALL INIT_GAME
    
GAME_LOOP:
    CMP gameOver, 1
    JNE CONTINUE_GAME
    JMP END_GAME

CONTINUE_GAME:
    CALL READ_INPUT
    CALL UPDATE_SNAKE
    CALL DRAW_FRAME
    
    ; in điểm số khi đang chơi
    MOV DL, offsetX
    MOV DH, offsetY
    SUB DH, 2       ; in điểm cao hơn khung bản đồ 2 dòng
    CALL SET_CURSOR
    MOV AH, 09H
    LEA DX, msgScore
    INT 21H
    MOV AX, score
    CALL PRINT_NUMBER
    
    ; tạo độ trễ
    MOV CX, delayCX
    MOV DX, delayDX
    MOV AH, 86H
    INT 15H
    
    JMP GAME_LOOP

END_GAME:
    CALL UPDATE_HIGH_SCORE
    CALL DRAW_GAME_OVER
    
WAIT_YN:
    MOV AH, 00H
    INT 16H
    OR AL, 20H      ; đổi phím thành chữ thường (ví dụ 'y' -> 'y')
    
    CMP AL, 'y'
    JNE CHECK_N
    JMP PREPARE_GAME ; chơi lại luôn với độ khó đang chọn
    
CHECK_N:
    CMP AL, 'n'
    JNE CONTINUE_WAIT
    JMP MAIN_MENU_LOOP ; không chơi nữa, thoát ra menu
    
CONTINUE_WAIT:
    JMP WAIT_YN

EXIT_DOS:
    CALL CLEAR_SCREEN
    MOV AX, 4C00H
    INT 21H
MAIN ENDP

; đặt lại các biến game khi bắt đầu ván mới
RESET_GAME_VARS PROC
    MOV snakeLen, 3
    MOV dir, 1
    MOV score, 0
    MOV gameOver, 0
    MOV gameWin, 0
    RET
RESET_GAME_VARS ENDP

; cập nhật điểm kỷ lục
UPDATE_HIGH_SCORE PROC
    MOV AX, score
    CMP AX, highScore
    JLE NO_UPDATE_HS
    MOV highScore, AX
NO_UPDATE_HS:
    RET
UPDATE_HIGH_SCORE ENDP

; in số nguyên có trong thanh ghi ax ra màn hình
PRINT_NUMBER PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV CX, 0       ; biến đếm số lượng chữ số
    MOV BX, 10      ; chia cho 10
DIV_LOOP:
    XOR DX, DX      ; xóa dx trước khi chia (vì dx:ax / bx)
    DIV BX          ; kết quả lưu trong ax, số dư lưu trong dx
    PUSH DX         ; cất số dư vào stack
    INC CX
    CMP AX, 0       ; nếu ax chưa về 0 thì chia tiếp
    JNE DIV_LOOP
    
PRINT_LOOP:
    POP DX          ; lấy từng chữ số từ stack (lifo: ra đúng thứ tự)
    ADD DL, '0'     ; đổi sang ký tự ascii
    MOV AH, 02H
    INT 21H
    LOOP PRINT_LOOP
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_NUMBER ENDP

; khởi tạo thông số game ban đầu
INIT_GAME PROC
    ; vẽ viền bản đồ
    CALL DRAW_BORDER
    
    ; tọa độ ban đầu của rắn (nằm giữa)
    MOV snakeX[0], 8
    MOV snakeY[0], 8
    MOV snakeX[1], 7
    MOV snakeY[1], 8
    MOV snakeX[2], 6
    MOV snakeY[2], 8
    
    ; tạo mồi đầu tiên
    CALL SPAWN_FOOD
    RET
INIT_GAME ENDP

; xử lý nhập từ bàn phím (w, a, s, d và mũi tên)
READ_INPUT PROC
    MOV AH, 01H     ; kiểm tra xem có phím nào được nhấn không
    INT 16H
    JZ NO_KEY_PRESSED ; nếu không có phím, tiếp tục giữ hướng cũ
    
    MOV AH, 00H     ; đọc phím
    INT 16H
    
    ; chuyển phím chữ thường thành chữ hoa (để dễ so sánh w,a,s,d)
    CMP AL, 'a'
    JB CHECK_KEYS
    CMP AL, 'z'
    JA CHECK_KEYS
    SUB AL, 32

CHECK_KEYS:
    ; al chứa mã ascii, ah chứa mã scan code (cho phím mũi tên)
    
    ; kiểm tra phím lên (w hoặc mũi tên lên)
    CMP AL, 'W'
    JE TRY_UP
    CMP AH, 48H     ; scan code mũi tên lên
    JE TRY_UP
    
    ; kiểm tra phím phải (d hoặc mũi tên phải)
    CMP AL, 'D'
    JE TRY_RIGHT
    CMP AH, 4DH
    JE TRY_RIGHT
    
    ; kiểm tra phím xuống (s hoặc mũi tên xuống)
    CMP AL, 'S'
    JE TRY_DOWN
    CMP AH, 50H
    JE TRY_DOWN
    
    ; kiểm tra phím trái (a hoặc mũi tên trái)
    CMP AL, 'A'
    JE TRY_LEFT
    CMP AH, 4BH
    JE TRY_LEFT
    
    JMP NO_KEY_PRESSED

TRY_UP:
    CMP dir, 2      ; không được đi ngược lại hướng hiện tại
    JE NO_KEY_PRESSED
    MOV dir, 0
    JMP NO_KEY_PRESSED
TRY_RIGHT:
    CMP dir, 3
    JE NO_KEY_PRESSED
    MOV dir, 1
    JMP NO_KEY_PRESSED
TRY_DOWN:
    CMP dir, 0
    JE NO_KEY_PRESSED
    MOV dir, 2
    JMP NO_KEY_PRESSED
TRY_LEFT:
    CMP dir, 1
    JE NO_KEY_PRESSED
    MOV dir, 3

NO_KEY_PRESSED:
    RET
READ_INPUT ENDP

; cập nhật logic rắn (di chuyển, ăn mồi, chết)
UPDATE_SNAKE PROC
    ; 1. xóa đuôi cũ trên màn hình
    MOV BX, snakeLen
    DEC BX
    MOV DL, snakeX[BX]
    ADD DL, offsetX
    MOV DH, snakeY[BX]
    ADD DH, offsetY
    CALL SET_CURSOR
    MOV DL, ' '     ; xóa bằng dấu cách
    MOV AH, 02H
    INT 21H

    ; 2. dịch chuyển mảng tọa độ (từ đuôi lên đầu)
    MOV CX, snakeLen
    DEC CX
SHIFT_LOOP:
    MOV BX, CX
    MOV AL, snakeX[BX-1]
    MOV snakeX[BX], AL
    MOV AL, snakeY[BX-1]
    MOV snakeY[BX], AL
    DEC CX
    JNZ SHIFT_LOOP
    
    ; 3. cập nhật cái đầu mới dựa theo hướng (dir)
    MOV AL, snakeX[1]
    MOV AH, snakeY[1]
    
    CMP dir, 0
    JE MOVE_UP
    CMP dir, 1
    JE MOVE_RIGHT
    CMP dir, 2
    JE MOVE_DOWN
    CMP dir, 3
    JE MOVE_LEFT

MOVE_UP:    DEC AH  ; y - 1
            JMP CHECK_COLLISIONS
MOVE_RIGHT: INC AL  ; x + 1
            JMP CHECK_COLLISIONS
MOVE_DOWN:  INC AH  ; y + 1
            JMP CHECK_COLLISIONS
MOVE_LEFT:  DEC AL  ; x - 1

CHECK_COLLISIONS:
    MOV snakeX[0], AL
    MOV snakeY[0], AH

    ; kiểm tra đụng tường
    CMP AL, 0
    JL SET_GAME_OVER
    CMP AL, mapWidth
    JGE SET_GAME_OVER
    CMP AH, 0
    JL SET_GAME_OVER
    CMP AH, mapHeight
    JGE SET_GAME_OVER

    ; kiểm tra cắn đuôi chính mình
    MOV CX, snakeLen
    DEC CX
    MOV BX, 1
CHECK_SELF_LOOP:
    MOV DL, snakeX[BX]
    MOV DH, snakeY[BX]
    CMP AL, DL
    JNE NEXT_SEGMENT
    CMP AH, DH
    JNE NEXT_SEGMENT
    JMP SET_GAME_OVER  ; trùng tọa độ với thân => chết
NEXT_SEGMENT:
    INC BX
    DEC CX
    JNZ CHECK_SELF_LOOP

    ; kiểm tra ăn mồi
    MOV DL, foodX
    MOV DH, foodY
    CMP AL, DL
    JNE DONE_UPDATE
    CMP AH, DH
    JNE DONE_UPDATE

    ; nếu ăn mồi:
    INC snakeLen       ; tăng chiều dài
    ADD score, 10      ; tăng điểm
    
    CMP snakeLen, 256  ; kiểm tra rắn đầy bản đồ chưa (16x16=256)
    JNE CONTINUE_SPAWN
    
    MOV gameWin, 1     ; đánh dấu chiến thắng
    MOV gameOver, 1    ; kết thúc game
    JMP DONE_UPDATE
    
CONTINUE_SPAWN:
    CALL SPAWN_FOOD    ; tạo mồi mới
    JMP DONE_UPDATE

SET_GAME_OVER:
    MOV gameOver, 1

DONE_UPDATE:
    RET
UPDATE_SNAKE ENDP

; tạo mồi ngẫu nhiên
SPAWN_FOOD PROC
FIND_FOOD_POS:
    ; lấy số ngẫu nhiên từ bộ đếm thời gian hệ thống
    MOV AH, 00H
    INT 1AH         ; dx chứa tick count
    
    ; x ngẫu nhiên (dx mod 16)
    MOV AX, DX
    XOR DX, DX
    MOV CX, 16
    DIV CX
    MOV foodX, DL
    
    ; đọc lại để lấy y ngẫu nhiên
    MOV AH, 00H
    INT 1AH
    
    ; y ngẫu nhiên (dx mod 16)
    MOV AX, DX
    ; làm hoán vị dx một chút để y khác x
    SHR AX, 3
    XOR DX, DX
    MOV CX, 16
    DIV CX
    MOV foodY, DL

    ; kiểm tra xem mồi sinh ra có trùng với thân rắn không
    MOV CX, snakeLen
    MOV BX, 0
CHECK_FOOD_COLLISION:
    MOV AL, foodX
    CMP AL, snakeX[BX]
    JNE NEXT_FOOD_CHECK    ; nếu x khác nhau, tiếp tục kiểm tra đốt tiếp theo
    
    MOV AL, foodY
    CMP AL, snakeY[BX]
    JNE NEXT_FOOD_CHECK    ; nếu y khác nhau, tiếp tục kiểm tra đốt tiếp theo
    
    ; nếu cả x và y đều trùng với 1 đốt trên thân rắn -> tạo lại mồi
    JMP FIND_FOOD_POS
    
NEXT_FOOD_CHECK:
    INC BX
    DEC CX
    JNZ CHECK_FOOD_COLLISION

    RET
SPAWN_FOOD ENDP

; vẽ game ra màn hình
DRAW_FRAME PROC
    ; vẽ mồi (food) kí tự '*'
    MOV DL, foodX
    ADD DL, offsetX
    MOV DH, foodY
    ADD DH, offsetY
    CALL SET_CURSOR
    MOV AH, 02H
    MOV DL, '*'
    INT 21H

    ; vẽ đầu rắn
    MOV BX, 0
    MOV DL, snakeX[BX]
    ADD DL, offsetX
    MOV DH, snakeY[BX]
    ADD DH, offsetY
    CALL SET_CURSOR
    MOV AH, 02H
    MOV DL, 'O'     ; kí tự đầu rắn
    INT 21H
    
    ; vẽ đốt ngay sau đầu thành 'o' (để phân biệt đầu và thân)
    CMP snakeLen, 1
    JBE SKIP_BODY
    MOV BX, 1
    MOV DL, snakeX[BX]
    ADD DL, offsetX
    MOV DH, snakeY[BX]
    ADD DH, offsetY
    CALL SET_CURSOR
    MOV AH, 02H
    MOV DL, 'o'     ; kí tự thân rắn
    INT 21H
SKIP_BODY:
    RET
DRAW_FRAME ENDP

; vẽ khung bản đồ (border)
DRAW_BORDER PROC
    ; vẽ tường trên và dưới
    MOV CX, mapWidth
    ADD CX, 2       ; viền trái + phải
DRAW_HORIZ:
    PUSH CX
    ; tường trên
    MOV DL, offsetX
    DEC DL
    ADD DL, CL
    MOV DH, offsetY
    DEC DH
    CALL SET_CURSOR
    MOV AH, 02H
    MOV DL, '#'
    INT 21H
    ; tường dưới
    MOV DL, offsetX
    DEC DL
    POP CX
    PUSH CX
    ADD DL, CL
    MOV DH, offsetY
    ADD DH, mapHeight
    CALL SET_CURSOR
    MOV AH, 02H
    MOV DL, '#'
    INT 21H
    POP CX
    LOOP DRAW_HORIZ

    ; vẽ tường trái và phải
    MOV CX, mapHeight
DRAW_VERT:
    PUSH CX
    ; tường trái
    MOV DL, offsetX
    DEC DL
    MOV DH, offsetY
    DEC DH
    ADD DH, CL
    CALL SET_CURSOR
    MOV AH, 02H
    MOV DL, '#'
    INT 21H
    ; tường phải
    MOV DL, offsetX
    ADD DL, mapWidth
    MOV DH, offsetY
    DEC DH
    POP CX
    PUSH CX
    ADD DH, CL
    CALL SET_CURSOR
    MOV AH, 02H
    MOV DL, '#'
    INT 21H
    POP CX
    LOOP DRAW_VERT
    RET
DRAW_BORDER ENDP

; tiện ích: xóa màn hình
CLEAR_SCREEN PROC
    MOV AX, 0600H   ; cuộn lên toàn màn hình
    MOV BH, 07H     ; thuộc tính màu (trắng trên nền đen)
    MOV CX, 0000H   ; góc trên trái (0,0)
    MOV DX, 184FH   ; góc dưới phải (24, 79)
    INT 10H
    
    ; đặt cursor về 0,0
    MOV DL, 0
    MOV DH, 0
    CALL SET_CURSOR
    RET
CLEAR_SCREEN ENDP

; tiện ích: đặt con trỏ văn bản
; dl = x (cột), dh = y (hàng)
SET_CURSOR PROC
    MOV AH, 02H
    MOV BH, 0       ; trang màn hình 0
    INT 10H
    RET
SET_CURSOR ENDP

; hiện thông báo kết thúc và hỏi chơi lại
DRAW_GAME_OVER PROC
    CMP gameWin, 1
    JE SHOW_WIN_MSG
    
    ; hiện game over nếu thua
    MOV DL, 22
    MOV DH, 10
    CALL SET_CURSOR
    MOV AH, 09H
    LEA DX, msgGameOver
    INT 21H
    JMP SHOW_ASK_MSG
    
SHOW_WIN_MSG:
    ; hiện thông báo chiến thắng
    MOV DL, 22
    MOV DH, 10
    CALL SET_CURSOR
    MOV AH, 09H
    LEA DX, msgWin
    INT 21H
    
SHOW_ASK_MSG:
    ; hỏi chơi lại
    MOV DL, 22
    MOV DH, 11
    CALL SET_CURSOR
    MOV AH, 09H
    LEA DX, msgPlayAgain
    INT 21H
    RET
DRAW_GAME_OVER ENDP

END MAIN