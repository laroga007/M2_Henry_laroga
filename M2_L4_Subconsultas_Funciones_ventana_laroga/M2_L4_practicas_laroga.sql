WITH RECURSIVE numeros AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1
    FROM numeros
    WHERE n < 5
)
SELECT n FROM numeros;

WITH RECURSIVE numeros AS (
    SELECT 10 AS n
    UNION ALL
    SELECT n - 1
    FROM numeros
    WHERE n > 1
)
SELECT n FROM numeros;

WITH RECURSIVE numeros AS (
    SELECT 10 AS n
    UNION ALL
    SELECT n - 1
    FROM numeros
    WHERE n > 0
)
SELECT n FROM numeros;