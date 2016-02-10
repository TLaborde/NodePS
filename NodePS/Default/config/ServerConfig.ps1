# NodePS Server Configuration

# Number of concurrent listening thread
# Default is equal to the number of processor
$NodePSConfig.Threads = (Get-WmiObject Win32_ComputerSystem).NumberOfProcessors


# Cache mode can be used for better speed in production
$NodePSConfig.CachedMode = $false