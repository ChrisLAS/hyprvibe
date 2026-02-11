#!/usr/bin/env python3
"""
Embedding Service - FastAPI wrapper for sentence-transformers
Provides local embedding generation to replace Voyage AI

Model: all-MiniLM-L6-v2 (23MB, 384 dimensions, ~750 qps on CPU)
"""

import os
import asyncio
from typing import List
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer
import uvicorn

# Configuration
MODEL_NAME = os.getenv("EMBEDDING_MODEL", "sentence-transformers/all-MiniLM-L6-v2")
HOST = os.getenv("EMBEDDING_HOST", "127.0.0.1")
PORT = int(os.getenv("EMBEDDING_PORT", "8000"))

# Global model instance
model = None


class EmbedRequest(BaseModel):
    text: str
    normalize: bool = True


class EmbedBatchRequest(BaseModel):
    texts: List[str]
    normalize: bool = True


class EmbedResponse(BaseModel):
    embedding: List[float]
    dimensions: int
    model: str


class EmbedBatchResponse(BaseModel):
    embeddings: List[List[float]]
    dimensions: int
    model: str
    count: int


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load model on startup"""
    global model
    print(f"Loading embedding model: {MODEL_NAME}")
    try:
        model = SentenceTransformer(MODEL_NAME)
        print(f"Model loaded successfully. Dimensions: {model.get_sentence_embedding_dimension()}")
    except Exception as e:
        print(f"Error loading model: {e}")
        raise
    yield
    print("Shutting down embedding service")


app = FastAPI(
    title="Lore Embedding Service",
    description="Local embedding generation via sentence-transformers",
    version="1.0.0",
    lifespan=lifespan
)


@app.get("/health")
async def health():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "model": MODEL_NAME,
        "loaded": model is not None
    }


@app.post("/embed", response_model=EmbedResponse)
async def embed(request: EmbedRequest):
    """Generate embedding for a single text"""
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    try:
        embedding = model.encode(
            request.text,
            normalize_embeddings=request.normalize
        )
        return EmbedResponse(
            embedding=embedding.tolist(),
            dimensions=len(embedding),
            model=MODEL_NAME
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Embedding failed: {str(e)}")


@app.post("/embed/batch", response_model=EmbedBatchResponse)
async def embed_batch(request: EmbedBatchRequest):
    """Generate embeddings for multiple texts (batch processing)"""
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    if len(request.texts) > 1000:
        raise HTTPException(status_code=400, detail="Batch size limited to 1000 texts")
    
    try:
        embeddings = model.encode(
            request.texts,
            normalize_embeddings=request.normalize,
            show_progress_bar=False
        )
        return EmbedBatchResponse(
            embeddings=[e.tolist() for e in embeddings],
            dimensions=embeddings.shape[1],
            model=MODEL_NAME,
            count=len(request.texts)
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Batch embedding failed: {str(e)}")


@app.get("/info")
async def info():
    """Get model information"""
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    return {
        "model": MODEL_NAME,
        "dimensions": model.get_sentence_embedding_dimension(),
        "max_seq_length": model.max_seq_length,
        "device": str(model.device)
    }


if __name__ == "__main__":
    uvicorn.run(app, host=HOST, port=PORT)
