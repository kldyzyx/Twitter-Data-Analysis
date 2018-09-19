import csv
from os import path

CountyTweets = []
with open("E:\\osu\\research\\CountyTweets.csv","rt",encoding="utf8") as f1:
    with open("E:\\osu\\research\\extratweets_fid.csv","rt",encoding="utf8") as f2:
        reader = csv.reader(f1)
        for row in reader:
            for i in row:
                CountyTweets.append(int(i))

        reader = csv.reader(f2)
        next(reader, None)
        for row in reader:
            CountyTweets[int(row[2])] += 1
with open("E:\\osu\\research\\CountyTweets_f.csv","wt",newline='') as wf:
    FID = 0
    writer = csv.writer(wf)
    for n in CountyTweets:
        writer.writerow([FID,n])
        FID += 1
