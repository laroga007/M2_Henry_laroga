"""
Asistente de conocimiento: consulta a MongoDB desde Python (Lecture 10)

Se conecta a la base asistente_conocimiento y busca artículos por categoría
y por palabra clave (con el índice de texto creado en Compass).

Uso (con el contenedor de MongoDB encendido y el entorno virtual activo):
    python consulta_articulos.py
"""

from pymongo import MongoClient

with MongoClient("mongodb://localhost:27017") as cliente:
    articulos = cliente["asistente_conocimiento"]["articulos"]

    # 1. Búsqueda por categoría (usa el índice categoria_1)
    categoria = "Empleabilidad"
    print(f"Artículos de la categoría {categoria}:")
    for doc in articulos.find({"categoria": categoria}, {"_id": 0, "titulo": 1, "contenido": 1}):
        print(f"  - {doc['titulo']}: {doc['contenido']}")

    # 2. Búsqueda por palabra clave (usa el índice de texto contenido_text)
    palabra = "cultivo"
    print(f"\nArtículos que mencionan '{palabra}':")
    for doc in articulos.find({"$text": {"$search": palabra}}, {"_id": 0, "titulo": 1}):
        print(f"  - {doc['titulo']}")

    # 3. Las limitaciones de la búsqueda por palabra: "CV" no aparece en ningún texto
    pregunta = "CV"
    encontrados = list(articulos.find({"$text": {"$search": pregunta}}))
    print(f"\nArtículos que mencionan '{pregunta}': {len(encontrados)}")
