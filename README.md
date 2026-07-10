# 📊 Análisis de Rendimiento Comercial y Logístico (SQL + Python)

## 📌 Resumen del Proyecto
Este proyecto es una solución integral de análisis de datos que evalúa el rendimiento comercial y la eficiencia logística de la operación. A través de la conexión directa a una base de datos SQL, se extrajo una vista consolidada para procesarla en Python, realizando un Análisis Exploratorio de Datos (EDA) profundo y generando visualizaciones estratégicas que responden a preguntas clave del negocio.

---

## 🗄️ Fase 1: Consultas y Extracción de Datos (SQL)
Para sentar las bases del análisis, se desarrolló un script estructurado enfocado en resolver preguntas estratégicas del negocio directamente desde el motor de base de datos. 

📄 **Revisa el código y las consultas aquí:** [`Final.sql`](./Final.sql)

El análisis en SQL abarcó los siguientes pilares:

### 1. Desempeño Comercial
* **Concentración y Dependencia:** Mapeo de clientes activos por país y evaluación de riesgo o dependencia hacia los clientes principales (Top 3).
* **Rentabilidad y Volumen:** Identificación de los productos que traccionan mayor volumen y análisis de los países con mayor rentabilidad neta (ventas netas - impuestos).
* **Tendencias y Canales:** Detección de estacionalidad (meses/trimestres pico) y evaluación de la facturación promedio por vendedor o canal.

### 2. Comportamiento y Eficiencia Logística
* **Cumplimiento de Entregas (SLA):** Cálculo del porcentaje de pedidos entregados fuera de plazo y detección de ciudades con mayor variabilidad o retrasos crónicos.
* **Correlaciones Logísticas:** Análisis de la relación entre los montos de venta, los tiempos de entrega y la detección de productos con fricciones logísticas.
* **Retención y Satisfacción:** Comparativa del ticket promedio entre clientes nuevos vs. recurrentes y rastreo de categorías con alta tasa de reclamos/devoluciones.
* **Crecimiento:** Análisis de crecimiento o decrecimiento interanual de ventas por país.

### 3. Creación de Vista Consolidada (ETL)
Como etapa final de la extracción, se diseñó la vista `vw_ConsolidadoVentasLogistica` para empaquetar la información y alimentar el modelo en Python. Esta vista integra los KPIs fundamentales de la operación: *País, cliente, producto, monto total, margen, impuesto, fecha y días de entrega.*

---

## ⚙️ Fase 2: Procesamiento y Transformación en Python
Una vez obtenida la vista consolidada desde SQL, el flujo de trabajo continuó en Python para la limpieza, manipulación avanzada y visualización de los datos.

📄 **Explora el código completo y los gráficos en el notebook:** [`final.ipynb`](./final.ipynb)

* **Conexión SQL-Python:** Integración directa con la base de datos para cargar la vista consolidada de ventas y logística al entorno de trabajo.
* **Limpieza de Datos:** Evaluación de la estructura del DataFrame, tipos de datos e identificación y tratamiento de valores nulos o inconsistentes.
* **Ingeniería de Características (Feature Engineering):** Conversión de formatos temporales (`datetime`) y creación de variables clave para el negocio:
  * `Año` y `Mes`
  * `Margen` (Venta - Impuesto)
  * `Días de entrega`
  * `Ratio de impuestos`

## 📈 Análisis Exploratorio de Datos (EDA)
El análisis estadístico permitió descubrir *insights* fundamentales sobre la cartera y la operación:
1. **Métricas Globales:** Cálculo de ventas totales, promedios, medianas y desviación estándar a nivel país.
2. **Detección de Anomalías:** Identificación de registros fuera del rango normal (outliers) mediante análisis descriptivo.
3. **Segmentación de Cartera:** Clasificación de clientes según su nivel de facturación (Alta, Media, Baja).
4. **Análisis de Rentabilidad:** Detección de nichos de oportunidad (productos con alta rentabilidad pero bajo volumen de ventas).
5. **Validación Estadística:** Evaluación de diferencias significativas en el rendimiento entre distintos países y categorías de clientes.

## 📊 Visualización Estratégica y Respuestas de Negocio
Utilizando `matplotlib`, se desarrollaron las siguientes visualizaciones para facilitar la toma de decisiones:

### 🌍 Desempeño Comercial y Crecimiento
* **Concentración Global:** Gráfico de barras horizontales detallando las zonas que concentran la mayor facturación.
* **Evolución y Estacionalidad:** Análisis de tendencia mensual para el Top 3 de países.
* **Curva de Crecimiento:** Gráfico de crecimiento global acumulado para identificar qué países impulsan el crecimiento anual.

### 💰 Rentabilidad
* **Matriz de Productos:** Gráfico destacando los artículos más vendidos vs. los de mayor margen.
* **Volumen vs. Margen:** Gráfico combinado (doble eje) de ventas y margen promedio mensual para detectar meses de alto volumen pero baja rentabilidad.

### 🚚 Eficiencia Logística
* **Impacto del Tiempo en Ventas:** *Scatter plot* (gráfico de dispersión) evaluando la relación entre el monto de venta y los días de entrega.
* **Variabilidad Regional:** *Boxplot* detallando la distribución y los retrasos en los días de entrega por región.
* **Mapeo Logístico:** Mapa de calor/puntos para ubicar a los clientes más importantes y evaluar las zonas críticas para la optimización logística basada en los tiempos promedio de entrega.
