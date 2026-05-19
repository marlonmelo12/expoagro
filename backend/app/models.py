from sqlalchemy import Column, Integer, String, Float, ForeignKey, Date, Boolean
from sqlalchemy.orm import relationship
from app.database import Base

class Animal(Base):
    __tablename__ = "animais"
    
    id = Column(Integer, primary_key=True, index=True)
    especie = Column(String, index=True)
    raca = Column(String)
    linhagem = Column(String, nullable=True)
    idade_meses = Column(Integer)
    fazenda = Column(String)
    
    inseminacoes = relationship("Inseminacao", back_populates="animal", cascade="all, delete-orphan")
    
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