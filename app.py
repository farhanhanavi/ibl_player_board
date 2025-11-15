import streamlit as st
import pandas as pd
import numpy as np
import os

from shot_eda import viz_shot
from player_eda import *
from player_photo import *



@st.cache_data 
def read_data(path):
    return pd.read_csv(path)




##################################
#                               #
#          Load Data            #
#                               #
##################################

#Read Player Data
df_player                           = read_data('./dataset/ibl_gopay_2025_playerstat.csv')
df_player['game_minutes_timedelta'] = pd.to_timedelta('00:' + df_player['game_minutes'])
df_player['game_minutes_timedelta'] = df_player['game_minutes_timedelta'].apply(lambda x: x.total_seconds()/60)

#Read Shot Data
df_shot             = read_data('./dataset/ibl_gopay_2025_shotdf.csv')
df_shot             = df_shot.query("game_type != 'playoffs'")
df_shot['color']    = np.where(df_shot['shot_point'] == 2, 'blue', 'orange')
df_shot['marker']   = np.where(df_shot['shot_result'] == 1, 'o', 'x')
df_shot['adjusted_x_halfcourt_left'] = np.where(df_shot['adjusted_x_loc'] < 28/2, df_shot['adjusted_x_loc'], 0 + (28 - df_shot['adjusted_x_loc']))
df_shot['adjusted_y_halfcourt_left'] = np.where(df_shot['adjusted_x_loc'] < 28/2, df_shot['adjusted_y_loc'], 0 + (15 - df_shot['adjusted_y_loc']))


#Read player detail data
df_player_detail    = read_data('./dataset/ibl_gopay_2025_player_detail.csv')





##################################
#                               #
#          Streamlit App        #
#                               #
##################################




#Page Title
st.set_page_config(page_title='IBL Player Performance Dashboard V1',  layout='wide')
st.title("IBL Player Performance Dashboard V1")
st.subheader("Hi ! This board is meant for public scouting & player performance analysis")

#Playerlist
unique_player       = sorted(df_player['player_name'].unique())

#Filter Box
selected_player = st.selectbox("Select Player", unique_player)


if selected_player:

    #Sub Header
    #st.subheader(selected_player)
    st.markdown(f"<h2 style='text-align: center;'>{selected_player}</h2>", unsafe_allow_html=True)

    #Columns
    col1, col2, col3 = st.columns([1,0.1,3])

    with col1:

        #Viz Photo
        photo_path = f'./player_photo/{selected_player}.png'

        #Check if photo available
        if os.path.exists(photo_path):
            #visualize image
            st.image(photo_path, use_container_width=True)

        #If fail, use the error photo
        else:
            photo_path = './player_photo/error.png'
            st.image(photo_path, use_container_width=True)

        #Player Bio
        st.markdown(f"<p style='text-align: center;'>Player Bio & Historical Team (No data)</p>", unsafe_allow_html=True)
            

    with col2:
        st.empty()

        
    with col3:

        #col3_1, col2_2 = col3.columns((2,1))


        #Visualize shots
        tab1, tab2, tab3, tab4, tab5, tab6, tab7 = col3.tabs(["All Shots", "Restricted Area", "Paint Area", "Short Midrange", "Long Midrange", "Corner 3", "ATB"])
    

        # --- TAB 1: All shots ---
        with tab1:
            chart_col, metric_col = st.columns((2, 1))

            with chart_col:
                data = viz_shot(df_shot, selected_player)

            with metric_col:
                st.header("Shot Performance")
                st.metric(label="Shots Attempt", value=data['total_shot_attempt'])
                st.metric(label="Successfull Shots", value=data['total_shot_made'])
                st.metric(label="Failed Shots", value=data['total_shot_fail'])
                st.metric(label="Shot Accuracy", value=data['shot_accuracy'])

        with tab2:
            chart_col, metric_col = st.columns((2, 1))

            with chart_col:
                data = viz_shot(df_shot, selected_player, zone="Zone_1")

            with metric_col:
                st.header("Shot Performance")
                st.metric(label="Shots Attempt", value=data['total_shot_attempt'])
                st.metric(label="Successfull Shots", value=data['total_shot_made'])
                st.metric(label="Failed Shots", value=data['total_shot_fail'])
                st.metric(label="Shot Accuracy", value=data['shot_accuracy'])

        with tab3:
            chart_col, metric_col = st.columns((2, 1))

            with chart_col:
                data = viz_shot(df_shot, selected_player, zone="Zone_2")

            with metric_col:
                st.header("Shot Performance")
                st.metric(label="Shots Attempt", value=data['total_shot_attempt'])
                st.metric(label="Successfull Shots", value=data['total_shot_made'])
                st.metric(label="Failed Shots", value=data['total_shot_fail'])
                st.metric(label="Shot Accuracy", value=data['shot_accuracy'])


        with tab4:
            chart_col, metric_col = st.columns((2, 1))

            with chart_col:
                data = viz_shot(df_shot, selected_player, zone="Zone_3")

            with metric_col:
                st.header("Shot Performance")
                st.metric(label="Shots Attempt", value=data['total_shot_attempt'])
                st.metric(label="Successfull Shots", value=data['total_shot_made'])
                st.metric(label="Failed Shots", value=data['total_shot_fail'])
                st.metric(label="Shot Accuracy", value=data['shot_accuracy'])


        with tab5:
            chart_col, metric_col = st.columns((2, 1))

            with chart_col:
                data = viz_shot(df_shot, selected_player, zone="Zone_4")

            with metric_col:
                st.header("Shot Performance")
                st.metric(label="Shots Attempt", value=data['total_shot_attempt'])
                st.metric(label="Successfull Shots", value=data['total_shot_made'])
                st.metric(label="Failed Shots", value=data['total_shot_fail'])
                st.metric(label="Shot Accuracy", value=data['shot_accuracy'])


        with tab6:
            chart_col, metric_col = st.columns((2, 1))

            with chart_col:
                data = viz_shot(df_shot, selected_player, zone="Zone_5")

            with metric_col:
                st.header("Shot Performance")
                st.metric(label="Shots Attempt", value=data['total_shot_attempt'])
                st.metric(label="Successfull Shots", value=data['total_shot_made'])
                st.metric(label="Failed Shots", value=data['total_shot_fail'])
                st.metric(label="Shot Accuracy", value=data['shot_accuracy'])


        with tab7:
            chart_col, metric_col = st.columns((2, 1))

            with chart_col:
                data = viz_shot(df_shot, selected_player, zone="Zone_6")

            with metric_col:
                st.header("Shot Performance")
                st.metric(label="Shots Attempt", value=data['total_shot_attempt'])
                st.metric(label="Successfull Shots", value=data['total_shot_made'])
                st.metric(label="Failed Shots", value=data['total_shot_fail'])
                st.metric(label="Shot Accuracy", value=data['shot_accuracy'])

    #Text
    st.header("Upcoming Patch", divider=True)
    st.write('''
            - Filter Feature (To search a certain player with shot zone capabilities)
            - ChatGPT capabilities to ask player strength / weakness
            - Distinguishing Metric for right / left shot zone
            - Distinguishing Type of shots (Layup, etc) in each zone
            - Player boxscore in each match
                ''')
    st.write('Thanks for visiting ! if you like the board and want to support to keep the server running you can donate to https://saweria.co/fhanavi')


        
        





