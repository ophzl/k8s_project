from fastapi import FastAPI, APIRouter
import uvicorn
from dotenv import load_dotenv
from fastapi_sqlalchemy import DBSessionMiddleware, db
import os
from schema import ProductSchema
from models import Product

load_dotenv('.env')

app = FastAPI()
app.add_middleware(DBSessionMiddleware, db_url=os.environ['DATABASE_URL'])

print(os.environ['DATABASE_URL'])

@app.get('/')
async def index():
    return db.session.query(Product).all()

@app.post('/')
async def add_product(product: ProductSchema):
    new_product = Product(name=product.name, description=product.description, price=product.price)
    db.session.add(new_product)
    db.session.commit()
    return product

if __name__ == '__main__':
    uvicorn.run(app, host='0.0.0.0', port=8000)