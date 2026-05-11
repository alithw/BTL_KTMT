.286
.MODEL SMALL
.STACK 256
.DATA
    ; ===== CHUỖI VĂN BẢN (GIAO DIỆN) =====
    menu_title  DB '=== GAME TETRIS (ASSEMBLY) ===', 13, 10
                DB 'Dieu khien: WASD hoac Phim Mui Ten', 13, 10
                DB '>> Phim W hoac MUI TEN LEN de Xoay', 13, 10
                DB '----------------------------------', 13, 10
                DB '1. De (Slow)', 13, 10
                DB '2. Trung Binh (Normal)', 13, 10
                DB '3. Kho (Fast)', 13, 10
                DB '4. Thoat', 13, 10
                DB 13, 10, 'Chon che do (1-4): $'
    
    msg_wait_enter DB 13, 10, 'Ban da chon Thoat. Nhan ENTER de xac nhan... $'
    
    msg_gameover DB 'THUA ROI!', 13, 10
                 DB 'Ban co muon choi lai khong? (Y/N): $'

    msg_score    DB 'DIEM: $'
    msg_combo    DB 'COMBO: $'
    msg_next     DB 'NEXT:$'
    clear_spaces DB '      $'    ; Chuỗi khoảng trắng để xóa số cũ khi in đè

    ; ===== BIẾN TRẠNG THÁI GAME =====
    board       DB 200 DUP(0)   ; Bảng game 10 cột x 20 hàng.
    board_w     EQU 10
    board_h     EQU 20
    
    piece_x     DW 3            ; Tọa độ X
    piece_y     DW 0            ; Tọa độ Y
    piece_id    DW 0            ; Loại khối hiện tại (0-6)
    piece_rot   DW 0            ; Trạng thái xoay (0-3)
    
    next_piece_id DW 0          ; Khối tiếp theo
    combo       DW 0            ; Số Combo hiện tại
    lines_cleared DW 0          ; Số hàng phá trong 1 lượt rơi
    
    test_x      DW 0            ; Biến tạm cho CheckCollision
    test_y      DW 0
    test_rot    DW 0

    speed       DW 0            
    score       DW 0            
    rand_seed   DW 1234h        ; Seed ngẫu nhiên

    ; Dữ liệu 7 khối Tetromino (4 trạng thái xoay) - Dạng bitmask 4x4
    shapes      DW 00F00h, 02222h, 000F0h, 04444h ; 0: I
                DW 08E00h, 06440h, 00E20h, 044C0h ; 1: J
                DW 02E00h, 04460h, 00E80h, 0C440h ; 2: L
                DW 06600h, 06600h, 06600h, 06600h ; 3: O
                DW 06C00h, 04620h, 006C0h, 08C40h ; 4: S
                DW 04E00h, 04640h, 00E40h, 04C40h ; 5: T
                DW 0C600h, 02640h, 00C60h, 04C80h ; 6: Z
                
    ; Bảng màu cho 7 khối
    colors      DB 0Bh, 09h, 0Ch, 0Eh, 0Ah, 0Dh, 04h

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    MOV ES, AX

MenuStart:
    CALL ClearScreen
    
    MOV AH, 09h
    LEA DX, menu_title
    INT 21h

MenuInput:
    MOV AH, 07h
    INT 21h
    
    CMP AL, '1'
    JE SetEasy
    CMP AL, '2'
    JE SetMed
    CMP AL, '3'
    JE SetHard
    CMP AL, '4'
    JE ConfirmExit
    JMP MenuInput

SetEasy:
    MOV speed, 10
    JMP InitGame
SetMed:
    MOV speed, 5
    JMP InitGame
SetHard:
    MOV speed, 2
    JMP InitGame

ConfirmExit:
    CALL ClearScreen
    MOV AH, 09h
    LEA DX, msg_wait_enter
    INT 21h
WaitEnterLoop:
    MOV AH, 07h
    INT 21h
    CMP AL, 13
    JNE WaitEnterLoop
    JMP ExitProg

InitGame:
    CALL ClearScreen

    ; Khởi tạo ngẫu nhiên từ đồng hồ hệ thống
    MOV AH, 00h
    INT 1Ah
    MOV rand_seed, DX

    ; Xóa mảng board
    LEA DI, board
    MOV CX, 200
    MOV AL, 0
    REP STOSB
    
    MOV score, 0
    MOV combo, 0
    
    ; Sinh trước khối NEXT đầu tiên
    MOV AX, rand_seed
    MOV CX, 25173
    MUL CX
    ADD AX, 13849
    MOV rand_seed, AX
    MOV DX, 0
    MOV CX, 7
    DIV CX
    MOV next_piece_id, DX

    CALL SpawnPiece

GameLoop:
    CALL DrawGame
    
    MOV CX, speed
DelayWait:
    PUSH CX
    MOV AH, 00h
    INT 1Ah
    MOV BX, DX
WaitTick:
    MOV AH, 00h
    INT 1Ah
    CMP DX, BX
    JE WaitTick
    
    CALL CheckInput
    POP CX
    LOOP DelayWait
    
    ; Logic rơi xuống
    MOV AX, piece_x
    MOV test_x, AX
    MOV AX, piece_y
    INC AX
    MOV test_y, AX
    MOV AX, piece_rot
    MOV test_rot, AX
    
    CALL CheckCollision
    CMP AX, 1
    JNE ApplyDrop
    
    ; Nếu chạm -> Khóa khối, xóa hàng, sinh khối mới
    CALL LockPiece
    CALL ClearLines
    CALL SpawnPiece
    
    ; Kiểm tra Game Over
    MOV AX, piece_x
    MOV test_x, AX
    MOV AX, piece_y
    MOV test_y, AX
    MOV AX, piece_rot
    MOV test_rot, AX
    CALL CheckCollision
    CMP AX, 1
    JE GameOver
    JMP ContinueGameLoop

ApplyDrop:
    INC piece_y
ContinueGameLoop:
    JMP GameLoop

GameOver:
    CALL DrawGame
    
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 22
    MOV DL, 0
    INT 10h
    
    MOV AH, 09h
    LEA DX, msg_gameover
    INT 21h

AskReplay:
    MOV AH, 07h
    INT 21h
    AND AL, 11011111b
    CMP AL, 'Y'
    JNE CheckN
    JMP InitGame
CheckN:
    CMP AL, 'N'
    JNE AskReplay
    JMP MenuStart

ExitProg:
    CALL ClearScreen
    MOV AH, 4Ch
    INT 21h
MAIN ENDP

; ===== XỬ LÝ NHẬP PHÍM =====
CheckInput PROC
    MOV AH, 01h
    INT 16h
    JZ NoInput
    
    MOV AH, 00h
    INT 16h
    
    ; Dùng Trampoline Jumps
    CMP AH, 4Bh         ; TRÁI
    JE JmpMoveLeft
    CMP AH, 4Dh         ; PHẢI
    JE JmpMoveRight
    CMP AH, 50h         ; XUỐNG
    JE JmpMoveDownFast
    CMP AH, 48h         ; LÊN (XOAY)
    JE JmpMoveRotate
    
    AND AL, 11011111b
    CMP AL, 'A'
    JE JmpMoveLeft
    CMP AL, 'D'
    JE JmpMoveRight
    CMP AL, 'S'
    JE JmpMoveDownFast
    CMP AL, 'W'         ; W (XOAY)
    JE JmpMoveRotate
    
NoInput:
    RET

JmpMoveLeft:
    JMP MoveLeft
JmpMoveRight:
    JMP MoveRight
JmpMoveDownFast:
    JMP MoveDownFast
JmpMoveRotate:
    JMP MoveRotate

MoveRotate:
    MOV AX, piece_x
    MOV test_x, AX
    MOV AX, piece_y
    MOV test_y, AX
    
    MOV AX, piece_rot
    INC AX
    CMP AX, 4
    JL RotNoWrap
    MOV AX, 0
RotNoWrap:
    MOV test_rot, AX
    
    CALL CheckCollision
    CMP AX, 1
    JE RetRotate
    
    MOV AX, test_rot
    MOV piece_rot, AX
    CALL DrawGame
RetRotate:
    RET

MoveLeft:
    MOV AX, piece_x
    DEC AX
    MOV test_x, AX
    MOV AX, piece_y
    MOV test_y, AX
    MOV AX, piece_rot
    MOV test_rot, AX
    
    CALL CheckCollision
    CMP AX, 1
    JE RetLeft
    DEC piece_x
    CALL DrawGame
RetLeft:
    RET
    
MoveRight:
    MOV AX, piece_x
    INC AX
    MOV test_x, AX
    MOV AX, piece_y
    MOV test_y, AX
    MOV AX, piece_rot
    MOV test_rot, AX
    
    CALL CheckCollision
    CMP AX, 1
    JE RetRight
    INC piece_x
    CALL DrawGame
RetRight:
    RET

MoveDownFast:
    MOV AX, piece_x
    MOV test_x, AX
    MOV AX, piece_y
    INC AX
    MOV test_y, AX
    MOV AX, piece_rot
    MOV test_rot, AX
    
    CALL CheckCollision
    CMP AX, 1
    JE RetDown
    INC piece_y
    CALL DrawGame
RetDown:
    RET

CheckInput ENDP

; ===== KIỂM TRA VA CHẠM (MA TRẬN 4x4) =====
CheckCollision PROC
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    MOV AX, piece_id
    SHL AX, 2
    ADD AX, test_rot
    SHL AX, 1
    MOV SI, AX
    MOV DX, shapes[SI]

    MOV BX, 0
ColLoopY:
    MOV CX, 0
ColLoopX:
    SHL DX, 1
    JNC ColNextX

    MOV AX, test_x
    ADD AX, CX
    
    CMP AX, 0
    JL IsCollided_Pop0
    CMP AX, board_w
    JGE IsCollided_Pop0
    JMP BoundsX_OK
IsCollided_Pop0:
    JMP IsCollided

BoundsX_OK:
    PUSH AX
    MOV AX, test_y
    ADD AX, BX
    
    CMP AX, board_h
    JGE IsCollided_Pop1
    CMP AX, 0
    JL ColNextX_Pop1
    JMP BoundsY_OK
    
IsCollided_Pop1:
    POP AX
    JMP IsCollided
ColNextX_Pop1:
    POP AX
    JMP ColNextX
    
BoundsY_OK:
    MOV SI, AX
    POP AX
    PUSH AX
    PUSH DX
    
    MOV DX, SI
    MOV SI, 10
    PUSH AX
    MOV AX, DX
    MUL SI
    MOV SI, AX
    POP AX
    
    ADD SI, AX
    POP DX
    
    CMP board[SI], 0
    JNE IsCollided_Pop1
    
ColNextX_PopActualX:
    POP AX
ColNextX:
    INC CX
    CMP CX, 4
    JGE CheckColY
    JMP ColLoopX
CheckColY:
    INC BX
    CMP BX, 4
    JGE EndColSafe
    JMP ColLoopY

EndColSafe:
    MOV AX, 0
    JMP EndCol

IsCollided:
    MOV AX, 1
EndCol:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    RET
CheckCollision ENDP

; ===== GẮN KHỐI VÀO BẢNG =====
LockPiece PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    MOV AX, piece_id
    SHL AX, 2
    ADD AX, piece_rot
    SHL AX, 1
    MOV SI, AX
    MOV DX, shapes[SI]

    MOV BX, 0
LockLoopY:
    MOV CX, 0
LockLoopX:
    SHL DX, 1
    JNC LockNextX

    MOV AX, piece_x
    ADD AX, CX
    
    PUSH AX
    MOV AX, piece_y
    ADD AX, BX
    
    CMP AX, 0
    JL LockNextX_Pop1
    JMP BoundsY_OK_Lock
    
LockNextX_Pop1:
    POP AX
    JMP LockNextX
    
BoundsY_OK_Lock:
    MOV SI, AX
    POP AX
    PUSH AX
    PUSH DX
    
    MOV DX, SI
    MOV SI, 10
    PUSH AX
    MOV AX, DX
    MUL SI
    MOV SI, AX
    POP AX
    
    ADD SI, AX
    POP DX
    
    ; Gắn ID màu
    MOV AX, piece_id
    INC AX
    MOV board[SI], AL
    
LockNextX_PopActualX:
    POP AX
LockNextX:
    INC CX
    CMP CX, 4
    JGE CheckLockY
    JMP LockLoopX
CheckLockY:
    INC BX
    CMP BX, 4
    JGE EndLock
    JMP LockLoopY

EndLock:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
LockPiece ENDP

; ===== KHỞI TẠO KHỐI MỚI =====
SpawnPiece PROC
    ; Đưa next block vào block chính
    MOV AX, next_piece_id
    MOV piece_id, AX
    
    ; Sinh số ngẫu nhiên cho next block mới
    MOV AX, rand_seed
    MOV CX, 25173
    MUL CX
    ADD AX, 13849
    MOV rand_seed, AX
    
    MOV DX, 0
    MOV CX, 7
    DIV CX
    MOV next_piece_id, DX
    
    MOV piece_x, 3
    MOV piece_y, 0
    MOV piece_rot, 0
    RET
SpawnPiece ENDP

; ===== XÓA HÀNG VÀ TÍNH ĐIỂM =====
ClearLines PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    MOV lines_cleared, 0

    MOV CX, board_h
    MOV BX, 19
CheckLineLoop:
    PUSH CX
    MOV CX, board_w
    MOV AX, BX
    MOV SI, 10
    MUL SI
    MOV SI, AX
    
    MOV DX, 1
CheckCellLoop:
    CMP board[SI], 0
    JNE CellNotEmpty
    MOV DX, 0
CellNotEmpty:
    INC SI
    LOOP CheckCellLoop
    
    CMP DX, 1
    JNE NextLine
    
    ; Tăng biến đếm số hàng đã phá
    INC lines_cleared
    
    MOV CX, BX
ShiftLoopY:
    PUSH CX
    MOV AX, CX
    DEC AX
    MOV SI, 10
    MUL SI
    MOV SI, AX
    
    MOV DI, SI
    ADD DI, 10
    
    MOV CX, 10
ShiftLoopX:
    MOV AL, board[SI]
    MOV board[DI], AL
    INC SI
    INC DI
    LOOP ShiftLoopX
    
    POP CX
    LOOP ShiftLoopY
    
    MOV CX, 10
    MOV DI, 0
    MOV AL, 0
ClearTop:
    MOV board[DI], AL
    INC DI
    LOOP ClearTop
    
    INC BX
    POP CX
    INC CX
    JMP ResumeLineLoop
    
NextLine:
    POP CX
ResumeLineLoop:
    DEC BX
    DEC CX
    
    CMP CX, 0
    JLE FinishClear
    JMP CheckLineLoop
    
FinishClear:
    ; === TÍNH TOÁN ĐIỂM SỐ COMBO ===
    CMP lines_cleared, 0
    JNE CalcScore
    ; Không phá được hàng nào -> Reset Combo
    MOV combo, 0
    JMP EndClearLines

CalcScore:
    MOV AX, lines_cleared
    CMP AX, 1
    JE Score1
    CMP AX, 2
    JE Score2
    CMP AX, 3
    JE Score3
    ; Xóa 4 hàng (TETRIS)
    MOV DX, 100
    JMP ApplyCombo
Score1: 
    MOV DX, 10
    JMP ApplyCombo
Score2: 
    MOV DX, 30
    JMP ApplyCombo
Score3: 
    MOV DX, 50
    JMP ApplyCombo

ApplyCombo:
    MOV AX, combo
    INC AX              ; Cấp số nhân = Combo + 1
    MOV CX, DX          ; CX chứa điểm cơ sở
    MUL CX              ; AX = AX * CX
    ADD score, AX
    
    INC combo           ; Tăng chuỗi phá liên tiếp
    JMP EndClearLines

EndClearLines:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
ClearLines ENDP

; ===== XÓA MÀN HÌNH =====
ClearScreen PROC
    MOV AX, 0003h
    INT 10h
    
    MOV AH, 01h
    MOV CX, 2607h
    INT 10h
    RET
ClearScreen ENDP

; ===== IN SỐ NGUYÊN =====
PrintNumber PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV CX, 0
    MOV BX, 10
DivLoop:
    MOV DX, 0
    DIV BX
    PUSH DX
    INC CX
    CMP AX, 0
    JNE DivLoop
    
PrintLoopOut:
    POP DX
    ADD DL, '0'
    MOV AH, 02h
    INT 21h
    LOOP PrintLoopOut
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PrintNumber ENDP

; ===== VẼ GIAO DIỆN GAME =====
DrawGame PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH ES
    PUSH SI
    PUSH DI

    MOV AX, 0B800h
    MOV ES, AX

    MOV BX, 0
DrawY:
    MOV CX, 0
DrawX:
    MOV AX, BX
    INC AX
    MOV SI, 160
    MUL SI
    MOV DI, AX
    
    MOV AX, CX
    ADD AX, 30
    SHL AX, 1
    ADD DI, AX
    
    CMP BX, board_h
    JE DrawWallBottom
    CMP CX, 0
    JE DrawWall
    CMP CX, 11
    JE DrawWall
    
    MOV AX, BX
    MOV SI, 10
    MUL SI
    ADD AX, CX
    DEC AX
    MOV SI, AX
    
    CMP board[SI], 0
    JE DrawEmpty
    
    MOV AL, board[SI]
    DEC AL
    MOV AH, 0
    PUSH SI
    MOV SI, AX
    MOV AH, colors[SI]
    POP SI
    MOV AL, 0DBh
    MOV ES:[DI], AX
    JMP NextX
    
DrawEmpty:
    MOV AL, '.'
    MOV AH, 08h
    MOV ES:[DI], AX
    JMP NextX

DrawWall:
    MOV AL, '|'
    MOV AH, 0Fh
    MOV ES:[DI], AX
    JMP NextX
    
DrawWallBottom:
    MOV AL, '='
    MOV AH, 0Fh
    MOV ES:[DI], AX
    JMP NextX
    
NextX:
    INC CX
    CMP CX, 11
    JG CheckNextY
    JMP DrawX
CheckNextY:
    INC BX
    CMP BX, board_h
    JG EndDrawBoard
    JMP DrawY

EndDrawBoard:
    ; ==== VẼ KHỐI GẠCH ĐANG RƠI ====
    MOV AX, piece_id
    SHL AX, 2
    ADD AX, piece_rot
    SHL AX, 1
    MOV SI, AX
    MOV DX, shapes[SI]
    
    MOV SI, piece_id
    MOV AH, colors[SI]
    PUSH AX

    MOV BX, 0
DrawPieceY:
    MOV CX, 0
DrawPieceX:
    SHL DX, 1
    JNC DrawNextXP

    MOV AX, piece_y
    ADD AX, BX
    
    CMP AX, 0
    JL DrawNextXP
    
    INC AX
    PUSH DX
    MOV SI, 160
    MUL SI
    MOV DI, AX
    POP DX
    
    MOV AX, piece_x
    ADD AX, CX
    
    ADD AX, 31
    SHL AX, 1
    ADD DI, AX
    
    POP AX
    PUSH AX
    MOV AL, 0DBh
    MOV ES:[DI], AX
    
DrawNextXP:
    INC CX
    CMP CX, 4
    JGE CheckPieceY
    JMP DrawPieceX
CheckPieceY:
    INC BX
    CMP BX, 4
    JGE EndDrawPiece
    JMP DrawPieceY

EndDrawPiece:
    POP AX

    ; ==== IN ĐIỂM SỐ ====
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 5
    MOV DL, 46
    INT 10h
    MOV AH, 09h
    LEA DX, msg_score
    INT 21h
    
    ; Đè bằng khoảng trắng để tránh số cũ còn dính
    MOV AH, 09h
    LEA DX, clear_spaces
    INT 21h
    
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 5
    MOV DL, 52
    INT 10h
    MOV AX, score
    CALL PrintNumber

    ; ==== IN COMBO ====
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 6
    MOV DL, 46
    INT 10h
    MOV AH, 09h
    LEA DX, msg_combo
    INT 21h
    
    MOV AH, 09h
    LEA DX, clear_spaces
    INT 21h
    
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 6
    MOV DL, 53
    INT 10h
    MOV AX, combo
    CALL PrintNumber

    ; ==== VẼ CHỮ "NEXT:" ====
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 8
    MOV DL, 46
    INT 10h
    MOV AH, 09h
    LEA DX, msg_next
    INT 21h
    
    ; Xóa vùng 4x4 để vẽ khối Next Piece
    MOV BX, 0
ClearNextYLoop:
    MOV CX, 0
ClearNextXLoop:
    MOV AX, 10          ; Hàng Y = 10
    ADD AX, BX
    MOV SI, 160
    MUL SI
    MOV DI, AX
    
    MOV AX, CX
    ADD AX, 46          ; Cột X = 46
    SHL AX, 1
    ADD DI, AX
    
    MOV AX, 0720h       ; Dấu cách (xóa màu cũ đi)
    MOV ES:[DI], AX
    
    INC CX
    CMP CX, 4
    JL ClearNextXLoop
    INC BX
    CMP BX, 4
    JL ClearNextYLoop

    ; Vẽ Khối Next Piece
    MOV AX, next_piece_id
    SHL AX, 2
    SHL AX, 1           ; Rot luôn = 0
    MOV SI, AX
    MOV DX, shapes[SI]
    
    MOV SI, next_piece_id
    MOV AH, colors[SI]
    PUSH AX

    MOV BX, 0
DrawNextBlockY:
    MOV CX, 0
DrawNextBlockX:
    SHL DX, 1
    JNC SkipDrawNextBlock
    
    MOV AX, 10
    ADD AX, BX
    
    ; --- [ĐÃ SỬA Ở ĐÂY] Bọc PUSH DX và POP DX để bảo toàn bitmask khối ---
    PUSH DX             
    MOV SI, 160
    MUL SI
    MOV DI, AX
    POP DX              
    ; ---------------------------------------------------------------------
    
    MOV AX, CX
    ADD AX, 46
    SHL AX, 1
    ADD DI, AX
    
    POP AX
    PUSH AX
    MOV AL, 0DBh
    MOV ES:[DI], AX

SkipDrawNextBlock:
    INC CX
    CMP CX, 4
    JGE NextCheckY2
    JMP DrawNextBlockX
NextCheckY2:
    INC BX
    CMP BX, 4
    JGE EndDrawNextFinal
    JMP DrawNextBlockY

EndDrawNextFinal:
    POP AX

    POP DI
    POP SI
    POP ES
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DrawGame ENDP

END MAIN