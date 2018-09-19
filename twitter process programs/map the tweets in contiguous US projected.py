import matplotlib.pyplot as plt
import pysal
import struct
import timeit


US_state = pysal.open('D:\\OneDrive - The Ohio State University\\AAG\\data\\tl_2010_us_state10\\tl_2010_us_state10.shp')
# .read with no arguments returns a list of all shapes in the file.
polygons = polygon_file.read()


start = timeit.default_timer()
fname = 'D:\\OneDrive - The Ohio State University\\AAG\\data\\tl_2010_us_state10\\tl_2010_us_state10.shp'
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
    patch = PathPatch(path, facecolor='none', edgecolor='darkgrey',alpha = 0.9, lw =0.7)
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

count = 0
lng = []
lat = []

with open('H:\\tweets_uscontiguous','rb') as rf:
    for rec in by16(rf):
        coor = struct.unpack('<ihbbff', rec)
        lng.append(coor[4])
        lat.append(coor[5])
        count += 1

major_cities = [
    {'city': 'Atlanta', 'dma_code': 524, 'latitude': 33.748995399999998, 'longitude': -84.387982399999999, 'region': 'GA', 'slug': 'atlanta-ga'},
    {'city': 'Austin', 'dma_code': 635, 'latitude': 30.267153, 'longitude': -97.743060799999995, 'region': 'TX', 'slug': 'austin-tx'},
    {'city': 'Chicago', 'dma_code': 602, 'latitude': 41.850033000000003, 'longitude': -87.650052299999999, 'region': 'IL', 'slug': 'chicago-il'},
    {'city': 'Charlotte', 'dma_code': 517, 'latitude': 35.227086900000003, 'longitude': -80.843126699999999, 'region': 'NC', 'slug': 'charlotte-nc'},
    {'city': 'Columbus', 'dma_code': 535, 'latitude': 39.961175500000003, 'longitude': -82.998794200000006, 'region': 'OH', 'slug': 'columbus-oh'},
    {'city': 'Dallas', 'dma_code': "NA", 'latitude': 32.7767, 'longitude': -96.7970, 'region': 'TX', 'slug': 'dallas-tx'},
    {'city': 'Denver', 'dma_code': 751, 'latitude': 39.739153600000002, 'longitude': -104.9847034, 'region': 'CO', 'slug': 'denver-co'},
    {'city': 'Houston', 'dma_code': 618, 'latitude': 29.762884400000001, 'longitude': -95.383061499999997, 'region': 'TX', 'slug': 'houston-tx'},
    {'city': 'Jacksonville', 'dma_code': 561, 'latitude': 30.332183799999999, 'longitude': -81.655651000000006, 'region': 'FL', 'slug': 'jacksonville-fl'},
    {'city': 'Los Angeles', 'dma_code': 803, 'latitude': 34.052234200000001, 'longitude': -118.24368490000001, 'region': 'CA', 'slug': 'los-angeles-ca'},
    {'city': 'New York', 'dma_code': 501, 'latitude': 40.714269100000003, 'longitude': -74.005972900000003, 'region': 'NY', 'slug': 'new-york-ny'},
    {'city': 'Philadelphia', 'dma_code': 504, 'latitude': 39.952334999999998, 'longitude': -75.163788999999994, 'region': 'PA', 'slug': 'philadelphia-pa'},
    {'city': 'Phoenix', 'dma_code': 753, 'latitude': 33.448377100000002, 'longitude': -112.0740373, 'region': 'AZ', 'slug': 'phoenix-az'},
    {'city': 'San Diego', 'dma_code': 825, 'latitude': 32.715329199999999, 'longitude': -117.1572551, 'region': 'CA', 'slug': 'san-diego-ca'},
    {'city': 'Seattle', 'dma_code': "NA", 'latitude': 47.608013, 'longitude': -122.335167, 'region': 'WA', 'slug': 'seattle-wa'},
    {'city': 'San Francisco', 'dma_code': "NA", 'latitude': 37.774929, 'longitude': -122.419416, 'region': 'CA', 'slug': 'san-francisco-ca'},
    {'city': 'Washington DC ', 'dma_code': 511, 'latitude': 38.895111800000002, 'longitude': -77.036365799999999, 'region': 'MD', 'slug': 'washington-dc-md'}
    ]

city_name = []
city_lng = []
city_lat = []
for city in major_cities:
    city_lng.append(city["longitude"])
    city_lat.append(city["latitude"])
    city_name.append(city["city"])

ax.scatter(lng,lat,s=0.01, alpha=0.6, color ='dodgerblue')
ax.scatter(city_lng,city_lat,s=2, alpha=1, color ='red')
for i, txt in enumerate(city_name):
    ax.annotate(txt, (city_lng[i]+0.3,city_lat[i]+0.7))

stop = timeit.default_timer()
plt.show()
print(count)
print("time:",stop-start)

# 43282257
# time: 1195.8431144456256
