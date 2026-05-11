# Bài tập lớn - KTMT N08 - Nhóm 13 

## Mô tả dự án

`snake.asm` là một trò chơi Rắn săn mồi (Snake Game) viết bằng Assembly cho kiến trúc x86, chạy trên DOS. Trò chơi sử dụng ngắt BIOS/DOS cơ bản để điều khiển con trỏ, in ký tự màn hình, đọc phím, và tạo độ trễ.

## Tính năng

- Chọn độ khó: `Easy`, `Medium`, `Hard`
- Di chuyển bằng `W`, `A`, `S`, `D` hoặc các phím mũi tên
- Ăn mồi ngẫu nhiên trên bản đồ
- Tăng chiều dài rắn và điểm khi ăn mồi
- Dừng game khi rắn va vào tường hoặc tự cắn vào mình
- Cảnh báo `GAME OVER` và hỏi có chơi lại không
- Lưu điểm kỷ lục trong phiên hiện tại của chương trình

## Yêu cầu

- Trình biên dịch/assembler TASM hoặc MASM tương thích x86
- Môi trường DOS hoặc DOSBox để chạy chương trình
- Kích thước màn hình giả định: 80x25 ký tự

## Chạy chương trình

1. Mở DOSBox hoặc môi trường DOS tương thích.
2. Mount thư mục chứa `snake.asm` là ổ đĩa ảo, ví dụ:

   `mount c c:\Code\PTIT\BTL_KTMT`

3. Vào ổ `C:` và biên dịch nếu cần.

4. Nếu dùng TASM/TLINK:

   `tasm snake.asm`
   `tlink snake.obj`

5. Chạy chương trình:

   `snake.exe`

## Cách chơi

- Chọn `1`, `2`, `3` hoặc `4` để chọn chế độ chơi hoặc thoát.
- Trong game, dùng:
  - `W` hoặc `↑` để đi lên
  - `D` hoặc `→` để đi phải
  - `S` hoặc `↓` để đi xuống
  - `A` hoặc `←` để đi trái
- Rắn di chuyển liên tục, chỉ thay đổi hướng khi người chơi nhấn phím.
- Ăn `*` để nhận điểm và tăng chiều dài.
- Game kết thúc khi rắn chạm tường hoặc cắn chính mình.
- Sau khi `GAME OVER`, nhấn `Y` để chơi lại hoặc `N` để về menu chính.

## Cấu trúc mã nguồn

- `.MODEL SMALL` và `.STACK 100H` để định nghĩa mô hình bộ nhớ nhỏ.
- Phần `.DATA` chứa chuỗi thông báo, cấu hình bản đồ, trạng thái rắn, tọa độ mồi, điểm số và biến delay.
- Phần `.CODE` chứa các thủ tục chính:
  - `MAIN`: vòng lặp menu chính và vòng lặp game.
  - `RESET_GAME_VARS`: đặt lại biến game trước khi bắt đầu.
  - `UPDATE_HIGH_SCORE`: cập nhật kỷ lục nếu điểm hiện tại lớn hơn.
  - `PRINT_NUMBER`: in số nguyên từ thanh ghi `AX` ra màn hình.
  - `INIT_GAME`: khởi tạo rắn ban đầu và tạo mồi.
  - `READ_INPUT`: xử lý phím `W/A/S/D` và các phím mũi tên.
  - `UPDATE_SNAKE`: dịch chuyển cơ chế rắn, kiểm tra va chạm và ăn mồi.
  - `SPAWN_FOOD`: sinh tọa độ ngẫu nhiên cho mồi.
  - `DRAW_FRAME`: vẽ mồi và rắn lên màn hình.
  - `DRAW_BORDER`: vẽ khung viền bản đồ.
  - `CLEAR_SCREEN`: dọn màn hình bằng ngắt `INT 10h`.
  - `SET_CURSOR`: đặt con trỏ ở vị trí cụ thể.
  - `DRAW_GAME_OVER`: hiển thị thông báo kết thúc.

## Biến quan trọng

- `mapWidth`, `mapHeight`: kích thước bản đồ trong ô.
- `offsetX`, `offsetY`: độ dịch để vẽ bản đồ vào giữa màn hình.
- `snakeX`, `snakeY`: mảng tọa độ của thân rắn.
- `snakeLen`: chiều dài rắn hiện tại.
- `dir`: hướng di chuyển (0=Up, 1=Right, 2=Down, 3=Left).
- `foodX`, `foodY`: tọa độ mồi.
- `score`, `highScore`: điểm hiện tại và điểm cao nhất.
- `delayCX`, `delayDX`: giá trị delay cho ngắt `INT 15h AH=86h`.

## Ghi chú kỹ thuật

- Rắn được lưu trữ dưới dạng mảng tọa độ và được dịch chuyển bằng cách copy từ thân đến đầu.
- Khi rắn ăn mồi, `snakeLen` tăng và `score` cộng thêm 10.
- Ngắt `INT 15h AH=86h` tạo độ trễ không chính xác nhưng đủ cho mục đích trò chơi đơn giản.
- `PRINT_NUMBER` sử dụng stack để in từng chữ số theo thứ tự đúng.

## Liên hệ

- Dự án được phát triển cho môn Kiến trúc máy tính
- Nhóm 13.

