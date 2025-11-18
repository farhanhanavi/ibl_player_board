import math
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Circle, Polygon, Path, Rectangle


# Viz Setting
line_width = 3
line_color = 'black'
SCALE      = 1

# FIBA half-court dimensions (meters)
COURT_HEIGHT = 15.0     
COURT_WIDTH  = 14.0   

# BASKET POSITION
BASKET_X     = 1.575    # Basket x position
BASKET_Y     = 7.5      # Basket y position

# Free throw lane (key/paint) - FIBA dimensions
key_width   = 5.9
key_height  = 4.9
key_y_start = BASKET_Y - (key_height/2)  #free throw box y bottom  point
key_y_stop  = BASKET_Y + (key_height/2)  #free throw box y top point

#Other
bottom_y_3pt_stop = 0.9
top_y_3pt_stop    = COURT_HEIGHT - bottom_y_3pt_stop

#3PT
ARC_3PT                     = 6.75         # FIBA arc 3PT distance
ARC_BASKET                  = 1.25         # FIBA basket area arc
ARC_BASKET_STOP_X           = 1.575
ARC_BASKET_STOP_Y_TOP       = BASKET_Y - ARC_BASKET
ARC_BASKET_STOP_Y_BOTTOM    = BASKET_Y + ARC_BASKET

#FT
free_throw_radius   = 1.8
center_court_radius = 1.8


'''
Calculate where the ARC_3PT meets stops and become a straight horizontal line (x_stop)
Top and bottom x_stop point is the same, here is using the y bottom stop
'''

# (h,k) is the circle center
# (x,y) is the coordinate where the arc stops

# r**2                = (x - h)**2         + (y-k)**2

# ARC_3PT**2                                                            = (x - BASKET_X)**2    + (bottom_y_3pt_stop - BASKET_Y)**2
# ARC_3PT**2 - (bottom_y_3pt_stop - BASKET_Y)**2                        = (x - BASKET_X)**2
# np.sqrt(ARC_3PT**2 - (bottom_y_3pt_stop - BASKET_Y)**2)               = (x - BASKET_X)
# np.sqrt(ARC_3PT**2 - (bottom_y_3pt_stop - BASKET_Y)**2) + BASKET_X    = x
x_stop            = np.sqrt(ARC_3PT**2 - (bottom_y_3pt_stop - BASKET_Y)**2) + BASKET_X


'''
Finding X (x_3pt_arc)
Finding Y (y_3pt_arc_top)
Finding Y (y_3pt_arc_bottom)
This diagonal line is used to segment shot area
The line start from the basket, through top and bottom corner of the free throw box, up to the 3 point arc.
Therefore we have the same X and 2 Y (top and bottom)

1) Imagine a horizontal line from the basket (X_BASKET, Y_BASKET) to ARC_3PT (X_BASKET + 6.75, Y_BASKET) (6.75 is the distance between x_basket to the 3 point in a straight manner)
2) Imagine a diagonal line. Start from the basket, through top and bottom corner of the free throw box, up to the 3 point arc.
3) We are finding the vertical line that connects them

In the sin cos tan, 2 is the hypotenuse with the radius of ARC_3PT as the distance

'''
# math.cos(np.deg2rad(30)) = x / 6.75                                             (Hypotenuse = r)
# x                        = math.cos(np.deg2rad(30)) * 6.75
# x                        = 5.845671475544961
# x                        = 5.845671475544961 + BASKET_X                         (Because x start from the center of basket, not from (0,0) cartesian)         
x_3pt_arc                  = 7.420671475544961


#Finding y in a 3PT circle equation
# math.sin(np.deg2rad(30)) = y / 6.75                                             (Hypotenuse = r)
# y                        = math.sin(np.deg2rad(30)) * 6.75
# y                        = 3.3749999999999996

# y                        = 3.3749999999999996 + BASKET_Y                         (Because x start from the center of basket, not from (0,0) cartesian)         
y_3pt_arc_top              = 10.875

# y                        = BASKET_Y - 3.3749999999999996                         (Because x start from the center of basket, not from (0,0) cartesian)         
y_3pt_arc_bottom           = 4.125



'''

Drawing the 3PT Circle

'''
# compute θ (angle) in radians from basket center to intersection point a point (x_stop, y_stop)
# dx = distance of x to the point of x_stop relative to the BASKET_X
# dy = distance of y to the point of y_stop relative to the BASKET_Y
theta_arc_1 = math.atan2(bottom_y_3pt_stop  - BASKET_Y, x_stop - BASKET_X) #math.atan2(-(BASKET_Y - 0.9), dx)
theta_arc_2 = math.atan2(top_y_3pt_stop     - BASKET_Y, x_stop - BASKET_X) #math.atan2((7.5 - 0.9), dx)

# Sample angles from bottom to top and convert to (x, y) by 600 data point
# draw 600 sample of radiant angle relative from the basket
arc_angles = np.linspace(theta_arc_1, theta_arc_2, 600)

# convert back to Cartesian
# x=a + r cosθ
# y=b + r sinθ
arc_x = BASKET_X + ARC_3PT * np.cos(arc_angles)
arc_y = BASKET_Y + ARC_3PT * np.sin(arc_angles)



'''

Drawing the Basket Circle

'''
# Half circle angles: 0°–180° (or π radians)

theta_basket = np.linspace(-np.pi/2, np.pi/2, 200)  # right half
#theta_basket = np.linspace(0, np.pi, 200)   # top half
# theta = np.linspace(np.pi/2, 3*np.pi/2, 200) # left half
# choose depending on which half you want

arc_basket_x = BASKET_X + ARC_BASKET * np.cos(theta_basket)
arc_basket_y = BASKET_Y + ARC_BASKET * np.sin(theta_basket)










'''

Zones  for shot segmentation

'''
zone1 = [
    (0                   , 0),
    (0                   , bottom_y_3pt_stop),
    (x_stop              , bottom_y_3pt_stop),
    (x_stop              , 0)
]

zone1_1 = [
    (0                   , top_y_3pt_stop),
    (0                   , COURT_HEIGHT),
    (x_stop              , COURT_HEIGHT),
    (x_stop              , top_y_3pt_stop)   
]


''' Zone 2 (Corner 2PT Shot)'''

zone2 = [
    (0                  , bottom_y_3pt_stop),
    (0                  , key_y_start),
    (x_stop             , key_y_start),
    (x_stop             , bottom_y_3pt_stop)
]

zone2_2 = [
    (0                  , key_y_stop),
    (0                  , top_y_3pt_stop),
    (x_stop             , top_y_3pt_stop),
    (x_stop             , key_y_stop)
]


''' Zone 3 (Basket Area)'''

zone3 = [
    (0                  , key_y_start),
    (0                  , key_y_stop),
    (x_stop             , key_y_stop),
    (x_stop             , key_y_start)

]

''' Zone 4 (> 30 degree 3PT Shot), INSIDE == FALSE'''

zone4 = [
    (x_stop           , 0),                     # (2.990097169808492, 0)
    (x_stop           , bottom_y_3pt_stop),        
    (x_3pt_arc        , y_3pt_arc_bottom),      
    (COURT_WIDTH      , y_3pt_arc_bottom),
    (COURT_WIDTH      , 0)
]

zone4_4 = [
    (x_stop       , top_y_3pt_stop),
    (x_stop       , COURT_HEIGHT),
    (COURT_WIDTH , COURT_HEIGHT),
    (COURT_WIDTH  , y_3pt_arc_top),
    (x_3pt_arc    , y_3pt_arc_top)
]


''' Zone 5 (> 30 degree 2PT Shot), INSIDE == TRUE'''

#RED BOTTOM
zone5 = [
    (x_stop        , bottom_y_3pt_stop),
    (x_stop        , key_y_start),
    (key_width     , key_y_start),
    (x_3pt_arc     , y_3pt_arc_bottom),
    (COURT_WIDTH  , y_3pt_arc_bottom),
    (COURT_WIDTH   , bottom_y_3pt_stop)
]

#RED TOP
zone5_5 = [
    (x_stop      , key_y_stop),
    (x_stop      , top_y_3pt_stop),
    (COURT_WIDTH , top_y_3pt_stop),
    (COURT_WIDTH , y_3pt_arc_top),
    (x_3pt_arc   , y_3pt_arc_top),
    (key_width   , key_y_stop)
]

''' Zone 6 (Freethrow area, 2PT Shot)'''
zone6 = [
    (x_stop, key_y_start),
    (x_stop, key_y_stop),
    (key_width, key_y_stop),
    (key_width, key_y_start)
]

''' Zone 7 (Long 2, near FT Area)'''
zone7 = [
    (key_width    , key_y_start),
    (key_width    , key_y_stop),
    (x_3pt_arc    , y_3pt_arc_top),
    (COURT_WIDTH  , y_3pt_arc_top),
    (COURT_WIDTH  , y_3pt_arc_bottom),
    (x_3pt_arc    , y_3pt_arc_bottom)
]

''' Zone 8 (3 Point Straight from basket)'''
zone8 = [
    (x_3pt_arc   , y_3pt_arc_bottom),
    (x_3pt_arc   , y_3pt_arc_top),
    (COURT_WIDTH, y_3pt_arc_top),
    (COURT_WIDTH, y_3pt_arc_bottom)
]


'''
Visualize Court
'''
#distance_from_center = np.sqrt((X - BASKET_X)**2 + (Y - BASKET_Y)**2)


def draw_court_canvas(color=False):
    
    #Canvas
    fig, ax = plt.subplots(figsize=(COURT_HEIGHT, COURT_WIDTH))
    ax.set_facecolor('white')
    ax.set_xlim(0, 14)
    ax.set_ylim(0, 15)
    ax.set_aspect('equal')
    ax.grid(False)


    ''' Drawing the court '''
    
    #Plot basket
    ax.scatter(BASKET_X, BASKET_Y, c='red', s=120)    

    # Free throw circle
    ft_circle = Circle((key_width, BASKET_Y), free_throw_radius, linewidth=line_width, edgecolor=line_color, facecolor='none', zorder=8)
    ax.add_patch(ft_circle)

    #Bottom straight line
    line_x_1, line_y_1 = [0, x_stop], [bottom_y_3pt_stop,bottom_y_3pt_stop]
    #Top straight line
    line_x_2, line_y_2 = [0, x_stop], [top_y_3pt_stop,top_y_3pt_stop]

    #Plot lines
    ax.plot(line_x_1, line_y_1, c='black')                                                                  # the bottom y straight line
    ax.plot(line_x_2, line_y_2, c='black')                                                                  # the top y straight line
    ax.hlines(y=5.05, xmin=0, xmax=key_width, colors='black', linestyles='-', linewidth=line_width)
    ax.hlines(y=9.95, xmin=0, xmax=key_width, colors='black', linestyles='-', linewidth=line_width)
    ax.vlines(x=key_width, ymin=5.05, ymax=9.95, colors='black', linestyles='-', linewidth=line_width)
    ax.vlines(x=BASKET_X, ymin=BASKET_Y-ARC_BASKET, ymax=BASKET_Y+ARC_BASKET, colors='black', linestyles='-', linewidth=line_width)
    
    #3PT Circle
    ax.plot(arc_x, arc_y, linewidth=2, c='black')      # the arc segment

    #Basket Circle
    ax.plot(arc_basket_x, arc_basket_y, linewidth=2, c='black')      # the arc segment

    #Hide tick
    ax.tick_params(axis='y', left=False, labelleft=False)
    ax.tick_params(axis='x', bottom=False, labelbottom=False)


    """
    Create a visualization of the zone system with filled colors

    #Zone 1
    #court_outline = Rectangle((0, 0), COURT_WIDTH, COURT_HEIGHT, linewidth=line_width, edgecolor=line_color, facecolor='none', zorder=8)
    #ax.add_patch(court_outline)

    Parameters:
    points        : list of (x, y) tuples defining the polygon vertices in order
    circle_center : (x, y) tuple for circle center
    circle_radius : radius of the circle
    grid_size     : (width, height) tuple for coordinate system size
    color         : color for the filled area
    ax            : matplotlib axis to draw on (if None, creates new plot)
    
    Returns:
    ax: the matplotlib axis object
    """

    def color_polygon_area_excluding_circle(points, color, ax=None, position_detail=False):

        # Create a mesh grid for coloring
        x = np.linspace(0, 14, 1000)
        y = np.linspace(0, 15, 1000)
        X, Y = np.meshgrid(x, y)

        # Each element is the distance from that grid point (X,Y) from a basket located at BASKET_X, BASKET_Y
        # A 1000×1000 array,
        distance_from_center = np.sqrt((X - BASKET_X)**2 + (Y - BASKET_Y)**2)
        # Gives a boolean mask
        # True -> Inside the ARC_3PT
        # False -> Outside the ARC_3PT
        inside_circle        = distance_from_center <= ARC_3PT
        
        # Create polygon path
        polygon_path = Path(points)
        
        # Create mask for points inside the polygon
        inside_polygon = polygon_path.contains_points(np.column_stack([X.flatten(), Y.flatten()]))
        inside_polygon = inside_polygon.reshape(X.shape)


        # Create mask for points inside the circle
        # Returns the point needed
        def create_mask(polygon_points, position_detail=False):

            if position_detail == 'outside': 
                
                # Inside polygon and outside 3pt arc
                selected_area = polygon_points & (~inside_circle)

            elif position_detail == 'inside':
                # Inside polygon and inside 3pt arc
                selected_area = polygon_points & (inside_circle)

            if not position_detail:
                selected_area = polygon_points

            return selected_area

        
        # Color the area
        final_mask = create_mask(inside_polygon, position_detail)
        ax.contourf(X, Y, final_mask.astype(int), levels=[0.5, 1.5], colors=[color], alpha=0.2)


    if color:

        # Color both polygon areas
        zone_colors = {
            1: '#00AA00',    # Dark green - Corner 3 bottom
            2: '#FFA500',    # Orange - Left short corner
            3: '#8A2BE2',    # Purple - Left wing
            4: '#FFB6C1',    # Light pink - Left deep
            5: '#0000FF',    # Blue - Left baseline mid
            6: '#FFA500',    # Orange - Left paint side
            7: '#8B4513',    # Brown - Paint center
            8: '#FF0000',    # Red - Arc area
        }

        color_polygon_area_excluding_circle(zone1    , color=zone_colors[1], ax=ax)
        color_polygon_area_excluding_circle(zone1_1  , color=zone_colors[1], ax=ax)
        color_polygon_area_excluding_circle(zone2    , color=zone_colors[2], ax=ax)
        color_polygon_area_excluding_circle(zone2_2  , color=zone_colors[2], ax=ax)
        color_polygon_area_excluding_circle(zone3    , color=zone_colors[3], ax=ax)
        color_polygon_area_excluding_circle(zone4    , color=zone_colors[4], ax=ax, position_detail='outside')
        color_polygon_area_excluding_circle(zone4_4  , color=zone_colors[4], ax=ax, position_detail='outside')
        color_polygon_area_excluding_circle(zone5    , color=zone_colors[5], ax=ax, position_detail='inside')
        color_polygon_area_excluding_circle(zone5_5  , color=zone_colors[5], ax=ax, position_detail='inside')
        color_polygon_area_excluding_circle(zone6    , color=zone_colors[6], ax=ax)
        color_polygon_area_excluding_circle(zone7    , color=zone_colors[7], ax=ax)
        color_polygon_area_excluding_circle(zone8    , color=zone_colors[8], ax=ax, position_detail='outside')
     

    # Map each zone number to its polygon(s)
    #zone_polys = {
    #    1: [zone1, zone1_1],
    #    2: [zone2, zone2_2],
    #    3: [zone3],
    #    4: [zone4, zone4_4],
    #    5: [zone5, zone5_5],
    #    6: [zone6],
    #    7: [zone7],
    #    8: [zone8],
    #}

    
    return fig, ax
    



