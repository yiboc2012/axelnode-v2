#!/usr/bin/expect -f

set timeout 60
set password "Ilove67"
set user "rpi"
set ip "192.168.0.112"
set remote_dir "/home/rpi/axelnode_rpi"

# 1. Copy ALL files from rpi folder
spawn scp -o StrictHostKeyChecking=no -r rpi/ $user@$ip:$remote_dir/
expect {
    "*password:" {
        send "$password\r"
        exp_continue
    }
    eof
}

# 2. Setup permissions and move desktop shortcut
spawn ssh -o StrictHostKeyChecking=no $user@$ip "chmod +x $remote_dir/start_all.sh && cp $remote_dir/axel_node.desktop /home/rpi/Desktop/ && chmod +x /home/rpi/Desktop/axel_node.desktop"
expect {
    "*password:" {
        send "$password\r"
        exp_continue
    }
    eof
}

# 3. Start the system
spawn ssh -o StrictHostKeyChecking=no $user@$ip "cd $remote_dir && ./start_all.sh"
expect {
    "*password:" {
        send "$password\r"
        exp_continue
    }
    eof
}

puts "\n--- Deployment and Pi Setup Complete ---"
puts "Desktop shortcut created at /home/rpi/Desktop/axel_node.desktop"
