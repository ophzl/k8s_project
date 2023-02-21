from fastapi import FastAPI
from dbconfig import connect
import uvicorn
from dotenv import load_dotenv
from fastapi_sqlalchemy import DBSessionMiddleware, db
import os
from models import Product

load_dotenv('.env')

app = FastAPI()

app.add_middleware(DBSessionMiddleware, db_url=os.environ['DATABASE_URL'])

@app.get('/')
async def index():
    return {"message": "Hello from products!"}

@app.post('/')
async def add_product(product: Product):
    return product

if __name__ == '__main__':
    uvicorn.run(app, host='0.0.0.0', port=8000)