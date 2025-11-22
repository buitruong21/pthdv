-- Tao database
CREATE DATABASE HeThongNhuongQuyen;
GO

USE HeThongNhuongQuyen;
GO


-- Bang cua hang
CREATE TABLE cuaHang (
    cuaHangId      INT IDENTITY(1,1) PRIMARY KEY,
    maCuaHang      VARCHAR(50) UNIQUE NOT NULL,
    tenCuaHang     VARCHAR(255) NOT NULL,
    chuCuaHang     VARCHAR(255),
    soDienThoai    VARCHAR(20),
    diaChi         VARCHAR(255),
    ngayTao        DATETIME DEFAULT GETDATE()
);
GO


-- Bang hop dong
CREATE TABLE hopDong (
    hopDongId      INT IDENTITY(1,1) PRIMARY KEY,
    cuaHangId      INT NOT NULL,
    maHopDong      VARCHAR(50) UNIQUE NOT NULL,
    ngayBatDau     DATE NOT NULL,
    ngayKetThuc    DATE,
    tyLePhi        DECIMAL(5,2) NOT NULL,
    dieuKhoan      NVARCHAR(MAX),
    tepPdf         VARCHAR(500),
    ngayTao        DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (cuaHangId) REFERENCES cuaHang(cuaHangId) ON DELETE CASCADE
);
GO


-- Bang doanh thu
CREATE TABLE doanhThu (
    doanhThuId      INT IDENTITY(1,1) PRIMARY KEY,
    cuaHangId       INT NOT NULL,
    ngayBaoCao      DATE NOT NULL,
    tongTien        DECIMAL(15,2) NOT NULL,
    tienKhuyenMai   DECIMAL(15,2) DEFAULT 0,
    tienThucNhan    AS (tongTien - tienKhuyenMai),
    ngayTao         DATETIME DEFAULT GETDATE(),

    UNIQUE(cuaHangId, ngayBaoCao),
    FOREIGN KEY (cuaHangId) REFERENCES cuaHang(cuaHangId) ON DELETE CASCADE
);
GO


-- Bang hoa don
CREATE TABLE hoaDon (
    hoaDonId        INT IDENTITY(1,1) PRIMARY KEY,
    hopDongId       INT NOT NULL,
    cuaHangId       INT NOT NULL,
    ngayHoaDon      DATE NOT NULL,
    kyTuNgay        DATE NOT NULL,
    kyDenNgay       DATE NOT NULL,
    tongDoanhThu    DECIMAL(15,2) NOT NULL,
    tyLePhi         DECIMAL(5,2) NOT NULL,
    soTienPhaiTra   DECIMAL(15,2) NOT NULL,
    trangThai       VARCHAR(20) DEFAULT 'UNPAID',
    tepPdf          VARCHAR(500),
    ngayTao         DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (hopDongId) REFERENCES hopDong(hopDongId) ON DELETE CASCADE,
    FOREIGN KEY (cuaHangId) REFERENCES cuaHang(cuaHangId) ON DELETE CASCADE
);
GO


-- Bang thanh toan
CREATE TABLE thanhToan (
    thanhToanId        INT IDENTITY(1,1) PRIMARY KEY,
    hoaDonId           INT NOT NULL,
    soTienThanhToan    DECIMAL(15,2) NOT NULL,
    ngayThanhToan      DATE NOT NULL,
    hinhThuc           VARCHAR(20) DEFAULT 'BANK',
    ghiChu             NVARCHAR(MAX),
    ngayTao            DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (hoaDonId) REFERENCES hoaDon(hoaDonId) ON DELETE CASCADE
);
GO


-- Trigger cap nhat trang thai hoa don
CREATE TRIGGER capNhatTrangThaiHoaDon
ON thanhToan
AFTER INSERT
AS
BEGIN
    UPDATE hoaDon
    SET trangThai = 'PAID'
    WHERE hoaDonId IN (SELECT hoaDonId FROM inserted)
      AND (
            (SELECT SUM(soTienThanhToan) FROM thanhToan WHERE hoaDonId = inserted.hoaDonId)
            >= (SELECT soTienPhaiTra FROM hoaDon WHERE hoaDonId = inserted.hoaDonId)
          );
END;
GO


-- View bao cao doanh thu
CREATE VIEW baoCaoDoanhThu
AS
SELECT 
    c.cuaHangId,
    c.tenCuaHang,
    d.ngayBaoCao,
    d.tongTien,
    d.tienKhuyenMai,
    d.tienThucNhan
FROM cuaHang c
JOIN doanhThu d ON c.cuaHangId = d.cuaHangId;
GO


-- Procedure tao hoa don
CREATE PROCEDURE taoHoaDon
    @cuaHangId INT,
    @tuNgay DATE,
    @denNgay DATE
AS
BEGIN
    DECLARE @doanhThu DECIMAL(15,2);
    DECLARE @tyLePhi DECIMAL(5,2);
    DECLARE @hopDongId INT;

    SELECT TOP 1 
        @hopDongId = hopDongId,
        @tyLePhi = tyLePhi
    FROM hopDong
    WHERE cuaHangId = @cuaHangId
    ORDER BY ngayBatDau DESC;

    SELECT @doanhThu = SUM(tienThucNhan)
    FROM doanhThu
    WHERE cuaHangId = @cuaHangId
      AND ngayBaoCao BETWEEN @tuNgay AND @denNgay;

    INSERT INTO hoaDon (
        hopDongId, cuaHangId, ngayHoaDon,
        kyTuNgay, kyDenNgay, tongDoanhThu,
        tyLePhi, soTienPhaiTra
    )
    VALUES (
        @hopDongId, @cuaHangId, GETDATE(),
        @tuNgay, @denNgay, @doanhThu,
        @tyLePhi, @doanhThu * @tyLePhi / 100
    );
END;
GO
