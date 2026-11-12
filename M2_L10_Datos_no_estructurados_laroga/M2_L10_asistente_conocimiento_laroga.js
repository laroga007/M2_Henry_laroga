// =========================================================
// Lecture 10: asistente de conocimiento en MongoDB
// Se ejecuta en la consola de Compass (Open MongoDB shell), una línea por vez.
// Antes: crear la base asistente_conocimiento con la colección articulos
// e importar data/articulos.json (ADD DATA → Import JSON or CSV file).
// =========================================================

use("asistente_conocimiento")

// Verificación de la carga: 5 artículos
db.articulos.countDocuments()

// ---------------------------------------------------------
// Índices
// ---------------------------------------------------------

// Simple: filtros rápidos por categoría
db.articulos.createIndex({ categoria: 1 })

// Compuesto: búsquedas por categoría y título
// (también sirve para buscar solo por categoría, su primer campo)
db.articulos.createIndex({ categoria: 1, titulo: 1 })

// De texto sobre el contenido, en español: ignora tildes y palabras como
// "de", "la", "y", y reduce cada palabra a su raíz (cultivar y cultivo)
db.articulos.createIndex({ contenido: "text" }, { default_language: "spanish" })

// Verificación: 4 índices (_id_, categoria_1, categoria_1_titulo_1, contenido_text)
db.articulos.getIndexes()

// ---------------------------------------------------------
// Búsqueda por palabra clave (usa el índice de texto)
// ---------------------------------------------------------

// Sin tilde: encuentra "Cómo redactar un currículum efectivo"
db.articulos.find({ $text: { $search: "curriculum" } }, { titulo: 1, _id: 0 })

// Otra forma de la palabra: encuentra "Guía para cultivar tomates en casa"
db.articulos.find({ $text: { $search: "cultivo" } }, { titulo: 1, _id: 0 })

// ---------------------------------------------------------
// Agregación: artículos por categoría
// $group = GROUP BY · $match = HAVING · $project = columnas del SELECT
// ---------------------------------------------------------

// Categorías con más de 1 artículo: no devuelve nada,
// porque en el dataset cada categoría tiene un solo artículo
db.articulos.aggregate([
  { $group: { _id: "$categoria", cantidad: { $sum: 1 } } },
  { $match: { cantidad: { $gt: 1 } } },
  { $project: { _id: 0, categoria: "$_id", cantidad: 1 } }
])

// La misma pipeline con 1 o más: las 5 categorías, con cantidad 1
db.articulos.aggregate([
  { $group: { _id: "$categoria", cantidad: { $sum: 1 } } },
  { $match: { cantidad: { $gte: 1 } } },
  { $project: { _id: 0, categoria: "$_id", cantidad: 1 } }
])
