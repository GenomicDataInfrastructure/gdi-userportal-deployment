# SPDX-FileCopyrightText: 2024 PNED G.I.E.
#
# SPDX-License-Identifier: Apache-2.0

FROM python:3.11-slim

RUN apt-get update && apt-get -y install cron

WORKDIR /app

COPY . .

RUN pip install --no-cache-dir -r ./requirements.txt

RUN chmod +x ./entry.sh

RUN chmod 0644 crontab

RUN crontab crontab

CMD ["./entry.sh"]
