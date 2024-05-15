/***** use database *****/
USE hw5DB;

/***** info *****/
DROP TABLE IF EXISTS self;
CREATE TABLE self (
    StuID varchar(10) NOT NULL,
    Department varchar(10) NOT NULL,
    SchoolYear int DEFAULT 1,
    Name varchar(15) NOT NULL,
    PRIMARY KEY (StuID)
);

INSERT INTO self
VALUES ('r12921105', '電機所', 1, 'Yu, Jing-En');

SELECT DATABASE();
SELECT * FROM self;

/* Prepared statement */
-- (1) Use prepared statement to write a SELECT statement on the student table you created in Part I with “系所" select condition, but leave selection condition value as “?”. 
-- (2) List the students from your own “ 系所", by using “set” statement to set the selection condition values, and then run the prepared statement. 
-- (3) Set the conditions to a different “系所" (you can pick any one you like, but the output should not be empty) and run the prepared statement again.

PREPARE stmt FROM 'SELECT * FROM student WHERE 系所 = ?';
SET @dep = '電機所';
EXECUTE stmt USING @dep;
SET @dep2 = '經濟系';
EXECUTE stmt USING @dep2;

/* Stored-function */
DELIMITER // 
CREATE FUNCTION ExtractChineseName(name_value VARCHAR(255))
RETURNS VARCHAR(255) DETERMINISTIC
BEGIN
    DECLARE chinese_name VARCHAR(255);
    SET chinese_name = SUBSTRING_INDEX(name_value, ' (', 1);
    RETURN chinese_name;
END //
DELIMITER ;

DELIMITER //
CREATE FUNCTION ExtractEnglishName(name_value VARCHAR(255))
RETURNS VARCHAR(255) DETERMINISTIC
BEGIN
	DECLARE english_name VARCHAR(255);
	IF INSTR(name_value, '(') > 0 AND INSTR(name_value, ')') > 0 THEN
		SET english_name = SUBSTRING_INDEX(name_value, '(', -1);
		SET english_name = SUBSTRING_INDEX(english_name, ')', 1);
	ELSE
		SET english_name = '';
	END IF;
    RETURN english_name;
END //
DELIMITER ;

SELECT 
    ExtractChineseName(姓名) AS ChineseName,
    ExtractEnglishName(姓名) AS EnglishName
FROM 
    student
WHERE
    `group` = 4;

/* Stored procedure */
DELIMITER //
CREATE PROCEDURE CntByDep(IN dep_name VARCHAR(255), OUT stu_cnt INT)
BEGIN
    SELECT COUNT(*) INTO stu_cnt
    FROM student
    WHERE 系所 = dep_name;
END//
DELIMITER ;

CALL CntByDep('電機所', @STCOUNT);
SELECT @STCOUNT;
CALL CntByDep('經濟系', @STCOUNT);
SELECT @STCOUNT;

/* View  */
CREATE VIEW new_student AS
SELECT 
    身份, 
    系所, 
    年級, 
    學號, 
    ExtractChineseName(姓名) AS 中文名, 
    ExtractEnglishName(姓名) AS 英文名, 
    信箱, 
    班別
FROM student;

SELECT 
    系所,
    年級,
    學號,
    中文名,
    英文名
FROM 
    new_student
WHERE 
    系所 = '電機所';

/* Trigger */
DROP TABLE IF EXISTS record_table;
CREATE TABLE record_table (
	action_id INT PRIMARY KEY AUTO_INCREMENT,
    action_type ENUM('INSERT', 'DELETE') NOT NULL,
    action_by VARCHAR(255) NOT NULL,
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

SET @NUMDEL = 0;
SET @NUMINS = 0;

DROP TRIGGER IF EXISTS InsertStu;
DELIMITER //
CREATE TRIGGER InsertStu AFTER INSERT ON student
FOR EACH ROW
BEGIN
    INSERT INTO record_table(action_type, action_by) VALUES ('INSERT', USER()); 
    SET @NUMINS = @NUMINS + 1;
END //
DELIMITER ;

DROP TRIGGER IF EXISTS DeleteStu;
DELIMITER //
CREATE TRIGGER DeleteStu AFTER DELETE ON student
FOR EACH ROW
BEGIN
    INSERT INTO record_table(action_type, action_by) VALUES ('DELETE', USER());
    SET @NUMDEL = @NUMDEL + 1;
END //
DELIMITER ;

INSERT INTO student (身份, 系所, 年級, 學號, 姓名, 信箱, 班別) VALUES ('學生', '電機所', 1, 'R12345678', '蔡亨源', 'r12345678@ntu.edu.tw', '資料庫系統-從SQL到NoSQL (EE5178)');
INSERT INTO student (身份, 系所, 年級, 學號, 姓名, 信箱, 班別) VALUES ('學生', '電機所', 1, 'R23456789', '李玟赫', 'r23456789@ntu.edu.tw', '資料庫系統-從SQL到NoSQL (EE5178)');
INSERT INTO student (身份, 系所, 年級, 學號, 姓名, 信箱, 班別) VALUES ('學生', '電機所', 1, 'R34567890', '孫賢祐', 'r34567890@ntu.edu.tw', '資料庫系統-從SQL到NoSQL (EE5178)');
SET SQL_SAFE_UPDATES = 0;
DELETE FROM student WHERE 學號 = 'R23456789';
DELETE FROM student WHERE 學號 = 'R34567890';
SET SQL_SAFE_UPDATES = 1;

SELECT * FROM record_table;
SELECT @NUMDEL AS 'Number_of_Deletions', @NUMINS AS 'Number_of_Insertions';

-- /* drop database */
DROP DATABASE IF EXISTS hw5DB; 