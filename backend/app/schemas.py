from pydantic import BaseModel, ConfigDict
from typing import List, Optional, Literal
from datetime import date

# ─── Inseminação ────────────────────────────────────────────────────────────

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

class InseminacaoUpdateStatus(BaseModel):
    sucesso_prenhez: bool

class InseminacaoResponse(InseminacaoBase):
    id: int
    animal_id: int
    
    model_config = ConfigDict(from_attributes=True)

# ─── Animal ─────────────────────────────────────────────────────────────────

class AnimalBase(BaseModel):
    registro_id: Optional[str] = None
    nome: Optional[str] = None
    especie: str
    raca: str
    linhagem: Optional[str] = None
    
    data_nascimento: Optional[date] = None
    status_reprodutivo: str = "Vazia"
    
    peso: Optional[float] = None
    ecc: Optional[float] = None
    fazenda: Optional[str] = "Fazenda Única"
    sexo: Optional[str] = "Fêmea"
    foto_url: Optional[str] = None
    
    mae_id: Optional[int] = None
    origem_paterna: Optional[str] = None
    
class AnimalCreate(AnimalBase):
    idade_meses: Optional[int] = None

class AnimalUpdate(BaseModel):
    """Schema para edição parcial de um animal. Todos os campos são opcionais."""
    registro_id: Optional[str] = None
    nome: Optional[str] = None
    especie: Optional[str] = None
    raca: Optional[str] = None
    linhagem: Optional[str] = None
    data_nascimento: Optional[date] = None
    status_reprodutivo: Optional[str] = None
    peso: Optional[float] = None
    ecc: Optional[float] = None
    fazenda: Optional[str] = None
    sexo: Optional[str] = None
    foto_url: Optional[str] = None
    origem_paterna: Optional[str] = None

class AnimalMaeResponse(BaseModel):
    id: int
    nome: Optional[str] = None
    registro_id: Optional[str] = None
    
    model_config = ConfigDict(from_attributes=True)

class AnimalResponse(AnimalBase):
    id: int
    idade_meses: int
    inseminacoes: List[InseminacaoResponse] = []
    mae: Optional[AnimalMaeResponse] = None
    
    model_config = ConfigDict(from_attributes=True)

# ─── Eventos Históricos (Linha do Tempo) ────────────────────────────────────

CATEGORIA_EVENTO = Literal['Reprodutivo', 'Sanitário', 'Manejo']

class EventoHistoricoCreate(BaseModel):
    """Payload para registrar um novo evento na linha do tempo."""
    categoria_evento: CATEGORIA_EVENTO
    titulo_evento: str
    data_evento: date
    detalhes: Optional[str] = None
    novo_peso: Optional[float] = None

class PartoCreate(BaseModel):
    data_parto: date
    detalhes: Optional[str] = None
    cria: AnimalCreate

class EventoHistoricoResponse(BaseModel):
    id: int
    animal_id: int
    categoria_evento: str
    titulo_evento: str
    data_evento: date
    detalhes: Optional[str] = None
    
    model_config = ConfigDict(from_attributes=True)