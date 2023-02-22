from pydantic import BaseModel

class ProductSchema(BaseModel):
    name:str
    description:str
    price:float

    class Config:
        orm_mode = True