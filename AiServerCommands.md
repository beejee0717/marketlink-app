


### Logging In
## To log in to different servers, enter the console, navigate to the key file folder, then run:

# Search AI 
ssh -i "mk-key.pem" ubuntu@ec2-13-218-245-133.compute-1.amazonaws.com
[For search ai file editing flow click here ->>](#search-ai-editing)


# Feed Recommendation AI
ssh -i "custom-feed.pem" ubuntu@ec2-13-217-97-212.compute-1.amazonaws.com
[For feed ai file editing flow click here ->>](#feed-recommendation-editing)

# Notification Server
ssh -i "notif.pem" ubuntu@ec2-75-101-250-45.compute-1.amazonaws.com
[For notif server file editing flow click here ->>](#notification-editing)


------------------------------------------------

### Inside the Server
## Storage & Resources

# Show server storage usage
df -h
# Show memory usage
free -h

------------------------------------------------

## Folder Navigation / Creation / Removal

# Show files/folders in current directory
ls -lh
# Navigate to a directory
cd directoryname
# Create a folder
mkdir foldername
# Remove an empty folder
rmdir foldername
# Remove a folder with contents
rm -r foldername
# Renaming a folder
mv old_folder_name new_folder_name

------------------------------------------------

## File Management

# Create/edit file
nano filename.py
# Delete file
rm filename.py
# Rename file
mv old_file_name new_file_name
# Show file content
cat filename.py
# Display first 20 lines of a file
head -n 20 filename.txt
# Display last 20 lines of a file
tail -n 20 filename.txt


## common keyboard commands to use during file editing

- ctr+s **save file**
- ctr+x **exit file editing**
- ctr+k **cut entire line**
- ctr+c **cancel file editing, exit real time monitoring[example of real time monitoring](#follow-file-logs-in-real-time)** 


------------------------------------------------

## Uploading Files
# Format
scp -i "file.pem" file.file ubuntu@ec2-ip-address.compute-1.amazonaws.com:/directory 
# Example
scp -i "mk-key.pem" export_firebase_data.py ubuntu@ec2-34-227-56-36.compute-1.amazonaws.com:/home/ubuntu/product-search/

------------------------------------------------

## Processes & Virtual Environments
# Activate virtual environment
source venv/bin/activate
# Show processes containing 'uvicorn'
ps aux | grep uvicorn
# Kill process by PID
kill -9 <PID>

------------------------------------------------

## Using `nohup` (background processes)

### WE'RE USING NOHUP FOR THE CUSTOM FEED, ONLY USE THESE COMMANDS WHEN WE'RE INSIDE THIS SERVER

# Run Uvicorn server in background
nohup uvicorn app:app --host 0.0.0.0 --port 8000 &
# Follow file logs in real time
tail -f nohup.out


## Using `pm2` (process manager)

### WE'RE USING NOHUP FOR THE NOTIFICATIONS, ONLY USE THESE COMMANDS WHEN WE'RE INSIDE THIS SERVER

# View logs
pm2 logs notif
pm2 logs notif --lines 100

# Manage processes
pm2 stop notif
pm2 restart notif
pm2 delete notif
pm2 list

------------------------------------------------

## Using `systemctl` (Linux service manager)

### WE'RE USING NOHUP FOR THE PRODUCT SEARCH, ONLY USE THESE COMMANDS WHEN WE'RE INSIDE THIS SERVER

# Restart server
sudo systemctl restart product-search
# Show last 50 logs
journalctl -u product-search.service --no-pager -n 50

# Show logs in real time
journalctl -u product-search.service -f

------------------------------------------------

### Logging Out
exit

------------------------------------------------

## Important Notes

- It is recommended to activate virtual environment (venv) as soon as you enter the server, to avoid errors when running commands
- Always **kill the running process first** (`ps aux | grep uvicorn` → `kill -9 <PID>`) **before restarting** with `nohup`, `pm2`, or `systemctl`.  
- When editing files with `nano`, changes will only take effect **after the process/service is restarted**.  
- Use `rm -r` with caution — it will delete everything inside a folder permanently.  
- Use `scp` carefully when uploading files — overwriting files cannot be undone.  
- If unsure about a command, add `-i` (interactive) to confirm before deletion (e.g., `rm -ri foldername`).  
- For long-running apps, prefer `pm2` or `systemctl` over `nohup` for easier log management and restarts.  
- Always check logs (`tail -f nohup.out`, `pm2 logs`, or `journalctl -f`) after restarting to confirm the service is running correctly.  


//-----//---//-----//---//-----//---//-----//---//-----//---//-----//---//-----//---

## search ai editing

# enter server
ssh -i "mk-key.pem" ubuntu@ec2-13-218-245-133.compute-1.amazonaws.com
# navigate to the main directory 
cd ai-search
# activate venv 
source venv/bin/activate
# choose a file to edit/create a new file, use 'nano', and save using ctr+s
nano filename
- if unsure of the file lists, use **ls -lh** command to display all file
# run this command to restart the server to reflect changes
sudo systemctl restart product-search
# show logs to monitor if server is restarting fine
journalctl -u product-search.service -f
# exit real time log monitoring 
ctr+c


//-----//---//-----//---//-----//---//-----//---//-----//---//-----//---//-----//---

## feed recommendation editing
# enter server
ssh -i "custom-feed.pem" ubuntu@ec2-13-217-97-212.compute-1.amazonaws.com
# navigate to the main directory 
cd custom-feed
# activate venv 
source venv/bin/activate
# choose a file to edit/create a new file, use 'nano', and save using ctr+s
nano filename
- if unsure of the file lists, use **ls -lh** command to display all file
# In order to reflect changes we'll run multiple codes
1. check for existing running services
ps aux | grep uvicorn
## sample output
ubuntu     20601  0.1 32.5 1563812 303248 ?      Sl   Aug27  19:33 /home/ubuntu/custom-feed/venv/bin/python3 /home/ubuntu/custom-feed/venv/bin/uvicorn app:app --host 0.0.0.0 --port 8000
ubuntu     54366  0.0  0.1   6676  1800 pts/1    S+   10:06   0:00 grep --color=auto uvicorn
ubuntu@ip-172-31-47-147:~/custom-feed$
**note: if you only see one line of output, there's no existing service running**
2. kill the existing process using the PID (the second column, usually consists of numbers)
kill -9 <PID>
# example (we'll use the previous output)
kill -9 20601
**to confirm if the process is successfully killed, run the 'ps aux | grep uvicorn' command again, and it should output one line**
# example output if existing processes are killed successfully (note it should only be one line)
ubuntu     54366  0.0  0.1   6676  1800 pts/1    S+   10:06   0:00 grep --color=auto uvicorn
ubuntu@ip-172-31-47-147:~/custom-feed$
3. restart the server
nohup uvicorn app:app --host 0.0.0.0 --port 8000 &
4. check real time logs to see if its restarting okay
tail -f nohup.out
5. exit real time log monitoring 
ctr+c





//-----//---//-----//---//-----//---//-----//---//-----//---//-----//---//-----//---

## notification editing

# enter server
ssh -i "notif.pem" ubuntu@ec2-75-101-250-45.compute-1.amazonaws.com
# navigate to the main directory 
cd notif
# activate venv 
source venv/bin/activate
# choose a file to edit/create a new file, use 'nano', and save using ctr+s
nano filename
- if unsure of the file lists, use **ls -lh** command to display all file
# run this command to restart the server to reflect changes
pm2 stop notif
# show logs to monitor if server is restarting fine
pm2 logs notif
# exit real time log monitoring 
ctr+c

