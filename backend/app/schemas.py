from pydantic import BaseModel
from typing import List, Optional
from datetime import date

class InseminacaoBase(BaseModel):
    data_inseminacao: date
    ecc: float
    tentativas_previas: int = 0
    indice_genetico_reprodutor: int
    estacao: str
    dias_pos_parto: int
    sucesso_prenhez: Optional[bool] = None

class InseminacaoCreate(InseminacaoBase):
    pass

class InseminacaoResponse(InseminacaoBase):
    id: int
    animal_id: int
    
    class Config:
        from_attributes = True
        
class AnimalBase(BaseModel):
    especie: str
    raca: str
    linhagem: Optional[str] = None
    idade_meses: int
    fazenda: str
    
class AnimalCreate(AnimalBase):
    pass

class AnimalResponse(AnimalBase):
    id: int
    inseminacoes: List[InseminacaoResponse] = []
    
    class Config:
        from_attributes = True