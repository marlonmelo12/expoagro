import joblib
import pandas as pd
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

router = APIRouter(
    prefix="/api/predicao",
    tags=["Inteligência Artificial"]
)

try:
    modelo_ia = joblib.load("app/ml/pipeline_inseminacao.pkl")
except Exception as e:
    print(f"Erro ao carregar o modelo de IA: {e}")
    modelo_ia = None
    
#Schema para validacao de dados do frontend
class InseminacaoInput(BaseModel):
    especie: str = Field(..., description="Bovino, Ovino, Caprino")
    idade_meses: int = Field(..., gt=0)
    ecc: float = Field(..., ge=1.0, le=5.0)
    tentativas_previas: int = Field(..., ge=0)
    indice_genetico_reprodutor: int = Field (..., ge=0, le=100)
    estacao: str = Field(..., description="Seca ou Chuva")
    dias_pos_parto: int = Field(..., ge=0)
    fazenda: str
    
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