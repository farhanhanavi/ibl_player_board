import matplotlib.pyplot as plt
import streamlit as st
import numpy as np
import matplotlib.patches as mpatches




FIBA_HALF_LENGTH = 28.0                         # baseline to midline
FIBA_WIDTH       = 15.0
hoop_x           = FIBA_HALF_LENGTH - 1.575   # 1.575m in from the right baseline
hoop_y           = FIBA_WIDTH / 2
corner_y_min     = 0.9
corner_y_max     = FIBA_WIDTH - 0.9
r3               = 6.75


#                               #
#       SHOT VIZ FUNCTION       #
#                               #

#Visuzalize shot
def viz_shot(dataframe, input_player_name):

    #Data Filter
    filtered_data = dataframe.query("player_name == @input_player_name")
    
    #Variables
    x             = filtered_data['halfcourt_xloc']
    y             = filtered_data['halfcourt_yloc']
    marker        = filtered_data['marker']
    color         = filtered_data['color']
    point         = filtered_data['shot_point']

    #Plot
    scale   = 0.15
    fig, ax = plt.subplots(figsize=(28*scale, 15*scale))

    for x_point, y_point, m, c in zip(x, y, marker, color):
        ax.scatter(x_point, y_point, s=20, marker=m, c=c)

    # Set fixed axis limits to match half-court size
    ax.set_xlim(14, 28)    # court length (HALF COURT)
    ax.set_ylim(0, 15)     # court width (HALF COURT)

    #Legend
    # After plotting your scatter points
    #twopt_patch = mpatches.Patch(color='blue', label='2pt Shot')
    #threept_path= mpatches.Patch(color='orange', label='3pt Shot')
    #ax.legend(handles=[twopt_patch, threept_path], loc='upper left')

    #Delete ticks
    ax.set_xticks([])
    ax.set_xticklabels([])
    ax.set_yticks([])
    ax.set_yticklabels([])

    # Corner "straight" 3-point lines
    ax.plot(
                [(FIBA_HALF_LENGTH - 0.9), (FIBA_HALF_LENGTH - 0.9)], [corner_y_min, corner_y_max], 
                lw=1, 
                color='black'
            )
    
    # Arc curving to the LEFT side now
    t = np.linspace(np.pi/2, 3*np.pi/2, 361)   # flip the angle range
    arc_x = hoop_x + r3 * np.cos(t)
    arc_y = hoop_y + r3 * np.sin(t)
    
    mask = (arc_x <= FIBA_HALF_LENGTH - 0.9)   # clip so arc stops at corner line
    ax.plot(arc_x[mask], arc_y[mask], lw=1, color='black')

    # Show in Streamlit
    st.pyplot(fig, use_container_width=False)



















#Player Stat
def get_player_stat(dataframe, input_player_name):
    player_stat = dataframe.query("player_name == @input_player_name").groupby('player_name').agg(
            {
                'match_id'                   : 'count',
                'game_minutes_timedelta'     : 'mean',
                
                'game_field_goals_attempted' : 'sum',
                'game_field_goals_made'      : 'sum',
                

                'game_three_pointers_attempted' : 'sum',
                'game_three_pointers_made'      : 'sum',
                
                
                'game_two_pointers_attempted' : 'sum',
                'game_two_pointers_made'      : 'sum',
                
                
                'game_free_throws_attempted' : 'sum',
                'game_free_throws_made'      : 'sum',

                'game_rebounds_defensive' : 'mean',
                'game_rebounds_offensive' : 'mean',
                'total_rebound'           : 'mean',

                'game_assists'                   : 'mean',
                'game_turnovers'                 : 'mean',
                'game_steals'                    : 'mean',
                'game_blocks'                    : 'mean',
                'game_blocks_received'           : 'mean',
                'game_fouls_personal'            : 'mean',
                'game_fouls_on'                  : 'mean',
                'game_points'                    : 'mean',
                'game_points_second_chance'      : 'mean',
                
            }
        ).reset_index()

    player_stat['field_goal_pct'] = player_stat['game_field_goals_made'] / player_stat['game_field_goals_attempted']
    player_stat['2pt_pct']        = player_stat['game_two_pointers_made'] / player_stat['game_two_pointers_attempted']
    player_stat['3pt_pct']        = player_stat['game_three_pointers_made'] / player_stat['game_three_pointers_attempted']
    player_stat['ft_pct']         = player_stat['game_free_throws_made'] / player_stat['game_free_throws_attempted']

    return player_stat