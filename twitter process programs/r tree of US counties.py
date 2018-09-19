import sys
sys.path.append("D:\\pylib")
from indexing.rtree1 import *
from indexing.rtree2 import *
from geom.point import *
from geom.point_in_polygon import *
import fiona
import struct
import timeit
import json

start = timeit.default_timer()
fname = '/Users/Yuxiao/cb_2016_us_county_20m/cb_2016_us_county_20m.shp'
US_county = fiona.open(fname, 'r')
def MBR(polys):
    minx = min([min([p[0] for p in poly]) for poly in polys])
    maxx = max([max([p[0] for p in poly]) for poly in polys])
    miny = min([min([p[1] for p in poly]) for poly in polys])
    maxy = max([max([p[1] for p in poly]) for poly in polys])
    bound = [minx, maxx, miny, maxy]
    return bound

def point_in_MBR(node,point):
    '''
    input the root of the rtree and the query point
    output the polygon which contains the point
    '''
    foundnum = []
    found=[] # list of polygons which contain the point
    def point_in_mbr(node,point):
        if node.is_leaf():
            for ent in node.entries:
                if point[0] > ent.MBR[0] and point[0] < ent.MBR[1] and point[1] > ent.MBR[2] and point[1] < ent.MBR[3]:
                    found.append(ent)
                    foundnum.append(ent.num)            
            return
 
        for ent in node.entries:
            if point[0] > ent.MBR[0] and point[0] < ent.MBR[1] and point[1] > ent.MBR[2] and point[1] < ent.MBR[3]:
                point_in_mbr(ent.child,point)
    point_in_mbr(node,point)
    return found,foundnum

polygons = [US_county[i]['geometry']['coordinates'] for i in range(102)]
MBRs = []
for polygon in polygons:
    MBRs.append(MBR(polygon))

M = 3
root = RTreeNode(M, None)
extents = [Extent(mbr[0], mbr[1], mbr[2], mbr[3]) for mbr in MBRs]
i = 0
for e in extents:
    n = search_rtree_extent(root, e)
    print(i)
    insert(n, e, N = i)
    i += 1
root.get_all_leaves()


# print(point_in_MBR(root,Point(2,3.5)))
# test the Point(-83,39) in which polygon
print(point_in_MBR(root,Point(-83,39)))
'''
def by16(f):
    rec = 'x'  # placeholder for the `while`
    while rec:
        rec = f.read(16)
        if rec: yield rec
with open('H:\\tweets_uscontiguous','rb') as rf:
    with open("H:\\countytweets.txt",'w') as wf:
        county_tweets = [0]*len(US_county)
        for rec in by16(rf):
            pos = struct.unpack('<ihbbff', rec)
            for i in point_in_MBR(root,Point(pos[4],pos[5]))[1]:
                polygons = [[ Point(p[0],p[1]) for p in poly for poly in US_county[i]['geometry']['coordinates'] ]]
                if pip_cross2(Point(pos[4],pos[5]),polygons)[0] == True:
                    county_tweets[i] += 1

        wf.write(county_tweets)
            
stop = timeit.default_timer()
print("time:",stop-start)

'''