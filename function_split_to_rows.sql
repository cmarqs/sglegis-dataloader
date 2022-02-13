-- split-string-into-rows.sql
-- Duane Hutchins
-- https://www.github.com/duanehutchins
-- Split a string into a mysql resultset of rows
-- This is designed to work with a comma-separated string (csv, SET, array)

-- To use a delimiter other than a comma:
--      Just change all the occurrences of ',' to the new delimiter
--      (four occurrences in SET_EXTRACT and one occurrence in SET_COUNT)

-- Function SET_EXTRACT
-- Essentially does the reverse of MySQL's built-in function FIND_IN_SET(str,strlist) = index INT
-- Splits a comma-separated string (AKA "SET"), $strlist, and returns the element (aka substring) matching the provided index, $i.
-- If index $i is zero or positive, the elements are counted from the left, starting at zero.
-- If index $i is negative, the elements are instead counted from the right, starting at -1.
-- If either parameter is NULL or if $i is outside the element count, NULL will be returned
-- Usage Example: SELECT SET_EXTRACT(2,'foo,bar,foobar'); // "foobar"
DROP FUNCTION SET_EXTRACT;
CREATE FUNCTION SET_EXTRACT($i SMALLINT UNSIGNED, $strlist MEDIUMBLOB) RETURNS VARBINARY(255)
    DETERMINISTIC NO SQL
    RETURN NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(CONCAT(0b0, ',', $strlist, ',', 0b0), ',', $i+1.5*(SIGN($i+0.5)+1)-1), ',', -SIGN($i+0.5)),0b0);

-- Function SET_COUNT
-- Returns the number of elements in a set
-- (Actually returns the one plus the number of commas in the string)
DROP FUNCTION SET_COUNT;
CREATE FUNCTION SET_COUNT($strlist MEDIUMBLOB) RETURNS SMALLINT UNSIGNED
    DETERMINISTIC NO SQL
    RETURN 1+CHAR_LENGTH($strlist)-CHAR_LENGTH(REPLACE($strlist,',',''));

-- Table number_set
-- A column of integers counting from 0 to 255
-- This is a handy tool to pivot a table (or mysql result) row of columns into a column of rows
-- The ENGINE=MEMORY engine may be used for a performance gain, but see note on the MEMORY engine listed below
DROP TABLE `number_set`;
CREATE TABLE `number_set` (
    `n` TINYINT(3) UNSIGNED NOT NULL PRIMARY KEY,
    UNIQUE KEY `n` (`n`) USING BTREE
) ENGINE=INNODB DEFAULT CHARSET=BINARY MAX_ROWS=256 MIN_ROWS=256;

-- Note: If using MEMORY engine for the number_set table, the data in MEMORY tables is lost on server restart,
--          I recommend adding this INSERT query below to the mysql --init-file, if using MEMORY engine
--          https://dev.mysql.com/doc/refman/5.7/en/memory-storage-engine.html#memory-storage-engine-loading-data

-- Insert numbers 0-255 into the number_set table
TRUNCATE number_set;
INSERT INTO number_set (n)
    SELECT STRAIGHT_JOIN n1.n|(n2.n<<2)|(n3.n<<4)|(n4.n<<6) AS n FROM
    (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3) n1,
    (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3) n2,
    (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3) n3,
    (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3) n4;

-- Function split_string_into_rows()
-- Only used as a work-around to pass @split_string_into_rows to the split_string_into_rows VIEW
-- Returns @split_string_into_rows if the argument is NULL
-- Sets @split_string_into_rows if the argument is not NULL
DROP FUNCTION split_string_into_rows;
CREATE FUNCTION split_string_into_rows($split_string_into_rows MEDIUMBLOB) RETURNS MEDIUMBLOB
    DETERMINISTIC NO SQL
    RETURN IF($split_string_into_rows IS NULL, IFNULL(@split_string_into_rows,''), '1'|@split_string_into_rows:=$split_string_into_rows);

-- View split_string_into_rows
-- Splits a comma-delimited string (aka csv aka comma-separated string) into rows
-- Result set contains the index (`i`) and element (`e`)
-- Resultset sorted by index, starting at zero
-- The comma-separated string is passed via @split_string_into_rows
-- Usage Examples:
--    Two queries:
--      SET @split_string_into_rows = 'foo,bar,foobar'; SELECT e FROM split_string_into_rows;
--    As a single query:
--      SELECT e FROM split_string_into_rows WHERE split_string_into_rows('foo,bar,foobar,barfoo');
--    With a JOIN to another table:
--      SELECT u.name FROM users u JOIN split_string_into_rows s ON u.birth_month = s.e WHERE split_string_into_rows('March,April,May');
--      _ or even better _
--      SELECT STRAIGHT_JOIN u.name FROM split_string_into_rows s, users u WHERE u.birth_month = s.e AND split_string_into_rows('March,April,May,June');
-- Field indexes are still used when doing a join against a string split!
-- This preforms much faster than FIND_IN_SET() because the indexes are preserved.

-- Limited to 256 results
CREATE OR REPLACE ALGORITHM = MERGE VIEW split_string_into_rows(i,e) AS
    SELECT HIGH_PRIORITY SQL_SMALL_RESULT n1.n AS i, SET_EXTRACT(n1.n, split_string_into_rows(NULL)) AS e
    FROM number_set n1
    WHERE 1&(n1.n < SET_COUNT(split_string_into_rows(NULL)));

-- Limited to 65535 results (slightly slower)
CREATE OR REPLACE VIEW split_string_into_rows(i,e) AS
    SELECT STRAIGHT_JOIN n1.n|(n256.n<<8) AS i, SET_EXTRACT(n1.n|(n256.n<<8), split_string_into_rows(NULL)) AS e
    FROM number_set n1, number_set n256
    WHERE 1&(n1.n|(n256.n<<8) < SET_COUNT(split_string_into_rows(NULL)));

-- Larger than 65535 results will get very slow,
--      but can be done with additional joins within the above view
--      and adjusting the INT and BLOB variable types to support larger sizes in the functions