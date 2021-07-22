# pifi
This is a shell script to connect a raspberry pi to a WPA2 enterprise wifi service and forward traffic to the Pi's ethernet adaptor. 
The sources are in the comments.

on a fresh install join a regular network (wifi psk or ethernet) and then download this script, or copy it to the pi using removable media,
run the script and then reboot your pi, it should now be connected to the wireless network using the details you supply when prompted by the script and the ethernet port should be acting as a router for you to plug in a wired device.
