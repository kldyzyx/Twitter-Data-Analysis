import math
import sys
sys.path.append('D:\\pylib')
from geom.point import *
import timeit
import struct
def pip_cross2(point, polygons):
    """
    This function is originally from Dr. Ningchuan Xiao
    See https://github.com/gisalgs/geom/blob/master/point_in_polygon.py
    
    Input
      polygon: a list of lists, where each inner list contains points
               forming a part of a multipolygon. Each part must be
               closed, otherwise an error will be raised.
      point:   the point

    Ouput
      Returns a boolean value of True or False and the number
      of times the half line crosses the polygon boundary
    
    adapted:
    make the result consistent for boundary points: inclusive
    """
    # tx, ty = point.x, point.y
    x, y = point.x, point.y
    crossing_count = 0
    is_point_inside = False
    for pgon in polygons:
        if pgon[0] != pgon[-1]:
            raise Exception('Polygon not closed')
        N = len(pgon)
        mside = [] 
        for i in range(N-1):
            p1, p2 = pgon[i], pgon[i+1]

            if p2.y == y:
                if p1.y == y and (p1.x>x or p2.x>x):
                    crossing_count = math.inf
                    is_point_inside = True
                    break
                if p2.x == x:
                    crossing_count = 1 # arbitrary
                    is_point_inside = True
                    break
            yside1 = (p1.y >= y)
            yside2 = (p2.y >= y)
            if yside1 != yside2 or (p1.y == y and p2.y > y) or (p1.y > y and p2.y == y):
                xside1 = (p1.x >= x)
                xside2 = (p2.x >= x)
                if xside1 == xside2:
                    if xside1:
                        crossing_count += 1
                        is_point_inside = not is_point_inside
                        m = p2.x - (p2.y-y)*(p1.x-p2.x)/float(p1.y-p2.y)
                        if m == x:
                            is_point_inside = True
                            break
                        if m == p2.x:  # when the intersect is the endpoint of the line
                            mside.append(yside1)
                        if m == p1.x:
                            mside.append(yside2)
                        if len(mside) == 2:
                            if mside[0] != mside[1]:
                                crossing_count -= 1
                                is_point_inside = not is_point_inside
                            mside = []

                else:
                    m = p2.x - (p2.y-y)*(p1.x-p2.x)/float(p1.y-p2.y)
                    if m == x:
                        is_point_inside = True
                        break
                    if m > x:
                        crossing_count += 1
                        is_point_inside = not is_point_inside
                        if m == p2.x:  # when the intersect is the endpoint of the line
                            mside.append(yside1)
                        if m == p1.x:
                            mside.append(yside2)
                        if len(mside) == 2:
                            if mside[0] != mside[1]:
                                crossing_count -= 1
                                is_point_inside = not is_point_inside
                            mside = []

    return is_point_inside, crossing_count

poly = [[Point(p[0],p[1]) for p in [(3,0),(5,4),(4,5),(2,3),(0,1),(3,0)]]]
# print([pip_cross2(Point(p[0],p[1]),poly)[0] for p in poly[0]])  # test the endpoints of the polygon

poly2 = [[Point(p[0],p[1]) for p in [(-1.5,1.5),(0,0),(1.5,1.5),(3,0),(4,1.5),(3,3),(0,3),(-1.5,1.5)]]]
# print([pip_cross2(Point(p[0],p[1]),poly2)[0] for p in poly2[0]])  # test the endpoints of the polygon

poly3 = [[Point(p[0],p[1]) for p in [(0,0),(1.5,1.5),(3,0),(3,4.5),(0,4.5),(0,0)]]]
# print([pip_cross2(Point(p[0],p[1]),poly3)[0] for p in poly3[0]])  # test the endpoints of the polygon

start =  timeit.default_timer()
import sys
sys.path.append("D:\\pylib")
from geom.point import *
import fiona
import timeit

fname = '/Users/Yuxiao/cb_2016_us_nation_20m/cb_2016_us_nation_20m.shp'
US_contig = fiona.open(fname, 'r')
polygon = US_contig[0]['geometry']['coordinates']
polygon = [[Point(p[0], p[1]) for p in poly] for poly in polygon]
def by16(f):
    rec = 'x'  # placeholder for the `while`
    while rec:
        rec = f.read(16)
        if rec: yield rec
rects = [[[-105.125835,30.769477],[-81.525843,41.369460]],[[-81.525838,34.569464],[-77.328885,41.568148]],
         [[-77.325807,39.569577],[-74.325988,43.268483]],[[-74.325368,41.569860],[-71.025846,44.969459]],
         [[-69.819463,44.478840],[-67.874848,46.771450]],[[-122.525296,38.169895],[-105.126266,48.969269]],
         [[-122.525210,41.369880],[-105.125899,48.969417]],[[-105.126266,48.969269],[-105.125927,38.169420]],
         [[-120.525291,34.570321],[-117.227727,38.167291]]]
start = timeit.default_timer()
with open('H:\\tweets_us','rb') as rf:
    with open('H:\\test_tweets_uscontiguous','wb') as wf:
        count = 0
        count1 = 0
        count2 = 0
        for rec in by16(rf):
            in_rects = False
            pos = struct.unpack('<ihbbff', rec)
            
            for rect in rects:
                if pos[4]>= rect[0][0] and pos[4]<=rect[1][0] and pos[5]>=rect[0][1] and pos[5]<=rect[1][1]:
                    line_num = struct.pack("i",pos[0])  # 4 bytes
                    year = struct.pack("h",pos[1]) # 2 byte
                    month = struct.pack("b",pos[2]) # 1 byte
                    date = struct.pack("b",pos[3])  # 1 byte
                    lng =  struct.pack("f",pos[4]) # 4 bytes
                    lat =  struct.pack("f",pos[5]) # 4 bytes
                           
                    wf.write(line_num)
                    wf.write(year)
                    wf.write(month)
                    wf.write(date)
                    wf.write(lng)
                    wf.write(lat)

                    in_rects = True
                    count1+=1
                    break
                    
            if in_rects == False:
                if pip_cross2(Point(pos[4],pos[5]),polygon)[0] == True:
                    line_num = struct.pack("i",pos[0])  # 4 bytes
                    year = struct.pack("h",pos[1]) # 2 byte
                    month = struct.pack("b",pos[2]) # 1 byte
                    date = struct.pack("b",pos[3])  # 1 byte

                    lng =  struct.pack("f",pos[4]) # 4 bytes
                    lat =  struct.pack("f",pos[5]) # 4 bytes
                           
                    wf.write(line_num)
                    wf.write(year)
                    wf.write(month)
                    wf.write(date)
                    wf.write(lng)
                    wf.write(lat)
                    count2+=1
                    
            count += 1



stop = timeit.default_timer()
print('time:', stop-start)
print(count1+count2)
print(count)
'''
time: 7.6909439564469295
9463
10000

time: 82.3280232765144
93993
100000
'''
