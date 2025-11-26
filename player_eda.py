import numpy as np
import pandas as pd
from datetime import datetime

#Player Stat Box Score
def ibl_boxscore_table(input_dataframe):


    input_dataframe['game_field_goals_failed']      = input_dataframe['game_field_goals_attempted'] - input_dataframe['game_field_goals_made']
    input_dataframe['field_goal_box']               = ( input_dataframe['game_field_goals_made'].astype(str)+ '-' +input_dataframe['game_field_goals_failed'].astype(str) )
    input_dataframe['field_goal_pct']               = np.where(
                                                            input_dataframe['game_field_goals_attempted'] == 0, 
                                                            0, 
                                                            round(input_dataframe['game_field_goals_made'] / input_dataframe['game_field_goals_attempted'] * 100,2)
                                                        )
    input_dataframe['field_goal_pct']               = input_dataframe['field_goal_pct'].astype('str') + '%'
    
    input_dataframe['game_two_pointers_fail']       = input_dataframe['game_two_pointers_attempted'] - input_dataframe['game_two_pointers_made']
    input_dataframe['2pt_box']                      = ( input_dataframe['game_two_pointers_made'].astype(str)+ '-' +input_dataframe['game_two_pointers_fail'].astype(str) )
    input_dataframe['2pt_pct']                      = np.where(
                                                            input_dataframe['game_two_pointers_attempted'] == 0, 
                                                            0, 
                                                            round(input_dataframe['game_two_pointers_made'] / input_dataframe['game_two_pointers_attempted'] * 100,2)
                                                        )
    input_dataframe['2pt_pct']                          = input_dataframe['2pt_pct'].astype('str') + '%'

    input_dataframe['game_three_pointers_fail']         = input_dataframe['game_three_pointers_attempted'] - input_dataframe['game_three_pointers_made']
    input_dataframe['3pt_box']                          = ( input_dataframe['game_three_pointers_made'].astype(str)+ '-' +input_dataframe['game_three_pointers_fail'].astype(str) )
    input_dataframe['3pt_pct']                          = np.where(
                                                            input_dataframe['game_three_pointers_attempted'] == 0, 
                                                            0, 
                                                            round(input_dataframe['game_three_pointers_made'] / input_dataframe['game_three_pointers_attempted'] * 100,2)
                                                        )
    input_dataframe['3pt_pct']                          = input_dataframe['3pt_pct'].astype('str') + '%'

    input_dataframe['game_free_throws_pointers_fail']   = input_dataframe['game_free_throws_attempted'] - input_dataframe['game_free_throws_made']
    input_dataframe['ft_box']                           = ( input_dataframe['game_free_throws_made'].astype(str)+ '-' +input_dataframe['game_free_throws_pointers_fail'].astype(str) )
    input_dataframe['ft_pct']                           = np.where(
                                                            input_dataframe['game_free_throws_attempted'] == 0, 
                                                            0, 
                                                            round(input_dataframe['game_free_throws_made'] / input_dataframe['game_free_throws_attempted'] * 100,2)
                                                        )
    input_dataframe['ft_pct']                           = input_dataframe['ft_pct'].astype('str') + '%'



    input_dataframe = input_dataframe[[
                'match_id', 'match_date','venue','home_team','away_team','game_minutes','game_points',
                'field_goal_box','field_goal_pct',
                '2pt_box', '2pt_pct',
                '3pt_box', '3pt_pct',
                'ft_box', 'ft_pct',
                'total_rebound', 'game_assists', 'game_turnovers', 'game_steals', 'game_blocks', 'game_blocks_received', 'game_fouls_personal', 'game_fouls_on'
                ]]


    return input_dataframe




def player_performance_summary(input_dataframe):

    #Function to change 23:10 into total seconds / total minutes
    def get_seconds(input_text):
        dt = datetime.strptime(input_text, "%M:%S")
        total_seconds = dt.minute * 60 + dt.second
        return total_seconds

    # Prepend hour "00:" → results in "00:32:11"
    input_dataframe['game_seconds']                 = input_dataframe['game_minutes'].apply(lambda x: get_seconds(x))
    input_dataframe['game_minutes_timedelta']       = input_dataframe['game_seconds'].apply(lambda x: round(x/60,2))
    

    player_stat = input_dataframe.groupby('player_name').agg(
            {
                'match_id'                   : 'count',
                'game_minutes_timedelta'        : 'mean',
                
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

    player_stat['field_goal_pct']   = np.where(
                                                player_stat['game_field_goals_attempted'] == 0, 
                                                0, 
                                                round(player_stat['game_field_goals_made'] / player_stat['game_field_goals_attempted'] * 100,2)
                                            )
    
    player_stat['2pt_pct']          = np.where(
                                                player_stat['game_two_pointers_attempted'] == 0, 
                                                0, 
                                                round(player_stat['game_two_pointers_made'] / player_stat['game_two_pointers_attempted'] * 100,2)
                                            )
    player_stat['3pt_pct']          = np.where(
                                                player_stat['game_three_pointers_attempted'] == 0, 
                                                0, 
                                                round(player_stat['game_three_pointers_made'] / player_stat['game_three_pointers_attempted'] * 100,2)
                                            )
    player_stat['ft_pct']           = np.where(
                                                player_stat['game_free_throws_attempted'] == 0, 
                                                0, 
                                                round(player_stat['game_free_throws_made'] / player_stat['game_free_throws_attempted'] * 100,2)
                                            )
    
    player_stat[player_stat.select_dtypes(include=['float']).columns] = player_stat.select_dtypes(include=['float']).round(2)
    return player_stat