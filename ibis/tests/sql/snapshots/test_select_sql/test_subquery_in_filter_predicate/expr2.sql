SELECT *
FROM star1
WHERE `f` > (
  SELECT avg(`f`) AS `mean`
  FROM star1
  WHERE `foo_id` = 'foo'
)