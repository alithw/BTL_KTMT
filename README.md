<div align="center">
  <h1>Bài tập lớn - Kiến trúc máy tính</h1>

  <p align="center">
    Xây dựng ứng dụng Game bằng Hợp ngữ Assembly 8086.
    <br />
    <a href="#hướng-dẫn-cài-đặt-và-chạy"><strong>Hướng dẫn cài đặt »</strong></a>
    &nbsp;·&nbsp;
    <a href="#hướng-dẫn-chơi-snake">Snake Tutorial</a>
    &nbsp;·&nbsp;
    <a href="#hướng-dẫn-chơi-tetris">Tetris Tutorial</a>
    &nbsp;·&nbsp;
    <a href="SNAKE.md">SNAKE.md</a>
    &nbsp;·&nbsp;
    <a href="TETRIS.md">TETRIS.md</a>
  </p>
</div>

**Đọc [SNAKE.md](SNAKE.md) và [TETRIS.md](TETRIS.md) để biết thêm thông tin chi tiết về bài làm.**

## Hướng dẫn cài đặt và chạy

### 1. Clone mã nguồn

```bash
git clone https://github.com/alithw/BTL_KTMT.git
cd BTL_KTMT
```

### 2. Yêu cầu hệ thống
- Môi trường DOS hoặc DOSBox để chạy chương trình.
- Trình biên dịch/assembler TASM hoặc MASM tương thích x86.
- Có thể sử dụng extension TASM/MASM để chạy chương trình.

### 3. Biên dịch và chạy
1. Mở DOSBox hoặc môi trường DOS tương thích.
2. Mount thư mục chứa file là ổ đĩa ảo, ví dụ:
   ```
   mount c c:\path\to\BTL_KTMT
   ```
3. Vào ổ `C:`:
   ```
   c:
   ```

## Hướng dẫn chơi Tetris

Game Tetris là trò chơi xếp khối rơi xuống.

### Cách chơi:
1. **Khởi động game**: Chạy `tetris.asm` trong môi trường DOS hoặc DOSBox.
2. **Điều khiển khối**:
   - Sử dụng phím mũi tên trái/phải để di chuyển khối ngang.
   - Mũi tên xuống để tăng tốc rơi.
   - Phím lên hoặc khoảng trắng để xoay khối.
3. **Mục tiêu**: Xếp các khối sao cho tạo thành hàng đầy và xóa chúng để ghi điểm.
4. **Kết thúc game**: Khi khối chồng lên đến đỉnh màn hình, game kết thúc.
5. **Điểm số**: Điểm tăng dựa trên số hàng xóa và tốc độ.

### Lưu ý:
- Các khối rơi tự động; người chơi điều khiển vị trí và xoay.
- Xóa nhiều hàng cùng một lúc để ghi điểm cao hơn.

### Chạy Tetris
- Biên dịch `tetris.asm`:
  ```
  tasm tetris.asm
  tlink tetris.obj
  ```
- Chạy Tetris: `tetris.exe`

Đọc **[TETRIS.md](TETRIS.md)** và để biết thêm thông tin chi tiết về bài làm.

## Hướng dẫn chơi Snake

Game Snake là trò chơi điều khiển con rắn ăn mồi trên bản đồ.

### Cách chơi:
1. **Khởi động game**: Chạy `snake.asm` trong môi trường DOS hoặc DOSBox.
2. **Chọn độ khó**: Chọn từ 1 đến 4 để chọn chế độ Easy, Medium, Hard hoặc thoát.
3. **Điều khiển rắn**:
   - Sử dụng phím `W` hoặc mũi tên lên để đi lên.
   - `D` hoặc mũi tên phải để đi phải.
   - `S` hoặc mũi tên xuống để đi xuống.
   - `A` hoặc mũi tên trái để đi trái.
4. **Mục tiêu**: Ăn mồi (ký hiệu `*`) để tăng điểm và chiều dài rắn.
5. **Tránh va chạm**: Rắn sẽ chết nếu chạm vào tường hoặc cắn vào thân mình.
6. **Kết thúc game**: Khi game over, nhấn `Y` để chơi lại hoặc `N` để về menu.
7. **Điểm số**: Mỗi mồi ăn được cộng 10 điểm. Game lưu điểm cao nhất trong phiên.

### Lưu ý:
- Rắn di chuyển liên tục; chỉ thay đổi hướng khi nhấn phím.
- Độ khó ảnh hưởng đến tốc độ rắn.

### Chạy Snake

- Biên dịch cho `snake.asm`:
     ```
     tasm snake.asm
     tlink snake.obj
     ```
- Chạy Snake:
   - `snake.exe`

Đọc **[SNAKE.md](SNAKE.md)** và để biết thêm thông tin chi tiết về bài làm.

