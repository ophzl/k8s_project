from pydantic import BaseModel

class Product(BaseModel):
    name:str
    description:str
    price:float

    class Config:
        orm_mode = True