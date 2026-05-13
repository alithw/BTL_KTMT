# 🧩 BÀI TẬP LỚN MÔN KIẾN TRÚC MÁY TÍNH

**Đề tài:** Xây dựng ứng dụng Game Tetris (Xếp gạch) bằng Hợp ngữ Assembly 8086.

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

Dự án này là một phiên bản hoàn chỉnh của trò chơi kinh điển "Tetris" chạy trên môi trường DOS, được viết bằng ngôn ngữ Assembly 8086. Nhóm đã ứng dụng kiến thức về tổ chức bộ nhớ, toán học số học trong thanh ghi, quản lý ngắt BIOS/DOS và xử lý đồ họa ký tự để xây dựng luồng game mượt mà.

### ✨ Các tính năng chính

* **Hệ thống Board 10x20:** Màn chơi dạng lưới 2D được lưu trữ tuyến tính trong bộ nhớ, dễ dàng xử lý va chạm và xoá hàng.
* **7 loại Tetromino:** Bao gồm `I`, `J`, `L`, `O`, `S`, `T`, `Z` với 4 trạng thái xoay.
* **Điều khiển thời gian thực:** Di chuyển trái/phải, xoay khối, tăng tốc rơi bằng phím mũi tên.
* **Xử lý va chạm thông minh:** Phát hiện chạm tường, đáy và va chạm với các ô đã khoá.
* **Xoá hàng ngang:** Khi một hàng đầy, hàng đó sẽ bị xóa và các hàng phía trên sẽ rơi xuống.
* **Tăng độ khó:** Tốc độ rơi tăng dần theo điểm số nhằm tạo độ khó và tính cạnh tranh.

---

## 🛠 CƠ SỞ LÝ THUYẾT & ÁP DỤNG MÃ NGUỒN

### 1. Tổ chức dữ liệu và địa chỉ mảng 2 chiều

Tetris yêu cầu quản lý một sân chơi 2D (thường là 10 cột x 20 hàng), nhưng trong Assembly 8086, dữ liệu này được biểu diễn dưới dạng mảng 1 chiều trong đoạn `.DATA`.

* **Sân chơi (Board):** Mảng 1D lưu trạng thái từng ô, ví dụ `board DB 200 DUP(0)` tương đương với 20 hàng x 10 cột.
* **Tính toán địa chỉ:** `index = Y * WIDTH + X`. Lệnh `MUL` và `ADD` được sử dụng để chuyển tọa độ 2D thành chỉ số tuyến tính.
* **Cơ chế địa chỉ:** Duyệt dữ liệu bằng `MOV AL, [BX + SI + offset]`, trong đó `BX` chứa địa chỉ gốc và `SI/DI` làm chỉ số dịch.

### 2. Tổ chức dữ liệu khối gạch và xoay hình

* **Tetrominoes:** 7 loại gạch được định nghĩa dưới dạng các hằng số byte `DB`, mỗi khối có 4 trạng thái xoay.
* **Biểu diễn:** Có thể lưu dưới dạng ô 4x4 hoặc bitmask 16-bit, từ đó tạo ra dữ liệu màu và hình dáng.
* **Lưu trữ trạng thái:** Mã khối và màu sắc được ghi vào bảng `board` sau khi khối dừng lại.

### 3. Hệ thống cờ và xử lý va chạm

Tetris xây dựng luồng logic dựa trên các phép so sánh `CMP` và cờ `ZF`/`CF` của CPU.

* **Va chạm tường / đáy:** So sánh tọa độ hiện tại với biên trái/phải và đáy màn hình.
* **Va chạm chồng khối:** Kiểm tra trước một bước rơi bằng cách đọc `board[Y+1, X]`. Nếu ô đó khác 0 thì khối hiện tại được khoá lại.
* **Xoá hàng:** Vòng lặp lồng nhau sử dụng `LOOP`, `CX` và `MOVSB` để kiểm tra hàng đầy, xóa hàng và dịch các hàng phía trên xuống.

### 4. Giao tiếp phần cứng và ngắt hệ thống

#### 🎮 Ngắt đồ họa và hiển thị (`INT 10H`)

* Dùng `INT 10H` để in ký tự và điều khiển màu sắc hiển thị các khối khác nhau như `I`, `O`, `T`, `S`, `Z`.
* Cách vẽ trực tiếp giúp giảm nháy màn và đảm bảo game mượt hơn khi khối di chuyển.

#### ⌨️ Ngắt bàn phím (`INT 16H`)

* Kiểm tra bộ đệm bàn phím bằng `MOV AH, 01H` / `INT 16H` để không làm dừng vòng lặp game.
* Đọc phím bằng `MOV AH, 00H` / `INT 16H` và xử lý phím mũi tên, phím xoay, phím tăng tốc.

#### ⏱ Ngắt thời gian (`INT 15H`)

* Sử dụng `INT 15H` với `AH = 86H` để tạo độ trễ giữa các lần rơi của khối.
* Tốc độ rơi được điều chỉnh dựa theo điểm số, giúp game tăng dần độ khó.

### 5. Tổ chức mã nguồn bằng thủ tục và ngăn xếp

* Chia logic thành các thủ tục `PROC`: `ClearScreen`, `CheckInput`, `CheckCollision`, `LockPiece`, `SpawnPiece`, `ClearLines`, `DrawGame`, `PrintNumber`.
* Dùng `PUSH`/`POP` để lưu lại trạng thái thanh ghi trước khi gọi các thủ tục phụ, tránh phá huỷ bối cảnh trong vòng lặp chính.

### 📊 Minh họa cách hệ thống hoạt động

```text
 MAIN PROC
    ├─ MenuStart
    │   └─ ClearScreen
    │   └─ Hiển thị menu
    │   └─ Nhận lựa chọn người chơi
    ├─ InitGame
    │   └─ Khởi tạo board, seed, score
    │   └─ Sinh khối tiếp theo
    ├─ GameLoop
    │   ├─ DrawGame
    │   ├─ Delay / INT 15H
    │   ├─ CheckInput -> di chuyển/ xoay/ rơi nhanh
    │   ├─ CheckCollision
    │   │   ├─ Kiểm tra biên trái/phải, đáy
    │   │   └─ Kiểm tra board[Y+1, X] để xác định chồng khối
    │   ├─ Nếu va chạm: LockPiece + ClearLines + SpawnPiece
    │   └─ Nếu không: tăng piece_y (rơi tiếp)
    ├─ GameOver
    │   └─ Hiển thị kết quả
    │   └─ Hỏi chơi lại
    └─ ExitProg
```

#### 🔍 Giải thích chi tiết theo nhánh

* `MenuStart`:
  - `ClearScreen` xóa màn hình và chuẩn bị vùng hiển thị mới.
  - Hiển thị danh sách chế độ chơi và hướng dẫn điều khiển.
  - Đọc lựa chọn `1-4` từ bàn phím bằng `INT 21h` / `AH=07h`.

* `InitGame`:
  - Đọc thời gian hệ thống `INT 1Ah` để khởi tạo `rand_seed`.
  - Xóa toàn bộ mảng `board` bằng `REP STOSB`.
  - Thiết lập `score`, `combo`, `lines_cleared` về 0.
  - Sinh `next_piece_id` ngẫu nhiên trước khi gọi `SpawnPiece`.

* `GameLoop`:
  - `DrawGame` vẽ lại toàn bộ trạng thái màn hình, bao gồm board, khối rơi, điểm số, combo và khối kế tiếp.
  - `Delay / INT 15H` tạo khoảng thời gian giữa các chu kỳ rơi, được điều chỉnh bởi biến `speed`.
  - `CheckInput` quét bàn phím không chặn, cho phép người chơi di chuyển/trắng/ rơi nhanh mà không làm gián đoạn vòng lặp.

* `CheckCollision`:
  - Tính toán bitmask của khối theo `piece_id` và `test_rot`.
  - Duyệt 4x4 vùng của khối, kiểm tra từng ô có gạch hay không.
  - So sánh tọa độ `test_x`/`test_y` với biên `board_w`/`board_h`.
  - Kiểm tra `board` tại vị trí tương ứng để xác định va chạm với khối đã khoá.

* Nếu va chạm:
  - `LockPiece` gắn các ô khối hiện tại vào `board` theo `piece_id`.
  - `ClearLines` quét các hàng đầy, xoá hàng đó và dịch các hàng phía trên xuống.
  - Tính điểm theo số hàng xóa liên tiếp và cập nhật `combo`.
  - `SpawnPiece` tạo khối mới và cập nhật `next_piece_id`.

* Nếu không va chạm:
  - Tăng `piece_y` để khối rơi thêm một bước.
  - Quay lại `GameLoop` để tiếp tục vẽ và xử lý.

* `GameOver`:
  - Vẽ lại màn hình lần cuối để hiển thị trạng thái sau cùng.
  - Hiển thị thông báo `THUA ROI!` và yêu cầu người chơi chọn `Y/N`.
  - Nếu người chơi chọn `Y`, chương trình quay về `InitGame`; nếu chọn `N`, quay về `MenuStart`.

* `ExitProg`:
  - Xóa màn hình và thoát chương trình bằng `INT 21h` / `AH=4Ch`.

* Tổng quan luồng:
  - `MAIN PROC` điều phối menu, khởi tạo và game loop.
  - `GameLoop` luôn là trái tim của trò chơi.
  - Các thủ tục `CheckInput`, `CheckCollision`, `LockPiece`, `ClearLines` và `DrawGame` phối hợp với nhau để giữ trạng thái game nhất quán.

---

## 🧱 BẢNG CẤU TRÚC MÃ NGUỒN

| Thành phần | Mô tả |
| --- | --- |
| `.MODEL SMALL`, `.STACK 256` | Cấu hình mô hình bộ nhớ và ngăn xếp cho Assembly 8086. |
| `.DATA` | Khai báo biến trạng thái, bảng `board`, seed sinh ngẫu nhiên, dữ liệu tetromino, màu sắc. |
| `MAIN PROC` | Khởi tạo DS/ES, hiển thị menu, xử lý lựa chọn độ khó, khởi tạo game, vòng lặp chính, và xử lý Game Over. |
| `ClearScreen PROC` | Xóa màn hình bằng `INT 10h` và chuẩn bị giao diện DOS. |
| `CheckInput PROC` | Kiểm tra phím với `INT 16h`, nhận lệnh di chuyển/ xoay/ rơi nhanh. |
| `CheckCollision PROC` | Kiểm tra va chạm của khối đang thử với biên, đáy và ô đã khoá trong `board`. |
| `LockPiece PROC` | Ghi khối hiện tại vào `board` khi nó không thể rơi thêm. |
| `SpawnPiece PROC` | Khởi tạo khối mới, cập nhật `next_piece_id`, thiết lập vị trí ban đầu. |
| `ClearLines PROC` | Quét từng hàng đầy, xoá hàng, dịch các hàng trên xuống, tính điểm và combo. |
| `DrawGame PROC` | Vẽ board, vẽ khối rơi, hiển thị `score`, `combo`, và khối kế tiếp trên màn hình. |
| `PrintNumber PROC` | In số nguyên (`score`, `combo`) bằng cách chia lấy dư và xuất từng chữ số. |

---

## 🚀 HƯỚNG DẪN CHẠY CHƯƠNG TRÌNH

1. Cài đặt trình giả lập **DOSBox** và biên dịch Assembly (**TASM** hoặc **MASM**).
2. Clone repository:
```bash
git clone https://github.com/alithw/BTL_KTMT.git
```
3. Mount thư mục chứa code trong DOSBox.
4. Biên dịch và liên kết tệp tin:
```dos
TASM TETRIS.ASM
TLINK TETRIS.OBJ
```
5. Chạy file thực thi:
```dos
TETRIS.EXE
```
