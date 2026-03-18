"""
Embedding Manager — Singleton wrapper around SentenceTransformer.

The ML model is loaded ONCE at startup and reused for every request.
This avoids the ~2-3 second load time on every API call.

Includes an LRU Cache to avoid re-encoding the same strings
(e.g., repeated skills lists or identical internship descriptions)
across different API requests.
"""

import logging
from sentence_transformers import SentenceTransformer
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from cachetools import LRUCache

from app.config.settings import settings

logger = logging.getLogger(__name__)


class EmbeddingManager:
    """
    Singleton class that manages the SentenceTransformer model.
    """

    _instance = None
    _model: SentenceTransformer | None = None
    _is_loaded: bool = False
    
    # Cache up to 10,000 unique string embeddings (~15MB RAM)
    _cache: LRUCache

    def __new__(cls) -> "EmbeddingManager":
        """Ensure only one instance exists (singleton pattern)."""
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._cache = LRUCache(maxsize=10000)
        return cls._instance

    def load_model(self) -> None:
        """
        Load the SentenceTransformer model into memory.
        Called once during FastAPI startup event.
        """
        if self._is_loaded:
            logger.info("Model already loaded, skipping.")
            return

        logger.info(f"Loading SentenceTransformer model: {settings.MODEL_NAME}")
        try:
            self._model = SentenceTransformer(settings.MODEL_NAME)
            self._is_loaded = True
            logger.info("✅ Model loaded successfully!")
        except Exception as e:
            logger.error(f"❌ Failed to load model: {e}")
            raise

    @property
    def is_loaded(self) -> bool:
        """Check if the model is ready to serve requests."""
        return self._is_loaded

    def encode(self, texts: list[str]) -> np.ndarray:
        """
        Encode a list of texts into embedding vectors, using an LRU cache
        to skip computation for previously seen texts.
        """
        if not self._is_loaded or self._model is None:
            from app.exceptions import ModelNotLoadedError
            raise ModelNotLoadedError()

        # Clean texts (empty strings produce garbage embeddings)
        clean_texts = [t.strip() if t.strip() else "empty" for t in texts]
        
        results = [None] * len(clean_texts)
        misses_indices = []
        misses_texts = []

        # 1. Check cache for each text
        for i, text in enumerate(clean_texts):
            cached_embedding = self._cache.get(text)
            if cached_embedding is not None:
                results[i] = cached_embedding
            else:
                misses_indices.append(i)
                misses_texts.append(text)

        # 2. Encode all misses in a single batch
        if misses_texts:
            new_embeddings = self._model.encode(misses_texts, convert_to_numpy=True)
            for cache_idx, original_idx in enumerate(misses_indices):
                emb = new_embeddings[cache_idx]
                results[original_idx] = emb
                self._cache[misses_texts[cache_idx]] = emb

        # Return as 2D numpy array
        return np.array(results)

    def similarity(self, text_a: str, text_b: str) -> float:
        """
        Compute cosine similarity between two texts.
        """
        if not text_a.strip() or not text_b.strip():
            return 0.0

        embeddings = self.encode([text_a, text_b])
        score = cosine_similarity(
            embeddings[0].reshape(1, -1),
            embeddings[1].reshape(1, -1)
        )[0][0]

        return float(max(0.0, min(1.0, score)))

    def batch_similarity(self, query: str, documents: list[str]) -> list[float]:
        """
        Compute cosine similarity between one query and multiple documents.
        Much faster than calling similarity() in a loop because we encode
        the query only once. Uses cache via self.encode().
        """
        if not query.strip() or not documents:
            return [0.0] * len(documents)

        # Encode query + all documents in a single batch
        all_texts = [query] + documents
        embeddings = self.encode(all_texts)

        query_embedding = embeddings[0].reshape(1, -1)
        doc_embeddings = embeddings[1:]

        # Compute similarities in one vectorized operation
        scores = cosine_similarity(query_embedding, doc_embeddings)[0]

        # Clamp each score to [0, 1]
        return [float(max(0.0, min(1.0, s))) for s in scores]


# Global singleton instance
embedding_manager = EmbeddingManager()
