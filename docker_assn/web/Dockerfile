FROM python:3.4-alpine

#Adds code folder to docker container that holds requirements

ADD . /code
WORKDIR /code
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

CMD python3 app.py