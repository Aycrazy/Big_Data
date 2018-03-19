FROM jupyter/pyspark-notebook
MAINTAINER AY

ADD . /code
WORKDIR /code
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
RUN pip install findspark

EXPOSE 5000

CMD python3 api.py

