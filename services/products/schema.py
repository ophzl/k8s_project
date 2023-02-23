from pydantic import BaseModel

class ProductSchema(BaseModel):
    name:str
    description:str
    price:int

    class Config:
        orm_mode = True