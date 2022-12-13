ALTER TABLE `players` ADD IF NOT EXISTS (
  `daily` int(10) DEFAULT 0,
);