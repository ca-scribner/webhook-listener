FROM python:3.8-buster

COPY requirements.txt requirements.txt

RUN pip install -r requirements.txt

ENV FLASK_APP=webhook_listener.py

COPY webhook_listener.py /webhook_listener.py

EXPOSE 5000
ENV PYTHONUNBUFFERED=0

CMD python -u -m flask run --host=0.0.0.0
