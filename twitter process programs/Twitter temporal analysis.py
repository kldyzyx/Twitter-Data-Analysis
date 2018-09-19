# Get the day Tweets
import fiona
import struct
import timeit
import rtree
from shapely.geometry import *
import math
import csv
from datetime import *
import copy

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
        CountyTweetsDaily = []

        # create an empty spatial index object
        idx =  rtree.index.Index()

        # populate the spatial index
        for fid,feature in UScounty.items():
            geometry_county = shape(feature['geometry'])
            idx.insert(fid, geometry_county.bounds)

        n0 = [] # belong to no county
        n2 = [] # belong to more than one county
        lastdate = datetime(1000, 1, 1).date()

        # create a date timeseries and save as the first elements in each list of the CounyTweetsDaily
        d = datetime(2015, 7, 1).date()
        for i in range(850):
            CountyTweetsDaily.append([d]+[0]*len(UScounty))
            d = d + timedelta(days=1)
       
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
            date = datetime(pos[1], pos[2], pos[3]).date()
            if date == lastdate:
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
                        CountyTweetsDaily[m][fid+1] += 1
                        ids.append(fid)
                        n += 1
                        break
                    
            else:
                for m in range(len(CountyTweetsDaily)):
                    if date == CountyTweetsDaily[m][0]:
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
                                CountyTweetsDaily[m][fid+1] += 1
                                ids.append(fid)
                                n += 1
                                break
                        break

            count += 1
            lastdate = date
            
            if count%1000000 == 0:
                print('completed:',count)
            if n > 1:
                n2.append([n,pos[1],pos[2],pos[3],pos[4], pos[5], ids])
            if n == 0:
                n0.append([pos[1],pos[2],pos[3],pos[4], pos[5]])            
           

with open("E://osu/research/CountyTweetsDaily.csv",'w', newline="") as wf:
    writer = csv.writer(wf)
    for daytweets in CountyTweetsDaily:
        writer.writerow(daytweets)


print(count)
stop = timeit.default_timer()
print('cost time:', stop-start)
print('n2:',n2)
print('n0:',n0)

# 43282257
# cost time: 21587.410527367017
# n2: []
# n0
