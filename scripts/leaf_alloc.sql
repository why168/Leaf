DROP TABLE IF EXISTS `leaf_alloc`;

CREATE TABLE `leaf_alloc`
(
    `biz_tag`     varchar(128) COLLATE utf8mb4_general_ci NOT NULL DEFAULT '',
    `max_id`      bigint                                  NOT NULL DEFAULT '1',
    `step`        int                                     NOT NULL,
    `description` varchar(256) COLLATE utf8mb4_general_ci          DEFAULT NULL,
    `create_time` timestamp                               NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time` timestamp                               NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`biz_tag`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_general_ci;

INSERT INTO leaf_alloc(biz_tag, max_id, step, description)
VALUES ('leaf-segment-test', 1, 2000, 'Test leaf Segment Mode Get Id');