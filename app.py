import os
from dotenv import load_dotenv
import streamlit    as st
import pandas       as pd

from shot_eda import viz_shot
from db import get_engine, get_player_list, get_player_shots, get_player_stat
from player_eda import player_performance_summary
from player_photo import *


# Load .env credentials
load_dotenv()
HOST        = os.getenv("PG_HOST")
PORT        = os.getenv("PG_PORT")
DBNAME      = os.getenv("PG_DBNAME")
USER        = os.getenv("PG_USER")
PASSWORD    = os.getenv("PG_PASSWORD")
SSLMODE     = os.getenv("PG_SSLMODE", "require")


#Load Enginge
postgre_engine = get_engine(USER, PASSWORD, HOST, PORT, DBNAME, SSLMODE)


##################################
#                               #
#          Streamlit App        #
#                               #
##################################

#Page Title
st.set_page_config(page_title='IBL Player Performance Dashboard',  layout='wide')
st.markdown(""" <style>
/* Remove the 3-dot menu */
#MainMenu {display: none !important;}

/* Remove footer */
footer {display: none !important;}

/* Remove the header bar */
header {display: none !important;}

/* 🔴 THIS removes the "None" badge */
div[data-testid="stStatusWidget"] {
    display: none !important;
}

/* Extra safety (some themes wrap it) */
div[data-testid="stToolbar"] {
    display: none !important;
}
</style>"""
, unsafe_allow_html=True)
st.title("IBL Player Performance Dashboard")
st.text("Dasboard by Farhan Hanavi")

##################################
#                               #
#          Header.              #
#                               #
##################################

#Season Toggle
season_selectbox = st.selectbox("IBL Season", ["IBL Gopay 2025", "IBL Gopay 2026"], index=0)
season_mapping = {
    "IBL Gopay 2025"    : "ibl_gopay_2025",
    "IBL Gopay 2026"    : "ibl_gopay_2026"
}
selected_season = season_mapping[season_selectbox]

#Player Toggle
#Selecting player based on the season input
unique_player   = get_player_list(postgre_engine, selected_season)
selected_player = st.selectbox("Select Player", unique_player, index=0)

##################################
#                               #
#          Main App             #
#                               #
##################################


    
if (selected_player and selected_season):

    #Sub Header
    #st.subheader(selected_player)
    st.markdown(f"<h2 style='text-align: center;'>{selected_player}</h2>", unsafe_allow_html=True)

    #Load Data
    player_shot_data = get_player_shots(postgre_engine, selected_player, selected_season)
    player_stat_data = get_player_stat(postgre_engine, selected_player, selected_season)

    #Clean data
    player_stat_data = player_stat_data.drop(columns = ['game_season','shirt_number','position'])

    ##################################
    #                               #
    #          Column 1             #
    #                               #
    ##################################


    #Columns
    col1, col2, col3 = st.columns([1,0.1,3])

    #Player Photo & Bio
    with col1:

        photo_path = f'./player_photo/{selected_player}.png'

        #Check if photo available
        if os.path.exists(photo_path):
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

        #Visualize shots
        tab1, tab2, tab3, tab4, tab5, tab6, tab7 = col3.tabs(["All Shots", "Restricted Area", "Paint Area", "Short Midrange", "Long Midrange", "Corner 3", "ATB"])
    

        # --- TAB 1: All shots ---
        with tab1:
            chart_col, metric_col = st.columns((2, 1))

            with chart_col:
                data = viz_shot(player_shot_data)

            with metric_col:
                st.header("Shot Performance")
                st.metric(label="Shots Attempt", value=data['total_shot_attempt'])
                st.metric(label="Successfull Shots", value=data['total_shot_made'])
                st.metric(label="Failed Shots", value=data['total_shot_fail'])
                st.metric(label="Shot Accuracy", value=data['shot_accuracy'])

        with tab2:
            chart_col, metric_col = st.columns((2, 1))

            with chart_col:
                data = viz_shot(player_shot_data, zone="Zone_1")

            with metric_col:
                st.header("Shot Performance")
                st.metric(label="Shots Attempt", value=data['total_shot_attempt'])
                st.metric(label="Successfull Shots", value=data['total_shot_made'])
                st.metric(label="Failed Shots", value=data['total_shot_fail'])
                st.metric(label="Shot Accuracy", value=data['shot_accuracy'])

        with tab3:
            chart_col, metric_col = st.columns((2, 1))

            with chart_col:
                data = viz_shot(player_shot_data, zone="Zone_2")

            with metric_col:
                st.header("Shot Performance")
                st.metric(label="Shots Attempt", value=data['total_shot_attempt'])
                st.metric(label="Successfull Shots", value=data['total_shot_made'])
                st.metric(label="Failed Shots", value=data['total_shot_fail'])
                st.metric(label="Shot Accuracy", value=data['shot_accuracy'])


        with tab4:
            chart_col, metric_col = st.columns((2, 1))

            with chart_col:
                data = viz_shot(player_shot_data, zone="Zone_3")

            with metric_col:
                st.header("Shot Performance")
                st.metric(label="Shots Attempt", value=data['total_shot_attempt'])
                st.metric(label="Successfull Shots", value=data['total_shot_made'])
                st.metric(label="Failed Shots", value=data['total_shot_fail'])
                st.metric(label="Shot Accuracy", value=data['shot_accuracy'])


        with tab5:
            chart_col, metric_col = st.columns((2, 1))

            with chart_col:
                data = viz_shot(player_shot_data, zone="Zone_4")

            with metric_col:
                st.header("Shot Performance")
                st.metric(label="Shots Attempt", value=data['total_shot_attempt'])
                st.metric(label="Successfull Shots", value=data['total_shot_made'])
                st.metric(label="Failed Shots", value=data['total_shot_fail'])
                st.metric(label="Shot Accuracy", value=data['shot_accuracy'])


        with tab6:
            chart_col, metric_col = st.columns((2, 1))

            with chart_col:
                data = viz_shot(player_shot_data, zone="Zone_5")

            with metric_col:
                st.header("Shot Performance")
                st.metric(label="Shots Attempt", value=data['total_shot_attempt'])
                st.metric(label="Successfull Shots", value=data['total_shot_made'])
                st.metric(label="Failed Shots", value=data['total_shot_fail'])
                st.metric(label="Shot Accuracy", value=data['shot_accuracy'])


        with tab7:
            chart_col, metric_col = st.columns((2, 1))

            with chart_col:
                data = viz_shot(player_shot_data, zone="Zone_6")

            with metric_col:
                st.header("Shot Performance")
                st.metric(label="Shots Attempt", value=data['total_shot_attempt'])
                st.metric(label="Successfull Shots", value=data['total_shot_made'])
                st.metric(label="Failed Shots", value=data['total_shot_fail'])
                st.metric(label="Shot Accuracy", value=data['shot_accuracy'])


    ##################################
    #                               #
    #       Player Performance      #
    #                               #
    ##################################


    #Player Performance
    st.header("Player Performance Metric", divider=True)
    player_performance_table = player_performance_summary(player_stat_data)
    
    col1, col2, col3, col4 = st.columns(4)


    with col1:
        st.metric(label="Total Games"                       , value=player_performance_table['match_id'])
        st.metric(label="FG Attempted"                      , value=player_performance_table['fga'])
        st.metric(label="3P Attempted"                      , value=player_performance_table['three_pa'])
        st.metric(label="2P Attempted"                      , value=player_performance_table['two_pa'])
        st.metric(label="FT Attempted"                      , value=player_performance_table['fta'])
        st.metric(label="Avg. Defensive Rebound"            , value=player_performance_table['dreb'])
        st.metric(label="Avg. Assist"                       , value=player_performance_table['ast'])
        st.metric(label="Avg. Blocks Received"              , value=player_performance_table['blocks_received'])

    with col2:
        st.metric(label="Avg. Minutes Played"               , value=player_performance_table['game_minutes'])
        st.metric(label="Successfull FG"                    , value=player_performance_table['fgm'])
        st.metric(label="Successfull 3P"                    , value=player_performance_table['three_pm'])
        st.metric(label="Successfull 2P"                    , value=player_performance_table['two_pm'])
        st.metric(label="Successfull FT"                    , value=player_performance_table['ftm'])
        st.metric(label="Avg. Offensive Rebound"            , value=player_performance_table['oreb'])
        st.metric(label="Avg. TO"                           , value=player_performance_table['tov'])
        st.metric(label="Avg. Foul"                         , value=player_performance_table['pf'])
        
    with col3:
        st.metric(label="Avg. Point"                , value=player_performance_table['total_points'])
        st.metric(label="FG %"                      , value=player_performance_table['fg_pct'])
        st.metric(label="3P %"                      , value=player_performance_table['three_p_pct'])
        st.metric(label="2P %"                      , value=player_performance_table['two_p_pct'])
        st.metric(label="FT %"                      , value=player_performance_table['ft_pct'])
        st.metric(label="Avg. Rebound"              , value=player_performance_table['reb'])
        st.metric(label="Avg. Steals"               , value=player_performance_table['stl'])
        st.metric(label="Avg. Fouls On"             , value=player_performance_table['fouls_drawn'])

    with col4:
        st.metric(label="Avg. Point 2nd Chance"     , value=player_performance_table['total_points_second_chance'])
        st.metric(label="Avg. Blocks"               , value=player_performance_table['blk'])


    ##################################
    #                               #
    #       Player Box score        #
    #                               #
    ##################################


    #Box Score
    st.header("Player Match Box Score", divider=True)
    st.markdown(
                """
                <style>
                [data-testid="stElementToolbar"] {
                    display: none;
                }
                </style>
                """,
                unsafe_allow_html=True
            )
    st.dataframe(data=player_stat_data, use_container_width=True, hide_index=True)

    #Text
    st.header("Upcoming Patch", divider=True)
    st.write('''
            - Filter Feature (To search a certain player with shot zone capabilities)
            - ChatGPT capabilities to ask player strength / weakness
            - Differentiating metric for right / left shot zone
            - Differentiating type of shots (Layup, etc) in each zone
            - Advanced Stats
            - Other stat (from match player motion capture)
                ''')
    st.write('Thanks for visiting ! if you like the board and want to support to keep the server running you can donate to https://saweria.co/fhanavi')


        
        





