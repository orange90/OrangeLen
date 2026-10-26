-- OrangeLen 中文 SQL preview
CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL);
INSERT INTO users (id, name) VALUES (1, '测试用户');
SELECT id, name FROM users WHERE id = 1;
