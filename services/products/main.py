from fastapi import FastAPI, APIRouter
import uvicorn
from dotenv import load_dotenv
from fastapi_sqlalchemy import DBSessionMiddleware, db
import os
from schema import ProductSchema
from models import Product

load_dotenv('.env')

app = FastAPI()
router = APIRouter()
app.add_middleware(DBSessionMiddleware, db_url=os.environ['DATABASE_URL'])

@router.get('/')
async def index():
    return db.session.query(Product).all()

@router.post('/')
async def add_product(product: ProductSchema):
    return {"message": "Hello from products!"}

if __name__ == '__main__':
    uvicorn.run(app, host='0.0.0.0', port=8000)