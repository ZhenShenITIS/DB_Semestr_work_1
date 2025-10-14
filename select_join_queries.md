
SELECT * FROM ORDER
SELECT * FROM WORKER

```
SELECT id, CASE WHEN value >= 1000 THEN "Дорого" ELSE "Дёшево" END AS тип_стоимости
FROM PURCHASE
```

```
SELECT id, CASE WHEN creation_date >= "20.08.2025" THEN "Новый" ELSE "Старый" END AS тип_заказа_по_дате
FROM ORDER
```

```SELECT id, 
```
