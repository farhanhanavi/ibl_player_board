import matplotlib.pyplot as plt
import streamlit as st
import numpy as np
from draw_court import *

RESTRICTED_R    = 1.25
THREE_R         = 6.75

#Visuzalize shot
def viz_shot(dataframe, zone=False):

    
    #Classify Zone
    def get_zone(x, y):
        d = np.hypot(x - BASKET_X, y - BASKET_Y)

        # side: facing the hoop, bottom = "Left", top = "Right"
        side = "Left" if y < BASKET_Y else "Right"

        # 1. Restricted
        if d <= RESTRICTED_R:
            return "Zone_1"

        # in the paint?
        in_paint = (0 <= x <= key_width) and (key_y_start <= y <= key_y_stop)

        # 2. Paint but not restricted
        if in_paint:
            return "Zone_2"

        # 3PT or 2PT (approx – real FIBA corner is slightly shorter)
        is_three = d >= THREE_R

        if not is_three:
            # 2-point midrange
            if d <= 4.5:
                return f"Zone_3"
            else:
                return f"Zone_4"
        else:
            # 3-point
            if y <= 2.0 or y >= COURT_WIDTH - 2.0:
                return f"Zone_5"
            else:
                if y < COURT_WIDTH/3:
                    pos = "Left"
                elif y < 2*COURT_WIDTH/3:
                    pos = "Center"
                else:
                    pos = "Right"
                return f"Zone_6"


    #Classify Zone
    dataframe['zone'] = dataframe.apply(lambda x: get_zone(x['adjusted_x_halfcourt_left'], x['adjusted_y_halfcourt_left']), axis=1)

    #Filter data by zone
    if zone:
        dataframe = dataframe[dataframe['zone'] == zone]

    #Calculate Performance
    total_shot_attempt  = dataframe.shape[0]
    total_shot_made     = dataframe[dataframe['shot_result'] == 1].shape[0]
    total_shot_fail     = dataframe[dataframe['shot_result'] != 1].shape[0]
    if total_shot_attempt > 0:
        shot_accuracy       = round((total_shot_made / total_shot_attempt) * 100, 2)
    else:
        shot_accuracy       = 0

    performance_data    = {
        'total_shot_attempt' : total_shot_attempt,
        'total_shot_made'    : total_shot_made,
        'total_shot_fail'    : total_shot_fail,
        'shot_accuracy'      : shot_accuracy
    }

    


    #Draw Property
    x             = dataframe['adjusted_x_halfcourt_left']
    y             = dataframe['adjusted_y_halfcourt_left']
    marker        = dataframe['marker']
    color         = dataframe['color']

    #Draw court
    fig, ax = draw_court_canvas()

    #Draw Shots
    for x_point, y_point, m, c in zip(x, y, marker, color):
        ax.scatter(x_point, y_point, s=120, linewidth=2, marker=m, c=c)

    # Show in Streamlit
    st.pyplot(fig, use_container_width=True)

    #Return metric
    return performance_data




    # m1, m2, m3, m4, m5 = col2.columns((1,1,1,1,1))


    # #Player Data
    # player_data = get_player_stat(df_player, selected_player)

    # m1.metric(label = 'Total Games'             , value = player_data['match_id'].values)
    # m1.metric(label = 'Avg. Defensive Rebound'  , value = player_data['game_rebounds_defensive'].values)


    # m2.metric(label = 'Avg. Minutes'            , value = round(player_data['game_minutes_timedelta'].values[0], 2))
    # m2.metric(label = 'Avg. Offensive Rebound'  , value = round(player_data['game_rebounds_offensive'].values[0], 2))
    # m2.metric(label = 'Field Goal Attempted'    , value = player_data['game_field_goals_attempted'].values)
    # m2.metric(label = '2PT Attempted'           , value = player_data['game_two_pointers_attempted'].values)
    # m2.metric(label = '3PT Attempted'           , value = player_data['game_three_pointers_attempted'].values)
    # m2.metric(label = 'FT Attempted'            , value = player_data['game_free_throws_attempted'].values)

    # m3.metric(label = 'Avg. Points'             , value = round(player_data['game_points'].values[0],2))
    # m3.metric(label = 'Avg. Rebound'            , value = round(player_data['total_rebound'].values[0],2))
    # m3.metric(label = 'Field Goal Made'         , value = player_data['game_field_goals_made'].values)
    # m3.metric(label = '2PT Made'                , value = player_data['game_two_pointers_made'].values)
    # m3.metric(label = '3PT Made'                , value = player_data['game_three_pointers_made'].values)
    # m3.metric(label = 'FT Made'                 , value = player_data['game_free_throws_made'].values)

    # m4.metric(label = 'Avg. Assists'            , value = round(player_data['game_assists'].values[0],2))
    # m4.metric(label = 'Avg. Turnovers'          , value = round(player_data['game_turnovers'].values[0],2))
    # m4.metric(label = 'Field Goal %'            , value = round(player_data['field_goal_pct'].values[0] * 100,2))
    # m4.metric(label = '2PT %'                   , value = round(player_data['2pt_pct'].values[0] * 100,2))
    # m4.metric(label = '3PT %'                   , value = round(player_data['3pt_pct'].values[0] * 100,2))
    # m4.metric(label = 'FT %'                    , value = round(player_data['ft_pct'].values[0] * 100,2))

    # m5.metric(label = 'Avg. Blocks'         , value =  round(player_data['game_blocks'].values[0],2))
    # m5.metric(label = 'Avg. Steals'         , value =  round(player_data['game_steals'].values[0],2))