

-- a. Desempeño comercial
-- 1. ¿Cuántos clientes activos tiene la empresa y en qué países están concentrados?

USE WideWorldImporters

SELECT 
    co.CountryName AS País,
    COUNT(c.CustomerID) AS TotalClientesActivos
FROM 
    WideWorldImporters.Sales.Customers c
INNER JOIN 
    WideWorldImporters.Application.Cities ci ON c.DeliveryCityID = ci.CityID
INNER JOIN 
    WideWorldImporters.Application.StateProvinces sp ON ci.StateProvinceID = sp.StateProvinceID
INNER JOIN 
    WideWorldImporters.Application.Countries co ON sp.CountryID = co.CountryID
WHERE 
    c.IsOnCreditHold = 0  -- Filtro estándar de clientes activos/sin retención de crédito
GROUP BY 
    co.CountryName;



-- Concentración clientes por Estado

SELECT TOP 5
    sp.StateProvinceName AS [Estado/Región],
    COUNT(c.CustomerID) AS [Cantidad de Clientes]
FROM Sales.Customers c
INNER JOIN Application.Cities ci ON c.DeliveryCityID = ci.CityID
INNER JOIN Application.StateProvinces sp ON ci.StateProvinceID = sp.StateProvinceID
GROUP BY sp.StateProvinceName
ORDER BY [Cantidad de Clientes] DESC;


-- 2. ¿Qué productos representan el mayor volumen de ventas por país?

WITH VentasPorProducto AS (
    SELECT 
        co.CountryName AS [País],
        si.StockItemName AS [Producto],
        SUM(il.Quantity) AS [Volumen Total Vendido],
        DENSE_RANK() OVER (PARTITION BY co.CountryName ORDER BY SUM(il.Quantity) DESC) AS [Ranking]
    FROM 
        WideWorldImporters.Sales.InvoiceLines il
    INNER JOIN 
        WideWorldImporters.Warehouse.StockItems si ON il.StockItemID = si.StockItemID
    INNER JOIN 
        WideWorldImporters.Sales.Invoices i ON il.InvoiceID = i.InvoiceID
    INNER JOIN 
        WideWorldImporters.Sales.Customers c ON i.CustomerID = c.CustomerID
    INNER JOIN 
        WideWorldImporters.Application.Cities ci ON c.DeliveryCityID = ci.CityID
    INNER JOIN 
        WideWorldImporters.Application.StateProvinces sp ON ci.StateProvinceID = sp.StateProvinceID
    INNER JOIN 
        WideWorldImporters.Application.Countries co ON sp.CountryID = co.CountryID
    GROUP BY 
        co.CountryName, si.StockItemName
)
SELECT 
    [País],
    [Ranking],
    [Producto],
    [Volumen Total Vendido]
FROM 
    VentasPorProducto
WHERE 
    [Ranking] <= 3; -- Filtramos para ver el Top 3 de productos más vendidos



-- 3. ¿Qué tan dependiente es cada país de sus tres principales clientes?

WITH VentasPorCliente AS (
    SELECT 
        co.CountryName AS [País],
        c.CustomerName AS [Cliente],
        SUM(il.ExtendedPrice) AS [Venta Cliente],
        SUM(SUM(il.ExtendedPrice)) OVER(PARTITION BY co.CountryName) AS [Venta Total País],
        ROW_NUMBER() OVER(PARTITION BY co.CountryName ORDER BY SUM(il.ExtendedPrice) DESC) AS [Ranking]
    FROM 
        Sales.InvoiceLines il
    INNER JOIN Sales.Invoices i ON il.InvoiceID = i.InvoiceID
    INNER JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
    INNER JOIN Application.Cities ci ON c.DeliveryCityID = ci.CityID
    INNER JOIN Application.StateProvinces sp ON ci.StateProvinceID = sp.StateProvinceID
    INNER JOIN Application.Countries co ON sp.CountryID = co.CountryID
    GROUP BY 
        co.CountryName, c.CustomerName
),
Top3Clientes AS (
    SELECT 
        [País],
        [Cliente],
        [Venta Cliente],
        [Venta Total País],
        [Ranking]
    FROM 
        VentasPorCliente
    WHERE 
        [Ranking] <= 3
)
SELECT 
    [País],
    SUM([Venta Cliente]) AS [Venta Acumulada Top 3],
    MAX([Venta Total País]) AS [Venta Total País],
    ROUND((SUM([Venta Cliente]) / MAX([Venta Total País])) * 100, 2) AS [Porcentaje Dependencia (%)]
FROM 
    Top3Clientes
GROUP BY 
    [País];


-- 4. ¿Cuáles son los países con mayor rentabilidad (ventas netas – impuestos)?

SELECT 
    co.CountryName AS [País],
    SUM(il.ExtendedPrice) AS [Ventas Netas Totales],
    SUM(il.TaxAmount) AS [Impuestos Totales],
    SUM(il.ExtendedPrice - il.TaxAmount) AS [Rentabilidad Real]
FROM 
    Sales.InvoiceLines il
INNER JOIN Sales.Invoices i ON il.InvoiceID = i.InvoiceID
INNER JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
INNER JOIN Application.Cities ci ON c.DeliveryCityID = ci.CityID
INNER JOIN Application.StateProvinces sp ON ci.StateProvinceID = sp.StateProvinceID
INNER JOIN Application.Countries co ON sp.CountryID = co.CountryID
GROUP BY 
    co.CountryName
ORDER BY 
    [Rentabilidad Real] DESC;



-- 5. ¿En qué meses o trimestres se concentran las mayores ventas globales?

SELECT 
    DATEPART(QUARTER, i.InvoiceDate) AS [Trimestre],
    SUM(il.ExtendedPrice) AS [Ventas Totales],
    ROUND((SUM(il.ExtendedPrice) / SUM(SUM(il.ExtendedPrice)) OVER()) * 100, 2) AS [Participación (%)]
FROM 
    Sales.InvoiceLines il
INNER JOIN 
    Sales.Invoices i ON il.InvoiceID = i.InvoiceID
GROUP BY 
    DATEPART(QUARTER, i.InvoiceDate)
ORDER BY 
    [Ventas Totales] DESC;


SELECT 
    MONTH(i.InvoiceDate) AS [Mes Numero],
    DATENAME(MONTH, i.InvoiceDate) AS [Mes],
    SUM(il.ExtendedPrice) AS [Ventas Totales],
    ROUND((SUM(il.ExtendedPrice) / SUM(SUM(il.ExtendedPrice)) OVER()) * 100, 2) AS [Participación (%)]
FROM 
    Sales.InvoiceLines il
INNER JOIN 
    Sales.Invoices i ON il.InvoiceID = i.InvoiceID
GROUP BY 
    MONTH(i.InvoiceDate), DATENAME(MONTH, i.InvoiceDate)
ORDER BY 
    [Ventas Totales] DESC;



-- 6. ¿Qué vendedores o canales generan mayor facturación promedio por transacción?

SELECT 
    p.FullName AS [Vendedor],
    COUNT(DISTINCT i.InvoiceID) AS [Total Transacciones],
    SUM(il.ExtendedPrice) AS [Facturación Total],
    -- El Ticket Promedio por Transacción blindado contra división por cero
    ROUND(SUM(il.ExtendedPrice) / NULLIF(COUNT(DISTINCT i.InvoiceID), 0), 2) AS [Ticket Promedio por Transaccion]
FROM 
    Sales.InvoiceLines il
INNER JOIN 
    Sales.Invoices i ON il.InvoiceID = i.InvoiceID
INNER JOIN 
    Application.People p ON i.SalespersonPersonID = p.PersonID
GROUP BY 
    p.FullName
ORDER BY 
    [Ticket Promedio por Transaccion] DESC;


SELECT 
    cc.CustomerCategoryName AS [Canal Comercial],
    COUNT(DISTINCT i.InvoiceID) AS [Total Transacciones],
    SUM(il.ExtendedPrice) AS [Facturación Total],
    -- El Ticket Promedio por Transacción blindado contra división por cero
    ROUND(SUM(il.ExtendedPrice) / NULLIF(COUNT(DISTINCT i.InvoiceID), 0), 2) AS [Ticket Promedio por Transaccion]
FROM 
    Sales.InvoiceLines il
INNER JOIN 
    Sales.Invoices i ON il.InvoiceID = i.InvoiceID
INNER JOIN 
    Sales.Customers c ON i.CustomerID = c.CustomerID
INNER JOIN 
    Sales.CustomerCategories cc ON c.CustomerCategoryID = cc.CustomerCategoryID
GROUP BY 
    cc.CustomerCategoryName
ORDER BY 
    [Ticket Promedio por Transaccion] DESC;



-- 7. ¿Qué porcentaje de pedidos se entregan fuera del plazo esperado?

SELECT 
    COUNT(o.OrderID) AS [Total de Pedidos Entregados],
    SUM(CASE WHEN CAST(i.ConfirmedDeliveryTime AS DATE) > o.ExpectedDeliveryDate THEN 1 ELSE 0 END) AS [Pedidos Fuera de Plazo],
    ROUND(
        (SUM(CASE WHEN CAST(i.ConfirmedDeliveryTime AS DATE) > o.ExpectedDeliveryDate THEN 1 ELSE 0 END) * 100.0) 
        / COUNT(o.OrderID), 
    2) AS [Porcentaje Fuera de Plazo (%)]
FROM WideWorldImporters.Sales.Orders o
INNER JOIN 
    WideWorldImporters.Sales.Invoices i ON o.OrderID = i.OrderID
WHERE 
    i.ConfirmedDeliveryTime IS NOT NULL; -- Solo evaluamos pedidos que ya fueron entregados



-- 8. ¿Qué ciudades presentan más retrasos o mayor variabilidad en entregas?

WITH EvaluacionEntregas AS (
    SELECT 
        ci.CityName AS [Ciudad],
        sp.StateProvinceName AS [Estado],
        o.OrderID,
        CASE WHEN CAST(i.ConfirmedDeliveryTime AS DATE) > o.ExpectedDeliveryDate THEN 1 ELSE 0 END AS [EsRetraso],
        CASE WHEN CAST(i.ConfirmedDeliveryTime AS DATE) > o.ExpectedDeliveryDate 
             THEN DATEDIFF(DAY, o.ExpectedDeliveryDate, CAST(i.ConfirmedDeliveryTime AS DATE)) 
             ELSE 0 END AS [DiasDeRetraso]
    FROM Sales.Orders o
    INNER JOIN Sales.Invoices i ON o.OrderID = i.OrderID
    INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
    INNER JOIN Application.Cities ci ON c.DeliveryCityID = ci.CityID
    INNER JOIN Application.StateProvinces sp ON ci.StateProvinceID = sp.StateProvinceID
    WHERE i.ConfirmedDeliveryTime IS NOT NULL
)
SELECT TOP 10
    [Ciudad],
    [Estado],
    COUNT(OrderID) AS [Total Pedidos],
    SUM([EsRetraso]) AS [Total Retrasos],
    ROUND((SUM([EsRetraso]) * 100.0) / COUNT(OrderID), 2) AS [Tasa de Retraso (%)],
    MAX([DiasDeRetraso]) AS [Pico Máximo de Demora (Días)]
FROM EvaluacionEntregas
GROUP BY [Ciudad], [Estado]
HAVING SUM([EsRetraso]) > 0
ORDER BY [Tasa de Retraso (%)] DESC;



-- 9. ¿Existe relación entre el monto de venta y el tiempo de entrega?

WITH TiemposYMontos AS (
    -- Paso 1: Calculamos el tiempo real de entrega y el monto por CADA transacción única
    SELECT 
        i.InvoiceID,
        -- DATEDIFF desde que se creó la orden hasta que se entregó físicamente
        DATEDIFF(DAY, o.OrderDate, CAST(i.ConfirmedDeliveryTime AS DATE)) AS [DiasDeEntrega],
        SUM(il.ExtendedPrice) AS [MontoTotalFactura]
    FROM 
        Sales.Orders o
    INNER JOIN 
        Sales.Invoices i ON o.OrderID = i.OrderID
    INNER JOIN 
        Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
    WHERE 
        i.ConfirmedDeliveryTime IS NOT NULL
    GROUP BY 
        i.InvoiceID,
        o.OrderDate,
        CAST(i.ConfirmedDeliveryTime AS DATE)
)
-- Paso 2: Agrupamos por la cantidad de días para buscar la tendencia estadística
SELECT 
    [DiasDeEntrega] AS [Días de Tiempo de Entrega],
    COUNT(InvoiceID) AS [Volumen de Pedidos],
    ROUND(AVG([MontoTotalFactura]), 2) AS [Ticket Promedio del Pedido ($)],
    ROUND(MIN([MontoTotalFactura]), 2) AS [Pedido más Pequeño ($)],
    ROUND(MAX([MontoTotalFactura]), 2) AS [Pedido más Grande ($)]
FROM 
    TiemposYMontos
WHERE 
    [DiasDeEntrega] >= 0 -- Filtro de calidad: Evitar posibles fechas invertidas (corruptas)
GROUP BY 
    [DiasDeEntrega]
ORDER BY 
    [DiasDeEntrega] ASC;



-- 10. ¿Qué productos muestran mayores problemas logísticos?

WITH LogisticaPorProducto AS (
    -- Paso 1: Evaluamos el comportamiento de cada línea de detalle a nivel transaccional
    SELECT 
        si.StockItemName AS [Producto],
        i.InvoiceID,
        il.Quantity,
        CASE WHEN CAST(i.ConfirmedDeliveryTime AS DATE) > o.ExpectedDeliveryDate THEN 1.0 ELSE 0.0 END AS [EsRetraso],
        DATEDIFF(DAY, o.OrderDate, CAST(i.ConfirmedDeliveryTime AS DATE)) AS [DiasEsperaTotal]
    FROM 
        Sales.Orders o
    INNER JOIN 
        Sales.Invoices i ON o.OrderID = i.OrderID
    INNER JOIN 
        Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
    INNER JOIN 
        Warehouse.StockItems si ON il.StockItemID = si.StockItemID
    WHERE 
        i.ConfirmedDeliveryTime IS NOT NULL
)
-- Paso 2: Consolidamos el análisis integrando métricas operativas y estadísticas
SELECT 
    [Producto],
    COUNT(DISTINCT InvoiceID) AS [Frecuencia de Pedidos],
    SUM([Quantity]) AS [Volumen Físico Demandado (Unidades)],
    SUM(CASE WHEN [EsRetraso] = 1.0 THEN [Quantity] ELSE 0 END) AS [Unidades Físicas Retrasadas],
    ROUND(AVG([EsRetraso]) * 100, 2) AS [Tasa de Pedidos con Falla (%)],
    ROUND(AVG(CAST([DiasEsperaTotal] AS FLOAT)), 2) AS [Promedio de Espera Real (Días)],
    MAX([DiasEsperaTotal]) AS [Pico Máximo de Espera (Días)]
FROM 
    LogisticaPorProducto
GROUP BY 
    [Producto]
HAVING 
    COUNT(DISTINCT InvoiceID) > 30
ORDER BY 
    [Tasa de Pedidos con Falla (%)] DESC, 
    [Unidades Físicas Retrasadas] DESC;



-- 11. ¿Qué categorías de clientes generan mayor número de reclamos o devoluciones?

SELECT 
    cc.CustomerCategoryName AS [Categoría de Cliente],
    COUNT(ct.CustomerTransactionID) AS [Frecuencia de Devoluciones],
    SUM(ABS(ct.TransactionAmount)) AS [Monto Total Devuelto ($)],
    ROUND(AVG(ABS(ct.TransactionAmount)), 2) AS [Ticket Promedio de Devolución ($)]
FROM 
    Sales.CustomerTransactions ct
INNER JOIN 
    Sales.Customers c ON ct.CustomerID = c.CustomerID
INNER JOIN 
    Sales.CustomerCategories cc ON c.CustomerCategoryID = cc.CustomerCategoryID
INNER JOIN 
    Application.TransactionTypes tt ON ct.TransactionTypeID = tt.TransactionTypeID
WHERE 
    tt.TransactionTypeName = 'Customer Credit Note'
GROUP BY 
    cc.CustomerCategoryName
ORDER BY 
    [Frecuencia de Devoluciones] DESC, 
    [Monto Total Devuelto ($)] DESC;



-- 12. ¿Qué países presentan márgenes decrecientes pese a vender más unidades?

WITH VentasPorAño AS (
    -- Paso 1: Agrupamos las ventas y costos totales por País y Año
    SELECT 
        co.CountryName AS [Pais],
        YEAR(i.InvoiceDate) AS [Año],
        SUM(il.Quantity) AS [UnidadesVendidas],
        SUM(il.LineProfit) AS [BeneficioTotal],
        SUM(il.ExtendedPrice) AS [IngresoTotal]
    FROM Sales.Invoices i
    INNER JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
    INNER JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
    INNER JOIN Application.Cities ci ON c.DeliveryCityID = ci.CityID
    INNER JOIN Application.StateProvinces sp ON ci.StateProvinceID = sp.StateProvinceID
    INNER JOIN Application.Countries co ON sp.CountryID = co.CountryID
    GROUP BY co.CountryName, YEAR(i.InvoiceDate)
),
AnalisisTendencia AS (
    -- Paso 2: Calculamos el margen y usamos LAG() para traer los datos del año anterior
    SELECT 
        [Pais],
        [Año],
        [UnidadesVendidas],
        ROUND(([BeneficioTotal] / NULLIF([IngresoTotal], 0)) * 100, 2) AS [MargenPorcentual],
        LAG([UnidadesVendidas]) OVER(PARTITION BY [Pais] ORDER BY [Año]) AS [UnidadesAnterior],
        LAG(ROUND(([BeneficioTotal] / NULLIF([IngresoTotal], 0)) * 100, 2)) OVER(PARTITION BY [Pais] ORDER BY [Año]) AS [MargenAnterior]
    FROM VentasPorAño
)
-- Paso 3: Filtramos solo los escenarios que cumplen tu hipótesis (Más volumen, menos margen)
SELECT 
    [Pais] AS [País],
    [Año] AS [Año de Evaluación],
    [UnidadesAnterior] AS [Unidades (Año Anterior)],
    [UnidadesVendidas] AS [Unidades (Año Actual)],
    [MargenAnterior] AS [Margen % (Año Anterior)],
    [MargenPorcentual] AS [Margen % (Año Actual)]
FROM AnalisisTendencia
WHERE 
    [UnidadesVendidas] > [UnidadesAnterior] -- Condición 1: Venden más unidades
    AND [MargenPorcentual] < [MargenAnterior] -- Condición 2: El margen decrece
ORDER BY 
    [Pais], [Año];



-- 13. ¿Cuál es la diferencia entre el ticket promedio de un cliente nuevo y uno recurrente?

WITH FacturasClasificadas AS (
    -- Paso 1: Ordenamos las compras de cada cliente cronológicamente
    SELECT 
        i.CustomerID,
        i.InvoiceID,
        SUM(il.ExtendedPrice) AS [TotalFactura],
        ROW_NUMBER() OVER(PARTITION BY i.CustomerID ORDER BY i.InvoiceDate ASC, i.InvoiceID ASC) AS [NumeroCompra]
    FROM Sales.Invoices i
    INNER JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
    GROUP BY i.CustomerID, i.InvoiceID, i.InvoiceDate
),
EtiquetadoClientes AS (
    -- Paso 2: Etiquetamos si es la primera compra o una compra de retención
    SELECT 
        [InvoiceID],
        [TotalFactura],
        CASE WHEN [NumeroCompra] = 1 THEN '1. Cliente Nuevo (Primera Compra)' 
             ELSE '2. Cliente Recurrente (Compras Posteriores)' END AS [TipoDeCompra]
    FROM FacturasClasificadas
)
-- Paso 3: Extraemos la estadística descriptiva para comparar los tickets
SELECT 
    [TipoDeCompra] AS [Tipo de Cliente / Compra],
    COUNT([InvoiceID]) AS [Volumen de Transacciones],
    ROUND(AVG([TotalFactura]), 2) AS [Ticket Promedio ($)],
    ROUND(MIN([TotalFactura]), 2) AS [Ticket Más Bajo ($)],
    ROUND(MAX([TotalFactura]), 2) AS [Ticket Más Alto ($)]
FROM EtiquetadoClientes
GROUP BY [TipoDeCompra]
ORDER BY [TipoDeCompra] ASC;



-- 14. ¿Qué países crecieron o decrecieron en ventas en los últimos dos años?

WITH VentasPorAnioPais AS (
    -- Paso 1: Agrupamos las ventas totales por País y Año
    SELECT 
        co.CountryName AS [Pais],
        YEAR(i.InvoiceDate) AS [Anio],
        SUM(il.ExtendedPrice) AS [TotalVentas]
    FROM Sales.Invoices i
    INNER JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
    INNER JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
    INNER JOIN Application.Cities ci ON c.DeliveryCityID = ci.CityID
    INNER JOIN Application.StateProvinces sp ON ci.StateProvinceID = sp.StateProvinceID
    INNER JOIN Application.Countries co ON sp.CountryID = co.CountryID
    GROUP BY co.CountryName, YEAR(i.InvoiceDate)
),
RankingAnios AS (
    -- Paso 2: Etiquetamos los años (1 = El más reciente, 2 = El anterior)
    SELECT 
        [Pais],
        [Anio], -- NUEVO: Rescatamos el año explícito
        [TotalVentas],
        DENSE_RANK() OVER(ORDER BY [Anio] DESC) AS [RangoAnio]
    FROM VentasPorAnioPais
),
Comparativa AS (
    -- Paso 3: Pivotamos usando las etiquetas estáticas
    SELECT 
        [Pais],
        -- NUEVO: Extraemos el número exacto del año para las columnas
        MAX(CASE WHEN [RangoAnio] = 2 THEN [Anio] END) AS [Etiqueta_Anio_Anterior],
        MAX(CASE WHEN [RangoAnio] = 1 THEN [Anio] END) AS [Etiqueta_Anio_Actual],
        
        MAX(CASE WHEN [RangoAnio] = 2 THEN [TotalVentas] ELSE 0 END) AS [Ventas_Anio_Anterior],
        MAX(CASE WHEN [RangoAnio] = 1 THEN [TotalVentas] ELSE 0 END) AS [Ventas_Anio_Actual]
    FROM RankingAnios
    WHERE [RangoAnio] IN (1, 2)
    GROUP BY [Pais]
)
-- Paso 4: Calculamos el crecimiento porcentual y la tendencia
SELECT 
    [Pais],
    [Etiqueta_Anio_Anterior] AS [Año Base],         -- NUEVO: Se mostrará el año (ej. 2015)
    [Etiqueta_Anio_Actual] AS [Año de Evaluación],  -- NUEVO: Se mostrará el año (ej. 2016)
    [Ventas_Anio_Anterior] AS [Ventas Año Anterior ($)],
    [Ventas_Anio_Actual] AS [Ventas Año Actual ($)],
    [Ventas_Anio_Actual] - [Ventas_Anio_Anterior] AS [Diferencia Absoluta ($)],
    ROUND(CASE 
        WHEN [Ventas_Anio_Anterior] = 0 THEN NULL 
        ELSE (([Ventas_Anio_Actual] - [Ventas_Anio_Anterior]) / [Ventas_Anio_Anterior]) * 100 
    END, 2) AS [Crecimiento (%)],
    CASE 
        WHEN [Ventas_Anio_Actual] > [Ventas_Anio_Anterior] THEN 'Crecimiento'
        WHEN [Ventas_Anio_Actual] < [Ventas_Anio_Anterior] THEN 'Decrecimiento'
        ELSE 'Estancado'
    END AS [Tendencia]
FROM Comparativa
ORDER BY [Crecimiento (%)] DESC;



-- 15. Crea una vista o procedure que consolide los datos clave que consideres clave

CREATE VIEW dbo.vw_ConsolidadoVentasLogistica AS
SELECT 
    -- Dimensión Geográfica 
    co.CountryName AS [País],
    sp.StateProvinceName AS [Estado],
    
    -- Dimensión Comercial
    c.CustomerName AS [Cliente],
    si.StockItemName AS [Producto],
    
    -- Dimensión Temporal y Financiera
    CAST(i.InvoiceDate AS DATE) AS [Fecha Facturación],
    il.ExtendedPrice AS [Monto Total],
    il.TaxAmount AS [Impuesto],
    il.LineProfit AS [Ganancia Neta],
    
    -- Margen Porcentual (Optimizando tu lógica para evitar división por cero)
    ROUND(
        (il.LineProfit / NULLIF(il.ExtendedPrice, 0)) * 100, 2
    ) AS [Margen (%)],
    
    -- Dimensión Logística (Corregido a OrderDate para ver los verdaderos retrasos)
    DATEDIFF(DAY, o.OrderDate, CAST(i.ConfirmedDeliveryTime AS DATE)) AS [Días de Entrega]

FROM 
    Sales.InvoiceLines il
INNER JOIN 
    Sales.Invoices i ON il.InvoiceID = i.InvoiceID
INNER JOIN 
    Sales.Orders o ON i.OrderID = o.OrderID -- Añadido vital para el Lead Time
INNER JOIN 
    Sales.Customers c ON i.CustomerID = c.CustomerID
INNER JOIN 
    Warehouse.StockItems si ON il.StockItemID = si.StockItemID
INNER JOIN 
    Application.Cities ci ON c.DeliveryCityID = ci.CityID
INNER JOIN 
    Application.StateProvinces sp ON ci.StateProvinceID = sp.StateProvinceID
INNER JOIN 
    Application.Countries co ON sp.CountryID = co.CountryID
WHERE 
    i.ConfirmedDeliveryTime IS NOT NULL; -- Excluimos pedidos que aún están en tránsito
GO





SELECT * FROM WideWorldImporters.dbo.vw_ConsolidadoVentasLogistica
ORDER BY [Fecha Facturación] ASC;
