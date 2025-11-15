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