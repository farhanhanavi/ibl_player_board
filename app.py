import streamlit as st
import pandas as pd
import numpy as np

from eda import *
from player_photo import *


st.set_page_config(page_title='IBL Gopay 2025 Season Performance',  layout='wide')
st.title("IBL 2025 Seasonal Player Dashboard")
st.subheader("Indonesian Basketball League Player Performance Stat Board v1")

@st.cache_data 
def read_data(path):
    return pd.read_csv(path)

#Read Player Data
df_player = read_data('./dataset/ibl_gopay_2025_playerstat.csv')
df_player['game_minutes_timedelta'] = pd.to_timedelta('00:' + df_player['game_minutes'])
df_player['game_minutes_timedelta'] = df_player['game_minutes_timedelta'].apply(lambda x: x.total_seconds()/60)

#Read Shot Data
df_shot   = read_data('./dataset/ibl_gopay_2025_shotdf.csv')
df_shot['color']  = np.where(df_shot['shot_point'] == 2, 'blue', 'orange')
df_shot['marker'] = np.where(df_shot['shot_result'] == 1, 'o', 'x')

#Read player detail data
df_player_detail   = read_data('./dataset/ibl_gopay_2025_player_detail.csv')


#Playerlist
unique_player = sorted(df_player['player_name'].unique())


#Filter Box
selected_player = st.selectbox("Select Player", unique_player)
if selected_player:

    #Sub Header
    st.subheader(selected_player)

    #Viz Photo
    photo = df_player_detail.query('player_name == @selected_player')['player_photo'].values[0]
    if photo == 'Not Available':
        st.write('Picture Not Available')
    else:
        photo = get_player_photo(photo)
        

    #First Col
    col1, col2 = st.columns([1,2])
    with col1:
        st.image(photo, use_container_width=True)
        #custom caption with bigger font
        

    with col2:
    
        #Controller
        #shot_results = ['All','Successfull','Unsuccessfull']
        #selected_player = st.segmented_control("Shot Result", shot_results, selection_mode="multi")

        viz_shot(df_shot, selected_player)

        m1, m2, m3, m4, m5 = col2.columns((1,1,1,1,1))

        #Player Data
        player_data = get_player_stat(df_player, selected_player)
        
        m1.metric(label = 'Total Games'             , value = player_data['match_id'].values)
        m1.metric(label = 'Avg. Defensive Rebound'  , value = player_data['game_rebounds_defensive'].values)


        m2.metric(label = 'Avg. Minutes'            , value = round(player_data['game_minutes_timedelta'].values[0], 2))
        m2.metric(label = 'Avg. Offensive Rebound'  , value = round(player_data['game_rebounds_offensive'].values[0], 2))
        m2.metric(label = 'Field Goal Attempted'    , value = player_data['game_field_goals_attempted'].values)
        m2.metric(label = '2PT Attempted'           , value = player_data['game_two_pointers_attempted'].values)
        m2.metric(label = '3PT Attempted'           , value = player_data['game_three_pointers_attempted'].values)
        m2.metric(label = 'FT Attempted'            , value = player_data['game_free_throws_attempted'].values)

        m3.metric(label = 'Avg. Points'             , value = round(player_data['game_points'].values[0],2))
        m3.metric(label = 'Avg. Rebound'            , value = round(player_data['total_rebound'].values[0],2))
        m3.metric(label = 'Field Goal Made'         , value = player_data['game_field_goals_made'].values)
        m3.metric(label = '2PT Made'                , value = player_data['game_two_pointers_made'].values)
        m3.metric(label = '3PT Made'                , value = player_data['game_three_pointers_made'].values)
        m3.metric(label = 'FT Made'                 , value = player_data['game_free_throws_made'].values)

        m4.metric(label = 'Avg. Assists'            , value = round(player_data['game_assists'].values[0],2))
        m4.metric(label = 'Avg. Turnovers'          , value = round(player_data['game_turnovers'].values[0],2))
        m4.metric(label = 'Field Goal %'            , value = round(player_data['field_goal_pct'].values[0] * 100,2))
        m4.metric(label = '2PT %'                   , value = round(player_data['2pt_pct'].values[0] * 100,2))
        m4.metric(label = '3PT %'                   , value = round(player_data['3pt_pct'].values[0] * 100,2))
        m4.metric(label = 'FT %'                    , value = round(player_data['ft_pct'].values[0] * 100,2))

        m5.metric(label = 'Avg. Blocks'         , value =  round(player_data['game_blocks'].values[0],2))
        m5.metric(label = 'Avg. Steals'         , value =  round(player_data['game_steals'].values[0],2))

        
        





