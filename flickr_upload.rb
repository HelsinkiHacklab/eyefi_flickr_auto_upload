#
#  Automated upload to Flickr
#   jssmk @ Helsinki Hacklab
#
#     arranges photos in
#       albums by date
#

# Start with editing your locals.rb file, use locals_default.rb as a template
require_relative 'locals'

pic_list = Dir[PIC_path+"**/**{.JPG,.jpg}"].reject { |p| p.index(PIC_exclude_prefix) }


# if pic_list is empty, no need to do anything else, just exit
if pic_list.empty?
  exit
end

require 'flickraw'
require 'exifr'
require 'logger'

# Logfile
$mylog = Logger.new(LOG_path+'flickr_upload_log.txt', 10, 1024000)
$mylog.info("Start ---->")
$mylog.info("Number of new pics to upload: "+pic_list.length.to_s)


FlickRaw.api_key = MY_api_key
FlickRaw.shared_secret = MY_shared_secret


### uncomment below if you yet have no token
#token = flickr.get_request_token
#auth_url = flickr.get_authorize_url(token['oauth_token'], :perms => 'delete')
#
#puts "Open this url in your process to complete the authication process : #{auth_url}"
#puts "Copy here the number given when you complete the process."
#verify = gets.strip
#
#begin
#  flickr.get_access_token(token['oauth_token'], token['oauth_token_secret'], verify)
#  login = flickr.test.login
#  puts "You are now authenticated as #{login.username} with token #{flickr.access_token} and secret #{flickr.access_secret}"
#rescue FlickRaw::FailedResponse => e
#  puts "Authentication failed : #{e.msg}"
#end
############

### use when you have your token
flickr.access_token = MY_access_token
flickr.access_secret = MY_access_secret

# Login

begin
  login = flickr.test.login
rescue TypeError, NameError => e
  $mylog.error("Login failed: #{e}")
  exit
end
$mylog.info("You are authenticated as #{login.username}")


# List of albums in my Flickr account

$album_list = nil
def refresh_album_list()
  $album_list = flickr.photosets.getList
end
refresh_album_list()


def upload_pic(pic, pic_name, album_name)
  
  pic_dirname = File.dirname(pic)
  pic_basename = File.basename(pic)
  
  ## Upload

  begin
    # try uploading the pic
    $mylog.info("Start uploading: "+pic_basename)
    
    # upload_photo returns Flickr photo id
    pic_result = flickr.upload_photo pic, :title => pic_name, :description => PIC_default_desc
  rescue FlickRaw::FailedResponse => e
    $mylog.error("Photo upload failed: #{e.msg}")
    return
  end
  $mylog.info("Pic "+pic_basename+" uploaded")
  
  # mark this file now uploaded using a prefix
  File.rename(pic, pic_dirname+'/'+PIC_exclude_prefix+pic_basename)
  
  
  ## Tags

  begin
    # Add tags to newly uploaded photo
    flickr.photos.addTags api_key: FlickRaw.api_key, photo_id: pic_result, tags: PIC_default_tags
  rescue FlickRaw::FailedResponse => e
    $mylog.error("Photo tagging failed: #{e.msg}")
  end
  
  
  ## Handle albums

  # return first occurrence of an album with title '%Y-%m-%d'
  dest_album = $album_list.detect{|a| a.title == album_name}
  
  if dest_album != nil
    # album already exists
    $mylog.info("Adding pic to album "+dest_album.title)
    
    begin
      flickr.photosets.addPhoto photoset_id: dest_album.id, photo_id: pic_result
    rescue FlickRaw::FailedResponse => e
      $mylog.error("Adding to album failed: #{e.msg}")
    end
    
  else
    # album does not yet exist
    $mylog.info("Creating new album: "+album_name)
    
    begin
      flickr.photosets.create api_key: FlickRaw.api_key, title: album_name, :primary_photo_id => pic_result
    rescue FlickRaw::FailedResponse => e
      $mylog.error("Creating album failed: #{e.msg}")
    end
    
    refresh_album_list() # we now have a new album available, refresh the list
  end
end


# Upload the pics so that photostream shows new photos first
pic_list.sort! {|left, right| EXIFR::JPEG.new(left).date_time <=> EXIFR::JPEG.new(right).date_time }


for pic in pic_list
  # Use exif data to rename both picture and album titles
  
  # Reduce 3h from album dates, so that pics taken before 3 am. are sorted in same Flickr album with pics taken at same evening/night
  album_date = EXIFR::JPEG.new(pic).album_date - (60 * 60 * 3)

  album_name = album_date.strftime('%Y-%m-%d')
  pic_name = EXIFR::JPEG.new(pic).date_time.strftime('%Y-%m-%d %H:%M:%S')
  
  # Upload the pic, insert to album or create a new one if not existing
  upload_pic(pic, pic_name, album_name)
end

$mylog.info("----> End")