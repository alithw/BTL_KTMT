.MODEL SMALL
.STACK 100H

.DATA
    ; --- Các chuỗi văn bản (Tiếng Việt không dấu) ---
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
    msgPlayAgain    DB 'Ban co muon choi lai khong (Y/N)? ', '$'
    
    ; --- Cấu hình Game ---
    mapWidth    EQU 16
    mapHeight   EQU 16
    offsetX     DB 32   ; Độ dời X để in bản đồ ra giữa màn hình
    offsetY     DB 4    ; Độ dời Y để in bản đồ ra giữa màn hình
    
    ; --- Trạng thái Rắn ---
    snakeX      DB 256 DUP(0) ; Mảng lưu tọa độ X (Tối đa 16x16 = 256)
    snakeY      DB 256 DUP(0) ; Mảng lưu tọa độ Y
    snakeLen    DW 3          ; Chiều dài ban đầu
    dir         DB 1          ; Hướng: 0=Lên, 1=Phải, 2=Xuống, 3=Trái
    
    ; --- Biến Game ---
    foodX       DB 0
    foodY       DB 0
    score       DW 0
    highScore   DW 0
    gameOver    DB 0
    
    ; --- Biến Delay (Microseconds) cho Interrupt 15h AH=86h ---
    delayCX     DW 0
    delayDX     DW 0

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

MAIN_MENU_LOOP:
    CALL CLEAR_SCREEN
    
    ; In Title
    MOV DL, 25
    MOV DH, 5
    CALL SET_CURSOR
    MOV AH, 09H
    LEA DX, msgTitle
    INT 21H
    
    ; In Ky luc
    MOV DL, 25
    MOV DH, 7
    CALL SET_CURSOR
    MOV AH, 09H
    LEA DX, msgHighScoreStr
    INT 21H
    MOV AX, highScore
    CALL PRINT_NUMBER
    
    ; In Menu (1, 2, 3, 4)
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
    CMP AL, 13      ; Phím Enter (Carriage Return)
    JNE NOT_ENTER
    JMP EXIT_DOS
NOT_ENTER:
    JMP MAIN_MENU_LOOP ; Nhấn phím khác sẽ quay lại Menu

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
    JE END_GAME

    CALL READ_INPUT
    CALL UPDATE_SNAKE
    CALL DRAW_FRAME
    
    ; In Điểm số khi đang chơi
    MOV DL, offsetX
    MOV DH, offsetY
    SUB DH, 2       ; In điểm cao hơn khung bản đồ 2 dòng
    CALL SET_CURSOR
    MOV AH, 09H
    LEA DX, msgScore
    INT 21H
    MOV AX, score
    CALL PRINT_NUMBER
    
    ; Tạo độ trễ
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
    OR AL, 20H      ; Đổi phím thành chữ thường (ví dụ 'Y' -> 'y')
    
    CMP AL, 'y'
    JNE CHECK_N
    JMP PREPARE_GAME ; Chơi lại luôn với độ khó đang chọn
    
CHECK_N:
    CMP AL, 'n'
    JNE CONTINUE_WAIT
    JMP MAIN_MENU_LOOP ; Không chơi nữa, thoạt ra Menu
    
CONTINUE_WAIT:
    JMP WAIT_YN

EXIT_DOS:
    CALL CLEAR_SCREEN
    MOV AX, 4C00H
    INT 21H
MAIN ENDP

; --------------------------------------------------------
; Đặt lại các biến game khi bắt đầu ván mới
; --------------------------------------------------------
RESET_GAME_VARS PROC
    MOV snakeLen, 3
    MOV dir, 1
    MOV score, 0
    MOV gameOver, 0
    RET
RESET_GAME_VARS ENDP

; --------------------------------------------------------
; Cập nhật điểm Kỷ lục
; --------------------------------------------------------
UPDATE_HIGH_SCORE PROC
    MOV AX, score
    CMP AX, highScore
    JLE NO_UPDATE_HS
    MOV highScore, AX
NO_UPDATE_HS:
    RET
UPDATE_HIGH_SCORE ENDP

; --------------------------------------------------------
; In số nguyên có trong thanh ghi AX ra màn hình
; --------------------------------------------------------
PRINT_NUMBER PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV CX, 0       ; Biến đếm số lượng chữ số
    MOV BX, 10      ; Chia cho 10
DIV_LOOP:
    XOR DX, DX      ; Xóa DX trước khi chia (vì DX:AX / BX)
    DIV BX          ; Kết quả lưu trong AX, số dư lưu trong DX
    PUSH DX         ; Cất số dư vào Stack
    INC CX
    CMP AX, 0       ; Nếu AX chưa về 0 thì chia tiếp
    JNE DIV_LOOP
    
PRINT_LOOP:
    POP DX          ; Lấy từng chữ số từ Stack (LIFO: ra đúng thứ tự)
    ADD DL, '0'     ; Đổi sang ký tự ASCII
    MOV AH, 02H
    INT 21H
    LOOP PRINT_LOOP
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_NUMBER ENDP

; --------------------------------------------------------
; Khởi tạo thông số game ban đầu
; --------------------------------------------------------
INIT_GAME PROC
    ; Vẽ viền bản đồ
    CALL DRAW_BORDER
    
    ; Tọa độ ban đầu của Rắn (Nằm giữa)
    MOV snakeX[0], 8
    MOV snakeY[0], 8
    MOV snakeX[1], 7
    MOV snakeY[1], 8
    MOV snakeX[2], 6
    MOV snakeY[2], 8
    
    ; Tạo mồi đầu tiên
    CALL SPAWN_FOOD
    RET
INIT_GAME ENDP

; --------------------------------------------------------
; Xử lý Nhập từ Bàn phím (W, A, S, D và Mũi tên)
; --------------------------------------------------------
READ_INPUT PROC
    MOV AH, 01H     ; Kiểm tra xem có phím nào được nhấn không
    INT 16H
    JZ NO_KEY_PRESSED ; Nếu không có phím, tiếp tục giữ hướng cũ
    
    MOV AH, 00H     ; Đọc phím
    INT 16H
    
    ; Chuyển phím chữ thường thành chữ hoa (để dễ so sánh W,A,S,D)
    CMP AL, 'a'
    JB CHECK_KEYS
    CMP AL, 'z'
    JA CHECK_KEYS
    SUB AL, 32

CHECK_KEYS:
    ; AL chứa mã ASCII, AH chứa mã Scan Code (cho phím mũi tên)
    
    ; Kiểm tra phím Lên (W hoặc Mũi tên lên)
    CMP AL, 'W'
    JE TRY_UP
    CMP AH, 48H     ; Scan code mũi tên Lên
    JE TRY_UP
    
    ; Kiểm tra phím Phải (D hoặc Mũi tên phải)
    CMP AL, 'D'
    JE TRY_RIGHT
    CMP AH, 4DH
    JE TRY_RIGHT
    
    ; Kiểm tra phím Xuống (S hoặc Mũi tên xuống)
    CMP AL, 'S'
    JE TRY_DOWN
    CMP AH, 50H
    JE TRY_DOWN
    
    ; Kiểm tra phím Trái (A hoặc Mũi tên trái)
    CMP AL, 'A'
    JE TRY_LEFT
    CMP AH, 4BH
    JE TRY_LEFT
    
    JMP NO_KEY_PRESSED

TRY_UP:
    CMP dir, 2      ; Không được đi ngược lại hướng hiện tại
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

; --------------------------------------------------------
; Cập nhật logic Rắn (Di chuyển, ăn mồi, chết)
; --------------------------------------------------------
UPDATE_SNAKE PROC
    ; 1. Xóa đuôi cũ trên màn hình
    MOV BX, snakeLen
    DEC BX
    MOV DL, snakeX[BX]
    ADD DL, offsetX
    MOV DH, snakeY[BX]
    ADD DH, offsetY
    CALL SET_CURSOR
    MOV DL, ' '     ; Xóa bằng dấu cách
    MOV AH, 02H
    INT 21H

    ; 2. Dịch chuyển mảng tọa độ (từ đuôi lên đầu)
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
    
    ; 3. Cập nhật cái Đầu mới dựa theo Hướng (dir)
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

MOVE_UP:    DEC AH  ; Y - 1
            JMP CHECK_COLLISIONS
MOVE_RIGHT: INC AL  ; X + 1
            JMP CHECK_COLLISIONS
MOVE_DOWN:  INC AH  ; Y + 1
            JMP CHECK_COLLISIONS
MOVE_LEFT:  DEC AL  ; X - 1

CHECK_COLLISIONS:
    MOV snakeX[0], AL
    MOV snakeY[0], AH

    ; Kiểm tra đụng tường
    CMP AL, 0
    JL SET_GAME_OVER
    CMP AL, mapWidth
    JGE SET_GAME_OVER
    CMP AH, 0
    JL SET_GAME_OVER
    CMP AH, mapHeight
    JGE SET_GAME_OVER

    ; Kiểm tra cắn đuôi chính mình
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
    JMP SET_GAME_OVER  ; Trùng tọa độ với thân => Chết
NEXT_SEGMENT:
    INC BX
    DEC CX
    JNZ CHECK_SELF_LOOP

    ; Kiểm tra ăn mồi
    MOV DL, foodX
    MOV DH, foodY
    CMP AL, DL
    JNE DONE_UPDATE
    CMP AH, DH
    JNE DONE_UPDATE

    ; Nếu ăn mồi:
    INC snakeLen       ; Tăng chiều dài
    ADD score, 10      ; Tăng điểm
    CALL SPAWN_FOOD    ; Tạo mồi mới
    JMP DONE_UPDATE

SET_GAME_OVER:
    MOV gameOver, 1

DONE_UPDATE:
    RET
UPDATE_SNAKE ENDP

; --------------------------------------------------------
; Tạo Mồi Ngẫu Nhiên
; --------------------------------------------------------
SPAWN_FOOD PROC
FIND_FOOD_POS:
    ; Lấy số ngẫu nhiên từ bộ đếm thời gian hệ thống
    MOV AH, 00H
    INT 1AH         ; DX chứa tick count
    
    ; X ngẫu nhiên (DX mod 16)
    MOV AX, DX
    XOR DX, DX
    MOV CX, 16
    DIV CX
    MOV foodX, DL
    
    ; Đọc lại để lấy Y ngẫu nhiên
    MOV AH, 00H
    INT 1AH
    
    ; Y ngẫu nhiên (DX mod 16)
    MOV AX, DX
    ; Làm hoán vị DX một chút để Y khác X
    SHR AX, 3
    XOR DX, DX
    MOV CX, 16
    DIV CX
    MOV foodY, DL

    RET
SPAWN_FOOD ENDP

; --------------------------------------------------------
; Vẽ Game ra màn hình
; --------------------------------------------------------
DRAW_FRAME PROC
    ; Vẽ Mồi (Food) kí tự '*'
    MOV DL, foodX
    ADD DL, offsetX
    MOV DH, foodY
    ADD DH, offsetY
    CALL SET_CURSOR
    MOV AH, 02H
    MOV DL, '*'
    INT 21H

    ; Vẽ Đầu rắn
    MOV BX, 0
    MOV DL, snakeX[BX]
    ADD DL, offsetX
    MOV DH, snakeY[BX]
    ADD DH, offsetY
    CALL SET_CURSOR
    MOV AH, 02H
    MOV DL, 'O'     ; Kí tự Đầu Rắn
    INT 21H
    
    ; Vẽ đốt ngay sau đầu thành 'o' (Để phân biệt đầu và thân)
    CMP snakeLen, 1
    JBE SKIP_BODY
    MOV BX, 1
    MOV DL, snakeX[BX]
    ADD DL, offsetX
    MOV DH, snakeY[BX]
    ADD DH, offsetY
    CALL SET_CURSOR
    MOV AH, 02H
    MOV DL, 'o'     ; Kí tự Thân rắn
    INT 21H
SKIP_BODY:
    RET
DRAW_FRAME ENDP

; --------------------------------------------------------
; Vẽ Khung bản đồ (Border)
; --------------------------------------------------------
DRAW_BORDER PROC
    ; Vẽ tường trên và dưới
    MOV CX, mapWidth
    ADD CX, 2       ; Viền trái + phải
DRAW_HORIZ:
    PUSH CX
    ; Tường trên
    MOV DL, offsetX
    DEC DL
    ADD DL, CL
    MOV DH, offsetY
    DEC DH
    CALL SET_CURSOR
    MOV AH, 02H
    MOV DL, '#'
    INT 21H
    ; Tường dưới
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

    ; Vẽ tường trái và phải
    MOV CX, mapHeight
DRAW_VERT:
    PUSH CX
    ; Tường trái
    MOV DL, offsetX
    DEC DL
    MOV DH, offsetY
    DEC DH
    ADD DH, CL
    CALL SET_CURSOR
    MOV AH, 02H
    MOV DL, '#'
    INT 21H
    ; Tường phải
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

; --------------------------------------------------------
; Tiện ích: Xóa màn hình
; --------------------------------------------------------
CLEAR_SCREEN PROC
    MOV AX, 0600H   ; Cuộn lên toàn màn hình
    MOV BH, 07H     ; Thuộc tính màu (Trắng trên nền đen)
    MOV CX, 0000H   ; Góc trên trái (0,0)
    MOV DX, 184FH   ; Góc dưới phải (24, 79)
    INT 10H
    
    ; Đặt cursor về 0,0
    MOV DL, 0
    MOV DH, 0
    CALL SET_CURSOR
    RET
CLEAR_SCREEN ENDP

; --------------------------------------------------------
; Tiện ích: Đặt con trỏ văn bản
; DL = X (Cột), DH = Y (Hàng)
; --------------------------------------------------------
SET_CURSOR PROC
    MOV AH, 02H
    MOV BH, 0       ; Trang màn hình 0
    INT 10H
    RET
SET_CURSOR ENDP

; --------------------------------------------------------
; Hiện thông báo Game Over và Hỏi chơi lại
; --------------------------------------------------------
DRAW_GAME_OVER PROC
    MOV DL, 22
    MOV DH, 10
    CALL SET_CURSOR
    MOV AH, 09H
    LEA DX, msgGameOver
    INT 21H
    
    MOV DL, 22
    MOV DH, 11
    CALL SET_CURSOR
    MOV AH, 09H
    LEA DX, msgPlayAgain
    INT 21H
    RET
DRAW_GAME_OVER ENDP

END MAIN