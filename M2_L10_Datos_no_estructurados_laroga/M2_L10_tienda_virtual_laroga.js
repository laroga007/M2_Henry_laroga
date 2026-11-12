// =========================================================
// Lecture 10 - Homework: tienda virtual en MongoDB
// Se ejecuta en la consola de Compass (Open MongoDB shell), una línea por vez.
// Antes: crear la base tienda_virtual con la colección productos
// e importar data/productos.json (ADD DATA → Import JSON or CSV file).
// =========================================================

use("tienda_virtual")

// Verificación de la carga: 100 productos, con fecha_ingreso como fecha (ISODate)
db.productos.countDocuments()
db.productos.findOne()

// ---------------------------------------------------------
// Operaciones CRUD
// ---------------------------------------------------------

// Insertar un producto nuevo
db.productos.insertOne({ nombre: "Termo de acero 1 L", precio: 32.5, categoria: "Hogar", stock: 40, fecha_ingreso: new Date("2026-11-12") })

// Modificar su precio ($set cambia solo ese campo)
db.productos.updateOne({ nombre: "Termo de acero 1 L" }, { $set: { precio: 29.9 } })
db.productos.findOne({ nombre: "Termo de acero 1 L" }, { _id: 0, nombre: 1, precio: 1 })

// Eliminar un producto por nombre
db.productos.deleteOne({ nombre: "Pelota saltarina" })

// Consultar todos los productos de una categoría
db.productos.find({ categoria: "Libros" }, { _id: 0, nombre: 1, precio: 1, stock: 1 })

// ---------------------------------------------------------
// Índices
// ---------------------------------------------------------

// Simple sobre categoria
db.productos.createIndex({ categoria: 1 })

// Compuesto sobre categoria y precio
db.productos.createIndex({ categoria: 1, precio: 1 })

// Verificación: la consulta usa el índice compuesto (IXSCAN, categoria_1_precio_1)
db.productos.find({ categoria: "Hogar", precio: { $lt: 50 } }).explain().queryPlanner.winningPlan

// ---------------------------------------------------------
// Agregación: cantidad de productos y precio promedio por categoría
// ---------------------------------------------------------

db.productos.aggregate([
  { $group: { _id: "$categoria", cantidad: { $sum: 1 }, precio_promedio: { $avg: "$precio" } } },
  { $project: { _id: 0, categoria: "$_id", cantidad: 1, precio_promedio: { $round: ["$precio_promedio", 2] } } },
  { $sort: { cantidad: -1 } }
])

// =========================================================
// Extra mile
// =========================================================

// 1. Campo descuento (porcentaje) y precio final como campo proyectado
db.productos.updateMany({ categoria: "Electrónica" }, { $set: { descuento: 15 } })
db.productos.updateMany({ categoria: "Indumentaria" }, { $set: { descuento: 10 } })
db.productos.updateMany({ descuento: { $exists: false } }, { $set: { descuento: 0 } })

// precio_descuento = precio × (1 − descuento / 100); se calcula al consultar, no se guarda
db.productos.aggregate([
  { $match: { descuento: { $gt: 0 } } },
  { $project: {
      _id: 0, nombre: 1, categoria: 1, precio: 1, descuento: 1,
      precio_descuento: { $round: [ { $multiply: [ "$precio", { $subtract: [1, { $divide: ["$descuento", 100] }] } ] }, 2 ] }
  } },
  { $sort: { precio_descuento: -1 } },
  { $limit: 5 }
])

// 2. $match + $group + $project: stock disponible por categoría
//    de los productos que ingresaron en 2026
//    ($match antes de $group filtra documentos, como un WHERE)
db.productos.aggregate([
  { $match: { stock: { $gt: 0 }, fecha_ingreso: { $gte: new Date("2026-01-01") } } },
  { $group: { _id: "$categoria", productos: { $sum: 1 }, unidades: { $sum: "$stock" }, precio_promedio: { $avg: "$precio" } } },
  { $project: { _id: 0, categoria: "$_id", productos: 1, unidades: 1, precio_promedio: { $round: ["$precio_promedio", 2] } } },
  { $sort: { unidades: -1 } }
])

// 3. Índice TTL: borra cada documento cuando llega su fecha_expiracion
db.productos.createIndex({ fecha_expiracion: 1 }, { expireAfterSeconds: 0 })

// Los alimentos vencen el 30/6/2027
db.productos.updateMany({ categoria: "Alimentos" }, { $set: { fecha_expiracion: new Date("2027-06-30") } })

// Prueba: un producto que vence en 1 minuto
db.productos.insertOne({ nombre: "Yogur de prueba", precio: 2.5, categoria: "Alimentos", stock: 10, descuento: 0, fecha_ingreso: new Date(), fecha_expiracion: new Date(Date.now() + 60 * 1000) })
db.productos.countDocuments({ nombre: "Yogur de prueba" })   // 1

// Esperar unos 2 minutos (MongoDB revisa los TTL cada 60 segundos) y repetir:
db.productos.countDocuments({ nombre: "Yogur de prueba" })   // 0
