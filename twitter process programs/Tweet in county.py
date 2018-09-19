import fiona
import struct
import timeit
import rtree
from shapely.geometry import *
import math
import csv

start = timeit.default_timer()
fname = 'E:\\osu\\research\\cb_2016_us_county_20m\\cb_2016_us_county_20m.shp'
def by16(f):
    rec = 'x'  # placeholder for the `while`
    while rec:
        rec = f.read(16)
        if rec: yield rec

with open('H:\\tweets_uscontiguous','rb') as tweet:
    with fiona.open(fname,'r') as UScounty:
        count = 0
        CountyTweet = [0] * len(UScounty)

        # create an empty spatial index object
        idx =  rtree.index.Index()

        # populate the spatial index
        for fid,feature in UScounty.items():
            geometry_county = shape(feature['geometry'])
            idx.insert(fid, geometry_county.bounds)

        n0 = []
        n2 = []
        for rec in by16(tweet): # iterate through the tweet record
        #  line_num  4 bytes
        #  year      2 byte
        #  month     1 byte
        #  date      1 byte
        #  lng       4 bytes
        #  lat       4 bytes
    
            n = 0      # n is the number of polygons which contain the point
            ids = []   # ids is the list of the polygon ids
           
            pos = struct.unpack('<ihbbff', rec)
            geometry = shape({"coordinates": [pos[4], pos[5]], "type": "Point"})
            geometry_buffered = geometry.buffer(0.01)

            # get list of fids where bounding boxes intersect
            fids = [int(i) for i in idx.intersection(geometry_buffered.bounds)]

            # access the features that those fids reference
            for fid in fids:
                Itstcounty = UScounty[fid]
                GeometryCounty = shape(Itstcounty['geometry'])

                # check the geometries intersect, not just their bboxs
                if GeometryCounty.contains(geometry):
                    CountyTweet[fid] += 1
                    ids.append(fid)
                    n += 1  
            if n > 1:
                n2.append([n,pos[4], pos[5], ids])
            if n == 0:
                n0.append([pos[4], pos[5]])
            count += 1
            if count%1000000 == 0:
                print('completed:',count)
            
with open("H:\\CountyTweets2.csv",'w') as wf:
    writer = csv.writer(wf)
    writer.writerow(CountyTweet)

print(sum(CountyTweet) == count)
print(count)
stop = timeit.default_timer()
print('cost time:', stop-start)

# False
# 43282257
# cost time: 24305.853712191158s  6.75 hour
# >>> sum(CountyTweet)
# 43282096
