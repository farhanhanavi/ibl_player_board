pip install -r requirements.txt
cp .env.example .env      # fill in PGHOST / PGUSER / PGPASSWORD, and DBT_SCHEMA
python app.py             # opens http://127.0.0.1:8050