"""
Asistente de conocimiento: búsqueda semántica y RAG sin LLM (Lecture 10)

1. Lee los artículos de MongoDB (base asistente_conocimiento).
2. Convierte cada artículo en un vector numérico (embedding) con sentence-transformers.
3. Guarda cada vector en su documento, en el campo "embedding".
4. Para cada pregunta, busca los artículos más parecidos por similitud de coseno,
   aunque no compartan palabras con la pregunta.
5. Arma el prompt que recibiría un LLM y una respuesta borrador sin LLM
   (no hace falta una clave de OpenAI).

Uso (con MongoDB encendido y el entorno virtual activo):
    pip install pymongo sentence-transformers
    python busqueda_semantica.py

La primera ejecución descarga el modelo (unos 470 MB); después funciona sin internet.
"""

import numpy as np
from pymongo import MongoClient
from sentence_transformers import SentenceTransformer

# Modelo multilingüe: entiende preguntas y textos en español.
# El de la clase (all-MiniLM-L6-v2) está entrenado en inglés.
MODELO = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"

PREGUNTAS = [
    "¿Cómo armar un CV?",
    "¿Cómo puedo buscar trabajo por internet?",
    "Quiero plantar verduras en el balcón",
    "¿Qué es bitcoin?",
]


def make_prompt(pregunta, contextos, max_chars=800):
    """Arma el texto que se le enviaría a un LLM: la pregunta y los artículos recuperados."""
    bloques, usados = [], 0
    for c in contextos:
        bloque = f"Título: {c['titulo']}\nContenido: {c['contenido']}\n"
        if usados + len(bloque) > max_chars:
            break
        bloques.append(bloque)
        usados += len(bloque)
    contexto = "\n---\n".join(bloques) if bloques else "Sin contexto recuperado."
    return (
        "Responde la pregunta del usuario usando solo el contexto dado.\n"
        "Si falta información, dilo explícitamente.\n\n"
        f"Pregunta: {pregunta}\n\nContexto:\n{contexto}\n\nRespuesta:"
    )


def respuesta_borrador(contextos):
    """Sin LLM: devuelve el contenido de los artículos recuperados."""
    lineas = ["(Borrador sin LLM)"]
    for c in contextos:
        lineas.append(f"- {c['titulo']}: {c['contenido']}")
    return "\n".join(lineas)


def main():
    modelo = SentenceTransformer(MODELO)

    with MongoClient("mongodb://localhost:27017") as cliente:
        articulos = cliente["asistente_conocimiento"]["articulos"]
        docs = list(articulos.find({}, {"titulo": 1, "categoria": 1, "contenido": 1}))

        # Un vector por artículo, a partir del título y el contenido.
        # normalize_embeddings=True deja cada vector con largo 1: así el producto
        # entre dos vectores es directamente su similitud de coseno.
        textos = [f"{d['titulo']}. {d['contenido']}" for d in docs]
        vectores = modelo.encode(textos, normalize_embeddings=True)
        print(f"{len(docs)} artículos vectorizados, {vectores.shape[1]} dimensiones cada uno")

        # Guardar cada vector en su documento
        for doc, vector in zip(docs, vectores):
            articulos.update_one({"_id": doc["_id"]}, {"$set": {"embedding": vector.tolist()}})
        print("Vectores guardados en el campo 'embedding' de cada documento\n")

    for pregunta in PREGUNTAS:
        v_pregunta = modelo.encode([pregunta], normalize_embeddings=True)[0]
        similitudes = vectores @ v_pregunta          # similitud de coseno con cada artículo
        orden = np.argsort(similitudes)[::-1][:2]    # los 2 más parecidos

        print("=" * 70)
        print(f"Pregunta: {pregunta}")
        for i in orden:
            print(f"  {similitudes[i]:.2f}  {docs[i]['titulo']} ({docs[i]['categoria']})")

        mejor = [docs[orden[0]]]
        print("\nPrompt para el LLM:")
        print(make_prompt(pregunta, mejor))
        print("\n" + respuesta_borrador(mejor) + "\n")


if __name__ == "__main__":
    main()
