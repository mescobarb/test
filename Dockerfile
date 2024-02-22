FROM python:3.13.0a4

# copy all files
RUN mkdir hello
COPY . /hello
WORKDIR /hello

# install required libraries
RUN pip install Flask
RUN pip install Flask_Script

EXPOSE 5000

CMD ["python", "run.py"]