# 🐍 BÀI TẬP LỚN MÔN KIẾN TRÚC MÁY TÍNH

**Đề tài:** Xây dựng ứng dụng Game Rắn săn mồi (Snake Game) bằng Hợp ngữ Assembly 8086.

**Giảng viên hướng dẫn:** Vũ Hoài Nam

**Nhóm môn học:** 08 | **Nhóm bài tập lớn:** 13

**Hà Nội – 2026**

## 👥 Thành viên nhóm 13

| STT | Họ và Tên | Mã Sinh Viên |
| --- | --- | --- |
| 1 | **Nguyễn Đức Anh** | B24DCCN192 |
| 2 | **Đào Quang Đạt** | B24DCCN106 |
| 3 | **Dương Trường Công Hưng** | B24DCCN258 |
| 4 | **Dương Đình Hưởng** | B24DCCN269 |

---

## 📖 GIỚI THIỆU DỰ ÁN

Dự án này là một phiên bản hoàn chỉnh của trò chơi kinh điển "Rắn săn mồi" chạy trên môi trường DOS, được viết hoàn toàn bằng ngôn ngữ Assembly (kiến trúc vi xử lý 8086). Thông qua dự án, nhóm đã áp dụng trực tiếp các kiến thức nền tảng về tổ chức bộ nhớ, tập lệnh vi xử lý, hệ thống ngắt (Interrupts) và tương tác phần cứng mức thấp.

### ✨ Các tính năng chính

* **Hệ thống Menu:** Cho phép chọn 3 cấp độ khó (Dễ, Trung bình, Khó) điều chỉnh tốc độ khung hình.

* **Gameplay thời gian thực:** Di chuyển bằng `W, A, S, D` hoặc phím mũi tên.

* **Tính điểm & Kỷ lục:** Cập nhật điểm số thời gian thực (`score`) và lưu kỷ lục cao nhất (`highScore`).

* **Điều kiện kết thúc game:** Xử lý va chạm với tường, cắn vào đuôi (Game Over), hoặc rắn đạt độ dài tối đa lấp đầy bản đồ (Win).

---

## 🛠 CƠ SỞ LÝ THUYẾT & ÁP DỤNG MÃ NGUỒN

### 1. Tổ chức bộ nhớ (Memory Model)

Do vi xử lý 8086 quản lý bộ nhớ theo cơ chế Phân đoạn, chương trình sử dụng mô hình `.MODEL SMALL`. Toàn bộ dữ liệu được cấp phát tại `.DATA` và mã lệnh nằm tại `.CODE`. Hệ thống sử dụng các thanh ghi đa năng (`AX`, `BX`, `CX`, `DX`) để tính toán tọa độ và điều hướng luồng.

Cấu trúc dữ liệu chính không dùng Object/Struct mà được tuyến tính hóa qua các mảng:

* **Thân rắn:** Lưu tọa độ qua hai mảng 1-byte `snakeX DB 256 DUP(0)` và `snakeY DB 256 DUP(0)`.
* **Chỉ mục:** Sử dụng thanh ghi Base `BX` và Index để duyệt mảng, ví dụ `MOV AL, snakeX[BX-1]`.
* **Trạng thái di chuyển:** Quản lý qua biến `dir DB 1` (0=Lên, 1=Phải, 2=Xuống, 3=Trái).

### 2. Giao tiếp Phần cứng & Hệ thống Ngắt (Interrupts)

Trò chơi hoạt động dựa trên việc can thiệp trực tiếp vào các ngắt của BIOS và DOS:

#### 🎮 Ngắt Bàn phím (Keyboard Interrupt - `INT 16H`)

Trong hàm `READ_INPUT`, thay vì chờ người dùng nhập phím gây "treo" game, chương trình quét bộ đệm bàn phím liên tục:

* Gọi `MOV AH, 01H` và `INT 16H`. Nếu cờ Zero (`ZF`) bật (chưa có phím bấm), lệnh `JZ NO_KEY_PRESSED` sẽ giữ rắn đi thẳng.
* Nếu có phím, dùng `MOV AH, 00H` / `INT 16H` để đọc. Nhóm đã xử lý so sánh cả mã ASCII trong thanh ghi `AL` (cho phím `W, A, S, D`) và mã quét (Scan Code) trong thanh ghi `AH` (cho phím mũi tên như `CMP AH, 48H` - Mũi tên lên).

#### 📺 Ngắt Đồ họa & Xử lý Chuỗi (`INT 10H` & `INT 21H`)

* **Di chuyển con trỏ:** Hàm `SET_CURSOR` sử dụng ngắt BIOS `INT 10H` với `AH = 02H` để đưa con trỏ chuột đến tọa độ `DL` (X), `DH` (Y) trước khi in.
* **Xóa màn hình:** Hàm `CLEAR_SCREEN` cuộn màn hình bằng `MOV AX, 0600H` và `INT 10H`.
* **In ký tự/chuỗi:** Sử dụng ngắt DOS `INT 21H` với `AH = 09H` (in chuỗi kết thúc bằng `$`) và `AH = 02H` (in từng ký tự như `O`, `o`, `*`, `#`).

#### ⏱ Quản lý Thời gian (Timer Delay - `INT 15H`)

Để rắn không bò với tốc độ bằng xung nhịp CPU, một khoảng trễ được thiết lập trong `GAME_LOOP`:

* Gọi `MOV AH, 86H` và `INT 15H`.
* Tốc độ được tinh chỉnh dựa trên độ khó bằng cách thay đổi giá trị của `delayCX` và `delayDX` (đếm micro-giây). Ví dụ chế độ Dễ (Easy): `MOV delayCX, 03H` / `MOV delayDX, 0D090H`.

#### 🎲 Khởi tạo Mồi ngẫu nhiên (System Time - `INT 1AH`)

Hàm `SPAWN_FOOD` đọc số tick hệ thống bằng `MOV AH, 00H` và `INT 1AH`. Giá trị trả về trong thanh ghi `DX` được chia lấy dư cho kích thước bản đồ (`DIV CX` với `CX = 16`) để sinh tọa độ `foodX` và `foodY` hoàn toàn ngẫu nhiên.

### 3. Cờ trạng thái (Flags) và Logic Rẽ nhánh

Thuật toán va chạm (Collision Detection) dựa hoàn toàn vào hệ thống cờ sinh ra từ lệnh `CMP`:

* **Chạm tường:** So sánh `AL` (tọa độ X của đầu rắn) với `0` và `mapWidth`. Lệnh rẽ nhánh `JL` (Jump if Less) và `JGE` (Jump if Greater or Equal) sẽ kích hoạt nhãn `SET_GAME_OVER`.
* **Cắn đuôi:** Vòng lặp `CHECK_SELF_LOOP` duyệt từ đốt số 1 đến đốt cuối cùng (`CX = snakeLen - 1`), nếu tọa độ đầu rắn bằng tọa độ thân (`JNE NEXT_SEGMENT`), cờ `gameOver` được bật.

### 4. Kiến trúc Module (Procedures)

Toàn bộ logic CISC phức tạp được module hóa bằng các `PROC`, gọi thông qua lệnh `CALL`:

* `DRAW_BORDER`: In khung bản đồ.
* `UPDATE_SNAKE`: Tịnh tiến mảng tọa độ từ đuôi lên đầu (`SHIFT_LOOP`).
* `DRAW_FRAME`: Vẽ lại thực thể rắn và thức ăn trên khung hình mới.
* `PRINT_NUMBER`: Thuật toán chia liên tiếp (`DIV BX` với `BX=10`) và dùng ngăn xếp (`PUSH`, `POP`) để in điểm số (kiểu số nguyên) ra chuỗi ký tự ASCII.

---

## 🚀 HƯỚNG DẪN CHẠY CHƯƠNG TRÌNH

1. Tải và cài đặt trình giả lập **DOSBox** cùng trình biên dịch Assembly (**TASM** hoặc **MASM**).
2. Clone repository:
```bash
git clone https://github.com/alithw/BTL_KTMT.git

```


3. Mount thư mục chứa code trong DOSBox.
4. Biên dịch và liên kết tệp tin:
```dos
TASM SNAKE.ASM
TLINK SNAKE.OBJ
```


5. Chạy file thực thi:
```dos
SNAKE.EXE
```

