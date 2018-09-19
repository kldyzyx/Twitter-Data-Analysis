import struct
import csv
'''
# unpacking
def by28(f):
    rec = 'x'  # placeholder for the `while`
    while rec:
        rec = f.read(28)
        if rec: yield rec 

# filter the tweets in us bound box
# USA Extent: (-124.848974, 24.396308) - (-66.885444, 49.384358)
with open('H:\\world_tweets_binary', 'rb') as inh:
    with open('H:\\world_tweets_us','wb') as wf:
        count = 0
        for rec in by28(inh):
            pos = struct.unpack('<ihbbbbbbffq', rec) #<ihbbbbbbffq is the way of coding binary file
            if pos[8] <-66:
                if pos[8] >-125:
                    if pos[9]>24:
                        if pos[9] < 50:
                            line_num = struct.pack("i",pos[0])  # 4 bytes
                            year = struct.pack("h",pos[1]) # 2 byte
                            month = struct.pack("b",pos[2]) # 1 byte
                            date = struct.pack("b",pos[3])  # 1 byte

                            lng =  struct.pack("f",pos[8]) # 4 bytes
                            lat =  struct.pack("f",pos[9]) # 4 bytes
                            # userid = struct.pack('q',pos[10]) # 8 byte
                            # line =struct.pack("<ihbbbbbbffq",pos[0],pos[1],pos[2],pos[3],pos[4],pos[5],pos[6],pos[7],pos[8],pos[9],pos[10])
                            wf.write(line_num)
                            wf.write(year)
                            wf.write(month)
                            wf.write(date)
                            wf.write(lng)
                            wf.write(lat)
                            # wf.write(userid)
                            count += 1
        print(count)

# 46362310 records are saved after this filter



# filter the tweets in ohio bound box
def by16(f):
    rec = 'x'  # placeholder for the `while`
    while rec:
        rec = f.read(16)
        if rec: yield rec 
# Ohio extent: [-84.82030499999999,38.403423]-[-80.51845399999999,42.327132]
with open('H:\\world_tweets_us','rb') as rf:
    with open('H:\\world_tweets_ohio','wb') as wf:
        count = 0
        for rec in by16(rf):
            pos = struct.unpack('<ihbbff', rec)
            if pos[4] <-80.5:
                if pos[4] > -84.821:
                    if pos[5] > 38.4:
                        if pos[5] < 42.33:
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
                            count += 1
        print(count)

# 258327 records
'''

# filter the tweets in the contiguous USA
import sys
sys.path.append("D:\\pylib")
from geom.point_in_polygon import *
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
    with open('H:\\test2_tweets_uscontiguous','wb') as wf:
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
# time: 3137.865856099131
# there are 5823224 records

