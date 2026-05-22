from sqlalchemy import Column, Integer, String, Float, ForeignKey, Date, Boolean, Text
from sqlalchemy.orm import relationship
from app.database import Base
from datetime import date

class Animal(Base):
    __tablename__ = "animais"
    
    id = Column(Integer, primary_key=True, index=True)
    registro_id = Column(String, index=True, nullable=True)
    nome = Column(String, nullable=True)
    especie = Column(String, index=True)
    raca = Column(String)
    linhagem = Column(String, nullable=True)
    
    data_nascimento = Column(Date, nullable=True)
    status_reprodutivo = Column(String, default="Vazia")
    
    peso = Column(Float, nullable=True)
    ecc = Column(Float, nullable=True)
    fazenda = Column(String, default="Fazenda Única")
    sexo = Column(String, default="Fêmea")
    foto_url = Column(String, nullable=True)
    
    mae_id = Column(Integer, ForeignKey("animais.id"), nullable=True)
    origem_paterna = Column(String, nullable=True)
    
    inseminacoes = relationship("Inseminacao", back_populates="animal", cascade="all, delete-orphan")
    eventos_historico = relationship("EventoHistorico", back_populates="animal", cascade="all, delete-orphan", order_by="EventoHistorico.data_evento.desc()")
    mae = relationship("Animal", remote_side=[id], back_populates="filhotes")
    filhotes = relationship("Animal", back_populates="mae")
    
    @property
    def idade_meses(self):
        if self.data_nascimento is None:
            return 0
        hoje = date.today()
        # Aproximação de meses considerando 30 dias. Para maior precisão, pode-se usar relativedelta.
        dias = (hoje - self.data_nascimento).days
        return max(0, dias // 30)

class Inseminacao(Base):
    __tablename__ = "inseminacoes"
    
    id = Column(Integer, primary_key=True, index=True)
    animal_id = Column(Integer, ForeignKey("animais.id"))
    
    data_inseminacao = Column(Date)
    ecc = Column(Float)
    tentativas_previas = Column(Integer, default=0)
    indice_genetico_reprodutor = Column(Integer)
    estacao = Column(String)
    dias_pos_parto = Column(Integer)
    
    sucesso_prenhez = Column(Boolean, nullable=True)
    
    animal = relationship("Animal", back_populates="inseminacoes")

class EventoHistorico(Base):
    """
    Tabela de Eventos Unificada para a Linha do Tempo.
    categoria_evento: 'Reprodutivo' | 'Sanitário' | 'Manejo'
    """
    __tablename__ = "eventos_historico"
    
    id = Column(Integer, primary_key=True, index=True)
    animal_id = Column(Integer, ForeignKey("animais.id"), nullable=False)
    categoria_evento = Column(String, nullable=False)
    titulo_evento = Column(String, nullable=False)
    data_evento = Column(Date, nullable=False)
    detalhes = Column(Text, nullable=True)
    
    animal = relationship("Animal", back_populates="eventos_historico")