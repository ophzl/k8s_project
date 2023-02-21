FROM python:3.9

RUN mkdir /app
WORKDIR /app
ADD . /app/
RUN pip install -r requirements.txt

EXPOSE 8001
CMD ["uvicorn", "main:app", "--reload", "--host", "0.0.0.0", "--port", "8001"]