import numpy as np
import pandas as pd
from datetime import datetime


def player_performance_summary(input_dataframe):

    
    
    player_stat = input_dataframe.groupby('player_name').agg(
            {
                'match_id'                   : 'count', #Total Games
                'game_minutes'               : 'mean', #Avg. Minutes Played
                
                'fga' : 'sum', #FG Attempted
                'fgm' : 'sum', 
                
                'three_pa' : 'sum',
                'three_pm' : 'sum',
                
                'two_pa' : 'sum',
                'two_pm' : 'sum',
                
                'fta' : 'sum',
                'ftm' : 'sum',

                'dreb' : 'mean',
                'oreb' : 'mean',
                'reb'  : 'mean',

                'ast'               : 'mean',
                'tov'               : 'mean',
                'stl'               : 'mean',
                'blk'               : 'mean',
                'blocks_received'   : 'mean',
                'pf'                : 'mean',
                'fouls_drawn'                  : 'mean',
                
                'total_points'               : 'mean',
                'total_points_paint'         : 'mean',
                'total_points_fastbreak'     : 'mean',
                'total_points_second_chance' : 'mean'
                
            }
        ).reset_index()

    player_stat['fg_pct']   = np.where(
                                                player_stat['fga'] == 0, 
                                                0, 
                                                round(player_stat['fgm'] / player_stat['fga'] * 100,2)
                                            )
    
    player_stat['two_p_pct']    = np.where(
                                                player_stat['two_pa'] == 0, 
                                                0, 
                                                round(player_stat['two_pm'] / player_stat['two_pa'] * 100,2)
                                            )
    
    player_stat['three_p_pct']          = np.where(
                                                player_stat['three_pa'] == 0, 
                                                0, 
                                                round(player_stat['three_pm'] / player_stat['three_pa'] * 100,2)
                                            )
    player_stat['ft_pct']           = np.where(
                                                player_stat['fta'] == 0, 
                                                0, 
                                                round(player_stat['ftm'] / player_stat['fta'] * 100,2)
                                            )
    
    player_stat[player_stat.select_dtypes(include=['float']).columns] = player_stat.select_dtypes(include=['float']).round(2)
    return player_stat