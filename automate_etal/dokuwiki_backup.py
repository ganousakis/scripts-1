#!/usr/bin/python

import subprocess
import time
import os
import sys
import logging
import glob

root, ext = os.path.splitext(__file__)
logging.basicConfig(format='%(asctime)s %(levelname)s %(message)s', filename=root+'.log', datefmt='%d/%m/%Y %H:%M:%S', level=logging.INFO)
current_time = time.time()
wiki_path = '/opt/rh/httpd24/root/var/www/html/wiki'
bkp_path = '/root/'
bkp_date = time.strftime("%Y%m%d")
bkp_file = bkp_path + 'wiki.' + bkp_date + '.tar.gz'
bkp_retention = 2 

# Delete files older than 2 days
for wiki_file in glob.glob(bkp_path + 'wiki.*.tar.gz'):
    creation_time = os.path.getctime(wiki_file)
    if (current_time - creation_time) // 86400 >= bkp_retention:
        try:
            os.unlink(wiki_file)
        except:
            logging.warning('Deleting ' + wiki_file + ' failed...')
            print ('Deleting {} failed...').format(wiki_file)
            sys.exit(1)
        else:
            logging.info('Deleting file ' + wiki_file + ' as its alive more than ' + str(bkp_retention) + ' days...')
            print('Deleting file {} as its alive more than {} days...'.format(wiki_file, bkp_retention))

# Check if BKP file exist for today or create BKP
if os.path.isfile(bkp_file):
    logging.info('Backup for today exists. Exiting...')
    print "Backup for today exists. Exiting..."
    sys.exit(2)
else:
    logging.info('Start executing gtar on ' + wiki_path)
    print ("\nStart executing gtar czf wiki.{}.tar on " + wiki_path).format(bkp_date)
    try:
        subprocess.call(['gtar', 'czf', bkp_file, wiki_path])
    except:
        logging.info('Something went wrong during tar or gunzip...')
        print("An exception occurred")
        sys.exit(1)
    else:
        if os.path.isfile(bkp_file):
            logging.info('Backup completed for today. ' + bkp_file + ' file created. Now will exit...')
            print "Backup completed for today. Exiting..."
            sys.exit(0)

