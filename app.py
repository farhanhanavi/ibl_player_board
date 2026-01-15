import streamlit    as st
import pandas       as pd
import os
from sqlalchemy import create_engine, text

from shot_eda import viz_shot
from db import *

from player_eda import *
from player_photo import *



##################################
#                               #
#          Load Data            #
#                               #
##################################

@st.cache_resource
def get_engine(show_spinner=False):
    url = f"postgresql://{USER}:{PASSOWRD}@{HOST}:{PORT}/{DBNAME}?sslmode={SSLMODE}"
    engine = create_engine(url, pool_pre_ping=True)
    return engine


@st.cache_data
def get_player_list():
    engine  = get_engine()
    query   = "SELECT DISTINCT player_name FROM shot_table ORDER BY player_name;"
    df      = pd.read_sql(query, engine)
    return df["player_name"].tolist()


@st.cache_data(show_spinner=False)
def get_player_shots(player_name: str, season: str):

    #Start engine vroom vroom
    engine = get_engine()
    query = text("""
                        SELECT
                            match_id,
                            game_type,
                            shot_point,
                            shot_result,
                            adjusted_x_halfcourt_left,
                            adjusted_y_halfcourt_left,
                            color,
                            marker
                        FROM 
                            shot_table
                        WHERE 
                            player_name = :player_name
                            AND
                            game_type = :season
    """)
    df = pd.read_sql(query, engine, params={"player_name": player_name, "season": season})
    return df


@st.cache_data(show_spinner=False)
def get_player_stat(player_name: str, season: str):

    #Start engine vroom vroom
    engine = get_engine()
    query = text("""
                        SELECT
                            *
                        FROM 
                            playerstat_table
                        WHERE 
                            player_name = :player_name
                            AND
                            game_type = :season
    """)
    df = pd.read_sql(query, engine, params={"player_name": player_name, "season": season})
    return df



##################################
#                               #
#          Streamlit App        #
#                               #
##################################

#Page Title
st.set_page_config(page_title='IBL Player Performance Dashboard V1',  layout='wide')
st.title("IBL Player Performance Dashboard v1")

#Playerlist
unique_player             = get_player_list()

#Filter Box
selected_player = st.selectbox("Select Player", unique_player)

#Gametype Toggle
season_selectbox = st.selectbox("Game Types", ["Regular Season", "Playoff"],index=0)
mapping = {
    "Regular Season": "regular_season",
    "Playoff"       : "playoffs"
}
selected_season = mapping[season_selectbox]





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
    player_shot_data = get_player_shots(selected_player, selected_season)
    player_stat_data = get_player_stat(selected_player, selected_season)

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



    #Player Performance
    st.header("Player Performance Metric", divider=True)
    player_performance_table = player_performance_summary(player_stat_data)
    
    col1, col2, col3, col4 = st.columns(4)


    with col1:
        st.metric(label="Total Games"           , value=player_performance_table['match_id'])
        st.metric(label="FG Attempted"          , value=player_performance_table['game_field_goals_attempted'])
        st.metric(label="3P Attempted"          , value=player_performance_table['game_three_pointers_attempted'])
        st.metric(label="2P Attempted"          , value=player_performance_table['game_two_pointers_attempted'])
        st.metric(label="FT Attempted"          , value=player_performance_table['game_free_throws_attempted'])
        st.metric(label="Avg. Defensive Rebound"          , value=player_performance_table['game_rebounds_defensive'])
        st.metric(label="Avg. Assist"       , value=player_performance_table['game_assists'])
        st.metric(label="Avg. Blocks Received"       , value=player_performance_table['game_blocks_received'])

    with col2:
        st.metric(label="Avg. Minutes Played"   , value=player_performance_table['game_minutes_timedelta'])
        st.metric(label="Successfull FG"        , value=player_performance_table['game_field_goals_made'])
        st.metric(label="Successfull 3P"        , value=player_performance_table['game_three_pointers_made'])
        st.metric(label="Successfull 2P"        , value=player_performance_table['game_two_pointers_made'])
        st.metric(label="Successfull FT"        , value=player_performance_table['game_free_throws_made'])
        st.metric(label="Avg. Offensive Rebound"          , value=player_performance_table['game_rebounds_offensive'])
        st.metric(label="Avg. TO"           , value=player_performance_table['game_turnovers'])
        st.metric(label="Avg. Foul"         , value=player_performance_table['game_fouls_personal'])
        

    with col3:
        st.metric(label="Avg. Point"            , value=player_performance_table['game_points'])
        st.metric(label="FG %"                  , value=player_performance_table['field_goal_pct'])
        st.metric(label="3P %"                  , value=player_performance_table['3pt_pct'])
        st.metric(label="2P %"                  , value=player_performance_table['3pt_pct'])
        st.metric(label="FT %"                  , value=player_performance_table['ft_pct'])
        st.metric(label="Avg. Rebound"                    , value=player_performance_table['total_rebound'])
        st.metric(label="Avg. Steals"       , value=player_performance_table['game_steals'])
        st.metric(label="Avg. Fouls On"     , value=player_performance_table['game_fouls_on'])

    with col4:
        st.metric(label="Avg. Point 2nd Chance" , value=player_performance_table['game_points_second_chance'])
        st.metric(label="Avg. Blocks"       , value=player_performance_table['game_blocks'])
    

    #Box Score
    st.header("Player Match Box Score", divider=True)
    player_boxscore_list = ibl_boxscore_table(player_stat_data)
    st.dataframe(data=player_boxscore_list, use_container_width=True, hide_index=True)

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


        
        





