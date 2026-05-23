FROM apache/airflow:2.10.5

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    bash \
    curl \
    unzip \
    openjdk-17-jre-headless \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://dl.min.io/client/mc/release/linux-amd64/mc \
    -o /usr/local/bin/mc && chmod +x /usr/local/bin/mc

RUN mkdir -p /opt/spark/jars

RUN curl -fsSL -o /opt/spark/jars/delta-spark_2.12-3.2.0.jar \
    https://repo1.maven.org/maven2/io/delta/delta-spark_2.12/3.2.0/delta-spark_2.12-3.2.0.jar && \
    curl -fsSL -o /opt/spark/jars/delta-storage-3.2.0.jar \
    https://repo1.maven.org/maven2/io/delta/delta-storage/3.2.0/delta-storage-3.2.0.jar && \
    curl -fsSL -o /opt/spark/jars/antlr4-runtime-4.9.3.jar \
    https://repo1.maven.org/maven2/org/antlr/antlr4-runtime/4.9.3/antlr4-runtime-4.9.3.jar && \
    curl -fsSL -o /opt/spark/jars/postgresql-42.7.3.jar \
    https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.3/postgresql-42.7.3.jar && \
    curl -fsSL -o /opt/spark/jars/aws-java-sdk-bundle-1.12.262.jar \
    https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar && \
    curl -fsSL -o /opt/spark/jars/hadoop-aws-3.3.4.jar \
    https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar

COPY requirements.txt /requirements.txt

USER airflow

# Step 1: data packages (no constraint needed)
RUN pip install --no-cache-dir \
    pyspark==3.5.2 \
    delta-spark==3.2.0 \
    pandas==2.2.3 \
    psycopg2-binary==2.9.10 \
    confluent-kafka==2.6.1 \
    faker==33.3.1 \
    requests==2.32.3

# Step 2: Airflow providers (constraints file pins compatible versions automatically)
RUN pip install --no-cache-dir \
    apache-airflow-providers-apache-spark \
    apache-airflow-providers-apache-kafka \
    apache-airflow-providers-mongo \
    apache-airflow-providers-amazon \
    apache-airflow-providers-http \
    --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.10.5/constraints-3.12.txt"
