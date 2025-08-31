import math
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Circle, Rectangle
from matplotlib.collections import PatchCollection


# FIBA half-court dimensions (meters)
COURT_HEIGHT = 15.0     
COURT_WIDTH  = 14.0   
BASKET_X     = 1.575    # Basket x position
BASKET_Y     = 7.5      # Basket y position

# Free throw lane (key/paint) - FIBA dimensions
key_width   = 5.9   
key_height  = 4.9 
key_y_start = (COURT_HEIGHT / 2) - (key_height/2)  #Start y rectangle free throw, x di 0
ARC_3PT          = 6.75       # FIBA arc 3PT distance
CORNER_EXTENSION = 0.9  # Corner 3PT extension from baseline

# Zone distance thresholds
ZONE1_MAX  = 1.5      # Restricted area
ZONE2_MAX  = 3.5      # Close range
ZONE3_MAX  = 6.75     # Mid-range (to 3PT line)
LONG_RANGE = 9.0     # Deep three threshold

# Viz Setting
line_width = 3
line_color = 'black'


def calculate_distance_from_basket(x, y):
    """Calculate Euclidean distance from basket position"""
    return math.sqrt((x - BASKET_X)**2 + (y - BASKET_Y)**2)

def is_in_corner_three_area(x, y):
    """Check if shot is in corner 3-point area"""
    distance = calculate_distance_from_basket(x, y)
    
    # Must be beyond 3PT distance and within corner extension area
    if distance >= ARC_3PT and x <= CORNER_EXTENSION:
        # Check if in actual corner areas (not middle of court)
        corner_boundary = 2.5  # meters from edge to define "corner"
        return y <= corner_boundary or y >= (COURT_HEIGHT - corner_boundary)
    return False

def classify_shot_zone(x, y):
    """
    Classify shot into one of 6 zones
    Returns: (zone_number, zone_name)
    """
    # Validate coordinates are within half-court
    if x < 0 or x > COURT_WIDTH or y < 0 or y > COURT_HEIGHT:
        return (0, "Out of Bounds")
    
    distance = calculate_distance_from_basket(x, y)
    
    # Zone 1: Restricted Area/Paint (0-1.5m)
    if distance <= ZONE1_MAX:
        return (1, "Restricted Area")
    
    # Zone 2: Close Range (1.5m-3.5m)
    elif distance <= ZONE2_MAX:
        return (2, "Close Range")
    
    # Zone 3: Mid-Range (3.5m-6.75m)
    elif distance <= ZONE3_MAX:
        return (3, "Mid-Range")
    
    # Zone 4: Corner 3-Point
    elif is_in_corner_three_area(x, y):
        return (4, "Corner 3PT")
    
    # Zone 6: Long Range (Beyond 9m) - check before Zone 5
    elif distance > LONG_RANGE:
        return (6, "Long Range")
    
    # Zone 5: Above-the-Break 3-Point (remaining 3PT area)
    elif distance >= ARC_3PT:
        return (5, "Above Break 3PT")
    
    # Fallback for edge cases
    else:
        return (3, "Mid-Range")  # Default to mid-range for borderline cases

def batch_classify_shots(shot_coordinates):
    """
    Classify multiple shots at once
    Input: List of (x, y) tuples
    Returns: List of (zone_number, zone_name) tuples
    """
    return [classify_shot_zone(x, y) for x, y in shot_coordinates]



def visualize_zones_with_court():

    # Zone colors (semi-transparent for court lines to show through)
    colors = {
        1: '#FF6B6B',  # Red - Restricted
        2: '#4ECDC4',  # Teal - Close Range  
        3: '#45B7D1',  # Blue - Mid-Range
        4: '#96CEB4',  # Green - Corner 3PT
        5: '#FFEAA7',  # Yellow - Above Break 3PT
        6: '#DDA0DD'   # Purple - Long Range
    }
    
    # Create high-resolution grid for zone filling
    x_grid = np.linspace(0, COURT_WIDTH, 560)
    y_grid = np.linspace(0, COURT_HEIGHT, 600)
    X, Y = np.meshgrid(x_grid, y_grid)


    # Create zone mask
    zone_mask = np.zeros_like(X)
    for i in range(X.shape[0]):
        for j in range(X.shape[1]):
            zone, _ = classify_shot_zone(X[i, j], Y[i, j])
            zone_mask[i, j] = zone

    
    """Create a visualization of the zone system with filled colors and court lines"""
    fig, ax = plt.subplots(figsize=(COURT_HEIGHT, COURT_WIDTH))
    ax.set_facecolor('white')                         #sets the background color of an axes (the plotting area) to white.


    # Fill each zone with color FIRST (behind court lines)
    for zone_num in range(1, 7):
        mask = zone_mask == zone_num
        if np.any(mask):
            ax.contourf(X, Y, mask, levels=[0.5, 1.5], 
                       colors=[colors[zone_num]], alpha=0.4)
    
    """Court Outline"""
    court_outline = Rectangle(
                            (0, 0), COURT_WIDTH, COURT_HEIGHT, 
                            linewidth=line_width, edgecolor=line_color, facecolor='none', zorder=8)
    ax.add_patch(court_outline)
    
    """Free Throw Area"""
    key = Rectangle(
                   (0, key_y_start), key_width, key_height,
                   linewidth=line_width, edgecolor=line_color, facecolor='none', zorder=8)
    ax.add_patch(key)
    
    
    """Free Throw Circle"""
    # Free throw circle - FIBA: 1.8m radius dari end of free throw area
    # Draw FULL circle
    ft_circle = Circle(
                      (5.9, BASKET_Y), 1.8, 
                      linewidth=line_width, edgecolor=line_color, facecolor='none', zorder=8)
    ax.add_patch(ft_circle)
    
    
    """3Pt Throw Circle"""
    #Calculate where the arc meets the X
    # (a,b) is the circle center
    # (x,y) is a coordinate
    # circle cartesian equation = (x-a)**2 + (y-b)**2 = r**2
    # Bottom y = 0.9, Top y = (15-0.9), but both will have the same x intersection with the arc
    # (x - 1.575)**2 + (0.9 - 7.5)**2 = 6.75**2
    x_stop   = math.sqrt(ARC_3PT**2 - (0.9-BASKET_Y)**2) + 1.575
    y_bottom = 0.9
    y_top    = (15-0.9)
    
    # Angles of the two intersection points (same x, different y)
    theta_b = math.atan2(y_bottom  - BASKET_Y, x_stop - BASKET_X)
    theta_t = math.atan2(y_top     - BASKET_Y, x_stop - BASKET_X)
    
    # Sample angles from bottom to top and convert to (x, y)
    arc_angles = np.linspace(theta_b, theta_t, 300)
    x = BASKET_X + ARC_3PT * np.cos(arc_angles)
    y = BASKET_Y + ARC_3PT * np.sin(arc_angles)
    
    #Bottom straight line
    line_x_1, line_y_1 = [0, x_stop], [y_bottom,y_bottom]
    #Top straight line
    line_x_2, line_y_2 = [0, x_stop], [y_top,y_top]
    #Plot lines
    ax.plot(line_x_1, line_y_1, c='black')     # the bottom y straight line
    ax.plot(line_x_2, line_y_2, c='black')     # the top y straight line
    ax.plot(x, y, linewidth=2, c='black')      # the arc segment
    
    ax.set_xlim(0, 14)
    ax.set_ylim(0, 15)
    ax.set_aspect('equal')
    ax.grid(False)


    # Add zone labels with white background for visibility
    label_props = dict(boxstyle='round,pad=0.3', facecolor='white', 
                      edgecolor='black', alpha=0.9)
    
    ax.text(1.2, 7.5, '1\nRestricted', ha='center', va='center', 
            fontweight='bold', fontsize=10, bbox=label_props, zorder=12)
    ax.text(3.0, 7.5, '2\nClose Range', ha='center', va='center', 
            fontweight='bold', fontsize=10, bbox=label_props, zorder=12)
    ax.text(5.5, 10, '3\nMid-Range', ha='center', va='center', 
            fontweight='bold', fontsize=10, bbox=label_props, zorder=12)
    ax.text(0.5, 2.0, '4\nCorner\n3PT', ha='center', va='center', 
            fontweight='bold', fontsize=9, bbox=label_props, zorder=12)
    ax.text(0.5, 13.0, '4\nCorner\n3PT', ha='center', va='center', 
            fontweight='bold', fontsize=9, bbox=label_props, zorder=12)
    ax.text(9.5, 7.5, '5\nAbove Break\n3PT', ha='center', va='center', 
            fontweight='bold', fontsize=10, bbox=label_props, zorder=12)
    ax.text(12.5, 7.5, '6\nLong Range', ha='center', va='center', 
            fontweight='bold', fontsize=10, bbox=label_props, zorder=12)

    # Add distance markers for reference (optional)
    distance_rings = [1.5, 3.5, 6.75, 9.0]
    for dist in distance_rings:
        circle = Circle((BASKET_X, BASKET_Y), dist, 
                      linewidth=1, edgecolor='gray', linestyle='--',
                      facecolor='none', alpha=0.2, zorder=5)
        ax.add_patch(circle)


    return fig, ax


