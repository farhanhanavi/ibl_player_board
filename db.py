from sqlalchemy import create_engine, text
import streamlit as st
import pandas as pd

#################
#                             
#      Engine             
#                 
#################

@st.cache_resource
def get_engine(USER, PASSWORD, HOST, PORT, DBNAME, SSLMODE, show_spinner=False):
    url = f"postgresql://{USER}:{PASSWORD}@{HOST}:{PORT}/{DBNAME}?sslmode={SSLMODE}"
    engine = create_engine(url, pool_pre_ping=True)
    return engine



'''
Get Player list             

input:
    - engine,
    - game_season: str
output:
    - pandas list
'''

@st.cache_data
def get_player_list(_engine_input, game_season: str):
    query   = text("""
                    SELECT 
                        DISTINCT player_name 
                    FROM 
                        dbt_schema.match_box_score
                    WHERE
                        game_season = :game_season
                    ORDER BY 
                        player_name;
                """)
    df      = pd.read_sql(query, _engine_input, params={"game_season": game_season})
    return df["player_name"].tolist()





'''
Get Player Shots             

input:
    - engine
    - player_name : str
    - game_season: str
output:
    - pandas dataframe
'''
@st.cache_data(show_spinner=False)
def get_player_shots(_engine_input, player_name: str, game_season: str):
    
    query = text("""
                        SELECT
                            match_id,
                            shot_point,
                            shot_result,
                            adjusted_x_halfcourt_left,
                            adjusted_y_halfcourt_left,
                            color,
                            marker
                        FROM 
                            dbt_schema.shot_data
                        WHERE 
                            player_name = :player_name
                            AND
                            game_season = :game_season
    """)
    df = pd.read_sql(query, _engine_input, params={"player_name": player_name, "game_season": game_season})
    return df



'''
Get Player Stats             

input:
    - engine
    - player_name : str
    - game_season: str
output:
    - pandas dataframe
'''
@st.cache_data(show_spinner=False)
def get_player_stat(_engine_input, player_name: str, game_season: str):

    query = text("""
                        SELECT
                            *
                        FROM 
                            dbt_schema.match_box_score
                        WHERE 
                            player_name = :player_name
                            AND
                            game_season = :game_season
    """)
    df = pd.read_sql(query, _engine_input, params={"player_name": player_name, "game_season": game_season})
    return df

