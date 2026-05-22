import os
import joblib
import pandas as pd
from typing import List
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

# Importações do seu banco de dados (ajuste o caminho se necessário)
from app.database import get_db
from app import models

router = APIRouter(
    prefix="/api/predicao",
    tags=["Inteligência Artificial"]
)

CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
MODELO_PATH = os.path.join(CURRENT_DIR, "..", "ml", "pipeline_inseminacao.pkl")

try:
    modelo_ia = joblib.load(MODELO_PATH)
except Exception as e:
    print(f"Erro ao carregar o modelo de IA no caminho {MODELO_PATH}: {e}")
    modelo_ia = None
    
# ─── Schemas Originais (Simulador Individual) ───────────────────────────
class InseminacaoInput(BaseModel):
    especie: str = Field(..., description="Bovino, Ovino, Caprino")
    idade_meses: int = Field(..., gt=0)
    ecc: float = Field(..., ge=1.0, le=5.0)
    tentativas_previas: int = Field(..., ge=0)
    indice_genetico_reprodutor: int = Field (..., ge=0, le=100)
    estacao: str = Field(..., description="Seca ou Chuva")
    dias_pos_parto: int = Field(..., ge=0)
    fazenda: str

# ─── Novos Schemas (Ranking de Matrizes) ────────────────────────────────
class RankingInput(BaseModel):
    especie: str = Field(..., description="Filtrar por Bovino, Ovino ou Caprino")
    indice_genetico_reprodutor: int = Field(..., ge=0, le=100)
    estacao: str = Field(..., description="Seca ou Chuva")

class CandidataResponse(BaseModel):
    animal_id: int
    nome: str | None
    idade_meses: int
    ecc: float
    probabilidade_sucesso: float
    status: str

# ─── Rota 1: Predição Individual (Original) ─────────────────────────────
@router.post("/")
async def predizer_sucesso(dados: InseminacaoInput):
    if not modelo_ia:
        raise HTTPException(status_code=500, detail="Modelo de IA indisponível no momento.")
    try:
        df_input = pd.DataFrame([dados.model_dump()])
        
        probabilidades = modelo_ia.predict_proba(df_input)[0]
        prob_sucesso = round(probabilidades[1] * 100, 2)
        prob_falha = round(probabilidades[0] * 100, 2)
        
        if prob_sucesso >= 70:
            status = "Alta Viabilidade"
            recomendacao = "Avançar com a inseminação. Condições genéticas e corporais ideais."
        elif prob_sucesso >= 50:
            status = "Atenção"
            recomendacao = "Viabilidade moderada. Avaliar custo do sêmen antes de prosseguir."
        else:
            status = "Baixa Viabilidade"
            recomendacao = "Risco alto de falha. Recomendada intervenção nutricional ou descanso."

        return {
            "sucesso": True,
            "predicao": {
                "probabilidade_sucesso": f"{prob_sucesso}%",
                "probabilidade_falha": f"{prob_falha}%",
                "classificacao": status,
                "recomendacao": recomendacao
            }
        }

    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Erro ao processar dados na IA: {str(e)}")


# ─── Rota 2: Motor de Recomendação em Lote ──────────────────────────────
@router.post("/melhores-candidatas", response_model=List[CandidataResponse])
def rankear_melhores_matrizes(dados: RankingInput, db: Session = Depends(get_db)):
    if not modelo_ia:
        raise HTTPException(status_code=500, detail="Modelo de IA indisponível no momento.")

    # 1. Busca no banco de dados apenas as matrizes da espécie desejada
    animais_db = db.query(models.Animal).filter(models.Animal.especie == dados.especie).all()
    
    if not animais_db:
        raise HTTPException(status_code=404, detail=f"Nenhuma matriz de {dados.especie} encontrada no rebanho.")

    lista_analise = []
    
    # 2. Mescla os dados de cada fêmea do banco com os dados do sêmen atual
    for animal in animais_db:
        lista_analise.append({
            "especie": animal.especie,
            "idade_meses": animal.idade_meses,
            "ecc": animal.ecc if animal.ecc is not None else 3.0, # Evita nulos quebrando a IA
            "tentativas_previas": 0, # Simplificação para o MVP
            "indice_genetico_reprodutor": dados.indice_genetico_reprodutor,
            "estacao": dados.estacao,
            "dias_pos_parto": 90, # Simplificação para o MVP
            "fazenda": animal.fazenda,
            # Campos de controle interno, não vão para o Scikit-Learn
            "animal_id": animal.id,
            "nome": animal.nome or f"ID {animal.id}"
        })

    # 3. Transforma em DataFrame
    df_completo = pd.DataFrame(lista_analise)
    
    # 4. Dropa colunas de identificação para não estourar o Pipeline da IA
    df_para_modelo = df_completo.drop(columns=["animal_id", "nome"])
    
    try:
        # 5. Roda a predição no rebanho inteiro de uma vez
        probabilidades = modelo_ia.predict_proba(df_para_modelo)
        
        # 6. Anexa os resultados (Pegamos o índice 1, que é a prob de sucesso)
        df_completo["probabilidade_sucesso"] = probabilidades[:, 1] * 100
        
        # 7. Ordena as vacas mais férteis para o topo do DataFrame
        df_ordenado = df_completo.sort_values(by="probabilidade_sucesso", ascending=False)
        
        top_candidatas = []
        
        # 8. Extrai o Top 10 para enviar ao aplicativo
        for _, row in df_ordenado.head(10).iterrows():
            prob = round(row["probabilidade_sucesso"], 2)
            
            # Reutiliza a sua lógica de status de risco
            status = "Alta Viabilidade" if prob >= 70 else "Atenção" if prob >= 50 else "Baixa Viabilidade"
            
            top_candidatas.append({
                "animal_id": row["animal_id"],
                "nome": row["nome"],
                "idade_meses": row["idade_meses"],
                "ecc": row["ecc"],
                "probabilidade_sucesso": prob,
                "status": status
            })
            
        return top_candidatas

    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Erro na matriz de predição em lote: {str(e)}")