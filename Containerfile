FROM python:3.12-alpine

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

#Make a dedicated user to run the flask app
RUN addgroup -S app && adduser -S -G app app

#Install python requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

#Copy app and run it, exposing port 5000
COPY --chown=app:app app/app.py .
USER app
EXPOSE 5000
CMD ["python","app.py"]
