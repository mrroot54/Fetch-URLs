#!/bin/bash

# Function to calculate percentage
calculate_percentage() {
    current=$1
    total=$2
    percentage=$(awk "BEGIN { pc=100*${current}/${total}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
    echo $percentage
}

# Function to check if file exists
check_file_exists() {
    local file=$1
    if [ ! -f "$file" ]; then
        echo "Error: $file not found."
        exit 1
    fi
}

# Step 1: Extract URLs from domain.txt using gauplus
extract_urls_with_gauplus() {
    DOMAIN_FILE="domain.txt"
    check_file_exists "$DOMAIN_FILE"

    total_lines=$(wc -l < "$DOMAIN_FILE")
    current_line=0

    echo "Step 1: Extracting URLs using gauplus..."
    while IFS= read -r domain || [[ -n "$domain" ]]; do
        current_line=$((current_line + 1))
        echo -ne "$(calculate_percentage $current_line $total_lines)% complete\r"

        # Remove http:// or https:// prefix if present
        domain_name=$(echo "$domain" | sed -e 's/^http:\/\///' -e 's/^https:\/\///')

        # Create a folder on Desktop named after the domain
        folder_name="$HOME/Desktop/$domain_name"
        mkdir -p "$folder_name"

        # Run gauplus and save output to urls3.txt in the domain folder
        output_file="$folder_name/urls3.txt"
        echo "$domain" | gauplus -b jpeg,jpg,png,gif,bmp,tiff,tif,svg,webp,heic,heif,ico,raw,psd,eps,ai,pdf,cr2,nef,arw,dng,orf,pef -o "$output_file"
    done < "$DOMAIN_FILE"

    echo -ne "Step 1: 100% complete\n\n"
}

# Step 2: Fetch URLs using waybackurls and filter out specific file extensions
fetch_urls_with_waybackurls() {
    DOMAIN_FILE="domain.txt"
    check_file_exists "$DOMAIN_FILE"

    echo "Step 2: Fetching URLs using waybackurls..."
    while IFS= read -r domain || [[ -n "$domain" ]]; do
        # Remove http:// or https:// prefix if present
        domain_name=$(echo "$domain" | sed -e 's/^http:\/\///' -e 's/^https:\/\///')

        # Create a folder on Desktop named after the domain
        folder_name="$HOME/Desktop/$domain_name"
        mkdir -p "$folder_name"

        # Run waybackurls and save output to urls2.txt in the domain folder
        output_file="$folder_name/urls2.txt"
        waybackurls "$domain" | grep -vE '\.(jpg|jpeg|png|gif|bmp|ico|svg|tiff|webp)$' > "$output_file"

        echo "Step 2: URLs saved to $output_file"
    done < "$DOMAIN_FILE"
}

# Step 3: Scan domains using Katana
scan_domains_with_katana() {
    DOMAIN_FILE="domain.txt"
    check_file_exists "$DOMAIN_FILE"

    echo "Step 3: Scanning domains using Katana..."
    while IFS= read -r domain || [[ -n "$domain" ]]; do
        # Remove http:// or https:// prefix if present
        domain_name=$(echo "$domain" | sed -e 's/^http:\/\///' -e 's/^https:\/\///')

        # Create a folder on Desktop named after the domain
        folder_name="$HOME/Desktop/$domain_name"
        mkdir -p "$folder_name"

        # Run Katana and save output to urls1.txt in the domain folder
        output_file="$folder_name/urls1.txt"
        katana -u "$domain" -o "$output_file" -ps -d 8 -jc

        echo "Step 3: Scan completed for: $domain"
        echo "------------------------------------------------"
    done < "$DOMAIN_FILE"
}

# Main execution
echo "Starting script..."

extract_urls_with_gauplus
fetch_urls_with_waybackurls
scan_domains_with_katana

# After all tasks are completed, concatenate and sort unique URLs
echo "Concatenating and sorting unique URLs..."
DOMAIN_FILE="domain.txt"
while IFS= read -r domain || [[ -n "$domain" ]]; do
    # Remove http:// or https:// prefix if present
    domain_name=$(echo "$domain" | sed -e 's/^http:\/\///' -e 's/^https:\/\///')

    # Create a folder on Desktop named after the domain
    folder_name="$HOME/Desktop/$domain_name"

    # Concatenate urls1.txt, urls2.txt, and urls3.txt and sort unique entries
    cat "$folder_name/urls1.txt" "$folder_name/urls2.txt" "$folder_name/urls3.txt" | sort -u >> "$folder_name/unique_sub.txt"

    echo "Unique URLs saved to $folder_name/unique_sub.txt"
done < "$DOMAIN_FILE"

echo "All tasks completed."
