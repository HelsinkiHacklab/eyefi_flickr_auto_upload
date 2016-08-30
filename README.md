# eyefi_flickr_auto_upload

_(This is more like tutorial or an example rather than a project - in fact all Eye-Fi related stuff is handled by eyefiserver2)_

Upload photos to Flickr albums using X2 Eye-Fi card and Raspberry Pi 3.

## Features
 * Replacement for soon-to-be-discontinued Eye-Fi Center auto-upload
 * Gets photos from the card, uploads them to Flickr 
 * Sorts photos in folders in RasPi and in albums by date in Flickr using exif data

## Requirements
 * eyefiserver2 by dgrant: https://github.com/dgrant/eyefiserver2
 * flickraw: https://github.com/hanklords/flickraw
 * exifr: https://github.com/remvee/exifr
 * Raspberry Pi 3

## Step-by-step, how to use:

(this might be missing some steps, I try to make better instructons for Eye-Fi Center stuff later)

###1.
These instructions require you to first configure your eye-fi card using Eye-Fi Center. Remove your card from your Eye-Fi account, but first enable its Wifi option (Direct mode network). You will need the Wifi network name and the password. You also need its MAC address and upload key.

On Mac OS, you can find the MAC address in Eye-Fi xml file in your Library folder.

###2.
Using your Raspberry Pi 3:
Start with apt-get update

###3.
Download and configure eyefiserver2, I'm putting all my project files in folder ~/eyefi
```
mkdir eyefi
cd eyefi
git clone https://github.com/dgrant/eyefiserver2
cd eyefiserver2
```
edit your etc/eyefiserver2.conf
you need to change following:
 * mac_0
 * upload_key_0
 * upload_uid
 * upload_gid
 * upload_dir

For this example, I'm using upload_dir:/home/pi/Pictures/%%Y-%%m-%%d

upload_uid and upload_gid are both 1000

Copy the files:
```
sudo cp etc/eyefiserver2.conf /etc
sudo cp etc/init.d/eyefiserver /etc/init.d/
sudo cp usr/local/bin/eyefiserver.py /usr/local/bin/
```

###4.
Set up Wifi
* edit your /etc/wpa_supplicant/wpa_supplicant.conf:

```
   network={
      ssid="Eye-Fi Card ffffff"
      psk="PASSWORD"
  }
```


###5.
Ruby installs
```
sudo gem install flickraw
sudo gem install exifr
```

###6.
In ~/eyefi:
 * git clone https://github.com/HelsinkiHacklab/eyefi_flickr_auto_upload
 * Make your own locals.rb file using locals_default.rb template file

###7.
Add in your crontab
```
@reboot sudo eyefiserver.py start /etc/eyefiserver.conf /home/pi/Documents/eyefi-log.txt
*/5 * * * * ruby /home/pi/eyefi/eyefi_flickr_auto_upload/flickr_upload.rb 
```

### TODO:
Remove photos older than X days from Raspberry Pi to make space for new ones.
