import matplotlib.pyplot as plt
import fiona
import struct
import sys
sys.path.append("E://osu/research")

fname = '/Users/Yuxiao/tl_2010_us_state10/tl_2010_us_state10.shp'
US_state = fiona.open(fname, 'r')
from matplotlib.path import Path
from matplotlib.patches import PathPatch

def path_codes(n):
    codes = [Path.LINETO for i in range(n)]
    codes[0] = Path.MOVETO
    return codes

def pathful_ring(ring):
    points = []
    codes = []
    for i in ring:
        points.extend(i)
        codes += path_codes(len(i))
    return points, codes


def pathful(geom):
    """Creates a matplotlib path.
    
    This function requires the following:
       import copy
       from matplotlib.path import Path
       def path_codes

    Input: 
        rings: can be a multipolygon or polygon, can't deal with other kinds
    Output:
       path: a Path object"""
    geomtype = geom['type']
    rings = geom['coordinates']
    if geomtype == 'MultiPolygon':
        points = []
        codes = []
        for r in rings:
            res = pathful_ring(r)
            points += res[0]
            codes += res[1]
    elif geomtype == 'Polygon':
        points, codes = pathful_ring(rings)
    else:
        return
    return Path(points, codes)

ax = plt.gca()
ax.axis('off')
ax.set_aspect(1)

patches = []
for f in US_state:
    path = pathful(f['geometry'])
    patch = PathPatch(path, facecolor='none', edgecolor='darkgrey')
    ax.add_patch(patch)

ax.set_ylim([24, 50])
ax.set_xlim([-125, -66])

ax.set_xticks([])
ax.set_yticks([])

def by16(f):
    rec = 'x'  # placeholder for the `while`
    while rec:
        rec = f.read(16)
        if rec: 
            yield rec 

lng = []
lat = []
with open('H:\\world_tweets_us','rb') as rf:
    for rec in by16(rf):
        coor = struct.unpack('<ihbbff', rec)
        lng.append(coor[4])
        lat.append(coor[5])

       
ax.scatter(lng,lat,s=0.01, alpha=0.4)
plt.show()
