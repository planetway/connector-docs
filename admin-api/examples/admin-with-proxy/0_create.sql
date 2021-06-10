CREATE TABLE example (
  id BIGINT NOT NULL AUTO_INCREMENT,
  col_1 VARCHAR(255),
  col_2 VARCHAR(255),
  PRIMARY KEY (id)
);

INSERT INTO example (id, col_1, col_2) VALUES (1, 'col_1_row_1', 'col_2_row_1');
